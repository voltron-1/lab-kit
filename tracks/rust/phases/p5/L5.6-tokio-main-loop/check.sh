#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L5.6}"
: "${LAB_CHECKLIB:?run this via: lab check rust L5.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains "answers.txt" '^q2=b$'
assert_file_contains "answers.txt" '^q3=4$'
assert_file_contains "answers.txt" '^q4=8625$'
assert_file_contains "answers.txt" '^q5=b$'

assert_file_exists "loop_out.txt"
assert_file_contains_fixed "loop_out.txt" 'port sum = 8625'

ck_summary
