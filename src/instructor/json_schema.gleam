import gleam/dict.{type Dict}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

/// JSON Schema representation
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

  let base_fields = [
    #("type", json.string(type_)),
  ]

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
