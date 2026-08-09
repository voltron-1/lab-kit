#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L5.5}"
: "${LAB_CHECKLIB:?run this via: lab check rust L5.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains "answers.txt" '^q2=b$'
assert_file_contains "answers.txt" '^q3=42$'
assert_file_contains "answers.txt" '^q4=b$'
assert_file_contains "answers.txt" '^q5=b$'

assert_file_exists "async_out.txt"
assert_file_contains_fixed "async_out.txt" 'result = 42'
assert_file_contains_fixed "async_out.txt" 'a = 2, b = 4'

ck_summary
