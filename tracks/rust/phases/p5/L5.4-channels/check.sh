#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L5.4}"
: "${LAB_CHECKLIB:?run this via: lab check rust L5.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt"
assert_file_contains "predictions.txt" '^count=3$'
assert_file_contains "predictions.txt" '^total=600$'

assert_file_exists "sample"
assert_output_contains 'sample sums channel values' 'total = 600' 'step 3 — rustc sample.rs -o sample' -- ./sample

ck_summary
