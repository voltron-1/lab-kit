# Terminal Capstone Report (Model)

## Scope
- 4 hosts affected: wks-acct-07, fs01, wks-eng-12, web01

## Timeline
- 2026-03-11 14:22:31Z: Event cm-0311-0142 spray success for m.reyes
- 2026-03-11 15:41:07Z: Event cm-0311-0201 macro execution spawning powershell.exe

## Indicators
- C2 Host: c2.stonewick[.]example
- C2 IP: 203.0.113[.]66

## ATT&CK
- T1059.001: PowerShell
- T1547.001: Registry Run Keys

## Verdict
- True Positive / Malicious Intrusion

## Recommendation
- Isolate affected hosts and reset compromised credentials.

## Tuning Recommendation
- Add rule selector tuning: cmdline:winword->powershell to alert on Office child execution specifically.
