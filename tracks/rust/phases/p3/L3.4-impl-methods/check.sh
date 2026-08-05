#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L3.4}"
: "${LAB_CHECKLIB:?run this via: lab check rust L3.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=a$'
assert_file_contains "answers.txt" '^q2=b$'
assert_file_contains_fixed "answers.txt" 'q3=failed-auth: 3 hits'
assert_file_contains "answers.txt" '^q4=E0382$'
assert_file_contains "answers.txt" '^q5=a$'

assert_file_exists "sample"
assert_output_contains 'sample runs' 'archived: failed-auth' 'step 4 — remove extra call and recompile' -- ./sample

ck_summary
