#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L5.3}"
: "${LAB_CHECKLIB:?run this via: lab check bash L5.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- PREDICT: predictions.txt is written before running anything ---
assert_file_contains "predictions.txt" '^predict1_line1=high 3$' \
  "command 1 counts alerts by severity — how many 'high' rows are there?"
assert_file_contains "predictions.txt" '^predict1_line2=low 2$' \
  "command 1 counts alerts by severity — how many 'low' rows are there?"
assert_file_contains "predictions.txt" '^predict1_line3=medium 1$' \
  "command 1 counts alerts by severity — how many 'medium' rows are there?"
assert_file_contains "predictions.txt" '^predict2_line1=2026-07-18T10:00:00Z host-a\.test$' \
  "command 2 prints timestamp and host for every 'high' row, in file order"
assert_file_contains "predictions.txt" '^predict2_line2=2026-07-18T10:07:00Z host-a\.test$' \
  "command 2 prints timestamp and host for every 'high' row, in file order"
assert_file_contains "predictions.txt" '^predict2_line3=2026-07-18T10:11:00Z host-b\.test$' \
  "command 2 prints timestamp and host for every 'high' row, in file order"
assert_file_contains "predictions.txt" '^predict3=3 fields: timestamp,severity,host$' \
  "command 3 prints NF (field count) and the header row — how many comma-separated fields does the header have?"
# verify1.sh (files/) reruns command 1 for real — a tamper check that
# avoids invoking awk via a lint-banned inline-shell form (lint-labs.sh:83).
assert_cmd_ok "verify1.sh runs clean" \
  "it should execute with no errors under set -euo pipefail" \
  -- bash -- verify1.sh
assert_output_contains "command 1 reproduces the predicted counts" 'high 3' \
  "verify1.sh's real output should show the same severity counts you predicted" \
  -- bash -- verify1.sh
ck_summary
