//// Adapter pattern for LLM providers
////
//// This module defines the adapter interface that all LLM providers implement.
//// It provides a consistent way to interact with different LLM providers
//// (OpenAI, Anthropic, Gemini, Groq, Ollama, etc.) through a unified interface.
////
//// ## Example
////
//// ```gleam
//// import instructor/adapter
//// import instructor/adapters/openai
////
//// let openai = openai.openai_adapter()
//// // Use the adapter for chat completion
//// ```

import gleam/list
import instructor/http_client
import instructor/types.{type AdapterConfig, type ChatParams}

/// Adapter behavior for LLM providers
/// 
/// An adapter encapsulates the logic for communicating with a specific LLM provider,
/// including request formatting, response parsing, and error handling.
pub type Adapter(a) {
  Adapter(
    name: String,
    chat_completion: fn(ChatParams, AdapterConfig) -> Result(String, String),
    streaming_chat_completion: fn(ChatParams, AdapterConfig) -> Iterator(String),
    reask_messages: fn(String, ChatParams, AdapterConfig) -> List(types.Message),
  )
}

/// Iterator type for streaming responses
pub type Iterator(a) {
  Iterator(next: fn() -> Result(#(a, Iterator(a)), Nil))
}

/// Make an HTTP request
pub fn make_request(
  request: types.HttpRequest,
) -> Result(types.HttpResponse, String) {
  // Use the actual HTTP client implementation
  http_client.make_http_request(request)
}

/// Create a basic streaming iterator
pub fn streaming_iterator(items: List(a)) -> Iterator(a) {
  case items {
    [] -> Iterator(fn() { Error(Nil) })
    [first, ..rest] -> Iterator(fn() { Ok(#(first, streaming_iterator(rest))) })
  }
}

/// Convert iterator to list
pub fn iterator_to_list(iterator: Iterator(a)) -> List(a) {
  iterator_to_list_helper(iterator, [])
}

fn iterator_to_list_helper(iterator: Iterator(a), acc: List(a)) -> List(a) {
  case iterator.next() {
    Ok(#(item, next_iterator)) ->
      iterator_to_list_helper(next_iterator, [item, ..acc])
    Error(Nil) -> acc |> list.reverse()
  }
}

/// Create a mock adapter for testing
pub fn mock_adapter() -> Adapter(String) {
  Adapter(
    name: "mock",
    chat_completion: fn(_params, _config) {
      Ok("{\"result\": \"mock response\"}")
    },
    streaming_chat_completion: fn(_params, _config) {
      streaming_iterator(["{\"partial\": true}", "{\"result\": \"final\"}"])
    },
    reask_messages: fn(_response, _params, _config) { [] },
  )
}
