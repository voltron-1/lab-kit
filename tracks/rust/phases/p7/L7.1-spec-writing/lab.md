## BRIEF
Welcome to Phase 7: the capstone phase! You learn to **write specs** for safe Rust, **audit AI output** with a checklist, and **direct AI code generation**.

A safe-Rust spec constrains **failure behavior**, not just the happy path.

## GUIDED STEPS

1. Read `files/task.md`.
2. Determine which candidate constraints (a–h) are essential for safe Rust.
3. Create `answers.txt` specifying the essential sorted letter set:
   ```text
   essential=a,c,d,f
   ```
4. Create `spec.md` writing the specification in prose. Your spec MUST address:
   - Returning a `Result` or `Option`
   - Validating range `1..=65535`
   - Never calling `panic` or `unwrap` on input
5. Verify with `lab check rust L7.1`.
