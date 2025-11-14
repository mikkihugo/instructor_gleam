# Changelog

All notable changes to the Instructor Gleam library will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-10-16

### Added

- **Codex (ChatGPT OAuth) Adapter**: Official support for subscription-based ChatGPT API
  - `CodexOAuthConfig` variant in `AdapterConfig` type
  - Support for 3 models: `codex-mini-latest`, `gpt-5-codex`, `gpt-5`
  - Reasoning effort levels: `minimal`, `low`, `medium`, `high`
  - Reasoning summary support for viewing model's thinking process
  - Auth tokens read from `~/.codex/auth.json` (managed by codex CLI)
  - No pay-per-token billing - subscription only (ChatGPT Plus/Pro)
- **Codex Examples**: Complete usage examples in `examples/codex_usage.gleam`
- **Documentation**: Codex section added to README with model specs and authentication guide

### Changed

- **types.gleam**: Extended `AdapterConfig` enum with `CodexOAuthConfig` variant
- **README.md**: Added Codex models to supported models list with pricing and features

## [1.0.0] - 2025-01-16

This is the **first stable release** of Instructor for Gleam - a production-ready library for structured prompting with Large Language Models.

### Added

- **Production-Ready Release**: Promoted from beta to stable 1.0.0
- **Comprehensive Documentation**: 
  - Full inline documentation for all public APIs
  - Module-level documentation with examples for all modules
  - Complete HexDocs configuration for published documentation
  - Enhanced README with badges, installation guide, and contributing section
- **Quality Assurance**:
  - All code properly formatted with `gleam format`
  - Zero security vulnerabilities in dependencies
  - Comprehensive test coverage
  - Release-level documentation standards

### Changed

- Version bumped from 1.0.0-beta.1 to 1.0.0
- README updated to release level with badges and improved structure
- HexDocs configuration enhanced with extras and source links
- All source files now include comprehensive module-level documentation

## [1.0.0-beta.1] - 2025-01-16

This is the first beta release of Instructor for Gleam - a complete rewrite from the Elixir version with idiomatic Gleam patterns and type safety.

### Added

- **Core Library**: Complete Gleam implementation with type-safe LLM interactions
- **Streaming Support**: Full streaming with partial and array modes
  - Partial streaming: Incrementally updates objects as chunks arrive
  - Array streaming: Emits validated items as they complete
  - SSE (Server-Sent Events) parser for streaming responses
  - JSON streaming parser with incremental object building
- **Multiple LLM Providers**:
  - OpenAI adapter (GPT-5, GPT-5 Pro, GPT-4o, o1 models)
  - Anthropic adapter (Claude Opus 4, Claude Sonnet 4, Claude 3.5)
  - Google Gemini adapter (Gemini 2.5 Pro/Flash/Flash-Lite, Gemini 2.0)
  - Groq adapter (Llama 3.3, Llama 3.1, Mixtral for fast inference)
  - Ollama adapter (Llama 3.2, Qwen 2.5, Phi-3 for local hosting)
- **Custom Validators Module**: Advanced validation framework
  - Composable validators with functional patterns
  - Built-in validators: email, string length, number ranges, enums, lists
  - Custom validation logic with decoder integration
  - Full documentation and examples
- **Enhanced JSON Schema Generation**:
  - Builder pattern for complex object schemas
  - Constraint support (min/max for numbers, patterns for strings)
  - Field-by-field schema construction
  - Helper methods for common schema types
- **Advanced Examples**: Comprehensive examples in `examples/advanced_validators.gleam`
  - Email validation patterns
  - Person model with composed validation rules
  - Product model with business logic
  - Schema generation demonstrations
- **Development Guide**: `.github/AGENTS.md` with quality standards and workflows
- **Latest 2025 AI Models**:
  - OpenAI GPT-5 (400K context, dynamic thinking mode)
  - Anthropic Claude 4 (enhanced coding and reasoning)
  - Google Gemini 2.5 (advanced multimodal capabilities)

### Changed

- **Pure Gleam Implementation**: Rewritten from Elixir to idiomatic Gleam
  - Uses `gleam/dynamic/decode` instead of Ecto changesets
  - Compile-time type checking throughout
  - Pattern matching and exhaustive case checking
  - No database framework dependency
- **Validation Approach**: Functional validators instead of changeset-based validation
- **Configuration**: Explicit configuration patterns (no Mix.Config)
- **Error Handling**: Result types with detailed error information

