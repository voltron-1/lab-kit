# Coppermine IR summary — WKS-ACCT-07, 2026-03-11

[A] 2026-03-09T13:05:00Z — WHOIS lookup reveals domain copperm1ne-billing[.]example was newly registered.
[B] 2026-03-10T18:40:00Z — VBA macro project built inside malicious document invoice_2026-03.docm on attacker infrastructure.
[C] 2026-03-11T15:02:00Z — Spearphishing email from billing@copperm1ne-billing[.]example (sender IP 198.51.100.71) delivered to m.reyes containing invoice_2026-03.docm.
[D] 2026-03-11T15:41:07Z — User opens attachment; macros execute and WINWORD.EXE spawns powershell.exe -nop -w hidden -enc to fetch stage-2 payload from hxxps://cdn.stonewick[.]example/.
[E] 2026-03-11T15:41:20Z — Persistence established by writing a registry run key value under HKCU\Software\Microsoft\Windows\CurrentVersion\Run.
[F] 2026-03-11T15:46:02Z — Encrypted C2 beaconing initiated to c2.stonewick[.]example (203.0.113.66:443) every 300 seconds.
[G] 2026-03-11T16:32:00Z — Accounts Payable invoice data gathered and staged to SMB share \\FS01\finance.
