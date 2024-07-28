import gleam/function.{identity}
import gleeunit
import gleeunit/should
import outcome.{type Outcome, Defect, ErrorStack, Failure}

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
  let expected =
    ErrorStack(problem: Defect("error"), original: Defect("error"), stack: [])

  Error("error")
  |> outcome.into_defect
  |> should.equal(Error(expected))
}

pub fn into_failure_test() {
  let expected =
    ErrorStack(
      problem: Failure("failure"),
      original: Failure("failure"),
      stack: [],
    )

  Error("failure")
  |> outcome.into_failure
  |> should.equal(Error(expected))
}

pub fn replace_with_defect_test() {
  let expected =
    ErrorStack(problem: Defect("error"), original: Defect("error"), stack: [])

  Error(Nil)
  |> outcome.replace_with_defect("error")
  |> should.equal(Error(expected))
}

pub fn replace_with_failure_test() {
  let expected =
    ErrorStack(
      problem: Failure("failure"),
      original: Failure("failure"),
      stack: [],
    )

  Error(Nil)
  |> outcome.replace_with_failure("failure")
  |> should.equal(Error(expected))
}

pub fn with_context_test() {
  let expected =
    ErrorStack(
      problem: Failure("failure"),
      original: Failure("failure"),
      stack: ["context 2", "context 1"],
    )

  Error("failure")
  |> outcome.into_failure
  |> outcome.with_context("context 1")
  |> outcome.with_context("context 2")
  |> should.equal(Error(expected))
}

pub fn to_defect_test() {
  let expected =
    ErrorStack(
      problem: Defect("failure"),
      original: Failure("failure"),
      stack: [],
    )

  Error("failure")
  |> outcome.into_failure
  |> outcome.to_defect
  |> should.equal(Error(expected))
}

pub fn to_failure_test() {
  let expected =
    ErrorStack(
      problem: Failure("defect"),
      original: Defect("defect"),
      stack: [],
    )

  Error("defect")
  |> outcome.into_defect
  |> outcome.to_failure
  |> should.equal(Error(expected))
}

pub fn extract_problem_test() {
  Error("error")
  |> outcome.into_defect
  |> outcome.extract_problem
  |> should.equal(Error(Defect("error")))
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
    |> outcome.with_context("context 1")
    |> outcome.with_context("context 2")

  let pretty = pretty_print_outcome(error)

  pretty
  |> should.equal(
    "Defect: defect

stack:
  c: context 2
  c: context 1
  d: defect",
  )
}

pub fn print_line_test() {
  let error =
    outcome.error_with_defect("defect")
    |> outcome.with_context("context 1")
    |> outcome.with_context("context 2")

  let output = print_line_outcome(error)

  output
  |> should.equal("Defect: defect << c: context 2 < c: context 1 < d: defect")
}
