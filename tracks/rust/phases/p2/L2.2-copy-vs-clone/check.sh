#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L2.2}"
: "${LAB_CHECKLIB:?run this via: lab check rust L2.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt"
assert_file_contains "predictions.txt" '^b=41$'
assert_file_contains "predictions.txt" '^w=5$'
assert_file_contains "predictions.txt" '^first=20$'
assert_file_contains "predictions.txt" '^error=E0204$'

assert_file_exists "sample"
assert_output_contains 'sample runs' 'dmz-probe' 'step 3 — rustc sample.rs -o sample' -- ./sample

ck_summary
