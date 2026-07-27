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

assert_file_exists "fixed1.rs"
assert_file_not_contains fixed1.rs "clone"

assert_file_exists "fixed2.rs"
assert_file_exists "fixed3.rs"

assert_output_contains "fixed1 keeps title usable" "original: scan report" "fixed1 binary execution" -- ./fixed1
assert_output_contains "fixed2 both counters bumped" "\[11, 12, 3\]" "fixed2 binary execution" -- ./fixed2
assert_output_contains "fixed3 read-then-grow" "entries = 2" "fixed3 binary execution" -- ./fixed3

ck_summary
