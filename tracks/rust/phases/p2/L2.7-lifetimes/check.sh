#!/usr/bin/env bash
set -euo pipefail

: "${LAB_WORKSPACE:?LAB_WORKSPACE environment variable must be set}"
: "${LAB_CHECKLIB:?LAB_CHECKLIB environment variable must be set}"

# shellcheck disable=SC1090
source "$LAB_CHECKLIB"

cd "$LAB_WORKSPACE"

assert_file_exists "answers.txt"
assert_file_contains answers.txt '^q1=b$'
assert_file_contains answers.txt '^q2=credential-stuffing$'
assert_file_contains answers.txt '^q3=b$'
assert_file_contains answers.txt '^q4=b$'
assert_file_contains answers.txt '^q5=E0597$'

assert_output_contains "sample runs (experiment reverted)" "rule = credential-stuffing" "sample binary execution" -- ./sample

ck_summary
