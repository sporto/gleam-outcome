import gleam/list
import gleam/result
import gleam/string
import non_empty_list.{type NonEmptyList}

/// The error type ie. `Result(t, Problem)`
/// An application error is either a Defect or a Failure.
/// A Defect is an unexpected application error, which shouldn't be shown to the user.
/// A Failure is an expected error.
pub type Problem {
  Defect(message: String, stack: Stack)
  Failure(message: String, stack: Stack)
}

/// Stax entries
/// Context is just information about the place in the application to build a stack trace.
pub type StackEntry {
  StackEntryContext(String)
  StackEntryDefect(String)
  StackEntryFailure(String)
}

/// A stack of problems or context
pub type Stack =
  NonEmptyList(StackEntry)

/// Alias to Result with Problem as error type.
pub type Outcome(t) =
  Result(t, Problem)

/// Create a new Defect
/// This is a lower level function.
/// Prefer to use `error_with_defect` instead,
/// which gives you a Defect wrapped in an Error
@internal
pub fn new_defect(message: String) -> Problem {
  Defect(
    message: message,
    stack: non_empty_list.single(StackEntryDefect(message)),
  )
}

/// Create a new Failure
/// This is a lower level function.
/// Prefer to use `error_with_failure` instead,
/// which gives you a Failure wrapped in an Error
@internal
pub fn new_failure(message: String) -> Problem {
  Failure(
    message: message,
    stack: non_empty_list.single(StackEntryFailure(message)),
  )
}

/// Create a Defect wrapped in an Error
///
/// ## Example
///
/// ```gleam
/// case something {
///   True -> Ok("Yay")
///   False -> error_with_defect("Something went wrong")
/// }
/// ```
///
pub fn error_with_defect(defect: String) -> Outcome(t) {
  Error(new_defect(defect))
}

/// Create Failure wrapped in an Error
///
/// ## Example
///
/// ```gleam
/// case something {
///   True -> Ok("Yay")
///   False -> error_with_failure("Invalid input")
/// }
/// ```
///
pub fn error_with_failure(failure: String) -> Outcome(t) {
  Error(new_failure(failure))
}

/// Convert an `Error(String)` into an `Error(Defect)`
/// This is useful when you have a `Result(t, String)` and
/// want to convert it into a `Result(t, Problem)`
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> into_defect
/// ```
pub fn into_defect(result: Result(t, String)) -> Outcome(t) {
  result.map_error(result, new_defect)
}

/// Convert an `Error(String)` into an `Error(Failure)`
/// This is useful when you have a `Result(t, String)` and
/// want to convert it into a `Result(t, Problem)`
///
/// ## Example
///
/// ```gleam
/// Error("Invalid input")
/// |> into_failure
/// ```
pub fn into_failure(result: Result(t, String)) -> Outcome(t) {
  result.map_error(result, new_failure)
}

/// Convert an `Error(t)` into a wrapped Defect, by using a mapping function
/// Similar to into_defect, but takes a function to map the error value to a string
pub fn map_into_defect(
  result: Result(t, e),
  mapper: fn(e) -> String,
) -> Outcome(t) {
  result
  |> result.map_error(mapper)
  |> into_defect
}

/// Convert an `Error(t)` into a wrapped Failure, by using a mapping function
/// Similar to into_defect, but takes a function to map the error value to a string
pub fn map_into_failure(
  result: Result(t, e),
  mapper: fn(e) -> String,
) -> Outcome(t) {
  result
  |> result.map_error(mapper)
  |> into_failure
}

/// Replaces an `Error(Nil)` with an `Error(Defect)`
/// This is useful when you have a `Result(t, Nil)` and
/// want to convert it into a `Result(t, Problem)`
///
/// ## Example
///
/// ```gleam
/// Error(Nil)
/// |> as_defect("Something went wrong")
/// ```
pub fn as_defect(result: Result(t, Nil), e: String) -> Outcome(t) {
  result.replace_error(result, new_defect(e))
}

/// Replaces an Error(Nil) with an Error(Failure)
/// This is useful when you have a `Result(t, Nil)` and
/// want to convert it into a `Result(t, Problem)`
///
/// ## Example
///
/// ```gleam
/// Error(Nil)
/// |> as_failure("Invalid input")
/// ```
pub fn as_failure(result: Result(t, Nil), e: String) -> Outcome(t) {
  result.replace_error(result, new_failure(e))
}

/// Add context to an Outcome
/// This will add a Context entry to the stack
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> into_defect
/// |> with_context("In find user function")
/// ```
///
pub fn with_context(
  outcome outcome: Outcome(t),
  context context: String,
) -> Outcome(t) {
  result.map_error(outcome, fn(problem) {
    add_context_to_problem(problem, context)
  })
}

/// Add a defect to an Outcome (Result)
/// If the outcome is already a defect, it will stay as the previous defect.
/// This always adds the defect to the stack.
///
/// ## Example
///
/// ```gleam
/// Error("Invalid input")
/// |> into_failure
/// |> with_defect("Something went wrong")
/// ```
pub fn with_defect(
  outcome outcome: Outcome(t),
  defect_message defect_message: String,
) -> Outcome(t) {
  result.map_error(outcome, problem_with_defect(_, defect_message))
}

