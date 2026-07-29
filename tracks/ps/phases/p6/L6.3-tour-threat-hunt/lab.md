## BRIEF
A threat hunt is a query you run when nothing has alerted yet. This one goes looking for obfuscated PowerShell in the ScriptBlock log — which means it is the defensive mirror of everything you did in phases 4 and 5.

`Get-WinEvent` reads Windows event logs and does not exist on this machine, so the hunt is read, never run. That is not a limitation of the lab; it is the normal way you meet a hunt written by someone else.

## GUIDED STEPS

1. **Read the hunt**:
   ```bash
   less hunt.ps1
   ```
   Three things carry the meaning: the hashtable (which log, which event ID), the
   `-match` filter (what it hunts for), and the closing comment (what it cannot see).

2. **Work out why 4104 is the right log**:
   The hunt could have read command lines instead. Think back to L4.5 and decide
   what 4104 gives you that a command line does not — the answer is why encoding
   the command does not hide the script from this hunt.

3. **Then work out what it misses**:
   The filter matches literal strings. Think back to L5.2 through L5.4 and name a
   technique whose output would never contain any of them.

4. **Write your readout**:
   Create `readout.md` with the log and event ID, the cmdlet the hunt queries with,
   what the filter looks for, and what it would miss.

5. **Check your work**:
   ```bash
   lab check ps L6.3
   ```
