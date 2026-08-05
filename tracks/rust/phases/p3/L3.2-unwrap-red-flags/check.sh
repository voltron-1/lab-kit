#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L3.2}"
: "${LAB_CHECKLIB:?run this via: lab check rust L3.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=4$'
assert_file_contains "answers.txt" '^q2=3$'
assert_file_contains "answers.txt" '^q3=b$'
assert_file_contains "answers.txt" '^q4=a$'
assert_file_contains "answers.txt" '^q5=b$'

assert_file_exists "panic1.txt"
assert_file_contains "panic1.txt" 'panicked'

assert_file_exists "ingest"
assert_output_contains 'ingest happy path' 'scan accepted \(512 bytes\)' 'step 3 — rustc ingest.rs -o ingest, then run with scan:512' -- ./ingest scan:512

ck_summary
