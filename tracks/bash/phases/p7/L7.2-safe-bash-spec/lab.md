## BRIEF
Prompting an AI with "write a safe script" produces insecure code by default.
To force an AI to generate hardened Bash, you must provide a **Safe-Bash Spec** with non-negotiable requirements:
1. Strict mode preamble (`set -euo pipefail`)
2. Explicit variable double-quoting
3. Strict input validation
4. Absolute bans on `eval` constructs
5. Fail-loud error handling
6. Mechanical acceptance criteria (`shellcheck-clean`)

In this lab, you author `spec.md` from `spec-skeleton.md`, append fixed commitment tags to each section, and answer the audit questions in `answers.txt`.

## GUIDED STEPS

1. **Create `spec.md` from `spec-skeleton.md`**:
   Copy `spec-skeleton.md` to `spec.md`:
   ```bash
   cp spec-skeleton.md spec.md
   ```

2. **Complete each section in `spec.md` and add commitment tags**:
   Fill in each section of `spec.md`. At the bottom of each section (1 through 6), append the exact required commitment line:
   - In Section 1: `preamble=set -euo pipefail`
   - In Section 2: `quoting=always`
   - In Section 3: `validation=reject-unset`
   - In Section 4: `forbidden=evalstring`
   - In Section 5: `errors=fail-loud`
   - In Section 6: `acceptance=shellcheck-clean`

3. **Answer the spec rationale in `answers.txt`**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set:
   - `whystrict=silentsuccess` (without strict mode, failing steps exit 0 silently)
   - `whyaccept=mechanical` (acceptance criteria turns review into a mechanical check)
   - `whyban=code` (eval string re-parses arbitrary string data as executable code)

4. **Verify your work**:
   ```bash
   lab check bash L7.2
   ```
