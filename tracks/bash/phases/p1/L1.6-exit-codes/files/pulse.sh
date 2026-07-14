#!/usr/bin/env bash
# pulse.sh — tiny health probe: scan a log, report, exit accordingly.
log="app.log"
if grep -q "ERROR" "$log"; then
  echo "status: degraded"
  exit 1
fi
echo "status: healthy"
exit 0
