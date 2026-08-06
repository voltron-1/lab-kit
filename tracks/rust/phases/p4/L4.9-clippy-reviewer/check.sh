#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L4.9}"
: "${LAB_CHECKLIB:?run this via: lab check rust L4.9}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains "answers.txt" '^q2=b$'
assert_file_contains "answers.txt" '^q3=b$'
assert_file_contains "answers.txt" '^q4=needless_range_loop$'
assert_file_contains "answers.txt" '^q5=b$'

assert_file_exists "clippy_out.txt"
assert_file_contains "clippy_out.txt" 'clippy'

ck_summary
