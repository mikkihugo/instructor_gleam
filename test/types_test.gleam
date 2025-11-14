import gleam/http
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import instructor/types

pub fn main() {
  gleeunit.main()
}

// Test all Role to string conversions
pub fn role_to_string_system_test() {
  types.role_to_string(types.System) |> should.equal("system")
}

pub fn role_to_string_user_test() {
  types.role_to_string(types.User) |> should.equal("user")
}

pub fn role_to_string_assistant_test() {
  types.role_to_string(types.Assistant) |> should.equal("assistant")
}

pub fn role_to_string_tool_test() {
  types.role_to_string(types.Tool) |> should.equal("tool")
}

// Test all string to Role conversions
pub fn string_to_role_system_test() {
  types.string_to_role("system") |> should.equal(Ok(types.System))
}

pub fn string_to_role_user_test() {
  types.string_to_role("user") |> should.equal(Ok(types.User))
}

pub fn string_to_role_assistant_test() {
  types.string_to_role("assistant") |> should.equal(Ok(types.Assistant))
}

pub fn string_to_role_tool_test() {
  types.string_to_role("tool") |> should.equal(Ok(types.Tool))
}

pub fn string_to_role_invalid_test() {
  types.string_to_role("invalid") |> should.equal(Error(Nil))
}

// Test ResponseMode to string conversions
pub fn response_mode_tools_test() {
  types.response_mode_to_string(types.Tools) |> should.equal("tools")
}

pub fn response_mode_json_test() {
  types.response_mode_to_string(types.Json) |> should.equal("json")
}

pub fn response_mode_json_schema_test() {
  types.response_mode_to_string(types.JsonSchema) |> should.equal("json_schema")
}

pub fn response_mode_md_json_test() {
  types.response_mode_to_string(types.MdJson) |> should.equal("md_json")
}

// Test Message to JSON conversion
pub fn message_to_json_user_test() {
  let msg = types.Message(types.User, "Hello")
  let json_result = types.message_to_json(msg)
  let json_str = json.to_string(json_result)

  json_str |> should.not_equal("")
}

pub fn message_to_json_system_test() {
  let msg = types.Message(types.System, "You are a helpful assistant")
  let json_result = types.message_to_json(msg)
  let json_str = json.to_string(json_result)

  json_str |> should.not_equal("")
}

pub fn message_to_json_assistant_test() {
  let msg = types.Message(types.Assistant, "I can help you")
  let json_result = types.message_to_json(msg)
  let json_str = json.to_string(json_result)

  json_str |> should.not_equal("")
}

// Test messages to JSON conversion
pub fn messages_to_json_test() {
  let messages = [
    types.Message(types.System, "You are helpful"),
    types.Message(types.User, "Hello"),
    types.Message(types.Assistant, "Hi there!"),
  ]

  let json_result = types.messages_to_json(messages)
  let json_str = json.to_string(json_result)

  json_str |> should.not_equal("")
}

pub fn messages_to_json_empty_test() {
  let messages = []
  let json_result = types.messages_to_json(messages)
  let json_str = json.to_string(json_result)

  json_str |> should.equal("[]")
}

// Test Message decoder
pub fn message_decoder_user_test() {
  let json_str = "{\"role\":\"user\",\"content\":\"Hello\"}"
  case json.parse(json_str, types.message_decoder()) {
    Ok(types.Message(role, content)) -> {
      role |> should.equal(types.User)
      content |> should.equal("Hello")
    }
    Error(_) -> should.fail()
  }
}

pub fn message_decoder_system_test() {
  let json_str = "{\"role\":\"system\",\"content\":\"Be helpful\"}"
  case json.parse(json_str, types.message_decoder()) {
    Ok(types.Message(role, content)) -> {
      role |> should.equal(types.System)
      content |> should.equal("Be helpful")
    }
    Error(_) -> should.fail()
  }
}

pub fn message_decoder_assistant_test() {
  let json_str = "{\"role\":\"assistant\",\"content\":\"I'm here to help\"}"
  case json.parse(json_str, types.message_decoder()) {
    Ok(types.Message(role, content)) -> {
      role |> should.equal(types.Assistant)
      content |> should.equal("I'm here to help")
    }
    Error(_) -> should.fail()
  }
}

