#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L3.8}"
: "${LAB_CHECKLIB:?run this via: lab check rust L3.8}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=a$'
assert_file_contains "answers.txt" '^q2=8443$'
assert_file_contains "answers.txt" '^q3=65535$'
assert_file_contains "answers.txt" '^q4=4464$'
assert_file_contains "answers.txt" '^q5=b$'

assert_file_exists "sample"
assert_output_contains 'sample runs' 'truncated = 4464' 'step 2 — rustc sample.rs -o sample' -- ./sample

ck_summary
