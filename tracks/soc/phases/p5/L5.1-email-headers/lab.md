## BRIEF
Analyze `files/reported.eml` headers to trace the originating IP and check authentication alignment.

## GUIDED STEPS

1. Inspect `files/reported.eml` and `files/header-legend.md`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`:
   - `q1`: Originating IP (bottom Received hop, DEFANGED) -> `198.51.100[.]71`
   - `q2`: SPF result (pass|fail|softfail|none) -> `fail`
   - `q3`: DKIM result -> `fail`
   - `q4`: DMARC result -> `fail`
   - `q5`: From domain (DEFANGED) -> `copperm1ne-billing[.]example`
   - `q6`: Does Return-Path domain align with From domain? (y|n) -> `n`
4. Run `lab check soc L5.1`.
