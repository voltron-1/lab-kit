## BRIEF
Windows Management Instrumentation (WMI) and Common Information Model (CIM) provide deep access to Windows OS internals for reconnaissance, remote execution (`Win32_Process.Create`), and fileless persistence (`__EventFilter` subscriptions).
A critical PowerShell version tell: `Get-WmiObject` was **removed in PowerShell 7** and exists only in legacy PowerShell 5.1.
In PowerShell 7, `Get-CimInstance` replaces `Get-WmiObject`. Both WMI and CIM rely on the Windows CIM repository and are **Windows-only** at runtime.

## GUIDED STEPS

1. **Run `wmi-gone.ps1` and examine `wmi-samples.txt`**:
   Run `wmi-gone.ps1` and view `wmi-samples.txt`:
   ```bash
   pwsh -File wmi-gone.ps1
   cat wmi-samples.txt
   ```
   Notice that `wmi-gone.ps1` outputs `ABSENT-IN-PS7`, proving that `Get-WmiObject` was removed in PS7.

2. **Understand WMI capabilities and migration**:
   - `Get-WmiObject`: Legacy PS5.1 cmdlet for WMI queries (version tell).
   - `Get-CimInstance`: Modern PS7 cmdlet for querying WMI/CIM objects.
   - `Win32_Process.Create` / `Invoke-CimMethod`: Enables process execution (T1047).
   - WMI Event Subscriptions (`__EventFilter`, `__EventConsumer`): Provide fileless persistence.

3. **Record your notes**:
   Create `notes.txt` explaining why attackers favor WMI and noting the shift to `Get-CimInstance`:
   ```text
   Attackers favor WMI for reconnaissance, process execution, and fileless persistence.
   Get-WmiObject was removed in PS7 and replaced by Get-CimInstance.
   ```

4. **Check your work**:
   ```bash
   lab check ps L3.3
   ```
