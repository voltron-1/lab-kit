#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L7.2}"
: "${LAB_CHECKLIB:?run this via: lab check bash L7.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^whystrict=silentsuccess$'
assert_file_contains "answers.txt" '^whyaccept=mechanical$'
assert_file_contains "answers.txt" '^whyban=code$'

assert_file_exists "spec.md"
assert_file_contains "spec.md" '^## 1\. Non-negotiable preamble'
assert_file_contains "spec.md" '^## 2\. Quoting rule'
assert_file_contains "spec.md" '^## 3\. Input validation'
assert_file_contains "spec.md" '^## 4\. Forbidden constructs'
assert_file_contains "spec.md" '^## 5\. Error handling'
assert_file_contains "spec.md" '^## 6\. Acceptance criteria'

assert_file_contains "spec.md" '^preamble=set -euo pipefail$'
assert_file_contains "spec.md" '^quoting=always$'
assert_file_contains "spec.md" '^validation=reject-unset$'
assert_file_contains "spec.md" '^forbidden=evalstring$'
assert_file_contains "spec.md" '^errors=fail-loud$'
assert_file_contains "spec.md" '^acceptance=shellcheck-clean$'

ck_summary
