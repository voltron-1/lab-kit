#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L4.6}"
: "${LAB_CHECKLIB:?run this via: lab check soc L4.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=btp"
assert_file_contains ".answers.norm" "^q1t=(host:srv-backup|cmdline:robocopy)$"
assert_file_contains_fixed ".answers.norm" "q2=btp"
assert_file_contains ".answers.norm" "^q2t=(user:t.aoki|window:chg)$"
assert_file_contains_fixed ".answers.norm" "q3=fp"
assert_file_contains_fixed ".answers.norm" "q3t=path:securityawareness"
assert_file_contains_fixed ".answers.norm" "q4=tp"
assert_file_contains_fixed ".answers.norm" "q4t=none"

ck_summary
