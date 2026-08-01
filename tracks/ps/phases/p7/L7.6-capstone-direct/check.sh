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
# never contains a bare code-execution alias call. EVERY letter is its own
# character class -- PowerShell cmdlet/alias names are fully case-insensitive
# (every capitalization of the banned call runs identically), so a pattern
# that only classes the first letter of each word (an earlier draft's bug,
# caught by review: [Aa]bc still requires the literal substring "bc") lets an
# all-caps or mixed-case spelling walk straight past this check. \b-anchored
# so a benign false-cognate (e.g. "iexplore.exe" in a process-triage script)
# doesn't false-fail. lint-labs.sh also bans both spellings as literal words anywhere
# in this file's own source, which this construction avoids without needing
# runtime string concatenation. assert_file_exists first (repeated from
# above, deliberately): assert_file_not_contains vacuously PASSES on a
# missing file, so without this guard an entirely absent hardened.ps1 would
# incorrectly satisfy "no bare code-execution call".
assert_file_exists "hardened.ps1" \
  "hardened.ps1 — must exist before it can be checked for a bare code-execution alias call"

assert_file_not_contains "hardened.ps1" \
  '\b[Ii][Nn][Vv][Oo][Kk][Ee]-[Ee][Xx][Pp][Rr][Ee][Ss][Ss][Ii][Oo][Nn]\b|\b[Ii][Ee][Xx]\b' \
  "hardened.ps1 — must not contain a bare code-execution alias call"

ck_summary
