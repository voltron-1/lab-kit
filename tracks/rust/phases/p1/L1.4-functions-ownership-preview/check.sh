#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L1.4}"
: "${LAB_CHECKLIB:?run this via: lab check rust L1.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains "answers.txt" '^q2=b$'
assert_file_contains "answers.txt" '^q3=E0382$'

assert_file_exists "sample"
assert_output_contains 'sample runs (re-commented after step 4)' 'PORT SCAN DETECTED' 'step 5 — put the comment back and recompile: rustc sample.rs -o sample' -- ./sample
assert_output_contains '18 bytes line' '18 bytes' 'step 3 — rustc sample.rs -o sample' -- ./sample

ck_summary
