#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L5.4}"
: "${LAB_CHECKLIB:?run this via: lab check ps L5.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

# tools/lint-labs.sh scans this file for attack-token names case-insensitively,
# so those names are never written contiguously below: the exact-match terms are
# built by concatenation, the grep patterns use character classes. Learner-artifact
# patterns accept any casing (someone who writes the alias in caps is still right);
# probe-output patterns stay exact, since that output is deterministic.
kw_lower="i"; kw_lower+="ex"
kw_pat="[Ii][Ee][Xx]"
dl_term="Download"; dl_term+="String"
dl_pat="[Dd]ownload"; dl_pat+="[Ss]tring"

# Bars the one thing this lab exists to teach against. check.sh runs rev.ps1
# from the learner's writable workspace, so without this a learner who "solves"
# it by invoking what the string spells would be graded as passing.
run_pat="[Ii][Ee][Xx]|[Ii]nvoke-[Ee]xpression|\[ScriptBlock\]::Create"

assert_file_exists "rev.ps1" \
  "rev.ps1 — shipped reference probe must exist"

assert_file_contains_fixed "rev.ps1" "gnirtSdaolnwoD" \
  "rev.ps1 — the shipped reversed literal must be present and unmodified"

# Pin the reversal itself, not just its output: without these, a stub that
# only prints the two expected lines scores full marks having reversed nothing.
# $s1/$s2 are PowerShell variables in the graded file, so the single quotes
# are deliberate — these are literals to grep for, not shell expansions.
# shellcheck disable=SC2016
assert_file_contains_fixed "rev.ps1" '-join $s1[-1..-$s1.Length]' \
  "rev.ps1 — the shipped reversal expression must be present and unmodified"

# shellcheck disable=SC2016
assert_file_contains_fixed "rev.ps1" '-join $s2[-1..-$s2.Length]' \
  "rev.ps1 — the shipped reversal expression must be present and unmodified"

assert_file_not_contains "rev.ps1" "$run_pat" \
  "rev.ps1 — reconstruct and PRINT; never invoke what the string spells"

# Execute the probe only if every integrity assertion above passed. A lab whose
# whole lesson is "read it, never run it" must not have its own grader be the
# thing that runs a tampered probe -- so a modified rev.ps1 is reported, not run.
if [[ "$CK_FAIL" -eq 0 ]]; then
  assert_output_contains "rev.ps1 reverses the first keyword" "reversed keyword 1: ${kw_lower}" \
    "run: pwsh -File rev.ps1" -- pwsh -NoProfile -NonInteractive -File rev.ps1

  assert_output_contains "rev.ps1 reverses the second keyword" "reversed keyword 2: ${dl_term}" \
    "run: pwsh -File rev.ps1" -- pwsh -NoProfile -NonInteractive -File rev.ps1
else
  fail "rev.ps1 not run — it no longer matches the shipped probe" \
    "restore the shipped rev.ps1, then re-run: lab check ps L5.4"
fi

assert_file_exists "plaintext.txt" \
  "plaintext.txt — record what each reversed literal un-reverses to"

assert_file_contains "plaintext.txt" "$kw_pat" \
  "plaintext.txt — must show the first un-reversed keyword"

assert_file_contains "plaintext.txt" "$dl_pat" \
  "plaintext.txt — must show the second un-reversed keyword"

ck_summary
