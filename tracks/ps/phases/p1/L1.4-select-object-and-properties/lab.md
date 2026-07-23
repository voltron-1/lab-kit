## BRIEF
`Select-Object` selects specified properties from object streams or unwraps property values.
Selecting properties (`Select-Object Name, Id`) projects a new `PSCustomObject` containing only those properties.
In contrast, `-ExpandProperty` unwraps the raw underlying value (e.g. `Int32` or `String`). Calculated properties (`@{Name='X';Expression={...}}`) allow adding computed columns.

## GUIDED STEPS

1. **Test `-ExpandProperty` vs property selection**:
   Run `expand.ps1` and `itype.ps1` to see how `-ExpandProperty Id` unwraps a process ID to a bare `Int32`:
   ```bash
   pwsh -File expand.ps1
   pwsh -File itype.ps1
   ```

2. **Inspect selection object type**:
   Run `seltype.ps1` to observe that property projection emits a `PSCustomObject`:
   ```bash
   pwsh -File seltype.ps1
   ```

3. **Inspect calculated property output**:
   Run `calc.ps1` to see a computed column (`MB` calculated from working set bytes):
   ```bash
   pwsh -File calc.ps1
   ```

4. **Record your predictions**:
   Create `predictions.txt` with three lines recording your type predictions:
   ```text
   expand_type=Int32
   select_type=PSCustomObject
   calc_column=MB
   ```

5. **Check your work**:
   ```bash
   lab check ps L1.4
   ```
