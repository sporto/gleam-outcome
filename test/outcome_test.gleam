import gleam/function.{identity}
import gleeunit
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

  let actual =
    Error("error")
    |> outcome.outcome

  assert actual == Error(expected)
}

pub fn context_test() {
  let expected = Problem(error: "failure", stack: ["context 2", "context 1"])

  let actual =
    Error("failure")
    |> outcome.outcome
    |> outcome.context("context 1")
    |> outcome.context("context 2")

  assert actual == Error(expected)
}

pub fn remove_problem_test() {
  let actual =
    Error("error")
    |> outcome.outcome
    |> outcome.remove_problem

  assert actual == Error("error")
}

pub fn pretty_print_test() {
  let error =
    Error("defect")
    |> outcome.outcome
    |> outcome.context("context inner")
    |> outcome.context("context outer")

  let actual = pretty_print_outcome(error)

  let expected =
    "defect

stack:
  context inner
  context outer"

  assert actual == expected
}

pub fn pretty_print_without_context_test() {
  let error =
    Error("defect")
    |> outcome.outcome

  let actual = pretty_print_outcome(error)

  assert actual == "defect"
}

pub fn print_line_test() {
  let error =
    Error("defect")
    |> outcome.outcome
    |> outcome.context("context inner")
    |> outcome.context("context outer")

  let actual = print_line_outcome(error)

  assert actual == "defect < context inner < context outer"
}

pub fn print_line_without_context_test() {
  let error = Error("defect") |> outcome.outcome

  let actual = print_line_outcome(error)

  assert actual == "defect"
}
