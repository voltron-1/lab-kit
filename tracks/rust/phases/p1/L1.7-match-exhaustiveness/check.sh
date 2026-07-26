#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L1.7}"
: "${LAB_CHECKLIB:?run this via: lab check rust L1.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^error_code=E0004$'

assert_file_exists "fixed.rs"
assert_file_contains "fixed.rs" 'Severity::Critical[[:space:]]*=>'
assert_file_not_contains "fixed.rs" '_[[:space:]]*=>'

assert_file_exists "fixed"
assert_output_contains 'fixed binary handles Critical' 'isolate host' 'step 3 — rustc fixed.rs -o fixed' -- ./fixed

ck_summary
