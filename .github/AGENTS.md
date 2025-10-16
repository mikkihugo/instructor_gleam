# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview

Instructor is a Gleam library for structured prompting with Large Language Models.

## Development Workflow

### Before Committing Changes

Always run the following commands to ensure code quality:

1. **Format the code**:
   ```bash
   gleam format
   ```

2. **Check formatting** (ensure no files need formatting):
   ```bash
   gleam format --check
   ```

3. **Build the project** (check for compilation errors):
   ```bash
   gleam build
   ```

4. **Run tests** (ensure all tests pass):
   ```bash
   gleam test
   ```

### Quality Standards

- **No warnings**: All code must compile without warnings
- **No formatting issues**: All files must pass `gleam format --check`
- **All tests pass**: `gleam test` must complete successfully
- **Type safe**: Leverage Gleam's type system for safety

### Common Issues to Avoid

1. **Unused variables**: Prefix with `_` if intentionally unused
   ```gleam
   // Bad
   fn example(params: ChatParams, config: Config) -> Result {
     // params and config never used
   }
   
   // Good
   fn example(_params: ChatParams, _config: Config) -> Result {
     // Intentionally unused
   }
   ```

2. **Unused imports**: Remove unused type imports
   ```gleam
   // Bad
   import gleam/option.{type Option, None, Some}
   // Only using None and Some
   
   // Good  
   import gleam/option.{None, Some}
   ```

3. **Dynamic value creation**: Use proper JSON parsing
   ```gleam
   // Bad
   dynamic.from(Nil)  // This function doesn't exist
   
   // Good
   let assert Ok(value) = json.parse("{}", using: decode.dynamic)
   ```

## Essential Commands

### Development
- `gleam deps download` - Install dependencies
- `gleam format` - Format the code
- `gleam build` - Build the project
- `gleam test` - Run all tests
- `gleam format --check` - Verify formatting (for CI)

### Testing
- `gleam test` - Run all tests
- `gleam test --target javascript` - Run tests on JavaScript target

## Code Style

- Follow Gleam's official style guide
- Use `gleam format` to automatically format code
- Keep functions small and focused
- Use descriptive variable names
- Add documentation comments for public functions

## Pull Request Checklist

Before submitting a PR, ensure:

- [ ] Code is formatted (`gleam format`)
- [ ] No formatting issues (`gleam format --check` passes)
- [ ] Code compiles without warnings (`gleam build`)
- [ ] All tests pass (`gleam test`)
- [ ] New functionality has tests
- [ ] Documentation is updated (README, inline comments)
- [ ] Commit messages are descriptive

## Architecture Notes

### Adapters
- Each LLM provider has its own adapter in `src/instructor/adapters/`
- Adapters implement: `chat_completion`, `streaming_chat_completion`, `reask_messages`
- Currently supported: OpenAI, Anthropic, Gemini, Groq, Ollama

### Validation
- Uses `gleam/dynamic/decode` for type-safe validation
- Custom validators in `src/instructor/validator.gleam`
- Composable validation logic

### Streaming
- SSE parser: `src/instructor/sse_parser.gleam`
- JSON parser: `src/instructor/json_parser.gleam`
- Two modes: Partial (incremental updates) and Array (complete items)

## Common Development Tasks

### Adding a New Adapter

1. Create new file: `src/instructor/adapters/provider_name.gleam`
2. Implement the adapter interface
3. Add config type to `src/instructor/types.gleam`
4. Add config helper to `src/instructor/config.gleam`
5. Update validation and model recommendations in `config.gleam`
6. Test the adapter
7. Update README

### Adding a New Validator

1. Add to `src/instructor/validator.gleam`
2. Include documentation with examples
3. Add tests
4. Update `examples/advanced_validators.gleam` if applicable

## Troubleshooting

### Build Fails
- Run `gleam clean` and rebuild
- Check for syntax errors
- Ensure all dependencies are installed

### Tests Fail
- Check test output for specific failures
- Ensure mock data is properly formatted
- Verify validators are working correctly

### Format Check Fails
- Run `gleam format` to fix
- Check for any manual formatting that conflicts

## Resources

- [Gleam Language Tour](https://tour.gleam.run/)
- [Gleam Standard Library](https://hexdocs.pm/gleam_stdlib/)
- [Gleam HTTP](https://hexdocs.pm/gleam_http/)
- [Gleam JSON](https://hexdocs.pm/gleam_json/)
