## BRIEF
You already met the classic download cradle (`iex (DownloadString(url))`) in L3.5 — fetch remote text, `iex` evaluates it in memory, nothing touches disk.
This lab compares that baseline against two other cradle transports: `Invoke-WebRequest` (same fileless shape) and `Start-BitsTransfer` (which is **not** fileless — it drops a real file via a background transfer service that blends in with legitimate Windows Update traffic).
For each variant, record whether it's fileless or disk-dropping, its ATT&CK ID, and the detection artifact it generates, in `audit.md`.

## GUIDED STEPS

1. **Examine `cradle-variants.txt`**:
   ```bash
   cat cradle-variants.txt
   ```
   Notice all three variants fetch remote content over HTTP/S — the difference is what happens to it next.

2. **Compare the three transports**:
   - Variants 1-2 (`iex`, `Invoke-WebRequest` wrapped in `iex`): fetch-and-eval in memory — fileless, no disk artifact for file-based AV to scan.
   - Variant 3 (`Start-BitsTransfer`): downloads to a **real file** on disk via the Background Intelligent Transfer Service — not fileless, and its background-service transport pattern blends with routine Windows Update activity.
   - Detection: a single ScriptBlock (Event ID 4104) containing `DownloadString` + `iex` is the high-signal tell for variants 1-2 (ATT&CK T1059.001, T1105). BITS activity is logged separately under the `Microsoft-Windows-Bits-Client` event log (ATT&CK T1105, plus T1197 for the BITS Jobs technique specifically).

3. **Record your audit analysis**:
   Create `audit.md` covering all three variants:
   ```markdown
   # Download Cradle Audit
   Variant 1 (iex + DownloadString) and Variant 2 (Invoke-WebRequest + iex) are both fileless: they fetch remote text and iex evaluates it in memory, so no file ever hits disk.
   Variant 3 (Start-BitsTransfer) is different — it drops a real file via a background transfer service, blending in with legitimate Windows Update traffic.
   Fileless cradles are detected via a 4104 ScriptBlock event showing DownloadString and iex together. ATT&CK: T1059.001, T1105.
   ```

4. **Check your work**:
   ```bash
   lab check ps L4.1
   ```
