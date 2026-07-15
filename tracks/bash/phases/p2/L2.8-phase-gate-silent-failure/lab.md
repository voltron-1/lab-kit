## BRIEF
Integration, nothing new. The bug is hidden by the ABSENCE of L2.2's
preamble, the trace runs on L1.6/L2.4 exit-code reasoning, and the fix
is the preamble (or L2.4's `|| exit` guards — both pass). `archive-
errors.sh` claims to archive ERROR lines from a log — but it lies. Find
where, trace WHY the exit code agreed with the lie, then fix the
script so its exit code tells the truth on both a good input and a bad
one.

## GUIDED STEPS

1. Read the claim before testing it:

       cat archive-errors.sh
       cat app.log

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   # archive-errors.sh — extract the ERROR lines from a log and file them in archive/.
   log="$1"
   grep ERROR "$log" > errors.txt
   cp errors.txt archiv/errors.txt 2>/dev/null
   rm -f errors.txt
   echo "archived: ERROR lines from $log are in archive/errors.txt"
   exit 0
   ```

2. Run it and capture the evidence — the lie, on the record, BEFORE
   you touch anything:

       bash archive-errors.sh app.log > broken-run.txt 2>&1; echo "exit=$?" >> broken-run.txt
       cat broken-run.txt
       ls archive

   expect (`broken-run.txt`):

       archived: ERROR lines from app.log are in archive/errors.txt
       exit=0

   `ls archive` prints nothing — the archive is EMPTY. The script
   said success, exited 0, and did nothing. The gate question: the
   script said success — find where it lied.

3. Your co-pilot vouches for the liar:

       shellcheck archive-errors.sh

   expect: nothing — exit 0. The trace is on you.

4. Write `answers.txt` — the trace, BEFORE fixing — one `key=value`
   per line, no spaces around `=`:

   q1 (choice). The command that actually failed:
   a) grep — no ERROR lines
   b) cp — its target directory archiv/ does not exist
   c) rm

   q2 (choice). You saw no error because…
   a) cp fails silently by design
   b) 2>/dev/null threw cp's report away
   c) the terminal ate it

   q3 (choice). The exit code was 0 because…
   a) cp failures don't set $?
   b) nothing made the failure STOP the script — rm and echo then
      succeeded, and the trailing exit 0 sealed the lie (even without
      it, echo's 0 would — L1.6)
   c) bash resets $? between lines

   q4 (choice). The Phase-2 tool that stops the script AT the failing
   cp:
   a) set -euo pipefail — the -e
   b) a case statement
   c) trap cleanup EXIT

5. Fix the workspace copy of `archive-errors.sh`. Three goals (not a
   diff — find your own edits): (1) failures must stop the script —
   this track's default is the L2.2 preamble; (2) the real directory
   is `archive/`, not `archiv/`; (3) errors must be allowed to reach
   your eyes — delete the `2>/dev/null`. Verify yourself:

       bash archive-errors.sh app.log; echo $?
       grep -c ERROR archive/errors.txt
       bash archive-errors.sh missing.log; echo $?

   Expect the first two to show the message, exit 0, and the count 3.
   Expect the third to show a LOUD grep error and a NONZERO exit —
   the honesty test: a missing log must be fatal, never narrated over.

6. `lab check bash L2.8`
