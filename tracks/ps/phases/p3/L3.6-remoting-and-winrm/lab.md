## BRIEF
PowerShell Remoting enables administrative and scripted execution on remote computers using cmdlets like `Invoke-Command`, `Enter-PSSession`, and `New-PSSession`.
The presence of `-ComputerName` or `-Session` parameters signals **remote execution** and **lateral movement** (MITRE ATT&CK T1021.006).
Classic Windows PowerShell remoting uses the **WinRM** transport protocol (ports 5985/HTTP and 5986/HTTPS), while PowerShell 7 adds cross-platform SSH remoting (`-HostName` / `-UserName`).

## GUIDED STEPS

1. **Run `remoting-params.ps1` and examine `remoting-samples.txt`**:
   Run `remoting-params.ps1` and view `remoting-samples.txt`:
   ```bash
   pwsh -File remoting-params.ps1
   cat remoting-samples.txt
   ```
   Notice that `remoting-params.ps1` returns `HAS-COMPUTERNAME`, proving that `Invoke-Command` includes parameter bindings for remote targets.

2. **Understand Remoting Mechanics & Transports**:
   - `Invoke-Command -ComputerName <Host>`: Runs a script block remotely across single or fan-out hosts.
   - `Enter-PSSession`: Initiates an interactive remote shell session.
   - WinRM Transport: Classic Windows remoting operating over TCP ports 5985 (HTTP) and 5986 (HTTPS).
   - Triage Signal: Scripting with `-ComputerName` / `-Session` is a primary indicator of remote execution / lateral movement (T1021.006).

3. **Record your lateral movement analysis**:
   Create `lateral.txt` identifying remoting cmdlets and threat techniques:
   ```text
   Invoke-Command and Enter-PSSession perform remote execution and lateral movement via WinRM (T1021.006).
   ```

4. **Check your work**:
   ```bash
   lab check ps L3.6
   ```
