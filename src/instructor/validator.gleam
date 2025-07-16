import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import instructor/types.{type ValidationContext}

/// Validation error
pub type ValidationError {
  ValidationError(field: String, message: String)
}

/// Validation result
pub type ValidationResult(a) {
  Valid(a)
  Invalid(List(ValidationError))
}

/// Validator function type
pub type Validator(a) =
  fn(dynamic.Dynamic, ValidationContext) -> ValidationResult(a)

/// Create a validator for strings
pub fn string_validator() -> Validator(String) {
  fn(value, _context) {
    case dynamic.string(value) {
      Ok(s) -> Valid(s)
      Error(_) -> Invalid([ValidationError("", "Expected string")])
    }
  }
}

/// Create a validator for integers
pub fn int_validator() -> Validator(Int) {
  fn(value, _context) {
    case dynamic.int(value) {
      Ok(i) -> Valid(i)
      Error(_) -> Invalid([ValidationError("", "Expected integer")])
    }
  }
}

/// Create a validator for floats
pub fn float_validator() -> Validator(Float) {
  fn(value, _context) {
    case dynamic.float(value) {
      Ok(f) -> Valid(f)
      Error(_) -> Invalid([ValidationError("", "Expected float")])
    }
  }
}

/// Create a validator for booleans
pub fn bool_validator() -> Validator(Bool) {
  fn(value, _context) {
    case dynamic.bool(value) {
      Ok(b) -> Valid(b)
      Error(_) -> Invalid([ValidationError("", "Expected boolean")])
    }
  }
}

/// Create a validator for optional values
pub fn optional_validator(validator: Validator(a)) -> Validator(Option(a)) {
  fn(value, context) {
    case dynamic.optional(fn(v) { 
      case validator(v, context) {
        Valid(result) -> Ok(result)
        Invalid(_) -> Error([dynamic.DecodeError("validation failed", "", [])])
      }
    })(value) {
      Ok(opt) -> Valid(opt)
      Error(_) -> Invalid([ValidationError("", "Validation failed for optional value")])
    }
  }
}

/// Create a validator for lists
pub fn list_validator(validator: Validator(a)) -> Validator(List(a)) {
  fn(value, context) {
    case dynamic.list(fn(v) {
      case validator(v, context) {
        Valid(result) -> Ok(result)
        Invalid(_) -> Error([dynamic.DecodeError("validation failed", "", [])])
      }
    })(value) {
      Ok(lst) -> Valid(lst)
      Error(_) -> Invalid([ValidationError("", "Expected list")])
    }
  }
}

/// Create a validator that ensures a string is not empty
pub fn non_empty_string_validator() -> Validator(String) {
  fn(value, context) {
    case string_validator()(value, context) {
      Valid(s) -> case string.is_empty(s) {
        True -> Invalid([ValidationError("", "String cannot be empty")])
        False -> Valid(s)
      }
      Invalid(errors) -> Invalid(errors)
    }
  }
}

/// Create a validator that ensures an integer is within a range
pub fn int_range_validator(min: Option(Int), max: Option(Int)) -> Validator(Int) {
  fn(value, context) {
    case int_validator()(value, context) {
      Valid(i) -> {
        let min_check = case min {
          Some(min_val) -> i >= min_val
          None -> True
        }
        let max_check = case max {
          Some(max_val) -> i <= max_val
          None -> True
        }
        case min_check && max_check {
          True -> Valid(i)
          False -> Invalid([ValidationError("", "Integer out of range")])
        }
      }
      Invalid(errors) -> Invalid(errors)
    }
  }
}

/// Create a validator that ensures a float is within a range
pub fn float_range_validator(min: Option(Float), max: Option(Float)) -> Validator(Float) {
  fn(value, context) {
    case float_validator()(value, context) {
      Valid(f) -> {
        let min_check = case min {
          Some(min_val) -> f >=. min_val
          None -> True
        }
        let max_check = case max {
          Some(max_val) -> f <=. max_val
          None -> True
        }
        case min_check && max_check {
          True -> Valid(f)
          False -> Invalid([ValidationError("", "Float out of range")])
        }
      }
      Invalid(errors) -> Invalid(errors)
    }
  }
}

/// Create a validator that ensures a string is one of the allowed values
pub fn enum_validator(allowed_values: List(String)) -> Validator(String) {
  fn(value, context) {
    case string_validator()(value, context) {
      Valid(s) -> case list.contains(allowed_values, s) {
        True -> Valid(s)
        False -> Invalid([ValidationError("", "Value not in allowed enum values")])
      }
      Invalid(errors) -> Invalid(errors)
    }
  }
}

/// Create a custom validator
pub fn custom_validator(
  decoder: dynamic.Decoder(a),
  custom_validation: fn(a) -> Result(a, String),
) -> Validator(a) {
  fn(value, _context) {
    case decoder(value) {
      Ok(decoded) -> case custom_validation(decoded) {
        Ok(validated) -> Valid(validated)
        Error(msg) -> Invalid([ValidationError("", msg)])
      }
      Error(_) -> Invalid([ValidationError("", "Decoding failed")])
    }
  }
}

/// Combine multiple validation errors
pub fn combine_errors(errors1: List(ValidationError), errors2: List(ValidationError)) -> List(ValidationError) {
  list.append(errors1, errors2)
}

/// Format validation errors as a string
pub fn format_errors(errors: List(ValidationError)) -> String {
  errors
  |> list.map(fn(error) {
    let ValidationError(field, message) = error
    case string.is_empty(field) {
      True -> message
      False -> field <> ": " <> message
    }
  })
  |> string.join("\n")
}

/// Validate a value with context
pub fn validate_with_context(
  validator: Validator(a),
  value: dynamic.Dynamic,
  context: ValidationContext,
) -> ValidationResult(a) {
  validator(value, context)
}

/// Convert validation result to standard Result type
pub fn to_result(validation: ValidationResult(a)) -> Result(a, List(ValidationError)) {
  case validation {
    Valid(value) -> Ok(value)
    Invalid(errors) -> Error(errors)
  }
}