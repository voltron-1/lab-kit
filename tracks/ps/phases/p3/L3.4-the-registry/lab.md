## BRIEF
PowerShell exposes the Windows registry as virtual drives (`HKLM:` for `HKEY_LOCAL_MACHINE` and `HKCU:` for `HKEY_CURRENT_USER`).
Cmdlets such as `Get-ItemProperty` and `Set-ItemProperty` allow querying and modifying registry keys and values.
Security analysts pay close attention to specific registry paths: `CurrentVersion\Run` and `CurrentVersion\RunOnce` are classic **autostart persistence** locations (T1547.001) where values are automatically executed at system boot or user logon.
Registry PSDrives are **Windows-only**; invoking `Get-ItemProperty HKLM:\...` on Linux pwsh 7 returns a "Cannot find drive" error.

## GUIDED STEPS

1. **Examine `reg-oneliners.txt`**:
   View `reg-oneliners.txt`:
   ```bash
   cat reg-oneliners.txt
   ```
   Observe how `Get-ItemProperty` queries autostart entries in `HKLM:\Software\Microsoft\Windows\CurrentVersion\Run` and `Winlogon\Shell`, while `Set-ItemProperty` writes persistence entries under `HKCU:\...\Run`.

2. **Test registry drives on Linux**:
   Try accessing `HKLM:` on your Linux environment:
   ```bash
   pwsh -Command "Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'"
   ```
   Notice the error: `Cannot find drive. A drive with the name 'HKLM' does not exist.` This confirms registry PSDrives are Windows-only and must be analyzed statically on non-Windows hosts.

3. **Record your persistence analysis**:
   Create `persistence.txt` identifying the autostart key path and technique:
   ```text
   The registry key CurrentVersion\Run is used for autostart persistence (T1547.001) to run payloads automatically at logon.
   ```

4. **Check your work**:
   ```bash
   lab check ps L3.4
   ```
