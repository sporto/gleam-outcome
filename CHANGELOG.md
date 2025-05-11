# Changelog

## Unreleased

### Features

- [**breaking**] Remove severity
This version removes the severity (Defect, Failure). The idea of having
a Defect was copied from Effect.ts, this makes sense there as JS have
exceptions, and a Defect captures that. But after using this in Gleam
for a while in a real application, I concluded that it is better to
have the app define their own error type, which should include the
severity. The app can do better decisions on what severity is relevant.

