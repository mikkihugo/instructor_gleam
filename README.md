# Instructor for Gleam

Instructor is a Gleam library for structured prompting with Large Language Models. It converts LLM text outputs into validated data structures, enabling seamless integration between AI and traditional Gleam applications.

## Features

- **Structured Prompting**: Define response schemas and get validated structured data from LLMs
- **Multiple LLM Providers**: Support for OpenAI, Anthropic, Gemini, Groq, Ollama, and more
- **Validation & Retry Logic**: Automatic retry with error feedback when responses don't match schemas
- **Streaming Support**: Handle partial and array streaming responses
- **Type Safe**: Full Gleam type safety for LLM interactions

## Quick Start

```gleam
import instructor
import instructor/types

// Create configuration
let config = instructor.default_config()

// Create a simple response model
let response_model = instructor.string_response_model("Extract the sentiment as positive, negative, or neutral")

// Make a chat completion
let messages = [instructor.user_message("I love Gleam programming!")]

case instructor.chat_completion(
  config,
  response_model,
  messages,
  None, // model (uses default)
  None, // temperature 
  None, // max_tokens
  None, // mode
  None, // max_retries
  None, // validation_context
) {
  types.Success(result) -> io.println("Sentiment: " <> result)
  types.ValidationError(errors) -> io.println("Validation failed: " <> string.join(errors, ", "))
  types.AdapterError(error) -> io.println("API error: " <> error)
}
```

## Core Concepts

### Response Models

Response models define the structure and validation for LLM outputs:

```gleam
// Simple string response
let string_model = instructor.string_response_model("Description of the field")

// Integer response
let int_model = instructor.int_response_model("A number between 1-10")

// Boolean response  
let bool_model = instructor.bool_response_model("True if positive sentiment")
```

### Custom Validators

For complex domain models, use custom validators with business logic:

```gleam
import instructor/validator

pub type Person {
  Person(name: String, age: Int, email: String)
}

pub fn person_validator() -> validator.CustomValidator(Person) {
  let decoder = person_decoder()
  let validation = validator.compose_validators([
    validate_name,
    validate_age, 
    validate_email,
  ])
  validator.custom_validator(decoder, validation)
}
```

See `examples/advanced_validators.gleam` for complete examples.

### Advanced JSON Schema Generation

Build sophisticated schemas with the schema builder:

```gleam
import instructor/json_schema

let person_schema = 
  json_schema.object_builder()
  |> json_schema.add_string_field("name", "Person's name", True)
  |> json_schema.add_int_field("age", "Person's age", True)
  |> json_schema.add_enum_field("status", "Status", ["active", "inactive"], True)
  |> json_schema.build_object(Some("Person information"))

// With constraints
let score_schema = json_schema.float_with_range(
  Some("Confidence score"),
  Some(0.0),
  Some(1.0)
)

// With pattern validation
let email_schema = json_schema.string_with_pattern(
  Some("Email address"),
  "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
)
```

### Messages

Create messages for conversation:

```gleam
let messages = [
  instructor.system_message("You are a helpful assistant."),
  instructor.user_message("What is the capital of France?"),
]
```

### Response Modes

Different modes for LLM interaction:

- `Tools` - OpenAI function calling (most reliable)
- `Json` - JSON mode 
- `JsonSchema` - Structured outputs with schema
- `MdJson` - JSON in markdown code blocks

## Configuration

Configure adapters in your application:

```gleam
import instructor/types

let config = instructor.InstructorConfig(
  adapter: openai_adapter(),
  default_model: "gpt-4o-mini", 
  default_max_retries: 3,
)
```

## Development Status

This is a port of the Elixir Instructor library to Gleam. The current implementation includes:

- ✅ Core types and data structures
- ✅ JSON schema generation
- ✅ Validation using `gleam/dynamic/decode`
- ✅ Adapter pattern for multiple LLMs
- ✅ OpenAI, Anthropic, Gemini, Groq, and Ollama adapters
- ✅ HTTP client implementation
- ✅ Basic test suite
- ✅ Streaming support (partial and array streaming modes)
- ✅ Custom validators for complex domain models
- ✅ Advanced JSON schema generation with builder pattern

## Installation

Add to your `gleam.toml`:

```toml
[dependencies]
gleam_stdlib = "~> 0.34"
gleam_http = "~> 4.1"
gleam_httpc = "~> 5.0"
gleam_json = "~> 3.0"
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.