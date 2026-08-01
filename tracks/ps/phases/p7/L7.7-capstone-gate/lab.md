## BRIEF
The **capstone gate** -- the last lab of the PowerShell track. Ship `hardened.ps1` (the audited script from L7.6), run PSScriptAnalyzer on it for real, and self-audit it against the L7.3 checklist. This is the proof that directing AI and auditing its output actually produces something safe to run.

## GUIDED STEPS

1. **Bring `hardened.ps1` forward** (this workspace starts fresh -- if your L7.6 workspace is still on disk, copy it: `cp ../L7.6/hardened.ps1 .`; otherwise rewrite the audited result):
   ```powershell
   [CmdletBinding()]
   param(
       [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$OutputPath
   )
   Start-Transcript -Path (Join-Path $OutputPath 'triage.log')
   try {
       Get-Process | Select-Object Name, Id, Path |
           Export-Csv (Join-Path $OutputPath 'proc.csv') -NoTypeInformation -ErrorAction Stop
   }
   catch {
       Write-Error "collection failed: $($_.Exception.Message)"
   }
   finally {
       Stop-Transcript
   }
   ```

2. **Show PSSA actually ran, then run it for real and capture the output**:
   ```powershell
   Get-Module -ListAvailable PSScriptAnalyzer | Select-Object Name, Version > pssa-version.txt
   Invoke-ScriptAnalyzer -Path ./hardened.ps1 | Select-Object RuleName, Severity > pssa-clean.txt
   ```
   A genuinely clean script produces a **0-byte file** for `pssa-clean.txt` -- no header, no rows. If yours isn't empty, PSSA found something; fix `hardened.ps1` and re-run. `pssa-version.txt` proves you actually ran PSSA and didn't just ship an empty file -- a 0-byte `pssa-clean.txt` on its own can't tell "clean" from "never ran."

3. **Self-audit against the L7.3 checklist** (static reference -- walk it item by item, and name the alias by name -- item 1 is graded, not optional):
   ```text
   1. No Invoke-Expression / iex anywhere?       -> yes, no bare Invoke-Expression / iex call
   2. [CmdletBinding()] + validated params?      -> yes, OutputPath is Mandatory + ValidateNotNullOrEmpty
   3. try/catch with -ErrorAction Stop?          -> yes, Export-Csv -ErrorAction Stop inside try/catch
   4. Logging on?                                -> yes, Start-Transcript / Stop-Transcript
   5. PSScriptAnalyzer clean?                    -> yes, pssa-clean.txt is empty
   ```
   Write it to `answers.md`.

4. **Check your work**:
   ```bash
   lab check ps L7.7
   ```
