## BRIEF
Pivot from user `m.reyes` in `files/case/` to uncover the full compromise chain across hosts, processes, network, and lateral movement.

## GUIDED STEPS

1. Inspect `files/starting-indicator.txt` and `files/case/`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`:
   - `q1`: Host m.reyes's session landed on -> `wks-acct-07`
   - `q2`: Event ID of malicious process spawn on wks-acct-07 -> `cm-0311-0201`
   - `q3`: C2 destination host beaconed to (DEFANGED) -> `c2.stonewick[.]example`
   - `q4`: Persistence Run key leaf name -> `onedriveupd`
   - `q5`: Next host reached via compromised account -> `fs01`
   - `q6`: Event ID of rogue admin creation on fs01 -> `cm-0311-0244`
4. Run `lab check soc L6.1`.
