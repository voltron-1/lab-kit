#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L5.5}"
: "${LAB_CHECKLIB:?run this via: lab check bash L5.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^construct4=procsub$' \
  "line 4's two <(...) forms, <(sort allowed.txt) and <(sort seen.txt) — what construct is this?"
assert_file_contains "answers.txt" '^construct8=herestring$' \
  "line 8's <<< \"\$last_event\" — what construct is this?"
assert_file_contains "answers.txt" '^construct14=heredoc$' \
  "the cat <<REPORT ... REPORT block — what construct is this?"
assert_file_contains "answers.txt" '^expands=yes$' \
  "inside the unquoted <<REPORT heredoc, do \$variables expand or print literally?"
assert_cmd_ok "compare-hosts.sh runs clean" \
  "it should execute with no errors under set -euo pipefail" \
  -- bash -- compare-hosts.sh
assert_output_contains "flags the unexpected host" 'host-x\.test' \
  "the script's actual output should call out host-x.test as a new/flagged host" \
  -- bash -- compare-hosts.sh
ck_summary
