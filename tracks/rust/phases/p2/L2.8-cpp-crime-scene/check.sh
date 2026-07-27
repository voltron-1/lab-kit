#!/usr/bin/env bash
set -euo pipefail

: "${LAB_WORKSPACE:?LAB_WORKSPACE environment variable must be set}"
: "${LAB_CHECKLIB:?LAB_CHECKLIB environment variable must be set}"

# shellcheck disable=SC1090
source "$LAB_CHECKLIB"

cd "$LAB_WORKSPACE"

assert_file_exists "answers.txt"
assert_file_contains answers.txt '^q1=CWE-416$'
assert_file_contains answers.txt '^q2=b$'
assert_file_contains answers.txt '^q3=E0502$'
assert_file_contains answers.txt '^q4=b$'
assert_file_contains answers.txt '^q5=b$'

assert_file_exists "rust_error.txt"
assert_file_contains rust_error.txt 'error\[E0502\]'

ck_summary
