## BRIEF
PowerShell variables are dynamically typed ($type follows the value) unless explicitly constrained with a type acceleration (e.g. `[int]$n`).
An unassigned or misspelled variable evaluates as `$null`, which silently interpolates as an empty string in double-quoted strings — the silent bug introduced in L0.2.
In this lab, you decode `$null` behavior, type coercion, and why `$null -eq $var` (null on the left) is best practice.

## GUIDED STEPS

1. **Test $null interpolation and type coercion**:
   Run `interp.ps1` and `ntype.ps1` to observe `$null` interpolation and string-to-integer coercion:
   ```bash
   pwsh -File interp.ps1
   pwsh -File ntype.ps1
   ```
   Notice `interp.ps1` prints `value:[]` because `$null` evaluates to empty string, while `ntype.ps1` coerces `"42"` to `Int32`.

2. **Explain $null interpolation**:
   Write a one-line explanation in `decode.txt` explaining why referencing an unassigned variable in double quotes produces an empty string:
   ```text
   Unassigned variables evaluate to $null and interpolate as empty strings.
   ```

3. **Check your work**:
   ```bash
   lab check ps L1.7
   ```
