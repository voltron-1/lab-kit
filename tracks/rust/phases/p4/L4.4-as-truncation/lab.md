## BRIEF
An `as` cast between integer types **never fails** — it silently truncates (when narrowing) or extends (when widening).
When a narrowing `as` cast is placed *before* a bounds check, it silently truncates large inputs, allowing oversized values to defeat the check completely (**CWE-197**).

Auditor rule: Any `as` cast on data derived from untrusted input — especially near length, index, or size checks — is a red flag. Use `TryFrom` to make overflow an explicit decision.

## GUIDED STEPS

1. Inspect `files/sample.rs`.
2. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
3. Create `answers.txt` answering the following audit questions:
   - `q1`: Why does `accept(65636)` return `true`?
     - `a`: 65636 is less than 4096
     - `b`: `declared_len as u16` truncates 65636 to 100 before the comparison, so the gate compares 100 <= 4096
     - `c`: The compiler optimizes away the check
   - `q2`: What value is produced by `65636_u32 as u16`? -> `100`
   - `q3`: What is the CWE identifier for numeric truncation bugs? (format `CWE-###`) -> `CWE-197`
   - `q4`: What is the proper fix for the size gate?
     - `a`: Increase `MAX`
     - `b`: Validate with `u16::try_from` (or compare directly in `u32`) so out-of-range values return `Err`/`false` rather than narrowing silently
     - `c`: Add a code comment
   - `q5`: What is the code review heuristic for `as` casts?
     - `a`: `as` is always safe
     - `b`: Any `as` on input-derived data near a length, index, or comparison is a flag requiring verification
     - `c`: `as` only matters inside `unsafe` blocks

Format `answers.txt`:
```text
q1=b
q2=100
q3=CWE-197
q4=b
q5=b
```

4. Verify with `lab check rust L4.4`.
