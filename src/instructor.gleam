import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import instructor/adapter.{type Adapter}
import instructor/adapters/openai
import instructor/json_schema.{type JsonSchema}
import instructor/types.{
  type ChatParams, type LLMResult, type Message, type ResponseMode, type ValidationContext,
  ChatParams, Success, ValidationError, AdapterError, Tools
}
import instructor/validator.{type ValidationResult, type Validator, Valid, Invalid}

/// Main Instructor configuration
pub type InstructorConfig {
  InstructorConfig(
    adapter: Adapter(String),
    default_model: String,
    default_max_retries: Int,
  )
}

/// Response model configuration
pub type ResponseModel(a) {
  /// Single response validation
  Single(validator: Validator(a), schema: JsonSchema)
  /// Streaming partial responses
  Partial(validator: Validator(a), schema: JsonSchema)
  /// Streaming array of responses
  Array(validator: Validator(a), schema: JsonSchema)
}

/// Create default Instructor configuration
pub fn default_config() -> InstructorConfig {
  InstructorConfig(
    adapter: openai.openai_adapter(),
    default_model: "gpt-4o-mini",
    default_max_retries: 0,
  )
}

/// Create chat completion with validation
pub fn chat_completion(
  config: InstructorConfig,
  response_model: ResponseModel(a),
  messages: List(Message),
  model: Option(String),
  temperature: Option(Float),
  max_tokens: Option(Int),
  mode: Option(ResponseMode),
  max_retries: Option(Int),
  validation_context: Option(ValidationContext),
) -> LLMResult(a) {
  let actual_model = case model {
    Some(m) -> m
    None -> config.default_model
  }
  
  let actual_mode = case mode {
    Some(m) -> m
    None -> Tools
  }
  
  let actual_max_retries = case max_retries {
    Some(r) -> r
    None -> config.default_max_retries
  }
  
  let actual_validation_context = case validation_context {
    Some(ctx) -> ctx
    None -> []
  }
  
  let params = ChatParams(
    model: actual_model,
    messages: messages,
    temperature: temperature,
    max_tokens: max_tokens,
    stream: False,
    mode: actual_mode,
    max_retries: actual_max_retries,
    validation_context: actual_validation_context,
  )
  
  case response_model {
    Single(validator, schema) -> 
      do_single_chat_completion(config, params, validator, schema)
    Partial(validator, schema) ->
      do_partial_chat_completion(config, params, validator, schema)
    Array(validator, schema) ->
      do_array_chat_completion(config, params, validator, schema)
  }
}

/// Execute single chat completion
fn do_single_chat_completion(
  config: InstructorConfig,
  params: ChatParams,
  validator: Validator(a),
  schema: JsonSchema,
) -> LLMResult(a) {
  case config.adapter.chat_completion(params, types.OpenAIConfig("test", None)) {
    Ok(response) -> {
      case json.decode(response, dynamic.dynamic) {
        Ok(json_data) -> {
          case validator.validate_with_context(validator, json_data, params.validation_context) {
            Valid(validated_data) -> Success(validated_data)
            Invalid(errors) -> {
              case params.max_retries > 0 {
                True -> retry_with_errors(config, params, validator, schema, errors)
                False -> ValidationError(list.map(errors, fn(e) { e.message }))
              }
            }
          }
        }
        Error(_) -> AdapterError("Failed to parse JSON response")
      }
    }
    Error(err) -> AdapterError(err)
  }
}

/// Retry chat completion with validation errors
fn retry_with_errors(
  config: InstructorConfig,
  params: ChatParams,
  validator: Validator(a),
  schema: JsonSchema,
  errors: List(validator.ValidationError),
) -> LLMResult(a) {
  let error_message = validator.format_errors(errors)
  let retry_message = types.Message(
    types.System,
    "The response did not pass validation. Please try again and fix the following validation errors:\n\n" <> error_message
  )
  
  let updated_params = ChatParams(
    ..params,
    messages: list.append(params.messages, [retry_message]),
    max_retries: params.max_retries - 1,
  )
  
  do_single_chat_completion(config, updated_params, validator, schema)
}

/// Execute partial streaming chat completion (placeholder)
fn do_partial_chat_completion(
  config: InstructorConfig,
  params: ChatParams,
  validator: Validator(a),
  schema: JsonSchema,
) -> LLMResult(a) {
  // For now, delegate to single completion
  do_single_chat_completion(config, params, validator, schema)
}

/// Execute array streaming chat completion (placeholder)
fn do_array_chat_completion(
  config: InstructorConfig,
  params: ChatParams,
  validator: Validator(a),
  schema: JsonSchema,
) -> LLMResult(a) {
  // For now, delegate to single completion
  do_single_chat_completion(config, params, validator, schema)
}

/// Helper function to create a simple message
pub fn user_message(content: String) -> Message {
  types.Message(types.User, content)
}

/// Helper function to create a system message
pub fn system_message(content: String) -> Message {
  types.Message(types.System, content)
}

/// Helper function to create a simple string response model
pub fn string_response_model(description: String) -> ResponseModel(String) {
  let schema = json_schema.string_schema(Some(description))
  let validator = validator.string_validator()
  Single(validator, schema)
}

/// Helper function to create a simple integer response model
pub fn int_response_model(description: String) -> ResponseModel(Int) {
  let schema = json_schema.int_schema(Some(description))
  let validator = validator.int_validator()
  Single(validator, schema)
}

/// Helper function to create a simple boolean response model
pub fn bool_response_model(description: String) -> ResponseModel(Bool) {
  let schema = json_schema.bool_schema(Some(description))
  let validator = validator.bool_validator()
  Single(validator, schema)
}