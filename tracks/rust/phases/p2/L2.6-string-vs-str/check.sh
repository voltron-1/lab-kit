#!/usr/bin/env bash
set -euo pipefail

: "${LAB_WORKSPACE:?LAB_WORKSPACE environment variable must be set}"
: "${LAB_CHECKLIB:?LAB_CHECKLIB environment variable must be set}"

# shellcheck disable=SC1090
source "$LAB_CHECKLIB"

cd "$LAB_WORKSPACE"

assert_file_exists "answers.txt"
assert_file_contains answers.txt '^q1=c$'
assert_file_contains answers.txt '^q2=https$'
assert_file_contains answers.txt '^q3=tcp$'
assert_file_contains answers.txt '^q4=18$'
assert_file_contains answers.txt '^q5=b$'

assert_output_contains "sample runs" "scheme = ldap" "sample binary execution" -- ./sample

ck_summary
