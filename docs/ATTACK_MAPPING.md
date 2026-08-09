# MITRE ATT&CK Technique Mapping — PowerShell & SOC Analyst Labs

This document maps security-relevant lessons across the **PowerShell Literacy Lab (`ps`)** and **SOC Analyst Lab (`soc`)** tracks to the **MITRE ATT&CK® Framework**. 

---

## 1. PowerShell Literacy Lab (`ps`) Mapping

| Lesson | Title / Focus | ATT&CK ID | ATT&CK Technique Name | Category / Context |
|---|---|---|---|---|
| `ps L3.3` | WMI / CIM Integration | `T1047` | Windows Management Instrumentation | Execution / Discovery / Persistence |
| `ps L3.4` | Windows Registry Paths | `T1547.001` | Boot or Logon Autostart Execution: Registry Run Keys / Startup Folder | Persistence |
| `ps L3.5` | `Invoke-Expression` (`iex`) | `T1059.001` | Command and Scripting Interpreter: PowerShell | Execution / Stager Evaluation |
| `ps L3.6` | Remoting & WinRM | `T1021.006` | Remote Services: Windows Remote Management | Lateral Movement |
| `ps L3.7` | ACL Enumeration & Modification | `T1222.001` | File and Directory Permissions Modification: Windows File and Directory Permissions Modification | Defense Evasion / Privilege Escalation |
| `ps L4.1` | Download Cradles | `T1105`<br>`T1059.001` | Ingress Tool Transfer<br>Command and Scripting Interpreter: PowerShell | Execution / Command Delivery |
| `ps L4.2` | Encoded Commands | `T1027`<br>`T1059.001` | Obfuscated Files or Information<br>Command and Scripting Interpreter: PowerShell | Defense Evasion |
| `ps L4.3` | AMSI Architecture & Bypass | `T1562.001` | Impair Defenses: Disable or Modify Tools | Defense Evasion |
| `ps L4.4` | Constrained Language Mode | `T1562.001` | Impair Defenses: Disable or Modify Tools | Defense Evasion Analysis |
| `ps L4.5` | ScriptBlock & Module Logging | `T1562.002` | Impair Defenses: Disable Windows Event Logging | Audit / Detection |
| `ps L4.6` | LOLBins from PowerShell | `T1218` | System Binary Proxy Execution | Defense Evasion / Execution |
| `ps L4.7` | Credential Exposure | `T1552.001` | Unsecured Credentials: Credentials In Files | Credential Access |
| `ps L4.8` | Empire & PowerSploit Structure | `T1059.001`<br>`T1027` | Command and Scripting Interpreter: PowerShell<br>Obfuscated Files or Information | Framework Reading |
| `ps L4.9` | Phase Gate: Malicious One-Liners | `T1059.001`<br>`T1105` | Command and Scripting Interpreter: PowerShell<br>Ingress Tool Transfer | Integrative Gate |
| `ps L5.1` | Base64 Decode Pipeline | `T1027` | Obfuscated Files or Information | Deobfuscation |
| `ps L5.2` | String Concatenation | `T1027` | Obfuscated Files or Information | Deobfuscation |
| `ps L5.3` | Format String Obfuscation | `T1027` | Obfuscated Files or Information | Deobfuscation |
| `ps L5.4` | String Reversal | `T1027` | Obfuscated Files or Information | Deobfuscation |
| `ps L5.5` | Layered Obfuscation | `T1027` | Obfuscated Files or Information | Deobfuscation |
| `ps L5.6` | Sanitized Real-World Loader | `T1059.001`<br>`T1071.001` | Command and Scripting Interpreter: PowerShell<br>Application Layer Protocol: Web Protocols | Loader Triage |
| `ps L5.7` | Phase Gate: Three-Layer Payload | `T1027`<br>`T1059.001` | Obfuscated Files or Information<br>Command and Scripting Interpreter: PowerShell | Deobfuscation Gate |
| `ps L6.1` | Tour: PowerView | `T1087.002`<br>`T1069.002` | Account Discovery: Domain Account<br>Permission Groups Discovery: Domain Groups | Discovery Tool Reading |

---

## 2. SOC Analyst Lab (`soc`) Mapping

| Lesson | Title / Focus | ATT&CK ID | ATT&CK Technique Name | Category / Context |
|---|---|---|---|---|
| `soc L1.1`–`L1.8` | Attacks to Alerts Pipeline | `T1078`<br>`T1059.001`<br>`T1136.001` | Valid Accounts<br>PowerShell<br>Create Account: Local Account | Initial Access / Execution / Persistence |
| `soc L2.2` | DNS Analysis & Tunnels | `T1071.004` | Application Layer Protocol: DNS | Command and Control / Exfiltration |
| `soc L2.3` | HTTP / TLS C2 Beacons | `T1071.001` | Application Layer Protocol: Web Protocols | Command and Control |
| `soc L2.6` | Beaconing & Jitter | `T1071` | Application Layer Protocol | Network Triage |
| `soc L3.1` | Windows Security Events | `T1078`<br>`T1059`<br>`T1136.001` | Valid Accounts<br>Command Interpreter<br>Create Account | Endpoint Telemetry |
| `soc L3.2`–`L3.3` | Sysmon Process Trees & Office Shell Spawning | `T1566.001`<br>`T1059.001` | Phishing: Spearphishing Attachment<br>PowerShell | Execution / Phishing |
| `soc L3.4` | Endpoint Persistence Spots | `T1547.001`<br>`T1053.005`<br>`T1543.003`<br>`T1053.003` | Registry Run Keys<br>Scheduled Task<br>Windows Service<br>Cron | Persistence |
| `soc L3.5` | Linux Auth & Audit Logs | `T1110.001`<br>`T1548.003`<br>`T1136.001` | Brute Force: Password Guessing<br>Sudo Abuse<br>Create Account | Credential Access / Privilege Escalation |
| `soc L3.6` | LOLBins Triage | `T1218`<br>`T1105` | System Binary Proxy Execution<br>Ingress Tool Transfer | Defense Evasion |
| `soc L4.4` | Brute Force vs Password Spray | `T1110.001`<br>`T1110.003` | Brute Force: Password Guessing<br>Brute Force: Password Spraying | Credential Access |
| `soc L5.1` | Email Headers & Authentication | `T1566.001`<br>`T1566.002` | Spearphishing Attachment<br>Spearphishing Link | Phishing Triage |
| `soc L5.2` | URL Analysis & Lookalikes | `T1566.002` | Phishing: Spearphishing Link | Domain Analysis |
| `soc L5.3` | Attachment Triage & Magic Bytes | `T1566.001`<br>`T1027` | Spearphishing Attachment<br>Obfuscated Files or Information | File Safety Inspection |
| `soc L5.4` | Sandbox Report Reading | `T1566.001`<br>`T1547.001` | Spearphishing Attachment<br>Registry Run Keys | Detonation Summary |
| `soc L6.1`–`L6.6` | Investigation & Escalation | `T1566.001`<br>`T1059.001`<br>`T1547.001`<br>`T1136.001` | Phishing<br>PowerShell<br>Run Keys<br>Create Account | Full Incident Chain |
| `soc L7.1`–`L7.7` | The AI-Assisted Analyst | `T1059.001`<br>`T1547.001`<br>`T1136.001` | Execution / Persistence | Verification & Tuning Handoff |

---

## 3. Summary Statistics
- **Total PowerShell (`ps`) Mapped Lessons:** 22 lessons covering 11 distinct MITRE ATT&CK techniques.
- **Total SOC Analyst (`soc`) Mapped Lessons:** 24 lessons covering 14 distinct MITRE ATT&CK techniques.
