## BRIEF
`lab start` stages all evidence files and `answers.template.txt` directly into `workspace/soc/L0.2/`.
In this lab, you explore the Coppermine evidence pack layout, inspect a SIEM alert (`alert-sample.json`), pivot to raw log events (`events.jsonl`), practice defang discipline, and record your findings in `answers.txt`.

## GUIDED STEPS

1. **Read `README-evidence.md`**:
   View the evidence pack documentation:
   ```bash
   cat README-evidence.md
   ```

2. **Inspect the SIEM alert (`alert-sample.json`)**:
   Examine the alert's rule metadata and evidence citations:
   ```bash
   jq '.rule' alert-sample.json
   jq -r '.evidence.event_ids[]' alert-sample.json
   ```

3. **Pivot to raw log events (`events.jsonl`)**:
   Search for the cited event IDs in `events.jsonl`:
   ```bash
   grep -E 'CM-0311-0107|CM-0311-0111' events.jsonl
   ```

4. **Prepare `answers.txt`**:
   Copy the answers template:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each field in `answers.txt`:
   - `q1`: Rule ID of the staged alert (`cm-r-0112`)
   - `q2`: Event ID of the FIRST cited evidence event (`cm-0311-0107`)
   - `q3`: Defanged form of `c2.stonewick.example` (`c2.stonewick[.]example`)
   - `q4`: Staged workspace destination path (`workspace/soc/l0.2`)

5. **Check your work**:
   ```bash
   lab check soc L0.2
   ```
