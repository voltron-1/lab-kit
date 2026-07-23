## BRIEF
PowerShell pipelines pass **live .NET objects**, not plain text strings.
The text displayed on your screen is merely a default representation produced by PowerShell's formatting engine.
Filtering with `Where-Object` operates on object properties, whereas piping to `grep` filters string lines from screen text.

## GUIDED STEPS

1. **Compare object filtering vs text filtering**:
   Run both pipeline variations to see the difference:
   ```bash
   pwsh -Command "Get-Process | Where-Object { \$_.ProcessName -eq 'pwsh' }"
   pwsh -Command "Get-Process | grep pwsh"
   ```
   `Where-Object` filters live `[System.Diagnostics.Process]` objects by property, while `grep` filters string lines from the formatted text output.

2. **Inspect the underlying .NET type**:
   Run the type probe script:
   ```bash
   pwsh -File type.ps1
   ```
   *(Expected output: `System.Diagnostics.Process`)*

3. **Record your prediction**:
   Write the exact .NET type emitted by `Get-Process` into `prediction.txt`:
   ```text
   System.Diagnostics.Process
   ```

4. **Check your work**:
   ```bash
   lab check ps L1.2
   ```
