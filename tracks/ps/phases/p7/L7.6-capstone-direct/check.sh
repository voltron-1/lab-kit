#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L7.6}"
: "${LAB_CHECKLIB:?run this via: lab check ps L7.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "spec.md" \
  "spec.md — write the direction you gave (the L7.2-style spec)"

assert_file_exists "hardened.ps1" \
  "hardened.ps1 — write the audited, hardened script"

assert_file_contains_i "hardened.ps1" '\[CmdletBinding\(\)\]' \
  "hardened.ps1 — must have [CmdletBinding()]"

assert_file_contains_i "hardened.ps1" '\btry\b' \
  "hardened.ps1 — must have a try block"

assert_file_contains_i "hardened.ps1" '\bcatch\b' \
  "hardened.ps1 — must have a catch block"

assert_file_contains_i "hardened.ps1" '\blogging\b|\blogs\b|\blogged\b|transcript|verbose' \
  "hardened.ps1 — must turn logging on (Start-Transcript or Write-Verbose)"

# Security-critical: the capstone's whole point is proving the shipped script
# never contains a bare code-execution alias call. Case-insensitive by
# construction (character classes, not a runtime -i flag) so both spellings
# of the alias are caught -- lint-labs.sh also bans both spellings as literal
# words anywhere in this file's own source, which this pattern's construction
# avoids without needing runtime string concatenation. assert_file_exists
# first (repeated from above, deliberately): assert_file_not_contains
# vacuously PASSES on a missing file, so without this guard an entirely
# absent hardened.ps1 would incorrectly satisfy "no bare code-execution call".
assert_file_exists "hardened.ps1" \
  "hardened.ps1 — must exist before it can be checked for a bare code-execution alias call"

assert_file_not_contains "hardened.ps1" '[Ii]nvoke-[Ee]xpression|[Ii][Ee][Xx]' \
  "hardened.ps1 — must not contain a bare code-execution alias call"

ck_summary
