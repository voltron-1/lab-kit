## BRIEF
Every Tier 1 triage follows five questions:
1. **What FIRED?** (The rule ID)
2. **What is the EVIDENCE?** (The deciding event ID)
3. **Is it EXPECTED?** (User/host role & context — y/n)
4. **What is the SCOPE?** (Count of affected hosts)
5. **What is the VERDICT?** (tp | fp | btp)

Run these five questions in order on `files/alert.json` and `files/events.jsonl`.

## GUIDED STEPS

1. Inspect `files/alert.json`, `files/events.jsonl`, and `files/asset-inventory.csv`.
2. Copy `files/answers.template.txt` to `answers.txt`:
   ```bash
   cp files/answers.template.txt answers.txt
   ```
3. Fill `answers.txt`:
   - `q1`: Rule ID -> `cm-r-0159`
   - `q2`: Event ID for process creation -> `cm-0311-0201`
   - `q3`: Expected for m.reyes on workstation? -> `n`
   - `q4`: Scope count -> `1`
   - `q5`: Verdict -> `tp`
4. Run `lab check soc L4.1`.
