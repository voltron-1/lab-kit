## BRIEF
Constrained Language Mode (CLM) restricts PowerShell to a safe subset of cmdlets and language features: it blocks direct **.NET type access** (`[System.Net.WebClient]::new()`), **`Add-Type`**, **COM object creation** (`New-Object -ComObject`), and most of the script-based attack primitives Phase 3 taught you to read.
That power only holds **when an application-control engine enforces it** — WDAC or AppLocker. Setting `$ExecutionContext.SessionState.LanguageMode` by itself, with no enforcement engine behind it, is just a session property a script can set back.
Record what CLM blocks and its enforcement dependency in `notes.txt`.

## GUIDED STEPS

1. **Read what CLM blocks and allows** (static reference):
   ```text
   CLM BLOCKS (when WDAC/AppLocker-enforced):
     - direct .NET type access, e.g. [System.Net.WebClient]::new()
     - Add-Type (compiling and loading arbitrary .NET code)
     - New-Object -ComObject (COM instantiation)
     - most of the arbitrary-code-execution primitives Phase 3 covered

   CLM ALLOWS: approved cmdlets and a safe language subset (variables,
   pipelines, basic control flow — no direct type/COM/compilation access)
   ```
   This is exactly the reach Phase 3 (L3.1 `.NET` types, L3.2 COM objects) taught you to read — under CLM, that reach disappears.

2. **Read the enforcement dependency** (the part that's easy to miss):
   ```text
   CLM is the LANGUAGE-MODE CONSEQUENCE of a WDAC or AppLocker policy decision — it is
   not a standalone toggle you can trust on its own.

   Bare (session property only, no enforcement engine): bypassable — nothing stops a script
   from resetting $ExecutionContext.SessionState.LanguageMode itself.
   WDAC/AppLocker-enforced: a REAL boundary — the enforcement engine, not the language
   mode setting, is what actually blocks the primitive.
   ```
   This mirrors L0.3's classification: CLM is a real control *only* when something outside the PowerShell process itself (WDAC or AppLocker) enforces it. ATT&CK classifies WDAC/AppLocker as **M1038** (Execution Prevention).

3. **Record your notes**:
   Create `notes.txt`:
   ```text
   CLM blocks direct .NET type access, Add-Type, and COM object creation via New-Object -ComObject.
   It's only a real boundary when WDAC or AppLocker enforces it -- a session-property-only LanguageMode setting with no enforcement engine is bypassable.
   ```

4. **Check your work**:
   ```bash
   lab check ps L4.4
   ```
