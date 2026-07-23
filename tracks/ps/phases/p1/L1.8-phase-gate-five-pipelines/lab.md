## BRIEF
This is the Phase 1 Exit Gate (`gate: true`).
PowerShell pipelines process live .NET objects: `objects in -> filter/project/transform -> objects out`.
In this lab, you analyze five representative pipelines and record your predictions for input types, operations, and outputs.

## GUIDED STEPS

1. **Test deterministic probe scripts**:
   Run `p2.ps1` and `p4.ps1` to observe pipeline transformations:
   ```bash
   pwsh -File p2.ps1
   pwsh -File p4.ps1
   ```
   Notice `p2.ps1` transforms `1..5` by `* 10` to produce `10`, `20`, `30`, `40`, `50`, while `p4.ps1` converts string elements to uppercase (`CHROME`, `PWSH`, `SSHD`).

2. **Analyze input object types**:
   Observe that `Get-Process | Where-Object { $_.WS -gt 100MB } | Select-Object Name, Id` operates on `System.Diagnostics.Process` input objects, where `Name` is a `String` and `Id` is an `Int32`.

3. **Record your predictions**:
   Create `answers.md` containing your pipeline analysis and predictions:
   ```markdown
   # Phase 1 Pipeline Analysis
   - Pipeline 1 Input Type: System.Diagnostics.Process
   - Pipeline 2 Output: 10 20 30 40 50
   - Pipeline 4 Output: CHROME PWSH SSHD
   ```

4. **Check your work**:
   ```bash
   lab check ps L1.8
   ```
