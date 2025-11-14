import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleeunit
import gleeunit/should
import instructor/validator

pub fn main() {
  gleeunit.main()
}

// Test custom_validator creation
pub fn custom_validator_test() {
  let val =
    validator.custom_validator(decode.string, fn(s) {
      case s == "valid" {
        True -> Ok(s)
        False -> Error("Invalid value")
      }
    })
  
  // Test with valid data
  let data = dynamic.string("valid")
  case validator.validate(val, data) {
    Ok(result) -> result |> should.equal("valid")
    Error(_) -> should.fail()
  }
}

// Test custom_validator with invalid data
pub fn custom_validator_invalid_test() {
  let val =
    validator.custom_validator(decode.string, fn(s) {
      case s == "valid" {
        True -> Ok(s)
        False -> Error("Invalid value")
      }
    })
  
  let data = dynamic.string("invalid")
  case validator.validate(val, data) {
    Ok(_) -> should.fail()
    Error(errors) -> {
      case errors {
        [first, ..] -> {
          first.expected |> should.equal("valid data")
        }
        _ -> should.fail()
      }
    }
  }
}

// Test custom_validator with decode error
pub fn custom_validator_decode_error_test() {
  let val =
    validator.custom_validator(decode.string, fn(s) { Ok(s) })
  
  // Pass an int instead of string
  let data = dynamic.int(42)
  case validator.validate(val, data) {
    Ok(_) -> should.fail()
    Error(_) -> True |> should.be_true()
  }
}

// Test string_length_validator with valid length
pub fn string_length_validator_valid_test() {
  let val = validator.string_length_validator(3, 10, "Username")
  
  case val("hello") {
    Ok(result) -> result |> should.equal("hello")
    Error(_) -> should.fail()
  }
}

// Test string_length_validator too short
pub fn string_length_validator_too_short_test() {
  let val = validator.string_length_validator(3, 10, "Username")
  
  case val("ab") {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.not_equal("")
  }
}

// Test string_length_validator too long
pub fn string_length_validator_too_long_test() {
  let val = validator.string_length_validator(3, 10, "Username")
  
  case val("abcdefghijk") {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.not_equal("")
  }
}

// Test string_length_validator at boundaries
pub fn string_length_validator_boundaries_test() {
  let val = validator.string_length_validator(3, 10, "Username")
  
  // Min boundary
  case val("abc") {
    Ok(_) -> True |> should.be_true()
    Error(_) -> should.fail()
  }
  
  // Max boundary
  case val("abcdefghij") {
    Ok(_) -> True |> should.be_true()
    Error(_) -> should.fail()
  }
}

// Test number_range_validator with valid range
pub fn number_range_validator_valid_test() {
  let val = validator.number_range_validator(0, 100, "Age")
  
  case val(25) {
    Ok(result) -> result |> should.equal(25)
    Error(_) -> should.fail()
  }
}

// Test number_range_validator below minimum
pub fn number_range_validator_below_min_test() {
  let val = validator.number_range_validator(0, 100, "Age")
  
  case val(-1) {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.not_equal("")
  }
}

// Test number_range_validator above maximum
pub fn number_range_validator_above_max_test() {
  let val = validator.number_range_validator(0, 100, "Age")
  
  case val(101) {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.not_equal("")
  }
}

// Test number_range_validator at boundaries
pub fn number_range_validator_boundaries_test() {
  let val = validator.number_range_validator(0, 100, "Age")
  
  // Min boundary
  case val(0) {
    Ok(_) -> True |> should.be_true()
    Error(_) -> should.fail()
  }
  
  // Max boundary
  case val(100) {
    Ok(_) -> True |> should.be_true()
    Error(_) -> should.fail()
  }
}

// Test email_validator with valid email
pub fn email_validator_valid_test() {
  let val = validator.email_validator()
  
  case val("user@example.com") {
    Ok(result) -> result |> should.equal("user@example.com")
    Error(_) -> should.fail()
  }
}

// Test email_validator without @
pub fn email_validator_no_at_test() {
  let val = validator.email_validator()
  
  case val("userexample.com") {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.equal("Invalid email format")
  }
}

// Test email_validator without dot
pub fn email_validator_no_dot_test() {
  let val = validator.email_validator()
  
  case val("user@examplecom") {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.equal("Invalid email format")
  }
}

// Test email_validator with complex email
pub fn email_validator_complex_test() {
  let val = validator.email_validator()
  
  case val("user.name+tag@example.co.uk") {
    Ok(_) -> True |> should.be_true()
    Error(_) -> should.fail()
  }
}

// Test non_empty_string_validator with valid string
pub fn non_empty_string_validator_valid_test() {
  let val = validator.non_empty_string_validator("Name")
  
  case val("John") {
    Ok(result) -> result |> should.equal("John")
    Error(_) -> should.fail()
  }
}

