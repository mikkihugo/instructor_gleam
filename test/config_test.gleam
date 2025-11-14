import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import instructor/config
import instructor/types

pub fn main() {
  gleeunit.main()
}

// Test default config creation
pub fn default_config_test() {
  let cfg = config.default_config()
  cfg.default_model |> should.equal("gpt-4o-mini")
  cfg.default_max_retries |> should.equal(0)
  cfg.timeout_ms |> should.equal(30_000)
  cfg.user_agent |> should.equal("instructor-gleam/1.0.0")
}

// Test OpenAI config creation
pub fn openai_config_test() {
  let cfg = config.openai_config("test-key", None)
  cfg.default_model |> should.equal("gpt-4o-mini")

  case cfg.default_adapter {
    types.OpenAIConfig(api_key, _) -> api_key |> should.equal("test-key")
    _ -> should.fail()
  }
}

// Test OpenAI config with base URL
pub fn openai_config_with_base_url_test() {
  let cfg = config.openai_config("test-key", Some("https://custom.api.com"))

  case cfg.default_adapter {
    types.OpenAIConfig(api_key, base_url) -> {
      api_key |> should.equal("test-key")
      base_url |> should.equal(Some("https://custom.api.com"))
    }
    _ -> should.fail()
  }
}

// Test Anthropic config creation
pub fn anthropic_config_test() {
  let cfg = config.anthropic_config("test-key", None)
  cfg.default_model |> should.equal("claude-sonnet-4")

  case cfg.default_adapter {
    types.AnthropicConfig(api_key, _) -> api_key |> should.equal("test-key")
    _ -> should.fail()
  }
}

// Test Gemini config creation
pub fn gemini_config_test() {
  let cfg = config.gemini_config("test-key", None)
  cfg.default_model |> should.equal("gemini-2.5-flash")

  case cfg.default_adapter {
    types.GeminiConfig(api_key, _) -> api_key |> should.equal("test-key")
    _ -> should.fail()
  }
}

// Test Groq config creation
pub fn groq_config_test() {
  let cfg = config.groq_config("test-key", None)
  cfg.default_model |> should.equal("llama-3.3-70b-versatile")

  case cfg.default_adapter {
    types.GroqConfig(api_key, _) -> api_key |> should.equal("test-key")
    _ -> should.fail()
  }
}

// Test Ollama config creation
pub fn ollama_config_test() {
  let cfg = config.ollama_config("http://localhost:11434")
  cfg.default_model |> should.equal("llama3.2")

  case cfg.default_adapter {
    types.OllamaConfig(base_url) ->
      base_url |> should.equal("http://localhost:11434")
    _ -> should.fail()
  }
}

// Test with_model configuration
pub fn with_model_test() {
  let cfg =
    config.default_config()
    |> config.with_model("gpt-4")

  cfg.default_model |> should.equal("gpt-4")
}

// Test with_temperature configuration
pub fn with_temperature_test() {
  let cfg =
    config.default_config()
    |> config.with_temperature(0.7)

  cfg.default_temperature |> should.equal(Some(0.7))
}

// Test with_max_tokens configuration
pub fn with_max_tokens_test() {
  let cfg =
    config.default_config()
    |> config.with_max_tokens(1000)

  cfg.default_max_tokens |> should.equal(Some(1000))
}

// Test with_max_retries configuration
pub fn with_max_retries_test() {
  let cfg =
    config.default_config()
    |> config.with_max_retries(3)

  cfg.default_max_retries |> should.equal(3)
}

// Test with_timeout configuration
pub fn with_timeout_test() {
  let cfg =
    config.default_config()
    |> config.with_timeout(60_000)

  cfg.timeout_ms |> should.equal(60_000)
}

// Test validate_config with valid OpenAI config
pub fn validate_openai_config_test() {
  let cfg = config.openai_config("valid-key", None)

  case config.validate_config(cfg) {
    Ok(_) -> True |> should.be_true()
    Error(_) -> should.fail()
  }
}

// Test validate_config with empty OpenAI key
pub fn validate_empty_openai_key_test() {
  let cfg = config.openai_config("", None)

  case config.validate_config(cfg) {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.equal("OpenAI API key is required")
  }
}

