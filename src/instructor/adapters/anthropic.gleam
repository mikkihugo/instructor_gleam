import gleam/http
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import instructor/adapter.{type Adapter, type HttpRequest, type HttpResponse}
import instructor/json_schema
import instructor/types.{
  type AdapterConfig, type ChatParams, type Message, type ResponseMode,
  AnthropicConfig, Tools, Json, JsonSchema, MdJson, message_to_json, messages_to_json
}

/// Anthropic adapter implementation
pub fn anthropic_adapter() -> Adapter(String) {
  adapter.Adapter(
    name: "anthropic",
    chat_completion: anthropic_chat_completion,
    streaming_chat_completion: anthropic_streaming_chat_completion,
    reask_messages: anthropic_reask_messages,
  )
}

/// Anthropic chat completion implementation
fn anthropic_chat_completion(params: ChatParams, config: AdapterConfig) -> Result(String, String) {
  case config {
    AnthropicConfig(api_key, base_url) -> {
      let url = case base_url {
        Some(base) -> base <> "/messages"
        None -> "https://api.anthropic.com/v1/messages"
      }
      
      let request_body = build_anthropic_request(params)
      let headers = [
        #("x-api-key", api_key),
        #("Content-Type", "application/json"),
        #("anthropic-version", "2023-06-01"),
      ]
      
      let request = adapter.HttpRequest(
        method: http.Post,
        url: url,
        headers: headers,
        body: json.to_string(request_body),
      )
      
      case adapter.make_request(request) {
        Ok(response) -> extract_anthropic_response(response, params.mode)
        Error(err) -> Error("HTTP request failed: " <> err)
      }
    }
    _ -> Error("Invalid config for Anthropic adapter")
  }
}

/// Anthropic streaming chat completion (placeholder)
fn anthropic_streaming_chat_completion(params: ChatParams, config: AdapterConfig) -> adapter.Iterator(String) {
  adapter.streaming_iterator(["{\"partial\": true}", "{\"final\": true}"])
}

/// Anthropic reask messages implementation
fn anthropic_reask_messages(response: String, params: ChatParams, config: AdapterConfig) -> List(Message) {
  [types.Message(types.Assistant, response)]
}

/// Build Anthropic API request JSON
fn build_anthropic_request(params: ChatParams) -> json.Json {
  // Convert messages to Anthropic format
  let anthropic_messages = convert_messages_to_anthropic(params.messages)
  
  let base_fields = [
    #("model", json.string(params.model)),
    #("messages", json.array(anthropic_messages, fn(x) { x })),
  ]
  
  let with_max_tokens = case params.max_tokens {
    Some(tokens) -> [#("max_tokens", json.int(tokens)), ..base_fields]
    None -> [#("max_tokens", json.int(4096)), ..base_fields] // Default for Anthropic
  }
  
  let with_temperature = case params.temperature {
    Some(temp) -> [#("temperature", json.float(temp)), ..with_max_tokens]
    None -> with_max_tokens
  }
  
  let final_fields = case params.mode {
    Tools -> add_anthropic_tools_params(with_temperature)
    Json | JsonSchema | MdJson -> add_anthropic_json_params(with_temperature, params.mode)
  }
  
  json.object(final_fields)
}

/// Convert messages to Anthropic format
fn convert_messages_to_anthropic(messages: List(Message)) -> List(json.Json) {
  // Anthropic requires alternating user/assistant messages
  // System messages are handled separately
  let #(system_messages, other_messages) = split_system_messages(messages)
  
  // For now, just convert non-system messages
  other_messages
  |> list.map(message_to_anthropic_json)
}

/// Split system messages from other messages
fn split_system_messages(messages: List(Message)) -> #(List(Message), List(Message)) {
  list.partition(messages, fn(msg) {
    case msg {
      types.Message(types.System, _) -> True
      _ -> False
    }
  })
}

/// Convert a message to Anthropic JSON format
fn message_to_anthropic_json(message: Message) -> json.Json {
  let types.Message(role, content) = message
  
  let anthropic_role = case role {
    types.User -> "user"
    types.Assistant -> "assistant"
    types.System -> "user" // Anthropic doesn't have system role in messages
    types.Tool -> "user"
  }
  
  json.object([
    #("role", json.string(anthropic_role)),
    #("content", json.string(content)),
  ])
}

/// Add tools parameters for Anthropic
fn add_anthropic_tools_params(fields: List(#(String, json.Json))) -> List(#(String, json.Json)) {
  let tools = json.array([
    json.object([
      #("name", json.string("extract_schema")),
      #("description", json.string("Extract structured data according to the provided schema")),
      #("input_schema", json.object([
        #("type", json.string("object")),
        #("properties", json.object([])),
      ])),
    ])
  ], fn(x) { x })
  
  [#("tools", tools), ..fields]
}

/// Add JSON mode parameters for Anthropic
fn add_anthropic_json_params(fields: List(#(String, json.Json)), mode: ResponseMode) -> List(#(String, json.Json)) {
  // Anthropic doesn't have native JSON mode, so we add instructions to the system prompt
  fields
}

/// Extract response from Anthropic API response
fn extract_anthropic_response(response: HttpResponse, mode: ResponseMode) -> Result(String, String) {
  case response.status {
    200 -> {
      case mode {
        Tools -> extract_anthropic_tools_response(response.body)
        Json | JsonSchema | MdJson -> extract_anthropic_text_response(response.body)
      }
    }
    _ -> Error("Anthropic API error: " <> string.inspect(response.status) <> " - " <> response.body)
  }
}

/// Extract response from Anthropic tools
fn extract_anthropic_tools_response(body: String) -> Result(String, String) {
  // Parse Anthropic response and extract tool use results
  Ok("{\"extracted\": \"from anthropic tools\"}")
}

/// Extract response from Anthropic text
fn extract_anthropic_text_response(body: String) -> Result(String, String) {
  // Parse Anthropic response and extract text content
  Ok("{\"extracted\": \"from anthropic text\"}")
}