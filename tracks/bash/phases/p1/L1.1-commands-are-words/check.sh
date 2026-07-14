#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L1.1}"
: "${LAB_CHECKLIB:?run this via: lab check bash L1.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt" \
  "step 2 — write p1..p4 into predictions.txt before running anything"
assert_file_contains_fixed "predictions.txt" "p1=2|<hello><world>" \
  "p1 — rerun: bash argv.sh hello world, transcribe the WHOLE line as the value"
assert_file_contains_fixed "predictions.txt" "p2=2|<hello><world>" \
  "p2 — the run of spaces is one separator; rerun the line and transcribe"
assert_file_contains_fixed "predictions.txt" "p3=1|<hello   world>" \
  "p3 — quotes keep the three interior spaces inside ONE argument; transcribe exactly"
assert_file_contains_fixed "predictions.txt" "p4=0|" \
  "p4 — zero arguments still prints a line; rerun: bash argv.sh"
assert_output_contains "argv.sh splits on whitespace" '2\|<hello><world>' \
  "run: bash argv.sh hello world" -- bash -- argv.sh hello world
ck_summary
