#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L6.4}"
: "${LAB_CHECKLIB:?run this via: lab check rust L6.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains "answers.txt" '^q2=b$'
assert_file_contains "answers.txt" '^q3=b$'
assert_file_contains_fixed "answers.txt" 'q4=decode'
assert_file_contains "answers.txt" '^q5=b$'

ck_summary
