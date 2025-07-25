// ⚠️ WARNING: This example does not currently work!
// The library is in early development and has build issues.
// See PRODUCTION_READINESS.md for current status.
//
// Example: Basic text classification with Instructor
import gleam/io
import gleam/option.{None, Some}
import instructor
import instructor/types
import instructor/adapters/openai

pub fn main() {
  // Create configuration
  let config = instructor.InstructorConfig(
    adapter: openai.openai_adapter(),
    default_model: "gpt-4o-mini",
    default_max_retries: 2,
  )
  
  // Create a response model for sentiment classification
  let sentiment_model = instructor.string_response_model(
    "Extract the sentiment as exactly one of: positive, negative, neutral"
  )
  
  // Define the conversation
  let messages = [
    instructor.system_message("You are a sentiment analysis expert. Always respond with exactly one word: positive, negative, or neutral."),
    instructor.user_message("I absolutely love programming in Gleam! It's such a wonderful language."),
  ]
  
  // Make the chat completion
  case instructor.chat_completion(
    config,
    sentiment_model,
    messages,
    None, // model (use default)
    Some(0.1), // temperature (low for consistency)
    Some(10), // max_tokens (just need one word)
    Some(types.Json), // mode
    None, // max_retries (use default)
    None, // validation_context
  ) {
    types.Success(sentiment) -> {
      io.println("Sentiment analysis result: " <> sentiment)
    }
    types.ValidationError(errors) -> {
      io.println("Validation failed with errors:")
      io.debug(errors)
    }
    types.AdapterError(error) -> {
      io.println("API error: " <> error)
    }
  }
}

// Example: Structured data extraction
pub fn extract_person_info() {
  let config = instructor.default_config()
  
  // For structured data, we'd normally create a custom validator
  // but for this example, we'll use a simple approach
  let person_model = instructor.string_response_model(
    "Extract person information as JSON with fields: name, age, occupation"
  )
  
  let messages = [
    instructor.system_message("Extract person information from the text and return as JSON."),
    instructor.user_message("John Smith is a 35-year-old software engineer who works at Google."),
  ]
  
  case instructor.chat_completion(
    config,
    person_model,
    messages,
    None,
    Some(0.0), // temperature 0 for deterministic results
    Some(100),
    Some(types.Json),
    Some(1), // retry once if validation fails
    None,
  ) {
    types.Success(person_json) -> {
      io.println("Extracted person info: " <> person_json)
    }
    types.ValidationError(errors) -> {
      io.println("Could not extract valid person info")
      io.debug(errors)
    }
    types.AdapterError(error) -> {
      io.println("API error: " <> error)
    }
  }
}

// Example: Using different adapters
pub fn ollama_example() {
  let config = instructor.InstructorConfig(
    adapter: instructor/adapters/ollama.ollama_adapter(),
    default_model: "llama2",
    default_max_retries: 1,
  )
  
  let summary_model = instructor.string_response_model(
    "Provide a one-sentence summary of the text"
  )
  
  let messages = [
    instructor.user_message("Gleam is a friendly language for building type-safe systems that scale! It compiles to Erlang and JavaScript."),
  ]
  
  case instructor.chat_completion(
    config,
    summary_model,
    messages,
    None,
    None,
    Some(50),
    Some(types.MdJson), // Ollama works well with markdown JSON
    None,
    None,
  ) {
    types.Success(summary) -> {
      io.println("Summary: " <> summary)
    }
    types.ValidationError(errors) -> {
      io.println("Summary generation failed")
      io.debug(errors)
    }
    types.AdapterError(error) -> {
      io.println("Ollama error: " <> error)
    }
  }
}