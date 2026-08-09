## BRIEF
Verdict a sample safely by reading its sandbox detonation report (`files/sandbox-report.json` / `files/sandbox-report.md`).

## GUIDED STEPS

1. Inspect `files/sandbox-report.md`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`:
   - `q1`: Report's verdict (malicious|suspicious|clean) -> `malicious`
   - `q2`: C2 destination host beaconed to (DEFANGED) -> `c2.stonewick[.]example`
   - `q3`: ATT&CK technique ID for spearphishing attachment -> `t1566.001`
   - `q4`: Dropped Run key leaf name -> `onedriveupd`
   - `q5`: Can you verdict this WITHOUT executing the sample? (y|n) -> `y`
4. Run `lab check soc L5.4`.
