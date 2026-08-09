## BRIEF
Apply the grounding contract to 5 claims in `files/ai-summary.md`. Flag grounded vs flawed claims, flaw types, and the hallucinated event ID.

## GUIDED STEPS

1. Inspect `files/ai-summary.md` and `files/evidence/`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`:
   - `q1`: grounded
   - `q2`: flawed | `q2f`: hallucinated
   - `q3`: grounded
   - `q4`: flawed | `q4f`: wrongpivot
   - `q5`: flawed | `q5f`: ungrounded
   - `q_hall`: `cm-9999-9999`
4. Run `lab check soc L7.4`.
