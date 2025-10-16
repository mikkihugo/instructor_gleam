/// Advanced examples demonstrating custom validators and complex domain models
///
/// This example shows how to:
/// 1. Create custom type decoders for complex domain models
/// 2. Build sophisticated validators with business logic
/// 3. Use advanced JSON schema generation
/// 4. Compose validators for reusability
import gleam/dynamic/decode
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import instructor
import instructor/json_schema
import instructor/types
import instructor/validator

// Example 1: Email validation with custom validator
pub type Email {
  Email(address: String)
}

pub fn email_decoder() -> decode.Decoder(Email) {
  use address <- decode.field("address", decode.string)
  decode.success(Email(address))
}

pub fn email_validator() -> validator.CustomValidator(Email) {
  let decoder = email_decoder()
  let validation_fn = fn(email: Email) {
    case
      string.contains(email.address, "@")
      && string.contains(email.address, ".")
      && string.length(email.address) > 5
    {
      True -> Ok(email)
      False -> Error("Invalid email format")
    }
  }
  validator.custom_validator(decoder, validation_fn)
}

// Example 2: Person with multiple validation rules
pub type Person {
  Person(name: String, age: Int, email: String, status: String)
}

pub fn person_decoder() -> decode.Decoder(Person) {
  use name <- decode.field("name", decode.string)
  use age <- decode.field("age", decode.int)
  use email <- decode.field("email", decode.string)
  use status <- decode.field("status", decode.string)
  decode.success(Person(name: name, age: age, email: email, status: status))
}

/// Validate person name is not empty and reasonable length
fn validate_name(person: Person) -> Result(Person, String) {
  case string.is_empty(person.name) {
    True -> Error("Name cannot be empty")
    False ->
      case string.length(person.name) < 100 {
        True -> Ok(person)
        False -> Error("Name is too long (max 100 characters)")
      }
  }
}

/// Validate age is within reasonable range
fn validate_age(person: Person) -> Result(Person, String) {
  case person.age >= 0 && person.age <= 150 {
    True -> Ok(person)
    False -> Error("Age must be between 0 and 150")
  }
}

/// Validate email format
fn validate_email(person: Person) -> Result(Person, String) {
  case
    string.contains(person.email, "@") && string.contains(person.email, ".")
  {
    True -> Ok(person)
    False -> Error("Invalid email format")
  }
}

/// Validate status is one of allowed values
fn validate_status(person: Person) -> Result(Person, String) {
  let allowed = ["active", "inactive", "pending"]
  case list.contains(allowed, person.status) {
    True -> Ok(person)
    False -> Error("Status must be one of: active, inactive, pending")
  }
}

pub fn person_validator() -> validator.CustomValidator(Person) {
  let decoder = person_decoder()
  let validation_fn =
    validator.compose_validators([
      validate_name,
      validate_age,
      validate_email,
      validate_status,
    ])
  validator.custom_validator(decoder, validation_fn)
}

// Example 3: Using advanced JSON schema builders
pub fn create_person_schema() -> json_schema.JsonSchema {
  json_schema.object_builder()
  |> json_schema.add_string_field("name", "Person's full name", True)
  |> json_schema.add_int_field("age", "Person's age in years", True)
  |> json_schema.add_string_field("email", "Contact email address", True)
  |> json_schema.add_enum_field(
    "status",
    "Account status",
    ["active", "inactive", "pending"],
    True,
  )
  |> json_schema.build_object(Some("Person information"))
}

// Example 4: Product with price range validation
pub type Product {
  Product(name: String, price: Float, category: String, tags: List(String))
}

pub fn product_decoder() -> decode.Decoder(Product) {
  use name <- decode.field("name", decode.string)
  use price <- decode.field("price", decode.float)
  use category <- decode.field("category", decode.string)
  use tags <- decode.field("tags", decode.list(decode.string))
  decode.success(Product(
    name: name,
    price: price,
    category: category,
    tags: tags,
  ))
}

