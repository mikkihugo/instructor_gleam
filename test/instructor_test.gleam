import gleam/dynamic
import gleam/option.{Some}
import gleeunit
import gleeunit/should
import instructor
import instructor/json_schema
import instructor/types

pub fn main() {
  gleeunit.main()
}

// Test basic types functionality
pub fn role_conversion_test() {
  types.role_to_string(types.User)
  |> should.equal("user")

  types.role_to_string(types.Assistant)
  |> should.equal("assistant")

  types.string_to_role("system")
  |> should.equal(Ok(types.System))

  types.string_to_role("invalid")
  |> should.equal(Error(Nil))
}

// Test message creation
pub fn message_creation_test() {
  let msg = instructor.user_message("Hello, world!")
  case msg {
    types.Message(role, content) -> {
      role |> should.equal(types.User)
      content |> should.equal("Hello, world!")
    }
  }
}

// Test JSON schema creation
pub fn json_schema_test() {
  let schema = json_schema.string_schema(Some("A test string"))
  let json_str = json_schema.schema_to_string(schema)

  // Just check that it produces a string
  json_str
  |> should.not_equal("")
}

import gleam/dynamic/decode

// Test decoder functionality
pub fn decoder_test() {
  let model = instructor.string_response_model("Test description")
  case model {
    instructor.Single(validator) -> {
      let data = dynamic.string("test")
      case decode.run(data, validator) {
        Ok(result) -> result |> should.equal("test")
        Error(_) -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

// Test config creation
pub fn config_test() {
  let config = instructor.default_config()
  config.default_model |> should.equal("gpt-4o-mini")
  config.default_max_retries |> should.equal(0)
}

// Test response model creation
pub fn response_model_test() {
  let model = instructor.string_response_model("Test description")
  case model {
    instructor.Single(_) -> True |> should.be_true()
    _ -> should.fail()
  }
}
