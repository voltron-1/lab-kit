## BRIEF
CI merge gates automate quality control:
- `shellcheck -x -S style` checks for shell security/style flaws.
- `shfmt -d` checks for formatting diffs without modifying files.
- Nonzero exit codes from CI scripts cause merge requests to fail fast (`set -euo pipefail`).

In this lab, you copy `gate.sh` and `scripts/`, test gate failure, fix `scripts/bad.sh`, format with `shfmt`, confirm `gate.sh` passes (`gate: clean`), and answer the rationale questions in `answers.txt`.

## GUIDED STEPS

1. **Set up your workspace**:
   Copy `gate.sh` and `scripts/` into your workspace directory:
   ```bash
   cp -r scripts .
   cp gate.sh .
   chmod +x gate.sh
   ```

2. **Run `gate.sh` and observe failure**:
   ```bash
   ./gate.sh
   ```
   Notice that `gate.sh` fails on `scripts/bad.sh` with `SC2086` (unquoted `$msg`).

3. **Fix `scripts/bad.sh` and format**:
   Edit `scripts/bad.sh` to quote `"$msg"` (`echo "$msg"`).
   Format all scripts:
   ```bash
   shfmt -w scripts/
   ```

4. **Run `gate.sh` to verify zero findings**:
   ```bash
   ./gate.sh
   ```
   Confirm output prints `gate: clean` and exits 0.

5. **See the production version**: `gate.sh` is a teaching stand-in — this
   repo's actual CI gate is `tools/shellcheck-all.sh`. Read it:
   ```bash
   cat ../../../tools/shellcheck-all.sh
   ```
   Its file-discovery line uses
   `git ls-files -z --cached --others --exclude-standard` instead of a
   plain glob like `gate.sh`'s: `--cached` lists tracked files,
   `--others --exclude-standard` adds untracked-but-not-gitignored ones.
   A plain `git ls-files` alone only sees files `git add`-ed at least
   once, so a brand-new script nobody staged yet would be silently
   skipped from the sweep — a false "0 warnings" clean bill.

6. **Record your answers in `answers.txt`**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set:
   - `gatefail=sc2086`
   - `whyexit=exitcode`
   - `fmtflag=-d`
   - `strictgate=failfast`
   - `sweeptrap=untracked`

7. **Verify your work**:
   ```bash
   lab check bash L7.5
   ```
