## BRIEF
This is THE #1 Bash bug — the map says so. After `$var` expands, the
*result* is split on whitespace, so one variable can become several
words and a program receives arguments its caller never intended.
Map's security hook, quoted in spirit: "a filename with a space, a
newline, or a leading dash silently changes what a command does —
you'll meet it here and hunt it for the rest of the course." Honor
line (once, in BRIEF): "the check can't tell whether you predicted
first — you're only cheating your own reps."

## GUIDED STEPS

1. `f="report final.txt"` — one variable holding ONE string with a space
   in it (assignments are never word-split).

2. Write ALL predictions into `predictions.txt` before running anything —
   `p1=`/`p2=` take the full `N|<...>` argv.sh line, `p3=`/`p5=` take a
   single letter.

   p3 (choice): `cp $f backup/` — what happens?
   a) copies the file
   b) cp is handed TWO source names, `report` and `final.txt` — neither
      exists → two "cannot stat" errors
   c) shell syntax error

   p5 (choice): `bash argv.sh $opt` prints `1|<-n>` — the shell
   delivered exactly one word. So `echo $opt` prints…?
   a) `-n`
   b) nothing — echo parsed its argument as an option
   c) `$opt`

3. `bash argv.sh $f` — compare against p1.

4. `bash argv.sh "$f"` — compare against p2.

5. `cp $f backup/` — read both error lines; compare against p3.

6. `cp "$f" backup/` — silence is success.

7. `ls backup` — the artifact proves the quoted copy worked (a tty shows
   `'report final.txt'` — ls warning you the name has a space).

8. `opt=-n`

9. `bash argv.sh $opt` — this prints `1|<-n>`: the shell handed over
   exactly one word.

10. `echo $opt` — compare against p5.

11. `echo "$opt"` — identical result: same argv, so quoting can't fix
    option parsing. One sentence to carry forward: a dash-word turning
    into an option is argument-injection territory, formalized with the
    `--` guard in Phases 3–4.

12. `lab check bash L1.3`
