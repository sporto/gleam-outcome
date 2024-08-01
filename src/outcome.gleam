import gleam/list
import gleam/result
import gleam/string

// *************************
// Types
// *************************

/// An application error is either a Defect or a Failure.
/// A Defect is an unexpected application error, which shouldn't be shown to the user.
/// A Failure is an expected error.
pub type Severity {
  Defect
  Failure
}

/// The error type ie. `Result(t, Problem)`
/// This contains the error, the severity and the context stack.
pub type Problem(err) {
  Problem(error: err, severity: Severity, stack: ContextStack)
}

/// A list of context entries
pub type ContextStack =
  List(String)

/// Alias to Result with Problem as error type.
pub type Outcome(t, err) =
  Result(t, Problem(err))

// *************************
// Create new
// *************************
//
fn new_defect(error: err) -> Problem(err) {
  new_problem(error, Defect)
}

fn new_failure(error: err) -> Problem(err) {
  new_problem(error, Failure)
}

fn new_problem(error: err, severity: Severity) -> Problem(err) {
  Problem(error: error, severity: severity, stack: [])
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
/// want to convert it into a `Result(t, Problem)`
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
/// want to convert it into a `Result(t, Problem)`
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
pub fn replace_with_defect(result: Result(t, b), e: err) -> Outcome(t, err) {
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
pub fn replace_with_failure(result: Result(t, b), e: err) -> Outcome(t, err) {
  result.replace_error(result, new_failure(e))
}

// *************************
// Mapping
// *************************

fn map_error_in_problem(
  problem: Problem(err),
  mapper: fn(err) -> err,
) -> Problem(err) {
  Problem(..problem, error: mapper(problem.error))
}

fn map_defect_in_problem(
  problem: Problem(err),
  mapper: fn(err) -> err,
) -> Problem(err) {
  case problem.severity {
    Defect -> Problem(..problem, error: mapper(problem.error))
    _ -> problem
  }
}

fn map_failure_in_problem(
  problem: Problem(err),
  mapper: fn(err) -> err,
) -> Problem(err) {
  case problem.severity {
    Failure -> Problem(..problem, error: mapper(problem.error))
    _ -> problem
  }
}

/// Map the error value inside a Problem
pub fn map_error(
  outcome: Outcome(t, err),
  mapper: fn(err) -> err,
) -> Outcome(t, err) {
  result.map_error(outcome, map_error_in_problem(_, mapper))
}

pub fn map_defect(outcome: Outcome(t, err), mapper: fn(err) -> err) {
  result.map_error(outcome, map_defect_in_problem(_, mapper))
}

pub fn map_failure(outcome: Outcome(t, err), mapper: fn(err) -> err) {
  result.map_error(outcome, map_failure_in_problem(_, mapper))
}

// *************************
// Tap
// *************************

fn tap_error_in_problem(
  problem: Problem(err),
  fun: fn(err) -> any,
) -> Problem(err) {
  fun(problem.error)
  problem
}

fn tap_defect_in_problem(
  problem: Problem(err),
  fun: fn(err) -> any,
) -> Problem(err) {
  case problem.severity {
    Defect -> {
      fun(problem.error)
      problem
    }
    _ -> problem
  }
}

fn tap_failure_in_problem(
  problem: Problem(err),
  fun: fn(err) -> any,
) -> Problem(err) {
  case problem.severity {
    Failure -> {
      fun(problem.error)
      problem
    }
    _ -> problem
  }
}

/// Use tap functions to log the errors
pub fn tap(
  outcome: Outcome(t, err),
  fun: fn(Problem(err)) -> any,
) -> Outcome(t, err) {
  result.map_error(outcome, fn(problem) {
    fun(problem)
    problem
  })
}

pub fn tap_error(
  outcome: Outcome(t, err),
  fun: fn(err) -> any,
) -> Outcome(t, err) {
  result.map_error(outcome, tap_error_in_problem(_, fun))
}

pub fn tap_defect(
  outcome: Outcome(t, err),
  fun: fn(err) -> any,
) -> Outcome(t, err) {
  result.map_error(outcome, tap_defect_in_problem(_, fun))
}

pub fn tap_failure(
  outcome: Outcome(t, err),
  fun: fn(err) -> any,
) -> Outcome(t, err) {
  result.map_error(outcome, tap_failure_in_problem(_, fun))
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

fn push_to_stack(stack: ContextStack, entry: String) -> List(String) {
  [entry, ..stack]
}

fn add_context_to_problem(problem: Problem(err), value: String) -> Problem(err) {
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
pub fn unwrap_failure(problem: Problem(err), default_value: err) -> err {
  case problem.severity {
    Defect -> default_value
    Failure -> problem.error
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
  let current =
    prettry_print_problem_error(problem.severity, to_s(problem.error))

  let stack =
    join_current
    <> problem.stack
    |> stack_to_lines
    |> string.join(join_stack)

  let stack = case problem.stack {
    [] -> ""
    _ -> stack
  }

  current <> stack
}

fn prettry_print_problem_error(severity: Severity, error: String) -> String {
  long_suffix(severity) <> error
}

fn long_suffix(severity: Severity) -> String {
  case severity {
    Defect -> "Defect: "
    Failure -> "Failure: "
  }
}

fn pretty_print_stack_entry(value: String) -> String {
  value
}
