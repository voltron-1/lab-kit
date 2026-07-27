#!/usr/bin/env bash
set -euo pipefail

: "${LAB_WORKSPACE:?LAB_WORKSPACE environment variable must be set}"
: "${LAB_CHECKLIB:?LAB_CHECKLIB environment variable must be set}"

# shellcheck disable=SC1090
source "$LAB_CHECKLIB"

cd "$LAB_WORKSPACE"

assert_file_exists "answers.txt"
assert_file_contains answers.txt '^e1=E0382$'
assert_file_contains answers.txt '^c1=a$'
assert_file_contains answers.txt '^e2=E0499$'
assert_file_contains answers.txt '^c2=b$'
assert_file_contains answers.txt '^e3=E0502$'
assert_file_contains answers.txt '^c3=c$'
assert_file_contains answers.txt '^e4=E0515$'
assert_file_contains answers.txt '^c4=d$'
assert_file_contains answers.txt '^e5=E0597$'
assert_file_contains answers.txt '^c5=e$'

assert_file_exists "fixed5.rs"

assert_output_contains "fixed5 runs" "short-lived" "fixed5 binary execution" -- ./fixed5

ck_summary
