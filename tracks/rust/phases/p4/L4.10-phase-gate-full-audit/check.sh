#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L4.10}"
: "${LAB_CHECKLIB:?run this via: lab check rust L4.10}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains_fixed "answers.txt" 'a=CWE-197'
assert_file_contains "answers.txt" '^whyA=b$'
assert_file_contains_fixed "answers.txt" 'b=CWE-22'
assert_file_contains "answers.txt" '^whyB=b$'
assert_file_contains_fixed "answers.txt" 'c=CWE-78'
assert_file_contains "answers.txt" '^whyC=b$'
assert_file_contains_fixed "answers.txt" 'd=CWE-248'
assert_file_contains "answers.txt" '^whyD=b$'
assert_file_contains "answers.txt" '^e=logic$'
assert_file_contains "answers.txt" '^whyE=b$'
assert_file_contains_fixed "answers.txt" 'f=CWE-190'
assert_file_contains "answers.txt" '^whyF=b$'

assert_file_exists "iocscan"
assert_output_contains 'iocscan runs on good input' 'distinct = 2, total = 10' 'compile it: rustc iocscan.rs -o iocscan' -- ./iocscan

ck_summary
