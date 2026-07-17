#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L3.9}"
: "${LAB_CHECKLIB:?run this via: lab check bash L3.9}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- identification: name each footgun's line (answers.txt) ---
assert_file_contains "answers.txt" '^a_rmrf=8$' \
  "which line is the empty-var rm -rf catastrophe?"
assert_file_contains "answers.txt" '^b_split=9$' \
  "which line word-splits the manifest?"
assert_file_contains "answers.txt" '^c_unquoted=10$' \
  "which line copies with an unquoted \$f?"
assert_file_contains "answers.txt" '^d_dashname=12$' \
  "which line lets a -rf.tmp filename flag rm?"
assert_file_contains "answers.txt" '^e_arith=14$' \
  "which line runs arithmetic on untrusted input?"
assert_file_contains "answers.txt" '^f_eval=15$' \
  "which line re-parses an untrusted action as a command?"

# --- hardened rewrite: deploy.sh is edited IN PLACE (TAME, like L3.1's
# stage.sh) — strict mode, no re-parsing construct, validated, fenced.
# tools/lint-labs.sh bans L3.7's re-parsing builtin's name as a whole word
# anywhere in check.sh, so this asserts the fix POSITIVELY (a case
# allowlist + no dynamic "run_$" string) rather than asserting the
# builtin's absence by name. ---
assert_file_contains "deploy.sh" 'set -euo pipefail' \
  "harden with the strict-mode preamble"
assert_file_contains "deploy.sh" ':?' \
  "REL must be :? guarded so it never becomes the filesystem root"
assert_file_contains "deploy.sh" 'case ' \
  "dispatch the build step through a case allowlist, not a built-and-reparsed string"
assert_file_not_contains "deploy.sh" 'run_\$' \
  "no dynamic command building — dispatch known steps directly"

# --- fence proof, part 1: the shipped (still-flawed) deploy.sh must have
# been run via run-fenced.sh with REL empty FIRST, before any editing —
# fence.log is the persisted evidence of that demonstration. ---
assert_file_contains_fixed "fence.log" 'FENCE-BLOCKED: rm -rf' \
  "run the shipped, still-flawed deploy.sh via run-fenced.sh with REL empty first — the fence must log the blocked rm -rf"

# --- fence proof, part 2: the now-hardened deploy.sh must abort BEFORE rm
# when REL is empty — nothing new should reach the fence. ---
make_decoy_tree gate
: > fence.log
assert_cmd_fails "hardened deploy aborts when REL is empty" \
  "your :? guard must stop the script before rm when REL is empty" \
  -- bash -- run-fenced.sh deploy.sh "" 4 build
assert_file_not_contains "fence.log" 'FENCE-BLOCKED' \
  "the hardened script must abort before rm — nothing should reach the fence"
decoy_intact gate

# --- hardened run does its real work INSIDE a decoy release dir. A
# still-flawed deploy.sh (rm -rf with no recreate) can leave decoy-gate/rel
# behind as a plain FILE instead of a directory — clear that first so a
# re-run after a partial fix reports a graded FAIL instead of crashing on
# mkdir -p against a non-directory path. ---
require_in_workspace "decoy-gate/rel"
[[ -d "$REQ_PATH" ]] || rm -rf -- "$REQ_PATH"
mkdir -p "$REQ_PATH"
printf '%s\n' 'alpha.txt' > manifest.txt
: > alpha.txt
assert_cmd_ok "hardened deploy runs cleanly against an in-decoy release dir" \
  "with a valid REL inside the decoy, staging must succeed" \
  -- bash -- run-fenced.sh deploy.sh decoy-gate/rel 4 build
assert_file_exists "decoy-gate/rel/alpha.txt" \
  "the manifest file must be staged into the release dir"

# --- footgun (E): a non-numeric scale must be refused before the
# arithmetic ever runs. deploy.sh's own :? guard on REL means a
# non-numeric scale is checked before rm -rf ever fires here, so this
# needs no fresh decoy — decoy-gate/rel from above is untouched either way. ---
assert_cmd_fails "hardened deploy rejects a non-numeric scale" \
  "scale must be validated as all-digit before it reaches the arithmetic" \
  -- bash -- run-fenced.sh deploy.sh decoy-gate/rel x build
ck_summary
