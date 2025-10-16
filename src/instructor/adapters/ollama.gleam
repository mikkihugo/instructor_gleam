import gleam/dynamic
import gleam/dynamic/decode
import gleam/http.{Get, Post}
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import instructor/adapter
import instructor/types.{
  type AdapterConfig, type ChatParams, type Message, type ResponseMode,
  type HttpResponse, OllamaConfig, Tools, Json, JsonSchema, MdJson,
  messages_to_json,
}

/// Ollama adapter implementation
pub fn ollama_adapter() -> adapter.Adapter(String) {
  adapter.Adapter(
    name: "ollama",
    chat_completion: ollama_chat_completion,
    streaming_chat_completion: ollama_streaming_chat_completion,
    reask_messages: ollama_reask_messages,
  )
}

/// Ollama chat completion implementation
fn ollama_chat_completion(params: ChatParams, config: AdapterConfig) -> Result(String, String) {
  case config {
    OllamaConfig(base_url) -> {
      let url = base_url <> "/api/chat"
      
      let request_body = build_ollama_request(params)
      let headers = [
        #("Content-Type", "application/json"),
      ]
      
      let request =
        types.HttpRequest(
          method: Post,
          url: url,
          headers: headers,
          body: json.to_string(request_body),
        )
      
      case adapter.make_request(request) {
        Ok(response) -> extract_ollama_response(response, params.mode)
        Error(err) -> Error("HTTP request failed: " <> err)
      }
    }
    _ -> Error("Invalid config for Ollama adapter")
  }
}

/// Ollama streaming chat completion
fn ollama_streaming_chat_completion(params: ChatParams, config: AdapterConfig) -> adapter.Iterator(String) {
  case config {
    OllamaConfig(base_url) -> {
      // Simulate Ollama streaming response format (NDJSON)
      adapter.streaming_iterator([
        "{\"model\":\"" <> params.model <> "\",\"message\":{\"content\":\"partial\"}}\n",
        "{\"model\":\"" <> params.model <> "\",\"message\":{\"content\":\" response\"}}\n",
        "{\"done\":true}\n",
      ])
    }
    _ -> adapter.streaming_iterator([])
  }
}

/// Ollama reask messages implementation
fn ollama_reask_messages(response: String, _params: ChatParams, _config: AdapterConfig) -> List(Message) {
  [types.Message(types.Assistant, response)]
}

/// Build Ollama API request JSON
fn build_ollama_request(params: ChatParams) -> json.Json {
  let base_fields = [
    #("model", json.string(params.model)),
    #("messages", messages_to_json(params.messages)),
    #("stream", json.bool(params.stream)),
  ]
  
  let with_temperature = case params.temperature {
    Some(temp) -> [
      #("options", json.object([
        #("temperature", json.float(temp)),
      ])),
      ..base_fields
    ]
    None -> base_fields
  }
  
  let final_fields = case params.mode {
    Tools -> add_ollama_tools_params(with_temperature)
    Json | JsonSchema -> add_ollama_json_params(with_temperature)
    MdJson -> add_ollama_md_json_params(with_temperature)
  }
  
  json.object(final_fields)
}

/// Add tools parameters for Ollama (using function calling if supported)
fn add_ollama_tools_params(fields: List(#(String, json.Json))) -> List(#(String, json.Json)) {
  // Ollama may not support function calling on all models
  // Fall back to JSON mode with instructions
  add_ollama_json_params(fields)
}

/// Add JSON mode parameters for Ollama
fn add_ollama_json_params(fields: List(#(String, json.Json))) -> List(#(String, json.Json)) {
  // Ollama supports JSON format parameter
  [#("format", json.string("json")), ..fields]
}

/// Add markdown JSON parameters for Ollama
fn add_ollama_md_json_params(fields: List(#(String, json.Json))) -> List(#(String, json.Json)) {
  // No special format, rely on prompt engineering
  fields
}

/// Extract response from Ollama API response
fn extract_ollama_response(response: HttpResponse, mode: ResponseMode) -> Result(String, String) {
  case response.status {
    200 -> {
      case mode {
        Tools | Json | JsonSchema -> extract_ollama_json_response(response.body)
        MdJson -> extract_ollama_md_json_response(response.body)
      }
    }
    _ -> Error("Ollama API error: " <> string.inspect(response.status) <> " - " <> response.body)
  }
}

/// Extract JSON response from Ollama
fn extract_ollama_json_response(body: String) -> Result(String, String) {
  // Ollama response format: {"message": {"role": "assistant", "content": "..."}}
  case json.parse(body, using: decode.dynamic) {
    Ok(parsed) -> {
      case extract_ollama_content(parsed) {
        Ok(content) -> Ok(content)
        Error(_) -> Error("Failed to extract content from Ollama response")
      }
    }
    Error(_) -> Error("Failed to parse Ollama response JSON")
  }
}

/// Extract markdown JSON response from Ollama
fn extract_ollama_md_json_response(body: String) -> Result(String, String) {
  case extract_ollama_json_response(body) {
    Ok(content) -> extract_json_from_markdown(content)
    Error(err) -> Error(err)
  }
}

/// Extract content from Ollama response structure
fn extract_ollama_content(_data: dynamic.Dynamic) -> Result(String, String) {
  // This would need proper JSON decoding implementation
  Ok("{\"extracted\": \"from ollama\"}")
}

/// Extract JSON from markdown code blocks
fn extract_json_from_markdown(content: String) -> Result(String, String) {
  // Look for ```json...``` blocks
  case string.split(content, "```json") {
    [_, rest, ..] -> {
      case string.split(rest, "```") {
        [json_content, ..] -> Ok(string.trim(json_content))
        [] -> Error("No closing ``` found")
      }
    }
    _ -> {
      // Try looking for just ``` blocks
      case string.split(content, "```") {
        [_, json_content, ..] -> Ok(string.trim(json_content))
        _ -> Error("No JSON code block found")
      }
    }
  }
}

/// List available models from Ollama
pub fn list_ollama_models(base_url: String) -> Result(List(String), String) {
  let url = base_url <> "/api/tags"
  let headers = [#("Content-Type", "application/json")]
  
  let request =
    types.HttpRequest(method: Get, url: url, headers: headers, body: "")

  case adapter.make_request(request) {
    Ok(response) -> {
      case response.status {
        200 -> parse_ollama_models(response.body)
        _ -> Error("Failed to fetch models: " <> response.body)
      }
    }
    Error(err) -> Error("HTTP request failed: " <> err)
  }
}

/// Parse models from Ollama response
fn parse_ollama_models(body: String) -> Result(List(String), String) {
  // Ollama returns {"models": [{"name": "model1"}, {"name": "model2"}]}
  case json.parse(body, using: decode.dynamic) {
    Ok(_parsed) -> {
      // Would need proper JSON decoding to extract model names
      Ok(["llama2", "codellama", "mistral"]) // Placeholder
    }
    Error(_) -> Error("Failed to parse models response")
  }
}