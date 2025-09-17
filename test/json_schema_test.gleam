import gleeunit
import gleeunit/should
import gleam/dict
import instructor/json_schema
import gleam/option.{Some}
import gleam/string

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
  string.contains(json_str, "\"type\":\"string\"")
  |> should.be_true()
}

pub fn json_schema_integer_test() {
  let schema = json_schema.int_schema(Some("A test integer field"))
  let json_str = json_schema.schema_to_string(schema)

  string.contains(json_str, "\"type\":\"integer\"")
  |> should.be_true()
}

pub fn json_schema_object_test() {
  let properties =
    dict.from_list([
      #("name", json_schema.string_schema(Some("Person's name"))),
      #("age", json_schema.int_schema(Some("Person's age"))),
    ])

  let schema =
    json_schema.object_schema(
      properties,
      ["name", "age"],
      Some("A person object"),
    )
  let json_str = json_schema.schema_to_string(schema)

  string.contains(json_str, "\"type\":\"object\"")
  |> should.be_true()
  string.contains(json_str, "\"properties\"")
  |> should.be_true()
  string.contains(json_str, "\"required\"")
  |> should.be_true()
}

pub fn json_schema_enum_test() {
  let schema =
    json_schema.enum_schema(["red", "green", "blue"], Some("Color choice"))
  let json_str = json_schema.schema_to_string(schema)

  string.contains(json_str, "\"enum\"")
  |> should.be_true()
  string.contains(json_str, "\"red\"")
  |> should.be_true()
}