# Full Escalation Report (Model)

## Scope
- 4 hosts affected: wks-acct-07, fs01, wks-eng-12, web01

## Timeline
- 2026-03-11 14:22:31Z: Event cm-0311-0142 spray success for m.reyes
- 2026-03-11 15:41:07Z: Event cm-0311-0201 macro exec spawning powershell.exe on wks-acct-07
- 2026-03-11 16:12:07Z: Event cm-0311-0244 rogue admin supportadmin creation on fs01

## Indicators
- C2 Host: c2.stonewick[.]example
- C2 IP: 203.0.113[.]66
- Source IP: 198.51.100[.]71

## ATT&CK
- T1059.001: PowerShell
- T1547.001: Registry Run Keys
- T1136.001: Create Account

## Verdict
- True Positive / Malicious Intrusion

## Recommendation
- Isolate hosts wks-acct-07, fs01, wks-eng-12, and web01.
- Block IP 203.0.113[.]66, domain c2.stonewick[.]example, and source IP 198.51.100[.]71.
