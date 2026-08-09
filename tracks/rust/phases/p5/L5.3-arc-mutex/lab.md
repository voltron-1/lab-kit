## BRIEF
To share mutable state across multiple OS threads in Rust, the canonical pattern is `Arc<Mutex<T>>`:
- **`Arc`**: Provides thread-safe shared ownership so multiple threads hold references to the allocation.
- **`Mutex`**: Provides synchronized access so only one thread can mutate `T` at any instant.

Calling `.lock()` returns a `Result<MutexGuard<T>>`. The `MutexGuard` uses RAII: when the guard variable goes out of scope and drops, the lock is automatically released.

If a thread holding the mutex panics, the mutex becomes **poisoned**, causing subsequent `.lock()` calls to return an `Err`.

## GUIDED STEPS

1. Inspect `files/sample.rs`.
2. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
3. Create `answers.txt` answering the following questions:
   - `q1`: What role does `Arc` serve in `Arc<Mutex<T>>`?
     - `a`: Synchronizes access
     - `b`: Provides shared ownership across threads to the same allocation
     - `c`: Memory allocation speedup
   - `q2`: What role does `Mutex` serve in `Arc<Mutex<T>>`?
     - `a`: Shared ownership
     - `b`: Synchronizes access so only one thread mutates at a time, making increments race-free
     - `c`: Atomic pointer tagging
   - `q3`: What integer count is printed by `sample.rs`? -> `100`
   - `q4`: When is the `Mutex` lock released?
     - `a`: Manual `unlock()` function call
     - `b`: Automatically when `MutexGuard` goes out of scope and drops (RAII)
     - `c`: When the main thread exits
   - `q5`: Under what condition does `.lock()` return an `Err`?
     - `a`: Lock timeout
     - `b`: Poisoned mutex — a thread panicked while holding the lock
     - `c`: High thread contention

Format `answers.txt`:
```text
q1=b
q2=b
q3=100
q4=b
q5=b
```

4. Verify with `lab check rust L5.3`.
