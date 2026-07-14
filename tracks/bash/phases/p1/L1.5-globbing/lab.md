## BRIEF
Globbing (pathname expansion) turns `*`, `?`, and `[...]` into filenames
that actually exist in the current directory. It runs LAST — after
variable expansion and word splitting — and only on unquoted words. A
pattern that matches nothing stays literal (bash default; `nullglob`
exists to drop it instead, off by default). `*` never recurses into
subdirectories and skips dotfiles; `?` matches exactly one character.
Honor line (mandatory): "the check can't tell whether you predicted
first — you're only cheating your own reps."

## GUIDED STEPS

1. `ls` — take inventory BEFORE predicting. Expect (one per line when
   piped; your terminal shows columns):

       app.conf
       app.log
       argv.sh
       error.log
       notes.txt
       sub

   Note `sub` is a directory; `readme.md` hides inside it.

2. Write all six predictions into `predictions.txt` — keys `p1=` … `p6=`,
   no spaces around `=`, each value the FULL line argv.sh will print.
   Saving this file adds `predictions.txt` to the directory — count it
   when you walk each pattern (none of today's six patterns matches it,
   by design). The six sample lines:

       bash argv.sh *.log
       bash argv.sh app.*
       bash argv.sh *.md
       bash argv.sh [ae]*
       pat="*.log"; bash argv.sh $pat
       bash argv.sh "$pat"

3. `bash argv.sh *.log`

4. `bash argv.sh app.*`

5. `bash argv.sh *.md`

6. `bash argv.sh [ae]*`

7. `pat="*.log"; bash argv.sh $pat`

8. `bash argv.sh "$pat"` — same shell, `pat` is still set.

9. Compare each real line against your prediction; correct any misses in
   `predictions.txt` (the rep was the prediction — the grade needs the
   true lines). Then: `lab check bash L1.5`
