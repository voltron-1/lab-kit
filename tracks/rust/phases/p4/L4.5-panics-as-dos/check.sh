#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L4.5}"
: "${LAB_CHECKLIB:?run this via: lab check rust L4.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=4$'
assert_file_contains "answers.txt" '^q2=b$'
assert_file_contains "answers.txt" '^q3=b$'
assert_file_contains "answers.txt" '^q4=b$'
assert_file_contains "answers.txt" '^q5=b$'

assert_file_exists "panic1.txt"
assert_file_contains "panic1.txt" 'panicked'

assert_file_exists "parse"
assert_output_contains 'parse happy path total' 'total = 8' 'step 3 — rustc parse.rs -o parse' -- ./parse scan=5 auth=3

ck_summary
