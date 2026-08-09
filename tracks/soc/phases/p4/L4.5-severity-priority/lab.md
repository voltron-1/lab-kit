## BRIEF
Severity is static rule badness. Priority is what YOU work first: `priority = f(severity, asset criticality, confidence)`.

Apply the formula in `files/priority-formula.md` to assign a tier (`p1`, `p2`, `p3`) to all 10 alerts in `files/queue.json`.

## GUIDED STEPS

1. Inspect `files/queue.json`, `files/asset-inventory.csv`, and `files/priority-formula.md`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`:
   - `q1`: CM-A-401 -> `p1`
   - `q2`: CM-A-402 -> `p1`
   - `q3`: CM-A-403 -> `p1`
   - `q4`: CM-A-404 -> `p3`
   - `q5`: CM-A-405 -> `p3`
   - `q6`: CM-A-406 -> `p2`
   - `q7`: CM-A-407 -> `p2`
   - `q8`: CM-A-408 -> `p3`
   - `q9`: CM-A-409 -> `p2`
   - `q10`: CM-A-410 -> `p3`
4. Run `lab check soc L4.5`.
