## BRIEF
Verify three AI triage summaries against raw evidence in `files/`. Identify the flawed summary and its contradicting event ID.

## GUIDED STEPS

1. Inspect `files/summary1`, `files/summary2`, and `files/summary3`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`:
   - `q1`: Summary 1 verdict -> `grounded`
   - `q2`: Summary 2 verdict -> `flawed`
   - `q2f`: Summary 2 flaw type -> `contradicted`
   - `q2e`: Event ID that contradicts summary 2 -> `cm-0311-0181`
   - `q3`: Summary 3 verdict -> `grounded`
4. Run `lab check soc L7.2`.
