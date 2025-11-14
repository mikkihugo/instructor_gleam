//// Codex (ChatGPT OAuth) Usage Examples
////
//// This example demonstrates how to use the Codex adapter for ChatGPT OAuth API.
//// Requires: ~/.codex/auth.json (run: codex login)

import gleam/io
import gleam/option.{None, Some}
import instructor
import instructor/adapters/codex
import instructor/types.{User}

/// Example 1: Simple chat with auto model selection
pub fn simple_chat_example() {
  io.println("Example 1: Simple chat with Codex")

  // Read auth from ~/.codex/auth.json
  case codex.codex_config_from_file(None, False) {
    Ok(config) -> {
      io.println("✓ Authenticated via OAuth")

      // Create a simple user message
      let messages = [types.Message(User, "What is 2 + 2? Just the number.")]

      // Make chat completion
      let result =
        instructor.chat_completion(
          instructor.default_config(),
          instructor.Single(instructor.string_response_model("Answer")),
          messages,
          Some("codex-mini-latest"),
          None,
          None,
          None,
          None,
          None,
        )

      case result {
        types.Success(answer) -> io.println("Answer: " <> answer)
        types.ValidationError(errors) ->
          io.println("Validation failed: " <> string.inspect(errors))
        types.AdapterError(error) -> io.println("API error: " <> error)
      }
    }
    Error(msg) -> io.println("Auth failed: " <> msg)
  }
}

/// Example 2: Complex task with reasoning
pub fn reasoning_example() {
  io.println("\nExample 2: Complex task with reasoning")

  // Use high reasoning effort for complex tasks
  case codex.codex_config_from_file(Some("high"), True) {
    Ok(config) -> {
      let messages = [
        types.Message(
          User,
          "Design the architecture for a distributed microservices system with event sourcing",
        ),
      ]

      let result =
        instructor.chat_completion(
          instructor.default_config(),
          instructor.Single(instructor.string_response_model("Architecture")),
          messages,
          Some("gpt-5-codex"),
          // Use full model for architecture
          None,
          Some(2000),
          None,
          None,
          None,
        )

      case result {
        types.Success(architecture) ->
          io.println("Architecture: " <> architecture)
        types.ValidationError(errors) ->
          io.println("Validation failed: " <> string.inspect(errors))
        types.AdapterError(error) -> io.println("API error: " <> error)
      }
    }
    Error(msg) -> io.println("Auth failed: " <> msg)
  }
}

/// Example 3: Smart model selection based on task
pub fn smart_selection_example() {
  io.println("\nExample 3: Smart model selection")

  let tasks = [
    #("What is Rust?", "low", "codex-mini-latest"),
    #("Implement error handling", "medium", "gpt-5-codex"),
    #("Design system architecture", "high", "gpt-5-codex"),
  ]

  list.each(tasks, fn(task) {
    let #(prompt, effort, model) = task

    case codex.codex_config_from_file(Some(effort), False) {
      Ok(config) -> {
        io.println(
          "\nTask: " <> prompt <> "\nModel: " <> model <> ", Effort: " <> effort,
        )

        let messages = [types.Message(User, prompt)]

        let result =
          instructor.chat_completion(
            instructor.default_config(),
            instructor.Single(instructor.string_response_model("Response")),
            messages,
            Some(model),
            None,
            None,
            None,
            None,
            None,
          )

        case result {
          types.Success(response) ->
            io.println(
              "✓ Got response: " <> string.slice(response, 0, 50) <> "...",
            )
          types.ValidationError(_) -> io.println("✗ Validation failed")
          types.AdapterError(_) -> io.println("✗ API error")
        }
      }
      Error(msg) -> io.println("Auth failed: " <> msg)
    }
  })
}

/// Run all examples
pub fn main() {
  io.println("🤖 Codex (ChatGPT OAuth) Examples\n")

  simple_chat_example()
  reasoning_example()
  smart_selection_example()

  io.println("\n✨ All examples completed!")
}
