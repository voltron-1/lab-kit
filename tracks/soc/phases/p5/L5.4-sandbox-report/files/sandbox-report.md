# Sandbox Detonation Report
- **Sample**: invoice_2026-03.docm
- **Verdict**: malicious (Score 88/100)
- **Process Tree**: WINWORD.EXE -> powershell.exe -enc -> cmd.exe
- **Network**: Beacon to c2.stonewick.example:443 (TLS, interval 300s)
- **Dropped Persistence**: Run key leaf `OneDriveUpd`
- **MITRE ATT&CK**: T1566.001 (Spearphishing Attachment), T1059.001 (PowerShell), T1547.001 (Registry Run Keys)
