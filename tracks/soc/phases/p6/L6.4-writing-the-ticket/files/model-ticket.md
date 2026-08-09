# Escalation Ticket (Model)

## Scope
- 2 hosts affected: wks-acct-07 (initial execution), fs01 (lateral admin creation)

## Timeline
- 2026-03-11 15:41:07Z: Macro executed WINWORD.EXE spawning powershell.exe on wks-acct-07
- 2026-03-11 15:46:02Z: C2 beacon initiated to c2.stonewick[.]example
- 2026-03-11 16:12:07Z: Rogue admin supportadmin created on fs01

## Indicators
- C2 Domain: c2.stonewick[.]example
- C2 IP: 203.0.113[.]66
- Persistence Run Key: OneDriveUpd

## ATT&CK
- T1059.001: PowerShell
- T1547.001: Registry Run Keys
- T1136.001: Create Account

## Verdict
- True Positive / Malicious Incident

## Recommendation
- Isolate hosts wks-acct-07 and fs01 immediately.
- Reset credentials for m.reyes and remove supportadmin account.
- Block IP 203.0.113[.]66 and domain c2.stonewick[.]example.
