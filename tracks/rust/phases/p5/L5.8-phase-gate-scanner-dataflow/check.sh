#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L5.8}"
: "${LAB_CHECKLIB:?run this via: lab check rust L5.8}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains_fixed "answers.txt" 'q1=MAX_IN_FLIGHT'
assert_file_contains "answers.txt" '^q2=100$'
assert_file_contains "answers.txt" '^q3=b$'
assert_file_contains "answers.txt" '^q4=b$'
assert_file_contains "answers.txt" '^q5=b$'
assert_file_contains "answers.txt" '^q6=b$'
assert_file_contains "answers.txt" '^q7=b$'
assert_file_contains "answers.txt" '^q8=b$'
assert_file_contains "answers.txt" '^q9=b$'
assert_file_contains "answers.txt" '^q10=b$'

ck_summary
