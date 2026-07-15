#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L2.4}"
: "${LAB_CHECKLIB:?run this via: lab check bash L2.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt" \
  "step 1 — write keys p1..p6 into predictions.txt before running anything"
assert_file_contains "predictions.txt" '^p1=rc=1$' \
  "p1 — the compound's verdict is false's own code; rerun sample p1"
assert_file_contains "predictions.txt" '^p2=fallback$' \
  "p2 — which side of || runs after a failure? rerun sample p2"
assert_file_contains "predictions.txt" '^p3=recovered$' \
  "p3 — || pairs with the most recent verdict, not with the first command; rerun sample p3"
assert_file_contains "predictions.txt" '^p4=b$' \
  "p4 — one letter: walk the line left to right, one verdict at a time"
assert_file_contains "predictions.txt" '^p5=1$' \
  "p5 — the guard fired: cd failed, exit 1 carried the failure upward; rerun sample p5"
assert_file_contains "predictions.txt" '^p6=deploying from deploy_dir$' \
  "p6 — after mkdir deploy_dir the guard passes; rerun sample p6 and transcribe"
assert_dir_exists "deploy_dir" \
  "step 4 — mkdir deploy_dir (p6 needs it to exist)"
assert_output_contains "the guard passes once the dir exists" 'deploying from deploy_dir' \
  "run: bash guard.sh" -- bash -- guard.sh
ck_summary
