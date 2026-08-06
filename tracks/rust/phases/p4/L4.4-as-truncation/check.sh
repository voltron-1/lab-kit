#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L4.4}"
: "${LAB_CHECKLIB:?run this via: lab check rust L4.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains "answers.txt" '^q2=100$'
assert_file_contains_fixed "answers.txt" 'q3=CWE-197'
assert_file_contains "answers.txt" '^q4=b$'
assert_file_contains "answers.txt" '^q5=b$'

assert_file_exists "sample"
assert_output_contains 'sample shows the safe gate rejecting' 'safe gate accepts 65636 = false' 'step 2 — rustc sample.rs -o sample' -- ./sample

ck_summary
