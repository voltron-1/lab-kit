A full compromise chain reads across sensors: Windows Security for the logon, Sysmon for the execution tree, Linux auth for the foothold — each grounded in a CM- id.
Separate authorized activity (CHG-2143 PsExec) from the attack, or you'll escalate a benign change as lateral movement.
Phase 3 complete: you read Windows event codes cold, walk Sysmon trees, spot the wrong child, find persistence, hunt Linux auth, and call a LOLBin — Phase 4 puts a mixed queue in front of you.
