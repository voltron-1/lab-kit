## BRIEF
A spec tells AI what to produce. A **checklist** is what YOU run on every script it hands back — the lead-analyst artifact that makes review consistent and fast instead of ad hoc. Each item is a concrete, greppable check; the last one is the automated backstop to everything above it.
Write `checklist.md` with ≥6 items covering the L7.1 failure set.

## GUIDED STEPS

1. **Turn the spec into checks** (static reference):
   ```text
   1. No Invoke-Expression / iex anywhere?                         (grep)
   2. [CmdletBinding()] + validated, typed parameters?
   3. try/catch with -ErrorAction Stop on every risky call?
   4. Logging on (Write-Verbose / transcript / audit line)?
   5. No hardcoded creds / plaintext secrets / echoed $Env: secrets?
   6. Least privilege; no unnecessary admin / broad scope?
   7. External input validated/sanitized (no injection)?
   8. PSScriptAnalyzer clean (no warnings)?
   ```

2. **Read why item 8 matters** (static reference):
   ```text
   Items 1-7 are things a human reviewer greps or eyeballs. Item 8 is different: it's the
   AUTOMATED backstop -- a static analyzer that catches what a tired reviewer might miss.
   A checklist without an automated backstop degrades the moment review gets rushed; one WITH
   it stays consistent under time pressure.
   ```

3. **Write your checklist**:
   Create `checklist.md`:
   ```text
   # ai-ps-review-checklist v1
   1. No Invoke-Expression / iex anywhere?                         (grep)
   2. [CmdletBinding()] + validated, typed parameters?
   3. try/catch with -ErrorAction Stop on every risky call?
   4. Logging on (Write-Verbose / transcript / audit line)?
   5. No hardcoded creds / plaintext secrets / echoed $Env: secrets?
   6. Least privilege; no unnecessary admin / broad scope?
   7. External input validated/sanitized (no injection)?
   8. PSScriptAnalyzer clean (no warnings)?
   ```

4. **Check your work**:
   ```bash
   lab check ps L7.3
   ```
