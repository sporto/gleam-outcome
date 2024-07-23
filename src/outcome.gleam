import gleam/list
import gleam/result

/// An application error is either a Defect or a Failure.
/// A Defect is an unexpected application error, which shouldn't be shown to the user.
/// A Failure is an expected error.
/// Context is just information about the place in the application to build a stack trace.
pub type Error {
  Context(String)
  Defect(String)
  Failure(String)
}

/// The error type. This is a stack that stores the latest problem and a list of previous problems.
pub type ErrorStack {
  ErrorStack(problem: Error, problems: List(Error))
}

/// Alias to Result with ErrorStack as error type.
pub type Outcome(t) =
  Result(t, ErrorStack)

/// Create a wrapped Defect
pub fn defect(defect: String) -> Outcome(t) {
  Error(ErrorStack(problem: Defect(defect), problems: []))
}

/// Create a wrapped Failure
pub fn failure(failure: String) -> Outcome(t) {
  Error(ErrorStack(problem: Failure(failure), problems: []))
}

/// Get a list of problems for a ErrorStack
pub fn stack_to_problems(stack: ErrorStack) -> List(Error) {
  [stack.problem, ..stack.problems]
}

/// Get the failure at the top of the stack.
/// If the top is not a failure, then return the given default.
/// Use this for showing an error message to users.
pub fn unwrap_failure(stack: ErrorStack, default: String) -> String {
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

/// Convert an Error into a wrapped Defect
pub fn into_defect(result: Result(t, String)) -> Outcome(t) {
  result.map_error(result, fn(e) { ErrorStack(Defect(e), []) })
}

/// Convert an Error into a wrapped Failure
pub fn into_failure(result: Result(t, String)) -> Outcome(t) {
  result.map_error(result, fn(e) { ErrorStack(Failure(e), []) })
}

/// Convert an Error into a wrapped Defect, by using a mapping function
pub fn map_into_defect(
  result: Result(t, e),
  mapper: fn(e) -> String,
) -> Outcome(t) {
  result
  |> result.map_error(mapper)
  |> into_defect
}

/// Replaces an Error with a wrapped Defect
pub fn as_defect(result: Result(t, Nil), e: String) -> Outcome(t) {
  result.replace_error(result, ErrorStack(Defect(e), []))
}

/// Replaces an Error with a wrapped Failure
pub fn as_failure(result: Result(t, Nil), e: String) -> Outcome(t) {
  result.replace_error(result, ErrorStack(Failure(e), []))
}

/// Context is not the same as the error
/// Add context to an Outcome
pub fn context(
  outcome outcome: Outcome(t),
  context context: String,
) -> Outcome(t) {
  result.map_error(outcome, fn(stack) { add_to_stack(stack, Context(context)) })
}

pub fn add_to_stack(stack: ErrorStack, new_problem: Error) -> ErrorStack {
  ErrorStack(new_problem, [stack.problem, ..stack.problems])
}
