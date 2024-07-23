import gleam/list
import gleam/result
import gleam/string

// *************************
// Types
// *************************

/// An application error is either a Defect or a Failure.
/// A Defect is an unexpected application error, which shouldn't be shown to the user.
/// A Failure is an expected error.
pub type Error {
  Defect(message: String)
  Failure(message: String)
}

/// The error type ie. `Result(t, Problem)`
/// This contains the error and the context stack.
pub type Problem {
  Problem(error: Error, stack: ContextStack, original: Error)
}

/// A list of contexts
pub type ContextStack =
  List(String)

/// Alias to Result with Problem as error type.
pub type Outcome(t) =
  Result(t, Problem)

fn new_defect(message: String) -> Problem {
  Problem(error: Defect(message), original: Defect(message), stack: [])
}

fn new_failure(message: String) -> Problem {
  Problem(error: Failure(message), original: Failure(message), stack: [])
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

// *************************
// Mapping
// *************************

fn map_current_error_in_problem(
  problem: Problem,
  mapper: fn(Error) -> Error,
) -> Problem {
  Problem(..problem, error: mapper(problem.error))
}

fn map_current_error(outcome: Outcome(t), mapper: fn(Error) -> Error) {
  result.map_error(outcome, map_current_error_in_problem(_, mapper))
}

fn map_current_message_in_problem(
  problem: Problem,
  mapper: fn(String) -> String,
) -> Problem {
  map_current_error_in_problem(problem, fn(error) {
    case error {
      Defect(message) -> Defect(mapper(message))
      Failure(message) -> Failure(mapper(message))
    }
  })
}

/// Map the message inside a Defect or Failure
pub fn map_message(
  outcome: Outcome(t),
  mapper: fn(String) -> String,
) -> Outcome(t) {
  result.map_error(outcome, map_current_message_in_problem(_, mapper))
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
  outcome outcome: Outcome(t),
  context context: String,
) -> Outcome(t) {
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
pub fn to_defect(outcome: Outcome(t)) -> Outcome(t) {
  map_current_error(outcome, fn(error) { Defect(error.message) })
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
pub fn to_failure(outcome: Outcome(t)) -> Outcome(t) {
  map_current_error(outcome, fn(error) { Failure(error.message) })
}

fn push_to_stack(stack: ContextStack, entry: String) -> List(String) {
  [entry, ..stack]
}

/// A context to a Problem
/// This is a low level function.
/// Prefer to use `with_context` instead which maps the Error.
fn add_context_to_problem(problem: Problem, value: String) -> Problem {
  Problem(..problem, stack: push_to_stack(problem.stack, value))
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
  case problem.error {
    Defect(_) -> default_message
    Failure(message) -> message
  }
}

fn stack_to_lines(stack: ContextStack) -> List(String) {
  stack
  |> list.map(pretty_print_stack_entry)
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
/// |> with_context("More context")
/// |> pretty_print
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
pub fn pretty_print(problem: Problem) -> String {
  pretty_print_with_joins(problem, "\n\nstack:\n  ", "\n  ")
}

/// Print problem in one line
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> into_defect
/// |> with_context("In find user function")
/// |> print_line
/// ```
///
/// ```
/// Defect: Something went wrong << c: In find user function < d: Something went wrong
/// ```
pub fn print_line(problem: Problem) -> String {
  pretty_print_with_joins(problem, " << ", " < ")
}

fn pretty_print_with_joins(
  problem: Problem,
  join_current: String,
  join_stack: String,
) -> String {
  let current = prettry_print_problem_error(problem)

  let stack =
    problem.stack
    |> stack_to_lines
    |> string.join(join_stack)

  let original = prettry_print_problem_original(problem)

  current <> join_current <> stack <> join_stack <> original
}

fn prettry_print_problem_error(problem: Problem) -> String {
  prettry_print_error(long_suffix(problem.error), problem.error)
}

fn long_suffix(error: Error) -> String {
  case error {
    Defect(_) -> "Defect: "
    Failure(_) -> "Failure: "
  }
}

fn prettry_print_problem_original(problem: Problem) -> String {
  prettry_print_error(short_suffix(problem.error), problem.original)
}

fn short_suffix(error: Error) -> String {
  case error {
    Defect(_) -> "d: "
    Failure(_) -> "f: "
  }
}

fn prettry_print_error(suffix: String, error: Error) -> String {
  suffix <> error.message
}

fn pretty_print_stack_entry(value: String) -> String {
  "c: " <> value
}
