import gleam/list
import gleam/result
import gleam/string

// *************************
// Types
// *************************

/// An application error is either a Defect or a Failure.
/// A Defect is an unexpected application error, which shouldn't be shown to the user.
/// A Failure is an expected error.
pub type Problem(err) {
  Defect(value: err)
  Failure(value: err)
}

/// The error type ie. `Result(t, ErrorStack)`
/// This contains the error and the context stack.
pub type ErrorStack(err) {
  ErrorStack(problem: Problem(err), stack: ContextStack, original: Problem(err))
}

/// A list of contexts
pub type ContextStack =
  List(String)

/// Alias to Result with ErrorStack as error type.
pub type Outcome(t, err) =
  Result(t, ErrorStack(err))

fn new_defect(value: err) -> ErrorStack(err) {
  ErrorStack(problem: Defect(value), original: Defect(value), stack: [])
}

fn new_failure(value: err) -> ErrorStack(err) {
  ErrorStack(problem: Failure(value), original: Failure(value), stack: [])
}

// *************************
// Create new
// *************************

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
pub fn error_with_defect(defect: err) -> Outcome(t, err) {
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
pub fn error_with_failure(failure: err) -> Outcome(t, err) {
  Error(new_failure(failure))
}

/// Convert an `Error(String)` into an `Error(Defect)`
/// This is useful when you have a `Result(t, String)` and
/// want to convert it into a `Result(t, ErrorStack)`
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> into_defect
/// ```
pub fn into_defect(result: Result(t, err)) -> Outcome(t, err) {
  result.map_error(result, new_defect)
}

/// Convert an `Error(String)` into an `Error(Failure)`
/// This is useful when you have a `Result(t, String)` and
/// want to convert it into a `Result(t, ErrorStack)`
///
/// ## Example
///
/// ```gleam
/// Error("Invalid input")
/// |> into_failure
/// ```
pub fn into_failure(result: Result(t, err)) -> Outcome(t, err) {
  result.map_error(result, new_failure)
}

/// Convert an `Error(t)` into a wrapped Defect, by using a mapping function
/// Similar to into_defect, but takes a function to map the error value to a string
pub fn map_into_defect(
  result: Result(t, e),
  mapper: fn(e) -> err,
) -> Outcome(t, err) {
  result
  |> result.map_error(mapper)
  |> into_defect
}

/// Convert an `Error(t)` into a wrapped Failure, by using a mapping function
/// Similar to into_defect, but takes a function to map the error value to a string
pub fn map_into_failure(
  result: Result(t, e),
  mapper: fn(e) -> err,
) -> Outcome(t, err) {
  result
  |> result.map_error(mapper)
  |> into_failure
}

/// Replaces an `Error(t)` with an `Error(Defect)`
///
/// ## Example
///
/// ```gleam
/// Error(Nil)
/// |> replace_with_defect("Something went wrong")
/// ```
pub fn replace_with_defect(result: Result(t, Nil), e: err) -> Outcome(t, err) {
  result.replace_error(result, new_defect(e))
}

/// Replaces any Error(t) with an Error(Failure)
///
/// ## Example
///
/// ```gleam
/// Error(Nil)
/// |> replace_with_failure("Invalid input")
/// ```
pub fn replace_with_failure(result: Result(t, Nil), e: err) -> Outcome(t, err) {
  result.replace_error(result, new_failure(e))
}

// *************************
// Mapping
// *************************

fn map_current_problem_in_error_stack(
  error_stack: ErrorStack(err),
  mapper: fn(Problem(err)) -> Problem(err),
) -> ErrorStack(err) {
  ErrorStack(..error_stack, problem: mapper(error_stack.problem))
}

fn map_current_error(
  outcome: Outcome(t, err),
  mapper: fn(Problem(err)) -> Problem(err),
) {
  result.map_error(outcome, map_current_problem_in_error_stack(_, mapper))
}

fn map_current_value_in_problem(
  problem: ErrorStack(err),
  mapper: fn(err) -> err,
) -> ErrorStack(err) {
  map_current_problem_in_error_stack(problem, fn(error) {
    case error {
      Defect(message) -> Defect(mapper(message))
      Failure(message) -> Failure(mapper(message))
    }
  })
}

/// Map the value inside a Defect or Failure
pub fn map_value(
  outcome: Outcome(t, err),
  mapper: fn(err) -> err,
) -> Outcome(t, err) {
  result.map_error(outcome, map_current_value_in_problem(_, mapper))
}

// *************************
// Adding
// *************************

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
  outcome outcome: Outcome(t, err),
  context context: String,
) -> Outcome(t, err) {
  result.map_error(outcome, add_context_to_problem(_, context))
}

