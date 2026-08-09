#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L4.3}"
: "${LAB_CHECKLIB:?run this via: lab check soc L4.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=fp"
assert_file_contains_fixed ".answers.norm" "q1t=sharedhosting"
assert_file_contains_fixed ".answers.norm" "q2=fp"
assert_file_contains_fixed ".answers.norm" "q2t=cdn"
assert_file_contains_fixed ".answers.norm" "q3=fp"
assert_file_contains_fixed ".answers.norm" "q3t=stale"

ck_summary
