import gleam/list
import gleeunit
import gleeunit/should
import instructor/adapter

pub fn main() {
  gleeunit.main()
}

// Test streaming_iterator with empty list
pub fn streaming_iterator_empty_test() {
  let iterator = adapter.streaming_iterator([])

  case iterator.next() {
    Error(Nil) -> True |> should.be_true()
    Ok(_) -> should.fail()
  }
}

// Test streaming_iterator with single item
pub fn streaming_iterator_single_test() {
  let iterator = adapter.streaming_iterator(["item1"])

  case iterator.next() {
    Ok(#(item, next_iter)) -> {
      item |> should.equal("item1")
      // Next should be empty
      case next_iter.next() {
        Error(Nil) -> True |> should.be_true()
        Ok(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test streaming_iterator with multiple items
pub fn streaming_iterator_multiple_test() {
  let iterator = adapter.streaming_iterator(["item1", "item2", "item3"])

  case iterator.next() {
    Ok(#(item1, iter2)) -> {
      item1 |> should.equal("item1")
      case iter2.next() {
        Ok(#(item2, iter3)) -> {
          item2 |> should.equal("item2")
          case iter3.next() {
            Ok(#(item3, iter4)) -> {
              item3 |> should.equal("item3")
              case iter4.next() {
                Error(Nil) -> True |> should.be_true()
                Ok(_) -> should.fail()
              }
            }
            Error(_) -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test iterator_to_list with empty iterator
pub fn iterator_to_list_empty_test() {
  let iterator = adapter.streaming_iterator([])
  let result = adapter.iterator_to_list(iterator)

  result |> should.equal([])
}

// Test iterator_to_list with single item
pub fn iterator_to_list_single_test() {
  let iterator = adapter.streaming_iterator(["item1"])
  let result = adapter.iterator_to_list(iterator)

  result |> should.equal(["item1"])
}

// Test iterator_to_list with multiple items
pub fn iterator_to_list_multiple_test() {
  let iterator = adapter.streaming_iterator(["item1", "item2", "item3"])
  let result = adapter.iterator_to_list(iterator)

  result |> should.equal(["item1", "item2", "item3"])
}

// Test iterator_to_list preserves order
pub fn iterator_to_list_order_test() {
  let items = ["a", "b", "c", "d", "e"]
  let iterator = adapter.streaming_iterator(items)
  let result = adapter.iterator_to_list(iterator)

  result |> should.equal(items)
}

// Test mock_adapter creation
pub fn mock_adapter_test() {
  let mock = adapter.mock_adapter()

  mock.name |> should.equal("mock")
}

// Test mock_adapter chat_completion
pub fn mock_adapter_chat_completion_test() {
  let mock = adapter.mock_adapter()

  case
    mock.chat_completion(
      types.ChatParams(
        model: "test",
        messages: [],
        temperature: option.None,
        max_tokens: option.None,
        stream: False,
        mode: types.Tools,
        max_retries: 0,
        validation_context: [],
      ),
      types.OpenAIConfig("test", option.None),
    )
  {
    Ok(response) -> response |> should.equal("{\"result\": \"mock response\"}")
    Error(_) -> should.fail()
  }
}

// Test mock_adapter streaming_chat_completion
pub fn mock_adapter_streaming_test() {
  let mock = adapter.mock_adapter()

  let iterator =
    mock.streaming_chat_completion(
      types.ChatParams(
        model: "test",
        messages: [],
        temperature: option.None,
        max_tokens: option.None,
        stream: True,
        mode: types.Tools,
        max_retries: 0,
        validation_context: [],
      ),
      types.OpenAIConfig("test", option.None),
    )

  let items = adapter.iterator_to_list(iterator)
  items |> should.equal(["{\"partial\": true}", "{\"result\": \"final\"}"])
}

// Test mock_adapter reask_messages
pub fn mock_adapter_reask_test() {
  let mock = adapter.mock_adapter()

  let messages =
    mock.reask_messages(
      "response",
      types.ChatParams(
        model: "test",
        messages: [],
        temperature: option.None,
        max_tokens: option.None,
        stream: False,
        mode: types.Tools,
        max_retries: 0,
        validation_context: [],
      ),
      types.OpenAIConfig("test", option.None),
    )

  messages |> should.equal([])
}

// Test creating custom iterator
pub fn custom_iterator_test() {
  let items = [1, 2, 3, 4, 5]
  let iterator = adapter.streaming_iterator(items)

  // Consume first item
  case iterator.next() {
    Ok(#(first, rest)) -> {
      first |> should.equal(1)

      // Convert rest to list
      let remaining = adapter.iterator_to_list(rest)
      remaining |> should.equal([2, 3, 4, 5])
    }
    Error(_) -> should.fail()
  }
}

// Test iterator consumption in steps
pub fn iterator_step_by_step_test() {
  let iterator = adapter.streaming_iterator(["a", "b", "c"])

  // First step
  case iterator.next() {
    Ok(#(item, iter2)) -> {
      item |> should.equal("a")

      // Second step
      case iter2.next() {
        Ok(#(item2, iter3)) -> {
          item2 |> should.equal("b")

          // Third step
          case iter3.next() {
            Ok(#(item3, iter4)) -> {
              item3 |> should.equal("c")

              // Fourth step (should be empty)
              case iter4.next() {
                Error(Nil) -> True |> should.be_true()
                Ok(_) -> should.fail()
              }
            }
            Error(_) -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test iterator with different types
pub fn iterator_int_test() {
  let numbers = [10, 20, 30]
  let iterator = adapter.streaming_iterator(numbers)
  let result = adapter.iterator_to_list(iterator)

  result |> should.equal([10, 20, 30])
}

pub fn iterator_bool_test() {
  let bools = [True, False, True]
  let iterator = adapter.streaming_iterator(bools)
  let result = adapter.iterator_to_list(iterator)

  result |> should.equal([True, False, True])
}

// Test large iterator
pub fn iterator_large_list_test() {
  let large_list = list.range(1, 100)
  let iterator = adapter.streaming_iterator(large_list)
  let result = adapter.iterator_to_list(iterator)

  list.length(result) |> should.equal(100)

  // Check first and last elements
  case result {
    [first, ..rest] -> {
      first |> should.equal(1)
      case list.last(rest) {
        Ok(last) -> last |> should.equal(100)
        Error(_) -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

import gleam/option
import instructor/types
