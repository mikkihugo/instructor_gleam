# Instructor for Gleam

[![Hex Package](https://img.shields.io/hexpm/v/instructor)](https://hex.pm/packages/instructor)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue)](https://hexdocs.pm/instructor/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Instructor is a Gleam library for structured prompting with Large Language Models. It converts LLM text outputs into validated data structures, enabling seamless integration between AI and traditional Gleam applications.

## Features

- **Structured Prompting**: Define response schemas and get validated structured data from LLMs
- **Multiple LLM Providers**: Support for OpenAI (GPT-5), Anthropic (Claude 4), Gemini (2.5), Groq, and Ollama
- **Validation & Retry Logic**: Automatic retry with error feedback when responses don't match schemas
- **Streaming Support**: Handle partial and array streaming responses
- **Type Safe**: Full Gleam type safety for LLM interactions

## Supported Models (2025)

### OpenAI
- **gpt-5** - Latest GPT-5 model (Aug 2025) with 400K context, dynamic thinking mode
- **gpt-5-pro** - GPT-5 Pro variant for advanced tasks
- **gpt-4o** - GPT-4 Omni model
- **gpt-4o-mini** - Fast, cost-effective GPT-4 variant
- **o1-preview** - Advanced reasoning model

### Anthropic Claude 4
- **claude-opus-4** - Most powerful Claude 4 model for complex coding and long-running tasks
- **claude-sonnet-4** - Balanced performance with enhanced coding and reasoning (recommended)
- **claude-3-5-sonnet-20241022** - Previous generation Claude 3.5
- **claude-3-5-haiku-20241022** - Fast, efficient Claude 3.5

### Google Gemini 2.5
- **gemini-2.5-pro** - Most capable Gemini 2.5 for complex reasoning
- **gemini-2.5-flash** - High performance with cost efficiency (recommended)
- **gemini-2.5-flash-lite** - Lightweight, high-throughput variant
- **gemini-2.0-flash-exp** - Experimental Gemini 2.0

### Groq (Fast Inference)
- **llama-3.3-70b-versatile** - Latest Llama 3.3
- **llama-3.1-70b-versatile** - Llama 3.1 70B
- **mixtral-8x7b-32768** - Mixtral MoE model

### Ollama (Local)
- **llama3.2** - Latest Llama 3.2
- **qwen2.5** - Qwen 2.5 models
- **mistral** - Mistral models

### Codex (ChatGPT OAuth - Subscription Only)
- **codex-mini-latest** - Fast, 200K context, optimized for speed ($1.50/$6 per 1M tokens)
- **gpt-5-codex** - Full quality, 272K context, better reasoning
- **gpt-5** - General purpose, 272K context

**Authentication**: Requires `~/.codex/auth.json` (run: `codex login`)
**Reasoning Effort**: `minimal`, `low`, `medium`, `high` (thinking depth)
**No Pay-Per-Token**: Subscription-based via ChatGPT Plus/Pro only

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
import instructor/adapters/openai
import instructor/adapters/codex

// OpenAI (pay-per-token)
let openai_config = instructor.InstructorConfig(
  adapter: openai.openai_adapter(),
  default_model: "gpt-4o-mini",
  default_max_retries: 3,
)

// Codex (ChatGPT OAuth - subscription only)
case codex.codex_config_from_file(Some("medium"), False) {
  Ok(codex_auth) -> {
    let codex_config = instructor.InstructorConfig(
      adapter: codex.codex_adapter(),
      default_model: "codex-mini-latest",
      default_max_retries: 2,
    )
    // Use codex_config for completions
  }
  Error(msg) -> io.println("Codex auth failed: " <> msg)
}
```

See `examples/codex_usage.gleam` for complete Codex examples including smart model selection and reasoning effort configuration.

## Development Status

This is a **production-ready release (v1.0.0)** of the Instructor library for Gleam. The implementation includes:

- ✅ Core types and data structures
- ✅ JSON schema generation
- ✅ Validation using `gleam/dynamic/decode`
- ✅ Adapter pattern for multiple LLMs
- ✅ OpenAI, Anthropic, Gemini, Groq, Ollama, and Codex adapters
- ✅ HTTP client implementation
- ✅ Comprehensive test suite
- ✅ Streaming support (partial and array streaming modes)
- ✅ Custom validators for complex domain models
- ✅ Advanced JSON schema generation with builder pattern
- ✅ Full inline documentation
- ✅ HexDocs published documentation

## Installation

Add to your `gleam.toml`:

```toml
[dependencies]
instructor = "~> 1.0"
```

Or install from the command line:

```sh
gleam add instructor
```

## API Documentation

Full API documentation is available on [HexDocs](https://hexdocs.pm/instructor/).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Install Gleam (v1.11.0 or later)
2. Clone the repository
3. Install dependencies: `gleam deps download`
4. Run tests: `gleam test`
5. Format code: `gleam format`

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

This library is inspired by the [Instructor](https://github.com/jxnl/instructor) library for Python and its Elixir port. Special thanks to the Gleam community for their excellent language and tooling.