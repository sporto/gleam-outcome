import gleam/list
import gleam/result
import gleam/string

// *************************
// Types
// *************************

/// The error type ie. `Result(t, ErrorStack)`
/// This contains the error and the context stack.
///
/// An application error is either a Defect or a Failure.
/// A Defect is an unexpected application error, which shouldn't be shown to the user.
/// A Failure is an expected error.
pub type Problem(err) {
  Defect(error: err, stack: ContextStack)
  Failure(error: err, stack: ContextStack)
}

/// A list of context entries
pub type ContextStack =
  List(String)

/// Alias to Result with ErrorStack as error type.
pub type Outcome(t, err) =
  Result(t, Problem(err))

// *************************
// Create new
// *************************
//
fn new_defect(value: err) -> Problem(err) {
  Defect(error: value, stack: [])
}

fn new_failure(value: err) -> Problem(err) {
  Failure(error: value, stack: [])
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

fn map_error_in_problem(
  problem: Problem(err),
  mapper: fn(err) -> err,
) -> Problem(err) {
  case problem {
    Defect(error, stack) -> Defect(mapper(error), stack)
    Failure(error, stack) -> Failure(mapper(error), stack)
  }
}

/// Map the value inside a Defect or Failure
pub fn map_error(
  outcome: Outcome(t, err),
  mapper: fn(err) -> err,
) -> Outcome(t, err) {
  result.map_error(outcome, map_error_in_problem(_, mapper))
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
  result.map_error(outcome, problem_to_defect)
}

fn problem_to_defect(problem: Problem(t)) -> Problem(t) {
  Defect(problem.error, problem.stack)
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
  result.map_error(outcome, problem_to_failure)
}

fn problem_to_failure(problem: Problem(t)) -> Problem(t) {
  Failure(problem.error, problem.stack)
}

fn push_to_stack(stack: ContextStack, entry: String) -> List(String) {
  [entry, ..stack]
}

fn add_context_to_problem(problem: Problem(err), value: String) -> Problem(err) {
  case problem {
    Defect(error, stack) -> Defect(error, push_to_stack(stack, value))
    Failure(error, stack) -> Failure(error, push_to_stack(stack, value))
  }
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
pub fn unwrap_failure(problem: Problem(err), default_value: err) -> err {
  case problem {
    Defect(_, _) -> default_value
    Failure(value, _) -> value
  }
}

/// Remove the Problem wrapping, returning just your error.
pub fn extract_error(outcome: Outcome(t, err)) -> Result(t, err) {
  outcome |> result.map_error(problem_to_error)
}

fn problem_to_error(problem: Problem(err)) -> err {
  problem.error
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
///  More context
///  In find user function
/// ```
pub fn pretty_print(problem: Problem(err), to_s: fn(err) -> String) -> String {
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
/// Defect: Something went wrong << In find user function
/// ```
pub fn print_line(problem: Problem(err), to_s: fn(err) -> String) -> String {
  pretty_print_with_joins(problem, " << ", " < ", to_s)
}

fn pretty_print_with_joins(
  problem: Problem(err),
  join_current: String,
  join_stack: String,
  to_s: fn(err) -> String,
) -> String {
  let current = prettry_print_problem_error(problem, to_s)

  let stack =
    problem.stack
    |> stack_to_lines
    |> string.join(join_stack)

  current <> join_current <> stack
}

fn prettry_print_problem_error(
  problem: Problem(err),
  to_s: fn(err) -> String,
) -> String {
  prettry_print_error(long_suffix(problem), problem.error, to_s)
}

fn long_suffix(problem: Problem(err)) -> String {
  case problem {
    Defect(_, _) -> "Defect: "
    Failure(_, _) -> "Failure: "
  }
}

fn prettry_print_error(
  suffix: String,
  error: err,
  to_s: fn(err) -> String,
) -> String {
  suffix <> to_s(error)
}

fn pretty_print_stack_entry(value: String) -> String {
  value
}
