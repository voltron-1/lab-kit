## BRIEF
In Rust, `async fn` returns a **lazy `Future`**.
- Calling an `async fn` executes **no code** inside its body immediately.
- `.await` drives the future forward and yields control to the async runtime when waiting (e.g. on I/O or sleep).
- An async runtime (like `tokio`) polls futures to completion. `#[tokio::main]` sets up the runtime and drives `main`'s future.
- `tokio::join!` awaits multiple futures concurrently on a runtime task without requiring OS thread creation.

## GUIDED STEPS

1. Inspect `files/async_demo/src/main.rs` and `files/async_demo/Cargo.toml`.
2. Run the async program and redirect output:
   ```bash
   cd files/async_demo && cargo run > ../../async_out.txt && cd ../..
   ```
3. Create `answers.txt` answering the following questions:
   - `q1`: What happens when `work(21)` is called without `.await`?
     - `a`: Runs immediately
     - `b`: Returns an inert Future — nothing runs until awaited
     - `c`: Spawns a new OS thread
   - `q2`: What is the primary role of `.await`?
     - `a`: Blocks the current OS thread
     - `b`: Drives the future forward and yields control to the runtime while waiting
     - `c`: Creates a sub-process
   - `q3`: What integer value is printed for `result`? -> `42`
   - `q4`: What role does `#[tokio::main]` perform?
     - `a`: Marks functions as static
     - `b`: Initializes the Tokio runtime that polls main's future to completion
     - `c`: Enables multi-threading only
   - `q5`: How does `tokio::join!(work(1), work(2))` execute the two calls?
     - `a`: Strictly sequentially
     - `b`: Concurrently by driving both futures on the runtime
     - `c`: In separate processes

Format `answers.txt`:
```text
q1=b
q2=b
q3=42
q4=b
q5=b
```

4. Verify with `lab check rust L5.5`.
