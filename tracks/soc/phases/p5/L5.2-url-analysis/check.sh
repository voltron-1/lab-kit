#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check soc L5.2}"
: "${LAB_CHECKLIB:?run this via: lab check soc L5.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"

if [[ -f "answers.txt" ]]; then
  tr '[:upper:]' '[:lower:]' < answers.txt | sed 's@#.*@@' | tr -d '' | sed 's@[[:space:]]*$@@' > .answers.norm
else
  : > .answers.norm
fi

assert_file_contains_fixed ".answers.norm" "q1=cdn.stonewick[.]example"
assert_file_contains_fixed ".answers.norm" "q2=copperm1ne-billing[.]example"
assert_file_contains ".answers.norm" "^q3=(coppermïne\[\.\]example|coppermine\[\.\]example)$"
assert_file_contains_fixed ".answers.norm" "q4=coppermine[.]example"
assert_file_contains_fixed ".answers.norm" "q5=3"

ck_summary
