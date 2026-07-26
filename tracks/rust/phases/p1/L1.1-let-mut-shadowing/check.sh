#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L1.1}"
: "${LAB_CHECKLIB:?run this via: lab check rust L1.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt"
assert_file_contains "predictions.txt" '^x=12$'
assert_file_contains "predictions.txt" '^count=15$'
assert_file_contains "predictions.txt" '^label=3$'
assert_file_contains "predictions.txt" '^error=E0384$'

assert_file_exists "sample"
assert_output_contains 'sample binary output' 'label = 3' 'step 3 — rustc sample.rs -o sample' -- ./sample

ck_summary
