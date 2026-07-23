## BRIEF
This is the Phase 0 Exit Gate (`gate: true`).
PowerShell 5.1 (Windows PowerShell, `PSEdition=Desktop`) and PowerShell 7 (PowerShell, `PSEdition=Core`) have key architecture differences.
Execution Policy is documented by Microsoft as anti-accidental-run safety — **not a security boundary**.
In contrast, AMSI and Constrained Language Mode (CLM with WDAC/AppLocker) are real security controls.

## GUIDED STEPS

1. **Compare PS 5.1 vs PS 7**:
   Review the key edition differences:
   - **PS 5.1 (Windows PowerShell)**: `PSEdition=Desktop`, .NET Framework 4.x, Windows-only, default `Restricted` ExecutionPolicy on client OS.
   - **PS 7 (PowerShell)**: `PSEdition=Core`, .NET (Core), Windows/Linux/macOS cross-platform, `Unrestricted` on non-Windows.

2. **Audit Execution Policy bypass techniques**:
   Read `files/bypass-list.txt` to examine documented bypass methods:
   ```bash
   cat files/bypass-list.txt
   ```
   Extract at least 3 distinct bypass techniques into `bypasses.txt`.

3. **Record your verdict**:
   Write a single line in `verdict.md` summarizing Execution Policy's status as a speed bump rather than a security boundary:
   ```text
   Execution Policy is a speed bump, not a security boundary.
   ```

4. **Check your work**:
   ```bash
   lab check ps L0.3
   ```
