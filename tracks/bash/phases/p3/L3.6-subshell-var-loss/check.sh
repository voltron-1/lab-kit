#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L3.6}"
: "${LAB_CHECKLIB:?run this via: lab check bash L3.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- PREDICT: no destructive command, no decoy, no fence — grade
# predictions.txt (written before running anything) ---
assert_file_contains "predictions.txt" '^pipe=0$' \
  "the pipe form's while loop runs in a SUBSHELL — what happens to count after it exits?"
assert_file_contains "predictions.txt" '^procsub=3$' \
  "the < <(cmd) form keeps the loop in the CURRENT shell — count survives"
assert_file_contains "predictions.txt" '^why=' \
  "one line: WHY does the pipe form lose the count? (name the subshell)"
assert_file_contains "predictions.txt" '(subshell|sub-shell|child)' \
  "the pipeline's right-hand side runs in a ___"
ck_summary
