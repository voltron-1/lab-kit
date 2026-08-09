## BRIEF
Write escalation report `report.md` from pre-investigated findings (`files/findings.md`) using `files/ticket-template.md`.

All IOCs in `report.md` MUST be defanged (`hxxp://`, `[.]`). Any raw IOC (`http://`, raw IP/domain) will fail the check.

## GUIDED STEPS

1. Inspect `files/findings.md` and `files/ticket-template.md`.
2. Copy `files/ticket-template.md` to `report.md`:
   ```bash
   cp files/ticket-template.md report.md
   ```
3. Edit `report.md` to ensure all required sections, ATT&CK ID `T1059.001`, verdict `malicious`, and defanged IOCs are included.
4. Run `lab check soc L6.4`.
