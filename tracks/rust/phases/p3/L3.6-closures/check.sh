#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L3.6}"
: "${LAB_CHECKLIB:?run this via: lab check rust L3.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt"
assert_file_contains "predictions.txt" '^high=true$'
assert_file_contains "predictions.txt" '^threshold=100$'
assert_file_contains "predictions.txt" '^streak=3$'
assert_file_contains "predictions.txt" '^error=E0382$'

assert_file_exists "sample"
assert_output_contains 'sample runs' 'scan:10' 'step 3 — rustc sample.rs -o sample' -- ./sample

ck_summary
