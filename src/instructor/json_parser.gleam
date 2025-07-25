import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

/// JSON streaming parser state
pub type ParserState {
  ParserState(buffer: String, depth: Int, in_string: Bool, escaped: Bool)
}

/// Initialize parser state
pub fn init_parser() -> ParserState {
  ParserState(buffer: "", depth: 0, in_string: False, escaped: False)
}

/// Parse incremental JSON chunks
pub fn parse_chunk(
  state: ParserState,
  chunk: String,
) -> #(ParserState, List(String)) {
  parse_chars(state, string.to_graphemes(chunk), [])
}

/// Process characters one by one
fn parse_chars(
  state: ParserState,
  chars: List(String),
  completed: List(String),
) -> #(ParserState, List(String)) {
  case chars {
    [] -> #(state, list.reverse(completed))
    [char, ..rest] -> {
      let new_state = process_char(state, char)
      case is_complete_object(new_state) {
        True -> {
          let completed_json = new_state.buffer
          let reset_state =
            ParserState(buffer: "", depth: 0, in_string: False, escaped: False)
          parse_chars(reset_state, rest, [completed_json, ..completed])
        }
        False -> parse_chars(new_state, rest, completed)
      }
    }
  }
}

/// Process a single character
fn process_char(state: ParserState, char: String) -> ParserState {
  let updated_buffer = state.buffer <> char

  case state.escaped {
    True -> ParserState(..state, buffer: updated_buffer, escaped: False)
    False -> {
      case char {
        "\\" -> {
          case state.in_string {
            True -> ParserState(..state, buffer: updated_buffer, escaped: True)
            False -> ParserState(..state, buffer: updated_buffer)
          }
        }
        "\"" ->
          ParserState(
            ..state,
            buffer: updated_buffer,
            in_string: !state.in_string,
          )
        "{" -> {
          case state.in_string {
            True -> ParserState(..state, buffer: updated_buffer)
            False ->
              ParserState(
                ..state,
                buffer: updated_buffer,
                depth: state.depth + 1,
              )
          }
        }
        "}" -> {
          case state.in_string {
            True -> ParserState(..state, buffer: updated_buffer)
            False ->
              ParserState(
                ..state,
                buffer: updated_buffer,
                depth: state.depth - 1,
              )
          }
        }
        _ -> ParserState(..state, buffer: updated_buffer)
      }
    }
  }
}

/// Check if we have a complete JSON object
fn is_complete_object(state: ParserState) -> Bool {
  state.depth == 0 && !string.is_empty(state.buffer) && !state.in_string
}

/// Parse partial JSON objects from stream
pub fn parse_partial_objects(stream_text: String) -> List(dynamic.Dynamic) {
  let #(_final_state, json_strings) = parse_chunk(init_parser(), stream_text)

  json_strings
  |> list.filter_map(fn(json_str) {
    case json.decode(json_str, dynamic.dynamic) {
      Ok(parsed) -> Some(parsed)
      Error(_) -> None
    }
  })
}

/// Extract nested field from partial JSON
pub fn extract_field(
  data: dynamic.Dynamic,
  field_path: List(String),
) -> Option(dynamic.Dynamic) {
  case field_path {
    [] -> Some(data)
    [field, ..rest] -> {
      case dynamic.field(field, dynamic.dynamic)(data) {
        Ok(nested) -> extract_field(nested, rest)
        Error(_) -> None
      }
    }
  }
}

/// Parse array elements from streaming JSON
pub fn parse_array_elements(data: dynamic.Dynamic) -> List(dynamic.Dynamic) {
  case dynamic.list(dynamic.dynamic)(data) {
    Ok(elements) -> elements
    Error(_) -> []
  }
}

/// Merge partial JSON objects (for streaming partial responses)
pub fn merge_partial_objects(
  base: dynamic.Dynamic,
  update: dynamic.Dynamic,
) -> dynamic.Dynamic {
  // This is a simplified merge - in a real implementation,
  // we'd need more sophisticated object merging
  case dynamic.dict(dynamic.string, dynamic.dynamic)(update) {
    Ok(_) -> update
    // If update is valid, use it
    Error(_) -> base
    // Otherwise keep base
  }
}

/// Check if JSON object is complete (has no null values)
pub fn is_complete(data: dynamic.Dynamic) -> Bool {
  // Simplified check - in practice would need recursive validation
  case dynamic.dict(dynamic.string, dynamic.dynamic)(data) {
    Ok(dict) -> True
    // Assume complete if it parses as dict
    Error(_) -> False
  }
}

/// Extract streaming deltas for array responses
pub fn extract_array_deltas(
  previous: List(dynamic.Dynamic),
  current: List(dynamic.Dynamic),
) -> List(dynamic.Dynamic) {
  case list.length(current) > list.length(previous) {
    True -> list.drop(current, list.length(previous))
    False -> []
  }
}
