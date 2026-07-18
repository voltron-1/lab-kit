#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L4.1}"
: "${LAB_CHECKLIB:?run this via: lab check bash L4.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- identification (answers.txt) ---
assert_file_contains "answers.txt" '^line=5$' \
  "which line hands a shell string built from untrusted input to a nested shell?"
assert_file_contains "answers.txt" '^flaw=command-injection$' \
  "name the flaw class (see the brief's slug list)"
assert_file_contains "answers.txt" '^cwe=CWE-78$' \
  "name the CWE for OS command injection"
assert_file_contains "answers.txt" '^fix=' \
  "state the fix — call the program directly, no built shell string"
assert_file_contains "answers.txt" '(argument|separate|quote)' \
  "the fix must pass the value as DATA — a separate quoted argument, not text a shell re-parses"

assert_file_exists "hardened.sh" \
  "author hardened.sh from scratch — call grep directly, no built command string to re-parse"
assert_file_contains "hardened.sh" 'grep' \
  "call grep directly on \$name — a lookup that never searches greetings.txt isn't a real fix"

# --- hardened script must never re-parse the name as a command line — prove
# it survives an injection-shaped name safely, and nothing reaches the fence ---
: > fence.log
assert_cmd_ok "hardened lookup runs safely on an injection-shaped name" \
  "your fix must not crash on an injection-shaped name — treat it as literal search text, never re-parsed" \
  -- bash -- run-fenced.sh hardened.sh 'x; rm -rf ~ #'
assert_file_not_contains "fence.log" 'FENCE-BLOCKED' \
  "the injection-shaped name must never reach rm — no re-parse means no injection"

# --- a known name must still resolve correctly ---
assert_output_contains "hardened lookup still finds a known name" '^alice:Hello, Alice!$' \
  "the 'alice' lookup should still work exactly like the original" \
  -- bash -- hardened.sh alice
ck_summary
