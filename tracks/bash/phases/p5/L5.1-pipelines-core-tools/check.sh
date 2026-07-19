#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L5.1}"
: "${LAB_CHECKLIB:?run this via: lab check bash L5.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^stage4=filter$' \
  "line 4 (grep ' 401 ' access.log) — what does this stage do to the stream?"
assert_file_contains "answers.txt" '^stage5=field$' \
  "line 5 (cut -d' ' -f1) — what does this stage extract?"
assert_file_contains "answers.txt" '^stage6=(order|group)$' \
  "line 6 (sort) — what does this stage do before uniq -c can count?"
assert_file_contains "answers.txt" '^stage7=count$' \
  "line 7 (uniq -c) — what does this stage do to adjacent duplicate lines?"
assert_file_contains "answers.txt" '^stage8=rank$' \
  "line 8 (sort -rn) — what does this stage do to the counted lines?"
assert_file_contains "answers.txt" '^top_ip=203\.0\.113\.7$' \
  "run ./top-offenders.sh for real — which IP does it report?"
assert_file_contains "answers.txt" '^top_count=4$' \
  "run ./top-offenders.sh for real — what count does it report for the top IP?"
assert_cmd_ok "top-offenders.sh runs clean" \
  "it should execute with no errors under set -euo pipefail" \
  -- bash -- top-offenders.sh
assert_output_contains "reports the real top offender" '203\.0\.113\.7' \
  "the script's actual output should name the IP with the most 401s" \
  -- bash -- top-offenders.sh
ck_summary
