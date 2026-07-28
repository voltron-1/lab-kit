## BRIEF
AMSI (Antimalware Scan Interface) hands PowerShell script content to the registered antivirus (e.g. Defender) at runtime, after de-obfuscation, right before execution — so it sees the REAL payload even if it arrived encoded or obfuscated.
Bypass *attempts* exist (in-memory tampering, string-splitting, forcing an init error) but they're noisy and detectable — AMSI is a real control and telemetry source, not a speed bump (L0.3's classification).
AMSI is a Windows runtime component; you read its behavior statically here — nothing in this lab runs, and no bypass code is ever shown in working form.
Record what AMSI scans, its classification, and the ATT&CK ID for a bypass attempt in `notes.txt`.

## GUIDED STEPS

1. **Read how AMSI fits into the execution path** (static reference — no working code, ever):
   ```text
   WHERE it sits:    pwsh -> amsi.dll -> AmsiScanBuffer() -> registered AV verdict -> allow/block
   WHAT it scans:    de-obfuscated script content, AT RUNTIME, right before execution
   WHY that matters: an encoded or obfuscated command (L4.2) is decoded before AMSI ever sees
                     it -- AMSI catches what a scan of the raw, on-disk, or encoded form would miss
   ```

2. **Read what bypass *attempts* look like** (behavioral description only — no runnable bypass is ever shipped or shown in this lab):
   ```text
   - in-memory tampering with the AMSI scan function -> a crash-prone, high-signal pattern
   - splitting the literal string "AMSI" across variables to dodge naive signature matching -> an obfuscation
     tell, not a real defeat
   - forcing an AMSI initialization error -> itself a detectable, loggable event
   ```
   None of these defeat AMSI silently — each leaves a trace. This is why AMSI is classified as a **real control** (L0.3), not a speed bump: bypassing it costs the attacker effort and is itself detectable.

3. **Record your notes**:
   Create `notes.txt`:
   ```text
   AMSI scans de-obfuscated script content at runtime, right before execution, so it sees the real payload even if it arrived encoded.
   Per L0.3's classification, AMSI is a real control and telemetry source, not a speed bump: bypass attempts are noisy and detectable.
   ATT&CK: T1562.001 (Impair Defenses) for an AMSI-bypass attempt.
   ```

4. **Check your work**:
   ```bash
   lab check ps L4.3
   ```
