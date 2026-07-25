## BRIEF
This is the Phase 3 Exit Gate (`gate: true`).
You read ten administrative and post-exploitation one-liners (`subsystems.txt`) cold and identify the underlying Windows subsystem (.NET, COM, WMI/CIM, Registry, `iex`, Remoting, or ACLs) and its attack relevance.

## GUIDED STEPS

1. **Examine `subsystems.txt`**:
   View `subsystems.txt`:
   ```bash
   cat subsystems.txt
   ```
   Study each one-liner and map it to its core Windows subsystem and security implication:
   - Line 1: `.NET` (`System.Convert` Base64 decoding)
   - Line 2: `COM` (`WScript.Shell` object instantiation)
   - Line 3: `WMI/CIM` (`Get-CimInstance` modern query)
   - Line 4: `Registry` (`CurrentVersion\Run` autostart persistence, T1547.001)
   - Line 5: `iex` (`Invoke-Expression` in-memory eval)
   - Line 6: `Remoting` (`Invoke-Command -ComputerName` WinRM lateral movement, T1021.006)
   - Line 7: `ACL` (`Get-Acl` ACE permission enumeration)
   - Line 8: `.NET` (`System.Net.WebClient` network fetch half of a download cradle)
   - Line 9: `WMI` (`Get-WmiObject` legacy query and PS5.1 version tell)
   - Line 10: `COM` -> `Registry` (`RegWrite` autostart persistence via COM)

2. **Record your answers**:
   Create `answers.md` listing the subsystem and attack relevance for each line:
   ```markdown
   1. .NET - Base64 decoding (System.Convert)
   2. COM - Object instantiation (WScript.Shell)
   3. WMI/CIM - Modern system query (Get-CimInstance)
   4. Registry - Autostart persistence via Run key (T1547.001)
   5. iex - In-memory string evaluation
   6. Remoting - WinRM lateral movement (T1021.006)
   7. ACL - Security descriptor ACE enumeration
   8. .NET - WebClient DownloadString cradle fetch half
   9. WMI - Legacy query and PS5.1 version tell
   10. COM - Registry persistence write
   ```

3. **Check your work**:
   ```bash
   lab check ps L3.8
   ```
