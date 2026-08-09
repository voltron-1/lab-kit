#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L5.1}"
: "${LAB_CHECKLIB:?run this via: lab check rust L5.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt"
assert_file_contains "predictions.txt" '^total=60$'
assert_file_contains "predictions.txt" '^error=E0373$'

assert_file_exists "sample"
assert_output_contains 'sample joins threads' 'total = 60' 'step 3 — rustc sample.rs -o sample' -- ./sample

assert_file_exists "rust_error.txt"
assert_file_contains "rust_error.txt" 'error\[E0373\]'

ck_summary
