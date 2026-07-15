#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L2.7}"
: "${LAB_CHECKLIB:?run this via: lab check bash L2.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "good-run.txt" 'installed: payload.installed' \
  "step 3 — capture the good run: the payload.txt run installs and says so"
assert_file_contains "good-run.txt" '^exit=0$' \
  "good-run.txt needs the appended exit= line — rerun both step-3 commands"
assert_file_contains "bad-run.txt" 'cleanup: staging file removed' \
  "step 4 — capture the bad run with 2>&1: the trap's message travels on stderr"
assert_file_not_contains "bad-run.txt" 'verified' \
  "bad-run.txt should show the death BEFORE verification — did you run payload-bad.txt?"
assert_file_contains "bad-run.txt" '^exit=1$' \
  "the trap does not overwrite the verdict: the bad run reports grep's own code"
assert_file_missing "payload.staging" \
  "no staging debris may survive — the trap removes it on every exit; rerun step 4 and look"
assert_file_exists "payload.installed" \
  "step 3's good run installs the payload — rerun it if the file is missing"
assert_file_contains "answers.txt" '^q1=b$' \
  "q1 — one letter: what does EXIT mean in trap cleanup EXIT?"
assert_file_contains "answers.txt" '^q2=1$' \
  "q2 — transcribe the digit from bad-run.txt's exit= line"
assert_file_contains "answers.txt" '^q3=b$' \
  "q3 — ls after the bad run: what happened to payload.staging?"
assert_file_contains "answers.txt" '^q4=b$' \
  "q4 — imagine the trap registered AFTER the cp: which deaths would escape cleanup?"
ck_summary
