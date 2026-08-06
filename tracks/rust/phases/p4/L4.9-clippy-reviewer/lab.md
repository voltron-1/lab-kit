## BRIEF
`clippy` is Rust's linter — a fast automated first-pass reviewer for idiomatic code, anti-patterns, performance improvements, and common correctness smells.

Triage rule: Most Clippy lints are cosmetic or idiomatic (`needless_return`, `identity_op`). A few point to real correctness issues. **Clippy does NOT detect security-class flaws** like path traversal (CWE-22), command injection (CWE-78), or inverted access control logic. A "clean" Clippy run does not mean code is secure.

## GUIDED STEPS

1. Inspect `files/lints.rs`.
2. Run clippy or simulate clippy on `files/lints.rs`, capturing output to `clippy_out.txt`:
   ```bash
   clippy-driver files/lints.rs 2> clippy_out.txt || echo "warning: clippy::needless_range_loop" > clippy_out.txt
   ```
   *(Ensure `clippy_out.txt` contains the word `clippy`).*
3. Create `answers.txt` answering the following questions:
   - `q1`: What role does Clippy serve in code review?
     - `a`: Code formatter
     - `b`: A fast first-pass reviewer for idiom, performance, and correctness smells
     - `c`: A compiler backend
   - `q2`: How should lints like `needless_return` and `identity_op` be classified?
     - `a`: Critical security vulnerabilities
     - `b`: Cosmetic / idiomatic style recommendations
     - `c`: Compile errors
   - `q3`: Will Clippy detect path traversal (CWE-22) or inverted boolean access controls?
     - `a`: Yes
     - `b`: No — high-level logic, injection, and traversal flaws are invisible to linters
     - `c`: Only with `--all-targets`
   - `q4`: What is the name of the lint that flags manual loop indexing (`for i in 0..events.len()`) without the `clippy::` prefix? -> `needless_range_loop`
   - `q5`: What does a "clean Clippy run" signify?
     - `a`: The code is 100% secure
     - `b`: The code is idiomatic — human security review remains necessary
     - `c`: All unit tests passed

Format `answers.txt`:
```text
q1=b
q2=b
q3=b
q4=needless_range_loop
q5=b
```

4. Verify with `lab check rust L4.9`.
