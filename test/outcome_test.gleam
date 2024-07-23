import gleeunit
import gleeunit/should
import outcome

pub fn main() {
  gleeunit.main()
}

// pub fn unwrap_failure_test() {
//   outcome.new_failure("Failure")
//   |> outcome.unwrap_failure("Default")
//   |> should.equal("Failure")

//   // Context doesn't affect the unwrapping
//   outcome.new_failure("Failure")
//   |> outcome.add_context_to_stack("Context")
//   |> outcome.unwrap_failure("Default")
//   |> should.equal("Failure")

//   // A Defect stops the unwrapping
//   outcome.new_stack_with_defect("Defect")
//   |> outcome.unwrap_failure("Default")
//   |> should.equal("Default")

//   // A Defect stops the unwrapping even with a Failure
//   outcome.new_failure("Failure")
//   |> outcome.add_defect_to_stack("Defect")
//   |> outcome.unwrap_failure("Default")
//   |> should.equal("Default")

//   // Can put a failure on top of a Defect
//   outcome.new_stack_with_defect("Defect")
//   |> outcome.add_failure_to_stack("Failure")
//   |> outcome.unwrap_failure("Default")
//   |> should.equal("Failure")
// }

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
