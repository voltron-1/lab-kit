## BRIEF
This is the Phase 0 Exit Gate (`gate: true`).
In this lab, you apply the Coppermine SOC Standard Operating Procedures (`sop-excerpt.md`) to evaluate five alert cases (`cases.md`) and verify that all five analyst toolbelt utilities respond correctly.
You determine whether Tier 1 handles (`h`) or escalates (`e`) each alert case based on the charter's four escalation triggers.

## GUIDED STEPS

1. **Verify analyst toolbelt utilities**:
   Confirm that all five core analyst tools are installed and operational:
   ```bash
   jq --version
   tshark --version | head -1
   dig -v 2>&1
   whois --version
   rg --version | head -1
   ```

2. **Review SOP charter & escalation triggers**:
   Read `sop-excerpt.md` to understand Tier 1 duties, disposition codes (FP, BTP, TP), the four escalation triggers (a-d), and authorized background activity:
   ```bash
   cat sop-excerpt.md
   ```

3. **Evaluate alert cases (`cases.md`)**:
   Inspect the five alert cases in `cases.md`:
   ```bash
   cat cases.md
   ```

4. **Record disposition decisions**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Set each field to `h` (Tier 1 handles) or `e` (Tier 1 escalates):
   - `q1`: Password spray success + no-MFA sign-in (`e` — confirmed credential compromise)
   - `q2`: AV quarantined adware download, no execution (`h` — contained, Tier 1 close + education)
   - `q3`: Reported phish email with no click evidence (`h` — Tier 1 block ticket + IOC note)
   - `q4`: Unauthorized PsExec + new admin on DC01 (`e` — DC compromise, containment needed)
   - `q5`: Documented nightly 02:00Z `svc_backup` robocopy job (`h` — BTP, close with tuning note)

5. **Check your work**:
   ```bash
   lab check soc L0.3
   ```
