## BRIEF
PowerShell supports four primary loop constructs: `for`, `foreach` (statement), `while`, and `do-while` / `do-until`.
Unlike `while`, a `do-while` loop evaluates its condition **after** the first iteration and always executes at least once even if the condition is false.
Additionally, the `foreach` **statement** (`foreach ($n in $items) { ... }`) operates on an in-memory collection without using pipeline streams or `$_`, whereas the `ForEach-Object` **cmdlet** (`... | ForEach-Object { ... }`) processes pipeline input dynamically.

## GUIDED STEPS

1. **Examine `forloop.ps1` and `foreachstmt.ps1`**:
   Run `forloop.ps1` and `foreachstmt.ps1`:
   ```bash
   pwsh -File forloop.ps1
   pwsh -File foreachstmt.ps1
   ```
   Notice `forloop.ps1` outputs `1`, `2`, `3`, while `foreachstmt.ps1` transforms `2, 4, 6` into `3`, `5`, `7`.

2. **Examine `dowhile.ps1`**:
   Run `dowhile.ps1`:
   ```bash
   pwsh -File dowhile.ps1
   ```
   Notice `dowhile.ps1` outputs `5` once, demonstrating that `do-while` executes its loop body before evaluating `$i -lt 3`.

3. **Record your predictions**:
   Create `prediction.txt` recording your predictions for loop behavior:
   ```text
   forloop=1 2 3
   foreachstmt=3 5 7
   dowhile=5
   ```

4. **Check your work**:
   ```bash
   lab check ps L2.3
   ```
