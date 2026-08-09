#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L5.3}"
: "${LAB_CHECKLIB:?run this via: lab check rust L5.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains "answers.txt" '^q2=b$'
assert_file_contains "answers.txt" '^q3=100$'
assert_file_contains "answers.txt" '^q4=b$'
assert_file_contains "answers.txt" '^q5=b$'

assert_file_exists "sample"
assert_output_contains 'sample counts to 100' 'count = 100' 'step 2 — rustc sample.rs -o sample' -- ./sample

ck_summary
