#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L2.3}"
: "${LAB_CHECKLIB:?run this via: lab check rust L2.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt"
assert_file_contains "predictions.txt" '^alias=bastion-01$'
assert_file_contains "predictions.txt" '^max=11$'
assert_file_contains "predictions.txt" '^error=E0596$'

assert_file_exists "sample"
assert_output_contains 'sample runs' 'core-router \+ edge-fw still here' 'step 3 — rustc sample.rs -o sample' -- ./sample

ck_summary
