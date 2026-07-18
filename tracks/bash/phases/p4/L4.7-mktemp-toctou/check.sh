#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L4.7}"
: "${LAB_CHECKLIB:?run this via: lab check bash L4.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^flaw=toctou$' \
  "name the flaw class (see the brief's slug list)"
assert_file_contains "answers.txt" '^cwe=CWE-367$' \
  "name the CWE for a time-of-check-to-time-of-use race"

assert_file_contains "cache.sh" 'mktemp' \
  "replace the predictable name with mktemp — an unpredictable, atomically-created path"
assert_file_not_contains "cache.sh" 'acme-cache' \
  "the old predictable name must be gone entirely, not just checked for existence first"
assert_file_contains "cache.sh" 'trap' \
  "register a cleanup trap so the temp file is removed on every exit path, not just the happy one"
# A decoy mktemp+trap pair aimed at a throwaway file would satisfy the three
# checks above and the TMPDIR-dependency check below while leaving the real
# check-then-use race on $tmp completely untouched — ban the idiom itself,
# not just the old name. (Residual: this catches the exact idiom shape; a
# rephrased guard using a different comparison operator or variable name
# could still dodge it — a fully sound black-box test would need to bind
# the mktemp-created path to the one actually read/written, which needs
# instrumenting the script, not just grading its text and behavior.)
# shellcheck disable=SC2016
assert_file_not_contains "cache.sh" '\-e[[:space:]]*"\$tmp"' \
  "remove the check-then-use guard entirely — mktemp already creates the file atomically, so there's nothing left to check for"

# --- behavioral proof, three parts, all under a workspace-local TMPDIR —
# never the real system temp directory:
#
# (1) a script that still hardcodes its own path (a decorative "fix" that
#     just swaps the literal name, or adds fake mktemp/trap text without
#     really using them) never looks at $TMPDIR at all — it would keep
#     writing to the real system temp dir regardless. Point TMPDIR at a
#     path that doesn't exist: a genuine mktemp call fails loudly (it has
#     nowhere to create the file); a hardcoded path silently ignores
#     TMPDIR and succeeds anyway. This is the test that actually proves
#     mktemp is in use, not just present as a string somewhere.
# (2) with a real, existing TMPDIR, the fix must still report the same
#     byte count as before — the fix must not change ordinary behavior.
# (3) TMPDIR must be completely empty afterward — a decoy trap that
#     "fires" without actually removing the temp file would still pass a
#     text-only check, but rmdir on a non-empty directory fails, so only
#     a genuine cleanup passes this. ---
require_in_workspace "tmp-missing"
missing_tmpdir="$REQ_PATH"
assert_file_missing "tmp-missing" \
  "this check needs a guaranteed-nonexistent TMPDIR to test against — something created a path this check.sh owns"
assert_cmd_fails "hardened cache.sh genuinely depends on TMPDIR, not a hardcoded path" \
  "a real mktemp call fails when TMPDIR doesn't exist — if your fix still succeeds here, it isn't really using TMPDIR" \
  -- env "TMPDIR=$missing_tmpdir" "DATA=hello" bash -- cache.sh

require_in_workspace "tmp-check"
rm -rf "$REQ_PATH"
mkdir -p "$REQ_PATH"
tmpdir="$REQ_PATH"

assert_output_contains "hardened cache.sh reports the same byte count as before" '^6$' \
  "DATA=hello should still report 6 bytes (5 + the trailing newline echo adds) — the fix must not change ordinary behavior" \
  -- env "TMPDIR=$tmpdir" "DATA=hello" bash -- cache.sh

assert_cmd_ok "TMPDIR is left completely clean after a normal run — nothing leaked" \
  "the temp file must be removed on exit — a trap that doesn't actually clean up still leaves it behind" \
  -- rmdir "$tmpdir"
ck_summary
