#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L3.10}"
: "${LAB_CHECKLIB:?run this via: lab check rust L3.10}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains "answers.txt" '^q2=b$'
assert_file_contains "answers.txt" '^q3=b$'
assert_file_contains "answers.txt" '^q4=None$'
assert_file_contains "answers.txt" '^q5=b$'
assert_file_contains "answers.txt" '^q6=get$'
assert_file_contains "answers.txt" '^q7=b$'
assert_file_contains "answers.txt" '^q8=b$'
assert_file_contains "answers.txt" '^q9=start$'
assert_file_contains "answers.txt" '^q10=b$'

ck_summary
