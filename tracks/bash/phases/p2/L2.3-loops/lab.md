## BRIEF
`for` iterates over WORDS — however they got there: a literal list, a
glob, or (the trap) an unquoted `$(cat file)`, which word-splits first
(L1.7 + L1.3). `while read` iterates LINES — but plain `read` drops a
final line that lacks its newline, silently. The graded signal is the
iteration COUNT: the same 3-line file drives one loop 7 times, another
2, and the correct one 3. `readlines.sh` ships the canonical pattern —
`while IFS= read -r line || [ -n "$line" ]` — keep it. The check can't
tell whether you predicted first — you're only cheating your own reps.

## GUIDED STEPS

1. Take inventory BEFORE predicting:

       ls

   expect: `readlines.sh`, `tasks.txt`, `web01.conf`, `web02.conf`
   (your terminal shows columns; piped output is one per line).

       cat tasks.txt

   Note where the prompt lands: immediately after `rotate keys`, no
   final newline.

2. Read the canonical pattern:

       cat readlines.sh

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   # readlines.sh — THE way to read a file line by line, byte-safe.
   while IFS= read -r line || [ -n "$line" ]; do
     printf '[%s]\n' "$line"
   done < "${1:?usage: bash readlines.sh <file>}"
   ```

   `IFS=` stops `read` from stripping leading/trailing whitespace;
   `-r` stops it from interpreting backslashes; `|| [ -n "$line" ]`
   runs the loop body one more time when `read` has failed (hit EOF)
   but still delivered bytes into `$line` — see step 6.

3. Below are six sample lines. "Count" means: the number of
   lines the loop prints. Write ALL SIX predictions into
   `predictions.txt` before running anything — keys `p1=` through
   `p6=`; `p1`, `p3`, `p4`, `p5` are bare counts; `p2` and `p6` are the
   EXACT output line each produces.

       for h in web01 web02 db01; do printf 'ping %s\n' "$h"; done
       for f in *.conf; do printf 'loading %s\n' "$f"; done
       for w in $(cat tasks.txt); do printf '[%s]\n' "$w"; done
       while read -r line; do printf '[%s]\n' "$line"; done < tasks.txt
       bash readlines.sh tasks.txt
       for f in *.missing; do printf 'got %s\n' "$f"; done

4. Run each of the six lines above, one at a time, comparing each
   against your prediction.

5. p3's trap: `$(cat tasks.txt)` is UNQUOTED, so its result
   word-splits (L1.7) before `for` ever sees it — `for` walks WORDS,
   not lines.

6. p4 vs p5: plain `while read -r line` silently drops the last line
   of `tasks.txt` — because that line has no trailing newline, `read`
   returns nonzero (EOF) even though it filled `$line`, and the loop
   body never runs for it. `readlines.sh`'s `|| [ -n "$line" ]` guard
   is what rescues that last line.

7. Correct any missed key to the observed truth, then:

       lab check bash L2.3
