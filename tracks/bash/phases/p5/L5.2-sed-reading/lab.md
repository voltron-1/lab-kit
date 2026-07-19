## BRIEF
`redact.sh` runs two `sed -E` expressions over `access.log`: the first masks
every IP address, the second reorders the surviving fields into
`key=value` form using capture groups. Real, correct, safe to run for
real. Your job is DECODE: name what each expression does.

## GUIDED STEPS

1. Read it:

       cat redact.sh

   ```bash
   #!/usr/bin/env bash
   # REFERENCE SAMPLE — read, decode, and run for real.
   set -euo pipefail
   sed -E \
     -e 's/([0-9]{1,3}\.){3}[0-9]{1,3}/[IP-REDACTED]/g' \
     -e 's/^\[IP-REDACTED\] - - \[([^]]+)\] "([A-Z]+) ([^ ]+) [^"]+" ([0-9]{3}) .*/ts=\1 method=\2 path=\3 status=\4/' \
     access.log
   ```

   `-E` turns on **extended regex** — `( )`, `{ }`, `+`, `?` all work
   unescaped, which is why `{1,3}` and `( )` above need no backslashes.
   The first `-e` **masks** every IPv4 address on the line — the trailing
   `g` makes it **global**, replacing every match, not just the first (only
   matters if a line had more than one IP; here it's belt-and-suspenders).
   The second `-e` is anchored (`^...$`-shaped) against the *entire*
   redacted line and captures four groups — timestamp, method, path,
   status — then **reorders** them into `ts=\1 method=\2 path=\3 status=\4`.
   `\1`, `\2`, `\3`, `\4` in the replacement each refer to whatever the
   correspondingly-numbered `( )` **capture** group matched.

2. Run it for real:

       ./redact.sh

   captured output:

       ```
       ts=18/Jul/2026:10:12:01 +0000 method=GET path=/login status=200
       ts=18/Jul/2026:10:12:03 +0000 method=GET path=/login status=401
       ts=18/Jul/2026:10:12:05 +0000 method=POST path=/login status=401
       ts=18/Jul/2026:10:12:07 +0000 method=GET path=/login status=401
       ts=18/Jul/2026:10:12:09 +0000 method=GET path=/login status=401
       ts=18/Jul/2026:10:12:11 +0000 method=GET path=/dashboard status=200
       ts=18/Jul/2026:10:12:13 +0000 method=GET path=/login status=401
       ts=18/Jul/2026:10:12:15 +0000 method=GET path=/dashboard status=200
       ```

   Every IP is gone from the output — the first `-e` already masked it
   before the second `-e` ever anchors against `^\[IP-REDACTED\]`.

3. Confirm ShellCheck's take:

       shellcheck redact.sh

   captured output: *(nothing — clean, no warnings)*

4. Answer the comprehension check. Write `answers.txt`:

       dash_e=extended
       flag_g=global
       purpose5=mask
       purpose6=reorder
       backslash1=capture

5. `lab check bash L5.2`
