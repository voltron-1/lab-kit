## BRIEF
Welcome to the PowerShell Literacy Lab!
Unlike Linux text pipelines that pass lines of strings, PowerShell pipelines pass **rich .NET objects**.
In this lab, you verify your PowerShell 7 (`pwsh`) installation on WSL2, inspect `$PSVersionTable`, run your first cmdlet, and set up `PSScriptAnalyzer` — the PowerShell equivalent of ShellCheck.

## GUIDED STEPS

1. **Verify PowerShell installation and version**:
   Ensure `pwsh` (PowerShell 7) is installed via the official apt repository:
   ```bash
   pwsh --version
   ```
   *(Expected output: `PowerShell 7.x.y`)*

2. **Inspect `$PSVersionTable`**:
   Launch `pwsh` or run a single command to record version metadata to `psversion.txt`:
   ```bash
   pwsh -Command '"{0} {1} {2}" -f $PSVersionTable.PSVersion, $PSVersionTable.PSEdition, $PSVersionTable.Platform' > psversion.txt
   ```
   Inspect `psversion.txt` (it will report `Core` edition and `Unix` platform).

3. **Install and verify PSScriptAnalyzer**:
   Run PowerShell to trust PSGallery, install PSScriptAnalyzer, and record module presence in `pssa.txt`:
   ```bash
   pwsh -Command 'Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force; Get-Module -ListAvailable PSScriptAnalyzer | Select-Object -ExpandProperty Name > pssa.txt'
   ```

4. **Run PSScriptAnalyzer on a flawed sample**:
   Analyze a script with cmdlet aliases and save rule findings to `findings.txt`:
   ```bash
   pwsh -Command "'gci | ForEach-Object { \$_ }' | Set-Content sample.ps1; Invoke-ScriptAnalyzer -Path sample.ps1 | Select-Object -ExpandProperty RuleName > findings.txt"
   ```

5. **Check your work**:
   ```bash
   lab check ps L0.1
   ```
