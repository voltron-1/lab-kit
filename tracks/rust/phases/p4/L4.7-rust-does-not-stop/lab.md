## BRIEF
**Memory safety ≠ Security.**

Rust eliminates memory corruption (buffer overflows, use-after-free, data races in safe code), but it does **not** protect against high-level application security vulnerabilities:
- **Path Traversal (CWE-22)**: `Path::new(base).join(untrusted)` does no boundary containment — `..` components break out of `base`.
- **Command Injection (CWE-78)**: Formatting untrusted variables into a shell string before execution allows arbitrary command injection.
- **Logic Flaws**: Swapped boolean flags or inverted access controls compile cleanly in 100% safe Rust.

Auditor takeaway: After verifying code is free of memory corruption, the security review has only just begun.

## GUIDED STEPS

1. Inspect `files/fetch.rs`.
2. Compile and run `files/fetch.rs`:
   ```bash
   rustc files/fetch.rs -o fetch
   ./fetch
   ```
3. Create `answers.txt` answering the following questions:
   - `q1`: What is the CWE identifier for Path Traversal in FLAW 1? (format `CWE-###`) -> `CWE-22`
   - `q2`: Why is `resolve` vulnerable to path traversal?
     - `a`: It can panic on long paths
     - `b`: `Path::join` performs no boundary containment check, so `..` in `name` escapes `base`
     - `c`: `PathBuf` uses extra memory
   - `q3`: What is the CWE identifier for OS Command Injection in FLAW 2? (format `CWE-###`) -> `CWE-78`
   - `q4`: What is the proper fix to prevent command injection in FLAW 2?
     - `a`: Escape double quotes in the string
     - `b`: Pass an argument vector directly (`Command::new("host").arg(host)`), avoiding shell invocation
     - `c`: Truncate the input to 16 bytes
   - `q5`: Which flaw will NO automated tool (clippy, cargo audit, borrow checker) detect?
     - `a`: FLAW 1
     - `b`: FLAW 3 (the inverted boolean access control logic bug)
     - `c`: FLAW 2
   - `q6`: What is the central thesis of Phase 4?
     - `a`: Rust code is automatically secure against all vulnerabilities
     - `b`: Memory safety is not security — safe Rust code can still suffer from traversal, injection, and logic flaws
     - `c`: Only `unsafe` code requires security review

Format `answers.txt`:
```text
q1=CWE-22
q2=b
q3=CWE-78
q4=b
q5=b
q6=b
```

4. Verify with `lab check rust L4.7`.
