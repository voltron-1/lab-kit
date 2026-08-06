## BRIEF
This phase gate tests your ability to conduct a cold security audit of a 100% memory-safe Rust tool (`iocscan.rs`).
The tool compiles, runs, and satisfies its happy path, but harbors **six planted security flaws**:
- Flaw A (`within_limit`): Numeric truncation before bounds check (**CWE-197**)
- Flaw B (`report_path`): Path traversal via uncontained `Path::join` (**CWE-22**)
- Flaw C (`enrich_command`): OS command injection via shell string interpolation (**CWE-78**)
- Flaw D (`parse_count`): Panic-based DoS on malformed input via unwrap chain (**CWE-248**)
- Flaw E (`severity`): Inverted threshold access/classification logic bug (**logic**)
- Flaw F (`scan` `total`): Integer overflow in accumulator variable (**CWE-190**)

## GUIDED STEPS

1. Inspect `files/iocscan.rs`.
2. Compile and run `files/iocscan.rs`:
   ```bash
   rustc files/iocscan.rs -o iocscan
   ./iocscan
   ```
3. Create `answers.txt` recording the CWE / class identifier and reachability choice for each flaw slot (A–F):
   - `a`: CWE for Flaw A (`within_limit`) -> `CWE-197`
   - `whyA`: Why is Flaw A vulnerable?
     - `a`: 512 is within limit
     - `b`: `u32` to `u16` truncation occurs before comparison, allowing large values to pass
     - `c`: `MAX_LINE_BYTES` is too small
   - `b`: CWE for Flaw B (`report_path`) -> `CWE-22`
   - `whyB`: Why is Flaw B vulnerable?
     - `a`: The path does not exist
     - `b`: `Path::join` performs no containment check, so `..` in `name` escapes `base`
     - `c`: PathBuf allocation is expensive
   - `c`: CWE for Flaw C (`enrich_command`) -> `CWE-78`
   - `whyC`: Why is Flaw C vulnerable?
     - `a`: `whois` is deprecated
     - `b`: Untrusted `indicator` is interpolated into a shell string before execution
     - `c`: String length is unvalidated
   - `d`: CWE for Flaw D (`parse_count`) -> `CWE-248`
   - `whyD`: Why is Flaw D vulnerable?
     - `a`: `split_once` is slow
     - `b`: Every parse step unwraps, causing a single malformed record to crash the scan
     - `c`: `u32` is too small
   - `e`: Class identifier for Flaw E (`severity`) -> `logic`
   - `whyE`: Why is Flaw E vulnerable?
     - `a`: Input scores are invalid
     - `b`: The severity threshold comparison is inverted (`score < 10` returns "critical"), mapping high scores to "low"
     - `c`: String slice lifetime is invalid
   - `f`: CWE for Flaw F (`total: u16`) -> `CWE-190`
   - `whyF`: Why is Flaw F vulnerable?
     - `a`: HashMap order is unspecified
     - `b`: `total` is `u16` and overflows under large input counts (panic in debug, silent wrap in release)
     - `c`: Keys vector leaks memory

Format `answers.txt`:
```text
a=CWE-197
whyA=b
b=CWE-22
whyB=b
c=CWE-78
whyC=b
d=CWE-248
whyD=b
e=logic
whyE=b
f=CWE-190
whyF=b
```

4. Verify with `lab check rust L4.10`.
