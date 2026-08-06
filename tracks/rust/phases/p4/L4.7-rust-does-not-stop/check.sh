#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L4.7}"
: "${LAB_CHECKLIB:?run this via: lab check rust L4.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains_fixed "answers.txt" 'q1=CWE-22'
assert_file_contains "answers.txt" '^q2=b$'
assert_file_contains_fixed "answers.txt" 'q3=CWE-78'
assert_file_contains "answers.txt" '^q4=b$'
assert_file_contains "answers.txt" '^q5=b$'
assert_file_contains "answers.txt" '^q6=b$'

assert_file_exists "fetch"
assert_output_contains 'inert traversal demo escaped the base' 'etc/shadow' 'step 2 — rustc fetch.rs -o fetch' -- ./fetch

ck_summary
