## BRIEF
`Get-Member` (alias `gm`) is your primary tool for inspecting unknown objects in PowerShell pipelines.
Piping any object to `Get-Member` displays its `.NET TypeName` on the first line, followed by its properties, methods, alias properties, and script properties.
In this lab, you use `Get-Member` to decode `Get-Process` and `Get-Date` object structures.

## GUIDED STEPS

1. **Inspect `Get-Process` members**:
   Pipe `Get-Process` to `Get-Member` and export the full output to `members.txt`:
   ```bash
   pwsh -Command "Get-Process pwsh | Get-Member | Out-String > members.txt"
   ```
   Inspect `members.txt` to see the `TypeName: System.Diagnostics.Process`, as well as `Property`, `Method`, `AliasProperty`, and `ScriptProperty` entries.

2. **Inspect `Get-Date` members**:
   Pipe `Get-Date` to `Get-Member` and export the full output to `decode.txt`:
   ```bash
   pwsh -Command "(Get-Date) | Get-Member | Out-String > decode.txt"
   ```
   Inspect `decode.txt` to see `TypeName: System.DateTime`.

3. **Check your work**:
   ```bash
   lab check ps L1.3
   ```