fn validate_product_name(product: Product) -> Result(Product, String) {
  case string.is_empty(product.name) || string.length(product.name) < 3 {
    True -> Error("Product name must be at least 3 characters")
    False -> Ok(product)
  }
}

fn validate_product_price(product: Product) -> Result(Product, String) {
  case product.price > 0.0 && product.price < 1_000_000.0 {
    True -> Ok(product)
    False -> Error("Price must be between $0 and $1,000,000")
  }
}

fn validate_product_category(product: Product) -> Result(Product, String) {
  let allowed = ["electronics", "clothing", "food", "books", "other"]
  case list.contains(allowed, product.category) {
    True -> Ok(product)
    False ->
      Error(
        "Category must be one of: electronics, clothing, food, books, other",
      )
  }
}

fn validate_product_tags(product: Product) -> Result(Product, String) {
  case list.length(product.tags) <= 10 {
    True -> {
      // Check each tag is not empty
      let all_valid = list.all(product.tags, fn(tag) { !string.is_empty(tag) })
      case all_valid {
        True -> Ok(product)
        False -> Error("Tags cannot be empty")
      }
    }
    False -> Error("Maximum 10 tags allowed")
  }
}

pub fn product_validator() -> validator.CustomValidator(Product) {
  let decoder = product_decoder()
  let validation_fn =
    validator.compose_validators([
      validate_product_name,
      validate_product_price,
      validate_product_category,
      validate_product_tags,
    ])
  validator.custom_validator(decoder, validation_fn)
}

pub fn create_product_schema() -> json_schema.JsonSchema {
  json_schema.object_builder()
  |> json_schema.add_string_field("name", "Product name", True)
  |> json_schema.add_field(
    "price",
    json_schema.float_with_range(
      Some("Product price in USD"),
      Some(0.0),
      Some(1_000_000.0),
    ),
    True,
  )
  |> json_schema.add_enum_field(
    "category",
    "Product category",
    ["electronics", "clothing", "food", "books", "other"],
    True,
  )
  |> json_schema.add_array_field(
    "tags",
    "Product tags (max 10)",
    json_schema.string_schema(Some("Tag")),
    True,
  )
  |> json_schema.build_object(Some("Product information"))
}

// Example 5: Using validators with Instructor
pub fn extract_person_with_validation() {
  let config = instructor.default_config()

  // Note: In a real implementation, you would integrate the custom validator
  // with the response model. This example shows the pattern.
  let person_model = instructor.string_response_model("Extract person as JSON")

  let messages = [
    instructor.system_message(
      "Extract person information with fields: name, age, email, status (active/inactive/pending)",
    ),
    instructor.user_message(
      "John Doe is a 30-year-old active user with email john@example.com",
    ),
  ]

  case
    instructor.chat_completion(
      config,
      person_model,
      messages,
      None,
      Some(0.0),
      Some(200),
      Some(types.Json),
      Some(2),
      None,
    )
  {
    types.Success(json_str) -> {
      io.println("Extracted person (would validate with custom validator):")
      io.println(json_str)
    }
    types.ValidationError(errors) -> {
      io.println("Validation failed:")
      io.debug(errors)
    }
    types.AdapterError(error) -> {
      io.println("API error: " <> error)
    }
  }
}

// Example 6: Demonstrating schema generation
pub fn demonstrate_schema_generation() {
  io.println("\n=== Person Schema ===")
  let person_schema = create_person_schema()
  io.println(json_schema.schema_to_string(person_schema))

  io.println("\n=== Product Schema ===")
  let product_schema = create_product_schema()
  io.println(json_schema.schema_to_string(product_schema))

  io.println("\n=== Email Pattern Schema ===")
  let email_pattern_schema =
    json_schema.string_with_pattern(
      Some("Email address"),
      "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
    )
  io.println(json_schema.schema_to_string(email_pattern_schema))
}

pub fn main() {
  io.println("=== Advanced Custom Validators Examples ===\n")
  demonstrate_schema_generation()
  io.println("\n=== Extraction Example ===")
  extract_person_with_validation()
}
