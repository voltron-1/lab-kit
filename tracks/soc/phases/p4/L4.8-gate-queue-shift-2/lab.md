## BRIEF
Work a 10-alert fresh queue: verdict each, cite evidence for TPs, and set `qNesc=y` on the EXACT ONE alert that qualifies for escalation under `files/escalation-criteria.md`.

## GUIDED STEPS

1. Inspect `files/queue.json` and `files/escalation-criteria.md`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`:
   - `q1=tp`, `q1e=cm-0311-0142`, `q1esc=n`
   - `q2=btp`, `q2esc=n`
   - `q3=tp`, `q3e=cm-0312-0310`, `q3esc=n`
   - `q4=fp`, `q4esc=n`
   - `q5=tp`, `q5e=cm-0311-0715`, `q5esc=y`  <-- ESCALATION TARGET
   - `q6=btp`, `q6esc=n`
   - `q7=fp`, `q7esc=n`
   - `q8=tp`, `q8e=cm-0311-0201`, `q8esc=n`
   - `q9=fp`, `q9esc=n`
   - `q10=tp`, `q10e=cm-0311-0181`, `q10esc=n`
4. Run `lab check soc L4.8`.
