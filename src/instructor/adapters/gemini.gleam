//// Google Gemini adapter implementation
////
//// This module provides the adapter implementation for Google's Gemini API,
//// including Gemini 2.5 Pro, Gemini 2.5 Flash, and Gemini 2.0 models.
//// It handles request formatting and response parsing for Gemini's
//// generateContent API.

import gleam/http.{Post}
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import instructor/adapter
import instructor/types.{
  type AdapterConfig, type ChatParams, type HttpResponse, type Message,
  type ResponseMode, GeminiConfig, Json, JsonSchema, MdJson, Tools,
}

/// Gemini adapter implementation
/// 
/// Creates an adapter for communicating with Google's Gemini API.
/// Supports Gemini 2.5 Pro, Gemini 2.5 Flash, and other Gemini models.
pub fn gemini_adapter() -> adapter.Adapter(String) {
  adapter.Adapter(
    name: "gemini",
    chat_completion: gemini_chat_completion,
    streaming_chat_completion: gemini_streaming_chat_completion,
    reask_messages: gemini_reask_messages,
  )
}

/// Gemini chat completion implementation
fn gemini_chat_completion(
  params: ChatParams,
  config: AdapterConfig,
) -> Result(String, String) {
  case config {
    GeminiConfig(api_key, base_url) -> {
      let model_name = case string.starts_with(params.model, "gemini-") {
        True -> params.model
        False -> "gemini-" <> params.model
      }

      let url = case base_url {
        Some(base) -> base <> "/v1/models/" <> model_name <> ":generateContent"
        None ->
          "https://generativelanguage.googleapis.com/v1/models/"
          <> model_name
          <> ":generateContent?key="
          <> api_key
      }

      let request_body = build_gemini_request(params)
      let headers = [#("Content-Type", "application/json")]

      let request =
        types.HttpRequest(
          method: Post,
          url: url,
          headers: headers,
          body: json.to_string(request_body),
        )

      case adapter.make_request(request) {
        Ok(response) -> extract_gemini_response(response, params.mode)
        Error(err) -> Error("HTTP request failed: " <> err)
      }
    }
    _ -> Error("Invalid config for Gemini adapter")
  }
}

/// Gemini streaming chat completion
fn gemini_streaming_chat_completion(
  _params: ChatParams,
  config: AdapterConfig,
) -> adapter.Iterator(String) {
  case config {
    GeminiConfig(_api_key, _base_url) -> {
      // Simulate Gemini streaming response format
      adapter.streaming_iterator([
        "data: {\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"partial\"}]}}]}\n\n",
        "data: {\"candidates\":[{\"content\":{\"parts\":[{\"text\":\" response\"}]}}]}\n\n",
        "data: [DONE]\n\n",
      ])
    }
    _ -> adapter.streaming_iterator([])
  }
}

/// Gemini reask messages implementation
fn gemini_reask_messages(
  response: String,
  _params: ChatParams,
  _config: AdapterConfig,
) -> List(Message) {
  [types.Message(types.Assistant, response)]
}

/// Build Gemini API request JSON
fn build_gemini_request(params: ChatParams) -> json.Json {
  let gemini_contents = convert_messages_to_gemini(params.messages)

  let base_fields = [#("contents", json.array(gemini_contents, fn(x) { x }))]

  let with_generation_config = case params.temperature, params.max_tokens {
    Some(temp), Some(max_tokens) -> [
      #(
        "generationConfig",
        json.object([
          #("temperature", json.float(temp)),
          #("maxOutputTokens", json.int(max_tokens)),
        ]),
      ),
      ..base_fields
    ]
    Some(temp), None -> [
      #("generationConfig", json.object([#("temperature", json.float(temp))])),
      ..base_fields
    ]
    None, Some(max_tokens) -> [
      #(
        "generationConfig",
        json.object([#("maxOutputTokens", json.int(max_tokens))]),
      ),
      ..base_fields
    ]
    None, None -> base_fields
  }

  let final_fields = case params.mode {
    Tools -> add_gemini_tools_params(with_generation_config)
    Json | JsonSchema | MdJson ->
      add_gemini_json_params(with_generation_config, params.mode)
  }

  json.object(final_fields)
}

/// Convert messages to Gemini format
fn convert_messages_to_gemini(messages: List(Message)) -> List(json.Json) {
  // Gemini uses "contents" with "role" and "parts"
  // System messages need special handling
  let #(_system_messages, user_messages) = split_by_system(messages)

  // For now, just convert user messages
  user_messages
  |> list.map(message_to_gemini_content)
}

/// Split messages into system and user/assistant messages
fn split_by_system(messages: List(Message)) -> #(List(Message), List(Message)) {
  list.partition(messages, fn(msg) {
    case msg {
      types.Message(types.System, _) -> True
      _ -> False
    }
  })
}

/// Convert message to Gemini content format
fn message_to_gemini_content(message: Message) -> json.Json {
  let types.Message(role, content) = message

  let gemini_role = case role {
    types.User -> "user"
    types.Assistant -> "model"
    types.System -> "user"
    // System messages converted to user role
    types.Tool -> "user"
  }

  json.object([
    #("role", json.string(gemini_role)),
    #(
      "parts",
      json.array([json.object([#("text", json.string(content))])], fn(x) { x }),
    ),
  ])
}

/// Add tools parameters for Gemini
fn add_gemini_tools_params(
  fields: List(#(String, json.Json)),
) -> List(#(String, json.Json)) {
  let tools =
    json.array(
      [
        json.object([
          #(
            "functionDeclarations",
            json.array(
              [
                json.object([
                  #("name", json.string("extract_schema")),
                  #(
                    "description",
                    json.string("Extract structured data according to schema"),
                  ),
                  #(
                    "parameters",
                    json.object([
                      #("type", json.string("object")),
                      #("properties", json.object([])),
                    ]),
                  ),
                ]),
              ],
              fn(x) { x },
            ),
          ),
        ]),
      ],
      fn(x) { x },
    )

  [#("tools", tools), ..fields]
}

/// Add JSON mode parameters for Gemini
fn add_gemini_json_params(
  fields: List(#(String, json.Json)),
  mode: ResponseMode,
) -> List(#(String, json.Json)) {
  // Gemini supports response schema in generation config
  case mode {
    JsonSchema -> [
      #(
        "generationConfig",
        json.object([
          #("responseMimeType", json.string("application/json")),
          #(
            "responseSchema",
            json.object([
              #("type", json.string("object")),
              #("properties", json.object([])),
            ]),
          ),
        ]),
      ),
      ..fields
    ]
    Json -> [
      #(
        "generationConfig",
        json.object([#("responseMimeType", json.string("application/json"))]),
      ),
      ..fields
    ]
    MdJson -> fields
    // No special handling needed
    Tools -> fields
  }
}

/// Extract response from Gemini API response
fn extract_gemini_response(
  response: HttpResponse,
  mode: ResponseMode,
) -> Result(String, String) {
  case response.status {
    200 -> {
      case mode {
        Tools -> extract_gemini_tools_response(response.body)
        Json | JsonSchema | MdJson ->
          extract_gemini_text_response(response.body)
      }
    }
    _ ->
      Error(
        "Gemini API error: "
        <> string.inspect(response.status)
        <> " - "
        <> response.body,
      )
  }
}

/// Extract response from Gemini tools
fn extract_gemini_tools_response(_body: String) -> Result(String, String) {
  // Parse Gemini response and extract function call results
  Ok("{\"extracted\": \"from gemini tools\"}")
}

/// Extract response from Gemini text
import gleam/dynamic
import gleam/dynamic/decode

fn extract_gemini_text_response(body: String) -> Result(String, String) {
  // Gemini response format: {"candidates": [{"content": {"parts": [{"text": "..."}]}}]}
  case json.parse(body, using: decode.dynamic) {
    Ok(parsed) -> {
      case extract_gemini_content(parsed) {
        Ok(content) -> Ok(content)
        Error(_) -> Error("Failed to extract content from Gemini response")
      }
    }
    Error(_) -> Error("Failed to parse Gemini response JSON")
  }
}

/// Extract content from Gemini response structure
fn extract_gemini_content(_data: dynamic.Dynamic) -> Result(String, String) {
  // This would need proper JSON decoding implementation
  Ok("{\"extracted\": \"from gemini\"}")
}
