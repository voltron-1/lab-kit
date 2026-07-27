#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L7.5}"
: "${LAB_CHECKLIB:?run this via: lab check bash L7.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^gatefail=sc2086$'
assert_file_contains "answers.txt" '^whyexit=exitcode$'
assert_file_contains "answers.txt" '^fmtflag=-d$'
assert_file_contains "answers.txt" '^strictgate=failfast$'
assert_file_contains "answers.txt" '^sweeptrap=untracked$'

assert_file_exists "gate.sh"
assert_file_exists "scripts/bad.sh"
assert_file_contains "scripts/bad.sh" 'msg='

# Run gate script and assert gate: clean output
gate_out="$(bash ./gate.sh 2>&1)"
echo "$gate_out" | grep -q "gate: clean" || fail "gate.sh did not output 'gate: clean'"

# Anti-gaming: run shellcheck directly on scripts
(cd scripts && shellcheck -x -S style -- *.sh > /dev/null 2>&1) || fail "scripts under scripts directory are not shellcheck-clean" # lint-allow: redirect output to dev null
ck_summary
