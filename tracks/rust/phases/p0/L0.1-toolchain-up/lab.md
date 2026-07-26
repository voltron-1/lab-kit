## BRIEF
This track trains reading, not writing — but a reader who cannot build cannot verify.
Today is pure plumbing:
- `rustup`: The toolchain installer and version manager.
- `cargo`: The standard Rust build tool, package manager, and test runner.
- Your first throwaway binary crate.

Every later lab assumes `cargo` and `rustc` work in this WSL2 environment.

## GUIDED STEPS

1. **Verify your Rust toolchain**:
   Check if `cargo` is present:
   ```bash
   command -v cargo
   ```
   If `cargo` is missing, install the official toolchain via `rustup`:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
   source "$HOME/.cargo/env"
   ```

2. **Record your toolchain versions**:
   Write `rustc` and `cargo` versions to `toolchain.txt`:
   ```bash
   rustc --version > toolchain.txt
   cargo --version >> toolchain.txt
   ```
   Verify `toolchain.txt` contains lines resembling `rustc 1.8x.y (...)` and `cargo 1.8x.y (...)`.

3. **Initialize a new binary project**:
   Create a new Cargo crate named `hello_lab`:
   ```bash
   cargo new hello_lab
   ```
   Inspect the generated directory structure (`hello_lab/Cargo.toml`, `hello_lab/src/main.rs`).

4. **Build and execute via Cargo**:
   Change into `hello_lab` and run `cargo run`, redirecting stdout to `../first_run.txt`:
   ```bash
   cd hello_lab && cargo run > ../first_run.txt && cd ..
   ```
   Note that compiler status messages are emitted to stderr, while program output (`Hello, world!`) is written to `first_run.txt`.

5. **Locate and test the compiled binary**:
   Verify the binary artifact exists at `hello_lab/target/debug/hello_lab` and run it directly:
   ```bash
   ./hello_lab/target/debug/hello_lab
   ```

6. **Verify your progress**:
   ```bash
   lab check rust L0.1
   ```
