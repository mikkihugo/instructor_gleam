/// Validator module for custom type decoders and complex domain models
///
/// This module provides utilities for creating custom validators for complex
/// domain models that require more sophisticated validation logic than simple
/// type checking.
import gleam/dynamic
import gleam/dynamic/decode
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

/// Custom validator type that combines decoding with validation logic
pub type CustomValidator(a) {
  CustomValidator(
    decoder: decode.Decoder(a),
    validator: fn(a) -> Result(a, String),
  )
}

/// Create a custom validator from a decoder and validation function
///
/// ## Example
/// 
/// ```gleam
/// pub type Email {
///   Email(address: String)
/// }
///
/// pub fn email_validator() -> CustomValidator(Email) {
///   let decoder = {
///     use address <- decode.field("address", decode.string)
///     decode.success(Email(address))
///   }
///   
///   let validator = fn(email: Email) {
///     case string.contains(email.address, "@") {
///       True -> Ok(email)
///       False -> Error("Email must contain @ symbol")
///     }
///   }
///   
///   custom_validator(decoder, validator)
/// }
/// ```
pub fn custom_validator(
  decoder: decode.Decoder(a),
  validator: fn(a) -> Result(a, String),
) -> CustomValidator(a) {
  CustomValidator(decoder: decoder, validator: validator)
}

/// Run a custom validator on dynamic data
pub fn validate(
  validator: CustomValidator(a),
  data: dynamic.Dynamic,
) -> Result(a, List(decode.DecodeError)) {
  case decode.run(data, validator.decoder) {
    Ok(value) ->
      case validator.validator(value) {
        Ok(validated) -> Ok(validated)
        Error(msg) ->
          Error([
            decode.DecodeError(
              expected: "valid data",
              found: "invalid: " <> msg,
              path: [],
            ),
          ])
      }
    Error(errors) -> Error(errors)
  }
}

/// Compose multiple validators together
///
/// ## Example
///
/// ```gleam
/// pub fn person_validator() -> CustomValidator(Person) {
///   let decoder = person_decoder()
///   let validator = compose_validators([
///     validate_name,
///     validate_age,
///     validate_email,
///   ])
///   custom_validator(decoder, validator)
/// }
/// ```
pub fn compose_validators(
  validators: List(fn(a) -> Result(a, String)),
) -> fn(a) -> Result(a, String) {
  fn(value: a) {
    list.fold(validators, Ok(value), fn(acc, validator) {
      case acc {
        Ok(v) -> validator(v)
        Error(e) -> Error(e)
      }
    })
  }
}

/// Validator for string length constraints
///
/// ## Example
///
/// ```gleam
/// pub fn username_validator() -> CustomValidator(String) {
///   custom_validator(
///     decode.string,
///     string_length_validator(3, 20, "Username")
///   )
/// }
/// ```
pub fn string_length_validator(
  min: Int,
  max: Int,
  field_name: String,
) -> fn(String) -> Result(String, String) {
  fn(value: String) {
    let length = string.length(value)
    case length >= min && length <= max {
      True -> Ok(value)
      False ->
        Error(
          field_name
          <> " must be between "
          <> string.inspect(min)
          <> " and "
          <> string.inspect(max)
          <> " characters",
        )
    }
  }
}

/// Validator for number range constraints
///
/// ## Example
///
/// ```gleam
/// pub fn age_validator() -> CustomValidator(Int) {
///   custom_validator(
///     decode.int,
///     number_range_validator(0, 150, "Age")
///   )
/// }
/// ```
pub fn number_range_validator(
  min: Int,
  max: Int,
  field_name: String,
) -> fn(Int) -> Result(Int, String) {
  fn(value: Int) {
    case value >= min && value <= max {
      True -> Ok(value)
      False ->
        Error(
          field_name
          <> " must be between "
          <> string.inspect(min)
          <> " and "
          <> string.inspect(max),
        )
    }
  }
}

/// Validator for email format
///
/// ## Example
///
/// ```gleam
/// pub fn email_field_validator() -> CustomValidator(String) {
///   custom_validator(decode.string, email_validator())
/// }
/// ```
pub fn email_validator() -> fn(String) -> Result(String, String) {
  fn(email: String) {
    case string.contains(email, "@") && string.contains(email, ".") {
      True -> Ok(email)
      False -> Error("Invalid email format")
    }
  }
}

/// Validator for non-empty strings
///
/// ## Example
///
/// ```gleam
/// pub fn required_string_validator() -> CustomValidator(String) {
///   custom_validator(decode.string, non_empty_string_validator("Field"))
/// }
/// ```
pub fn non_empty_string_validator(
  field_name: String,
) -> fn(String) -> Result(String, String) {
  fn(value: String) {
    case string.is_empty(value) {
      True -> Error(field_name <> " cannot be empty")
      False -> Ok(value)
    }
  }
}

/// Validator for optional fields with default values
///
/// ## Example
///
/// ```gleam
/// pub fn optional_with_default(
///   decoder: decode.Decoder(a),
///   default: a,
/// ) -> decode.Decoder(a) {
///   decode.optional(decoder)
///   |> decode.map(fn(opt) {
///     case opt {
///       Some(value) -> value
///       None -> default
///     }
///   })
/// }
/// ```
pub fn optional_with_default(
  decoder: decode.Decoder(a),
  default: a,
) -> decode.Decoder(a) {
  decode.optional(decoder)
  |> decode.map(fn(opt) {
    case opt {
      Some(value) -> value
      None -> default
    }
  })
}

/// Validator for enum/choice values
///
/// ## Example
///
/// ```gleam
/// pub fn status_validator() -> CustomValidator(String) {
///   custom_validator(
///     decode.string,
///     enum_validator(["active", "inactive", "pending"], "Status")
///   )
/// }
/// ```
pub fn enum_validator(
  allowed_values: List(String),
  field_name: String,
) -> fn(String) -> Result(String, String) {
  fn(value: String) {
    case list.contains(allowed_values, value) {
      True -> Ok(value)
      False ->
        Error(
          field_name <> " must be one of: " <> string.join(allowed_values, ", "),
        )
    }
  }
}

/// Create a validator for a list with item validation
///
/// ## Example
///
/// ```gleam
/// pub fn tags_validator() -> CustomValidator(List(String)) {
///   let item_validator = string_length_validator(1, 50, "Tag")
///   list_validator(decode.string, item_validator)
/// }
/// ```
pub fn list_validator(
  item_decoder: decode.Decoder(a),
  item_validator: fn(a) -> Result(a, String),
) -> CustomValidator(List(a)) {
  let decoder = decode.list(item_decoder)
  let validator = fn(items: List(a)) {
    list.try_map(items, item_validator)
    |> result.map_error(fn(err) { "List validation failed: " <> err })
  }
  CustomValidator(decoder: decoder, validator: validator)
}
