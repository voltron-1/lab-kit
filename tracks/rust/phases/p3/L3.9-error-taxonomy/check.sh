#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L3.9}"
: "${LAB_CHECKLIB:?run this via: lab check rust L3.9}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=a$'
assert_file_contains "answers.txt" '^q2=a$'
assert_file_contains "answers.txt" '^q3=b$'
assert_file_contains_fixed "answers.txt" 'q4=malformed header at byte 12'
assert_file_contains "answers.txt" '^q5=a$'

ck_summary
