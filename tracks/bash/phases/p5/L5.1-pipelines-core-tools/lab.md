## BRIEF
`top-offenders.sh` finds the IP with the most failed logins in `access.log`
using five chained tools — `grep`, `cut`, `sort`, `uniq -c`, `sort -rn`. This
phase is different from what came before: nothing here is broken or
dangerous. It's correct, ordinary, real code — safe to run for real. Your
job is DECODE: name what each stage of the pipeline does to the stream.

## GUIDED STEPS

1. Read it:

       cat top-offenders.sh

   ```bash
   #!/usr/bin/env bash
   # REFERENCE SAMPLE — read, decode, and run for real.
   set -euo pipefail
   grep ' 401 ' access.log \
     | cut -d' ' -f1 \
     | sort \
     | uniq -c \
     | sort -rn \
     | head -1
   ```

   Six stages, one per line: `grep ' 401 '` **filters** the stream down to
   failed-auth lines only; `cut -d' ' -f1` keeps just the first
   whitespace-delimited **field** — the client IP; `sort` **orders**
   (groups) identical IPs adjacently, which `uniq -c` needs since it only
   collapses *adjacent* duplicates; `uniq -c` **counts** each run and
   prefixes it with that count; a second `sort -rn` **ranks** the counted
   lines numerically, largest first; `head -1` keeps just the winner.

2. Run it for real:

       ./top-offenders.sh

   captured output:

       ```
             4 203.0.113.7
       ```

3. See the full ranked list `head -1` throws away, by dropping the last
   stage:

       grep ' 401 ' access.log | cut -d' ' -f1 | sort | uniq -c | sort -rn

   captured output:

       ```
             4 203.0.113.7
             1 198.51.100.23
       ```

   203.0.113.7 failed 4 times; 198.51.100.23 failed once. `head -1` is why
   the script reports only the top offender.

4. Confirm ShellCheck's take:

       shellcheck top-offenders.sh

   captured output: *(nothing — clean, no warnings)*

5. Answer the comprehension check. Write `answers.txt`:

       stage4=filter
       stage5=field
       stage6=order
       stage7=count
       stage8=rank
       top_ip=203.0.113.7
       top_count=4

6. `lab check bash L5.1`
