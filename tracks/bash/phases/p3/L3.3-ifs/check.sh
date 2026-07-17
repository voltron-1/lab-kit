#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L3.3}"
: "${LAB_CHECKLIB:?run this via: lab check bash L3.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^default_argc=3$' \
  "run split-demo.sh — how many words is 'a b c' under default IFS?"
assert_file_contains "answers.txt" '^passwd_fields=7$' \
  "with IFS=':' how many colon-separated fields in the passwd line?"
assert_file_contains "answers.txt" '^empty_argc=1$' \
  "with IFS='' does 'a b c' split at all?"
assert_file_contains "answers.txt" '^ifs_controls=splitting$' \
  "one word: IFS decides how the shell cuts unquoted expansions into ___"
assert_file_contains "answers.txt" '^attack=' \
  "one line: how can an inherited/hostile IFS re-steer a for loop over an unquoted expansion?"
ck_summary
