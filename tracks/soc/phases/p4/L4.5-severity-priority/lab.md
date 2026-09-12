## BRIEF
Severity is static rule badness. Priority is what YOU work first: `priority = f(severity, asset criticality, confidence)`.

Apply the formula in `files/priority-formula.md` to assign a tier (`p1`, `p2`, `p3`) to all 10 alerts in `files/queue.json`.

## GUIDED STEPS

1. Inspect `files/queue.json`, `files/asset-inventory.csv`, and `files/priority-formula.md`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`. Every line in the template names exactly what it wants —
   answer each one from the evidence above.
4. Run `lab check soc L4.5`.
