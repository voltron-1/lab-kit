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
