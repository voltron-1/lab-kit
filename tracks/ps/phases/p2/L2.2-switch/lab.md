## BRIEF
PowerShell's `switch` statement has no implicit `break` — a single input value can match and execute **multiple** case blocks unless explicitly stopped with `break`.
In addition to exact string comparisons, `switch` supports `-Wildcard` matching (`*.exe`), `-Regex` pattern matching (`^\d+$`), and `-File` mode to stream and evaluate a text file line-by-line (`$_` = each line).

## GUIDED STEPS

1. **Test `switch` fall-through**:
   Run `fallthrough.ps1` to observe that multiple case blocks execute for a single input value:
   ```bash
   pwsh -File fallthrough.ps1
   ```
   Notice that `fallthrough.ps1` outputs both `DIGITS` and `HAS41` because PowerShell does not stop at the first matching case.

2. **Test `switch -File` log reading**:
   View `events.log` and run `scanlog.ps1`:
   ```bash
   cat events.log
   pwsh -File scanlog.ps1
   ```
   Notice that `switch -File events.log` reads each line as `$_` and outputs `HIT:2026-07-23 10:01:15 FAILED Login attempt for admin`.

3. **Explain fall-through behavior**:
   Create `notes.txt` explaining why `fallthrough.ps1` printed two lines instead of stopping after the first match:
   ```text
   PowerShell switch statements do not automatically break after a match and fall through to test subsequent cases unless break is used.
   ```

4. **Check your work**:
   ```bash
   lab check ps L2.2
   ```
