import gleam/list
import gleam/result
import gleam/string

/// A list of context entries
pub type ContextStack =
  List(String)

/// The error type in a result ie. `Result(t, Problem(e))`
pub type Problem(err) {
  Problem(error: err, stack: ContextStack)
}

/// An alias for the `Result` type. Where the error type is `Problem`.
pub type Outcome(t, err) =
  Result(t, Problem(err))

fn push_to_stack(stack: ContextStack, entry: String) -> List(String) {
  [entry, ..stack]
}

/// Add context to a Problem.
/// This will add a context entry to the stack.
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> outcome.outcome
/// |> outcome.context("In find user function")
/// ```
///
pub fn context(
  outcome outcome: Outcome(t, err),
  context context: String,
) -> Outcome(t, err) {
  result.map_error(outcome, problem_context(_, context))
}

fn problem_context(problem: Problem(err), value: String) -> Problem(err) {
  Problem(..problem, stack: push_to_stack(problem.stack, value))
}

/// Convert `Result(a, e)` to `Result(a, Problem(e))`
///
/// ## Example
///
/// ```gleam
/// Error("Something went wrong")
/// |> outcome.outcome
/// ```
pub fn outcome(result: Result(t, err)) -> Outcome(t, err) {
  result.map_error(result, new_problem)
}

/// Create a `Problem`
/// Use this if you need the `Problem` type only.
/// Usually you will use `outcome` instead.
///
/// ## Example
///
/// ```gleam
/// outcome.new_problem("Something went wrong")
/// ```
///
pub fn new_problem(error: err) -> Problem(err) {
  Problem(error:, stack: [])
}

/// Map the error value
pub fn map_error(
  outcome: Outcome(t, err),
  mapper: fn(err) -> err,
) -> Outcome(t, err) {
  result.map_error(outcome, problem_map_error(_, mapper))
}

fn problem_map_error(
  problem: Problem(err),
  mapper: fn(err) -> err,
) -> Problem(err) {
  Problem(..problem, error: mapper(problem.error))
}

/// Remove the `Problem` wrapping in the error value
///
/// ## Example
///
/// ```gleam
/// let outcome = Error("Fail") |> outcome.outcome
///
/// outcome.remove_problem(outcome) == Error("Fail")
/// ```
pub fn remove_problem(outcome: Outcome(t, err)) -> Result(t, err) {
  outcome |> result.map_error(fn(problem) { problem.error })
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
/// let result = Error("Something went wrong")
/// |> outcome.outcome
/// |> outcome.context("In find user function")
/// |> outcome.context("More context")
///
/// case result {
///   Error(problem) ->
///     outcome.pretty_print(function.identity)
///
///   Ok(_) -> todo
/// }
/// ```
///
/// ```
/// Something went wrong
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
/// let result = Error("Something went wrong")
/// |> outcome.outcome
/// |> outcome.context("In find user function")
///
/// case result {
///   Error(problem) ->
///     outcome.print_line(function.identity)
///
///   Ok(_) -> todo
/// }
/// ```
///
/// ```
/// Something went wrong < In find user function
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
  let current = to_s(problem.error)

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

fn stack_to_lines(stack: ContextStack) -> List(String) {
  stack
  |> list.reverse
}