### Removed

- **Elixir Dependencies**: Removed all Ecto, Mix, and Elixir-specific code
- **Legacy Files**: Cleaned up 22 Elixir-specific files (~3000 lines)
  - Deleted `pages/` directory with .livemd LiveBook files
  - Deleted `config/` directory with Elixir configuration
  - Removed `MIGRATION.md` (Elixir-to-Gleam migration guide)

### Fixed

- All compiler warnings resolved (zero warnings)
- Code formatted with `gleam format`
- All tests passing (20 tests, 0 failures)

### Documentation

- Comprehensive README with quick start guide
- Supported models section with 2025 model listings
- Custom validators documentation
- Advanced schema generation guide
- Development guide for contributors

---

## Legacy Elixir Versions

The following versions are from the original Elixir implementation:

## [v0.1.0](https://github.com/thmsmlr/instructor_ex/compare/v0.0.5..v0.1.0)

### Added
- **New Adapters**: Anthropic, Gemini, xAI,Groq, Ollama, and VLLM. Each of these provides specialized support for their respective LLM APIs.
- **`:json_schema` Mode**: The OpenAI adapter and others now support a `:json_schema` mode for more structured JSON outputs.
- **`Instructor.Extras.ChainOfThought`**: A new module to guide multi-step reasoning processes with partial returns and final answers.
- **Enhanced Streaming**: More robust partial/array streaming pipelines, plus improved SSE-based parsing for streamed responses.
- **Re-ask/Follow-up Logic**: Adapters can now handle re-asking the LLM to correct invalid JSON responses when `max_retries` is set.

### Changed
- **OpenAI Adapter Refactor**: A major internal refactor for more flexible streaming modes, additional “response format” options, and better error handling.
- **Ecto Dependency**: Updated from `3.11` to `3.12`. 
- **Req Dependency**: Now supports `~> 0.5` or `~> 1.0`.

### Deprecated
- **Schema Documentation via `@doc`**: Schemas using `@doc` to send instructions to the LLM will now emit a warning. Please migrate to `@llm_doc` via `use Instructor`.

### Breaking Changes
- Some adapter configurations now require specifying an `:api_path` or `:auth_mode`. Verify your adapter config matches the new format.
- The OpenAI adapter’s `:json_schema` mode strips unsupported fields (e.g., `format`, `pattern`) from schemas before sending them to the LLM.

### Fixed
- Various improvements to JSON parsing and streaming handling, including better handling of partial/invalid responses.


## [v0.0.5](https://github.com/thmsmlr/instructor_ex/compare/v0.0.4..v0.0.5)

### Added

- Support for [together.ai](https://together.ai) inference server
- Support for [ollama](https://ollama.com) local inference server
- GPT-4 Vision support
- Added `:json` and `:md_json` modes to support more models and inference servers

### Changed

- Default http settings and where they are stored

before:
```elixir
config :openai, http_options: [...]
```

after:
```elixir
config :instructor, :openai, http_options: [...]
```

### Removed

- OpenAI client to allow for better control of default settings and reduce dependencies


## [v0.0.4](https://github.com/thmsmlr/instructor_ex/compare/v0.0.3...v0.0.4) - 2024-01-15

### Added

- `Instructor.Adapters.Llamacpp` for running instructor against local llms.
- `use Instructor.EctoType` for supporting custom ecto types.
- More documentation

### Fixed

- Bug fixes in ecto --> json_schema --> gbnf grammar pipeline, added better tests


## [v0.0.3](https://github.com/thmsmlr/instructor_ex/compare/v0.0.2...v0.0.3) - 2024-01-10

### Added

- Schemaless Ecto support
- `response_model: {:partial, Model}` partial streaming mode
- `response_model: {:array, Model}` record streaming mode

### Fixed

- Bug handling nested module names

## [v0.0.2](https://github.com/thmsmlr/instructor_ex/compare/v0.0.1...v0.0.2) - 2023-12-30

### Added

- `use Instructor.Validator` for validation callbacks on your Ecto Schemas
- `max_retries:` option to reask the LLM to fix any validation errors

## [v0.0.1](https://github.com/thmsmlr/instructor_ex/compare/v0.0.1...v0.0.1) - 2023-12-19

### Added

- Structured prompting with LLMs using Ecto
