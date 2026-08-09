## BRIEF
Automated CI guardrails protect codebases from AI-generated regressions:
- `cargo clippy -- -W clippy::pedantic -D warnings`
- `cargo audit`
- `cargo deny check`
- `cargo test`

## GUIDED STEPS

1. Create `guardrails.sh` in your workspace with the four gate commands:
   ```bash
   cargo clippy -- -W clippy::pedantic -D warnings
   cargo audit
   cargo deny check
   cargo test
   ```
2. Create `answers.txt`:
   ```text
   g1=b
   g2=b
   g3=a
   g4=b
   g5=b
   ```
3. Verify with `lab check rust L7.4`.
