#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L1.5}"
: "${LAB_CHECKLIB:?run this via: lab check rust L1.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains "answers.txt" '^q2=port,tls$'
assert_file_contains "answers.txt" '^q3=c$'

assert_file_exists "sample"
assert_output_contains 'sample runs' 'port: 8080' 'step 2 — rustc sample.rs -o sample' -- ./sample
assert_output_contains 'a still owns its host' 'a\.host = 127\.0\.0\.1' 'step 2 — rustc sample.rs -o sample' -- ./sample

ck_summary
