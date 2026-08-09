#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L7.5}"
: "${LAB_CHECKLIB:?run this via: lab check rust L7.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains_fixed "answers.txt" 'essential=a,b,d,f,g'

assert_file_exists "spec.md"
assert_file_contains_fixed "spec.md" '@timestamp'
assert_file_contains_fixed "spec.md" 'event.outcome'
assert_file_contains "spec.md" 'panic|unwrap'
assert_file_contains "spec.md" 'malformed|skip|invalid'

ck_summary
