import gleeunit
import gleeunit/should
import outcome

pub fn main() {
  gleeunit.main()
}

pub fn unwrap_failure_test() {
  outcome.new_stack_with_failure("Failure")
  |> outcome.unwrap_failure("Default")
  |> should.equal("Failure")

  // Context doesn't affect the unwrapping
  outcome.new_stack_with_failure("Failure")
  |> outcome.add_context_to_stack("Context")
  |> outcome.unwrap_failure("Default")
  |> should.equal("Failure")

  // A Defect stops the unwrapping
  outcome.new_stack_with_defect("Defect")
  |> outcome.unwrap_failure("Default")
  |> should.equal("Default")

  // A Defect stops the unwrapping even with a Failure
  outcome.new_stack_with_failure("Failure")
  |> outcome.add_defect_to_stack("Defect")
  |> outcome.unwrap_failure("Default")
  |> should.equal("Default")

  // Can put a failure on top of a Defect
  outcome.new_stack_with_defect("Defect")
  |> outcome.add_failure_to_stack("Failure")
  |> outcome.unwrap_failure("Default")
  |> should.equal("Failure")
}

pub fn pretty_print_test() {
  let stack =
    outcome.new_stack_with_defect("defect")
    |> outcome.add_failure_to_stack("failure")
    |> outcome.add_context_to_stack("context")

  let pretty = outcome.pretty_print(stack)

  pretty
  |> should.equal(
    "Context: context
Failure: failure
Defect: defect",
  )
}
