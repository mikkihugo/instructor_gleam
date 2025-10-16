//// HTTP client utilities for making API requests
////
//// This module provides a thin wrapper around gleam_httpc for making HTTP requests
//// to LLM provider APIs. It handles request construction, header management,
//// and error formatting.

import gleam/http/request
import gleam/httpc
import gleam/list
import gleam/string
import instructor/types.{type HttpRequest, type HttpResponse, HttpResponse}

/// Make an HTTP request using gleam_httpc
/// 
/// Takes a simplified HttpRequest and executes it using the gleam_httpc library.
/// Returns either a successful HttpResponse or an error message.
pub fn make_http_request(req: HttpRequest) -> Result(HttpResponse, String) {
  // Create the HTTP request
  case request.to(req.url) {
    Ok(http_request) -> {
      let updated_request =
        http_request
        |> request.set_method(req.method)
        |> request.set_body(req.body)
        |> set_headers(req.headers)

      // Make the request
      case httpc.send(updated_request) {
        Ok(http_response) -> {
          Ok(HttpResponse(
            status: http_response.status,
            headers: http_response.headers,
            body: http_response.body,
          ))
        }
        Error(err) -> Error("HTTP request failed: " <> string.inspect(err))
      }
    }
    Error(err) -> Error("Invalid URL: " <> string.inspect(err))
  }
}

/// Set headers on an HTTP request
fn set_headers(
  req: request.Request(String),
  headers: List(#(String, String)),
) -> request.Request(String) {
  case headers {
    [] -> req
    [#(name, value), ..rest] ->
      req
      |> request.set_header(name, value)
      |> set_headers(rest)
  }
}

/// Extract error message from HTTP response
pub fn extract_error_message(response: HttpResponse) -> String {
  case response.status {
    400 -> "Bad Request: " <> response.body
    401 -> "Unauthorized: Check your API key"
    403 -> "Forbidden: Insufficient permissions"
    404 -> "Not Found: Invalid endpoint or model"
    429 -> "Rate Limited: Too many requests"
    500 -> "Internal Server Error: " <> response.body
    502 -> "Bad Gateway: Service temporarily unavailable"
    503 -> "Service Unavailable: " <> response.body
    _ -> "HTTP " <> string.inspect(response.status) <> ": " <> response.body
  }
}

/// Check if HTTP status indicates success
pub fn is_success_status(status: Int) -> Bool {
  status >= 200 && status < 300
}

/// Retry HTTP request with exponential backoff
pub fn retry_request(
  req: HttpRequest,
  max_retries: Int,
  current_retry: Int,
) -> Result(HttpResponse, String) {
  case current_retry >= max_retries {
    True -> Error("Max retries exceeded")
    False -> {
      case make_http_request(req) {
        Ok(response) -> {
          case is_success_status(response.status) {
            True -> Ok(response)
            False -> {
              // Retry on server errors (5xx) but not client errors (4xx)
              case response.status >= 500 {
                True -> retry_request(req, max_retries, current_retry + 1)
                False -> Error(extract_error_message(response))
              }
            }
          }
        }
        Error(err) -> {
          case current_retry < max_retries - 1 {
            True -> retry_request(req, max_retries, current_retry + 1)
            False -> Error(err)
          }
        }
      }
    }
  }
}

/// Add common headers for LLM APIs
pub fn add_common_headers(
  headers: List(#(String, String)),
  user_agent: String,
) -> List(#(String, String)) {
  [#("User-Agent", user_agent), #("Accept", "application/json"), ..headers]
}

/// Validate URL format
pub fn validate_url(url: String) -> Result(String, String) {
  case
    string.starts_with(url, "http://") || string.starts_with(url, "https://")
  {
    True -> Ok(url)
    False -> Error("URL must start with http:// or https://")
  }
}

/// Build base URL for API endpoints
pub fn build_api_url(base_url: String, endpoint: String) -> String {
  let trimmed_base = case string.ends_with(base_url, "/") {
    True -> string.drop_end(base_url, 1)
    False -> base_url
  }
  let trimmed_endpoint = case string.starts_with(endpoint, "/") {
    True -> string.drop_start(endpoint, 1)
    False -> endpoint
  }
  trimmed_base <> "/" <> trimmed_endpoint
}

/// Parse content-type header
pub fn parse_content_type(headers: List(#(String, String))) -> String {
  case
    list.find(headers, fn(header) {
      let #(name, _) = header
      string.lowercase(name) == "content-type"
    })
  {
    Ok(#(_, content_type)) -> content_type
    Error(_) -> "application/json"
    // Default
  }
}

/// Check if response is JSON
pub fn is_json_response(headers: List(#(String, String))) -> Bool {
  let content_type = parse_content_type(headers)
  string.contains(content_type, "application/json")
}

/// Check if response is streaming
pub fn is_streaming_response(headers: List(#(String, String))) -> Bool {
  let content_type = parse_content_type(headers)
  string.contains(content_type, "text/stream")
  || string.contains(content_type, "text/event-stream")
}
