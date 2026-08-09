## BRIEF
Welcome to Phase 6! In this phase, you tour **REAL open-source security tools** in Rust.

`RustScan` is a popular, high-speed port scanner. In this lab, you read its CLI definition and scan loop to see how user options map to bounded async concurrency.

## GUIDED STEPS

1. Inspect `files/rustscan-src/Cargo.toml` — notice it is a binary crate using `clap` for argument parsing.
2. Inspect `files/rustscan-src/opts.rs` — find the `Opts` struct exposing targets, ports, batch size, and timeout.
3. Inspect `files/rustscan-src/scanner.rs` — find `scan_batch` where batch futures are constructed and wrapped with `tokio::time::timeout`.
4. Create `answers.txt` with answers to the following questions:
   - `q1`: RustScan is a:
     - `a`: Library crate
     - `b`: Binary (CLI) crate
     - `c`: Proc-macro
   - `q2`: The four core user-facing options in `Opts` are:
     - `a`: Colors, verbosity, log file, help
     - `b`: Targets, ports, batch size, timeout
     - `c`: Threads, nice level, PID, cwd
   - `q3`: What is the exact name of the argument parser struct in `opts.rs`? -> `Opts`
   - `q4`: Concurrency in the scan loop is bounded by:
     - `a`: Nothing (unbounded)
     - `b`: Batch size — a fixed number of connect futures are awaited per batch
     - `c`: Thread sleep
   - `q5`: Each connection attempt is:
     - `a`: Unbounded (can hang forever)
     - `b`: Time-bounded by the timeout option
     - `c`: Retried infinitely

Format `answers.txt`:
```text
q1=b
q2=b
q3=Opts
q4=b
q5=b
```

5. Verify with `lab check rust L6.1`.
