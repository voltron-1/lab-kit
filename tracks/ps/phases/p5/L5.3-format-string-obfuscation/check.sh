#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L5.3}"
: "${LAB_CHECKLIB:?run this via: lab check ps L5.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

kw_lower="i"; kw_lower+="ex"
kw_mixed="I"; kw_mixed+="Ex"

lab_dir="$(dirname -- "${BASH_SOURCE[0]}")"

assert_file_exists "fmt.ps1" \
  "fmt.ps1 — shipped reference probe must exist"

# fmt.ps1 is read-only reference material, and this grader executes it. Byte
# identity is the whole integrity check: it rejects a gutted stub that hardcodes
# the expected output, and it rejects a probe edited to actually invoke what the
# format expressions spell, without needing to enumerate invocation primitives.
assert_file_unmodified "fmt.ps1" "$lab_dir/files/fmt.ps1" \
  "fmt.ps1 — resolve and PRINT, never invoke; restore the shipped file"

# Execute the probe only once it is proven unmodified. A phase whose whole lesson
# is decode-to-read-never-to-run must not have its own grader be the thing that runs
# a tampered probe -- so a modified fmt.ps1 is reported, never executed.
if [[ "$CK_FAIL" -eq 0 ]]; then
  assert_output_contains "fmt.ps1 resolves the 3-arg reordered format" "reordered 3-arg format: ${kw_mixed}" \
    "run: pwsh -File fmt.ps1" -- pwsh -NoProfile -NonInteractive -File fmt.ps1

  assert_output_contains "fmt.ps1 resolves the 2-arg reordered format" "reordered 2-arg format: ${kw_lower}" \
    "run: pwsh -File fmt.ps1" -- pwsh -NoProfile -NonInteractive -File fmt.ps1
else
  fail "fmt.ps1 not run — it no longer matches the shipped probe" \
    "restore the shipped fmt.ps1, then re-run: lab check ps L5.3"
fi

assert_file_exists "plaintext.txt" \
  "plaintext.txt — record what each format expression resolves to"

assert_file_contains_i "plaintext.txt" "$kw_lower" \
  "plaintext.txt — must show the keyword each format expression resolves to"

ck_summary
