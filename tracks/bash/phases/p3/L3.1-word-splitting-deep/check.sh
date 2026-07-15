#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L3.1}"
: "${LAB_CHECKLIB:?run this via: lab check bash L3.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

make_decoy_tree stage
require_in_workspace "decoy-stage/my report.txt"; : > "$REQ_PATH"
require_in_workspace "decoy-stage/archive";       mkdir -p "$REQ_PATH"

assert_file_exists "stage.sh" "edit the shipped stage.sh into your hardened version"
assert_file_contains "stage.sh" 'set -euo pipefail' "add the strict-mode preamble (L2.2)"
assert_file_contains_fixed "stage.sh" 'read -r' \
  "read the manifest LINE BY LINE (L2.3) instead of splitting it into a for loop"
assert_file_not_contains "stage.sh" 'for [a-zA-Z_]+ in \$\(cat' \
  "the \$(cat)-into-for split is the bug you're removing"

# manifest entries are relative to $LAB_WORKSPACE (stage.sh's own cwd when
# check.sh runs it), so the decoy's spaced file needs its decoy-stage/
# prefix spelled out in the manifest line itself — not just in argv.
printf '%s\n' 'decoy-stage/my report.txt' > decoy-stage/manifest.txt
assert_cmd_ok "hardened stage.sh runs clean on the decoy" \
  "your script must move the listed file without splitting it" \
  -- bash -- stage.sh decoy-stage/manifest.txt decoy-stage/archive
assert_file_exists "decoy-stage/archive/my report.txt" \
  "the spaced filename must arrive WHOLE — that's the whole lesson"
assert_file_missing "decoy-stage/archive/my" \
  "if 'my' exists on its own, the name still word-split — quote \$f and use --"
ck_summary