// Test validate_config with empty Anthropic key
pub fn validate_empty_anthropic_key_test() {
  let cfg = config.anthropic_config("", None)

  case config.validate_config(cfg) {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.equal("Anthropic API key is required")
  }
}

// Test validate_config with empty Gemini key
pub fn validate_empty_gemini_key_test() {
  let cfg = config.gemini_config("", None)

  case config.validate_config(cfg) {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.equal("Gemini API key is required")
  }
}

// Test validate_config with empty Groq key
pub fn validate_empty_groq_key_test() {
  let cfg = config.groq_config("", None)

  case config.validate_config(cfg) {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.equal("Groq API key is required")
  }
}

// Test validate_config with empty Ollama base URL
pub fn validate_empty_ollama_base_url_test() {
  let cfg = config.ollama_config("")

  case config.validate_config(cfg) {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.equal("Ollama base URL is required")
  }
}

// Test get_adapter_name
pub fn get_adapter_name_openai_test() {
  let cfg = config.openai_config("test-key", None)
  config.get_adapter_name(cfg) |> should.equal("openai")
}

pub fn get_adapter_name_anthropic_test() {
  let cfg = config.anthropic_config("test-key", None)
  config.get_adapter_name(cfg) |> should.equal("anthropic")
}

pub fn get_adapter_name_gemini_test() {
  let cfg = config.gemini_config("test-key", None)
  config.get_adapter_name(cfg) |> should.equal("gemini")
}

pub fn get_adapter_name_groq_test() {
  let cfg = config.groq_config("test-key", None)
  config.get_adapter_name(cfg) |> should.equal("groq")
}

pub fn get_adapter_name_ollama_test() {
  let cfg = config.ollama_config("http://localhost:11434")
  config.get_adapter_name(cfg) |> should.equal("ollama")
}

// Test supports_streaming
pub fn supports_streaming_openai_test() {
  let cfg = config.openai_config("test-key", None)
  config.supports_streaming(cfg) |> should.be_true()
}

pub fn supports_streaming_anthropic_test() {
  let cfg = config.anthropic_config("test-key", None)
  config.supports_streaming(cfg) |> should.be_true()
}

pub fn supports_streaming_gemini_test() {
  let cfg = config.gemini_config("test-key", None)
  config.supports_streaming(cfg) |> should.be_true()
}

pub fn supports_streaming_ollama_test() {
  let cfg = config.ollama_config("http://localhost:11434")
  config.supports_streaming(cfg) |> should.be_true()
}

// Test supports_function_calling
pub fn supports_function_calling_openai_test() {
  let cfg = config.openai_config("test-key", None)
  config.supports_function_calling(cfg) |> should.be_true()
}

pub fn supports_function_calling_anthropic_test() {
  let cfg = config.anthropic_config("test-key", None)
  config.supports_function_calling(cfg) |> should.be_true()
}

pub fn supports_function_calling_gemini_test() {
  let cfg = config.gemini_config("test-key", None)
  config.supports_function_calling(cfg) |> should.be_true()
}

pub fn supports_function_calling_groq_test() {
  let cfg = config.groq_config("test-key", None)
  config.supports_function_calling(cfg) |> should.be_true()
}

pub fn supports_function_calling_ollama_test() {
  let cfg = config.ollama_config("http://localhost:11434")
  config.supports_function_calling(cfg) |> should.be_false()
}

// Test get_recommended_models
pub fn get_recommended_models_openai_test() {
  let cfg = config.openai_config("test-key", None)
  let models = config.get_recommended_models(cfg)

  // Should have at least 5 models
  case models {
    [_, _, _, _, _, ..] -> True |> should.be_true()
    _ -> should.fail()
  }
}

pub fn get_recommended_models_anthropic_test() {
  let cfg = config.anthropic_config("test-key", None)
  let models = config.get_recommended_models(cfg)

  // Should have at least 4 models
  case models {
    [_, _, _, _, ..] -> True |> should.be_true()
    _ -> should.fail()
  }
}

pub fn get_recommended_models_ollama_test() {
  let cfg = config.ollama_config("http://localhost:11434")
  let models = config.get_recommended_models(cfg)

  // Should have at least 5 models
  case models {
    [_, _, _, _, _, ..] -> True |> should.be_true()
    _ -> should.fail()
  }
}
