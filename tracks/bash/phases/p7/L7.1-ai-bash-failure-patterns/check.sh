#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L7.1}"
: "${LAB_CHECKLIB:?run this via: lab check bash L7.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^strictmode=pipefail$'
assert_file_contains "answers.txt" '^cdrisk=wrongdir$'
assert_file_contains "answers.txt" '^execflaw=evalhook$'
assert_file_contains "answers.txt" '^sc2164=sc2164$'
assert_file_contains "answers.txt" '^sc2006=sc2006$'
assert_file_contains "answers.txt" '^blindspot=evalhook$'
assert_file_contains "answers.txt" '^tell=comments$'

ck_summary
