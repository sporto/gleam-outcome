import gleam/function.{identity}
import gleeunit
import gleeunit/should
import outcome.{type Outcome, Problem}

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

pub fn outcome_test() {
  let expected = Problem(error: "error", stack: [])

  Error("error")
  |> outcome.outcome
  |> should.equal(Error(expected))
}

pub fn context_test() {
  let expected = Problem(error: "failure", stack: ["context 2", "context 1"])

  Error("failure")
  |> outcome.outcome
  |> outcome.context("context 1")
  |> outcome.context("context 2")
  |> should.equal(Error(expected))
}

pub fn remove_problem_test() {
  Error("error")
  |> outcome.outcome
  |> outcome.remove_problem
  |> should.equal(Error("error"))
}

pub fn pretty_print_test() {
  let error =
    Error("defect")
    |> outcome.outcome
    |> outcome.context("context inner")
    |> outcome.context("context outer")

  let pretty = pretty_print_outcome(error)

  pretty
  |> should.equal(
    "defect

stack:
  context inner
  context outer",
  )
}

pub fn pretty_print_without_context_test() {
  let error =
    Error("defect")
    |> outcome.outcome

  let pretty = pretty_print_outcome(error)

  pretty
  |> should.equal("defect")
}

pub fn print_line_test() {
  let error =
    Error("defect")
    |> outcome.outcome
    |> outcome.context("context inner")
    |> outcome.context("context outer")

  let output = print_line_outcome(error)

  output
  |> should.equal("defect < context inner < context outer")
}

pub fn print_line_without_context_test() {
  let error = Error("defect") |> outcome.outcome

  let output = print_line_outcome(error)

  output
  |> should.equal("defect")
}
