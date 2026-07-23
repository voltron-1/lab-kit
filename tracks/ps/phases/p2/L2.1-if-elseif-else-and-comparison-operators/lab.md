## BRIEF
PowerShell conditionals use operator syntax (`-eq`, `-ne`, `-gt`, `-lt`, `-ge`, `-le`, `-like`, `-match`) rather than traditional symbols (`==`, `>`).
By default, comparison operators in PowerShell are **case-insensitive** (`-eq`, `-like`, `-match`). Case-sensitive forms use the `-c` prefix (`-ceq`, `-clike`, `-cmatch`).
Additionally, `-match` automatically populates the automatic `$Matches` hashtable, while `-eq` against an array performs element filtering rather than returning a boolean scalar.

## GUIDED STEPS

1. **Test case-sensitivity differences**:
   Run `caseq.ps1` to observe that `-eq` is case-insensitive while `-ceq` is case-sensitive:
   ```bash
   pwsh -File caseq.ps1
   ```
   Notice that `caseq.ps1` outputs `ceq-differs` and `eq-MATCH`.

2. **Test regex matching and `$Matches`**:
   Run `match.ps1` to inspect automatic regex capture in `$Matches`:
   ```bash
   pwsh -File match.ps1
   ```
   Notice that `match.ps1` outputs `2026`.

3. **Explain array filtering behavior**:
   Create `verdict.txt` explaining why `@('a','b','admin') -eq 'admin'` returns `admin` instead of `$true`:
   ```text
   When -eq is applied to an array, PowerShell filters the array and returns matching elements instead of a boolean scalar.
   ```

4. **Check your work**:
   ```bash
   lab check ps L2.1
   ```
