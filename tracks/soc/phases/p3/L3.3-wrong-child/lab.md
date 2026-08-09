## BRIEF
Hunt anomalous process parent-child relationships (e.g. Office/mail applications spawning shells).

## GUIDED STEPS

1. Inspect `files/sysmon.json` and `files/known-good-parents.md`.
2. Create `answers.txt`:
   ```text
   q1=powershell.exe
   q2=pg-ps1
   q3=outlook.exe
   q4=3
   q5=execution
   q6=cm-0311-0201
   ```
3. Verify with `lab check soc L3.3`.
