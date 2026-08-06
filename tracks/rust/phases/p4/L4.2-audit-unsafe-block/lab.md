## BRIEF
When auditing an `unsafe` block, check four mandatory invariants:
1. **Pointer Validity**: Is the pointer non-null, properly aligned, and pointing to initialized memory?
2. **Bounds & Length**: Is the length parameter strictly within the bounds of the allocated buffer?
3. **Lifetimes**: Does the returned reference borrow from the underlying buffer, or does it claim an unearned lifetime (e.g. `&'static`)?
4. **Safety Contract**: Is the `// SAFETY:` comment's invariant actually established by the caller?

In this lab, you audit `exhibit.rs` (a read-only exhibit — do not compile or run it).

## GUIDED STEPS

1. Inspect `files/exhibit.rs`.
2. Audit `files/exhibit.rs` against the four-point checklist.
3. Create `answers.txt` answering the following audit questions:
   - `q1`: What is the primary safety flaw in `parse_record`?
     - `a`: The pointer might be null
     - `b`: `declared` length is attacker-controlled and never bounds-checked against `buf.len()`
     - `c`: `u32::from_be_bytes` is slow
   - `q2`: What is the CWE identifier for reading past the end of a buffer? (format `CWE-###`) -> `CWE-125`
   - `q3`: What is wrong with the `&'static [u8]` return type of `view`?
     - `a`: Slices cannot be static
     - `b`: It claims an unearned `'static` lifetime, disguising a borrow of `buf` and inviting use-after-free
     - `c`: It requires an extra heap allocation
   - `q4`: What is wrong with the `// SAFETY:` comment on `view`?
     - `a`: Nothing
     - `b`: It states an invariant (`data points to len valid bytes`) that the caller `parse_record` never establishes
     - `c`: It is missing syntax formatting
   - `q5`: What is the proper fix for this code?
     - `a`: Add a null check
     - `b`: Bounds-check `declared` against `buf.len()` and use safe slicing (`&buf[4..4 + declared]`) — no `unsafe` needed
     - `c`: Mark `parse_record` as `unsafe` too

Format `answers.txt`:
```text
q1=b
q2=CWE-125
q3=b
q4=b
q5=b
```

4. Verify with `lab check rust L4.2`.
