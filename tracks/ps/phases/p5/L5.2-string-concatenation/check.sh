#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L5.2}"
: "${LAB_CHECKLIB:?run this via: lab check ps L5.2}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

kw_term="i"; kw_term+="ex"

lab_dir="$(dirname -- "${BASH_SOURCE[0]}")"

assert_file_exists "concat.ps1" \
  "concat.ps1 — shipped reference probe must exist"

# concat.ps1 is read-only reference material, and this grader executes it. Byte
# identity is the whole integrity check: it rejects a gutted stub that hardcodes
# the expected output, and it rejects a probe edited to actually invoke what the
# pieces spell, without needing to enumerate PowerShell's invocation primitives.
assert_file_unmodified "concat.ps1" "$lab_dir/files/concat.ps1" \
  "concat.ps1 — reassemble and PRINT, never invoke; restore the shipped file"

# Execute the probe only once it is proven unmodified. A phase whose whole lesson
# is decode-to-read-never-to-run must not have its own grader be the thing that runs
# a tampered probe -- so a modified concat.ps1 is reported, never executed.
if [[ "$CK_FAIL" -eq 0 ]]; then
  assert_output_contains "concat.ps1 reassembles the keyword via +" "$kw_term" \
    "run: pwsh -File concat.ps1" -- pwsh -NoProfile -NonInteractive -File concat.ps1

  assert_output_contains "concat.ps1 reassembles the second keyword via -join" "Download" \
    "run: pwsh -File concat.ps1" -- pwsh -NoProfile -NonInteractive -File concat.ps1

  assert_output_contains "concat.ps1 reassembles the keyword via char codes" "char codes:.*${kw_term}" \
    "run: pwsh -File concat.ps1" -- pwsh -NoProfile -NonInteractive -File concat.ps1
else
  fail "concat.ps1 not run — it no longer matches the shipped probe" \
    "restore the shipped concat.ps1, then re-run: lab check ps L5.2"
fi

assert_file_exists "plaintext.txt" \
  "plaintext.txt — record what each fragmented piece reassembles to"

assert_file_contains_i "plaintext.txt" "$kw_term" \
  "plaintext.txt — must show the reassembled first keyword"

assert_file_contains_i "plaintext.txt" "Download" \
  "plaintext.txt — must show the reassembled second keyword"

ck_summary
