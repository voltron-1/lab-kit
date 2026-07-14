#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L0.2}"
: "${LAB_CHECKLIB:?run this via: lab check bash L0.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^q1=b$' \
  "step 4 — q1: which verb re-primes you after a month away? the answer is a line in kit-notes.txt"
assert_file_contains "answers.txt" '^q2=3$' \
  "step 4 — q2: count the hint-ladder levels named in kit-notes.txt"
assert_file_contains "answers.txt" '^q3=b$' \
  "step 4 — q3: kit-notes.txt spells out the all-or-nothing check rule"
location_hint="step 5 — run: pwd > location.txt while inside workspace/bash/L0.2"
if [[ -f location.txt ]]; then
  recorded_dir="$(realpath -m -- "$(cat location.txt)")"
  workspace_dir="$(realpath -- "$LAB_WORKSPACE")"
  if [[ "$recorded_dir" == "$workspace_dir" ]]; then
    pass_msg "location.txt was written from inside the workspace"
  else
    fail "location.txt was written from inside the workspace" "$location_hint"
  fi
else
  fail "location.txt missing" "$location_hint"
fi

ck_summary
