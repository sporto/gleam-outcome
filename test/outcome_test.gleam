import gleeunit
import gleeunit/should
import non_empty_list
import outcome.{
  Defect, Failure, StackEntryContext, StackEntryDefect, StackEntryFailure,
}

pub fn main() {
  gleeunit.main()
}

pub fn into_defect_test() {
  Error("error")
  |> outcome.into_defect
  |> outcome.with_context("In context")
  |> outcome.outcome_to_lines
  |> should.equal(["Context: In context", "Defect: error"])
}

pub fn into_failure_test() {
  Error("a failure")
  |> outcome.into_failure
  |> outcome.with_context("In context")
  |> outcome.outcome_to_lines
  |> should.equal(["Context: In context", "Failure: a failure"])
}

pub fn failure_after_failure_test() {
  let expected =
    Failure(
      "failure 2",
      non_empty_list.new(StackEntryFailure("failure 2"), [
        StackEntryFailure("failure 1"),
      ]),
    )

  outcome.new_failure("failure 1")
  |> outcome.problem_with_failure("failure 2")
  |> should.equal(expected)
}

pub fn defect_after_failure_test() {
  let expected =
    Defect(
      "defect",
      non_empty_list.new(StackEntryDefect("defect"), [
        StackEntryFailure("failure"),
      ]),
    )

  outcome.new_failure("failure")
  |> outcome.problem_with_defect("defect")
  |> should.equal(expected)
}

pub fn defect_after_defect_test() {
  // The first defect bubbles up
  let expected =
    Defect(
      "defect 1",
      non_empty_list.new(StackEntryDefect("defect 2"), [
        StackEntryDefect("defect 1"),
      ]),
    )

  outcome.new_defect("defect 1")
  |> outcome.problem_with_defect("defect 2")
  |> should.equal(expected)
}

pub fn failure_after_defect_test() {
  // The defect bubbles up
  let expected =
    Defect(
      "defect",
      non_empty_list.new(StackEntryFailure("failure"), [
        StackEntryDefect("defect"),
      ]),
    )

  outcome.new_defect("defect")
  |> outcome.problem_with_failure("failure")
  |> should.equal(expected)
}

pub fn pretty_print_test() {
  let error =
    outcome.error_with_defect("defect 1")
    |> outcome.with_defect("defect 2")
    |> outcome.with_failure("failure")
    |> outcome.with_context("context")

  let pretty = outcome.pretty_print_outcome(error)

  pretty
  |> should.equal(
    "Defect: defect 1

stack:
  Context: context
  Failure: failure
  Defect: defect 2
  Defect: defect 1",
  )
}
