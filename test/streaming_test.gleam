import gleeunit
import gleeunit/should
import instructor/sse_parser
import instructor/json_parser

pub fn main() {
  gleeunit.main()
}

// Test SSE parsing functionality
pub fn sse_parse_line_test() {
  case sse_parser.parse_sse_line("data: hello world") {
    Some(#(field, value)) -> {
      field |> should.equal("data")
      value |> should.equal("hello world")
    }
    None -> should.fail()
  }
  
  case sse_parser.parse_sse_line("event: message") {
    Some(#(field, value)) -> {
      field |> should.equal("event")
      value |> should.equal("message")
    }
    None -> should.fail()
  }
}

pub fn sse_parse_event_test() {
  let lines = [
    "event: message",
    "data: {\"hello\": \"world\"}",
    "id: 123",
  ]
  
  case sse_parser.parse_sse_event(lines) {
    Some(event) -> {
      event.event_type |> should.equal(Some("message"))
      event.data |> should.equal("{\"hello\": \"world\"}\n")
      event.id |> should.equal(Some("123"))
    }
    None -> should.fail()
  }
}

pub fn sse_done_event_test() {
  let done_event = sse_parser.SSEEvent(
    event_type: None,
    data: "[DONE]",
    id: None,
    retry: None,
  )
  
  sse_parser.is_done_event(done_event)
  |> should.be_true()
  
  let normal_event = sse_parser.SSEEvent(
    event_type: None,
    data: "{\"content\": \"hello\"}",
    id: None,
    retry: None,
  )
  
  sse_parser.is_done_event(normal_event)
  |> should.be_false()
}

pub fn sse_extract_data_test() {
  let events = [
    sse_parser.SSEEvent(None, "{\"msg\": \"hello\"}", None, None),
    sse_parser.SSEEvent(None, "{\"msg\": \"world\"}", None, None),
    sse_parser.SSEEvent(None, "[DONE]", None, None),
  ]
  
  let data_events = sse_parser.extract_data_events(events)
  data_events |> should.equal(["{\"msg\": \"hello\"}", "{\"msg\": \"world\"}"])
}

// Test JSON streaming parser
pub fn json_parser_init_test() {
  let state = json_parser.init_parser()
  state.buffer |> should.equal("")
  state.depth |> should.equal(0)
  state.in_string |> should.be_false()
  state.escaped |> should.be_false()
}

pub fn json_parser_simple_object_test() {
  let state = json_parser.init_parser()
  let #(_final_state, completed) = json_parser.parse_chunk(state, "{\"key\": \"value\"}")
  
  completed |> should.equal(["{\"key\": \"value\"}"])
}

pub fn json_parser_nested_object_test() {
  let state = json_parser.init_parser()
  let #(_final_state, completed) = json_parser.parse_chunk(state, "{\"outer\": {\"inner\": \"value\"}}")
  
  completed |> should.equal(["{\"outer\": {\"inner\": \"value\"}}"])
}

pub fn json_parser_multiple_objects_test() {
  let state = json_parser.init_parser()
  let #(_final_state, completed) = json_parser.parse_chunk(state, "{\"first\": 1}{\"second\": 2}")
  
  completed |> should.equal(["{\"first\": 1}", "{\"second\": 2}"])
}

pub fn json_parser_string_with_braces_test() {
  let state = json_parser.init_parser()
  let #(_final_state, completed) = json_parser.parse_chunk(state, "{\"message\": \"Hello {world}\"}")
  
  completed |> should.equal(["{\"message\": \"Hello {world}\"}"])
}

pub fn json_parser_escaped_quotes_test() {
  let state = json_parser.init_parser()
  let #(_final_state, completed) = json_parser.parse_chunk(state, "{\"message\": \"Hello \\\"world\\\"\"}")
  
  completed |> should.equal(["{\"message\": \"Hello \\\"world\\\"\"}"])
}