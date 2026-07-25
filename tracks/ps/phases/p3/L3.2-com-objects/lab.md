## BRIEF
Component Object Model (COM) automation allows PowerShell to interact with Windows shell and system internals via `New-Object -ComObject <ProgID>`.
Because COM automation directly invokes Windows COM interfaces (such as `WScript.Shell` or `Shell.Application`), attackers frequently use it to execute processes or modify registry settings while bypassing standard cmdlet logging.
COM objects are **Windows-only**; running `New-Object -ComObject` on Linux pwsh 7 returns an error indicating that COM is not supported on non-Windows platforms.

## GUIDED STEPS

1. **Examine `com-oneliners.txt`**:
   View `com-oneliners.txt`:
   ```bash
   cat com-oneliners.txt
   ```
   Observe how `WScript.Shell` provides `.Run()` for program execution and `.RegWrite()` for registry persistence, while `Shell.Application` provides `.ShellExecute()` for launching processes (with window style `0` for hidden execution).

2. **Test `New-Object -ComObject` on Linux**:
   Try invoking `New-Object -ComObject` on your Linux environment:
   ```bash
   pwsh -Command "New-Object -ComObject WScript.Shell"
   ```
   Notice the error: `COM objects are not supported on this platform.` This confirms that COM automation is Windows-only and must be analyzed statically on non-Windows hosts.

3. **Record your classification**:
   Create `classify.txt` mapping each ProgID to its capabilities:
   ```text
   WScript.Shell provides capabilities for program execution via Run and registry persistence via RegWrite.
   Shell.Application provides capabilities for hidden program execution via ShellExecute.
   ```

4. **Check your work**:
   ```bash
   lab check ps L3.2
   ```
