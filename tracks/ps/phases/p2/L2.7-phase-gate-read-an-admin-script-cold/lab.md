## BRIEF
This is the Phase 2 Exit Gate (`gate: true`).
You read a 60-line administrative PowerShell script (`health-snapshot.ps1`) cold and analyze its parameters, validation decorators, conditional branches, loops, error handling posture, and module imports.

## GUIDED STEPS

1. **Examine `health-snapshot.ps1` and run `tagprobe.ps1`**:
   View `health-snapshot.ps1` and run `tagprobe.ps1`:
   ```bash
   cat health-snapshot.ps1
   pwsh -File tagprobe.ps1
   ```
   Notice that `tagprobe.ps1` executes the internal `Get-HealthTag` logic and outputs `CRITICAL`, `WARN`, and `OK`.

2. **Answer the 10 Comprehension Questions**:
   Read `health-snapshot.ps1` carefully and answer the following 10 questions in `answers.md`:

   1. **Mode validation**: What two values are allowed for the `-Mode` parameter by `[ValidateSet()]`?
   2. **Critical threshold**: At what working set memory threshold in MB does a process get tagged `CRITICAL`?
   3. **Tag classification**: What tag is returned for a process using **250 MB** of working set memory?
   4. **Decorator role**: What capabilities does `[CmdletBinding()]` grant to `health-snapshot.ps1`?
   5. **Switch default reachability**: Why is the `switch` statement `default` clause (`throw "unknown mode: $Mode"`) effectively unreachable?
   6. **Error handling catchability**: Does the `try/catch` block around `Out-File` catch a non-terminating file write error?
   7. **Array wrapping**: What does wrapping `$critical = @(...)` guarantee for the `.Count` property even if 0 or 1 item matches?
   8. **Loop construct**: Is the loop in `$report = foreach ($p in ...)` a pipeline cmdlet or an in-memory `foreach` statement?
   9. **Object output type**: What object type is created by `[pscustomobject]@{ ... }` inside the loop?
   10. **Process selection**: What subset of processes does `Sort-Object WS -Descending | Select-Object -First $TopN` select?

3. **Record your answers in `answers.md`**:
   Create `answers.md` with your answers:
   ```markdown
   1. Quick and Full
   2. 500 MB
   3. WARN
   4. Advanced function common parameters like Verbose and ErrorAction
   5. ValidateSet rejects invalid Mode parameters during parameter binding before the body runs
   6. No, because Out-File lacks -ErrorAction Stop
   7. Guarantees array type so .Count returns integer 0 or 1 safely
   8. In-memory foreach statement
   9. pscustomobject
   10. The top N processes sorted descending by working set memory
   ```

4. **Check your work**:
   ```bash
   lab check ps L2.7
   ```
