## BRIEF
PowerShell distinguishes between **terminating** and **non-terminating** errors.
Most cmdlet errors (like `Get-Content` on a missing file) are **non-terminating** by default and slip past `try/catch` blocks unless elevated using `-ErrorAction Stop` (or `$ErrorActionPreference = 'Stop'`).
Inside a `catch` block, `$_` (or `$PSItem`) contains the `ErrorRecord`, while `$?` contains a boolean indicating whether the last command succeeded, `$Error[0]` stores the most recent error, and `finally` runs unconditionally.

## GUIDED STEPS

1. **Examine `catch.ps1` and `nocatch.ps1`**:
   Run `catch.ps1` and `nocatch.ps1`:
   ```bash
   pwsh -File catch.ps1
   pwsh -File nocatch.ps1
   ```
   Notice that `catch.ps1` (with `-ErrorAction Stop`) outputs `CAUGHT` and `FINALLY`, whereas `nocatch.ps1` (without `-ErrorAction Stop`) does NOT catch the error and outputs `REACHED-END`.

2. **Explain non-terminating error behavior**:
   Create `why.txt` explaining why `nocatch.ps1` printed `REACHED-END` instead of entering the `catch` block:
   ```text
   Cmdlet errors are non-terminating by default and slip past try/catch unless elevated with -ErrorAction Stop.
   ```

3. **Check your work**:
   ```bash
   lab check ps L2.5
   ```
