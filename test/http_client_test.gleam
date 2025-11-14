import gleeunit
import gleeunit/should
import instructor/http_client
import instructor/types

pub fn main() {
  gleeunit.main()
}

// Test extract_error_message for different status codes
pub fn extract_error_message_400_test() {
  let response = types.HttpResponse(400, [], "Bad request body")
  let msg = http_client.extract_error_message(response)

  msg |> should.equal("Bad Request: Bad request body")
}

pub fn extract_error_message_401_test() {
  let response = types.HttpResponse(401, [], "")
  let msg = http_client.extract_error_message(response)

  msg |> should.equal("Unauthorized: Check your API key")
}

pub fn extract_error_message_403_test() {
  let response = types.HttpResponse(403, [], "")
  let msg = http_client.extract_error_message(response)

  msg |> should.equal("Forbidden: Insufficient permissions")
}

pub fn extract_error_message_404_test() {
  let response = types.HttpResponse(404, [], "")
  let msg = http_client.extract_error_message(response)

  msg |> should.equal("Not Found: Invalid endpoint or model")
}

pub fn extract_error_message_429_test() {
  let response = types.HttpResponse(429, [], "")
  let msg = http_client.extract_error_message(response)

  msg |> should.equal("Rate Limited: Too many requests")
}

pub fn extract_error_message_500_test() {
  let response = types.HttpResponse(500, [], "Server error details")
  let msg = http_client.extract_error_message(response)

  msg |> should.equal("Internal Server Error: Server error details")
}

pub fn extract_error_message_502_test() {
  let response = types.HttpResponse(502, [], "")
  let msg = http_client.extract_error_message(response)

  msg |> should.equal("Bad Gateway: Service temporarily unavailable")
}

pub fn extract_error_message_503_test() {
  let response = types.HttpResponse(503, [], "Maintenance")
  let msg = http_client.extract_error_message(response)

  msg |> should.equal("Service Unavailable: Maintenance")
}

pub fn extract_error_message_other_test() {
  let response = types.HttpResponse(418, [], "I'm a teapot")
  let msg = http_client.extract_error_message(response)

  msg |> should.equal("HTTP 418: I'm a teapot")
}

// Test is_success_status
pub fn is_success_status_200_test() {
  http_client.is_success_status(200) |> should.be_true()
}

pub fn is_success_status_201_test() {
  http_client.is_success_status(201) |> should.be_true()
}

pub fn is_success_status_299_test() {
  http_client.is_success_status(299) |> should.be_true()
}

pub fn is_success_status_199_test() {
  http_client.is_success_status(199) |> should.be_false()
}

pub fn is_success_status_300_test() {
  http_client.is_success_status(300) |> should.be_false()
}

pub fn is_success_status_400_test() {
  http_client.is_success_status(400) |> should.be_false()
}

pub fn is_success_status_500_test() {
  http_client.is_success_status(500) |> should.be_false()
}