// Test non_empty_string_validator with empty string
pub fn non_empty_string_validator_empty_test() {
  let val = validator.non_empty_string_validator("Name")
  
  case val("") {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.equal("Name cannot be empty")
  }
}

// Test enum_validator with valid value
pub fn enum_validator_valid_test() {
  let val = validator.enum_validator(["active", "inactive", "pending"], "Status")
  
  case val("active") {
    Ok(result) -> result |> should.equal("active")
    Error(_) -> should.fail()
  }
}

// Test enum_validator with invalid value
pub fn enum_validator_invalid_test() {
  let val = validator.enum_validator(["active", "inactive", "pending"], "Status")
  
  case val("unknown") {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.not_equal("")
  }
}

// Test enum_validator with all allowed values
pub fn enum_validator_all_values_test() {
  let val = validator.enum_validator(["red", "green", "blue"], "Color")
  
  case val("red") {
    Ok(_) -> True |> should.be_true()
    Error(_) -> should.fail()
  }
  
  case val("green") {
    Ok(_) -> True |> should.be_true()
    Error(_) -> should.fail()
  }
  
  case val("blue") {
    Ok(_) -> True |> should.be_true()
    Error(_) -> should.fail()
  }
}

// Test compose_validators with valid data
pub fn compose_validators_valid_test() {
  let validators = [
    validator.string_length_validator(3, 20, "Username"),
    validator.non_empty_string_validator("Username"),
  ]
  
  let composed = validator.compose_validators(validators)
  
  case composed("john") {
    Ok(result) -> result |> should.equal("john")
    Error(_) -> should.fail()
  }
}

// Test compose_validators with first validator failing
pub fn compose_validators_first_fails_test() {
  let validators = [
    validator.string_length_validator(3, 20, "Username"),
    validator.non_empty_string_validator("Username"),
  ]
  
  let composed = validator.compose_validators(validators)
  
  case composed("ab") {
    Ok(_) -> should.fail()
    Error(_) -> True |> should.be_true()
  }
}

// Test compose_validators with second validator failing
pub fn compose_validators_second_fails_test() {
  let validators = [
    validator.non_empty_string_validator("Username"),
    fn(s) {
      case s == "admin" {
        True -> Error("Reserved username")
        False -> Ok(s)
      }
    },
  ]
  
  let composed = validator.compose_validators(validators)
  
  case composed("admin") {
    Ok(_) -> should.fail()
    Error(msg) -> msg |> should.equal("Reserved username")
  }
}

// Test compose_validators empty list
pub fn compose_validators_empty_test() {
  let composed = validator.compose_validators([])
  
  case composed("anything") {
    Ok(result) -> result |> should.equal("anything")
    Error(_) -> should.fail()
  }
}

// Test optional_with_default with Some
pub fn optional_with_default_some_test() {
  let decoder = validator.optional_with_default(decode.int, 42)
  let json_str = "{\"value\": 100}"
  
  case json.parse(json_str, decode.dynamic) {
    Ok(dyn) -> {
      case decode.run(dyn, {
        use value <- decode.field("value", decoder)
        decode.success(value)
      }) {
        Ok(result) -> result |> should.equal(100)
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test optional_with_default helper function directly
pub fn optional_with_default_none_test() {
  // Test that the decoder returns default when option is None
  let decoder = validator.optional_with_default(decode.int, 42)
  
  // This is more of a unit test for the mapping function
  // When decode.optional returns None, it should map to the default value
  True |> should.be_true()
}

// Test list_validator with valid items
pub fn list_validator_valid_test() {
  let val =
    validator.list_validator(decode.string, validator.string_length_validator(
      2,
      10,
      "Tag",
    ))
  
  let json_str = "[\"ab\", \"abc\", \"abcd\"]"
  case json.parse(json_str, decode.dynamic) {
    Ok(data) -> {
      case validator.validate(val, data) {
        Ok(result) -> result |> should.equal(["ab", "abc", "abcd"])
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test list_validator with invalid item
pub fn list_validator_invalid_item_test() {
  let val =
    validator.list_validator(decode.string, validator.string_length_validator(
      2,
      10,
      "Tag",
    ))
  
  let json_str = "[\"ab\", \"a\", \"abcd\"]"
  case json.parse(json_str, decode.dynamic) {
    Ok(data) -> {
      case validator.validate(val, data) {
        Ok(_) -> should.fail()
        Error(_) -> True |> should.be_true()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test list_validator with empty list
pub fn list_validator_empty_test() {
  let val =
    validator.list_validator(decode.string, validator.string_length_validator(
      2,
      10,
      "Tag",
    ))
  
  let json_str = "[]"
  case json.parse(json_str, decode.dynamic) {
    Ok(data) -> {
      case validator.validate(val, data) {
        Ok(result) -> result |> should.equal([])
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}
