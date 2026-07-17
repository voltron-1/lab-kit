#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L3.4}"
: "${LAB_CHECKLIB:?run this via: lab check bash L3.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- identification (answers.txt) ---
assert_file_contains "answers.txt" '^line=4$' \
  "which line's glob can pick up a filename as a flag?"
assert_file_contains "answers.txt" '^flaw=dash-filename$' \
  "name the flaw class (see the brief's slug list)"
assert_file_contains "answers.txt" '(\./\*|-- )' \
  "the fix must mention ./* or -- to stop a name from being read as a flag"

# --- hardened script must exist before we try to run it — otherwise the
# subshell below would fail on a missing file, not on flawed rm logic ---
assert_file_exists "hardened.sh" \
  "author hardened.sh from scratch — purge files only, never let a name lead with a dash"

# --- hardened behavior: build a decoy carrying the hostile names, run the
# learner's hardened.sh INSIDE it (cd'd via a subshell, so it can never
# touch check.sh's own cwd), prove subdir survived (no recursion).
# assert_cmd_ok can only exec a single argv, not "cd && cp && bash", so this
# runs the compound step directly and reports through pass_msg/fail. No
# fence.sh here (contrast L3.2/L3.7) — the target is a relative glob inside
# an in-workspace decoy dir, so the blast radius is already bounded.
make_decoy_tree purge        # seeds -rf, --, alpha.txt, subdir/beta.txt
require_in_workspace "hardened.sh"
hardened_abs="$REQ_PATH"
require_in_workspace "decoy-purge"
decoy_abs="$REQ_PATH"
rc=0
out="$( cd -- "$decoy_abs" && cp -- "$hardened_abs" h.sh && bash -- h.sh 2>&1 )" || rc=$?
if [[ "$rc" -eq 0 ]]; then
  pass_msg "hardened purge runs without treating -rf as a flag"
else
  fail "hardened purge runs without treating -rf as a flag" \
    "your hardened script must purge plain files without erroring or recursing — see output below"
  if [[ -n "$out" ]]; then
    printf '%s\n' "$out" | tail -n 5 | while IFS= read -r ln; do printf '           | %s\n' "$ln"; done
  fi
fi
assert_file_missing "decoy-purge/-rf"     "the -rf file should be deleted as a FILE, safely"
assert_file_missing "decoy-purge/--"      "the -- file should be deleted as a FILE, safely"
assert_file_exists  "decoy-purge/subdir"  "subdir/ must survive — a flat purge must not recurse"
ck_summary
