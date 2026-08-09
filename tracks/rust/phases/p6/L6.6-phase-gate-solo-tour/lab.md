## BRIEF
This is the **Phase 6 Phase Gate**. You are presented with a real, unseen security-adjacent tool (`hexyl`, a hex viewer).

Without guided narration, read the codebase and answer the 8 structural auditor questions cold.

## GUIDED STEPS

1. Inspect `files/mystery-src/Cargo.toml`.
2. Inspect `files/mystery-src/src/main.rs` and `files/mystery-src/src/hex.rs`.
3. Create `answers.txt` with answers to the 8 structural questions:
   - `q1`: Is this a binary or library crate? -> `a` (binary crate with main.rs)
   - `q2`: What is the crate name in `Cargo.toml`? -> `hexyl`
   - `q3`: What is the file path of the main entry point from crate root? -> `src/main.rs`
   - `q4`: What does this tool do?
     - `a`: Port scanning
     - `b`: Hex viewing / formatting raw bytes from a file
     - `c`: Password cracking
   - `q5`: Where does untrusted input ENTER?
     - `a`: CLI args / file specified on command line
     - `b`: Network socket
     - `c`: Environment variables only
   - `q6`: What is the name of the core function in `src/hex.rs` that formats bytes? -> `format_hex`
   - `q7`: The failure posture when reading bytes in `format_hex`:
     - `a`: Panics on EOF
     - `b`: Returns Result/Ok match loop and handles end of file safely
     - `c`: Infinite loop
   - `q8`: Which Rust concept is visibly used in `format_hex`?
     - `a`: Raw pointers
     - `b`: Slice borrowing (`&buffer[..bytes_read]`) and trait bounds (`<R: Read>`)
     - `c`: Unsafe blocks

Format `answers.txt`:
```text
q1=a
q2=hexyl
q3=src/main.rs
q4=b
q5=a
q6=format_hex
q7=b
q8=b
```

5. Verify with `lab check rust L6.6`.
