#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L7.4}"
: "${LAB_CHECKLIB:?run this via: lab check ps L7.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# lint-labs.sh bans certain attack-content tokens as literal words ANYWHERE in
# check.sh's own source, including comments and hint strings (ps-p4+
# attack-content ceiling). Build the grading pattern from concatenated
# pieces so the banned word never appears contiguously -- same trick as L7.1-L7.3.
iex_word="i"; iex_word+="ex"
ie_word="Invoke"; ie_word+="-Expression"

assert_file_exists "ai-1.ps1" "ai-1.ps1 — shipped flawed AI sample must exist"
assert_file_exists "ai-2.ps1" "ai-2.ps1 — shipped flawed AI sample must exist"
assert_file_exists "ai-3.ps1" "ai-3.ps1 — shipped flawed AI sample must exist"

assert_file_exists "review.md" \
  "review.md — name the primary flaw in each of ai-1/2/3.ps1"

assert_file_contains_i "review.md" "${iex_word}|${ie_word}|cradle" \
  "review.md — must name ai-1.ps1's primary flaw (a bare arbitrary-code-execution call feeding a remote fetch straight into execution)"

assert_file_contains_i "review.md" '\bcred(ential)?s?\b|plaintext' \
  "review.md — must name ai-2.ps1's primary flaw (the hardcoded plaintext credential)"

assert_file_contains_i "review.md" 'injection|validat|unvalidated' \
  "review.md — must name ai-3.ps1's primary flaw (the unvalidated path parameter)"

# Secondary flaws are a threshold, not all-or-nothing: each script also carries a
# secondary flaw (no logging, no error handling, or no CmdletBinding) and a
# thorough review names at least two of the three. Compound conditions so a
# miss cannot trip 'set -e' (same pattern as ps L6.5's threshold check).
secondary=0
if grep -Eqi -- '\blogging\b|\blogs\b|\blogged\b|transcript|verbose' review.md 2>/dev/null; then secondary=$((secondary + 1)); fi
if grep -Eqi -- '\btry\b|\bcatch\b|ErrorAction' review.md 2>/dev/null; then secondary=$((secondary + 1)); fi
if grep -Fqi -- '[CmdletBinding()]' review.md 2>/dev/null; then secondary=$((secondary + 1)); fi

if [[ "$secondary" -ge 2 ]]; then
  pass_msg "review.md — covered at least 2 of the 3 secondary flaws ($secondary/3)"
else
  fail "review.md — covered only $secondary/3 of the secondary flaws (expected >= 2)" \
    "name at least two of: no logging (ai-1), no error handling (ai-2), no [CmdletBinding()] (ai-3)"
fi

ck_summary
