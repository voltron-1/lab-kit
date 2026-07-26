## BRIEF
This phase gate evaluates your mastery of Phase 1 concepts: telemetry source identification, ATT&CK technique mapping, and selecting raw evidence pulls.

You are provided with five untagged SIEM alerts (`CM-A-51.json` through `CM-A-55.json`), a `sources-catalog.md` defining valid telemetry slugs, an extended `attack-excerpt.json`, and an `evidence-menu.md`.

For each alert, identify:
- `qNa`: Telemetry source slug (`zeek-conn`, `zeek-dns`, `win-security`, `sysmon`, `linux-auth`, `entra-signin`).
- `qNb`: Exact ATT&CK technique ID (e.g., `t1110.003`).
- `qNc`: Best evidence pull option (`a`, `b`, or `c`).

## GUIDED STEPS

1. **Inspect Alert 1 (`alerts/CM-A-51.json`)**:
   - `evidence.query`: `index=entra_signin result:success mfa:absent` → `q1a=entra-signin`
   - Threat tactic: `credential-access`, Rule: "Successful sign-in without expected MFA claim" → `q1b=t1110.003` (Password Spraying)
   - `evidence-menu.md` selection → `q1c=b` (raw entra-signin records 14:05Z-14:25Z for IP 203.0.113.66 across all accounts)

2. **Inspect Alert 2 (`alerts/CM-A-52.json`)**:
   - `evidence.query`: `index=sysmon event.code:1` → `q2a=sysmon`
   - Threat tactic: `execution`, Rule: "Office application spawned encoded PowerShell" → `q2b=t1059.001` (PowerShell)
   - `evidence-menu.md` selection → `q2c=a` (Sysmon Event ID 1 on WKS-ACCT-07 with WINWORD parent and powershell -enc child)

3. **Inspect Alert 3 (`alerts/CM-A-53.json`)**:
   - `evidence.query`: `index=zeek_dns` → `q3a=zeek-dns`
   - Threat tactic: `command-and-control`, Rule: "High-entropy subdomain burst with NXDOMAIN ratio" → `q3b=t1071.004` (DNS)
   - `evidence-menu.md` selection → `q3c=c` (Zeek DNS log records for source 10.20.31.112 querying tun.stonewick.example)

4. **Inspect Alert 4 (`alerts/CM-A-54.json`)**:
   - `evidence.query`: `index=win_security event.code:(4720 OR 4732)` → `q4a=win-security`
   - Threat tactic: `persistence`, Rule: "Account created and added to Administrators within 60s" on FS01 → `q4b=t1136.001` (Local Account)
   - `evidence-menu.md` selection → `q4c=a` (Windows Security events 4720 and 4732 on FS01)

5. **Inspect Alert 5 (`alerts/CM-A-55.json`)**:
   - `evidence.query`: `index=linux_auth` → `q5a=linux-auth`
   - Threat tactic: `persistence`, Rule: "Cron entry installed during interactive root SSH session" → `q5b=t1053.003` (Cron)
   - `evidence-menu.md` selection → `q5c=b` (WEB01 auth.log entries for SSH auth, crontab REPLACE, and PAM session)

6. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each answer field `q1a` through `q5c` in lowercase.

7. **Check your work**:
   ```bash
   lab check soc L1.8
   ```
