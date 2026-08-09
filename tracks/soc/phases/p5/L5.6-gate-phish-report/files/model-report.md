# Phishing Escalation Report (Model)

## Timeline
- 2026-03-11 15:02:00Z: Phishing email delivered to m.reyes@coppermine.example
- 2026-03-11 15:42:10Z: Malicious macro executed WINWORD.EXE spawning powershell.exe

## Indicators
- Sender IP: 198.51.100[.]71 (Authentication-Results: spf=fail)
- Malicious Domain: copperm1ne-billing[.]example
- C2 Beacon: c2.stonewick[.]example
- C2 URL: hxxp://cdn.stonewick[.]example/pay

## ATT&CK
- T1566.001: Spearphishing Attachment
- T1059.001: PowerShell Execution

## Verdict
- True Positive / Malicious Phishing Campaign

## Recommendation
- Block IP 198.51.100[.]71 and domain copperm1ne-billing[.]example at mail & firewall gateway.
- Isolate host WKS-ACCT-07 and reset credentials for m.reyes.
