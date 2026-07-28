## BRIEF
Empire and PowerSploit are the two best-known offensive PowerShell toolkits. You'll read their **structure** — how a stager is built, how modules are named — with **no working payload anywhere**. Recognition is the analyst skill: knowing a framework by its shape in telemetry, never running or reconstructing it.
Record the stager's stages and ≥2 PowerSploit/PowerView function families (+ what each does) in `tour.md`.

## GUIDED STEPS

1. **Read the Empire stager shape** (sanitized structure only, no payload):
   ```text
   [encoded launcher] -> [staging key exchange] -> [agent tasking loop over C2]
   ```
   Tells: a base64-encoded launcher on the command line, an initial staging request to a C2 host, then a periodic beacon with jitter (randomized timing to blend into normal traffic).

2. **Read the PowerSploit / PowerView module families** (function-name tells, sanitized — no working code):
   ```text
   Invoke-Mimikatz         -> credential theft (dumps LSASS-held creds)
   Invoke-Shellcode        -> in-memory code injection
   Get-GPPPassword         -> recon (Group Policy Preference cached credentials)
   PowerView:
     Get-NetUser / Get-NetGroup / Find-LocalAdminAccess  -> Active Directory enumeration (-> Phase 6 PowerView tour)
   ```
   The naming pattern itself is the tell: `Invoke-<Verb>` for offensive actions, `Get-Net*` for AD recon. ATT&CK is framework-dependent per module — e.g. **T1059.001** (PowerShell) for execution, **T1003** for Mimikatz-style credential dumping.

3. **Record your tour**:
   Create `tour.md`:
   ```markdown
   # Empire & PowerSploit Structure Tour
   Empire stager shape: an encoded launcher, then a staging key exchange, then a beacon/tasking loop back to C2.
   PowerSploit/PowerView families: Invoke-Mimikatz (credential theft), Get-NetUser/PowerView (AD enumeration).
   You read the STRUCTURE to recognize the framework in telemetry -- never the payload.
   ```

4. **Check your work**:
   ```bash
   lab check ps L4.8
   ```
