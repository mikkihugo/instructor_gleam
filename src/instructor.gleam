//// Instructor for Gleam - Structured Prompting for Large Language Models
////
//// This module provides the main API for interacting with LLMs using structured
//// prompting. It converts LLM text outputs into validated data structures, enabling
//// seamless integration between AI and traditional Gleam applications.
////
//// ## Features
////
//// - **Structured Prompting**: Define response schemas and get validated structured data from LLMs
//// - **Multiple LLM Providers**: Support for OpenAI, Anthropic, Gemini, Groq, and Ollama
//// - **Validation & Retry Logic**: Automatic retry with error feedback when responses don't match schemas
//// - **Streaming Support**: Handle partial and array streaming responses
//// - **Type Safe**: Full Gleam type safety for LLM interactions
////
//// ## Example
////
//// ```gleam
//// import instructor
//// import instructor/types
////
//// // Create configuration
//// let config = instructor.default_config()
////
//// // Create a response model
//// let response_model = instructor.string_response_model("Extract the sentiment")
////
//// // Make a chat completion
//// let messages = [instructor.user_message("I love Gleam programming!")]
////
//// case instructor.chat_completion(
////   config,
////   response_model,
////   messages,
////   None, None, None, None, None, None,
//// ) {
////   types.Success(result) -> io.println("Result: " <> result)
////   types.ValidationError(errors) -> io.println("Validation failed")
////   types.AdapterError(error) -> io.println("API error")
//// }
//// ```

import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import instructor/adapter.{type Adapter}
import instructor/adapters/openai
import instructor/json_parser
import instructor/sse_parser
import instructor/types.{
  type ChatParams, type LLMResult, type Message, type ResponseMode,
  type ValidationContext, AdapterError, ChatParams, Success, Tools,
  ValidationError,
}

/// A validator is a decoder that can parse and validate dynamic data
pub type Validator(a) =
  decode.Decoder(a)

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
  /// Streaming partial responses
  Partial(validator: Validator(a))
  /// Streaming array of responses
  Array(validator: Validator(a))
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

  let params =
    ChatParams(
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
    Partial(validator) -> do_partial_chat_completion(config, params, validator)
    Array(validator) -> do_array_chat_completion(config, params, validator)
  }
}

fn format_decode_error(error: decode.DecodeError) -> String {
  let path = string.join(error.path, ".")
  "Expected "
  <> error.expected
  <> " but found "
  <> error.found
  <> " at path "
  <> path
}

/// Execute single chat completion
fn do_single_chat_completion(
  config: InstructorConfig,
  params: ChatParams,
  validator: Validator(a),
) -> LLMResult(a) {
  case
    config.adapter.chat_completion(params, types.OpenAIConfig("test", None))
  {
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

/// Execute partial streaming chat completion
fn do_partial_chat_completion(
  config: InstructorConfig,
  params: ChatParams,
  validator: Validator(a),
) -> LLMResult(a) {
  // Enable streaming in params
  let streaming_params = ChatParams(..params, stream: True)

  // Get streaming iterator from adapter
  let stream_iterator =
    config.adapter.streaming_chat_completion(
      streaming_params,
      types.OpenAIConfig("test", None),
    )

  // Create an initial empty object as dynamic value by parsing empty JSON
  let assert Ok(initial_value) = json.parse("{}", using: decode.dynamic)

  // Process streaming chunks
  process_partial_stream(stream_iterator, validator, initial_value)
}

/// Process partial streaming responses
fn process_partial_stream(
  iterator: adapter.Iterator(String),
  validator: Validator(a),
  previous: dynamic.Dynamic,
) -> LLMResult(a) {
  case iterator.next() {
    Error(Nil) -> {
      // Stream ended, validate the final result
      case decode.run(previous, validator) {
        Ok(result) -> Success(result)
        Error(errors) -> ValidationError(list.map(errors, format_decode_error))
      }
    }
    Ok(#(chunk, next_iterator)) -> {
      // Parse SSE events from chunk
      let events = sse_parser.parse_sse_stream(chunk)

      // Extract and merge JSON data
      let updated = case events {
        [] -> previous
        _ -> {
          let data_events = sse_parser.extract_data_events(events)
          case data_events {
            [] -> previous
            [first, ..] -> {
              // Parse the JSON and merge with previous
              case json.parse(first, using: decode.dynamic) {
                Ok(parsed) ->
                  json_parser.merge_partial_objects(previous, parsed)
                Error(_) -> previous
              }
            }
          }
        }
      }

      // Continue processing stream
      process_partial_stream(next_iterator, validator, updated)
    }
  }
}

/// Execute array streaming chat completion
fn do_array_chat_completion(
  config: InstructorConfig,
  params: ChatParams,
  validator: Validator(a),
) -> LLMResult(a) {
  // Enable streaming in params
  let streaming_params = ChatParams(..params, stream: True)

  // Get streaming iterator from adapter
  let stream_iterator =
    config.adapter.streaming_chat_completion(
      streaming_params,
      types.OpenAIConfig("test", None),
    )

  // Process streaming chunks for array
  process_array_stream(stream_iterator, validator, [])
}

/// Process array streaming responses
fn process_array_stream(
  iterator: adapter.Iterator(String),
  validator: Validator(a),
  accumulated: List(dynamic.Dynamic),
) -> LLMResult(a) {
  case iterator.next() {
    Error(Nil) -> {
      // Stream ended, validate accumulated items
      case accumulated {
        [] -> ValidationError(["No items received from stream"])
        [item, ..] -> {
          // Validate the first complete item as the result
          case decode.run(item, validator) {
            Ok(result) -> Success(result)
            Error(errors) ->
              ValidationError(list.map(errors, format_decode_error))
          }
        }
      }
    }
    Ok(#(chunk, next_iterator)) -> {
      // Parse SSE events from chunk
      let events = sse_parser.parse_sse_stream(chunk)

      // Extract new items from the stream
      let new_items = case events {
        [] -> []
        _ -> {
          let data_events = sse_parser.extract_data_events(events)
          list.flat_map(data_events, fn(data) {
            json_parser.parse_partial_objects(data)
          })
        }
      }

      // Append new items and continue
      let updated = list.append(accumulated, new_items)
      process_array_stream(next_iterator, validator, updated)
    }
  }
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
