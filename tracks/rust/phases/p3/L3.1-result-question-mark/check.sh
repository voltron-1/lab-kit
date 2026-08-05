#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L3.1}"
: "${LAB_CHECKLIB:?run this via: lab check rust L3.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains "answers.txt" '^q2=a$'
assert_file_contains "answers.txt" '^q3=443$'
assert_file_contains "answers.txt" '^q4=b$'
assert_file_contains "answers.txt" '^error=E0277$'

assert_file_exists "sample"
assert_output_contains 'sample ok path' '443 -> port 443' 'step 2 — rustc sample.rs -o sample' -- ./sample

ck_summary
