import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

/// SSE (Server-Sent Events) event
pub type SSEEvent {
  SSEEvent(
    event_type: Option(String),
    data: String,
    id: Option(String),
    retry: Option(Int),
  )
}

/// Parse a single SSE line
pub fn parse_sse_line(line: String) -> Option(#(String, String)) {
  case string.split_once(line, ":") {
    Ok(#(field, value)) -> {
      let trimmed_value = case string.starts_with(value, " ") {
        True -> string.drop_left(value, 1)
        False -> value
      }
      Some(#(field, trimmed_value))
    }
    Error(_) -> None
  }
}

/// Parse multiple SSE lines into an event
pub fn parse_sse_event(lines: List(String)) -> Option(SSEEvent) {
  let parsed_lines =
    lines
    |> list.filter_map(parse_sse_line)

  case parsed_lines {
    [] -> None
    _ -> {
      let event = SSEEvent(None, "", None, None)
      Some(fold_sse_fields(parsed_lines, event))
    }
  }
}

/// Fold SSE field/value pairs into an event
fn fold_sse_fields(fields: List(#(String, String)), event: SSEEvent) -> SSEEvent {
  case fields {
    [] -> event
    [#(field, value), ..rest] -> {
      let updated_event = case field {
        "event" -> SSEEvent(..event, event_type: Some(value))
        "data" -> SSEEvent(..event, data: event.data <> value <> "\n")
        "id" -> SSEEvent(..event, id: Some(value))
        "retry" -> {
          case string.to_int(value) {
            Ok(retry_val) -> SSEEvent(..event, retry: Some(retry_val))
            Error(_) -> event
          }
        }
        _ -> event
      }
      fold_sse_fields(rest, updated_event)
    }
  }
}

/// Split SSE stream text into events
pub fn split_sse_events(text: String) -> List(List(String)) {
  text
  |> string.split("\n\n")
  |> list.map(string.split(_, "\n"))
  |> list.filter(fn(lines) {
    case lines {
      [""] -> False
      [] -> False
      _ -> True
    }
  })
}

/// Parse complete SSE stream
pub fn parse_sse_stream(stream_text: String) -> List(SSEEvent) {
  stream_text
  |> split_sse_events()
  |> list.filter_map(parse_sse_event)
}

/// Check if an event is a "done" signal
pub fn is_done_event(event: SSEEvent) -> Bool {
  case event.data {
    "[DONE]" -> True
    _ -> False
  }
}

/// Extract JSON data from SSE event
pub fn extract_json_data(event: SSEEvent) -> Option(String) {
  case string.is_empty(string.trim(event.data)) {
    True -> None
    False -> Some(string.trim(event.data))
  }
}

/// Filter and extract data events from SSE stream
pub fn extract_data_events(events: List(SSEEvent)) -> List(String) {
  events
  |> list.filter(fn(event) { !is_done_event(event) })
  |> list.filter_map(extract_json_data)
}
