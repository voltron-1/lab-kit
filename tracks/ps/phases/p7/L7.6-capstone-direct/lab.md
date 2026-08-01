## BRIEF
The capstone: **direct** AI to build a real SOC deliverable — an IR triage / log-collection script — using the L7.2 spec, then **audit** the output against the L7.3 checklist and harden it. This is the whole track in one artifact.
Write `spec.md` (the direction you gave) and `hardened.ps1` (the audited, hardened result).

## GUIDED STEPS

1. **Write the direction** (static reference — this is what you'd hand an AI):
   ```text
   Direct: "Write a PowerShell IR triage script that collects running processes to a CSV,
   under the safe-PS spec from L7.2 -- CmdletBinding with a validated OutputPath parameter,
   logging on via a transcript, try/catch/finally around the collection, no bare eval-style
   calls, no hardcoded credentials."
   ```

2. **Audit and harden the output** (static reference — the graded shape):
   ```powershell
   [CmdletBinding()]
   param(
       [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$OutputPath
   )
   Start-Transcript -Path (Join-Path $OutputPath 'triage.log')      # logging ON
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
   # [CmdletBinding()] + validated param, try/catch/finally, logging ON, NO bare code-execution call
   ```
   (A Windows overlay could add `Get-WinEvent`/`Get-CimInstance` sections here -- noted, not
   graded, since the graded properties are cross-platform structure.)

3. **Write your files**:
   Create `spec.md` with the direction from step 1.
   Create `hardened.ps1` with the audited script from step 2.

4. **Check your work**:
   ```bash
   lab check ps L7.6
   ```
