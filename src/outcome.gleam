import gleam/result
import gleam/string
import outcome/problem.{type Problem, type Severity, Defect, Failure, Problem}

/// Alias to Result with Problem as error type.
pub type Outcome(t, err) =
  Result(t, Problem(err))

/// Convert `Result(a, e)` to `Result(a, Problem(e))`
/// with severity as `Defect`
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> outcome.result_with_defect
/// ```
pub fn result_with_defect(result: Result(t, err)) -> Outcome(t, err) {
  result.map_error(result, problem.new_defect)
}

/// Convert `Result(a, e)` to `Result(a, Problem(e))`
/// with severity as `Failure`.
///
/// ## Example
///
/// ```gleam
/// Error("Invalid input")
/// |> outcome.result_with_failure
/// ```
pub fn result_with_failure(result: Result(t, err)) -> Outcome(t, err) {
  result.map_error(result, problem.new_failure)
}

/// Map the error value
pub fn map_error(
  outcome: Outcome(t, err),
  mapper: fn(err) -> err,
) -> Outcome(t, err) {
  result.map_error(outcome, problem.map_error(_, mapper))
}

// *************************
// Tap
// *************************

/// Use tap functions to log the errors.
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
  result.map_error(outcome, problem.tap_error(_, fun))
}

/// Yield your error type.
/// Only called if the severity is Defect.
pub fn tap_defect(
  outcome: Outcome(t, err),
  fun: fn(err) -> any,
) -> Outcome(t, err) {
  result.map_error(outcome, problem.tap_defect(_, fun))
}

/// Yield your error type.
/// Only called if the severity is Failure.
pub fn tap_failure(
  outcome: Outcome(t, err),
  fun: fn(err) -> any,
) -> Outcome(t, err) {
  result.map_error(outcome, problem.tap_failure(_, fun))
}

/// Add context to an Outcome.
/// This will add a Context entry to the stack.
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> outcome.result_with_defect
/// |> outcome.context("In find user function")
/// ```
///
pub fn context(
  outcome outcome: Outcome(t, err),
  context context: String,
) -> Outcome(t, err) {
  result.map_error(outcome, problem.add_context(_, context))
}

/// Remove the `Problem` wrapping in the error value
///
/// ## Example
///
/// ```gleam
/// let result = Error("Fail") |> outcome.result_with_defect
///
/// outcome.to_simple_result(result) == Error("Fail")
/// ```
pub fn to_simple_result(outcome: Outcome(t, err)) -> Result(t, err) {
  outcome |> result.map_error(problem.extract_error)
}

// *************************
// Print
// *************************

/// Pretty print a Problem, including the stack.
/// The latest problem appears at the top of the stack.
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> outcome.result_with_defect
/// |> outcome.context("In find user function")
/// |> outcome.context("More context")
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
/// |> result_with_defect
/// |> context("In find user function")
/// |> print_line(function.identity)
/// ```
///
/// ```
/// Defect: Something went wrong < In find user function
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
    |> problem.stack_to_lines
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
