## BRIEF
`&&` runs its right side only after success; `||` only after failure —
both read `$?` (L1.6's verdict, wired directly into flow). They are
equal-precedence and left-associative, so `a && b || c` is NOT
if/else: `c` also fires when `a` succeeded but `b` failed. The guard
idiom `cmd || exit 1` is how scripts refuse to continue past a
failure. Safety line: never type `… || exit` at your interactive
prompt — if the left side fails, it exits YOUR SHELL; that's why the
exit samples live in `guard.sh`. The check can't tell whether you
predicted first — you're only cheating your own reps.

## GUIDED STEPS

1. Below are four sample lines. Write ALL SIX predictions into
   `predictions.txt` before running anything — keys `p1=` through
   `p6=`, no spaces around `=`. `p1`, `p2`, `p3`, `p6` are exact
   output lines; `p5` is a digit; `p4` is a letter (options below).

       false && echo up; echo "rc=$?"
       false || echo fallback
       true && false || echo recovered
       echo one && false && echo two || echo three

   p4 (choice). Which lines does the fourth sample print?
   a) `one` `two` `three`
   b) `one` then `three`
   c) only `three`

2. Run the four lines above, one at a time, comparing each against
   your prediction.

3. Read the guard idiom (do not run it yet from a bare prompt — see
   the BRIEF's safety line):

       cat guard.sh

   ```bash
   #!/usr/bin/env bash
   # guard.sh — refuse to continue if the deploy dir is missing.
   cd deploy_dir || exit 1
   echo "deploying from $(basename "$(pwd)")"
   ```

4. Run p5 (`deploy_dir` does not exist yet):

       bash guard.sh; echo $?

   Then create the directory and run p6:

       mkdir deploy_dir
       bash guard.sh

5. Correct any missed key in `predictions.txt` to the observed truth,
   then:

       lab check bash L2.4
