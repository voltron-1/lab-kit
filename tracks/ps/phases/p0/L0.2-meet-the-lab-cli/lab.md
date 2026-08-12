## BRIEF
The `lab` CLI drives every track in LAB-KIT (`lab start`, `lab check`, `lab hint`, `lab resume`).
`lab start` refuses to start a lab past the frontier (the next not-yet-passed lab in the track) unless you pass `--force` — which marks every lab it skips over with a permanent `⏭`, a mark that can never later become `✓`.
All work for the `ps` track happens inside `workspace/ps/<id>/`.
In this lab, you fix a variable typo in `broken.ps1`, run your script with `pwsh -File`, and verify your workspace path.

## GUIDED STEPS

1. **Examine `broken.ps1`**:
   View `broken.ps1` and run it:
   ```bash
   cat broken.ps1
   pwsh -File broken.ps1
   ```
   Notice that `$naem` is unassigned, so PowerShell evaluates it as `$null` (printing `Hello, ` with no error).

2. **Fix the script in `fixed.ps1`**:
   Copy `broken.ps1` to `fixed.ps1` and edit it to assign `$name = "analyst"` and output `"Hello, $name"`:
   ```powershell
   $name = "analyst"
   Write-Output "Hello, $name"
   ```

3. **Run your fixed script**:
   ```bash
   pwsh -File fixed.ps1
   ```
   *(Expected output: `Hello, analyst`)*

4. **Record your workspace path**:
   ```bash
   pwd > location.txt
   ```

5. **Check your work**:
   ```bash
   lab check ps L0.2
   ```
