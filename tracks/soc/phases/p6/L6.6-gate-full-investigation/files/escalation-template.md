# Full Escalation Report

## Scope
- 4 hosts affected: wks-acct-07, fs01, wks-eng-12, web01

## Timeline
- 2026-03-11 14:22:31Z: Event cm-0311-0142 password spray success for m.reyes on wks-acct-07
- 2026-03-11 15:41:07Z: Event cm-0311-0201 macro execution

## Indicators
- C2 Host: c2.stonewick[.]example
- C2 IP: 203.0.113[.]66

## ATT&CK
- T1059.001 PowerShell

## Verdict
- True Positive / Malicious

## Recommendation
- Isolate affected hosts and block C2 infrastructure
