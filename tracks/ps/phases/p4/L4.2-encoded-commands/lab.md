## BRIEF
`-EncodedCommand` (`-enc`) takes base64 of **UTF-16LE** text, never UTF-8. Decoding it is a real, cross-platform skill — you'll decode a benign blob for real below.
The decoded text is what gets logged: a 4104 ScriptBlock event records the *decoded* script, so the flag hides intent from a human glancing at the command line — not from logging, and not from a decoder.
The command-line combo `-nop -w hidden -enc <blob>` is itself a detection signature.
Record the encoding, the detection tell, and the ATT&CK ID in `audit.md`.

## GUIDED STEPS

1. **Decode the benign blob for real**:
   ```bash
   pwsh -NoProfile -NonInteractive -File decode-enc.ps1
   ```
   Real output:
   ```
   Write-Output 'benign'
   ```
   That's the whole trick: `-EncodedCommand` is just base64 of UTF-16LE bytes. `[System.Convert]::FromBase64String` (from L3.1) plus `[System.Text.Encoding]::Unicode.GetString` decode it in one line — cross-platform, no PowerShell required to defeat it.

2. **Read the malicious signature** (static, defanged — never run this):
   ```text
   powershell.exe -nop -w hidden -enc <base64-UTF16LE-blob>
   ```
   This is the classic malicious launch line. `-nop` (`-NoProfile`) and `-w hidden` (`-WindowStyle Hidden`) paired with an encoded command is a combination no legitimate script needs — it's built to run unattended and unseen. Nothing about the flag itself hides the payload from a defender who decodes it or reads the 4104 event; it only defeats a human eyeballing the raw command line.

3. **Record your audit**:
   Create `audit.md`:
   ```markdown
   # Encoded Command Audit
   The encoded-command flag takes base64 of UTF-16LE text, not UTF-8.
   Encoding hides intent from a human reading the command line, but a 4104 ScriptBlock event logs the decoded script, and the blob is trivially decoded with [System.Convert] + [System.Text.Encoding].
   The command-line combo -nop -w hidden plus the encoded-command flag is itself a detection signature. ATT&CK: T1027.
   ```

4. **Check your work**:
   ```bash
   lab check ps L4.2
   ```
