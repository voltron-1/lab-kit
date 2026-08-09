## BRIEF
Password spray = one password across MANY accounts (low and slow).
Brute force = MANY passwords against ONE account.

Analyze `files/auth-events.jsonl` to tell them apart by shape.

## GUIDED STEPS

1. Inspect `files/auth-events.jsonl`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`:
   - `q1`: 203.0.113.66 attack type (brute|spray) -> `spray`
   - `q2`: 198.51.100.71 attack type (brute|spray) -> `brute`
   - `q3`: Single account targeted by brute force -> `svc_web`
   - `q4`: Distinct accounts targeted by spray (integer) -> `40`
   - `q5`: Verdict for the brute force burst that succeeded (tp|fp|btp) -> `tp`
   - `q6`: Source IP of the spray (DEFANGED) -> `203.0.113[.]66`
4. Run `lab check soc L4.4`.
