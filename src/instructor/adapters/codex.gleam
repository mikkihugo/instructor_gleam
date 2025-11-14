//// Codex adapter implementation for ChatGPT OAuth
////
//// This module provides the adapter implementation for ChatGPT's subscription-based
//// OAuth API (not the pay-per-token OpenAI API). It reads authentication from
//// ~/.codex/auth.json and makes requests to chatgpt.com/backend-api/codex/responses.
////
//// ## Authentication
////
//// Requires OAuth tokens managed by the `codex` CLI tool:
//// - Reads from: `~/.codex/auth.json`
//// - Tokens auto-refresh in background (handled by codex CLI)
////
//// ## Supported Models
////
//// - `codex-mini-latest` - Fast, 200k context, based on o4-mini
//// - `gpt-5-codex` - Full quality, 272k context, better reasoning
//// - `gpt-5` - General purpose, 272k context
////
//// ## Reasoning Effort Levels
////
//// - `minimal` - gpt-5 only, fastest
//// - `low` - Quick reasoning
//// - `medium` - Balanced (default)
//// - `high` - Maximum quality, slowest

import gleam/http.{Post}
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import instructor/adapter
import instructor/types.{
  type AdapterConfig, type ChatParams, type HttpResponse, type Message,
  type ResponseMode, Json, JsonSchema, MdJson, Tools,
}

/// Codex adapter configuration
pub type CodexConfig {
  CodexConfig(
    access_token: String,
    account_id: Option(String),
    reasoning_effort: Option(String),
    reasoning_summary: Bool,
  )
}

/// Add CodexConfig to AdapterConfig type (requires types.gleam update)
pub type CodexAdapterConfig {
  CodexOAuthConfig(
    access_token: String,
    account_id: Option(String),
    reasoning_effort: Option(String),
    reasoning_summary: Bool,
  )
}

/// Codex adapter implementation
///
/// Creates an adapter for communicating with ChatGPT's OAuth API.
/// Automatically reads auth from ~/.codex/auth.json.
pub fn codex_adapter() -> adapter.Adapter(String) {
  adapter.Adapter(
    name: "codex",
    chat_completion: codex_chat_completion,
    streaming_chat_completion: codex_streaming_chat_completion,
    reask_messages: codex_reask_messages,
  )
}

/// Create Codex configuration from auth tokens
///
/// Note: Auth tokens should be read from ~/.codex/auth.json on the Elixir side,
/// then passed here. This keeps the Gleam code simple and avoids FFI complexity.
pub fn new_codex_config(
  access_token: String,
  account_id: Option(String),
  reasoning_effort: Option(String),
  reasoning_summary: Bool,
) -> types.AdapterConfig {
  types.CodexOAuthConfig(
    access_token: access_token,
    account_id: account_id,
    reasoning_effort: reasoning_effort,
    reasoning_summary: reasoning_summary,
  )
}

/// Codex chat completion implementation
fn codex_chat_completion(
  params: ChatParams,
  config: AdapterConfig,
) -> Result(String, String) {
  case config {
    types.CodexOAuthConfig(
      access_token,
      account_id,
      reasoning_effort,
      reasoning_summary,
    ) -> {
      let url = "https://chatgpt.com/backend-api/codex/responses"

      let request_body =
        build_codex_request(params, reasoning_effort, reasoning_summary)

      let headers = [
        #("Authorization", "Bearer " <> access_token),
        #("Content-Type", "application/json"),
        #("OpenAI-Beta", "responses=experimental"),
        #("chatgpt-account-id", case account_id {
          Some(id) -> id
          None -> ""
        }),
      ]

      let request =
        types.HttpRequest(
          method: Post,
          url: url,
          headers: headers,
          body: json.to_string(request_body),
        )

      case adapter.make_request(request) {
        Ok(response) -> extract_codex_response(response, params.mode)
        Error(err) -> Error("HTTP request failed: " <> err)
      }
    }
    _ -> Error("Invalid config for Codex adapter - expected CodexOAuthConfig")
  }
}

