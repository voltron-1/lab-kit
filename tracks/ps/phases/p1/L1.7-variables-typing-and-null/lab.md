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

2. **See the array-filtering trap**:
   ```bash
   pwsh -File null-trap.ps1
   ```
   expect:
   ```text
   arr -eq null: TRUE (misleading! $results is a populated 3-element array, not null)
   null -eq arr: FALSE (correct)
   ```
   `$results` here is a real, populated array — not null. But `$results -eq $null`
   doesn't compare the array to null; it FILTERS the array for elements equal to
   null, and a multi-element result is truthy in an `if`, so the check fires
   anyway and lies about `$results` being null. `$null -eq $results` always
   forces a scalar comparison against the whole array object, so it can't be
   fooled by what's inside it.

3. **Explain $null interpolation**:
   Write a one-line explanation in `decode.txt` explaining why referencing an unassigned variable in double quotes produces an empty string:
   ```text
   Unassigned variables evaluate to $null and interpolate as empty strings.
   ```

4. **Check your work**:
   ```bash
   lab check ps L1.7
   ```
