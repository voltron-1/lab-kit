## BRIEF
`cargo audit` checks a Rust project's dependency tree against the RUSTSEC advisory database for known vulnerabilities (CVEs and memory corruption advisories).
`cargo deny` goes further by enforcing CI policy rules — banning undesirable licenses, duplicate dependency versions, unmaintained crates, and specific security risks.

Supply-chain risks are invisible to the Rust compiler — a crate can compile cleanly while harboring a known critical vulnerability.

## GUIDED STEPS

1. Inspect `files/advisory.txt` to examine the structure of a RUSTSEC advisory record.
2. In your workspace (or against `files/vuln-project`), generate or simulate an audit report output into `audit_out.txt`:
   ```bash
   cd files/vuln-project && cargo audit > ../../audit_out.txt 2>&1 || echo "RUSTSEC-2023-0001: Vulnerability found" > ../../audit_out.txt
   ```
   *(Ensure `audit_out.txt` contains at least one `RUSTSEC` line).*
3. Create `answers.txt` answering the following questions:
   - `q1`: What does `cargo audit` check?
     - `a`: Code formatting and style
     - `b`: Your dependency tree against the RUSTSEC advisory database for known-vulnerable versions
     - `c`: Type check errors
   - `q2`: What additional capability does `cargo deny` provide beyond `cargo audit`?
     - `a`: Nothing
     - `b`: CI policy enforcement — banning undesirable licenses, duplicate versions, unmaintained or specific crates
     - `c`: Automatic refactoring
   - `q3`: What prefix is shared by all RUSTSEC advisory IDs? (format `RUSTSEC`) -> `RUSTSEC`
   - `q4`: What does a `cargo audit` warning signify?
     - `a`: Your local code has a syntax error
     - `b`: A dependency in your tree has a published security advisory — supply chain risk invisible to the compiler
     - `c`: The compiler version is outdated
   - `q5`: What is the primary remediation for a `cargo audit` finding?
     - `a`: Rewrite the crate yourself
     - `b`: Upgrade the dependency to a patched version (or remove/replace the crate)
     - `c`: Wrap the dependency in an `unsafe` block

Format `answers.txt`:
```text
q1=b
q2=b
q3=RUSTSEC
q4=b
q5=b
```

4. Verify with `lab check rust L4.8`.
