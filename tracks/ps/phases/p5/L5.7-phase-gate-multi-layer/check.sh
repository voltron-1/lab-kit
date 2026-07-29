#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L5.7}"
: "${LAB_CHECKLIB:?run this via: lab check ps L5.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off

# tools/lint-labs.sh scans this file for attack-token names case-insensitively,
# so the name is never written contiguously here.
dl_term="Download"; dl_term+="String"
kw_term="i"; kw_term+="ex"

lab_dir="$(dirname -- "${BASH_SOURCE[0]}")"

assert_file_exists "gate-blob.txt" \
  "gate-blob.txt — the shipped multi-layer sample must exist"

assert_file_exists "gate-peel.ps1" \
  "gate-peel.ps1 — shipped reference probe must exist"

# Both shipped files are read-only reference material and this grader executes the
# probe, so byte identity is the integrity check for each: it rejects a gutted stub
# that hardcodes the expected output, a swapped-in sample, and a probe edited to
# actually run a peeled layer -- with no list of invocation primitives to maintain.
assert_file_unmodified "gate-blob.txt" "$lab_dir/files/gate-blob.txt" \
  "gate-blob.txt — this is the sample under analysis; restore the shipped file"

assert_file_unmodified "gate-peel.ps1" "$lab_dir/files/gate-peel.ps1" \
  "gate-peel.ps1 — peel and PRINT every layer, never run one; restore the shipped file"

# Execute the probe only once both are proven unmodified. This is the phase gate for
# decode-to-read-never-to-run, so the grader must not itself be what runs a tampered
# probe -- a modified sample or probe is reported, never executed.
if [[ "$CK_FAIL" -eq 0 ]]; then
  assert_output_contains "the three-layer payload reconstructs to a cradle" "$dl_term" \
    "run: pwsh -File gate-peel.ps1" -- pwsh -NoProfile -NonInteractive -File gate-peel.ps1

  assert_output_contains "the reconstructed cradle names the fake C2 host" "fake-c2" \
    "run: pwsh -File gate-peel.ps1" -- pwsh -NoProfile -NonInteractive -File gate-peel.ps1
else
  fail "gate-peel.ps1 not run — see the modified-file check above for which one" \
    "restore the shipped file that check flagged, then re-run: lab check ps L5.7"
fi

assert_file_exists "plaintext.txt" \
  "plaintext.txt — record the fully peeled plaintext, all three layers off"

assert_file_contains_i "plaintext.txt" "$dl_term" \
  "plaintext.txt — must show the reconstructed cradle"

# The resolved keyword only exists once layer 3 is off: layer 2 still has it split
# across the format expression's arguments. Requiring it here is what distinguishes
# "peeled all three layers" from "stopped at the legible-looking layer 2".
assert_file_contains_i "plaintext.txt" "$kw_term" \
  "plaintext.txt — must show the RESOLVED plaintext, layer 3 included, not the layer-2 line"

assert_file_exists "answers.md" \
  "answers.md — name each layer you peeled and the payload you ended up with"

# Naming the payload is mandatory: saying what the sample would have done is the
# whole point of the gate, not one interchangeable point among several.
assert_file_contains_i "answers.md" "cradle|${dl_term}" \
  "answers.md — must name what the payload is (a download cradle)"

# The layers themselves are scored as a threshold, because the gate asks for the
# learner's own words: >= 2 of the 3 layers THIS sample actually uses. (An earlier
# draft also scored a concatenation layer, which this sample does not contain --
# it would have given credit for naming a layer that was never there.)
# Each test is a compound-command condition, so a miss cannot trip set -e.
matches=0
if grep -Eiq 'base64' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
if grep -Eiq 'revers' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
if grep -Eiq 'format|operator' answers.md 2>/dev/null; then matches=$((matches + 1)); fi

if [[ "$matches" -ge 2 ]]; then
  pass_msg "answers.md — named at least 2 of the 3 layers this sample uses ($matches/3)"
else
  fail "answers.md — named only $matches/3 of the layers this sample uses (expected >= 2)" \
    "name each layer you peeled: the encoding, the ordering, and the operator that reassembled the keyword"
fi

ck_summary
