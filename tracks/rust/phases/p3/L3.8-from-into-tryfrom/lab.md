## BRIEF
Type conversions in Rust follow explicit contracts:
1. **Infallible (`From` / `Into`)**: Widening conversions (e.g. `u16` -> `u32`) cannot fail. Implementing `From<A> for B` automatically provides `a.into()`.
2. **Fallible (`TryFrom` / `TryInto`)**: Narrowing conversions (e.g. `u32` -> `u16`) can fail if out of bounds. Returns a `Result<T, Error>` requiring explicit handling (e.g. `match` or `unwrap_or`).
3. **Silent Truncation (`as`)**: The `as` cast keyword NEVER fails — it silently truncates values (`70000_u32 as u16` = `70000 - 65536` = `4464`). In security reviews, `as` on untrusted numeric inputs is a flag.

## GUIDED STEPS

1. Inspect `files/sample.rs`.
2. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
3. Create `answers.txt` with your answers to the following questions:
   - `q1`: What is the distinction between `From` and `TryFrom`?
     - `a`: Widening conversions use `From` (infallible); narrowing conversions use `TryFrom` (returns `Result`)
     - `b`: `From` and `TryFrom` are identical and interchangeable
     - `c`: `TryFrom` is legacy syntax
   - `q2`: What value is printed for `wide2`?
   - `q3`: What value is printed for `clamped`?
   - `q4`: What value is printed for `truncated`?
   - `q5`: Why is `as` a security review flag on untrusted inputs?
     - `a`: It is slow
     - `b`: It has no error path and silently truncates overflow; `try_from` enforces an explicit policy
     - `c`: `as` requires an unsafe block

Format `answers.txt`:
```text
q1=a
q2=8443
q3=65535
q4=4464
q5=b
```

4. Verify with `lab check rust L3.8`.
