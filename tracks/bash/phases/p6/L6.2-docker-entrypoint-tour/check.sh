#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L6.2}"
: "${LAB_CHECKLIB:?run this via: lab check bash L6.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^override=nothing$' \
  "override — what does \${RELAY_PORT:=6514} do when RELAY_PORT is set?"
assert_file_contains "answers.txt" '^prepend=log-relay$' \
  "prepend — what does the case block prepend when \$1 starts with a dash?"
assert_file_contains "answers.txt" '^heredoc=expands$' \
  "heredoc — what happens to \${...} inside an unquoted heredoc?"
assert_file_contains "answers.txt" '^probe=devtcp$' \
  "probe — what mechanism performs the reachability probe?"
assert_file_contains "answers.txt" '^handoff=exec$' \
  "handoff — which single word hands PID 1 to the service?"
assert_file_contains "answers.txt" '^exposure=listen$' \
  "exposure — which default would a reviewer question first as wide exposure?"

ck_summary
