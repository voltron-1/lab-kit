#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L0.3}"
: "${LAB_CHECKLIB:?run this via: lab check rust L0.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=scanport$'
assert_file_contains "answers.txt" '^q2=src/main\.rs$'
assert_file_contains "answers.txt" '^q3=src/lib\.rs$'
assert_file_contains "answers.txt" '^q4=0$'
assert_file_contains "answers.txt" '^q5=b$'
assert_file_contains "answers.txt" '^q6=a$'

assert_file_exists "run_out.txt"
assert_file_contains_fixed "run_out.txt" '22 -> ok (port 22)'
assert_file_contains_fixed "run_out.txt" '99999 -> INVALID'
assert_file_exists "scanport/target/doc/scanport/index.html"

ck_summary
