## BRIEF
Real Rust code uses a clear two-layer error pattern:
1. **Library Layer (`thiserror`)**: Defines typed enums representing all specific failure modes. `#[derive(Error)]` auto-generates `std::error::Error` and `Display` implementations using `#[error("...")]` templates. `#[from]` auto-derives `From<InnerError> for OuterError` so the `?` operator converts errors across module boundaries. Callers can pattern match on enum variants.
2. **Application Layer (`anyhow`)**: Dynamic error report wrapper (`anyhow::Result<T>`) used in binaries or top-level handlers. `.context("...")` decorates errors with readable breadcrumbs without losing underlying error causes.

`Result<T, ConcreteError>` indicates library code callers match on; `anyhow::Result<T>` indicates application code that reports errors.

## GUIDED STEPS

1. Inspect `files/excerpt.rs` (Note: this is a read-only exhibit and is not intended to be compiled).
2. Create `answers.txt` with your answers to the following questions:
   - `q1`: What does `#[error("...")]` generate on an enum variant?
     - `a`: The `Display` message formatting for that variant from the template
     - `b`: A panic handler
     - `c`: A log statement
   - `q2`: What does `#[from]` on `FeedError::Io` do?
     - `a`: Derives `From<std::io::Error>` so `?` converts I/O errors into `FeedError` automatically
     - `b`: Reads the file automatically
     - `c`: Retries failed I/O operations
   - `q3`: Where does `anyhow::Result` belong?
     - `a`: Libraries
     - `b`: Applications — callers who report error chains rather than match on variants
     - `c`: Everywhere equally
   - `q4`: What is the exact Display string generated for `FeedError::BadHeader(12)`?
   - `q5`: What does `.context("...")` add to an error chain?
     - `a`: A contextual breadcrumb layered onto the error chain shown in reports
     - `b`: A retry policy
     - `c`: A call-time log line

Format `answers.txt`:
```text
q1=a
q2=a
q3=b
q4=malformed header at byte 12
q5=a
```

3. Verify with `lab check rust L3.9`.
