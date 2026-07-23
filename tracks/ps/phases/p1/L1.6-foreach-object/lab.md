## BRIEF
`ForEach-Object` (alias `foreach` or `%`) executes a script block once for every incoming object in the pipeline.
While `Where-Object` filters items (keeping or dropping them), `ForEach-Object` transforms or executes actions on each item (performing calculations, invoking methods, or reading properties).
Inside the script block, `$_` (or its long alias `$PSItem`) refers to the current item.

## GUIDED STEPS

1. **Examine `squares.ps1` and `lengths.ps1`**:
   View `squares.ps1` and `lengths.ps1` and run them:
   ```bash
   pwsh -File squares.ps1
   pwsh -File lengths.ps1
   ```
   Notice that `ForEach-Object { $_ * $_ }` transforms `1..3` into `1`, `4`, `9`, while `ForEach-Object { $_.Length }` calculates string lengths (`1`, `2`, `3`).

2. **Record your predictions**:
   Create `predictions.txt` recording the transformed square numbers and string length outputs:
   ```text
   squares=1 4 9
   lengths=1 2 3
   ```

3. **Check your work**:
   ```bash
   lab check ps L1.6
   ```
