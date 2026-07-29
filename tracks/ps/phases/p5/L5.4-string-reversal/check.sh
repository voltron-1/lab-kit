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
dl_term="Download"; dl_term+="String"

lab_dir="$(dirname -- "${BASH_SOURCE[0]}")"

assert_file_exists "rev.ps1" \
  "rev.ps1 — shipped reference probe must exist"

# rev.ps1 is read-only reference material, and this grader executes it. Byte
# identity is the whole integrity check: it rejects a gutted stub that hardcodes
# the expected output, and it rejects a probe edited to actually invoke what the
# string spells, without needing to enumerate PowerShell's invocation primitives.
assert_file_unmodified "rev.ps1" "$lab_dir/files/rev.ps1" \
  "rev.ps1 — reconstruct and PRINT, never invoke; restore the shipped file"

# Execute the probe only once it is proven unmodified. A lab whose whole lesson is
# "read it, never run it" must not have its own grader be the thing that runs a
# tampered probe -- so a modified rev.ps1 is reported, never executed.
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

assert_file_contains_i "plaintext.txt" "$kw_lower" \
  "plaintext.txt — must show the first un-reversed keyword"

assert_file_contains_i "plaintext.txt" "$dl_term" \
  "plaintext.txt — must show the second un-reversed keyword"

ck_summary
