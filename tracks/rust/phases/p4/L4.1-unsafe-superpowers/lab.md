## BRIEF
`unsafe` in Rust unlocks exactly **five** superpowers and nothing else:
1. Dereference a raw pointer (`*const T`, `*mut T`).
2. Call an `unsafe` function or method (e.g. `slice::get_unchecked`).
3. Access or modify a mutable `static` variable.
4. Implement an `unsafe` trait (e.g. `Send`, `Sync`).
5. Access fields of a `union`.

`unsafe` does **NOT** disable the borrow checker, the type checker, or lifetime rules.
A `// SAFETY:` comment is the audit contract — it documents the invariant the human programmer guarantees because the compiler can no longer verify it.

Calling an `unsafe` function outside an `unsafe` block or function produces compile error **`E0133`**.

## GUIDED STEPS

1. Inspect `files/sample.rs`.
2. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
3. Create `answers.txt` answering the following questions:
   - `q1`: How many specific superpowers does `unsafe` unlock? (a number) -> `5`
   - `q2`: Does `unsafe` turn off the borrow checker or type system?
     - `a`: Yes
     - `b`: No — it only unlocks the five superpowers; all other Rust safety checks remain active
     - `c`: Only in release builds
   - `q3`: What byte value is printed by the `get_unchecked` call? -> `30`
   - `q4`: What is the purpose of the `// SAFETY:` comment?
     - `a`: Documentation decoration
     - `b`: It states the invariant the human developer guarantees, since the compiler no longer checks it
     - `c`: It silences compiler warnings
   - `q5`: What error code is produced when attempting to compile `files/broken.rs` (`rustc files/broken.rs`)? -> `E0133`

Format `answers.txt`:
```text
q1=5
q2=b
q3=30
q4=b
q5=E0133
```

4. Verify with `lab check rust L4.1`.
