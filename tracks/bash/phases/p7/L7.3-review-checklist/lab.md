## BRIEF
ShellCheck is a syntax linter, not a trust judge.
To catch what static linters miss, you need **The AI-Bash Review Checklist v1**:
- **Blocking items** (`c1` through `c6`): Critical security and failure controls (strict mode, quoting, input validation, no `eval`, `cd` guards, `mktemp`).
- **Advisory items** (`c7`): Traps and cleanup.
- **Mechanical item** (`c8`): `shellcheck -x -S style` sweep.

> [!IMPORTANT]
> `c8-shellcheck` is placed **last**. Leading a human review with linter findings creates **anchoring bias**, blinding reviewers to logic flaws that linters miss.

In this lab, you build `checklist.md` with all 8 item tokens and answer the review questions in `answers.txt`.

## GUIDED STEPS

1. **Create `checklist.md`**:
   Write `checklist.md` containing all 8 checklist item lines, each starting with its ID token:
   - `c1-strictmode` — Does line 1-3 set errexit, nounset, and pipefail?
   - `c2-quoting` — Is every expansion quoted unless splitting is explicitly wanted?
   - `c3-input` — Is every argument and env var validated before use?
   - `c4-noeval` — Is any string re-parsed as code by a shell builtin?
   - `c5-cdguard` — Does every cd have a failure guard, or is the script path-absolute?
   - `c6-tempfiles` — Are temp files created with mktemp, never a predictable path?
   - `c7-cleanup` — Is there a trap that cleans up on every exit path?
   - `c8-shellcheck` — Does shellcheck -x -S style emit zero findings?

2. **Record your answers in `answers.txt`**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set:
   - `firstcheck=c1-strictmode` (first check a human reviewer applies)
   - `lastcheck=c8-shellcheck` (mechanical check belonging in CI)
   - `invisible=c4-noeval` (ShellCheck cannot prove if `eval` argument is untrusted)
   - `advisory=c7-cleanup` (advisory item)
   - `anchoring=anchoring` (leading with lint output causes anchoring bias)

3. **Verify your work**:
   ```bash
   lab check bash L7.3
   ```
