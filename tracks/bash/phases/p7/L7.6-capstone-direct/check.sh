#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L7.6}"
: "${LAB_CHECKLIB:?run this via: lab check bash L7.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^sc_count=3$'
assert_file_contains "answers.txt" '^realflaw=injection$'
assert_file_contains "answers.txt" '^whyquiet=quoted$'
assert_file_contains "answers.txt" '^tempflaw=predictable$'
assert_file_contains "answers.txt" '^appendbug=double$'
assert_file_contains "answers.txt" '^checklist=c4-noeval$'

assert_file_exists "ingest-spec.md"
assert_file_contains "ingest-spec.md" '^input=validate$'
assert_file_contains "ingest-spec.md" '^temp=mktemp$'
assert_file_contains "ingest-spec.md" '^filter=no-user-filter$'
assert_file_contains "ingest-spec.md" '^malformed=skip-and-count$'
assert_file_contains "ingest-spec.md" '^accept=shellcheck-clean$'

ck_summary
