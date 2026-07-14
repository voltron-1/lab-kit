## BRIEF
One idea: the shell reads your line as text, splits it into words on
whitespace, then runs word 0 as the program with the rest as arguments.
The program never sees your spacing — only the finished word list.
Phase 1's map, stated once here: every line goes through a fixed
sequence — tokenize → expand → split → glob → execute — and Phase 1
walks that sequence lab by lab; today is the split and the run. Ships
`argv.sh`, a one-trick printer that shows the argv it received as
`<count>|<each-arg-in-angle-brackets>`. Honor line: the check can't tell
whether you predicted first — you're only cheating your own reps.

## GUIDED STEPS

1. `cd workspace/bash/L1.1` (seeded by `lab start bash L1.1`), then read
   the printer:

       cat argv.sh

   It reports `<count>|<each argument in angle brackets>` — for example,
   two args `a` and `b c` print `2|<a><b c>`.

2. Predict FIRST. Below are four sample lines, spacing exactly as shown.
   Do not run any of them yet.

       bash argv.sh hello world
       bash argv.sh hello      world
       bash argv.sh "hello   world"
       bash argv.sh

   Write all four predictions into `predictions.txt` before running
   anything — keys `p1=` through `p4=`, no spaces around `=`, each value
   the exact line you expect argv.sh to print.

3. Run each of the four lines above, one at a time. After each, compare
   the real line against your prediction. A mismatch means the mental
   model was wrong — fix the file AND note which split rule you missed.

4. The reveal demo (not graded):

       echo one     two

   Who collapsed the five spaces down to one? Answer beat: the shell
   split the line into the two words `one` and `two` before echo ever
   ran — echo merely joins its argv with single spaces. The collapse
   happened in the shell, not in echo, not in the terminal.

5. Grade it.

       lab check bash L1.1
