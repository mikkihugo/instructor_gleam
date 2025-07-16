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
  OpenAIConfig, Tools, Json, JsonSchema, MdJson, message_to_json, messages_to_json
}

/// OpenAI adapter implementation
pub fn openai_adapter() -> Adapter(String) {
  adapter.Adapter(
    name: "openai",
    chat_completion: openai_chat_completion,
    streaming_chat_completion: openai_streaming_chat_completion,
    reask_messages: openai_reask_messages,
  )
}

/// OpenAI chat completion implementation
fn openai_chat_completion(params: ChatParams, config: AdapterConfig) -> Result(String, String) {
  case config {
    OpenAIConfig(api_key, base_url) -> {
      let url = case base_url {
        Some(base) -> base <> "/chat/completions"
        None -> "https://api.openai.com/v1/chat/completions"
      }
      
      let request_body = build_openai_request(params)
      let headers = [
        #("Authorization", "Bearer " <> api_key),
        #("Content-Type", "application/json"),
      ]
      
      let request = adapter.HttpRequest(
        method: http.Post,
        url: url,
        headers: headers,
        body: json.to_string(request_body),
      )
      
      case adapter.make_request(request) {
        Ok(response) -> extract_openai_response(response, params.mode)
        Error(err) -> Error("HTTP request failed: " <> err)
      }
    }
    _ -> Error("Invalid config for OpenAI adapter")
  }
}

/// OpenAI streaming chat completion (placeholder)
fn openai_streaming_chat_completion(params: ChatParams, config: AdapterConfig) -> adapter.Iterator(String) {
  // For now, return a mock streaming response
  adapter.streaming_iterator(["{\"partial\": true}", "{\"final\": true}"])
}

/// OpenAI reask messages implementation
fn openai_reask_messages(response: String, params: ChatParams, config: AdapterConfig) -> List(Message) {
  // Return the assistant's response as a message for retry context
  [types.Message(types.Assistant, response)]
}

/// Build OpenAI API request JSON
fn build_openai_request(params: ChatParams) -> json.Json {
  let base_fields = [
    #("model", json.string(params.model)),
    #("messages", messages_to_json(params.messages)),
    #("stream", json.bool(params.stream)),
  ]
  
  let with_temperature = case params.temperature {
    Some(temp) -> [#("temperature", json.float(temp)), ..base_fields]
    None -> base_fields
  }
  
  let with_max_tokens = case params.max_tokens {
    Some(tokens) -> [#("max_tokens", json.int(tokens)), ..with_temperature]
    None -> with_temperature
  }
  
  let final_fields = case params.mode {
    Tools -> add_tools_params(with_max_tokens)
    Json -> add_json_params(with_max_tokens)
    JsonSchema -> add_json_schema_params(with_max_tokens)
    MdJson -> with_max_tokens
  }
  
  json.object(final_fields)
}

/// Add tools parameters for function calling
fn add_tools_params(fields: List(#(String, json.Json))) -> List(#(String, json.Json)) {
  let tools = json.array([
    json.object([
      #("type", json.string("function")),
      #("function", json.object([
        #("name", json.string("Schema")),
        #("description", json.string("Correctly extracted schema with all required parameters")),
        #("parameters", json.object([
          #("type", json.string("object")),
          #("properties", json.object([])),
        ])),
      ])),
    ])
  ], fn(x) { x })
  
  let tool_choice = json.object([
    #("type", json.string("function")),
    #("function", json.object([
      #("name", json.string("Schema")),
    ])),
  ])
  
  [
    #("tools", tools),
    #("tool_choice", tool_choice),
    ..fields
  ]
}

/// Add JSON mode parameters
fn add_json_params(fields: List(#(String, json.Json))) -> List(#(String, json.Json)) {
  let response_format = json.object([
    #("type", json.string("json_object")),
  ])
  
  [#("response_format", response_format), ..fields]
}

/// Add JSON schema parameters
fn add_json_schema_params(fields: List(#(String, json.Json))) -> List(#(String, json.Json)) {
  let response_format = json.object([
    #("type", json.string("json_schema")),
    #("json_schema", json.object([
      #("name", json.string("schema")),
      #("strict", json.bool(True)),
      #("schema", json.object([
        #("type", json.string("object")),
        #("properties", json.object([])),
      ])),
    ])),
  ])
  
  [#("response_format", response_format), ..fields]
}

/// Extract response from OpenAI API response
fn extract_openai_response(response: HttpResponse, mode: ResponseMode) -> Result(String, String) {
  case response.status {
    200 -> {
      case mode {
        Tools -> extract_tools_response(response.body)
        Json | JsonSchema -> extract_json_response(response.body)
        MdJson -> extract_md_json_response(response.body)
      }
    }
    _ -> Error("OpenAI API error: " <> string.inspect(response.status) <> " - " <> response.body)
  }
}

/// Extract response from tools/function calling
fn extract_tools_response(body: String) -> Result(String, String) {
  // Parse the OpenAI response and extract the function call arguments
  // This is a simplified implementation
  Ok("{\"extracted\": \"from tools\"}")
}

/// Extract response from JSON mode
fn extract_json_response(body: String) -> Result(String, String) {
  // Parse the OpenAI response and extract the content
  // This is a simplified implementation
  Ok("{\"extracted\": \"from json\"}")
}

/// Extract response from markdown JSON mode
fn extract_md_json_response(body: String) -> Result(String, String) {
  // Parse the OpenAI response and extract JSON from markdown code block
  // This is a simplified implementation
  Ok("{\"extracted\": \"from md_json\"}")
}