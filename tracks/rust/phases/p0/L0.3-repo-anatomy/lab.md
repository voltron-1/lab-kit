## BRIEF
When auditing or reading an unfamiliar Rust repository, two fundamental questions arise immediately:
1. What does this crate do, and what external dependencies does it pull in?
2. Where is the main execution entry point?

Rust projects enforce a clear structural layout:
- `Cargo.toml`: Package manifest declaring crate metadata (`[package]`) and third-party dependencies (`[dependencies]`).
- `src/main.rs`: Default entry point for binary executable crates.
- `src/lib.rs`: Entry point for library crates (which binary crates can also expose/consume).
- `cargo doc`: Standard documentation tool generating HTML reference pages (which `docs.rs` hosts for published crates).

In this Phase 0 Gate lab, you explore the `scanport/` project structure and answer 6 structural questions.

## GUIDED STEPS

1. **Inspect the project directory layout**:
   Explore the `scanport` directory tree:
   ```bash
   ls -R scanport
   ```

2. **Audit Cargo.toml**:
   Inspect `scanport/Cargo.toml` to identify package name, description, edition, and dependencies:
   ```bash
   cat scanport/Cargo.toml
   ```

3. **Examine source files**:
   Inspect `scanport/src/main.rs` and `scanport/src/lib.rs`. Note how `main.rs` imports functions from the library crate via `use scanport::parse_port`.

4. **Run the project with sample arguments**:
   Execute `scanport` passing ports `22` and `99999`, saving output to `run_out.txt`:
   ```bash
   cd scanport && cargo run -- 22 99999 > ../run_out.txt && cd ..
   ```
   Inspect `run_out.txt` to confirm outputs (`22 -> ok (port 22)`, `99999 -> INVALID`).

5. **Generate documentation locally**:
   Build offline HTML documentation for `scanport`:
   ```bash
   cd scanport && cargo doc --no-deps && cd ..
   ```
   Verify documentation output was created at `scanport/target/doc/scanport/index.html`.

6. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each field (`q1` through `q6`):
   - `q1`: Crate name (`scanport`)
   - `q2`: Binary entry point path (`src/main.rs`)
   - `q3`: Library source file path (`src/lib.rs`)
   - `q4`: Third-party dependency count (`0`)
   - `q5`: Project function option (`b`)
   - `q6`: Definition of `docs.rs` (`a`)

7. **Verify your work**:
   ```bash
   lab check rust L0.3
   ```
