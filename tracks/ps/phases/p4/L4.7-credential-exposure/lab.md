## BRIEF
A `SecureString` sounds secure — but if it's built from an **in-script plaintext** (`-AsPlainText -Force`) or decrypted with an **in-script symmetric `-Key`**, the material is right there in source. It protects nothing. Separately, `$Env:`-held secrets **leak into transcripts and 4104 ScriptBlock events** the moment they're echoed.
Audit `creds-sample.ps1` and record ≥2 exposure types, the fix, and the ATT&CK ID in `finding.txt`.

## GUIDED STEPS

1. **Read the shipped sample**:
   ```bash
   cat creds-sample.ps1
   ```
   Three exposure patterns to find:
   ```text
   ConvertTo-SecureString 'Sup3rSecret!' -AsPlainText -Force   -> plaintext IN the script; the SecureString wrapper is theater
   ConvertTo-SecureString $enc -Key $key                        -> $key is ALSO in the script; anyone with the file can decrypt $enc
   Write-Output $env:LABKIT_DEMO_SECRET                          -> echoes an env-held secret straight into console output/transcripts/4104
   ```
   (The sample uses a fictional env var name so the file stays safe to actually run — the same pattern against a real one, e.g. `$env:AWS_SECRET_ACCESS_KEY`, would print a live cloud credential.)

2. **Read why each one fails, and the fix** (static reference):
   ```text
   A SecureString/ciphertext is only as protected as whatever decrypts it. If the plaintext or
   the symmetric key sits in the same script, there is no secret -- anyone who can read the file
   already has it.
   $Env: variables are fine to READ; the risk is ECHOING one (Write-Output, Write-Host, string
   interpolation into a log line) -- that's what lands the value in a transcript or a 4104 event.

   THE FIX: secrets belong in a vault or secret store (e.g. a credential manager, a cloud
   secrets service), fetched at runtime -- never hardcoded, and never echoed.
   ```
   ATT&CK: **T1552.001** (Unsecured Credentials: Credentials In Files).

3. **Record your finding**:
   Create `finding.txt`:
   ```text
   creds-sample.ps1 has two credential exposures: ConvertTo-SecureString built from an in-script
   plaintext (-AsPlainText -Force), and a second SecureString decrypted with an in-script -Key --
   both mean the "secret" is fully readable in source. It also echoes $env:LABKIT_DEMO_SECRET
   via Write-Output, which leaks it into transcripts and 4104 logs (a real secret env var,
   e.g. AWS_SECRET_ACCESS_KEY, would leak the same way).
   Fix: secrets belong in a vault/secret store, fetched at runtime, never hardcoded or echoed.
   ATT&CK: T1552.001 (Credentials In Files).
   ```

4. **Check your work**:
   ```bash
   lab check ps L4.7
   ```
