## BRIEF
PowerShell functions can be decorated with `[CmdletBinding()]` and parameter attributes such as `[Parameter(Mandatory)]`, `[Parameter(ValueFromPipeline)]`, and `[ValidateSet()]`.
Adding `[CmdletBinding()]` promotes a function to an **advanced function**, granting common parameters (`-Verbose`, `-ErrorAction`, `-WarningAction`, `-OutVariable`) and the `$PSCmdlet` automatic variable.
During code triage and security analysis, remember that parameter scaffolding is a **legitimacy costume** — malicious scripts frequently adopt clean advanced function decorators to mimic legitimate administrative tools.

## GUIDED STEPS

1. **Examine `tool.ps1` and run `probe.ps1`**:
   View `tool.ps1` and run `probe.ps1`:
   ```bash
   cat tool.ps1
   pwsh -File probe.ps1
   ```
   Notice that `probe.ps1` dot-sources `tool.ps1` and returns `True`, proving that `[CmdletBinding()]` added common parameters like `-Verbose` to `Get-SuspiciousProcess`.

2. **Analyze parameter decorators**:
   Examine `tool.ps1` to observe:
   - `$Name` is marked `[Parameter(Mandatory)]` (required parameter)
   - `$MinWorkingSetMB` uses `[Parameter(ValueFromPipeline)]`
   - `$OnFound` restricts arguments with `[ValidateSet('Stop','Continue','Ignore')]`

3. **Record your answers**:
   Create `answers.txt` naming the parameter `tool.ps1` marks mandatory, and stating
   what `[CmdletBinding()]` adds to a function.

4. **Check your work**:
   ```bash
   lab check ps L2.4
   ```
