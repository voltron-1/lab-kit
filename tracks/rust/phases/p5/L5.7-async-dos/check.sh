#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L5.7}"
: "${LAB_CHECKLIB:?run this via: lab check rust L5.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains "answers.txt" '^q2=b$'
assert_file_contains "answers.txt" '^q3=b$'
assert_file_contains "answers.txt" '^q4=b$'
assert_file_contains_fixed "answers.txt" 'q5=CWE-400'
assert_file_contains "answers.txt" '^q6=b$'

ck_summary
