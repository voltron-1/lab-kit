## BRIEF
This phase gate requires tracing the data flow of a production-style Tokio tool: a bounded-concurrency network port scanner.

The scanner combines all core Phase 5 concepts:
- **`Semaphore`**: Bounds max in-flight probes to prevent resource exhaustion.
- **`timeout`**: Bounds socket connect duration so unreachable ports don't hang.
- **`mpsc channel`**: Transmits open ports from producer tasks to a single collector loop.
- **`Arc`**: Shares the Semaphore across async tasks.
- **Race-free design**: Shared mutable state is avoided; tasks communicate by message.
- **Determinism**: Results are sorted before output because task completion order is non-deterministic.

Note: `files/scanner.rs` is a read-only exhibit. Do not compile or execute it.

## GUIDED STEPS

1. Read and trace `files/scanner.rs`.
2. Create `answers.txt` answering the 10 data flow questions:
   - `q1`: What constant defines the maximum in-flight probe cap? -> `MAX_IN_FLIGHT`
   - `q2`: What integer number of maximum probes can run concurrently? -> `100`
   - `q3`: What primitive bounds individual connection attempts?
     - `a`: Semaphore
     - `b`: `timeout` with CONNECT_TIMEOUT (500ms)
     - `c`: Nothing
   - `q4`: How are open port results passed back to main?
     - `a`: Shared global Vec
     - `b`: An mpsc channel (tasks send, main receives)
     - `c`: Global variable
   - `q5`: Why is this scanner race-free without a Mutex?
     - `a`: Luck
     - `b`: Tasks own their data and communicate by message, sharing nothing mutably
     - `c`: Tokio disables data races
   - `q6`: What is the purpose of `drop(permit)`?
     - `a`: Closes the channel
     - `b`: Releases the Semaphore permit slot so another probe task can start
     - `c`: Cancels the task
   - `q7`: Why is `drop(tx)` called before the receiving loop?
     - `a`: To save memory
     - `b`: So the receive loop terminates once all task transmitters drop, preventing a hang
     - `c`: Resets the channel
   - `q8`: Why is `open_ports.sort()` called at the end?
     - `a`: For performance
     - `b`: Probe tasks finish in nondeterministic order, so sorting stabilizes the result
     - `c`: Required by Tokio
   - `q9`: Which control directly prevents resource exhaustion under heavy probing?
     - `a`: The timeout
     - `b`: The Semaphore concurrency cap (CWE-400 defense)
     - `c`: The sort
   - `q10`: What core thesis does this scanner demonstrate?
     - `a`: Async requires unsafe code
     - `b`: Rust eliminates data races at compile time, but availability controls (timeouts, caps) remain the developer's responsibility
     - `c`: Concurrency is unsafe

Format `answers.txt`:
```text
q1=MAX_IN_FLIGHT
q2=100
q3=b
q4=b
q5=b
q6=b
q7=b
q8=b
q9=b
q10=b
```

3. Verify with `lab check rust L5.8`.
