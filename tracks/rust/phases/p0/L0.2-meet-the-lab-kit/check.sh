#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L0.2}"
: "${LAB_CHECKLIB:?run this via: lab check rust L0.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^q1=b$'
assert_file_contains "answers.txt" '^q2=3$'
assert_file_contains "answers.txt" '^q3=b$'

assert_file_exists "location.txt"
tr -d '\r' < location.txt | tr -d ' \t' > .location.norm
assert_file_contains ".location.norm" "workspace/rust/L0.2"

ck_summary
