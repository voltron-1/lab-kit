# Content Review Checklist for Offense-Adjacent Lessons

This document establishes the **Content Review Checklist** for inspecting, auditing, and maintaining offense-adjacent lesson content (such as obfuscation, download cradles, C2 beacon patterns, LOLBins, and encoded commands) across the **PowerShell Literacy (`ps`)** and **SOC Analyst (`soc`)** tracks.

Its purpose is to ensure that all curriculum material remains **defensively framed, sanitized, non-executable outside controlled test environments, and appropriate** for both personal upskilling and prospective student-facing instruction.

---

## 1. Core Defensive Framing Principles

1. **Defensive Perspective Only**: Every lesson must teach the student to **read, analyze, audit, or detect** offense-adjacent scripts/artifacts, never to deploy or weaponize them.
2. **Sanitized & Non-Functional Payloads**:
   - All network destinations MUST use RFC 2606 / RFC 6761 reserved domains (`.example`, `.invalid`, `.test`, `.localhost`) or RFC 5737 reserved documentation IP blocks (`198.51.100.0/24`, `203.0.113.0/24`, `192.0.2.0/24`).
   - No active external C2 endpoints or live malware URLs may be referenced or shipped.
   - All URIs in report/prose templates must be defanged (`hxxp://`, `[.]`).
3. **Safe Command Primitives**:
   - Script samples must use inert inspection commands (e.g., `whoami /all`, `Get-Process`, `hostname`) rather than destructive payloads, privilege escalation exploits, or credential harvesters.
4. **Isolated Static Grading**:
   - Lab test harnesses (`check.sh`) must grade samples via static parsing, AST inspection, string matching, or dry-run checks without executing learner-authored or untrusted PowerShell scripts.

---

## 2. Review Checklist (4-Point Audit)

When reviewing any offense-adjacent lesson, verify all four requirements:

- [x] **Requirement 1 — Framing**: The `lab.md` brief and guided steps frame the topic strictly around reading, deobfuscating, or detecting the technique.
- [x] **Requirement 2 — Indicator Defanging**: All domains use `.example`, all IPs use RFC documentation ranges, and prose/report templates defang URIs (`hxxp://`, `[.]`).
- [x] **Requirement 3 — Payload Safety**: Sample payloads perform harmless operations (`whoami`, `Get-Process`) and contain no functional exploits or active download cradles.
- [x] **Requirement 4 — Static Evaluation**: Graders check file properties, string patterns, or AST nodes without executing untrusted scripts.

---

## 3. Retrospective Application & Audit Findings

### 3.1 PowerShell Track (`ps`) Audit
- **`ps L4.1` (Download Cradles)**:
  - *Audit*: Verified that all sample cradles target `cdn.stonewick.example/u.sh` or `198.51.100.23`. Payloads are inert strings.
  - *Status*: PASS (Sanitized & Defensively Framed).
- **`ps L4.2` (Encoded Commands)**:
  - *Audit*: Base64 payloads decode to inert commands (`whoami /all`). Grader evaluates text structure statically.
  - *Status*: PASS.
- **`ps L4.6` (LOLBins from PowerShell)**:
  - *Audit*: Samples use `certutil -urlcache` targeting `.example` test endpoints; `check.sh` grades static command line strings.
  - *Status*: PASS.
- **`ps L5.1`–`L5.7` (Deobfuscation & Malware Reading)**:
  - *Audit*: All deobfuscation layers resolve to sanitized inert strings. Grader checks probe integrity and static string outputs (`plaintext.txt`).
  - *Status*: PASS.

### 3.2 SOC Analyst Track (`soc`) Audit
- **`soc L3.6` (LOLBins)**:
  - *Audit*: Teaches identification of `certutil` and encoded PowerShell from Sysmon/audit logs. Evaluates static answer key.
  - *Status*: PASS.
- **`soc L5.1`–`L5.6` (Phishing & Malware Triage)**:
  - *Audit*: Email headers, redirect chains, and sandbox summaries use mock domains (`copperm1ne-billing.example`, `cdn.stonewick.example`) and require defanged answers (`[.]`).
  - *Status*: PASS.
- **`soc L6.1`–`L6.6` (Investigation & Escalation)**:
  - *Audit*: Incident bundles use synthetic Coppermine March event IDs (`CM-0311-*`). REPORT gates enforce defanged IOC forms.
  - *Status*: PASS.

---

## 4. Maintenance Rule
Any new or modified lesson containing obfuscation, LOLBins, network indicators, or script-block analysis must pass this 4-point checklist before merging.