pub fn message_decoder_tool_test() {
  let json_str = "{\"role\":\"tool\",\"content\":\"Tool result\"}"
  case json.parse(json_str, types.message_decoder()) {
    Ok(types.Message(role, content)) -> {
      role |> should.equal(types.Tool)
      content |> should.equal("Tool result")
    }
    Error(_) -> should.fail()
  }
}

// Test HttpRequest creation
pub fn http_request_test() {
  let req =
    types.HttpRequest(
      method: http.Post,
      url: "https://api.example.com/chat",
      headers: [#("Authorization", "Bearer token")],
      body: "{\"message\":\"hello\"}",
    )

  req.url |> should.equal("https://api.example.com/chat")
  req.body |> should.equal("{\"message\":\"hello\"}")
}

// Test HttpResponse creation
pub fn http_response_test() {
  let resp =
    types.HttpResponse(
      status: 200,
      headers: [#("Content-Type", "application/json")],
      body: "{\"result\":\"success\"}",
    )

  resp.status |> should.equal(200)
  resp.body |> should.equal("{\"result\":\"success\"}")
}

// Test ChatParams creation
pub fn chat_params_test() {
  let params =
    types.ChatParams(
      model: "gpt-4",
      messages: [types.Message(types.User, "Hello")],
      temperature: Some(0.7),
      max_tokens: Some(1000),
      stream: False,
      mode: types.Tools,
      max_retries: 3,
      validation_context: [],
    )

  params.model |> should.equal("gpt-4")
  params.stream |> should.be_false()
  params.max_retries |> should.equal(3)
}

// Test LLMResult variants
pub fn llm_result_success_test() {
  let result: types.LLMResult(String) = types.Success("test result")

  case result {
    types.Success(data) -> data |> should.equal("test result")
    types.ValidationError(_) -> should.fail()
    types.AdapterError(_) -> should.fail()
  }
}

pub fn llm_result_validation_error_test() {
  let result: types.LLMResult(String) =
    types.ValidationError(["Error 1", "Error 2"])

  case result {
    types.ValidationError(errors) -> {
      case errors {
        ["Error 1", "Error 2"] -> True |> should.be_true()
        _ -> should.fail()
      }
    }
    types.Success(_) -> should.fail()
    types.AdapterError(_) -> should.fail()
  }
}

pub fn llm_result_adapter_error_test() {
  let result: types.LLMResult(String) = types.AdapterError("Connection failed")

  case result {
    types.AdapterError(msg) -> msg |> should.equal("Connection failed")
    types.Success(_) -> should.fail()
    types.ValidationError(_) -> should.fail()
  }
}

// Test AdapterConfig variants
pub fn adapter_config_openai_test() {
  let config = types.OpenAIConfig("test-key", Some("https://custom.api"))

  case config {
    types.OpenAIConfig(api_key, base_url) -> {
      api_key |> should.equal("test-key")
      base_url |> should.equal(Some("https://custom.api"))
    }
  }
}

pub fn adapter_config_anthropic_test() {
  let config = types.AnthropicConfig("test-key", None)

  case config {
    types.AnthropicConfig(api_key, base_url) -> {
      api_key |> should.equal("test-key")
      base_url |> should.equal(None)
    }
  }
}

pub fn adapter_config_gemini_test() {
  let config = types.GeminiConfig("test-key", None)

  case config {
    types.GeminiConfig(api_key, base_url) -> {
      api_key |> should.equal("test-key")
      base_url |> should.equal(None)
    }
  }
}

pub fn adapter_config_groq_test() {
  let config = types.GroqConfig("test-key", None)

  case config {
    types.GroqConfig(api_key, base_url) -> {
      api_key |> should.equal("test-key")
      base_url |> should.equal(None)
    }
  }
}

pub fn adapter_config_ollama_test() {
  let config = types.OllamaConfig("http://localhost:11434")

  case config {
    types.OllamaConfig(base_url) ->
      base_url |> should.equal("http://localhost:11434")
  }
}

pub fn adapter_config_llamacpp_test() {
  let config = types.LlamaCppConfig("http://localhost:8080", Some("llama3"))

  case config {
    types.LlamaCppConfig(base_url, chat_template) -> {
      base_url |> should.equal("http://localhost:8080")
      chat_template |> should.equal(Some("llama3"))
    }
  }
}

pub fn adapter_config_vllm_test() {
  let config = types.VLLMConfig("http://localhost:8000")

  case config {
    types.VLLMConfig(base_url) ->
      base_url |> should.equal("http://localhost:8000")
  }
}
