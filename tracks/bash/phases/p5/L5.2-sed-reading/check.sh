#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L5.2}"
: "${LAB_CHECKLIB:?run this via: lab check bash L5.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^dash_e=extended$' \
  "the -E flag on sed — what kind of regex does it switch to?"
assert_file_contains "answers.txt" '^flag_g=global$' \
  "the trailing g in s/pat/repl/g — replace just the first match, or every match on the line?"
assert_file_contains "answers.txt" '^purpose5=(mask|redact)$' \
  "line 5's substitution — what does it do to every IPv4 address on the line?"
assert_file_contains "answers.txt" '^purpose6=reorder$' \
  "line 6's substitution — it doesn't delete fields, it does what to them?"
assert_file_contains "answers.txt" '^backslash1=capture$' \
  "\\1 in the replacement text — what kind of thing does it refer to?"
assert_cmd_ok "redact.sh runs clean" \
  "it should execute with no errors under set -euo pipefail" \
  -- bash -- redact.sh
assert_output_contains "redacted output shows the reordered fields" 'ts=18/Jul/2026:10:12:01' \
  "the script's actual output should show the reordered ts=/method=/path=/status= fields" \
  -- bash -- redact.sh
ck_summary
