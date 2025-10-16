//// JSON Schema generation and manipulation
////
//// This module provides utilities for creating and working with JSON schemas,
//// which are used to describe the expected structure of LLM responses.
//// Schemas enable validation and structured data extraction from LLM outputs.
////
//// ## Example
////
//// ```gleam
//// import instructor/json_schema
////
//// let person_schema = 
////   json_schema.object_builder()
////   |> json_schema.add_string_field("name", "Person's name", True)
////   |> json_schema.add_int_field("age", "Person's age", True)
////   |> json_schema.build_object(Some("Person information"))
//// ```

import gleam/dict.{type Dict}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// JSON Schema representation following the JSON Schema specification
pub type JsonSchema {
  JsonSchema(
    type_: String,
    properties: Option(Dict(String, JsonSchema)),
    items: Option(JsonSchema),
    required: Option(List(String)),
    enum: Option(List(String)),
    description: Option(String),
    format: Option(String),
    pattern: Option(String),
    additional_properties: Option(Bool),
  )
}

/// Schema property definition
pub type SchemaProperty {
  StringProperty(description: Option(String), enum: Option(List(String)))
  IntProperty(
    description: Option(String),
    minimum: Option(Int),
    maximum: Option(Int),
  )
  FloatProperty(
    description: Option(String),
    minimum: Option(Float),
    maximum: Option(Float),
  )
  BoolProperty(description: Option(String))
  ArrayProperty(items: JsonSchema, description: Option(String))
  ObjectProperty(
    properties: Dict(String, JsonSchema),
    required: List(String),
    description: Option(String),
  )
  DateProperty(description: Option(String))
  DateTimeProperty(description: Option(String))
}

/// Convert a schema property to JsonSchema
pub fn property_to_schema(prop: SchemaProperty) -> JsonSchema {
  case prop {
    StringProperty(description, enum) ->
      JsonSchema(
        type_: "string",
        properties: None,
        items: None,
        required: None,
        enum: enum,
        description: description,
        format: None,
        pattern: None,
        additional_properties: None,
      )

    IntProperty(description, _minimum, _maximum) ->
      JsonSchema(
        type_: "integer",
        properties: None,
        items: None,
        required: None,
        enum: None,
        description: description,
        format: None,
        pattern: None,
        additional_properties: None,
      )

    FloatProperty(description, _minimum, _maximum) ->
      JsonSchema(
        type_: "number",
        properties: None,
        items: None,
        required: None,
        enum: None,
        description: description,
        format: None,
        pattern: None,
        additional_properties: None,
      )

    BoolProperty(description) ->
      JsonSchema(
        type_: "boolean",
        properties: None,
        items: None,
        required: None,
        enum: None,
        description: description,
        format: None,
        pattern: None,
        additional_properties: None,
      )

    ArrayProperty(items, description) ->
      JsonSchema(
        type_: "array",
        properties: None,
        items: Some(items),
        required: None,
        enum: None,
        description: description,
        format: None,
        pattern: None,
        additional_properties: None,
      )

    ObjectProperty(properties, required, description) ->
      JsonSchema(
        type_: "object",
        properties: Some(properties),
        items: None,
        required: Some(required),
        enum: None,
        description: description,
        format: None,
        pattern: None,
        additional_properties: Some(False),
      )

    DateProperty(description) ->
      JsonSchema(
        type_: "string",
        properties: None,
        items: None,
        required: None,
        enum: None,
        description: description,
        format: Some("date"),
        pattern: None,
        additional_properties: None,
      )

    DateTimeProperty(description) ->
      JsonSchema(
        type_: "string",
        properties: None,
        items: None,
        required: None,
        enum: None,
        description: description,
        format: Some("date-time"),
        pattern: None,
        additional_properties: None,
      )
  }
}

