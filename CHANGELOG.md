# Changelog

## 3.0.0

Split the package into two modules `outcome` and `problem`.
Move functions related the `Problem` type to `problem`.

- Moved `new_defect` to `problem` module.
- Moved `new_failure` to `problem` module.
- Moved `get_failure` to `problem` module.
- Rename `result_to_defect` to `result_with_defect`
- Rename `result_to_failure` to `result_with_failure`


## 2.0.0

This library has many helper functions that do the same thing as the standard libray methods.
Instead of making the API more terse, these functions just make the library more confusing.
Also has several functions that are not very clear where they apply.

This release renames some functions to make them clearer. And removes several functions that just wrap the standard library.

- Removed `map_defect`
- Removed `map_failure`
- Renamed `extract_error` to `to_simple_result`
- Renamed `into_defect` to `result_to_defect`
- Renamed `into_failure` to `result_to_failure`
- Renamed `unwrap_failure` to `get_failure_in_problem`
- Update `pretty_print` formatting. Stack has the closest context at the top
- Update `print_line` formatting

### Removed `error_with_defect`.

Use `Error("") |> result_to_defect` instead.

### Removed `error_with_failure`.

Use `Error("") |> result_to_failure` instead.

### Removed `map_result_to_defect`.

Use `result.map_error(..) |> outcome.result_to_defect` to map the error instead.

### Removed `map_result_to_failure`.

Use `result.map_error(..) |> outcome.result_to_failure` to map the error instead.

### Removed `replace_with_defect`

Use `result.replace_error(..) |> outcome.result_to_defect` instead.

### Removed `replace_with_failure`

Use `result.replace_error(..) |> outcome.result_to_failure` instead.

## 1.1.0

- Expose functions `new_failure` and `new_defect`

## 0.11

- Renamed `with_context` to `context`
