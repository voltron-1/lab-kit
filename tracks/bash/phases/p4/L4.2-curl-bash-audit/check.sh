#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L4.2}"
: "${LAB_CHECKLIB:?run this via: lab check bash L4.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^verdict=unsafe$' \
  "would you ever pipe this into a shell? name the verdict"
assert_file_contains "answers.txt" '^flag1=remote-exec$' \
  "line 8 chains a SECOND remote script straight into sh, unread"
assert_file_contains "answers.txt" '^flag2=privilege$' \
  "line 9 silently claims root privilege with no explanation"
assert_file_contains "answers.txt" '^flag3=http-binary$' \
  "line 11 downloads a binary over plain HTTP, then runs it"
assert_file_contains "answers.txt" '^flag4=persistence$' \
  "line 14 writes itself into .bashrc so it re-runs on every new shell"
assert_file_contains "answers.txt" '^flag5=exfil$' \
  "line 15 posts \$(env) — your whole environment — to a remote endpoint"
assert_file_contains "answers.txt" '^safe_alternative=' \
  "state the safe habit — what should you do with an installer like this instead?"
assert_file_contains "answers.txt" '(download|read|inspect|review)' \
  "the safe alternative must involve reading the script before running it"
ck_summary
