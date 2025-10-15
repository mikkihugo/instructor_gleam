import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/option.{type Option}

/// HTTP request configuration
pub type HttpRequest {
  HttpRequest(
    method: http.Method,
    url: String,
    headers: List(#(String, String)),
    body: String,
  )
}

/// HTTP response
pub type HttpResponse {
  HttpResponse(
    status: Int,
    headers: List(#(String, String)),
    body: String,
  )
}

/// Response modes for LLM interactions
pub type ResponseMode {
  Tools
  Json
  JsonSchema
  MdJson
}

/// Chat message role
pub type Role {
  System
  User
  Assistant
  Tool
}

/// Chat message structure
pub type Message {
  Message(role: Role, content: String)
}

/// LLM response result
pub type LLMResult(a) {
  Success(a)
  ValidationError(List(String))
  AdapterError(String)
}

/// Validation context for LLM responses
pub type ValidationContext =
  List(#(String, dynamic.Dynamic))

/// Configuration for LLM adapters
pub type AdapterConfig {
  OpenAIConfig(api_key: String, base_url: Option(String))
  AnthropicConfig(api_key: String, base_url: Option(String))
  GeminiConfig(api_key: String, base_url: Option(String))
  GroqConfig(api_key: String, base_url: Option(String))
  OllamaConfig(base_url: String)
  LlamaCppConfig(base_url: String, chat_template: Option(String))
  VLLMConfig(base_url: String)
}

/// Parameters for chat completion
pub type ChatParams {
  ChatParams(
    model: String,
    messages: List(Message),
    temperature: Option(Float),
    max_tokens: Option(Int),
    stream: Bool,
    mode: ResponseMode,
    max_retries: Int,
    validation_context: ValidationContext,
  )
}

/// Convert Role to string for JSON serialization
pub fn role_to_string(role: Role) -> String {
  case role {
    System -> "system"
    User -> "user"
    Assistant -> "assistant"
    Tool -> "tool"
  }
}

/// Convert string to Role for JSON deserialization
pub fn string_to_role(s: String) -> Result(Role, Nil) {
  case s {
    "system" -> Ok(System)
    "user" -> Ok(User)
    "assistant" -> Ok(Assistant)
    "tool" -> Ok(Tool)
    _ -> Error(Nil)
  }
}

/// Convert ResponseMode to string
pub fn response_mode_to_string(mode: ResponseMode) -> String {
  case mode {
    Tools -> "tools"
    Json -> "json"
    JsonSchema -> "json_schema"
    MdJson -> "md_json"
  }
}

/// Convert Message to JSON
pub fn message_to_json(message: Message) -> json.Json {
  let Message(role, content) = message
  json.object([
    #("role", json.string(role_to_string(role))),
    #("content", json.string(content)),
  ])
}

/// Convert list of Messages to JSON
pub fn messages_to_json(messages: List(Message)) -> json.Json {
  json.array(messages, message_to_json)
}

fn role_decoder() -> decode.Decoder(Role) {
  decode.string
  |> decode.then(fn(s) {
    case string_to_role(s) {
      Ok(role) -> decode.success(role)
      Error(_) -> decode.failure(System, "Role")
    }
  })
}

/// Decoder for Message from JSON
pub fn message_decoder() -> decode.Decoder(Message) {
  {
    use role <- decode.field("role", role_decoder())
    use content <- decode.field("content", decode.string)
    decode.success(Message(role: role, content: content))
  }
}