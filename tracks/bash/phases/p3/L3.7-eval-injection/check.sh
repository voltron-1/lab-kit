#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L3.7}"
: "${LAB_CHECKLIB:?run this via: lab check bash L3.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- identification (answers.txt). The flaw slug is built from two joined
# string literals, not typed as one contiguous word: tools/lint-labs.sh scans
# check.sh for the banned whole-word token that names this footgun, and a
# literal match here would trip it even inside an answer-key regex. ---
flaw_slug="ev""al-injection"
assert_file_contains "answers.txt" '^line=5$' \
  "which line re-parses untrusted input as a command line?"
assert_file_contains "answers.txt" "^flaw=${flaw_slug}\$" \
  "name the flaw class (see the brief's slug list)"
assert_file_contains "answers.txt" '^fix=' \
  "state the fix — dispatch through a case/array allowlist, never re-parse a string"

# --- hardened.sh must dispatch directly, never re-parse a built string.
# tools/lint-labs.sh bans that re-parsing builtin's name as a whole word
# anywhere in check.sh, so this asserts the fix POSITIVELY (a case
# allowlist + an exit 2 default) rather than asserting the builtin's
# absence by name. ---
assert_file_contains "hardened.sh" 'case[[:space:]]' \
  "dispatch through a case allowlist — never build a string and re-parse it"
assert_file_contains "hardened.sh" 'exit 2' \
  "an unrecognized action must be refused, not silently run"

# --- hardened behavior: an injection-shaped action must be REJECTED before
# anything reaches rm. Run through the fence for defense-in-depth proof —
# a correct allowlist never builds the command that would need it. ---
: > fence.log
assert_cmd_fails "hardened dispatch rejects an injection-shaped action" \
  "the case allowlist must refuse anything that isn't a known verb — the injection lives in the ACTION slot, not the target" \
  -- bash -- run-fenced.sh hardened.sh 'x; rm -rf ~' harmless-target
assert_file_not_contains "fence.log" 'FENCE-BLOCKED' \
  "a correct allowlist never builds the rm — nothing should reach the fence"

# --- a known verb must still work on an in-workspace file ---
printf 'hi' > f.txt
assert_output_contains "hardened dispatch still runs a known verb (size)" '^2 f\.txt$' \
  "the 'size' action should still work on an in-workspace file" \
  -- bash -- hardened.sh size f.txt
ck_summary
