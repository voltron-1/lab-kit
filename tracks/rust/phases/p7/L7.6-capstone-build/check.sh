#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L7.6}"
: "${LAB_CHECKLIB:?run this via: lab check rust L7.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^f1=availability$'
assert_file_contains "answers.txt" '^f2=availability$'
assert_file_contains "answers.txt" '^f3=correctness$'
assert_file_contains "answers.txt" '^f4=availability$'
assert_file_contains "answers.txt" '^escaping=ok$'

assert_file_contains_fixed "answers.txt" 'f1cwe=CWE-248'
assert_file_contains_fixed "answers.txt" 'f2cwe=CWE-248'
assert_file_contains_fixed "answers.txt" 'f4cwe=CWE-248'

assert_file_exists "direction.md"
assert_file_contains "direction.md" 'len|get|bounds|check'
assert_file_contains "direction.md" 'outcome|success|failure|map'

ck_summary
