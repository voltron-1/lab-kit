## BRIEF
Recognize FP/BTP from noisy rules and authorized admin behavior, and write precise tuning exclusions (`field:value`).

## GUIDED STEPS

1. Inspect `files/case1/` through `files/case4/`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`:
   - `q1`: case1 verdict -> `btp`
   - `q1t`: case1 tuning exclusion -> `host:srv-backup`
   - `q2`: case2 verdict -> `btp`
   - `q2t`: case2 tuning exclusion -> `user:t.aoki`
   - `q3`: case3 verdict -> `fp`
   - `q3t`: case3 tuning exclusion -> `path:securityawareness`
   - `q4`: case4 verdict -> `tp`
   - `q4t`: case4 tuning exclusion -> `none`
4. Run `lab check soc L4.6`.
