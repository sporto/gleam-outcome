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

pub type Stack =
  NonEmptyList(StackEntry)

/// Alias to Result with Problem as error type.
pub type Outcome(t) =
  Result(t, Problem)

pub fn new_defect(message: String) -> Problem {
  Defect(
    message: message,
    stack: non_empty_list.single(StackEntryDefect(message)),
  )
}

pub fn new_failure(message: String) -> Problem {
  Failure(
    message: message,
    stack: non_empty_list.single(StackEntryFailure(message)),
  )
}

/// Create a Defect wrapped in an Error
pub fn error_with_defect(defect: String) -> Outcome(t) {
  Error(new_defect(defect))
}

/// Create Failure wrapped in an Error
pub fn error_with_failure(failure: String) -> Outcome(t) {
  Error(new_failure(failure))
}

/// Convert an `Error(String)` into an `Error(Defect)`
pub fn into_defect(result: Result(t, String)) -> Outcome(t) {
  result.map_error(result, new_defect)
}

/// Convert an `Error(String)` into an `Error(Failure)`
pub fn into_failure(result: Result(t, String)) -> Outcome(t) {
  result.map_error(result, new_failure)
}

/// Convert an `Error(t)` into a wrapped Defect, by using a mapping function
pub fn map_into_defect(
  result: Result(t, e),
  mapper: fn(e) -> String,
) -> Outcome(t) {
  result
  |> result.map_error(mapper)
  |> into_defect
}

/// Replaces an `Error(Nil)` with an `Error(Defect)`
pub fn as_defect(result: Result(t, Nil), e: String) -> Outcome(t) {
  result.replace_error(result, new_defect(e))
}

/// Replaces an Error(Nil) with an Error(Failure)
pub fn as_failure(result: Result(t, Nil), e: String) -> Outcome(t) {
  result.replace_error(result, new_failure(e))
}

/// Add context to an Outcome
pub fn with_context(
  outcome outcome: Outcome(t),
  context context: String,
) -> Outcome(t) {
  result.map_error(outcome, fn(problem) {
    add_context_to_problem(problem, context)
  })
}

pub fn with_defect(
  outcome outcome: Outcome(t),
  defect_message defect_message: String,
) -> Outcome(t) {
  result.map_error(outcome, problem_with_defect(_, defect_message))
}

pub fn with_failure(
  outcome outcome: Outcome(t),
  failure_message failure_message: String,
) -> Outcome(t) {
  result.map_error(outcome, problem_with_failure(_, failure_message))
}

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

pub fn problem_with_failure(
  problem: Problem,
  failure_message: String,
) -> Problem {
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

/// Add an StackEntry to the top of a Problem stack
pub fn add_to_problem_stack(
  problem: Problem,
  stack_entry: StackEntry,
) -> Problem {
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
pub fn add_context_to_problem(problem: Problem, value: String) -> Problem {
  add_to_problem_stack(problem, StackEntryContext(value))
}

pub fn add_failure_to_problem_stack(
  problem: Problem,
  failure: String,
) -> Problem {
  add_to_problem_stack(problem, StackEntryFailure(failure))
}

pub fn add_defect_to_problem_stack(problem: Problem, failure: String) -> Problem {
  add_to_problem_stack(problem, StackEntryFailure(failure))
}

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
