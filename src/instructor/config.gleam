import gleam/option.{type Option, None, Some}
import instructor/types

/// Global configuration for Instructor
pub type Config {
  Config(
    default_adapter: types.AdapterConfig,
    default_model: String,
    default_max_retries: Int,
    default_temperature: Option(Float),
    default_max_tokens: Option(Int),
    timeout_ms: Int,
    user_agent: String,
  )
}

/// Create default configuration with OpenAI
pub fn default_config() -> Config {
  Config(
    default_adapter: types.OpenAIConfig(
      api_key: get_env_var("OPENAI_API_KEY", ""),
      base_url: None,
    ),
    default_model: "gpt-4o-mini",
    default_max_retries: 0,
    default_temperature: None,
    default_max_tokens: None,
    timeout_ms: 30_000,
    user_agent: "instructor-gleam/1.0.0",
  )
}

/// Create configuration for OpenAI
pub fn openai_config(api_key: String, base_url: Option(String)) -> Config {
  Config(
    ..default_config(),
    default_adapter: types.OpenAIConfig(api_key, base_url),
  )
}

/// Create configuration for Anthropic
pub fn anthropic_config(api_key: String, base_url: Option(String)) -> Config {
  Config(
    ..default_config(),
    default_adapter: types.AnthropicConfig(api_key, base_url),
    default_model: "claude-3-haiku-20240307",
  )
}

/// Create configuration for Gemini
pub fn gemini_config(api_key: String, base_url: Option(String)) -> Config {
  Config(
    ..default_config(),
    default_adapter: types.GeminiConfig(api_key, base_url),
    default_model: "gemini-pro",
  )
}

/// Create configuration for Ollama
pub fn ollama_config(base_url: String) -> Config {
  Config(
    ..default_config(),
    default_adapter: types.OllamaConfig(base_url),
    default_model: "llama2",
  )
}

/// Set default model for configuration
pub fn with_model(config: Config, model: String) -> Config {
  Config(..config, default_model: model)
}

/// Set default temperature for configuration
pub fn with_temperature(config: Config, temperature: Float) -> Config {
  Config(..config, default_temperature: Some(temperature))
}

/// Set default max tokens for configuration
pub fn with_max_tokens(config: Config, max_tokens: Int) -> Config {
  Config(..config, default_max_tokens: Some(max_tokens))
}

/// Set max retries for configuration
pub fn with_max_retries(config: Config, max_retries: Int) -> Config {
  Config(..config, default_max_retries: max_retries)
}

/// Set timeout for configuration
pub fn with_timeout(config: Config, timeout_ms: Int) -> Config {
  Config(..config, timeout_ms: timeout_ms)
}

/// Get environment variable with default
fn get_env_var(_name: String, default: String) -> String {
  // In a real implementation, this would read from environment
  // For now, return the default
  default
}

/// Validate configuration
pub fn validate_config(config: Config) -> Result(Config, String) {
  case config.default_adapter {
    types.OpenAIConfig(api_key, _) -> {
      case api_key == "" {
        True -> Error("OpenAI API key is required")
        False -> Ok(config)
      }
    }
    types.AnthropicConfig(api_key, _) -> {
      case api_key == "" {
        True -> Error("Anthropic API key is required")
        False -> Ok(config)
      }
    }
    types.GeminiConfig(api_key, _) -> {
      case api_key == "" {
        True -> Error("Gemini API key is required")
        False -> Ok(config)
      }
    }
    types.OllamaConfig(base_url) -> {
      case base_url == "" {
        True -> Error("Ollama base URL is required")
        False -> Ok(config)
      }
    }
    _ -> Ok(config)
  }
}

/// Get adapter name from config
pub fn get_adapter_name(config: Config) -> String {
  case config.default_adapter {
    types.OpenAIConfig(_, _) -> "openai"
    types.AnthropicConfig(_, _) -> "anthropic"
    types.GeminiConfig(_, _) -> "gemini"
    types.OllamaConfig(_) -> "ollama"
    _ -> "unknown"
  }
}

/// Check if adapter supports streaming
pub fn supports_streaming(config: Config) -> Bool {
  case config.default_adapter {
    types.OpenAIConfig(_, _) -> True
    types.AnthropicConfig(_, _) -> True
    types.GeminiConfig(_, _) -> True
    types.OllamaConfig(_) -> True
    _ -> False
  }
}

/// Check if adapter supports function calling
pub fn supports_function_calling(config: Config) -> Bool {
  case config.default_adapter {
    types.OpenAIConfig(_, _) -> True
    types.AnthropicConfig(_, _) -> True
    types.GeminiConfig(_, _) -> True
    types.OllamaConfig(_) -> False
    // Most Ollama models don't support function calling
    _ -> False
  }
}

/// Get recommended models for adapter
pub fn get_recommended_models(config: Config) -> List(String) {
  case config.default_adapter {
    types.OpenAIConfig(_, _) -> [
      "gpt-4o",
      "gpt-4o-mini",
      "gpt-4-turbo",
      "gpt-3.5-turbo",
    ]
    types.AnthropicConfig(_, _) -> [
      "claude-3-5-sonnet-20241022",
      "claude-3-opus-20240229",
      "claude-3-sonnet-20240229",
      "claude-3-haiku-20240307",
    ]
    types.GeminiConfig(_, _) -> [
      "gemini-1.5-pro",
      "gemini-1.5-flash",
      "gemini-pro",
    ]
    types.OllamaConfig(_) -> [
      "llama2",
      "llama2:13b",
      "codellama",
      "mistral",
      "neural-chat",
    ]
    _ -> []
  }
}
