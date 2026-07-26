#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L1.8}"
: "${LAB_CHECKLIB:?run this via: lab check rust L1.8}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt"
assert_file_contains_fixed "predictions.txt" 'p1=Some(22)'
assert_file_contains "predictions.txt" '^p2=None$'
assert_file_contains "predictions.txt" '^p3=0$'
assert_file_contains "predictions.txt" '^p4=53$'
assert_file_contains "predictions.txt" '^error=E0308$'

assert_file_exists "sample"
assert_output_contains 'sample runs' 'dns runs on 53' 'step 3 — rustc sample.rs -o sample' -- ./sample

ck_summary