/// Coherce the error into a Defect
///
/// ## Example
///
/// ```gleam
/// Error("Invalid Input")
/// |> into_failure
/// |> to_defect
/// ```
///
pub fn to_defect(outcome: Outcome(t, err)) -> Outcome(t, err) {
  map_current_error(outcome, fn(error) { Defect(error.value) })
}

/// Coherce the error into a Failure.
/// The original entry in the stack remains unchanged.
///
/// ## Example
///
/// ```gleam
/// Error("Invalid Input")
/// |> into_defect
/// |> to_failure
/// ```
///
pub fn to_failure(outcome: Outcome(t, err)) -> Outcome(t, err) {
  map_current_error(outcome, fn(error) { Failure(error.value) })
}

fn push_to_stack(stack: ContextStack, entry: String) -> List(String) {
  [entry, ..stack]
}

/// A context to a ErrorStack
/// This is a low level function.
/// Prefer to use `with_context` instead which maps the Error.
fn add_context_to_problem(
  problem: ErrorStack(err),
  value: String,
) -> ErrorStack(err) {
  ErrorStack(..problem, stack: push_to_stack(problem.stack, value))
}

/// Use this to show a failure to a user.
/// If the ErrorStack is a failure, it will show that
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
pub fn unwrap_failure(error_stack: ErrorStack(err), default_value: err) -> err {
  case error_stack.problem {
    Defect(_) -> default_value
    Failure(value) -> value
  }
}

/// Remove the `ErrorStack` wrapping.
/// This removes the context stack and the original problem
/// returning just the current problem.
pub fn extract_problem(outcome: Outcome(t, err)) -> Result(t, Problem(err)) {
  outcome |> result.map_error(error_stack_to_problem)
}

/// Remove all the wrapping types, returning the error
pub fn extract_error(outcome: Outcome(t, err)) -> Result(t, err) {
  outcome |> result.map_error(error_stack_to_error)
}

fn error_stack_to_problem(error_stack: ErrorStack(err)) -> Problem(err) {
  error_stack.problem
}

fn error_stack_to_error(error_stack: ErrorStack(err)) -> err {
  case error_stack.problem {
    Defect(value) -> value
    Failure(value) -> value
  }
}

fn stack_to_lines(stack: ContextStack) -> List(String) {
  stack
  |> list.map(pretty_print_stack_entry)
}

/// Pretty print a ErrorStack, including the stack.
/// The latest problem appears at the top of the stack.
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> into_defect
/// |> with_context("In find user function")
/// |> with_context("More context")
/// |> pretty_print(function.identity)
/// ```
///
/// ```
/// Defect: Something went wrong
///
/// stack:
///  c: More context
///  c: In find user function
///  d: Something went wrong
/// ```
pub fn pretty_print(problem: ErrorStack(err), to_s: fn(err) -> String) -> String {
  pretty_print_with_joins(problem, "\n\nstack:\n  ", "\n  ", to_s)
}

/// Print problem in one line
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> into_defect
/// |> with_context("In find user function")
/// |> print_line(function.identity)
/// ```
///
/// ```
/// Defect: Something went wrong << c: In find user function < d: Something went wrong
/// ```
pub fn print_line(problem: ErrorStack(err), to_s: fn(err) -> String) -> String {
  pretty_print_with_joins(problem, " << ", " < ", to_s)
}

fn pretty_print_with_joins(
  problem: ErrorStack(err),
  join_current: String,
  join_stack: String,
  to_s: fn(err) -> String,
) -> String {
  let current = prettry_print_error_stack_error(problem, to_s)

  let stack =
    problem.stack
    |> stack_to_lines
    |> string.join(join_stack)

  let original = prettry_print_error_stack_original(problem, to_s)

  current <> join_current <> stack <> join_stack <> original
}

fn prettry_print_error_stack_error(
  error_stack: ErrorStack(err),
  to_s: fn(err) -> String,
) -> String {
  prettry_print_error(
    long_suffix(error_stack.problem),
    error_stack.problem,
    to_s,
  )
}

fn long_suffix(error: Problem(err)) -> String {
  case error {
    Defect(_) -> "Defect: "
    Failure(_) -> "Failure: "
  }
}

fn prettry_print_error_stack_original(
  problem: ErrorStack(err),
  to_s: fn(err) -> String,
) -> String {
  prettry_print_error(short_suffix(problem.problem), problem.original, to_s)
}

fn short_suffix(error: Problem(err)) -> String {
  case error {
    Defect(_) -> "d: "
    Failure(_) -> "f: "
  }
}

fn prettry_print_error(
  suffix: String,
  error: Problem(err),
  to_s: fn(err) -> String,
) -> String {
  suffix <> to_s(error.value)
}

fn pretty_print_stack_entry(value: String) -> String {
  "c: " <> value
}
