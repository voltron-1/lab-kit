## BRIEF
Analyze `files/urls.txt` to follow redirect chains, spot lookalikes/punycode, and practice defang discipline.

## GUIDED STEPS

1. Inspect `files/urls.txt` and `files/url-legend.md`.
2. Copy `files/answers.template.txt` to `answers.txt`.
3. Fill `answers.txt`:
   - `q1`: Final landing domain of redirect chain (DEFANGED) -> `cdn.stonewick[.]example`
   - `q2`: Digit-homoglyph lookalike domain (DEFANGED) -> `copperm1ne-billing[.]example`
   - `q3`: Decoded punycode domain label (DEFANGED) -> `coppermïne[.]example`
   - `q4`: Real benign Coppermine domain (DEFANGED) -> `coppermine[.]example`
   - `q5`: Number of hops in redirect chain (integer) -> `3`
4. Run `lab check soc L5.2`.
