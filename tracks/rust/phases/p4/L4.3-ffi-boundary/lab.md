## BRIEF
FFI (Foreign Function Interface) is where Rust's safety guarantees end.
An `extern "C"` declaration is an **unchecked promise** made by the human developer:
- The compiler cannot verify if the C function exists, matches the signature, or upholds null/lifetime invariants.
- If an `extern "C"` declaration is wrong, calling it causes immediate **undefined behavior**.
- Calling any foreign C function requires an `unsafe` block or function; omitting it produces compile error **`E0133`**.
- Structs passed across FFI boundaries require `#[repr(C)]` for C-compatible memory layout.

## GUIDED STEPS

1. Inspect `files/sample.rs`.
2. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
3. Create `answers.txt` answering the following questions:
   - `q1`: What does the `extern "C"` declaration guarantee about `abs`?
     - `a`: The compiler verifies it against libc
     - `b`: Nothing — it is an unchecked promise made by the developer; a wrong signature is undefined behavior
     - `c`: That `abs` is safe from panics
   - `q2`: What value is printed by `abs(-9)`? -> `9`
   - `q3`: Why does calling `abs` require `unsafe`?
     - `a`: libc is deprecated
     - `b`: The compiler cannot check that foreign C code respects Rust's invariants — the boundary is a trust boundary
     - `c`: It performs a heap allocation
   - `q4`: How far into foreign C code does the Rust borrow checker reach?
     - `a`: Into all C functions linked at build time
     - `b`: It does not reach — no lifetimes, aliasing rules, or null safety are checked across FFI
     - `c`: It runs at link time
   - `q5`: What error code is produced when attempting to compile `files/broken.rs` (`rustc files/broken.rs`)? -> `E0133`

Format `answers.txt`:
```text
q1=b
q2=9
q3=b
q4=b
q5=E0133
```

4. Verify with `lab check rust L4.3`.
