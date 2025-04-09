# outcome

[![Package Version](https://img.shields.io/hexpm/v/outcome)](https://hex.pm/packages/outcome)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/outcome/)

An Error Handling library for Gleam. Inspired by
<https://github.com/lpil/snag> and <https://effect.website/>.

Outcomes gives you:

- An error stack that makes it easier to track the path of an error.
- A way to distinguish between unexpected errors (Defect) and expected errors (Failure).

```sh
gleam add outcome
```

```gleam
import gleam/function
import gleam/io
import outcome.{type Outcome}

fn run_program(email) {
  case signup(email) {
    Error(problem) -> {
      problem
      |> outcome.pretty_print(function.identity)
      |> io.debug
    }
    Ok(user) -> {
      todo
    }
  }
}

fn signup(email: String) -> Outcome(User, String) {
  use valid_email <- result.try(
    validate_email(email)
    |> outcome.context("in signup")
  )

  create_user(valid_email)
}

// An expected error should be marked as a failure
fn validate_email(email: String) -> Outcome(String, String) {
  Error("Invalid email")
    |> outcome.result_with_failure
    |> outcome.context("in validate_email")
}

// An unexpected error should be marked as a defect
fn create_user() -> Outcome(User, String) {
  Error("Some SQL error")
  |> outcome.result_with_defect
  |> outcome.context("in create_user")
}
```

```gleam
run_program("invalid email")

Failure: Invalid email

stack:
  in validate_email
  in signup
```

```gleam
run_program("sam@sample.com")

Defect: Some SQL error

stack:
  in create_user
  in signup
```

Further documentation can be found at <https://hexdocs.pm/outcome>.
