import gleam/list
import gleam/result
import gleam/string

/// An application error is either a Defect or a Failure.
/// A Defect is an unexpected application error, which shouldn't be shown to the user.
/// A Failure is an expected error.
/// Context is just information about the place in the application to build a stack trace.
pub type Problem {
  Context(String)
  Defect(String)
  Failure(String)
}

/// A stack of problems and context.
pub type Stack {
  Stack(problem: Problem, problems: List(Problem))
}

/// Alias to Result with Stack as error type.
pub type Outcome(t) =
  Result(t, Stack)

/// Wrap a String into a Defect
pub fn defect(value: String) -> Problem {
  Defect(value)
}

/// Wrap a String into a Failure
pub fn failure(value: String) -> Problem {
  Failure(value)
}

fn problem_is_error(problem: Problem) -> Bool {
  case problem {
    Context(_) -> False
    Defect(_) -> True
    Failure(_) -> True
  }
}

/// Create a Defect wrapped in an Problem
pub fn error_with_defect(defect: String) -> Outcome(t) {
  Error(Stack(problem: Defect(defect), problems: []))
}

/// Create Failure wrapped in an Problem
pub fn error_with_failure(failure: String) -> Outcome(t) {
  Error(new_stack_with_failure(failure))
}

/// Create a new Stack with the given Problem
pub fn new_stack(error: Problem) -> Stack {
  Stack(error, [])
}

/// Create a Defect wrapped in an Stack
pub fn new_stack_with_defect(failure: String) -> Stack {
  new_stack(Defect(failure))
}

/// Create a Failure wrapped in an Stack
pub fn new_stack_with_failure(failure: String) -> Stack {
  new_stack(Failure(failure))
}

/// Get a list of problems for a Stack
pub fn stack_to_problems(stack: Stack) -> List(Problem) {
  [stack.problem, ..stack.problems]
}

fn top_problem(problems: List(Problem)) -> Result(Problem, Nil) {
  list.find(problems, problem_is_error)
}

/// Get the failure at the top of the stack.
/// If the top is not a failure, then return the given default.
/// Use this for showing an error message to users.
pub fn unwrap_failure(stack: Stack, default: String) -> String {
  stack
  |> stack_to_problems
  |> list.fold_until(from: default, with: fn(message, problem) {
    case problem {
      Context(_) -> list.Continue(message)
      Defect(_) -> list.Stop(message)
      Failure(failure_message) -> list.Stop(failure_message)
    }
  })
}

/// Convert an Problem into a wrapped Defect
pub fn into_defect(result: Result(t, String)) -> Outcome(t) {
  result.map_error(result, fn(e) { Stack(Defect(e), []) })
}

/// Convert an Problem into a wrapped Failure
pub fn into_failure(result: Result(t, String)) -> Outcome(t) {
  result.map_error(result, fn(e) { Stack(Failure(e), []) })
}

/// Convert an Problem into a wrapped Defect, by using a mapping function
pub fn map_into_defect(
  result: Result(t, e),
  mapper: fn(e) -> String,
) -> Outcome(t) {
  result
  |> result.map_error(mapper)
  |> into_defect
}

/// Replaces an Problem with a wrapped Defect
pub fn as_defect(result: Result(t, Nil), e: String) -> Outcome(t) {
  result.replace_error(result, Stack(Defect(e), []))
}

/// Replaces an Problem with a wrapped Failure
pub fn as_failure(result: Result(t, Nil), e: String) -> Outcome(t) {
  result.replace_error(result, Stack(Failure(e), []))
}

/// Add context to an Outcome
pub fn add_context(
  outcome outcome: Outcome(t),
  context context: String,
) -> Outcome(t) {
  result.map_error(outcome, fn(stack) { add_context_to_stack(stack, context) })
}

pub fn add_context_to_stack(stack: Stack, value: String) -> Stack {
  add_to_stack(stack, Context(value))
}

pub fn add_defect_to_stack(stack: Stack, value: String) -> Stack {
  add_to_stack(stack, Defect(value))
}

pub fn add_failure_to_stack(stack: Stack, value: String) -> Stack {
  add_to_stack(stack, Failure(value))
}

/// Add a Problem to the top of a Stack
pub fn add_to_stack(stack: Stack, new_problem: Problem) -> Stack {
  Stack(new_problem, [stack.problem, ..stack.problems])
}

pub fn stack_to_lines(stack: Stack) -> List(String) {
  stack_to_problems(stack)
  |> list.map(pretty_print_problem)
}

@internal
pub fn outcome_to_lines(outcome: Outcome(t)) -> List(String) {
  case outcome {
    Ok(_) -> []
    Error(stack) -> stack_to_lines(stack)
  }
}

pub fn pretty_print(stack: Stack) -> String {
  let problem =
    stack
    |> stack_to_problems
    |> top_problem
    |> result.map(pretty_print_problem)
    |> result.unwrap("Error")

  let stack =
    stack_to_lines(stack)
    |> string.join("\n  ")

  problem <> "\n\nstack:\n  " <> stack
}

fn pretty_print_problem(problem: Problem) -> String {
  case problem {
    Context(value) -> "Context: " <> value
    Defect(value) -> "Defect: " <> value
    Failure(value) -> "Failure: " <> value
  }
}
