#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L2.4}"
: "${LAB_CHECKLIB:?run this via: lab check rust L2.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^error_code=E0502$'
assert_file_contains "answers.txt" '^q2=b$'
assert_file_contains "answers.txt" '^q3=b$'

assert_file_exists "fixed.rs"
assert_file_not_contains "fixed.rs" 'clone'

assert_file_exists "fixed"
assert_output_contains 'fixed reads before mutating' 'snapshot = alert-1' 'step 4 — rustc fixed.rs -o fixed' -- ./fixed
assert_output_contains 'fixed queue grew' 'queue = alert-1,alert-2' 'step 4 — the push_str must still happen' -- ./fixed

ck_summary
