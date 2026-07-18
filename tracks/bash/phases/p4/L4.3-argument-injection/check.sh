#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L4.3}"
: "${LAB_CHECKLIB:?run this via: lab check bash L4.3}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- identification (answers.txt) ---
assert_file_contains "answers.txt" '^line=5$' \
  "which line hands a client-chosen filename to mv with no option-parsing guard?"
assert_file_contains "answers.txt" '^flaw=argument-injection$' \
  "name the flaw class (see the brief's slug list)"
assert_file_contains "answers.txt" '^cwe=CWE-88$' \
  "name the CWE for argument injection"
assert_file_contains "answers.txt" '^fix=' \
  "state the fix — the end-of-options guard before the filename"
assert_file_contains "answers.txt" '(--|end.?of.?option)' \
  "the fix must be the -- end-of-options guard, not more quoting"

# --- hardened.sh must exist before the behavioral checks below run —
# otherwise a missing file makes bash exit 127 (nonzero), which the
# upcoming assert_cmd_fails would read as "correctly rejected" for the
# wrong reason. The overall grade still comes out FAIL either way (this
# assert_file_exists check fails on its own), matching the same collect-
# all-grader characteristic already documented in
# tracks/bash/phases/p3/L3.2-rm-rf-empty-var/check.sh:22-24. ---
assert_file_exists "hardened.sh" \
  "author hardened.sh from scratch — mv -- \"\$f\" staging/"
assert_file_contains "hardened.sh" 'mv[[:space:]]+--' \
  "hardened.sh must call mv WITH the -- end-of-options guard, not reimplement staging some other way"

# --- an injection-shaped name must no longer redirect staging/ elsewhere ---
# INVARIANT: the injected value below must stay a RELATIVE path with no ".."
# — that, plus mv relocating rather than deleting, is what keeps this whole
# demo inside $LAB_WORKSPACE. require_in_workspace only ever canonicalizes
# the "staging" and "exfil-target" strings this file passes it directly; it
# never sees (and cannot fence) the effective mv destination once -t's
# argument is glued onto an argv element handed to hardened.sh. An absolute
# or ../-traversing value here would escape the workspace for real.
require_in_workspace "staging"
mkdir -p "$REQ_PATH"
printf 'existing\n' > "$REQ_PATH/existing.txt"
require_in_workspace "exfil-target"
rm -rf "$REQ_PATH"
mkdir -p "$REQ_PATH"
assert_cmd_fails "hardened staging rejects an injection-shaped name" \
  "the -- guard must make an argument-shaped name a plain (nonexistent) filename, not an mv option — mv should fail to find it, not redirect staging/" \
  -- bash -- hardened.sh "-texfil-target/"
assert_file_exists "staging/existing.txt" \
  "staging/ must stay exactly where it is — the injection must not move it anywhere"
assert_file_missing "exfil-target/staging" \
  "the attacker-chosen target directory must stay empty — nothing should land inside it"

# --- a genuinely dash-prefixed upload must still be handled correctly, as data ---
touch -- "-flag.txt"
assert_cmd_ok "hardened staging still moves a real dash-prefixed filename" \
  "a filename that merely STARTS with - must still be staged normally once it's guarded by --" \
  -- bash -- hardened.sh "-flag.txt"
assert_file_exists "staging/-flag.txt" \
  "the dash-prefixed file should land in staging/, treated as a path — never as an option"

# --- normal use must still work ---
touch normal-upload.txt
assert_cmd_ok "hardened staging still handles an ordinary filename" \
  "the fix must not break the normal case" \
  -- bash -- hardened.sh normal-upload.txt
assert_file_exists "staging/normal-upload.txt" \
  "an ordinary upload should land in staging/ exactly as before"
ck_summary
