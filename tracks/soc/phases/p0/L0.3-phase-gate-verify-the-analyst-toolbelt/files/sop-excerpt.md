# Coppermine Logistics SOC Standard Operating Procedures (SOP Excerpt)

## 1. SOC Tier Responsibilities
- **Tier 1 (Triage & Incident Intake)**: Responsible for initial alert intake, triage, disposition (FP/BTP vs TP), initial scoping, ticketing, and submitting detection tuning requests.
- **Tier 2 (Incident Response & Investigation)**: Responsible for deep host/network investigation, threat containment, host isolation, remediation, and active threat eradication.
- **Tier 3 (Threat Hunting & Detection Engineering)**: Responsible for proactive threat hunting, developing custom detection rules, and analyzing advanced adversary TTPs.

## 2. Alert Triage Lifecycle
Alerts progress strictly through the following lifecycle stages:
`New` → `Triage` → `Disposition` → `Containment / Remediation`

Possible Dispositions:
- **False Positive (FP)**: Rule misfired on benign or unexpected activity.
- **Benign True Positive (BTP)**: Rule fired accurately on real behavior, but the activity is legitimate and authorized.
- **True Positive (TP)**: Confirmed security incident requiring escalation or containment.

## 3. Escalation Triggers (Tier 1 → Tier 2)
Tier 1 analysts MUST escalate an alert to Tier 2 if ANY of the following triggers are met:
a. **Confirmed Host or Service Compromise**: Unapproved code execution, backdoor installation, or active C2 beaconing.
b. **Multi-Host Scope**: Security activity impacting or spreading across more than one endpoint or server.
c. **Confirmed Credential Compromise**: Successful authentication using compromised or stolen user credentials.
d. **Containment Authority Needed**: Incident response requires actions outside Tier 1 authority (e.g. host isolation, revoking admin privileges, blocking domain controllers).

## 4. Documented Authorized Activity
The following recurring activities are authorized and pre-approved:
- **Nightly Backup Job**: `SRV-BACKUP` (10.20.10.9) executes a `robocopy.exe` SMB backup to `FS01` (10.20.10.8) daily at 02:00Z under account `svc_backup`.
- **Scheduled Administrative Maintenance**: Account `t.aoki` is authorized to use administrative tools (e.g. PsExec, RDP) ONLY during approved Change Control windows (e.g., `CHG-2143` on Tuesday 2026-03-10 10:00Z). Any administrative tool usage outside approved CHG tickets is unauthorized.