// Test add_common_headers
pub fn add_common_headers_test() {
  let headers = [#("Authorization", "Bearer token")]
  let result = http_client.add_common_headers(headers, "test-agent/1.0")

  // Should have at least 3 headers
  case result {
    [_, _, _, ..] -> True |> should.be_true()
    _ -> should.fail()
  }
}

pub fn add_common_headers_user_agent_test() {
  let headers = []
  let result = http_client.add_common_headers(headers, "test-agent/1.0")

  // Check for User-Agent header
  case result {
    [#("User-Agent", "test-agent/1.0"), ..] -> True |> should.be_true()
    _ -> should.fail()
  }
}

pub fn add_common_headers_accept_test() {
  let headers = []
  let result = http_client.add_common_headers(headers, "test-agent/1.0")

  // Should contain Accept: application/json
  case result {
    [#("User-Agent", _), #("Accept", "application/json"), ..] ->
      True |> should.be_true()
    _ -> should.fail()
  }
}

// Test validate_url
pub fn validate_url_http_test() {
  case http_client.validate_url("http://example.com") {
    Ok(url) -> url |> should.equal("http://example.com")
    Error(_) -> should.fail()
  }
}

pub fn validate_url_https_test() {
  case http_client.validate_url("https://example.com") {
    Ok(url) -> url |> should.equal("https://example.com")
    Error(_) -> should.fail()
  }
}

pub fn validate_url_invalid_test() {
  case http_client.validate_url("ftp://example.com") {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.equal("URL must start with http:// or https://")
  }
}

pub fn validate_url_no_protocol_test() {
  case http_client.validate_url("example.com") {
    Ok(_) -> should.fail()
    Error(_) -> True |> should.be_true()
  }
}

// Test build_api_url
pub fn build_api_url_no_trailing_slash_test() {
  let result =
    http_client.build_api_url("https://api.example.com", "chat/completions")
  result |> should.equal("https://api.example.com/chat/completions")
}

pub fn build_api_url_trailing_slash_test() {
  let result =
    http_client.build_api_url("https://api.example.com/", "chat/completions")
  result |> should.equal("https://api.example.com/chat/completions")
}

pub fn build_api_url_leading_slash_test() {
  let result =
    http_client.build_api_url("https://api.example.com", "/chat/completions")
  result |> should.equal("https://api.example.com/chat/completions")
}

pub fn build_api_url_both_slashes_test() {
  let result =
    http_client.build_api_url("https://api.example.com/", "/chat/completions")
  result |> should.equal("https://api.example.com/chat/completions")
}

pub fn build_api_url_empty_endpoint_test() {
  let result = http_client.build_api_url("https://api.example.com", "")
  result |> should.equal("https://api.example.com/")
}

pub fn build_api_url_complex_endpoint_test() {
  let result =
    http_client.build_api_url("https://api.example.com", "v1/chat/completions")
  result |> should.equal("https://api.example.com/v1/chat/completions")
}

// Test parse_content_type
pub fn parse_content_type_json_test() {
  let headers = [#("Content-Type", "application/json")]
  let result = http_client.parse_content_type(headers)
  result |> should.equal("application/json")
}

pub fn parse_content_type_lowercase_test() {
  let headers = [#("content-type", "text/plain")]
  let result = http_client.parse_content_type(headers)
  result |> should.equal("text/plain")
}

pub fn parse_content_type_mixed_case_test() {
  let headers = [#("Content-TYPE", "application/xml")]
  let result = http_client.parse_content_type(headers)
  result |> should.equal("application/xml")
}

pub fn parse_content_type_default_test() {
  let headers = []
  let result = http_client.parse_content_type(headers)
  result |> should.equal("application/json")
}

pub fn parse_content_type_multiple_headers_test() {
  let headers = [
    #("Authorization", "Bearer token"),
    #("Content-Type", "application/json; charset=utf-8"),
    #("Accept", "application/json"),
  ]
  let result = http_client.parse_content_type(headers)
  result |> should.equal("application/json; charset=utf-8")
}

// Test is_json_response
pub fn is_json_response_true_test() {
  let headers = [#("Content-Type", "application/json")]
  http_client.is_json_response(headers) |> should.be_true()
}

pub fn is_json_response_with_charset_test() {
  let headers = [#("Content-Type", "application/json; charset=utf-8")]
  http_client.is_json_response(headers) |> should.be_true()
}

pub fn is_json_response_false_test() {
  let headers = [#("Content-Type", "text/plain")]
  http_client.is_json_response(headers) |> should.be_false()
}

pub fn is_json_response_default_test() {
  let headers = []
  http_client.is_json_response(headers) |> should.be_true()
}

// Test is_streaming_response
pub fn is_streaming_response_event_stream_test() {
  let headers = [#("Content-Type", "text/event-stream")]
  http_client.is_streaming_response(headers) |> should.be_true()
}

pub fn is_streaming_response_text_stream_test() {
  let headers = [#("Content-Type", "text/stream")]
  http_client.is_streaming_response(headers) |> should.be_true()
}

pub fn is_streaming_response_false_test() {
  let headers = [#("Content-Type", "application/json")]
  http_client.is_streaming_response(headers) |> should.be_false()
}

pub fn is_streaming_response_default_test() {
  let headers = []
  http_client.is_streaming_response(headers) |> should.be_false()
}
