## BRIEF
PowerShell modules group related functions and tools into redistributable packages.
A module consists of a **manifest file** (`.psd1`, a metadata hashtable) and a **script module file** (`.psm1`, the underlying executable code).
Reading the manifest with `Import-PowerShellDataFile` allows inspecting the module's version, entry point (`RootModule`), exported functions (`FunctionsToExport`), and dependencies (`RequiredModules`) without running any module code.

## GUIDED STEPS

1. **Examine `AdminTools.psd1` and `AdminTools.psm1`**:
   View `AdminTools.psd1` and `readmanifest.ps1`:
   ```bash
   cat AdminTools.psd1
   pwsh -File readmanifest.ps1
   ```
   Notice that `readmanifest.ps1` uses `Import-PowerShellDataFile` to safely parse `AdminTools.psd1` as data, returning `Get-DiskReport`, `Restart-AppPool`, and version `1.2.0`.

2. **Understand `.psd1` vs `.psm1`**:
   - `.psd1`: The module manifest containing metadata, versioning, author info, and export declarations.
   - `.psm1`: The script module file containing the actual PowerShell function code.
   - `RootModule`: Specifies the `.psm1` code file loaded by the manifest.

3. **Record your notes**:
   Create `notes.txt` explaining the difference between `.psd1` and `.psm1` and naming the `RootModule` key:
   ```text
   A .psd1 file is a module manifest containing metadata, while a .psm1 file contains script code. The RootModule key specifies the script code entry point.
   ```

4. **Check your work**:
   ```bash
   lab check ps L2.6
   ```
