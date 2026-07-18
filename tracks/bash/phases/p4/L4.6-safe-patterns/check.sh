#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L4.6}"
: "${LAB_CHECKLIB:?run this via: lab check bash L4.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^validation=allowlist$' \
  "line 6's case statement — is it an allowlist or a denylist?"
assert_file_contains "answers.txt" '^grep_f=literal$' \
  "grep's -F flag — does it treat \$name as a literal string or a regex?"
assert_file_contains "answers.txt" '^dashdash=options$' \
  "the -- before \"\$name\" — what does it end?"
assert_file_contains "answers.txt" '^path=absolute$' \
  "line 4's PATH assignment — is it absolute or relative?"
assert_file_contains "answers.txt" '^safest=arguments$' \
  "one word: the single most important habit for untrusted input is passing it as ___, never as text a shell re-parses"
ck_summary
