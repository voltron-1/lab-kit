## BRIEF
In this lab, you trace open-port results from collection through sorting to the **nmap hand-off** in RustScan.

Passing open ports directly to an nmap subprocess as structured arguments avoids shell injection (CWE-78).

## GUIDED STEPS

1. Inspect `files/rustscan-src/output.rs`.
2. Notice `open_ports.sort()` — outputs are sorted because async probe completion order is nondeterministic.
3. Observe `run_nmap` — `Command::new("nmap")` builds an explicit argument vector.
4. Create `answers.txt`:
   - `q1`: A successful connect is recorded as:
     - `a`: An error
     - `b`: An open port pushed into a results collection
     - `c`: An immediate print with no storage
   - `q2`: Results are sorted before output because:
     - `a`: Speed
     - `b`: Async probe completion order is nondeterministic — sorting makes output stable
     - `c`: Required by OS
   - `q3`: After finding open ports, RustScan:
     - `a`: Stops
     - `b`: Hands the open ports to nmap for deep service detection
     - `c`: Retries
   - `q4`: What is the name of the function in `output.rs` that performs the nmap hand-off? -> `run_nmap`
   - `q5`: The open-port list is passed to the nmap subprocess as:
     - `a`: A concatenated shell string (injection-prone)
     - `b`: An argument vector / structured args (the L4.7-safe form)
     - `c`: An environment variable

Format `answers.txt`:
```text
q1=b
q2=b
q3=b
q4=run_nmap
q5=b
```

5. Verify with `lab check rust L6.2`.
