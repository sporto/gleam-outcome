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

/// Create a Defect
/// Use this if you need the `Problem` type only.
/// Usually you will use `result_to_defect` instead.
///
/// ## Example
///
/// ```gleam
/// new_defect("Something went wrong")
/// ```
///
pub fn new_defect(error: err) -> Problem(err) {
  new_problem(error, Defect)
}

/// Create a Failure
/// Use this if you need the `Problem` type only.
/// Usually you will use `result_to_failure` instead.
///
/// ## Example
///
/// ```gleam
/// new_failure("Something went wrong")
/// ```
///
pub fn new_failure(error: err) -> Problem(err) {
  new_problem(error, Failure)
}

fn new_problem(error: err, severity: Severity) -> Problem(err) {
  Problem(error: error, severity: severity, stack: [])
}

/// Convert an `Error(String)` into an `Error(Defect)`
/// This is useful when you have a `Result(t, String)` and
/// want to convert it into a `Result(t, Problem)`
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> result_to_defect
/// ```
pub fn result_to_defect(result: Result(t, err)) -> Outcome(t, err) {
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
/// |> result_to_failure
/// ```
pub fn result_to_failure(result: Result(t, err)) -> Outcome(t, err) {
  result.map_error(result, new_failure)
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

/// Map the error value
pub fn map_error(
  outcome: Outcome(t, err),
  mapper: fn(err) -> err,
) -> Outcome(t, err) {
  result.map_error(outcome, map_error_in_problem(_, mapper))
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
/// This yields the `Problem` type.
pub fn tap(
  outcome: Outcome(t, err),
  fun: fn(Problem(err)) -> any,
) -> Outcome(t, err) {
  result.map_error(outcome, fn(problem) {
    fun(problem)
    problem
  })
}

/// This yields your error type.
pub fn tap_error(
  outcome: Outcome(t, err),
  fun: fn(err) -> any,
) -> Outcome(t, err) {
  result.map_error(outcome, tap_error_in_problem(_, fun))
}

/// Yield your error type
/// Only called if the severity is Defect
pub fn tap_defect(
  outcome: Outcome(t, err),
  fun: fn(err) -> any,
) -> Outcome(t, err) {
  result.map_error(outcome, tap_defect_in_problem(_, fun))
}

/// Yield your error type
/// Only called if the severity is Failure
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
/// |> result_to_defect
/// |> context("In find user function")
/// ```
///
pub fn context(
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
/// Extracts the Error value from a `Problem` when the severity is `Failure`.
/// otherwise it will return the default value given.
///
/// ## Example
///
/// ```gleam
/// case result {
///  Ok(value) -> io.debug("Success")
///  Error(problem) -> io.error(get_failure_in_problem(problem, "Something went wrong"))
/// }
/// ```
pub fn get_failure_in_problem(problem: Problem(err), default_value: err) -> err {
  case problem.severity {
    Defect -> default_value
    Failure -> problem.error
  }
}

/// Remove the Problem wrapping, returning just your error.
///
/// ## Example
///
/// ```gleam
/// let outcome = Error("Fail") |> result_to_defect
///
/// to_simple_result(outcome) == Error("Fail")
/// ```
pub fn to_simple_result(outcome: Outcome(t, err)) -> Result(t, err) {
  outcome |> result.map_error(problem_to_error)
}

fn problem_to_error(problem: Problem(err)) -> err {
  problem.error
}

fn stack_to_lines(stack: ContextStack) -> List(String) {
  stack
  |> list.reverse
  |> list.map(pretty_print_stack_entry)
}

/// Pretty print a Problem, including the stack.
/// The latest problem appears at the top of the stack.
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> result_to_defect
/// |> context("In find user function")
/// |> context("More context")
/// |> pretty_print(function.identity)
/// ```
///
/// ```
/// Defect: Something went wrong
///
/// stack:
///  In find user function
///  More context
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
/// |> result_to_defect
/// |> context("In find user function")
/// |> print_line(function.identity)
/// ```
///
/// ```
/// Defect: Something went wrong << In find user function
/// ```
pub fn print_line(problem: Problem(err), to_s: fn(err) -> String) -> String {
  pretty_print_with_joins(problem, " < ", " < ", to_s)
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
