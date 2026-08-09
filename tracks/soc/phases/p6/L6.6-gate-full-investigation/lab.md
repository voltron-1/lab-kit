## BRIEF
Investigate `files/alert.json` and produce full escalation `report.md` using `files/escalation-template.md`.

All IOCs in `report.md` MUST be defanged (`hxxp://`, `[.]`). Any raw IOC (`http://`, raw IP/domain) will fail the check.
Your timeline section MUST cite at least one event ID starting with `cm-`.

## GUIDED STEPS

1. Inspect `files/alert.json`, `files/case/`, and `files/escalation-template.md`.
2. Copy `files/escalation-template.md` to `report.md`:
   ```bash
   cp files/escalation-template.md report.md
   ```
3. Edit `report.md` to ensure all required sections, ATT&CK ID `T1059.001`, verdict `malicious`, cited event ID (`cm-0311-0142`), and defanged IOCs are included.
4. Run `lab check soc L6.6`.
