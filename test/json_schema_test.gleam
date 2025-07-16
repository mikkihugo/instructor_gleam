import gleeunit
import gleeunit/should
import gleam/dict
import gleam/dynamic
import instructor/json_schema
import instructor/validator

pub fn main() {
  gleeunit.main()
}

// Test JSON schema creation for different types
pub fn json_schema_string_test() {
  let schema = json_schema.string_schema(Some("A test string field"))
  let json_str = json_schema.schema_to_string(schema)
  
  json_str
  |> should.not_equal("")
  
  // Should contain type: string
  json_str
  |> should.contain("\"type\":\"string\"")
}

pub fn json_schema_integer_test() {
  let schema = json_schema.int_schema(Some("A test integer field"))
  let json_str = json_schema.schema_to_string(schema)
  
  json_str
  |> should.contain("\"type\":\"integer\"")
}

pub fn json_schema_object_test() {
  let properties = dict.from_list([
    #("name", json_schema.string_schema(Some("Person's name"))),
    #("age", json_schema.int_schema(Some("Person's age"))),
  ])
  
  let schema = json_schema.object_schema(properties, ["name", "age"], Some("A person object"))
  let json_str = json_schema.schema_to_string(schema)
  
  json_str
  |> should.contain("\"type\":\"object\"")
  json_str
  |> should.contain("\"properties\"")
  json_str
  |> should.contain("\"required\"")
}

pub fn json_schema_enum_test() {
  let schema = json_schema.enum_schema(["red", "green", "blue"], Some("Color choice"))
  let json_str = json_schema.schema_to_string(schema)
  
  json_str
  |> should.contain("\"enum\"")
  json_str
  |> should.contain("\"red\"")
}

// Test validator functionality with different types
pub fn validator_string_test() {
  let validator_fn = validator.string_validator()
  let context = []
  
  case validator.validate_with_context(validator_fn, dynamic.from("test"), context) {
    validator.Valid(result) -> result |> should.equal("test")
    validator.Invalid(_) -> should.fail()
  }
}

pub fn validator_int_test() {
  let validator_fn = validator.int_validator()
  let context = []
  
  case validator.validate_with_context(validator_fn, dynamic.from(42), context) {
    validator.Valid(result) -> result |> should.equal(42)
    validator.Invalid(_) -> should.fail()
  }
}

pub fn validator_bool_test() {
  let validator_fn = validator.bool_validator()
  let context = []
  
  case validator.validate_with_context(validator_fn, dynamic.from(True), context) {
    validator.Valid(result) -> result |> should.equal(True)
    validator.Invalid(_) -> should.fail()
  }
}

pub fn validator_non_empty_string_test() {
  let validator_fn = validator.non_empty_string_validator()
  let context = []
  
  // Test valid non-empty string
  case validator.validate_with_context(validator_fn, dynamic.from("hello"), context) {
    validator.Valid(result) -> result |> should.equal("hello")
    validator.Invalid(_) -> should.fail()
  }
  
  // Test invalid empty string
  case validator.validate_with_context(validator_fn, dynamic.from(""), context) {
    validator.Valid(_) -> should.fail()
    validator.Invalid(errors) -> 
      errors
      |> should.be_ok()
  }
}

pub fn validator_int_range_test() {
  let validator_fn = validator.int_range_validator(Some(1), Some(10))
  let context = []
  
  // Test valid range
  case validator.validate_with_context(validator_fn, dynamic.from(5), context) {
    validator.Valid(result) -> result |> should.equal(5)
    validator.Invalid(_) -> should.fail()
  }
  
  // Test out of range
  case validator.validate_with_context(validator_fn, dynamic.from(15), context) {
    validator.Valid(_) -> should.fail()
    validator.Invalid(_) -> True |> should.be_true()
  }
}

pub fn validator_enum_test() {
  let validator_fn = validator.enum_validator(["red", "green", "blue"])
  let context = []
  
  // Test valid enum value
  case validator.validate_with_context(validator_fn, dynamic.from("red"), context) {
    validator.Valid(result) -> result |> should.equal("red")
    validator.Invalid(_) -> should.fail()
  }
  
  // Test invalid enum value
  case validator.validate_with_context(validator_fn, dynamic.from("purple"), context) {
    validator.Valid(_) -> should.fail()
    validator.Invalid(_) -> True |> should.be_true()
  }
}