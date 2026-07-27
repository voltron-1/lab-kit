## BRIEF
This is the **Bash Track Capstone Gate**.
Your deliverable is `hardened.sh` — a production-ready, hardened log-ingest helper that rewrites L7.6's flawed script.

### Acceptance Criteria for `hardened.sh`:
1. **Usage contract**: `./hardened.sh <input.ndjson>` takes exactly 1 argument (exit 2 on wrong count; exit 1 if file unreadable). Refuses any filter parameter.
2. **Transform**: For each valid line in `<input.ndjson>`, emit compact ECS JSON on stdout (`{"@timestamp": .ts, "source.ip": .src, "event.action": .action}`).
3. **Malformed Handling**: Skip malformed/non-JSON lines gracefully.
4. **Summary Output**: Print summary `valid=N skipped=M` to **stderr** (never polluting stdout).
5. **Exit Code**: Exit 0 if `valid > 0`; exit 1 (nonzero) if `valid == 0`.
6. **Linter Gate**: Pass `shellcheck -x -S style hardened.sh` with zero findings.

In this lab, you write `hardened.sh`, populate `answers.txt`, and pass all automated tests and quiz questions.

## GUIDED STEPS

1. **Write `hardened.sh`**:
   Write `hardened.sh` adhering to all 6 acceptance criteria above:
   - Use `set -euo pipefail`
   - Validate `$# -eq 1` (exit 2) and `[[ -r "$1" ]]` (exit 1)
   - Read lines with `while IFS= read -r line; do ... done < "$INPUT"` (redirect keep counters in current shell)
   - Use `jq` over `<<<"$line"` (here-string) to extract and format valid records safely
   - Print summary `valid=$valid skipped=$skipped` to `stderr` (`>&2`)
   - Exit 0 if `valid > 0`, else exit 1

2. **Test your script locally**:
   Make executable and run against fixtures:
   ```bash
   chmod +x hardened.sh
   ./hardened.sh sample.ndjson
   ./hardened.sh allbad.ndjson
   shellcheck -x -S style hardened.sh
   ```

3. **Record your answers in `answers.txt`**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set:
   - `loopform=redirect`
   - `notemp=herestring`
   - `streams=stderr`
   - `noinject=removing-the-filter`
   - `exitnone=nonzero`

4. **Verify your work**:
   ```bash
   lab check bash L7.7
   ```
