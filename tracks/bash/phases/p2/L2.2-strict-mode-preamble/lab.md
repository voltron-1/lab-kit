## BRIEF
The most important lab in the phase. Understanding `set -euo pipefail`
"is the difference between 'the script ran' and 'the script did what it
claimed.'" Each flag is demonstrated in isolation: a small flawed script
per flag, run plain (before) and then with just that one flag added on
the command line (after) — the only difference between the two runs is
the flag itself. `hardened.sh` then proves the in-script `set -euo
pipefail` line behaves identically to the command-line form. `-e` fails
on error, `-u` fails on unset variables, `-o pipefail` fails a pipeline
on ANY stage's death, not just the last.

## GUIDED STEPS

1. Read the lie-in-waiting, then run pair 1 (the `-e` flag):

       cat e-demo.sh

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   # e-demo.sh — back up the report, then declare victory.
   cp report.txt backup.txt
   echo "backup complete"
   ```

   `report.txt` does not exist in this workspace — its absence IS the
   failure.

       bash e-demo.sh > e-off.txt 2>&1; echo "exit=$?" >> e-off.txt
       cat e-off.txt

   expect:

       cp: cannot stat 'report.txt': No such file or directory
       backup complete
       exit=0

   Read that: the backup does not exist, the script said "backup
   complete" anyway, and the exit code (0) agrees with the lie.

       bash -e e-demo.sh > e-on.txt 2>&1; echo "exit=$?" >> e-on.txt
       cat e-on.txt

   expect:

       cp: cannot stat 'report.txt': No such file or directory
       exit=1

   With `-e`, the script died at the first failing command — no
   "backup complete", exit code 1, cp's own code.

2. Pair 2 (the `-u` flag) — a typo hiding in plain sight:

       cat u-demo.sh

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   # u-demo.sh — clean the release staging path.
   release_dir="v2"
   echo "cleaning staging/$relaese_dir"
   ```

       bash u-demo.sh > u-off.txt 2>&1; echo "exit=$?" >> u-off.txt
       cat u-off.txt

   expect:

       cleaning staging/
       exit=0

   The typo'd `$relaese_dir` expanded to NOTHING (L1.2's "silently
   became nothing") — the script "cleaned" a different path than
   anyone intended. This is the exact mechanism that turns
   `rm -rf "$DIR/"` into a catastrophe (detonated properly in Phase 3,
   L3.2).

       bash -u u-demo.sh > u-on.txt 2>&1; echo "exit=$?" >> u-on.txt
       cat u-on.txt

   expect:

       u-demo.sh: line 5: relaese_dir: unbound variable
       exit=1

   With `-u`, the typo is fatal, named, and line-numbered.

3. Pair 3 (`pipefail`) — before rerunning, ask yourself: if this
   number landed in your triage queue, would you trust it?

       cat p-demo.sh

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   # p-demo.sh — count GET requests in the web log.
   grep GET requests.log | wc -l
   ```

       bash p-demo.sh > p-off.txt 2>&1; echo "exit=$?" >> p-off.txt
       cat p-off.txt

   expect:

       grep: requests.log: No such file or directory
       0
       exit=0

   `wc` still prints `0` — a plausible-looking "zero GET requests
   today," manufactured by a dead pipeline. wc never knew grep failed;
   the pipeline's exit code is the LAST command's (wc's 0), so grep's
   death vanished.

       bash -o pipefail p-demo.sh > p-on.txt 2>&1; echo "exit=$?" >> p-on.txt
       cat p-on.txt

   expect:

       grep: requests.log: No such file or directory
       0
       exit=2

   Identical output — pipefail changes the VERDICT, not the data flow
   — but now the exit code is grep's own (2), the rightmost failure in
   the pipe.

4. The in-script form — same switches, carried inside the file:

       bash hardened.sh; echo $?

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   # hardened.sh — e-demo.sh with the preamble in place.
   cp report.txt backup.txt
   echo "backup complete"
   ```

   expect:

       cp: cannot stat 'report.txt': No such file or directory
       1

   Identical to `bash -e e-demo.sh` — the command-line flags and the
   `set` line are the same switches; scripts carry the line so every
   caller gets the protection.

5. Your co-pilot vouches for the liar:

       shellcheck e-demo.sh

   expect: nothing — exit 0. Missing strict mode is a runtime-behavior
   gap, not a syntax pattern; no SC code exists for "you forgot set
   -e." Only strict mode, at run time, catches it.

6. One boundary worth knowing before you rely on `-e` everywhere: a
   command tested by `if`/`while`/`&&`/`||` is EXEMPT from it — `if
   grep -q ERROR nofile.txt; then …; fi` under `set -euo pipefail`
   still prints grep's error and keeps going. `-e` guards statements,
   not conditions. (This is why L2.4's `cmd || true` idiom exists.)

7. One more boundary: this exact preamble line doesn't survive a shell
   swap. Run it under dash (L0.3's other shell):

       dash -c 'set -euo pipefail'; echo "exit=$?"

   expect:

       dash: 1: set: Illegal option -o pipefail
       exit=2

   `-e` and `-u` are POSIX and dash accepts them; `-o pipefail` is a
   bash-only extension — dash doesn't even recognize the option and
   aborts immediately, before your script's first real line runs.

8. Write `answers.txt` — one `key=value` per line, no spaces around
   `=`:

   q1 (choice). In `set -euo pipefail`, what is the `o`?
   a) a flag named o, enabling "option mode"
   b) it makes set read the NEXT word as an option name — the line is
      set -e, set -u, set -o pipefail in one breath
   c) shorthand for output

   q2 (choice). Which flag turns u-demo.sh's typo into a hard stop?
   a) -e
   b) pipefail
   c) -u

   q3 (choice). Without pipefail, `grep GET requests.log | wc -l`
   exits with…
   a) the last command's code — wc's 0, so grep's death vanishes
   b) the leftmost failure's code
   c) 1 whenever anything in the pipe fails

   q4 (choice). Under set -e, a command that fails inside
   `if <cmd>; then`…
   a) kills the script anyway
   b) does NOT kill the script — commands tested by if/while/&&/|| are
      exempt from -e
   c) prints a warning and continues

9. `lab check bash L2.2`