/// Convert JsonSchema to JSON
pub fn schema_to_json(schema: JsonSchema) -> json.Json {
  let JsonSchema(
    type_,
    properties,
    items,
    required,
    enum,
    description,
    format,
    pattern,
    additional_properties,
  ) = schema

  let base_fields = [#("type", json.string(type_))]

  let with_properties = case properties {
    Some(props) -> {
      let prop_json =
        dict.to_list(props)
        |> list.map(fn(pair) {
          let #(key, value) = pair
          #(key, schema_to_json(value))
        })
        |> json.object()
      [#("properties", prop_json), ..base_fields]
    }
    None -> base_fields
  }

  let with_items = case items {
    Some(item_schema) -> [
      #("items", schema_to_json(item_schema)),
      ..with_properties
    ]
    None -> with_properties
  }

  let with_required = case required {
    Some(req_list) -> [
      #("required", json.array(req_list, json.string)),
      ..with_items
    ]
    None -> with_items
  }

  let with_enum = case enum {
    Some(enum_list) -> [
      #("enum", json.array(enum_list, json.string)),
      ..with_required
    ]
    None -> with_required
  }

  let with_description = case description {
    Some(desc) -> [#("description", json.string(desc)), ..with_enum]
    None -> with_enum
  }

  let with_format = case format {
    Some(fmt) -> [#("format", json.string(fmt)), ..with_description]
    None -> with_description
  }

  let with_pattern = case pattern {
    Some(pat) -> [#("pattern", json.string(pat)), ..with_format]
    None -> with_format
  }

  let final_fields = case additional_properties {
    Some(add_props) -> [
      #("additionalProperties", json.bool(add_props)),
      ..with_pattern
    ]
    None -> with_pattern
  }

  json.object(final_fields)
}

/// Create a simple string schema
pub fn string_schema(description: Option(String)) -> JsonSchema {
  property_to_schema(StringProperty(description, None))
}

/// Create an integer schema
pub fn int_schema(description: Option(String)) -> JsonSchema {
  property_to_schema(IntProperty(description, None, None))
}

/// Create a float schema
pub fn float_schema(description: Option(String)) -> JsonSchema {
  property_to_schema(FloatProperty(description, None, None))
}

/// Create a boolean schema
pub fn bool_schema(description: Option(String)) -> JsonSchema {
  property_to_schema(BoolProperty(description))
}

/// Create an array schema
pub fn array_schema(
  items: JsonSchema,
  description: Option(String),
) -> JsonSchema {
  property_to_schema(ArrayProperty(items, description))
}

/// Create an object schema
pub fn object_schema(
  properties: Dict(String, JsonSchema),
  required: List(String),
  description: Option(String),
) -> JsonSchema {
  property_to_schema(ObjectProperty(properties, required, description))
}

/// Create a date schema
pub fn date_schema(description: Option(String)) -> JsonSchema {
  property_to_schema(DateProperty(description))
}

/// Create a datetime schema
pub fn datetime_schema(description: Option(String)) -> JsonSchema {
  property_to_schema(DateTimeProperty(description))
}

/// Create an enum schema
pub fn enum_schema(
  values: List(String),
  description: Option(String),
) -> JsonSchema {
  property_to_schema(StringProperty(description, Some(values)))
}

/// Convert schema to JSON string
pub fn schema_to_string(schema: JsonSchema) -> String {
  schema_to_json(schema)
  |> json.to_string()
}

// Advanced schema builders

/// Create a string schema with pattern validation
///
/// ## Example
///
/// ```gleam
/// // Email pattern
/// let email_schema = string_with_pattern(
///   Some("User email address"),
///   "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
/// )
/// ```
pub fn string_with_pattern(
  description: Option(String),
  pattern: String,
) -> JsonSchema {
  JsonSchema(
    type_: "string",
    properties: None,
    items: None,
    required: None,
    enum: None,
    description: description,
    format: None,
    pattern: Some(pattern),
    additional_properties: None,
  )
}

/// Create an integer schema with min/max constraints
///
/// ## Example
///
/// ```gleam
/// // Age between 0 and 150
/// let age_schema = int_with_range(
///   Some("Person's age"),
///   Some(0),
///   Some(150)
/// )
/// ```
pub fn int_with_range(
  description: Option(String),
  minimum: Option(Int),
  maximum: Option(Int),
) -> JsonSchema {
  // Note: We encode min/max in the description since JsonSchema type doesn't have them
  let enhanced_description = case description, minimum, maximum {
    Some(desc), Some(min), Some(max) ->
      Some(
        desc
        <> " (range: "
        <> int.to_string(min)
        <> " to "
        <> int.to_string(max)
        <> ")",
      )
    Some(desc), Some(min), None ->
      Some(desc <> " (minimum: " <> int.to_string(min) <> ")")
    Some(desc), None, Some(max) ->
      Some(desc <> " (maximum: " <> int.to_string(max) <> ")")
    _, _, _ -> description
  }

  property_to_schema(IntProperty(enhanced_description, minimum, maximum))
}

/// Create a number schema with min/max constraints
///
/// ## Example
///
/// ```gleam
/// // Score between 0.0 and 1.0
/// let score_schema = float_with_range(
///   Some("Confidence score"),
///   Some(0.0),
///   Some(1.0)
/// )
/// ```
pub fn float_with_range(
  description: Option(String),
  minimum: Option(Float),
  maximum: Option(Float),
) -> JsonSchema {
  // Note: We encode min/max in the description since JsonSchema type doesn't have them
  let enhanced_description = case description, minimum, maximum {
    Some(desc), Some(min), Some(max) ->
      Some(
        desc
        <> " (range: "
        <> string.inspect(min)
        <> " to "
        <> string.inspect(max)
        <> ")",
      )
    Some(desc), Some(min), None ->
      Some(desc <> " (minimum: " <> string.inspect(min) <> ")")
    Some(desc), None, Some(max) ->
      Some(desc <> " (maximum: " <> string.inspect(max) <> ")")
    _, _, _ -> description
  }

  property_to_schema(FloatProperty(enhanced_description, minimum, maximum))
}

/// Build a complex object schema using a builder pattern
///
/// ## Example
///
/// ```gleam
/// let person_schema = 
///   object_builder()
///   |> add_string_field("name", "Person's full name", True)
///   |> add_int_field("age", "Person's age", True)
///   |> add_string_field("email", "Email address", False)
///   |> build_object(Some("Person information"))
/// ```
pub type SchemaBuilder {
  SchemaBuilder(
    properties: Dict(String, JsonSchema),
    required_fields: List(String),
  )
}

/// Create a new schema builder
pub fn object_builder() -> SchemaBuilder {
  SchemaBuilder(properties: dict.new(), required_fields: [])
}

/// Add a string field to the schema builder
pub fn add_string_field(
  builder: SchemaBuilder,
  name: String,
  description: String,
  required: Bool,
) -> SchemaBuilder {
  let new_properties =
    dict.insert(builder.properties, name, string_schema(Some(description)))
  let new_required = case required {
    True -> [name, ..builder.required_fields]
    False -> builder.required_fields
  }
  SchemaBuilder(properties: new_properties, required_fields: new_required)
}

/// Add an integer field to the schema builder
pub fn add_int_field(
  builder: SchemaBuilder,
  name: String,
  description: String,
  required: Bool,
) -> SchemaBuilder {
  let new_properties =
    dict.insert(builder.properties, name, int_schema(Some(description)))
  let new_required = case required {
    True -> [name, ..builder.required_fields]
    False -> builder.required_fields
  }
  SchemaBuilder(properties: new_properties, required_fields: new_required)
}

/// Add a boolean field to the schema builder
pub fn add_bool_field(
  builder: SchemaBuilder,
  name: String,
  description: String,
  required: Bool,
) -> SchemaBuilder {
  let new_properties =
    dict.insert(builder.properties, name, bool_schema(Some(description)))
  let new_required = case required {
    True -> [name, ..builder.required_fields]
    False -> builder.required_fields
  }
  SchemaBuilder(properties: new_properties, required_fields: new_required)
}

/// Add an enum field to the schema builder
pub fn add_enum_field(
  builder: SchemaBuilder,
  name: String,
  description: String,
  values: List(String),
  required: Bool,
) -> SchemaBuilder {
  let new_properties =
    dict.insert(
      builder.properties,
      name,
      enum_schema(values, Some(description)),
    )
  let new_required = case required {
    True -> [name, ..builder.required_fields]
    False -> builder.required_fields
  }
  SchemaBuilder(properties: new_properties, required_fields: new_required)
}

/// Add an array field to the schema builder
pub fn add_array_field(
  builder: SchemaBuilder,
  name: String,
  description: String,
  items: JsonSchema,
  required: Bool,
) -> SchemaBuilder {
  let new_properties =
    dict.insert(
      builder.properties,
      name,
      array_schema(items, Some(description)),
    )
  let new_required = case required {
    True -> [name, ..builder.required_fields]
    False -> builder.required_fields
  }
  SchemaBuilder(properties: new_properties, required_fields: new_required)
}

/// Add a custom field to the schema builder
pub fn add_field(
  builder: SchemaBuilder,
  name: String,
  schema: JsonSchema,
  required: Bool,
) -> SchemaBuilder {
  let new_properties = dict.insert(builder.properties, name, schema)
  let new_required = case required {
    True -> [name, ..builder.required_fields]
    False -> builder.required_fields
  }
  SchemaBuilder(properties: new_properties, required_fields: new_required)
}

/// Build the final object schema from the builder
pub fn build_object(
  builder: SchemaBuilder,
  description: Option(String),
) -> JsonSchema {
  object_schema(builder.properties, builder.required_fields, description)
}
