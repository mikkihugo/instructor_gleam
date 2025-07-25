# Instructor for Gleam

Instructor is a Gleam library for structured prompting with Large Language Models. It converts LLM text outputs into validated data structures, enabling seamless integration between AI and traditional Gleam applications.

## Features

- **Structured Prompting**: Define response schemas and get validated structured data from LLMs
- **Multiple LLM Providers**: Support for OpenAI, Anthropic, Gemini, Groq, Ollama, and more
- **Validation & Retry Logic**: Automatic retry with error feedback when responses don't match schemas
- **Streaming Support**: Handle partial and array streaming responses
- **Type Safe**: Full Gleam type safety for LLM interactions

## Quick Start

⚠️ **Currently Not Functional** - The examples below show the intended API, but the library cannot be built or used yet due to critical issues. See [Development Status](#development-status) below.

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

⚠️ **This library is in early development and is NOT production ready.**

This is a port of the Elixir Instructor library to Gleam. The current implementation includes:

- ✅ Core types and data structures
- ✅ JSON schema generation
- ✅ Validation framework (replacing Ecto)
- ✅ Basic adapter pattern
- 🚧 OpenAI adapter foundation (placeholder implementations)
- 🚧 HTTP client implementation
- 🚧 Streaming support
- 🚧 Additional adapters (Anthropic, Gemini, etc.)
- 🚧 Comprehensive test suite
- ❌ Build system (dependency issues)
- ❌ Real API integration
- ❌ Production features

**Current Blockers:**
- Cannot build due to dependency resolution issues
- Adapter implementations return mock data
- No real LLM API integration
- CI configured for Elixir instead of Gleam

See [PRODUCTION_READINESS.md](PRODUCTION_READINESS.md) for a detailed assessment.

## Installation

⚠️ **Not recommended for installation yet** - The library is in early development and cannot be built.

When ready, installation will be:

```toml
[dependencies]
instructor = { git = "https://github.com/mikkihugo/instructor_gleam" }
```

For development/contribution:
```bash
git clone https://github.com/mikkihugo/instructor_gleam.git
cd instructor_gleam
# Note: gleam deps download currently fails
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.