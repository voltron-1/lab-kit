## BRIEF
`case` matches ONE word against GLOB patterns (L1.5's `*`, `?`,
`[...]` — not regex), top to bottom, and the FIRST match wins: order
is priority. `;;` ends an arm (no fallthrough); `pat1|pat2` is
alternation inside one arm; `*)` is the catch-all. The trap this phase
cares about: with no matching arm and no `*)`, `case` does NOTHING and
exits 0 — a silent non-decision. `triage.sh` routes artifact filenames
to handlers, and it ships with a real ordering bug to find.

## GUIDED STEPS

1. Decode: five arms, note the order.

       cat triage.sh

   ```bash
   #!/usr/bin/env bash
   # triage.sh — route an artifact filename to its handler.
   f="${1:-}"
   case "$f" in
     "") echo "usage: bash triage.sh <filename>" >&2; exit 2 ;;
     *.log) echo "route: plain log scanner" ;;
     *.json) echo "route: jq pipeline" ;;
     alert_*|ioc_*) echo "route: priority queue" ;;
     *) echo "route: quarantine (unknown type: $f)" ;;
   esac
   ```

2. Run the matrix. Before the third row, ask yourself: which arm
   SHOULD catch `alert_web.log` — and which one actually will?

       bash triage.sh app.log; echo $?
       bash triage.sh feed.json; echo $?
       bash triage.sh alert_web.log; echo $?
       bash triage.sh ioc_dump.bin; echo $?
       bash triage.sh notes.txt; echo $?
       bash triage.sh; echo $?

   expect:

       route: plain log scanner
       0
       route: jq pipeline
       0
       route: plain log scanner
       0
       route: priority queue
       0
       route: quarantine (unknown type: notes.txt)
       0
       usage: bash triage.sh <filename>
       2

   The teaching beat is row 3: `alert_web.log` was supposed to be
   priority — it matches BOTH `*.log` and `alert_*`, and `case` took
   the FIRST one. An alert just got routed to the slow queue by
   pattern ORDER, not by anyone's intent. The minimal fix (decode
   only, don't edit): move the `alert_*|ioc_*` arm ABOVE `*.log`.

   Also true, worth knowing: a `case` with no matching arm and no
   `*)` exits 0 with no output at all —
   `case zz in a) : ;; esac; echo $?` prints `0`. A silent
   non-decision.

3. Write `answers.txt` — one `key=value` per line, no spaces around
   `=`:

   q1 (choice). `bash triage.sh alert_web.log` printed…
   a) route: priority queue — alert_* is more specific
   b) route: plain log scanner — *.log sits first and case takes the
      FIRST match, not the best
   c) route: quarantine

   q2 (choice). The minimal fix so alerts win?
   a) change *.log to *.LOG
   b) move the alert_*|ioc_* arm ABOVE *.log — order is priority
   c) replace ;; with ;&

   q3 (value). Exit code of `bash triage.sh` (no argument)?

   q4 (choice). Delete the *) arm and feed a name no pattern matches.
   The case…
   a) errors, exit 1
   b) does nothing and the script exits 0 — a silent non-decision
   c) loops back to the first arm

4. `lab check bash L2.5`
