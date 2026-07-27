#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L7.3}"
: "${LAB_CHECKLIB:?run this via: lab check bash L7.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^firstcheck=c1-strictmode$'
assert_file_contains "answers.txt" '^lastcheck=c8-shellcheck$'
assert_file_contains "answers.txt" '^invisible=c4-noeval$'
assert_file_contains "answers.txt" '^advisory=c7-cleanup$'
assert_file_contains "answers.txt" '^anchoring=anchoring$'

assert_file_exists "checklist.md"
assert_file_contains "checklist.md" '^c1-strictmode[[:space:]]+.+$'
assert_file_contains "checklist.md" '^c2-quoting[[:space:]]+.+$'
assert_file_contains "checklist.md" '^c3-input[[:space:]]+.+$'
assert_file_contains "checklist.md" '^c4-noeval[[:space:]]+.+$'
assert_file_contains "checklist.md" '^c5-cdguard[[:space:]]+.+$'
assert_file_contains "checklist.md" '^c6-tempfiles[[:space:]]+.+$'
assert_file_contains "checklist.md" '^c7-cleanup[[:space:]]+.+$'
assert_file_contains "checklist.md" '^c8-shellcheck[[:space:]]+.+$'

ck_summary
