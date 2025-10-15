import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import instructor/adapter.{type Adapter}
import instructor/adapters/openai
import instructor/types.{
  type ChatParams, type LLMResult, type Message, type ResponseMode,
  type ValidationContext, ChatParams, Success, ValidationError, AdapterError,
  Tools,
}

pub type Validator(a) = decode.Decoder(a)

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
  Single(validator: Validator(a))
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
    Single(validator) -> do_single_chat_completion(config, params, validator)
  }
}

fn format_decode_error(error: decode.DecodeError) -> String {
  let path = string.join(error.path, ".")
  "Expected " <> error.expected <> " but found " <> error.found <> " at path " <> path
}

/// Execute single chat completion
fn do_single_chat_completion(
  config: InstructorConfig,
  params: ChatParams,
  validator: Validator(a),
) -> LLMResult(a) {
  case config.adapter.chat_completion(params, types.OpenAIConfig("test", None)) {
    Ok(response) -> {
      case json.parse(response, using: validator) {
        Ok(validated_data) -> Success(validated_data)
        Error(json.UnableToDecode(errors)) -> {
          case params.max_retries > 0 {
            True -> retry_with_errors(config, params, validator, errors)
            False -> ValidationError(list.map(errors, format_decode_error))
          }
        }
        Error(json.UnexpectedEndOfInput) ->
          AdapterError("Failed to parse JSON: Unexpected end of input")
        Error(json.UnexpectedByte(byte)) ->
          AdapterError("Failed to parse JSON: Unexpected byte " <> byte)
        Error(json.UnexpectedSequence(seq)) ->
          AdapterError("Failed to parse JSON: Unexpected sequence " <> seq)
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
  errors: List(decode.DecodeError),
) -> LLMResult(a) {
  let error_message =
    errors
    |> list.map(format_decode_error)
    |> string.join("\n")
  let retry_message =
    types.Message(
      types.System,
      "The response did not pass validation. Please try again and fix the following validation errors:\n\n"
        <> error_message,
    )

  let updated_params =
    ChatParams(
      ..params,
      messages: list.append(params.messages, [retry_message]),
      max_retries: params.max_retries - 1,
    )

  do_single_chat_completion(config, updated_params, validator)
}

/// Creates a user message.
pub fn user_message(content: String) -> Message {
  types.Message(types.User, content)
}

/// Creates a system message.
pub fn system_message(content: String) -> Message {
  types.Message(types.System, content)
}

/// Helper function to create a simple string response model
pub fn string_response_model(_description: String) -> ResponseModel(String) {
  Single(validator: decode.string)
}

/// Helper function to create a simple integer response model
pub fn int_response_model(_description: String) -> ResponseModel(Int) {
  Single(validator: decode.int)
}

/// Helper function to create a simple boolean response model
pub fn bool_response_model(_description: String) -> ResponseModel(Bool) {
  Single(validator: decode.bool)
}