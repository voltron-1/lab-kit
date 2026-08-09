#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L6.5}"
: "${LAB_CHECKLIB:?run this via: lab check rust L6.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains_fixed "answers.txt" 'q2=take'
assert_file_contains "answers.txt" '^q3=b$'
assert_file_contains "answers.txt" '^q4=b$'
assert_file_contains_fixed "answers.txt" 'q5=Record'

ck_summary
