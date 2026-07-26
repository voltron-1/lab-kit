#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L1.3}"
: "${LAB_CHECKLIB:?run this via: lab check rust L1.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt"
assert_file_contains "predictions.txt" '^x=9$'
assert_file_contains "predictions.txt" '^kind=well-known$'
assert_file_contains "predictions.txt" '^parity=odd$'
assert_file_contains "predictions.txt" '^error=E0308$'

assert_file_exists "sample"
assert_output_contains 'sample binary output' 'parity = odd' 'step 3 — rustc sample.rs -o sample' -- ./sample

ck_summary
