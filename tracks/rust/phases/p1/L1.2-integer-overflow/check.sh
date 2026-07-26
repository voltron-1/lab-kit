#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L1.2}"
: "${LAB_CHECKLIB:?run this via: lab check rust L1.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "predictions.txt"
assert_file_contains "predictions.txt" '^debug=panic$'
assert_file_contains "predictions.txt" '^release=0$'
assert_file_contains "predictions.txt" '^checked=None$'
assert_file_contains "predictions.txt" '^wrapped=0$'

assert_file_exists "debug_out.txt"
assert_file_contains_fixed "debug_out.txt" 'attempt to add with overflow'
assert_file_exists "release_out.txt"
assert_file_contains_fixed "release_out.txt" 'bumped = 0'

ck_summary
