## BRIEF
Determine the distinct host count for the C2 beacon vs the overall intrusion scope.

## GUIDED STEPS

1. Inspect files in `files/`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`:
   - `q1`: Number of hosts beaconing to C2 IP (integer) -> `1`
   - `q2`: Host beaconing to C2 -> `wks-acct-07`
   - `q3`: Number of distinct hosts involved in the whole intrusion (integer) -> `4`
   - `q4`: Comma-joined sorted host list -> `fs01,web01,wks-acct-07,wks-eng-12`
   - `q5`: Is C2 beacon contained to one host or spread? (contained|spread) -> `contained`
4. Run `lab check soc L6.3`.
