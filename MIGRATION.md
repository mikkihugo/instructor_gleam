# Migration Guide: Elixir to Gleam Instructor

This document outlines the key differences and migration path from the Elixir Instructor library to the Gleam version.

## Architecture Changes

### Type System
**Elixir (Ecto Schemas):**
```elixir
defmodule User do
  use Ecto.Schema
  use Instructor.Validator

  embedded_schema do
    field(:name, :string)
    field(:age, :integer)
    field(:email, :string)
  end

  def validate_changeset(changeset) do
    changeset
    |> validate_required([:name, :age])
    |> validate_format(:email, ~r/@/)
  end
end
```

**Gleam (Custom Types + Validators):**
```gleam
import instructor/validator
import instructor/json_schema
import gleam/dict

pub type User {
  User(name: String, age: Int, email: String)
}

pub fn user_validator() -> validator.Validator(User) {
  validator.custom_validator(
    user_decoder(),
    fn(user) {
      case string.is_empty(user.name) {
        True -> Error("Name cannot be empty")
        False -> case user.age < 0 {
          True -> Error("Age must be positive")
          False -> case string.contains(user.email, "@") {
            True -> Ok(user)
            False -> Error("Invalid email format")
          }
        }
      }
    }
  )
}

pub fn user_schema() -> json_schema.JsonSchema {
  let properties = dict.from_list([
    #("name", json_schema.string_schema(Some("User's name"))),
    #("age", json_schema.int_schema(Some("User's age"))),
    #("email", json_schema.string_schema(Some("User's email"))),
  ])
  json_schema.object_schema(properties, ["name", "age", "email"], Some("User information"))
}
```

### API Usage

**Elixir:**
```elixir
{:ok, user} = Instructor.chat_completion(
  model: "gpt-4o-mini",
  response_model: User,
  messages: [
    %{role: "user", content: "Extract user: John Doe, 30, john@example.com"}
  ]
)
```

**Gleam:**
```gleam
let config = instructor.default_config()
let user_model = instructor.ResponseModel.Single(user_validator(), user_schema())
let messages = [instructor.user_message("Extract user: John Doe, 30, john@example.com")]

case instructor.chat_completion(
  config,
  user_model,
  messages,
  None, None, None, None, None, None
) {
  types.Success(user) -> // Handle success
  types.ValidationError(errors) -> // Handle validation errors
  types.AdapterError(error) -> // Handle API errors
}
```

## Key Differences

### 1. Configuration Management

**Elixir (Mix Config):**
```elixir
config :instructor, adapter: Instructor.Adapters.OpenAI
config :instructor, :openai, api_key: System.get_env("OPENAI_API_KEY")
```

**Gleam (Explicit Configuration):**
```gleam
import instructor/config

let config = config.openai_config("your-api-key", None)
  |> config.with_model("gpt-4o")
  |> config.with_max_retries(3)
```

### 2. Error Handling

**Elixir (Tuples):**
```elixir
case Instructor.chat_completion(params) do
  {:ok, result} -> handle_success(result)
  {:error, %Ecto.Changeset{} = changeset} -> handle_validation_error(changeset)
  {:error, reason} -> handle_api_error(reason)
end
```

**Gleam (Custom Types):**
```gleam
case instructor.chat_completion(params) {
  types.Success(result) -> handle_success(result)
  types.ValidationError(errors) -> handle_validation_error(errors)
  types.AdapterError(error) -> handle_api_error(error)
}
```

### 3. Streaming

**Elixir (Streams):**
```elixir
Instructor.chat_completion(
  model: "gpt-4o-mini",
  response_model: {:partial, User},
  stream: true,
  messages: messages
)
|> Enum.each(fn
  {:partial, user} -> IO.inspect(user, label: "Partial")
  {:ok, user} -> IO.inspect(user, label: "Final")
end)
```

**Gleam (Iterators):**
```gleam
let partial_model = instructor.ResponseModel.Partial(user_validator(), user_schema())
// Streaming implementation would use Gleam's Iterator type
```

### 4. Adapter Pattern

**Elixir (Behaviours):**
```elixir
defmodule MyAdapter do
  @behaviour Instructor.Adapter

  @impl true
  def chat_completion(params, config) do
    # Implementation
  end
end
```

**Gleam (Custom Types):**
```gleam
pub fn my_adapter() -> adapter.Adapter(String) {
  adapter.Adapter(
    name: "my_adapter",
    chat_completion: my_chat_completion,
    streaming_chat_completion: my_streaming_chat_completion,
    reask_messages: my_reask_messages,
  )
}
```

## Migration Steps

### 1. Convert Ecto Schemas
1. Replace `defmodule` with `pub type`
2. Convert fields to record fields
3. Create separate validator functions
4. Create JSON schema functions

### 2. Update API Calls
1. Replace Mix config with explicit configuration
2. Update function calls to use new parameter structure
3. Handle new error types

### 3. Migrate Validation Logic
1. Convert Ecto changeset validations to custom validators
2. Use composition to build complex validators
3. Update error handling patterns

### 4. Adapter Migration
1. Convert behaviour implementations to custom type functions
2. Update HTTP client calls to use new abstraction
3. Migrate any custom adapter logic

## Benefits of Gleam Version

### 1. Type Safety
- Compile-time error checking
- No runtime type errors
- Better IDE support with precise types

### 2. Functional Programming
- Immutable data structures
- Pure functions
- Composable validators

### 3. Performance
- Efficient pattern matching
- Optimized Erlang bytecode
- Low-latency garbage collection

### 4. Interoperability
- Runs on Erlang VM
- Can call Elixir/Erlang code
- JavaScript compilation for browser use

## Common Patterns

### Building Complex Validators
```gleam
pub fn person_validator() -> validator.Validator(Person) {
  validator.custom_validator(
    person_decoder(),
    fn(person) {
      person
      |> validate_name()
      |> result.then(validate_age)
      |> result.then(validate_email)
    }
  )
}
```

### Handling Optional Fields
```gleam
pub type MaybeUser {
  MaybeUser(name: String, age: Option(Int), email: Option(String))
}

pub fn maybe_user_validator() -> validator.Validator(MaybeUser) {
  // Use optional_validator for optional fields
  let age_validator = validator.optional_validator(validator.int_validator())
  let email_validator = validator.optional_validator(validator.string_validator())
  // Combine validators...
}
```

### Response Model Composition
```gleam
pub fn list_response_model(item_validator: validator.Validator(a), item_schema: json_schema.JsonSchema) -> instructor.ResponseModel(List(a)) {
  let list_schema = json_schema.array_schema(item_schema, Some("List of items"))
  let list_validator = validator.list_validator(item_validator)
  instructor.ResponseModel.Single(list_validator, list_schema)
}
```

This migration maintains the core functionality while leveraging Gleam's type system for better safety and developer experience.