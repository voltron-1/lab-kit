## BRIEF
PowerShell can invoke .NET framework static methods directly using syntax like `[Namespace.Type]::Method()`.
This gives PowerShell direct access to string manipulation, cryptographic transformations, and network capabilities without relying on cmdlets.
Understanding `[System.Convert]` and `[System.Text.Encoding]` allows you to decode obfuscated base64 and UTF-16LE payloads on any platform, while recognizing `[System.Net.WebClient]` identifies the network fetch half of download cradles (`[System.Net.WebClient].DownloadString`).

## GUIDED STEPS

1. **Examine `b64.ps1` and `decode.ps1`**:
   Run `b64.ps1` and `decode.ps1`:
   ```bash
   pwsh -File b64.ps1
   pwsh -File decode.ps1
   ```
   Notice that `b64.ps1` converts `'hi'` to base64 `aGk=`, while `decode.ps1` decodes the UTF-16LE base64 payload `'aABpAA=='` back to `'hi'`.

2. **Understand the .NET types**:
   - `[System.Convert]`: Provides methods like `ToBase64String` and `FromBase64String`.
   - `[System.Text.Encoding]::Unicode`: Represents UTF-16LE encoding (used by PowerShell `-EncodedCommand`).
   - `[System.Net.WebClient]`: Provides network methods like `DownloadString` (used in stager download cradles).

3. **Record your notes**:
   Create `notes.txt` mapping each .NET type to its security analysis role:
   ```text
   System.Convert handles Base64 encoding and decoding.
   System.Text.Encoding handles byte-to-text string conversions.
   System.Net.WebClient performs network fetch and download operations.
   ```

4. **Check your work**:
   ```bash
   lab check ps L3.1
   ```
