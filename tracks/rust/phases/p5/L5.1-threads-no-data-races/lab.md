## BRIEF
Data races are a classic vulnerability class (CWE-362). In Rust, thread creation via `thread::spawn` requires data moved into the thread to satisfy `'static` lifetime bounds or be safely shared.

When a thread attempts to borrow local variables by reference without `move` or atomic sharing (`Arc`/`Mutex`), Rust's borrow checker rejects the code at **compile time** with error `E0373`.

Determinism rule: observable thread outputs should be order-independent (such as sums over join handles) rather than depending on OS scheduling order.

## GUIDED STEPS

1. Inspect `files/sample.rs`.
2. Predict the outcome of `files/sample.rs` and the error code when compiling `files/broken.rs`. Create `predictions.txt`:
   - `total`: The integer sum printed by `sample.rs` -> `60`
   - `error`: The error code produced when compiling `files/broken.rs` (`rustc files/broken.rs 2> rust_error.txt`) -> `E0373`

Format `predictions.txt`:
```text
total=60
error=E0373
```

3. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
4. Attempt to compile `files/broken.rs` and capture compiler error:
   ```bash
   rustc files/broken.rs 2> rust_error.txt || true
   ```
5. Verify with `lab check rust L5.1`.
