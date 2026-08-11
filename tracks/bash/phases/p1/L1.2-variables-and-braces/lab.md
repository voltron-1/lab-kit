## BRIEF
One concept: `$name` is replaced by its text BEFORE anything runs. After
`$` the shell takes the LONGEST run of identifier characters (letters,
digits, underscore) as the name; `${…}` draws the boundary yourself.
Assignment is `name=value` with NO spaces — add spaces and it stops
being an assignment at all. One preview, fully covered in L1.4: single
quotes suppress expansion entirely, so `'$v'` stays the literal text
`$v` — nothing, ever, no matter what `$v` would otherwise expand to.
Honor line (once, verbatim): "the check can't tell whether you
predicted first — you're only cheating your own reps."

## GUIDED STEPS

1. `cd workspace/bash/L1.2` then `ls` → `argv.sh`. Contract reminder:
   `bash argv.sh a "b c"` → `2|<a><b c>`; zero arguments → `0|`.

2. Read the four items below — never run them yet.

       bash argv.sh $v
       bash argv.sh ${v}wide
       bash argv.sh $vwide

   p4 (multiple choice): what does `v = world` (with spaces) do?
   a) assigns `world` to `v`
   b) runs a command named `v` with arguments `=` and `world` →
      "command not found"
   c) syntax error, nothing runs

3. Write ALL FOUR predictions into `predictions.txt` BEFORE running
   anything — keys `p1=` through `p4=`, no spaces around `=`. p1–p3 take
   the full argv.sh output line; p4 takes a single letter (a, b, or c).

4. `v=world` — one assignment, reused by every following line.

5. `bash argv.sh $v` — compare against your p1.

6. `bash argv.sh ${v}wide` — compare against your p2.

7. `bash argv.sh $vwide` — compare against your p3. Where did the
   argument go?

8. The p4 reveal:

       v = world
       echo $?

   Watch what the shell tried to do.

9. Correct any missed key in `predictions.txt` to the observed truth —
   the miss is the lesson; the file records what actually ran.

10. `lab check bash L1.2`
