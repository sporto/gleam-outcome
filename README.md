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
import outcome.{type Outcome}

fn using(email) {
  case signup(email) {
    Error(stack) -> io.print(outcome.pretty_print(stack))
    Ok(user) -> {
      //...
    }
  }
}

fn signup(email: String) -> Outcome(User) {
  use valid_email <- result.try(
    validate_email(email)
    |> outcome.with_context("In signup")
  )

  create_user(valid_email)
}

// An expected error should be marked as a failure
fn validate_email(email: String) -> Outcome(String) {
  Error("Invalid email")
    |> outcome.into_failure
}

// An unexpected error should be marked as a defect
fn create_user() -> Outcome(User) {
  Error("Some SQL error")
  |> outcome.into_defect
  |> outcome.with_context("In create_user")
}
```

```gleam
using("invalid")

Failure: Invalid email

stack:
  Context: In signup
  Failure: Invalid email
```

```gleam
using("sam@sample.com")

Defect: Some SQL error

stack:
  c: In signup
  c: In create_user
  d: Some SQL error
```

## Notes

- When you push a defect on top of a failure, then the `Problem` becomes a defect.
- When a problem is a `Defect` it stays a `Defect` unless explicitly changed.

Further documentation can be found at <https://hexdocs.pm/outcome>.
