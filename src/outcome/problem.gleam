import gleam/list

/// An application error is either a Defect or a Failure.
/// A Defect is an unexpected application error, which shouldn't be shown to the user.
/// A Failure is an expected error.
pub type Severity {
  Defect
  Failure
}

/// A list of context entries
pub type ContextStack =
  List(String)

/// The error type ie. `Result(t, Problem)`
/// This contains the error, the severity and the context stack.
pub type Problem(err) {
  Problem(error: err, severity: Severity, stack: ContextStack)
}

fn new_problem(error: err, severity: Severity) -> Problem(err) {
  Problem(error: error, severity: severity, stack: [])
}

/// Create a Defect
/// Use this if you need the `Problem` type only.
/// Usually you will use `result_with_defect` instead.
///
/// ## Example
///
/// ```gleam
/// problem.new_defect("Something went wrong")
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
/// problem.new_failure("Something went wrong")
/// ```
///
pub fn new_failure(error: err) -> Problem(err) {
  new_problem(error, Failure)
}

@internal
pub fn map_error(problem: Problem(err), mapper: fn(err) -> err) -> Problem(err) {
  Problem(..problem, error: mapper(problem.error))
}

@internal
pub fn tap_error(problem: Problem(err), fun: fn(err) -> any) -> Problem(err) {
  fun(problem.error)
  problem
}

@internal
pub fn tap_defect(problem: Problem(err), fun: fn(err) -> any) -> Problem(err) {
  case problem.severity {
    Defect -> {
      fun(problem.error)
      problem
    }
    _ -> problem
  }
}

@internal
pub fn tap_failure(problem: Problem(err), fun: fn(err) -> any) -> Problem(err) {
  case problem.severity {
    Failure -> {
      fun(problem.error)
      problem
    }
    _ -> problem
  }
}

fn push_to_stack(stack: ContextStack, entry: String) -> List(String) {
  [entry, ..stack]
}

@internal
pub fn add_context(problem: Problem(err), value: String) -> Problem(err) {
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
///  Error(problem) -> io.error(problem.get_failure(problem, "Something went wrong"))
/// }
/// ```
pub fn get_failure(problem: Problem(err), default_value: err) -> err {
  case problem.severity {
    Defect -> default_value
    Failure -> problem.error
  }
}

@internal
pub fn extract_error(problem: Problem(err)) -> err {
  problem.error
}

@internal
pub fn stack_to_lines(stack: ContextStack) -> List(String) {
  stack
  |> list.reverse
}
