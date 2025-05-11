# outcome

[![Package Version](https://img.shields.io/hexpm/v/outcome)](https://hex.pm/packages/outcome)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/outcome/)

An Error Handling library for Gleam. Inspired by
<https://github.com/lpil/snag> but with your own error type.

Outcome gives you:

- An error stack that makes it easier to track the path of an error.
- Use your error type (instead of `String`).

```sh
gleam add outcome
```

```gleam
import gleam/function
import outcome.{type Outcome}

fn run_program(email) {
  case signup(email) {
    Error(problem) -> {
      problem
      |> outcome.pretty_print(function.identity)
      |> echo
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

  todo
}

fn validate_email(email: String) -> Outcome(String, String) {
  Error("Invalid email")
    |> outcome.outcome
    |> outcome.context("in validate_email")
}
```

```text
run_program("invalid email")

Invalid email

stack:
  in validate_email
  in signup
```
