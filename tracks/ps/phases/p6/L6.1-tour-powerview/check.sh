#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L6.1}"
: "${LAB_CHECKLIB:?run this via: lab check ps L6.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# This lab executes nothing. The shipped catalog is names and prose with no code
# in it, PowerView itself is never present, and the graded work is entirely the
# learner's tour.md -- so there is no probe here and no pwsh.

assert_file_exists "powerview-catalog.txt" \
  "powerview-catalog.txt — shipped sanitized catalog must exist"

assert_file_exists "tour.md" \
  "tour.md — write your tour: map at least three functions to the data they collect"

assert_file_contains_i "tour.md" "Get-NetUser" \
  "tour.md — must cover Get-NetUser, the account-inventory function"

assert_file_contains_i "tour.md" "Find-LocalAdminAccess" \
  "tour.md — must cover Find-LocalAdminAccess, the one that maps where you can already go"

# lab.md asks for at least THREE functions, so grade three. With only the two named
# above required, a tour.md consisting of nothing but the graded keywords scored full
# marks -- this is the assertion that makes the third one actually get written.
assert_file_contains_i "tour.md" "Get-NetGroup|Get-NetComputer|Get-NetGPO|Get-NetOU|Invoke-ShareFinder" \
  "tour.md — must cover a third function beyond Get-NetUser and Find-LocalAdminAccess"

assert_file_contains_i "tour.md" "enumerat|recon|discovery|inventor" \
  "tour.md — must say what these functions are for (enumeration or recon of AD objects)"

assert_file_contains_i "tour.md" "T1087|T1069|T1135|T1018|T1615|lateral" \
  "tour.md — must tie at least one function to its ATT&CK technique (or to lateral movement)"

ck_summary
