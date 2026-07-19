## BRIEF
`compare-hosts.sh` uses three different ways to feed a command input
without ever writing a temp file: process substitution (`<(...)`), a
here-string (`<<<`), and a heredoc (`<<REPORT`). Real, correct, safe to
run for real. Your job is DECODE: name what each construct is for.

## GUIDED STEPS

1. Read it:

       cat compare-hosts.sh

   ```bash
   #!/usr/bin/env bash
   # REFERENCE SAMPLE — read, decode, and run for real.
   set -euo pipefail
   new_hosts=$(diff <(sort allowed.txt) <(sort seen.txt) \
     | grep '^>' | cut -d' ' -f2 || true)

   last_event="login_failed host-x.test"
   if grep -q 'failed' <<< "$last_event"; then
     verdict=flagged
   else
     verdict=clear
   fi

   cat <<REPORT
   === Host Check ===
   new hosts seen:  ${new_hosts:-none}
   last event:      $last_event
   verdict:         $verdict
   REPORT
   ```

   Line 4's `<(sort allowed.txt)` and `<(sort seen.txt)` are **process
   substitution** — each one makes a command's output look like a
   filename to whatever reads it, so `diff` compares two live command
   outputs with no temp files. (`|| true` on line 5 matters too: `diff`
   exits nonzero when it finds a difference — that's not a failure, just
   its normal way of reporting one — and under `set -euo pipefail` an
   unguarded `$(diff … | …)` would abort the script before it ever
   reaches the heredoc, the same silent-failure lesson from Phase 2
   resurfacing here.) Line 8's `<<< "$last_event"` is a **here-string** —
   the shortest way to feed one already-in-memory variable to a
   command's stdin, no `echo | cmd`, no temp file. Line 14's `cat
   <<REPORT` starts a **heredoc** — inline multi-line text; because the
   opening delimiter `REPORT` is unquoted, `$variables` inside it still
   **expand**, exactly like double quotes would.

2. Run it for real:

       ./compare-hosts.sh

   captured output:

       ```
       === Host Check ===
       new hosts seen:  host-x.test
       last event:      login_failed host-x.test
       verdict:         flagged
       ```

   `host-x.test` is in `seen.txt` but not `allowed.txt` — that's the "new
   host" the process substitution found. `login_failed` matched the
   here-string check, so `verdict=flagged`.

3. Confirm ShellCheck's take:

       shellcheck compare-hosts.sh

   captured output: *(nothing — clean, no warnings)*

4. Answer the comprehension check. Write `answers.txt`:

       construct4=procsub
       construct8=herestring
       construct14=heredoc
       expands=yes

5. `lab check bash L5.5`
