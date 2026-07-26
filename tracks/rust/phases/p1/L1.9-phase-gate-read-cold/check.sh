#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L1.9}"
: "${LAB_CHECKLIB:?run this via: lab check rust L1.9}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=Benign$'
assert_file_contains "answers.txt" '^q2=Suspicious$'
assert_file_contains "answers.txt" '^q3=Hostile$'
assert_file_contains "answers.txt" '^q4=1$'
assert_file_contains "answers.txt" '^q5=18$'
assert_file_contains "answers.txt" '^q6=3389$'
assert_file_contains "answers.txt" '^q7=3$'
assert_file_contains "answers.txt" '^q8=b$'
assert_file_contains "answers.txt" '^q9=b$'
assert_file_contains "answers.txt" '^q10=b$'

assert_file_exists "triage"
assert_output_contains 'triage binary runs' 'watch port 3389' 'compile it: rustc triage.rs -o triage' -- ./triage

ck_summary
