#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L7.1}"
: "${LAB_CHECKLIB:?run this via: lab check rust L7.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains_fixed "answers.txt" 'essential=a,c,d,f'

assert_file_exists "spec.md"
assert_file_contains "spec.md" 'Result|Option'
assert_file_contains "spec.md" '1\.\.=65535|range|1-65535'
assert_file_contains "spec.md" 'panic|unwrap'

ck_summary
