#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L2.1}"
: "${LAB_CHECKLIB:?run this via: lab check rust L2.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt"
assert_file_contains "predictions.txt" '^beta=intrusion$'
assert_file_contains "predictions.txt" '^size=7$'
assert_file_contains "predictions.txt" '^delta=intrusion$'
assert_file_contains "predictions.txt" '^error=E0382$'

assert_file_exists "sample"
assert_output_contains 'sample binary runs' 'beta again = intrusion' 'step 3 — rustc sample.rs -o sample' -- ./sample

ck_summary
