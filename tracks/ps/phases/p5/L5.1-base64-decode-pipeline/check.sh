#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L5.1}"
: "${LAB_CHECKLIB:?run this via: lab check ps L5.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

dl_term="Download"; dl_term+="String"

lab_dir="$(dirname -- "${BASH_SOURCE[0]}")"

assert_file_exists "decode.ps1" \
  "decode.ps1 — shipped reference decoder must exist"

# decode.ps1 is read-only reference material, and this grader executes it. Byte
# identity is the whole integrity check: it rejects a gutted stub that hardcodes
# the expected output, and it rejects a probe edited to actually run the decoded
# payload, without needing to enumerate PowerShell's invocation primitives.
assert_file_unmodified "decode.ps1" "$lab_dir/files/decode.ps1" \
  "decode.ps1 — decode to READ the payload, never to run it; restore the shipped file"

# Execute the decoder only once it is proven unmodified. A phase whose whole lesson
# is decode-to-read-never-to-run must not have its own grader be the thing that runs
# a tampered probe -- so a modified decode.ps1 is reported, never executed.
if [[ "$CK_FAIL" -eq 0 ]]; then
  assert_output_contains "decode.ps1 reveals the decoded cradle" "$dl_term" \
    "run: pwsh -File decode.ps1" -- pwsh -NoProfile -NonInteractive -File decode.ps1

  assert_output_contains "decode.ps1 reveals the fake C2 host" "fake-c2" \
    "run: pwsh -File decode.ps1" -- pwsh -NoProfile -NonInteractive -File decode.ps1
else
  fail "decode.ps1 not run — it no longer matches the shipped decoder" \
    "restore the shipped decode.ps1, then re-run: lab check ps L5.1"
fi

assert_file_exists "plaintext.txt" \
  "plaintext.txt — record the decoded text in plaintext.txt"

assert_file_contains_i "plaintext.txt" "$dl_term" \
  "plaintext.txt — must show the decoded payload you actually read"

assert_file_exists "technique.txt" \
  "technique.txt — name the technique and ATT&CK ID"

assert_file_contains "technique.txt" '[Cc]radle|[Dd]ownload' \
  "technique.txt — must name the payload as a download cradle"

assert_file_contains "technique.txt" '[Uu][Tt][Ff]-?16|[Uu]nicode' \
  "technique.txt — must mention UTF-16LE or Unicode (the actual encoding)"

assert_file_contains "technique.txt" 'T1140|T1027' \
  "technique.txt — must cite ATT&CK T1140 or T1027"

ck_summary
