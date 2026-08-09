## BRIEF
Many Tokio applications (servers, network scanners, worker pools) use a standard **spawn-and-drain** task pattern:
1. **Spawn loop**: `set.spawn(future)` submits tasks to Tokio's task scheduler to run concurrently.
2. **Drain loop**: `set.join_next().await` awaits completed tasks as they finish, in **completion order** (which is non-deterministic).

Using `JoinSet` manages a pool of tasks and automatically cancels any remaining tasks if the set is dropped.

## GUIDED STEPS

1. Inspect `files/tokio_loop/src/main.rs` and `files/tokio_loop/Cargo.toml`.
2. Run `tokio_loop` and redirect output:
   ```bash
   cd files/tokio_loop && cargo run > ../../loop_out.txt && cd ../..
   ```
3. Create `answers.txt` answering the following questions:
   - `q1`: What does `set.spawn(probe(port))` do inside the loop?
     - `a`: Runs each probe sequentially to completion
     - `b`: Spawns concurrent tasks for the runtime to drive
     - `c`: Spawns raw OS threads
   - `q2`: In what order does `join_next().await` return task results?
     - `a`: In exact spawn order
     - `b`: In completion order — whichever task finishes next
     - `c`: In numerical order
   - `q3`: What integer count is printed for `tasks completed`? -> `4`
   - `q4`: What integer sum is printed for `port sum`? (22 + 80 + 443 + 8080) -> `8625`
   - `q5`: Why must task accumulators like `sum` be order-independent?
     - `a`: For formatting
     - `b`: Tasks complete in nondeterministic order, so only order-independent results remain stable
     - `c`: Tokio enforces it at compile time

Format `answers.txt`:
```text
q1=b
q2=b
q3=4
q4=8625
q5=b
```

4. Verify with `lab check rust L5.6`.
