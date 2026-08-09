#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L7.3}"
: "${LAB_CHECKLIB:?run this via: lab check rust L7.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^s1a=availability$'
assert_file_contains "answers.txt" '^s1b=input-validation$'
assert_file_contains "answers.txt" '^s2a=input-validation$'
assert_file_contains "answers.txt" '^s2b=input-validation$'
assert_file_contains "answers.txt" '^s3a=availability$'
assert_file_contains "answers.txt" '^s3b=availability$'

assert_file_contains_fixed "answers.txt" 's1cwe=CWE-248'
assert_file_contains_fixed "answers.txt" 's1trunc=CWE-197'
assert_file_contains_fixed "answers.txt" 's2trav=CWE-22'
assert_file_contains_fixed "answers.txt" 's2inj=CWE-78'
assert_file_contains_fixed "answers.txt" 's3panic=CWE-248'
assert_file_contains_fixed "answers.txt" 's3exh=CWE-400'

ck_summary
