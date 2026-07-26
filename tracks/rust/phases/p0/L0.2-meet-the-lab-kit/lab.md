## BRIEF
The lab kit provides an interactive environment to guide your learning through automated checks, quizzes, and hints.
Key principles:
- **Zero penalty**: A failed check or wrong quiz answer costs nothing; fix your work and re-run `lab check`.
- **Exact keys**: Answer files in this track use strict `key=value` lines without extra whitespace.
- **Fence discipline**: Commands must be executed within the active workspace directory.

In this lab, you practice interacting with the lab kit tools and submit your first answer file.

## GUIDED STEPS

1. **Check track status**:
   Run `lab status` to view your track progress and find the active `▶` marker for this lab.

2. **Read the kit operating notes**:
   Inspect `kit-notes.txt`:
   ```bash
   cat kit-notes.txt
   ```

3. **Try the hint ladder**:
   Request a Level 1 hint for this lab:
   ```bash
   lab hint rust L0.2
   ```

4. **Create your answer file**:
   Create `answers.txt` in your workspace directory with 3 lines:
   - `q1`: Command to run after a month away from the kit (`a` = lab status, `b` = lab resume, `c` = lab hint) → `q1=b`
   - `q2`: Number of hint levels per lab → `q2=3`
   - `q3`: What happens when a quiz score is 2/3? (`a` = partial credit saved, `b` = whole check failed; fix and re-run `lab check`, `c` = lab resets) → `q3=b`

5. **Prove workspace fence location**:
   Record your current working directory in `location.txt`:
   ```bash
   pwd > location.txt
   ```

6. **Verify your work**:
   ```bash
   lab check rust L0.2
   ```
