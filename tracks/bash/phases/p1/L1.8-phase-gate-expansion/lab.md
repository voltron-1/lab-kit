## BRIEF
The Phase 1 gate. Nothing new — one 18-line script, report.sh, fires
everything you have learned: ${} name boundaries, all three quoting
modes, word splitting, a glob that matches and one that does not,
nested and unquoted command substitution, and a final $?.
The phase model, verbatim: everything is text, and the shell transforms
that text through a fixed sequence of expansions before it runs anything.
Write ALL ten predictions into predictions.txt BEFORE you run the script
once. The check can't tell whether you predicted first — you're only
cheating your own reps. report.sh is flawed on purpose: its unquoted
expansions are the lesson (shellcheck names three of them).

## GUIDED STEPS

1. Read the script and its data — never the outputs.

       cat report.sh

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   # L1.8 phase gate: predict all ten numbered lines BEFORE running.
   host="web01"
   printf '1:%s\n' "$host_id"
   printf '2:%s\n' "${host}_id"
   hosts=$(cat hosts.txt)
   printf '3:%s\n' '*.log'
   printf '4:%s\n' "$hosts"
   set -- $hosts
   printf '5:argc=%s\n' "$#"
   printf '6:%s %s\n' *.log
   printf '7:%s\n' *.conf
   printf '8:%s\n' "$(basename "$(pwd)")"
   set -- $(cat hosts.txt)
   printf '9:argc=%s\n' "$#"
   grep -q FATAL app.log
   printf '10:rc=%s\n' "$?"
   ```

       cat hosts.txt
       cat app.log error.log

   State pin: you run from `workspace/bash/L1.8`; do not create extra
   files first — `predictions.txt` (next step) matches neither glob.

2. Predict: create `predictions.txt` with keys p1…p10, one per numbered
   output line, value = the FULL line including its `N:` prefix, no
   spaces around `=`. Format example (not an answer): `p1=1:whatever-you-predict`.

3. Run exactly once: `bash report.sh`.

4. Compare `cat predictions.txt` against the run — every miss is the
   lesson; correct the key to the real line byte-for-byte (the honor
   line already did its work in the BRIEF).

5. `lab check bash L1.8`.
