## BRIEF
`Invoke-Expression` (aliased as `iex`) is PowerShell's `eval` statement — it parses and executes a **string** as live PowerShell code.
When combined with `[System.Net.WebClient].DownloadString` (from L3.1), `iex` creates the canonical **download cradle**: `iex (DownloadString(url))`.
This pattern fetches remote code over HTTP/S and executes it directly **in memory**, without ever writing a file to disk.
Because no file hits disk, traditional file-based antivirus scanners are bypassed — making download cradles an attacker staple in nearly every stager payload.

## GUIDED STEPS

1. **Examine `stager-sample.txt`**:
   View `stager-sample.txt`:
   ```bash
   cat stager-sample.txt
   ```
   Notice how `DownloadString` fetches remote code while `iex` evaluates the resulting string in memory.

2. **Understand Cradle Mechanics & Evasion**:
   - `Invoke-Expression` / `iex`: Evaluates a string payload (PowerShell's `eval`, analog of Bash `eval`).
   - In-memory execution: The payload runs entirely in RAM without writing to the filesystem (fileless evasion).
   - High-signal detection: A single ScriptBlock (Event ID 4104) containing both `iex` and `DownloadString` is a primary blue-team detection trigger.

3. **Record your audit analysis**:
   Create `audit.md` auditing the download cradle stager:
   ```markdown
   # Download Cradle Audit
   The download cradle uses WebClient DownloadString to fetch a remote payload and Invoke-Expression (iex) to eval the string in memory.
   This executes code directly in RAM without writing files to disk, bypassing file-based antivirus scanners.
   ```

4. **Check your work**:
   ```bash
   lab check ps L3.5
   ```
