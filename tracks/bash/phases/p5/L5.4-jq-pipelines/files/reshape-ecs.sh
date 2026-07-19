#!/usr/bin/env bash
# REFERENCE SAMPLE — read, decode, and run for real.
set -euo pipefail
jq -c '{
  "@timestamp":    .ts,
  "source.ip":     .src_ip,
  "user.name":     .user,
  "event.action":  .action,
  "event.outcome": (if (.action | test("failed")) then "failure" else "success" end)
}' events.jsonl
