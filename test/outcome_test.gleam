import gleam/function.{identity}
import gleeunit
import gleeunit/should
import outcome.{type Outcome, Defect, Failure, Problem}

pub fn main() {
  gleeunit.main()
}

pub fn pretty_print_outcome(outcome: Outcome(t, String)) -> String {
  case outcome {
    Ok(_) -> "Ok"
    Error(problem) -> outcome.pretty_print(problem, identity)
  }
}

pub fn print_line_outcome(outcome: Outcome(t, String)) -> String {
  case outcome {
    Ok(_) -> "Ok"
    Error(problem) -> outcome.print_line(problem, identity)
  }
}

pub fn into_defect_test() {
  let expected = Problem(error: "error", severity: Defect, stack: [])

  Error("error")
  |> outcome.into_defect
  |> should.equal(Error(expected))
}

pub fn into_failure_test() {
  let expected = Problem(error: "failure", severity: Failure, stack: [])

  Error("failure")
  |> outcome.into_failure
  |> should.equal(Error(expected))
}

pub fn replace_with_defect_test() {
  let expected = Problem(error: "error", severity: Defect, stack: [])

  Error(Nil)
  |> outcome.replace_with_defect("error")
  |> should.equal(Error(expected))
}

pub fn replace_with_failure_test() {
  let expected = Problem(error: "failure", severity: Failure, stack: [])

  Error(Nil)
  |> outcome.replace_with_failure("failure")
  |> should.equal(Error(expected))
}

pub fn context_test() {
  let expected =
    Problem(error: "failure", severity: Failure, stack: [
      "context 2", "context 1",
    ])

  Error("failure")
  |> outcome.into_failure
  |> outcome.context("context 1")
  |> outcome.context("context 2")
  |> should.equal(Error(expected))
}

pub fn extract_error_test() {
  Error("error")
  |> outcome.into_defect
  |> outcome.extract_error
  |> should.equal(Error("error"))
}

pub fn pretty_print_test() {
  let error =
    outcome.error_with_defect("defect")
    |> outcome.context("context 1")
    |> outcome.context("context 2")

  let pretty = pretty_print_outcome(error)

  pretty
  |> should.equal(
    "Defect: defect

stack:
  context 2
  context 1",
  )
}

pub fn pretty_print_without_context_test() {
  let error = outcome.error_with_defect("defect")

  let pretty = pretty_print_outcome(error)

  pretty
  |> should.equal("Defect: defect")
}

pub fn print_line_test() {
  let error =
    outcome.error_with_defect("defect")
    |> outcome.context("context 1")
    |> outcome.context("context 2")

  let output = print_line_outcome(error)

  output
  |> should.equal("Defect: defect << context 2 < context 1")
}

pub fn print_line_without_context_test() {
  let error = outcome.error_with_defect("defect")

  let output = print_line_outcome(error)

  output
  |> should.equal("Defect: defect")
}
