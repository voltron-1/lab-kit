## BRIEF
`Send` and `Sync` are built-in marker traits in Rust that control concurrency bounds:
- **Send**: Indicates safe transfer of ownership of `T` to another thread.
- **Sync**: Indicates safe sharing of references `&T` across threads (`T: Sync` if and only if `&T: Send`).

Types like `Rc<T>` have non-atomic reference counts, so `Rc<T>` is `!Send` and `!Sync`. Moving an `Rc<T>` across thread boundaries produces compiler error **`E0277`**.

Thread-safe reference counting requires `Arc<T>` (Atomic Reference Counting).

## GUIDED STEPS

1. Inspect `files/sample.rs` and `files/broken.rs`.
2. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
3. Attempt to compile `files/broken.rs` and capture compiler output:
   ```bash
   rustc files/broken.rs 2> rust_error.txt || true
   ```
4. Create `answers.txt` with answers to the following questions:
   - `q1`: What does the `Send` marker trait indicate?
     - `a`: Safe to move ownership to another thread
     - `b`: Safe to share references across threads
     - `c`: Thread-local storage only
   - `q2`: What does the `Sync` marker trait indicate?
     - `a`: Safe to move ownership to another thread
     - `b`: Safe to share `&T` across threads
     - `c`: Atomic execution
   - `q3`: What integer value is printed for `from_thread` in `sample.rs`? -> `60`
   - `q4`: Why is `Rc` marked `!Send` by the compiler?
     - `a`: Performance optimization
     - `b`: Its reference count is non-atomic — sharing across threads would race the count (CWE-362)
     - `c`: Deprecated type
   - `q5`: What error code is produced when attempting to send `Rc` across threads in `broken.rs`? -> `E0277`

Format `answers.txt`:
```text
q1=a
q2=b
q3=60
q4=b
q5=E0277
```

5. Verify with `lab check rust L5.2`.
