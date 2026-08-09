#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L6.6}"
: "${LAB_CHECKLIB:?run this via: lab check rust L6.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=a$'
assert_file_contains_fixed "answers.txt" 'q2=hexyl'
assert_file_contains_fixed "answers.txt" 'q3=src/main.rs'
assert_file_contains "answers.txt" '^q4=b$'
assert_file_contains "answers.txt" '^q5=a$'
assert_file_contains_fixed "answers.txt" 'q6=format_hex'
assert_file_contains "answers.txt" '^q7=b$'
assert_file_contains "answers.txt" '^q8=b$'

ck_summary
