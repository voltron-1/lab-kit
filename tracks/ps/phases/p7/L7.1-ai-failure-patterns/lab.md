## BRIEF
AI writes PowerShell badly by default: no error handling, no logging, weak or missing validation — and it loves bare `iex`. Phase 7 is the capstone: you learn to *direct* AI toward safe output and *audit* what it actually produces. This lab starts with the failure modes themselves.
Audit `ai-sample.ps1` and record ≥4 flaws in `findings.md`.

## GUIDED STEPS

1. **Read the shipped sample**:
   ```bash
   cat ai-sample.ps1
   ```
   Five flaws to find:
   ```text
   iex "Invoke-RestMethod ...$server..."   -> bare iex on interpolated input: evaluates arbitrary
                                               code AND is injectable through $server at once
   function Get-Stuff($server)             -> no [CmdletBinding()], no typed/validated parameter
   $pw = 'P@ssw0rd123'                     -> hardcoded plaintext credential, readable in source
   (no try/catch anywhere)                 -> no error handling
   (no Write-Verbose/transcript/log line)  -> no logging
   ```

2. **Read why this matters** (static reference):
   ```text
   iex on interpolated input is doubly dangerous: it both evaluates arbitrary code (PowerShell's
   eval) AND is injectable through whatever gets interpolated into the string -- an attacker who
   controls $server controls what runs.
   Treat AI-generated PowerShell as untrusted input to review, not trusted output to run. These
   five failure modes are AI's DEFAULT shape, not an unlucky one-off -- expect them every time
   until a spec (next lab) forces something better.
   ```

3. **Record your finding**:
   Create `findings.md`:
   ```text
   ai-sample.ps1 has five default AI-PS failures: a bare iex call on the interpolated $server
   parameter (eval + injection at once), no [CmdletBinding()] or parameter validation, a
   hardcoded plaintext credential ($pw), no error handling (no try/catch anywhere), and no
   logging (nothing records what the function did).
   The iex call is the highest-signal flaw: it both runs arbitrary code and is attacker-steerable
   through the same interpolated input.
   Treat AI-generated PowerShell as untrusted input to review -- not trusted code to run.
   ```

4. **Check your work**:
   ```bash
   lab check ps L7.1
   ```
