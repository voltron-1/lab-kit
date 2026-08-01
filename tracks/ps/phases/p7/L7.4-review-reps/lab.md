## BRIEF
The L7.3 checklist is only useful if you can run it fast, on real scripts, and catch what matters first. Three AI-generated scripts, three distinct primary flaws, secondaries riding along in each — this is the review-reps drill.
Apply the checklist to `ai-1.ps1`, `ai-2.ps1`, `ai-3.ps1` and record the primary flaw per script in `review.md`.

## GUIDED STEPS

1. **Read all three shipped scripts**:
   ```bash
   cat ai-1.ps1 ai-2.ps1 ai-3.ps1
   ```
   One primary flaw each, plus secondaries:
   ```text
   ai-1.ps1  primary: a bare eval call piping a remote fetch straight into execution -- a
             download cradle, the same shape as L4.1/L5.1.
             secondary: no logging -- nothing records that the update ran.
   ai-2.ps1  primary: a hardcoded plaintext credential (-AsPlainText -Force) -- the same
             theater-not-security flaw as L4.7.
             secondary: no error handling -- Invoke-Command has no try/catch around it.
   ai-3.ps1  primary: $name flows straight into a file path with no validation -- an
             attacker-controlled value like '..\..\..\important.txt' escapes the logs
             directory entirely.
             secondary: no [CmdletBinding()] -- $name isn't even typed.
   ```

2. **Read why the reps matter** (static reference):
   ```text
   The checklist catches these consistently BECAUSE each item is a concrete, greppable check --
   not because you're smarter on rep three than rep one. Finding every flaw fast, on real
   scripts, IS the lead-analyst review skill L7.1-L7.3 built toward.
   ```

3. **Record your review**:
   Create `review.md`:
   ```text
   ai-1.ps1: primary flaw is a bare eval call (iex) piping a remote fetch straight into
   execution -- a download cradle. Secondary: no logging records that the update ran.
   ai-2.ps1: primary flaw is a hardcoded plaintext credential (-AsPlainText -Force) -- the
   SecureString wrapper protects nothing since the plaintext sits right in source. Secondary:
   no try/catch around Invoke-Command.
   ai-3.ps1: primary flaw is an unvalidated $name parameter used directly in a file path --
   injection/path traversal. Secondary: no [CmdletBinding()], so $name isn't even typed.
   ```

4. **Check your work**:
   ```bash
   lab check ps L7.4
   ```
