#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L3.8}"
: "${LAB_CHECKLIB:?run this via: lab check bash L3.8}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- GUIDED: sample.sh is never executed, only read through ShellCheck.
# Grade the learner's classification in answers.txt. No decoy, no fence. ---
assert_file_contains "answers.txt" '^sc2115=security$' \
  "SC2115 (rm -rf could hit the filesystem root) — security-critical or cosmetic?"
assert_file_contains "answers.txt" '^sc2086=security$' \
  "SC2086 (unquoted var) — which class?"
assert_file_contains "answers.txt" '^sc2035=security$' \
  "SC2035 (dash-filename glob) — which class?"
assert_file_contains "answers.txt" '^sc2034=cosmetic$' \
  "SC2034 (unused variable) — security or cosmetic?"
assert_file_contains "answers.txt" '^sc2006=cosmetic$' \
  "SC2006 (backticks) — security or cosmetic?"
# tools/lint-labs.sh bans L3.7's re-parsing builtin's name as a whole word
# anywhere in check.sh, so the accepted-answer regex below is built from two
# joined string literals rather than typed as one contiguous word.
blindspot_re="^blindspot=.*(ev""al|arith|strict|pipefail|injection)"
assert_file_contains "answers.txt" '^blindspot=' \
  "name ONE thing ShellCheck cannot catch (the L3.7 re-parsing construct, arithmetic injection, or missing strict mode)"
assert_file_contains "answers.txt" "$blindspot_re" \
  "the blind spot named on the blindspot= line must be a real one from this phase"
ck_summary
