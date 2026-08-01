#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L7.7}"
: "${LAB_CHECKLIB:?run this via: lab check ps L7.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# The capstone gate: the same structural bar as L7.6's hardened.ps1, plus
# proof a real PSScriptAnalyzer pass came back clean and a self-audit against
# the L7.3 checklist.

assert_file_exists "hardened.ps1" \
  "hardened.ps1 — ship the audited, hardened script from L7.6"

assert_file_contains_i "hardened.ps1" '\[CmdletBinding[[:space:]]*\(' \
  "hardened.ps1 — must have [CmdletBinding()]"

assert_file_contains_i "hardened.ps1" '\btry\b' \
  "hardened.ps1 — must have a try block"

assert_file_contains_i "hardened.ps1" '\bcatch\b' \
  "hardened.ps1 — must have a catch block"

assert_file_contains_i "hardened.ps1" 'Start-Transcript|Write-Verbose|Write-Information' \
  "hardened.ps1 — must turn logging on (Start-Transcript, Write-Verbose, or Write-Information)"

# Security-critical, carried verbatim from L7.6 (PR #388 review): the whole
# capstone exists to prove this file never contains a bare code-execution
# alias call. Every letter is its own character class -- PowerShell
# cmdlet/alias names are fully case-insensitive (every capitalization of the
# banned call runs identically), so a pattern that only classes the first
# letter of each word (e.g. [Ii]nvoke-[Ee]xpression) still lets an ALLCAPS or
# mixed-case spelling walk straight past it. \b-anchored so a benign
# false-cognate (e.g. "iexplore.exe") doesn't false-fail. assert_file_exists
# first (repeated, deliberately): assert_file_not_contains vacuously PASSES
# on a missing file, so without this guard an absent hardened.ps1 would
# incorrectly satisfy "no bare code-execution call" -- not acceptable at the
# track's final checkpoint.
assert_file_exists "hardened.ps1" \
  "hardened.ps1 — must exist before it can be checked for a bare code-execution alias call"

assert_file_not_contains "hardened.ps1" \
  '\b[Ii][Nn][Vv][Oo][Kk][Ee]-[Ee][Xx][Pp][Rr][Ee][Ss][Ss][Ii][Oo][Nn]\b|\b[Ii][Ee][Xx]\b' \
  "hardened.ps1 — must not contain a bare code-execution alias call"

# The L5.2 lesson in this same track is that a bare-string ban like the one
# above misses the two mechanical ways PowerShell constructs and invokes code
# without ever spelling out the alias name: [ScriptBlock]::Create(...) builds
# a scriptblock from an arbitrary string, and the call operator (&) or
# dot-sourcing (.) on a variable/expression invokes whatever it evaluates to.
# tools/lint-labs.sh already bans both shapes in every shipped .ps1 for the
# same reason; same regexes, reused here as the single source of truth.
assert_file_not_contains "hardened.ps1" \
  '\[[[:space:]]*(System\.Management\.Automation\.)?ScriptBlock[[:space:]]*\][[:space:]]*::[[:space:]]*Create' \
  "hardened.ps1 — must not construct code dynamically ([ScriptBlock]::Create)"

assert_file_not_contains "hardened.ps1" \
  '&[[:space:]]*\(?[[:space:]]*\$[A-Za-z_]|(^|[[:space:]])\.[[:space:]]*\$[A-Za-z_]' \
  "hardened.ps1 — must not invoke a variable or expression via the call operator (&) or dot-sourcing"

# PSSA-from-artifact (ps-p01 §2/§3a, same reasoning as L7.5): PSSA is graded
# from a learner-produced FILE, never re-run live here -- under this
# check-runner's env -i HOME redirect, a live Invoke-ScriptAnalyzer sees an
# empty module path and finds nothing, the exact wrong-reason pass this
# avoids. A genuinely clean Invoke-ScriptAnalyzer pass on hardened.ps1,
# piped through Select-Object and redirected to a file, produces a literal
# 0-byte file (verified against real pwsh 7.6.4 + PSScriptAnalyzer 1.25.0) --
# a stronger, unambiguous bar than grepping for the absence of "Warning" or
# "Error", which an empty file would also vacuously satisfy. But a 0-byte
# file is ALSO what a `>` redirect produces when PSSA never ran at all --
# module missing, a typo'd -Path, or an error mid-run all vanish silently,
# since `>` only redirects the success stream. pssa-version.txt is the same
# proof-of-run signal L7.5 already requires (RuleName/Severity headers,
# harness/checklib.sh-graded there too) so an honest learner on a fresh
# machine with PSSA not yet installed gets a real failure instead of a false
# "clean" pass.
assert_file_exists "pssa-version.txt" \
  "pssa-version.txt — show the PSScriptAnalyzer module you actually ran (proves PSSA executed)"

assert_file_contains_i "pssa-version.txt" 'PSScriptAnalyzer' \
  "pssa-version.txt — must contain real Get-Module output naming PSScriptAnalyzer"

assert_file_exists "pssa-clean.txt" \
  "pssa-clean.txt — run Invoke-ScriptAnalyzer on hardened.ps1 and capture the output"

if [[ ! -f pssa-clean.txt ]]; then
  : # already recorded as missing above; do not also claim it's clean
elif [[ -s pssa-clean.txt ]]; then
  fail "pssa-clean.txt is not empty — PSScriptAnalyzer found something; fix hardened.ps1 and re-run" \
    "Invoke-ScriptAnalyzer -Path ./hardened.ps1 | Select-Object RuleName, Severity > pssa-clean.txt"
else
  pass_msg "pssa-clean.txt is empty — a genuinely clean PSScriptAnalyzer pass"
fi

assert_file_exists "answers.md" \
  "answers.md — self-audit hardened.ps1 against the L7.3 checklist"

# The checklist's item 1 (no bare code-execution alias) is this track's
# security-critical property -- L6.5 set the precedent that the load-bearing
# checklist item is mandatory while the rest are graded on a threshold
# (tracks/ps/phases/p6/L6.5-phase-gate-cold-tour/check.sh). A self-audit that
# never actually names the one property the whole capstone exists to prove
# is not a self-audit.
assert_file_contains_i "answers.md" \
  '\b[Ii][Nn][Vv][Oo][Kk][Ee]-[Ee][Xx][Pp][Rr][Ee][Ss][Ss][Ii][Oo][Nn]\b|\b[Ii][Ee][Xx]\b' \
  "answers.md — the checklist's first item is the bare code-execution alias; audit it by name"

# The remaining four checklist items are graded on a threshold, same as every
# other threshold-graded answers.md in this track (L4.9, L6.5). Each test is
# a compound-command condition, so a miss cannot trip set -e.
matches=0
if grep -Eiq -- 'cmdletbinding' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
if grep -Eiq -- 'try.*catch|catch.*try' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
if grep -Eiq -- '\blog\w*\b|transcript|verbose' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
if grep -Eiq -- 'PSScriptAnalyzer|PSSA|analyzer' answers.md 2>/dev/null; then matches=$((matches + 1)); fi

if [[ "$matches" -ge 3 ]]; then
  pass_msg "answers.md — walked at least 3 of the remaining 4 L7.3 checklist items ($matches/4)"
else
  fail "answers.md — walked only $matches/4 of the remaining L7.3 checklist items (expected >= 3)" \
    "audit hardened.ps1 against the L7.3 checklist: CmdletBinding, try/catch, logging, PSSA-clean"
fi

ck_summary
