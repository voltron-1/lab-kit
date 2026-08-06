## BRIEF
Parser-combinators like `nom` process input streams by returning `(value, remaining)` pairs threaded through the `?` operator.

The single security-critical habit when parsing untrusted binary formats: **every read must be bounds-checked BEFORE it occurs**.
In `sample.rs`, `take` checks `input.len() < n` before taking a slice. When a hostile payload claims a length of 200 with only 2 bytes remaining, `take` returns `None` and `?` propagates the error cleanly — turning what would be an out-of-bounds read into a handled rejection.

## GUIDED STEPS

1. Inspect `files/sample.rs`.
2. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
3. Create `answers.txt` answering the following questions:
   - `q1`: What does `take` do when `input.len() < n`?
     - `a`: It panics
     - `b`: It returns `None`, refusing to read past the end of the buffer
     - `c`: It returns zeroed bytes
   - `q2`: What payload length is printed for the valid record? -> `3`
   - `q3`: What trailing byte count is printed for the valid record? -> `1`
   - `q4`: Why is the hostile record rejected?
     - `a`: The tag byte is invalid
     - `b`: It claims length 200 (`0xC8`), but only 2 bytes follow, so `take` returns `None` and `?` propagates it
     - `c`: `parse_record` requires UTF-8 text
   - `q5`: How does `take` differ from `L4.2`'s `from_raw_parts` exhibit?
     - `a`: There is no difference
     - `b`: `take` bounds-checks the length before slicing, turning an attack into a handled error instead of an out-of-bounds read
     - `c`: `take` uses `unsafe`

Format `answers.txt`:
```text
q1=b
q2=3
q3=1
q4=b
q5=b
```

4. Verify with `lab check rust L4.6`.
