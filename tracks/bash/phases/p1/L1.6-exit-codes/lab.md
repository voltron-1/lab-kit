## BRIEF
Every command leaves a one-byte verdict behind in `$?`: 0 means success —
backwards from every language you know, where 0 is false — and nonzero
means some flavor of failure (each tool picks its own: grep says 1 for
"no match", GNU ls says 2 for "serious trouble"). Two rules carry this
lab: `if` consumes the CODE, not the output; and EVERY command overwrites
`$?` — including the echo you just used to look at it. pulse.sh turns a
log scan into an exit code because scripts are commands too: its `exit 1`
is a report to whoever calls it.

## GUIDED STEPS

1. Decode before running (DECODE discipline) — find the three
   load-bearing pieces: `grep -q`, `exit 1`, `exit 0`.

       cat pulse.sh

   ```bash
   #!/usr/bin/env bash
   # pulse.sh — tiny health probe: scan a log, report, exit accordingly.
   log="app.log"
   if grep -q "ERROR" "$log"; then
     echo "status: degraded"
     exit 1
   fi
   echo "status: healthy"
   exit 0
   ```

   `grep -q "ERROR" "$log"` — `-q` silences all output because nobody
   reads it: the exit code IS the answer. grep's contract: 0 = match
   found, 1 = no match, 2 = real error. `"$log"` is quoted — the L1.3
   reflex, one clause: a space-bearing value stays one argument instead
   of splitting into several. `if grep -q …; then` — `if` runs the
   command and branches on its exit code alone; grep -q prints nothing,
   so there is nothing else it COULD test. `exit 1` / `exit 0` — the
   script propagates the verdict upward: a cron job, a CI step, or
   another `if` reads pulse.sh's code exactly the way pulse.sh reads
   grep's.

2. The evidence:

       cat app.log

   Five INFO lines, one ERROR line, zero FATAL anywhere.

3. Run it, then check the verdict with nothing in between:

       bash pulse.sh
       echo $?

   expect:

       status: degraded
       1

   Message = stdout; verdict = code — two separate channels. `$?` still
   holds pulse.sh's exit code because nothing ran between the script and
   the echo.

4. Quiet grep, match present:

       grep -q INFO app.log; echo $?

   expect:

       0

5. Quiet grep, no match — total silence still carries an answer:

       grep -q FATAL app.log; echo $?

   expect:

       1

6. A different tool, a different failure flavor:

       ls ghost.txt; echo $?

   expect:

       ls: cannot access 'ghost.txt': No such file or directory
       2

   GNU ls exits 2 for "serious trouble" (a nonexistent command-line
   operand).

7. THE AHA — run `ls ghost.txt` once more, then on the next line
   `echo $?; echo $?`:

       ls ghost.txt
       echo $?; echo $?

   expect:

       ls: cannot access 'ghost.txt': No such file or directory
       2
       0

   The first echo reports ls's 2 — and by succeeding, overwrites `$?`
   with 0. The second echo is reporting the FIRST ECHO's success. Every
   command writes `$?`, even the one you used to look at it. Explain it
   to yourself before moving on — this is q3.

8. Write `answers.txt` — one `key=value` per line, no spaces around `=`:

   q1 (value). Exit code of `bash pulse.sh` on the shipped log?

   q2 (value). Exit code of `grep -q FATAL app.log`?

   q3 (choice). In step 7, why does the second `echo $?` print 0?
   a) `$?` resets to 0 every time it is read
   b) the first echo succeeded and overwrote it — every command writes
      `$?`
   c) echo always returns 0, so `$?` is meaningless after any echo

   q4 (choice). In `if grep -q "ERROR" "$log"; then …`, what does `if`
   actually test?
   a) grep's stdout text
   b) grep's exit code
   c) whether app.log is nonempty

9. `lab check bash L1.6`
