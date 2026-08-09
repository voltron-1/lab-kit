#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L7.4}"
: "${LAB_CHECKLIB:?run this via: lab check rust L7.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^g1=b$'
assert_file_contains "answers.txt" '^g2=b$'
assert_file_contains "answers.txt" '^g3=a$'
assert_file_contains "answers.txt" '^g4=b$'
assert_file_contains "answers.txt" '^g5=b$'

assert_file_exists "guardrails.sh"
assert_file_contains "guardrails.sh" 'clippy'
assert_file_contains "guardrails.sh" 'audit'
assert_file_contains "guardrails.sh" 'deny'
assert_file_contains "guardrails.sh" 'test'

ck_summary
