# Escalation Ticket

## Scope
- 2 hosts affected: wks-acct-07, fs01

## Timeline
- 2026-03-11 15:41:07Z: Macro executed WINWORD.EXE spawning powershell.exe

## Indicators
- C2 Domain: c2.stonewick[.]example
- C2 IP: 203.0.113[.]66

## ATT&CK
- T1059.001 PowerShell

## Verdict
- True Positive / Malicious

## Recommendation
- Isolate wks-acct-07 and fs01
- Block c2.stonewick[.]example at perimeter
