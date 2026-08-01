## BRIEF
The L7.3 checklist's last item is PSScriptAnalyzer — the **automated backstop**. This lab wires it as a **merge gate**: run it, capture the output, then draft the CI step that blocks anything it flags. PSSA is the PowerShell ShellCheck (installed back in L0.1) — same posture as bash's L7.5.

## GUIDED STEPS

1. **Run PSScriptAnalyzer on the shipped sample, for real**:
   ```powershell
   Invoke-ScriptAnalyzer -Path ./candidate.ps1 | Select-Object RuleName, Severity, Line, Message > pssa.txt
   cat pssa.txt
   ```
   Real output on this machine (pwsh 7.6.4, PSScriptAnalyzer 1.25.0), captured against the
   shipped `candidate.ps1` (the two-line file header pushes the flagged line to 4):
   ```text
   RuleName                  Severity Line Message
   --------                  -------- ---- -------
   PSAvoidUsingCmdletAliases  Warning    4 'gci' is an alias of 'Get-ChildItem'. Alias can
                                           introduce possible problems and make scripts hard
                                           to maintain. Please consider changing alias to its
                                           full content.
   ```
   (If PSScriptAnalyzer isn't installed: `Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force`, needs PSGallery egress. No egress? `Save-Module -Name PSScriptAnalyzer -Path <dir>` on a machine that has it, then `Import-Module <dir>/PSScriptAnalyzer` — the offline fallback from L0.1.)

2. **Read why this check.sh never re-runs PSSA itself** (static reference):
   ```text
   check.sh runs under a fenced HOME redirect (env -i) so shipped probes can't leak state --
   but a live Invoke-ScriptAnalyzer under that redirect sees an empty module path and silently
   finds nothing, which would report a flawed script as clean. So PSSA is graded from the FILE
   you produce, never re-run live. This is the same reason bash's L7.5 grades a captured
   shellcheck run, not a live one.
   ```

3. **Draft the CI gate**:
   Create `ci-step.yml`:
   ```yaml
   # ci-step.yml -- PSScriptAnalyzer as a merge gate
   - name: PSScriptAnalyzer
     run: |
       $results = Invoke-ScriptAnalyzer -Path . -Recurse
       $results | Format-Table -AutoSize
       if ($results | Where-Object { $_.Severity -in 'Error', 'Warning' }) {
         Write-Error "PSScriptAnalyzer found Error/Warning findings -- failing the build"
         exit 1
       }
   ```

4. **Name the cross-track equivalent**:
   Create `notes.md`:
   ```text
   PSScriptAnalyzer is the PowerShell equivalent of ShellCheck: a static analyzer wired as a
   merge gate. Both fail the build on any Error/Warning finding, blocking non-conforming code
   from landing -- the automated backstop behind the human checklist.
   ```

5. **Check your work**:
   ```bash
   lab check ps L7.5
   ```
