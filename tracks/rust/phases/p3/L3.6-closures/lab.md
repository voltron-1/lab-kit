## BRIEF
Rust closures automatically capture variables from their enclosing scope:
1. **Shared Borrow (`&T`)**: Lightest borrow (e.g. `is_high` reads `threshold`; `threshold` remains usable).
2. **Mutable Borrow (`&mut T`)**: Takes a mutable borrow (e.g. `bump` mutates `streak`; the closure variable itself requires `let mut bump`).
3. **Move (`move`)**: Transfers ownership of captured variables into the closure structure (e.g. `move |v| format!("{tag}:{v}")`).

When a closure uses `move`, captured non-`Copy` variables are moved into the closure. Attempting to use them afterward in the outer scope results in **`E0382`** (use of moved value).

## GUIDED STEPS

1. Inspect `files/sample.rs`.
2. Create `predictions.txt` with your predictions:
   - `high`: output of `is_high(150)` (`true` or `false`) -> `high=true`
   - `threshold`: value printed for `threshold still` -> `threshold=100`
   - `streak`: final value printed for `streak` after 3 calls -> `streak=3`
   - `error`: compile error code when attempting `rustc files/broken.rs` -> `error=E0382`

Format `predictions.txt`:
```text
high=true
threshold=100
streak=3
error=E0382
```

3. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
4. Compile `files/broken.rs` (`rustc files/broken.rs`) to verify the `E0382` error code.
5. Verify with `lab check rust L3.6`.
