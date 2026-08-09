## BRIEF
Write the complete terminal capstone report `report.md` using `files/report-template.md`. Include all standard sections plus `## Tuning Recommendation` containing a `field:value` exclusion string (e.g. `cmdline:winword->powershell`).

All IOCs MUST be defanged (`hxxp://`, `[.]`). Any raw IOC will fail the check.
Your timeline section MUST cite at least one event ID starting with `cm-`.

## GUIDED STEPS

1. Inspect `files/report-template.md`.
2. Copy `files/report-template.md` to `report.md`:
   ```bash
   cp files/report-template.md report.md
   ```
3. Edit `report.md` to ensure all required sections, ATT&CK ID `T1059.001`, verdict `malicious`, cited event ID (`cm-0311-0201`), defanged IOCs, and tuning recommendation (`cmdline:winword->powershell`) are included.
4. Run `lab check soc L7.7`.
