import gleam/function.{identity}
import gleeunit
import gleeunit/should
import outcome.{type Outcome}
import outcome/problem.{Defect, Failure, Problem}

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

pub fn result_with_defect_test() {
  let expected = Problem(error: "error", severity: Defect, stack: [])

  Error("error")
  |> outcome.result_with_defect
  |> should.equal(Error(expected))
}

pub fn result_with_failure_test() {
  let expected = Problem(error: "failure", severity: Failure, stack: [])

  Error("failure")
  |> outcome.result_with_failure
  |> should.equal(Error(expected))
}

pub fn context_test() {
  let expected =
    Problem(error: "failure", severity: Failure, stack: [
      "context 2", "context 1",
    ])

  Error("failure")
  |> outcome.result_with_failure
  |> outcome.context("context 1")
  |> outcome.context("context 2")
  |> should.equal(Error(expected))
}

pub fn to_simple_result_test() {
  Error("error")
  |> outcome.result_with_defect
  |> outcome.to_simple_result
  |> should.equal(Error("error"))
}

pub fn pretty_print_test() {
  let error =
    Error("defect")
    |> outcome.result_with_defect
    |> outcome.context("context inner")
    |> outcome.context("context outer")

  let pretty = pretty_print_outcome(error)

  pretty
  |> should.equal(
    "Defect: defect

stack:
  context inner
  context outer",
  )
}

pub fn pretty_print_without_context_test() {
  let error =
    Error("defect")
    |> outcome.result_with_defect

  let pretty = pretty_print_outcome(error)

  pretty
  |> should.equal("Defect: defect")
}

pub fn print_line_test() {
  let error =
    Error("defect")
    |> outcome.result_with_defect
    |> outcome.context("context inner")
    |> outcome.context("context outer")

  let output = print_line_outcome(error)

  output
  |> should.equal("Defect: defect < context inner < context outer")
}

pub fn print_line_without_context_test() {
  let error = Error("defect") |> outcome.result_with_defect

  let output = print_line_outcome(error)

  output
  |> should.equal("Defect: defect")
}
