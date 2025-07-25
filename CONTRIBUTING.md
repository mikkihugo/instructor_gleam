# Contributing to Instructor for Gleam

Thank you for your interest in contributing! This project is in early development and needs help to become production ready.

## Current Status

⚠️ **This library is NOT production ready.** See [PRODUCTION_READINESS.md](PRODUCTION_READINESS.md) for details.

## Priority Areas for Contribution

### 🔴 Critical (Blockers)
1. **Fix Build Issues** - Resolve dependency problems preventing compilation
2. **Complete OpenAI Adapter** - Replace mock responses with real API integration
3. **Update CI Configuration** - Currently configured for Elixir instead of Gleam
4. **Integration Testing** - Add tests that work with real APIs

### 🟡 High Priority
1. **Streaming Implementation** - Real streaming JSON parsing and SSE handling
2. **Error Handling** - Comprehensive error recovery and timeout handling
3. **Additional Adapters** - Complete Anthropic, Gemini, Ollama implementations
4. **Configuration Management** - Environment variable support

### 🟢 Medium Priority
1. **Documentation** - API docs, deployment guides, examples
2. **Observability** - Logging, metrics, health checks
3. **Rate Limiting** - Built-in rate limiting and queue management
4. **Performance** - Connection pooling, optimization

## Development Setup

### Prerequisites
- [Gleam](https://gleam.run/getting-started/) 1.4.1 or later
- [Erlang/OTP](https://www.erlang.org/) 26 or later

### Setup Steps

```bash
# Clone the repository
git clone https://github.com/mikkihugo/instructor_gleam.git
cd instructor_gleam

# Try to download dependencies (currently failing)
gleam deps download

# Check code (currently failing due to dependencies)
gleam check

# Run tests (currently failing due to dependencies)
gleam test
```

**Note:** The build currently fails due to dependency issues. Fixing this is the top priority.

## Project Structure

```
src/
├── instructor.gleam              # Main API
├── instructor/
│   ├── types.gleam              # Core type definitions
│   ├── adapter.gleam            # Adapter behavior
│   ├── json_schema.gleam        # JSON schema generation
│   ├── validator.gleam          # Validation framework
│   ├── http_client.gleam        # HTTP client
│   └── adapters/
│       ├── openai.gleam         # OpenAI adapter (incomplete)
│       ├── anthropic.gleam      # Anthropic adapter (incomplete)
│       ├── gemini.gleam         # Gemini adapter (incomplete)
│       └── ollama.gleam         # Ollama adapter (incomplete)
test/
├── instructor_test.gleam        # Main tests
├── json_schema_test.gleam       # Schema tests
└── streaming_test.gleam         # Streaming tests
examples/
└── basic_usage.gleam           # Usage examples
```

## Contribution Guidelines

### Before You Start
1. Check the [Production Readiness](PRODUCTION_READINESS.md) document
2. Look at existing [Issues](https://github.com/mikkihugo/instructor_gleam/issues)
3. Consider starting with critical blockers

### Pull Request Process
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Add/update tests if applicable
5. Update documentation if needed
6. Submit a pull request

### Code Style
- Follow [Gleam's style guide](https://gleam.run/book/conventions/)
- Use `gleam format` to format code
- Write descriptive commit messages
- Include tests for new functionality

### Testing
- Add unit tests for new functions
- Include integration tests for API interactions
- Test error cases and edge conditions
- Ensure existing tests still pass

## Getting Help

- **Documentation**: Check the [README](README.md) and [Production Readiness](PRODUCTION_READINESS.md)
- **Issues**: Open an issue for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions

## Code of Conduct

This project follows the [Contributor Covenant](https://www.contributor-covenant.org/) code of conduct.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

All contributors will be recognized in the project documentation. Thank you for helping make Instructor for Gleam production ready!