/// Add a failure to an Outcome (Result).
/// If the outcome is already a defect, it will stay as the previous defect.
/// This always adds the failure to the stack.
///
/// ## Example
///
/// ```gleam
/// Error("Invalid input")
/// |> into_failure
/// |> with_failure("Another failure")
/// ```
pub fn with_failure(
  outcome outcome: Outcome(t),
  failure_message failure_message: String,
) -> Outcome(t) {
  result.map_error(outcome, problem_with_failure(_, failure_message))
}

/// Add a defect to a Problem
/// This is a low level function.
/// Prefer to use `with_defect` instead which maps the Error.
@internal
pub fn problem_with_defect(problem: Problem, defect_message: String) -> Problem {
  case problem {
    Defect(current_defect_message, stack) ->
      // A defect stays a defect
      // We only push the failure into the stack
      Defect(
        current_defect_message,
        push_to_stack(stack, StackEntryDefect(defect_message)),
      )
    Failure(_, stack) ->
      // A failure becomes a defect
      Defect(
        defect_message,
        push_to_stack(stack, StackEntryDefect(defect_message)),
      )
  }
}

/// Add a failure to a Problem
/// This is a low level function.
/// Prefer to use `with_failure` instead which maps the Error.
@internal
pub fn problem_with_failure(problem: Problem, failure_message: String) -> Problem {
  case problem {
    Defect(current_defect_message, stack) ->
      // A defect stays a defect
      // We only push the failure into the stack
      Defect(
        current_defect_message,
        push_to_stack(stack, StackEntryFailure(failure_message)),
      )
    Failure(_, stack) ->
      Failure(
        failure_message,
        push_to_stack(stack, StackEntryFailure(failure_message)),
      )
  }
}

/// Add an StackEntry to the top of a Problem stack.
/// This is a low level function.
/// You shouldn't need to use this, unless you need to change the stack directly.
fn add_to_problem_stack(problem: Problem, stack_entry: StackEntry) -> Problem {
  case problem {
    Defect(problem, stack) -> Defect(problem, push_to_stack(stack, stack_entry))
    Failure(problem, stack) ->
      Failure(problem, push_to_stack(stack, stack_entry))
  }
}

fn push_to_stack(stack: Stack, entry: StackEntry) -> NonEmptyList(StackEntry) {
  non_empty_list.prepend(stack, entry)
}

/// A context to a Problem
/// This is a low level function.
/// Prefer to use `with_context` instead which maps the Error.
fn add_context_to_problem(problem: Problem, value: String) -> Problem {
  add_to_problem_stack(problem, StackEntryContext(value))
}

/// Use this to show a failure to a user.
/// If the Problem is a failure, it will show that
/// otherwise it will show the default message given.
/// We don't want to show defect messages to users.
///
/// ## Example
///
/// ```gleam
/// case result {
///  Ok(value) -> io.debug("Success")
///  Error(problem) -> io.error(unwrap_failure(problem, "Something went wrong"))
/// }
/// ```
pub fn unwrap_failure(problem: Problem, default_message: String) -> String {
  case problem {
    Defect(_, _) -> default_message
    Failure(message, _) -> message
  }
}

fn stack_to_lines(stack: Stack) -> List(String) {
  stack
  |> non_empty_list.to_list
  |> list.map(pretty_print_stack_entry)
}

@internal
pub fn outcome_to_lines(outcome: Outcome(t)) -> List(String) {
  case outcome {
    Ok(_) -> []
    Error(problem) -> stack_to_lines(problem.stack)
  }
}

/// Pretty print a Problem, including the stack.
/// The latest problem appears at the top of the stack.
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> into_defect
/// |> with_context("In find user function")
/// |> with_failure("Another failure")
/// |> pretty_print
/// ```
///
/// ```
/// Defect: Something went wrong
///
/// stack:
///  Failure: Another failure
///  Context: In find user function
///  Defect: Something went wrong
/// ```
pub fn pretty_print(problem: Problem) -> String {
  let stack =
    problem.stack
    |> stack_to_lines
    |> string.join("\n  ")

  prettry_print_problem_value(problem) <> "\n\nstack:\n  " <> stack
}

@internal
pub fn pretty_print_outcome(outcome: Outcome(t)) -> String {
  case outcome {
    Ok(_) -> "Ok"
    Error(problem) -> pretty_print(problem)
  }
}

fn prettry_print_problem_value(problem: Problem) -> String {
  case problem {
    Defect(value, _) -> "Defect: " <> value
    Failure(value, _) -> "Failure: " <> value
  }
}

fn pretty_print_stack_entry(entry: StackEntry) -> String {
  case entry {
    StackEntryContext(value) -> "Context: " <> value
    StackEntryDefect(value) -> "Defect: " <> value
    StackEntryFailure(value) -> "Failure: " <> value
  }
}
