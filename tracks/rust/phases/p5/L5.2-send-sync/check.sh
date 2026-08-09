#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L5.2}"
: "${LAB_CHECKLIB:?run this via: lab check rust L5.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=a$'
assert_file_contains "answers.txt" '^q2=b$'
assert_file_contains "answers.txt" '^q3=60$'
assert_file_contains "answers.txt" '^q4=b$'
assert_file_contains "answers.txt" '^q5=E0277$'

assert_file_exists "sample"
assert_output_contains 'sample shares via Arc' 'from_thread = 60' 'step 2 — rustc sample.rs -o sample' -- ./sample

assert_file_exists "rust_error.txt"
assert_file_contains "rust_error.txt" 'error\[E0277\]'

ck_summary
