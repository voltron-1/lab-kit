## BRIEF
A pipe (`|`) runs each side as a separate process — the right-hand side of
`cmd | while read …; done` is a **subshell**, a child process whose
variable changes vanish the instant it exits. Process substitution
(`< <(cmd)`) is different: it just redirects input, so the `while` loop
stays in your **current shell** and its variables survive. Same three
lines counted, same loop body — one form remembers, one forgets. Honor
line verbatim: "the check can't tell whether you predicted first — you're
only cheating your own reps."

## GUIDED STEPS

1. Read the script — do not run it yet:

       cat counter.sh

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — the SC2030/SC2031 warnings below ARE the lesson
   # counter.sh — count three lines two ways. Predict each 'count=' BEFORE running.

   count=0
   printf 'x\ny\nz\n' | while read -r _; do
     count=$((count + 1))
   done
   echo "pipe:  count=$count"          # <-- PREDICT this

   count=0
   while read -r _; do
     count=$((count + 1))
   done < <(printf 'x\ny\nz\n')
   echo "procsub: count=$count"        # <-- PREDICT this
   ```

   Both blocks count the same three lines (`x`, `y`, `z`) the same way.
   The only difference is *how* the loop receives its input: a pipe
   (first block) versus a process substitution (second block).

2. Before running anything, write your predictions to `predictions.txt`:

       pipe=<your guess: 0 or 3>
       procsub=<your guess: 0 or 3>
       why=<one line: why do the two forms differ?>

3. Check what ShellCheck says about the pipe form — read it before you
   run the script:

       shellcheck counter.sh

   Two warnings fire on the pipe block: **SC2030** on the `count=$((count
   + 1))` line inside it, and **SC2031** on the `echo` line right after.
   **These are the lesson, not noise** — read what each one is telling
   you about where `count` lives. This is the one footgun in this phase
   where the SC warning IS the point (L3.8 comes back to this).

4. Now run it and compare against your predictions:

       bash counter.sh

   Compare both lines of output against what you wrote in step 2 — did
   the pipe form and the process-substitution form agree with your
   guesses?

5. Update `predictions.txt` to reflect what you actually observed, plus
   the one-line `why=` naming the mechanism (not just the symptom):

       pipe=<what you actually saw>
       procsub=<what you actually saw>
       why=<one line: why did the two forms disagree?>

6. `lab check bash L3.6`
