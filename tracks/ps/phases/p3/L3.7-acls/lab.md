## BRIEF
PowerShell manages Windows security descriptors and Access Control Lists (ACLs) using `Get-Acl` and `Set-Acl`.
The `.Access` property returns an array of Access Control Entries (ACEs), which specify the identity (`IdentityReference`), permission rights (`FileSystemRights`), and access type (`AccessControlType`).
During privilege escalation audits, analysts look for **weak DACLs** where low-privilege accounts (such as `BUILTIN\Users` or `Everyone`) possess dangerous rights like `FullControl`, `WriteDacl`, `WriteOwner`, or `GenericAll` on privileged service binaries or autostart locations.
Windows ACL semantics are **Windows-only**; running `Get-Acl` on Linux pwsh returns POSIX mode bits rather than Windows DACL/ACE security descriptors.

## GUIDED STEPS

1. **Examine `acl-output.txt`**:
   View `acl-output.txt`:
   ```bash
   cat acl-output.txt
   ```
   Notice that `BUILTIN\Users` holds `FullControl` over `C:\Program Files\AppService\svc.exe`, allowing any standard user to overwrite the service binary.

2. **Understand Access Control Entries & Escalation**:
   - `(Get-Acl path).Access`: Returns the list of ACE rules.
   - Low-privilege rights: `BUILTIN\Users` or `Everyone`.
   - Dangerous rights: `FullControl`, `WriteDacl`, `WriteOwner`, `GenericAll`.
   - Escalation tell: A low-privilege user with write/control rights on a SYSTEM service executable represents an immediate privilege escalation vulnerability.

3. **Record your finding**:
   Create `finding.txt` identifying the dangerous right and explaining why it is a privilege escalation vulnerability:
   ```text
   The ACE grants BUILTIN\Users FullControl rights over the service binary, creating a privilege escalation path.
   ```

4. **Check your work**:
   ```bash
   lab check ps L3.7
   ```
