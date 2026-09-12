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
3. Investigate `files/case/`, then write `report.md` so it carries every section the
   template defines — scope, timeline, indicators, ATT&CK, verdict, recommendation —
   with the ATT&CK technique ids your evidence supports, at least one cited `cm-`
   event id, and every IOC defanged.
4. Run `lab check soc L6.6`.
