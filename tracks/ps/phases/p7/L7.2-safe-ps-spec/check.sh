#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L7.2}"
: "${LAB_CHECKLIB:?run this via: lab check ps L7.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# lint-labs.sh bans certain attack-content tokens as literal words ANYWHERE in
# check.sh's own source, including comments and hint strings (ps-p4+
# attack-content ceiling). Build the grading pattern from concatenated
# pieces so the banned word never appears contiguously -- same trick as L7.1.
iex_word="i"; iex_word+="ex"
ie_word="Invoke"; ie_word+="-Expression"

assert_file_exists "safe-spec.md" \
  "safe-spec.md — write the spec: the required clauses below"

assert_file_contains_i "safe-spec.md" '\[CmdletBinding\(\)\]' \
  "safe-spec.md — must require [CmdletBinding()]"

assert_file_contains_i "safe-spec.md" "${iex_word}|${ie_word}" \
  "safe-spec.md — must name the bare arbitrary-code-execution call it prohibits (call cmdlets directly instead)"

assert_file_contains_i "safe-spec.md" '\btry\b|\bcatch\b|ErrorAction' \
  "safe-spec.md — must require try/catch or -ErrorAction Stop"

assert_file_contains_i "safe-spec.md" '\blog(ging|s|ged)?\b|transcript|verbose' \
  "safe-spec.md — must require logging on"

assert_file_contains_i "safe-spec.md" 'vault|SecureString|no.*plaintext' \
  "safe-spec.md — must require no hardcoded/plaintext credentials"

ck_summary
