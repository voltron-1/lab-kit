## BRIEF
`unwrap()` and `expect()` are crash-on-purpose constructs: when an `Option` is `None` or a `Result` is `Err`, they detonate a panic and terminate the process.

While acceptable in tests or single-use scripts, using `unwrap()` on untrusted user input creates a **Denial of Service (DoS) vulnerability** (CWE-248: Uncaught Exception). One malicious or malformed request will crash the entire worker or process.

## GUIDED STEPS

1. Inspect `files/ingest.rs`. It compiles without warnings, but contains multiple panic paths.
2. Compile `files/ingest.rs`:
   ```bash
   rustc files/ingest.rs -o ingest
   ```
3. Test the happy path:
   ```bash
   ./ingest "scan:512"
   ```
4. Detonate a panic caused by a malformed argument (missing colon `:`), capturing stderr into `panic1.txt`:
   ```bash
   ./ingest "scan-512" 2> panic1.txt
   ```
5. Create `answers.txt` answering the audit questions:
   - `q1`: Total panic-capable call sites in `ingest.rs` (including `unwrap` and `expect`) -> `4`
   - `q2`: Total panic sites reachable by a crafted argument *value* (excluding missing argument) -> `3`
   - `q3`: What is the security impact of `unwrap()` on untrusted input?
     - `a`: Memory corruption
     - `b`: Denial of service — one request kills the process (CWE-248)
     - `c`: Privilege escalation
   - `q4`: Honest take on `expect()` vs `unwrap()` on production input paths:
     - `a`: Same crash, but the message documents the assumption — better forensics, same DoS
     - `b`: `expect()` handles the error gracefully
     - `c`: `expect()` only emits a compiler warning
   - `q5`: What is the proper fix direction for production code?
     - `a`: Call `unwrap()` but log before doing so
     - `b`: Make failure a handled value using `match`, `?`, or `unwrap_or` with explicit policy
     - `c`: Catch the panic downstream with `catch_unwind`

Format `answers.txt`:
```text
q1=4
q2=3
q3=b
q4=a
q5=b
```

6. Verify with `lab check rust L3.2`.
