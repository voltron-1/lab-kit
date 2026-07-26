## BRIEF
Triage verdicts grade the rule's specific **threat claim**:
- **True Positive (TP)**: The claimed malicious behavior actually occurred and was unauthorized. Action: Escalate to Tier 2 for containment/remediation.
- **False Positive (FP)**: The claimed malicious behavior did NOT occur (logic flaw, misparsed string, or lookalike benign protocol). Action: File detection tuning ticket.
- **Benign True Positive (BTP)**: The rule correctly detected the behavior, but the activity was legitimate and authorized (e.g. approved change ticket, authorized pentest). Action: Close alert and submit tuning feedback (e.g. allowlist window).

In this lab, you evaluate six alert cases under `cases/c1/` through `cases/c6/`. For each case, inspect `alert.json`, `events.jsonl`, and `context.txt`, assign a disposition (`tp`, `fp`, `btp`), and cite the deciding event ID.

## GUIDED STEPS

1. **Evaluate Case 1 (`cases/c1/`)**:
   - `alert.json`: Password Spray alert (`CM-A-11`) from `203.0.113.66`.
   - `events.jsonl`: 3 failed logons (`4625`), 1 successful domain logon (`4624` `CM-0311-0142`), and 1 OWA sign-in without MFA (`CM-0311-0143`).
   - `context.txt`: `m.reyes` not traveling; no change tickets.
   - Verdict: `tp` (confirmed credential compromise); Deciding event ID: `cm-0311-0142` (or `cm-0311-0143`).

2. **Evaluate Case 2 (`cases/c2/`)**:
   - `alert.json`: Mimikatz command line alert (`CM-A-12`).
   - `events.jsonl`: `POWERPNT.EXE` command line opening `how-attackers-use-mimikatz.pptx` (`CM-0310-0071`).
   - `context.txt`: Helpdesk security awareness deck downloaded from intranet.
   - Verdict: `fp` (rule misfired on filename string in PowerPoint viewer); Deciding event ID: `cm-0310-0071`.

3. **Evaluate Case 3 (`cases/c3/`)**:
   - `alert.json`: PsExec service on domain controller (`CM-A-13`).
   - `events.jsonl`: `PSEXESVC.exe` started by `t.aoki` on DC01 (`CM-0310-0019`).
   - `context.txt`: `CHG-2143` approved `t.aoki` emergency DC01 patching 09:00Z-12:00Z.
   - Verdict: `btp` (PsExec behavior occurred but was fully authorized); Deciding event ID: `cm-0310-0019`.

4. **Evaluate Case 4 (`cases/c4/`)**:
   - `alert.json`: Password Spray alert (`CM-A-14`) from `192.0.2.150`.
   - `events.jsonl`: Failed logons (`4625` `CM-0310-0092`). No successful logons.
   - `context.txt`: Bluewater Security authorized quarterly pentest from `192.0.2.150`.
   - Verdict: `btp` (spray occurred but was authorized pentest activity); Deciding event ID: `cm-0310-0092`.

5. **Evaluate Case 5 (`cases/c5/`)**:
   - `alert.json`: Office spawning PowerShell (`CM-A-15`).
   - `events.jsonl`: `WINWORD.EXE` spawned `powershell.exe -enc` (`CM-0311-0201`), outbound C2 connection, and Run key persistence.
   - `context.txt`: User reported invoice attachment issue; no change tickets.
   - Verdict: `tp` (active macro malware execution); Deciding event ID: `cm-0311-0201`.

6. **Evaluate Case 6 (`cases/c6/`)**:
   - `alert.json`: C2 beaconing alert (`CM-A-16`).
   - `events.jsonl`: UDP port 123 traffic every 64s (`CM-0312-0203`).
   - `context.txt`: Standard workstation NTP time sync configuration to `192.0.2.10:123`.
   - Verdict: `fp` (rule misidentified benign NTP time sync as C2 beaconing); Deciding event ID: `cm-0312-0203`.

7. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set `q1`..`q6` to `tp|fp|btp` and `q1e`..`q6e` to the lowercase event ID.

8. **Check your work**:
   ```bash
   lab check soc L1.7
   ```
