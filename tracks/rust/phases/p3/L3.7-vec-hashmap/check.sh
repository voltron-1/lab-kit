#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L3.7}"
: "${LAB_CHECKLIB:?run this via: lab check rust L3.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains "answers.txt" '^q2=3$'
assert_file_contains "answers.txt" '^q3=b$'
assert_file_contains "answers.txt" '^q4=a$'
assert_file_contains "answers.txt" '^q5=0$'

assert_file_exists "sample"
assert_output_contains 'sample runs, sorted keys' 'kinds = \["login", "probe", "scan"\]' 'step 2 — rustc sample.rs -o sample' -- ./sample

ck_summary
