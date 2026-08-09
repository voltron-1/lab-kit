## BRIEF
Memory safety does **not** equal security. Rust's borrow checker ensures memory safety, but async code can still suffer from Availability & Denial of Service vulnerabilities:
- **Unbounded await**: An awaited operation (e.g. socket read) without a timeout allows silent clients to hold tasks and file descriptors open indefinitely (Slowloris attack).
- **Unbounded task spawning**: Spawning an un-capped task per connection under heavy load leads to resource exhaustion (memory/FD exhaustion).

Both vulnerability patterns belong to **CWE-400** (Uncontrolled Resource Consumption).
Remediations include `tokio::time::timeout` wrappers and `tokio::sync::Semaphore` concurrency limits.

Note: `files/server.rs` is a read-only exhibit for audit purposes and is not intended to be compiled.

## GUIDED STEPS

1. Audit `files/server.rs` by reading the code and identifying the availability flaws.
2. Create `answers.txt` answering the following questions:
   - `q1`: What vulnerability does FLAW 1 (unbounded await) represent?
     - `a`: A memory leak
     - `b`: An unbounded await — a read without a timeout lets silent clients hold tasks open indefinitely (slowloris)
     - `c`: A data race
   - `q2`: What is the correct fix for FLAW 1?
     - `a`: Increase buffer size
     - `b`: Wrap the read in `tokio::time::timeout` and drop the connection on timeout
     - `c`: Add more CPU cores
   - `q3`: What vulnerability does FLAW 2 (unbounded spawning) represent?
     - `a`: Code style issue
     - `b`: Unbounded task spawning per connection — flooding connections exhausts memory and FDs
     - `c`: Syntax error
   - `q4`: What is the correct fix for FLAW 2?
     - `a`: Use `unwrap()` less
     - `b`: Bound concurrency using a Semaphore permit or a bounded channel/pool
     - `c`: Insert thread sleep calls
   - `q5`: What CWE class corresponds to uncontrolled resource consumption? (format `CWE-###`) -> `CWE-400`
   - `q6`: What does the presence of these flaws demonstrate?
     - `a`: Unsafe code was used
     - `b`: Memory safety is distinct from availability — memory-safe Rust can still suffer from DoS vulnerabilities
     - `c`: Borrow checker bugs

Format `answers.txt`:
```text
q1=b
q2=b
q3=b
q4=b
q5=CWE-400
q6=b
```

3. Verify with `lab check rust L5.7`.
