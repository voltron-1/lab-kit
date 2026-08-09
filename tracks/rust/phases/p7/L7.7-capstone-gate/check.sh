#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L7.7}"
: "${LAB_CHECKLIB:?run this via: lab check rust L7.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^a1=b$'
assert_file_contains "answers.txt" '^a2=b$'
assert_file_contains "answers.txt" '^a3=b$'
assert_file_contains "answers.txt" '^a4=b$'
assert_file_contains "answers.txt" '^a5=b$'
assert_file_contains "answers.txt" '^a6=3$'

assert_file_exists "ecs_out.txt"
assert_file_contains_fixed "ecs_out.txt" '"@timestamp"'
assert_file_contains_fixed "ecs_out.txt" '"event.outcome":"failure"'
assert_file_contains_fixed "ecs_out.txt" '"source.ip":"203.0.113.9"'

ck_summary
