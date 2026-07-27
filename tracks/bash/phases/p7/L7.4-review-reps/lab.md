## BRIEF
Practice makes perfect. In this lab, you audit three AI-generated scripts using the L7.3 review checklist:
- `gen1-cleanup.sh`: Contains an uninitialized variable (`$OLD_DIR`) that expands to `rm -rf /*.gz`.
- `gen2-fetch-deploy.sh`: Emits **zero ShellCheck findings**, yet lacks `curl --fail`, checksum validation, and `mktemp` paths.
- `gen3-report.sh`: Triggers `SC2045` (severity ERROR: iterating over `ls`), breaking on filenames with spaces.

In this lab, you audit all 3 scripts, run ShellCheck, and record your 12 answers in `answers.txt`.

## GUIDED STEPS

1. **Inspect all 3 generated scripts**:
   Inspect `gen1-cleanup.sh`, `gen2-fetch-deploy.sh`, and `gen3-report.sh`.

2. **Run ShellCheck across all 3 scripts**:
   ```bash
   shellcheck -x -S style gen1-cleanup.sh gen2-fetch-deploy.sh gen3-report.sh
   ```
   Notice that `gen2-fetch-deploy.sh` outputs **0 findings**, proving static analysis is necessary but insufficient.

3. **Record your review findings**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set:
   - `s1_worst=unsetvar` (`OLD_DIR` is uninitialized)
   - `s1_savedby=nounset` (`set -u` halts on unset variable)
   - `s2_findings=0` (`gen2-fetch-deploy.sh` emits 0 SC findings)
   - `s2_fetch=nofail` (`curl -s` lacks `--fail`)
   - `s2_integrity=checksum` (no checksum or signature check)
   - `s2_temppath=predictable` (`/tmp/agent.tar.gz` is a fixed, predictable path)
   - `s2_model=l6.5` (`L6.5` demonstrated the safe download/validate/atomic deploy pattern)
   - `s3_severity=sc2045` (`SC2045` is severity ERROR)
   - `s3_breaks=spaces` (filenames with spaces break `for f in $(ls $DIR)`)
   - `s3_useless=cat` (useless `cat` in `cat file | grep ...`)
   - `cleanest=gen2` (`gen2` is reported clean by ShellCheck)
   - `lesson=floor` (ShellCheck-clean is the quality floor, not the security ceiling)

4. **Verify your work**:
   ```bash
   lab check bash L7.4
   ```
