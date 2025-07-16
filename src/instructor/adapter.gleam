import gleam/http
import gleam/list
import gleam/result
import instructor/types.{type AdapterConfig, type ChatParams, type LLMResult}
import instructor/http_client

/// Adapter behavior for LLM providers
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

/// Make an HTTP request
pub fn make_request(request: HttpRequest) -> Result(HttpResponse, String) {
  // Use the actual HTTP client implementation
  http_client.make_http_request(request)
}

/// Create a basic streaming iterator
pub fn streaming_iterator(items: List(a)) -> Iterator(a) {
  case items {
    [] -> Iterator(fn() { Error(Nil) })
    [first, ..rest] -> Iterator(fn() { 
      Ok(#(first, streaming_iterator(rest)))
    })
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
    Error(Nil) -> 
      acc |> list.reverse()
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
    reask_messages: fn(_response, _params, _config) {
      []
    },
  )
}