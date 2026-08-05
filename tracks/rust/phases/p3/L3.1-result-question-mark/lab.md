## BRIEF
`Result<T, E>` is an ordinary enum in Rust: `Ok(T)` or `Err(E)`. Errors are not exceptions; they are normal values that travel through return types.

The `?` operator is a visible early return. When placed after an expression returning a `Result`, it expands to:
- On `Ok(value)`: unwraps the inner value and allows execution to continue.
- On `Err(err)`: returns `Err(err)` immediately from the enclosing function.

Because `?` returns early from the current function on error, it can **only** be used inside a function whose return type can hold the error (such as a `Result` or `Option`).

## GUIDED STEPS

1. Inspect `files/sample.rs`. Notice how `parse_port` uses `parse()?` to parse a port string into a `u16`.
2. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
3. Create `answers.txt` answering the following questions:
   - `q1`: What does `?` do when `parse()` returns an `Err`?
     - `a`: Panics immediately
     - `b`: Returns the `Err` to `parse_port`'s caller immediately
     - `c`: Logs the error and continues
   - `q2`: What does `?` do when `parse()` returns an `Ok`?
     - `a`: Unwraps the value into `port`
     - `b`: Returns early
     - `c`: Clones the string
   - `q3`: What port number is printed on the first output line? (e.g. `443`)
   - `q4`: Why can't a function returning `()` use `?` on a `Result`?
     - `a`: It can
     - `b`: `?` early-returns the `Err`, so the enclosing function's return type must be able to hold it — `()` cannot
     - `c`: `?` is method-only
   - `error`: Attempt to compile `files/broken.rs` (`rustc files/broken.rs`). Record the error code printed on the first line (e.g. `E0277`).

Format `answers.txt`:
```text
q1=b
q2=a
q3=443
q4=b
error=E0277
```

4. Verify your answers with `lab check rust L3.1`.
