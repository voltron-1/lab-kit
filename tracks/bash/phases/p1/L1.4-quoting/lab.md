## BRIEF
One question decides every quoting choice: *what do you want expanded?*
Single quotes: nothing, ever. Double quotes: `$` expands, but the result
stays one word — no splitting, no globbing. Bare: expand, then split,
then glob. Five one-line experiments against argv.sh, one variable
(`user=root`), and the decision rule falls out. Honor line verbatim:
"the check can't tell whether you predicted first — you're only
cheating your own reps."

## GUIDED STEPS

1. `lab start bash L1.4` seeded `argv.sh`. Contract reminder:
   `bash argv.sh a "b c"` → `2|<a><b c>`.

2. `user=root` — set the variable in THIS shell; every sample line runs
   in the same session. Troubleshooting note: if any run prints `1|<>`,
   you forgot this step in the current shell.

3. Before running anything, write all five predictions into
   `predictions.txt`: keys `p1=` through `p5=`, no spaces around `=`,
   each value the exact line argv.sh will print. Five sample lines:

       bash argv.sh '$user'
       bash argv.sh "$user"
       bash argv.sh "phase $user"
       bash argv.sh phase $user
       bash argv.sh "'$user'"

4. Run sample line 1: `bash argv.sh '$user'`. Compare against your p1.

5. Run sample line 2: `bash argv.sh "$user"`. Compare against your p2.

6. Run sample line 3: `bash argv.sh "phase $user"`. Compare against your
   p3.

7. Run sample line 4: `bash argv.sh phase $user`. Compare against your
   p4.

8. Run sample line 5: `bash argv.sh "'$user'"`. Compare against your p5.

9. Where you missed, correct `predictions.txt` to the observed line — the
   run is the legitimate answer source; the miss is the lesson (honor
   system).

10. Read the decision table — this lab's takeaway:

    | you want | reach for |
    |---|---|
    | the literal characters, zero expansion | single quotes |
    | expansion, delivered as exactly one word | double quotes — the default |
    | expansion PLUS the shell splitting/globbing the result | bare — rare, deliberate; say why in a comment |

    Phase rule, restating L1.3's reflex: **default to double quotes
    around every expansion.** Single quotes when you mean "no expansion
    at all." Bare is not a non-choice — it is a request for splitting and
    globbing, and it should look intentional.

11. `lab check bash L1.4`.
