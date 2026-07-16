#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L3.2}"
: "${LAB_CHECKLIB:?run this via: lab check bash L3.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- identification (answers.txt) ---
assert_file_contains "answers.txt" '^line=5$' \
  "which single line turns catastrophic when BUILD_DIR is empty?"
assert_file_contains "answers.txt" '^flaw=empty-var-rm$' \
  "name the flaw class (see the brief's slug list)"
assert_file_contains "answers.txt" '^fix=' \
  "state the fix — the :? guard or set -u making empty fatal"
assert_file_contains "answers.txt" '(:\?|set -u|nounset)' \
  "the fix must make an EMPTY variable fatal before rm runs"

# --- the fence engaged on the flawed demo (guided step wrote fence.log) ---
assert_file_contains_fixed "fence.log" 'FENCE-BLOCKED: rm -rf' \
  "run the demo via run-fenced.sh first so fence.log shows the blocked rm -rf line"

# --- hardened script must exist before we try to run it — otherwise the
# next assert_cmd_fails would pass for the wrong reason (source failing on
# a missing file, not the :? guard firing) ---
assert_file_exists "hardened.sh" \
  "author hardened.sh from scratch — strict mode plus a :? guard on BUILD_DIR"

# --- hardened script fails SAFE with an empty var, under the fence ---
make_decoy_tree c
: > fence.log
export BUILD_DIR=""
assert_cmd_fails "hardened cleanup aborts when BUILD_DIR is empty" \
  "your :? guard or set -u fix must stop the script before rm runs" \
  -- bash -- run-fenced.sh hardened.sh
unset BUILD_DIR
assert_file_not_contains "fence.log" 'FENCE-BLOCKED' \
  "the hardened script must abort BEFORE rm — nothing should reach the fence"
decoy_intact c
ck_summary
