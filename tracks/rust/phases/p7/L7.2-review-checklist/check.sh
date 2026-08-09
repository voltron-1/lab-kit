#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L7.2}"
: "${LAB_CHECKLIB:?run this via: lab check rust L7.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^rf1=availability$'
assert_file_contains "answers.txt" '^rf2=memory-safety$'
assert_file_contains "answers.txt" '^rf3=input-validation$'
assert_file_contains "answers.txt" '^rf4=input-validation$'
assert_file_contains "answers.txt" '^rf5=availability$'
assert_file_contains "answers.txt" '^rf6=supply-chain$'
assert_file_contains "answers.txt" '^rf7=input-validation$'
assert_file_contains "answers.txt" '^rf8=memory-safety$'

assert_file_exists "checklist.md"
assert_file_contains "checklist.md" 'memory-safety|unsafe|SAFETY'
assert_file_contains "checklist.md" 'availability|panic|unwrap|timeout'
assert_file_contains "checklist.md" 'input|validation|traversal|injection'
assert_file_contains "checklist.md" 'supply-chain|audit|RUSTSEC'

ck_summary
