## BRIEF
The direct-then-audit loop is a two-step rhythm:
1. **Direct**: Write a clear spec (`ingest-spec.md`) specifying input validation, `mktemp` usage, no user-filter execution, malformed line handling, and `shellcheck-clean`.
2. **Audit**: Review model output (`model-output.sh`) against the L7.3 checklist. Notice how static linters report 3 syntax findings, while missing the severe command injection vulnerability (`eval "jq '$FILTER' ..."`).

In this lab, you complete `ingest-spec.md` with 5 commitment tags and record your 6 audit answers in `answers.txt`.

## GUIDED STEPS

1. **Write your prompt specification (`ingest-spec.md`)**:
   Copy `spec-skeleton.md` to `ingest-spec.md`:
   ```bash
   cp spec-skeleton.md ingest-spec.md
   ```
   Fill in each section and include the required commitment tags:
   - `input=validate`
   - `temp=mktemp`
   - `filter=no-user-filter`
   - `malformed=skip-and-count`
   - `accept=shellcheck-clean`

2. **Inspect and audit `model-output.sh`**:
   Run ShellCheck on `model-output.sh`:
   ```bash
   shellcheck -x -S style model-output.sh
   ```
   Notice that ShellCheck flags syntax issues (`SC2086`, `SC2162`), but fails to catch the critical `eval` command injection vulnerability because the argument is quoted.

3. **Record your audit findings in `answers.txt`**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set:
   - `sc_count=3`
   - `realflaw=injection`
   - `whyquiet=quoted`
   - `tempflaw=predictable`
   - `appendbug=double`
   - `checklist=c4-noeval`

4. **Verify your work**:
   ```bash
   lab check bash L7.6
   ```