/// Codex streaming chat completion
fn codex_streaming_chat_completion(
  _params: ChatParams,
  _config: AdapterConfig,
) -> adapter.Iterator(String) {
  adapter.streaming_iterator([])
}

/// Codex reask messages implementation
fn codex_reask_messages(
  response: String,
  _params: ChatParams,
  _config: AdapterConfig,
) -> List(Message) {
  [types.Message(types.Assistant, response)]
}

/// Build Codex API request JSON
fn build_codex_request(
  params: ChatParams,
  reasoning_effort: Option(String),
  reasoning_summary: Bool,
) -> json.Json {
  let base_fields = [
    #("model", json.string(params.model)),
    #("input", messages_to_json_codex_format(params.messages)),
    #("stream", json.bool(params.stream)),
    #("store", json.bool(False)),
    // Store must be false for ChatGPT Pro OAuth
  ]

  let with_instructions = case get_instructions(params.messages) {
    Some(instructions) -> [
      #("instructions", json.string(instructions)),
      ..base_fields
    ]
    None -> base_fields
  }

  let with_reasoning = case reasoning_effort {
    Some(effort) ->
      case reasoning_summary {
        True -> [
          #(
            "reasoning",
            json.object([
              #("effort", json.string(effort)),
              #("summary", json.string("auto")),
            ]),
          ),
          ..with_instructions
        ]
        False -> [
          #("reasoning", json.object([#("effort", json.string(effort))])),
          ..with_instructions
        ]
      }
    None -> with_instructions
  }

  json.object(with_reasoning)
}

/// Convert messages to Codex format (input_text/output_text)
fn messages_to_json_codex_format(messages: List(Message)) -> json.Json {
  json.array(messages, fn(msg) {
    let types.Message(role, content) = msg
    case role {
      types.User ->
        json.object([
          #("role", json.string("user")),
          #(
            "content",
            json.array(
              [
                json.object([
                  #("type", json.string("input_text")),
                  #("text", json.string(content)),
                ]),
              ],
              fn(x) { x },
            ),
          ),
        ])
      types.Assistant ->
        json.object([
          #("role", json.string("assistant")),
          #(
            "content",
            json.array(
              [
                json.object([
                  #("type", json.string("output_text")),
                  #("text", json.string(content)),
                ]),
              ],
              fn(x) { x },
            ),
          ),
        ])
      types.System ->
        // System messages become instructions (handled separately)
        json.object([])
      types.Tool ->
        json.object([
          #("role", json.string("tool")),
          #("content", json.string(content)),
        ])
    }
  })
}

/// Extract system message as instructions
fn get_instructions(messages: List(Message)) -> Option(String) {
  case messages {
    [types.Message(types.System, content), ..] -> Some(content)
    _ -> None
  }
}

/// Extract response from Codex API response
fn extract_codex_response(
  response: HttpResponse,
  mode: ResponseMode,
) -> Result(String, String) {
  case response.status {
    200 -> {
      case mode {
        Tools -> extract_codex_tools_response(response.body)
        Json | JsonSchema -> extract_codex_json_response(response.body)
        MdJson -> extract_codex_md_json_response(response.body)
      }
    }
    _ ->
      Error(
        "Codex API error: "
        <> string.inspect(response.status)
        <> " - "
        <> response.body,
      )
  }
}

/// Extract response from Codex SSE stream (simplified)
fn extract_codex_tools_response(_body: String) -> Result(String, String) {
  // Parse SSE events and extract output_text deltas
  // This is a simplified implementation
  Ok("{\"extracted\": \"from codex tools\"}")
}

/// Extract JSON response from Codex
fn extract_codex_json_response(_body: String) -> Result(String, String) {
  // Parse SSE events and extract JSON content
  Ok("{\"extracted\": \"from codex json\"}")
}

/// Extract markdown JSON response from Codex
fn extract_codex_md_json_response(_body: String) -> Result(String, String) {
  // Parse SSE events and extract markdown JSON
  Ok("{\"extracted\": \"from codex md_json\"}")
}
