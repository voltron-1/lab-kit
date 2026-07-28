## BRIEF
This is the **Phase 4 Exit Gate** (`gate: true`). Five malicious one-liners (`malicious.txt`, static/defanged) — for each, name the **technique**, the **ATT&CK ID**, and the **log evidence it generates**. This integrates every Phase 4 lab: cradles (L4.1), encoding (L4.2), 4104 logging (L4.5), LOLBins (L4.6), and credential exposure (L4.7).
Record your analysis in `answers.md`; a 3-question quiz enforces 3/3 to pass the gate.

## GUIDED STEPS

1. **Read the five one-liners**:
   ```bash
   cat malicious.txt
   ```
   Map each to what you learned this phase:
   ```text
   1  iex + DownloadString cradle       -> fileless fetch-and-eval (L4.1)         -> T1059.001/T1105 -> evidence: 4104 ScriptBlock event
   2  powershell -nop -w hidden -enc    -> encoded command (L4.2)                 -> T1027/T1059.001  -> evidence: cmdline + 4104 (decoded)
   3  certutil -urlcache -split -f      -> LOLBin download (L4.6)                 -> T1105/T1218      -> evidence: process-creation (Sysmon 1/4688)
   4  Set-ItemProperty ...\Run          -> registry autostart persistence         -> T1547.001         -> evidence: registry write / 4104
   5  ConvertTo-SecureString -AsPlainText -> credential exposure (L4.7)           -> T1552.001         -> evidence: source itself / 4104
   ```

2. **Record your analysis**:
   Create `answers.md`:
   ```markdown
   # Malicious One-Liner Analysis
   1. Download cradle (iex + DownloadString): fileless fetch-and-eval. ATT&CK T1059.001/T1105. Evidence: a 4104 ScriptBlock event showing the decoded iex+DownloadString text.
   2. Encoded command (-enc): the -nop -w hidden -enc combo is itself a detection signature. ATT&CK T1027/T1059.001. Evidence: the command line plus a 4104 event recording the decoded script.
   3. LOLBin download (certutil): a signed, trusted binary abused to fetch a file. ATT&CK T1105/T1218. Evidence: process-creation telemetry showing powershell.exe spawning certutil.
   4. Registry Run-key persistence: writes an autostart entry pointing at an encoded launcher. ATT&CK T1547.001. Evidence: a registry-write event (or the 4104 event for the PowerShell call itself).
   5. Credential exposure: ConvertTo-SecureString from an in-script plaintext -- not secret at all. ATT&CK T1552.001. Evidence: the source itself, or a 4104 event if it's ever run.
   ```

3. **Check your work**:
   ```bash
   lab check ps L4.9
   ```
