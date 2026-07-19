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
