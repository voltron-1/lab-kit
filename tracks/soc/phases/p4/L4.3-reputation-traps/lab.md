## BRIEF
Reputation scores can mislead when indicators sit on shared hosting, CDN infrastructure, or carry stale scores. Evidence overrides the reputation score.

## GUIDED STEPS

1. Inspect `files/case1/`, `files/case2/`, `files/case3/`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`:
   - `q1`: case1 verdict (tp|fp|btp) -> `fp`
   - `q1t`: case1 trap (sharedhosting|cdn|stale) -> `sharedhosting`
   - `q2`: case2 verdict -> `fp`
   - `q2t`: case2 trap -> `cdn`
   - `q3`: case3 verdict -> `fp`
   - `q3t`: case3 trap -> `stale`
4. Verify with `lab check soc L4.3`.
