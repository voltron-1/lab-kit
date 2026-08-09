## BRIEF
Investigate `files/reported.eml` end to end and produce `report.md` using `files/report-template.md`.

All IOCs in `report.md` MUST be defanged (`hxxp://`, `[.]`). Any raw IOC (`http://`, raw IP/domain) will fail the check.

## GUIDED STEPS

1. Inspect `files/reported.eml`, `files/sandbox-report.md`, and `files/report-template.md`.
2. Create `report.md` by copying `files/report-template.md`:
   ```bash
   cp files/report-template.md report.md
   ```
3. Edit `report.md` to ensure all required sections, ATT&CK ID `T1566.001`, verdict `malicious`, and defanged IOCs are included.
4. Run `lab check soc L5.6`.
