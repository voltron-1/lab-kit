## BRIEF
**Phase gate.** `triage-summary.sh` is a realistic log-triage script that
chains every construct this phase taught: `grep`/`cut`/`sort`/`uniq`/`awk`
(L5.1, L5.3), an allowlist check, process substitution (L5.5), `sed` via
a here-string (L5.2, L5.5), `jq` (L5.4), and a heredoc report (L5.5).
Real, correct, safe to run for real. Decode it stage by stage and report
the concrete values it computes.

## GUIDED STEPS

1. Look at the inputs first:

       cat access.log
       cat allowed-ips.txt

   `access.log` is the same 8-line log from L5.1. `allowed-ips.txt` lists
   two known-good IPs: `192.0.2.15` and `198.51.100.23`.

2. Read the script one assignment at a time:

       cat triage-summary.sh

   ```bash
   #!/usr/bin/env bash
   # REFERENCE SAMPLE — read, decode, and run for real.
   set -euo pipefail
   LOG=access.log
   ALLOWLIST=allowed-ips.txt

   top_offender=$(grep ' 401 ' "$LOG" | cut -d' ' -f1 | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
   offender_count=$(grep ' 401 ' "$LOG" | cut -d' ' -f1 | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')

   if grep -qxF -- "$top_offender" "$ALLOWLIST"; then
     status=known
   else
     status=unknown
   fi

   new_ips=$(diff <(cut -d' ' -f1 "$LOG" | sort -u) <(sort "$ALLOWLIST") | grep '^<' | cut -d' ' -f2 || true)

   redacted=$(sed -E 's/[0-9]+$/xxx/' <<< "$top_offender")

   jq -n --arg ip "$top_offender" --arg cnt "$offender_count" --arg status "$status" \
     '{"source.ip": $ip, "event.count": ($cnt|tonumber), "ip.known": $status}'

   cat <<REPORT
   === Triage Summary ===
   top offender:   $redacted ($status)
   failed logins:  $offender_count
   new IPs seen:   $(printf '%s\n' "$new_ips" | grep -c .)
   REPORT
   ```

   `top_offender`/`offender_count` are L5.1's exact pipeline — `grep`
   **filters** to 401s, `cut`/`sort`/`uniq -c`/`sort -rn` rank them, and
   a trailing `awk '{print $N}'` pulls the **field** it needs out of
   `uniq -c`'s `"  count ip"` output (`$2` for the IP, `$1` for the
   count). The `if grep -qxF …` block checks the allowlist. `new_ips`
   uses **process substitution** (`<(...)` twice) so `diff` can compare
   two live, sorted, deduplicated command outputs with no temp files —
   guarded by `|| true` since `diff` exits nonzero on a real difference,
   which would otherwise abort the script under `set -euo pipefail`
   (Phase 2's silent-failure lesson, again). `redacted` feeds `sed` a
   single value through a **here-string** (`<<< "$top_offender"`) to mask
   its trailing digits. The `jq -n --arg …` call doesn't read a file —
   it **reshapes** three bash variables into one structured JSON record
   via `--arg`. The final `cat <<REPORT … REPORT` is a **heredoc** — it
   renders the human-readable **report**, and even its `new IPs seen:`
   line contains a live `$(...)` command substitution, expanded because
   the heredoc is unquoted.

3. Run it for real:

       ./triage-summary.sh

   captured output:

       ```
       {
         "source.ip": "203.0.113.7",
         "event.count": 4,
         "ip.known": "unknown"
       }
       === Triage Summary ===
       top offender:   203.0.113.xxx (unknown)
       failed logins:  4
       new IPs seen:   1
       ```

   `203.0.113.7` is the top offender with 4 failed logins, and it's not
   in `allowed-ips.txt` (`unknown`). `access.log` has three distinct
   IPs — `198.51.100.23`, `203.0.113.7`, `192.0.2.15` — and the first
   and third are both already in `allowed-ips.txt`; only `203.0.113.7`
   is new, so `new_ips` reports exactly one IP.

4. Confirm ShellCheck's take:

       shellcheck triage-summary.sh

   captured output: *(nothing — clean, no warnings)*

5. Answer the comprehension + concrete-value check. Write `answers.txt`:

       stage_grep=filter
       stage_awk=field
       stage_diff=procsub
       stage_sed=herestring
       stage_jq=reshape
       stage_heredoc=report
       top_ip=203.0.113.7
       top_count=4
       ip_status=unknown
       new_count=1

6. `lab check bash L5.6`
