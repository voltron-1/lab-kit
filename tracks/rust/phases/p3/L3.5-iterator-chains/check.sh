#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L3.5}"
: "${LAB_CHECKLIB:?run this via: lab check rust L3.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt"
assert_file_contains "predictions.txt" '^total=17766$'
assert_file_contains "predictions.txt" '^hi=8080$'
assert_file_contains "predictions.txt" '^low_count=2$'
assert_file_contains "predictions.txt" '^first=210$'

assert_file_exists "sample"
assert_output_contains 'sample runs' 'doubled = \[16160, 18400\]' 'step 3 — rustc sample.rs -o sample' -- ./sample

ck_summary
