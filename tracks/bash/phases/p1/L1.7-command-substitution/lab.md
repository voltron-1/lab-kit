## BRIEF
`$(cmd)` runs cmd and replaces itself with cmd's stdout, trailing
newlines stripped — then the normal expansion rules resume: unquoted,
the result word-splits (L1.3's bug wearing a new mask); double-quoted,
it stays one word. Nested substitutions read inside-out, innermost
first. Only stdout is captured — stderr goes to your terminal and `$?`
carries the exit code. Backticks (`` `cmd` ``) are the older syntax for
this exact same feature — same capture, same current-shell execution,
not a subshell — but nesting them requires escaping the inner
backticks, where `$(cmd)` nests plainly; prefer `$(cmd)`. Honor line
verbatim: "the check can't tell whether you predicted first — you're
only cheating your own reps."

## GUIDED STEPS

1. Inspect the inputs (not graded sample lines — exact bytes are needed
   to predict):

       cat version.txt
       cat servers.txt

   `version.txt` holds `2.4.1`. `servers.txt` holds `web01 web02` (one
   space between the names).

2. Write ALL five predictions into `predictions.txt` BEFORE running any
   sample line — keys `p1`…`p5`, no spaces around `=`; p1–p4 take the
   full output line in the `N|<...>` format, p5 takes a letter. Five
   sample lines:

       bash argv.sh $(cat version.txt)
       bash argv.sh $(cat servers.txt)
       bash argv.sh "$(cat servers.txt)"
       bash argv.sh $(basename $(pwd))

   p5 — conceptual choice. `missing.txt` does not exist. You run:
   `v=$(cat missing.txt)` — what happens?
   a) v gets the literal text "cat: missing.txt: No such file or
      directory"
   b) cat's error prints to YOUR terminal (stderr is not captured); v is
      empty; `$?` is cat's exit code 1
   c) the shell aborts with an error

3. Run p1: `bash argv.sh $(cat version.txt)` — compare.

4. Run p2: `bash argv.sh $(cat servers.txt)` — compare; count the argv
   words.

5. Run p3: `bash argv.sh "$(cat servers.txt)"` — compare against p2.

6. Run p4: `bash argv.sh $(basename $(pwd))` — read it inside-out before
   running: the inner `$(pwd)` runs FIRST, then `basename` trims it to
   the workspace directory name.

7. Run the p5 transcript one line at a time:

       v=$(cat missing.txt)
       echo $?
       bash argv.sh $v

   Watch which stream carried the error and how many words `$v`
   produced.

8. `lab check bash L1.7`
