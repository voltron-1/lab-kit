#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L7.4}"
: "${LAB_CHECKLIB:?run this via: lab check bash L7.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^s1_worst=unsetvar$'
assert_file_contains "answers.txt" '^s1_savedby=nounset$'
assert_file_contains "answers.txt" '^s2_findings=0$'
assert_file_contains "answers.txt" '^s2_fetch=nofail$'
assert_file_contains "answers.txt" '^s2_integrity=checksum$'
assert_file_contains "answers.txt" '^s2_temppath=predictable$'
assert_file_contains "answers.txt" '^s2_model=l6.5$'
assert_file_contains "answers.txt" '^s3_severity=sc2045$'
assert_file_contains "answers.txt" '^s3_breaks=spaces$'
assert_file_contains "answers.txt" '^s3_useless=cat$'
assert_file_contains "answers.txt" '^cleanest=gen2$'
assert_file_contains "answers.txt" '^lesson=floor$'

ck_summary
