#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L5.6}"
: "${LAB_CHECKLIB:?run this via: lab check ps L5.6}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# This lab executes nothing. loader-structure.txt is static reference prose with
# no runnable statement in it, so there is no probe to run and no pwsh here --
# the whole lab is read-and-describe. Grading is entirely on the learner's tour.md.

assert_file_exists "loader-structure.txt" \
  "loader-structure.txt — shipped sanitized loader structure must exist"

assert_file_exists "tour.md" \
  "tour.md — write your tour of the loader: the three stages, in order"

assert_file_contains_i "tour.md" "config|decode" \
  "tour.md — must name stage 1 (decoding the embedded config blob)"

# \bc2\b, not bare c2: unanchored it matches inside unrelated words.
assert_file_contains_i "tour.md" "\bc2\b|beacon|callback" \
  "tour.md — must name stage 2 (establishing C2)"

assert_file_contains_i "tour.md" "jitter|sleep|tasking" \
  "tour.md — must name stage 3 (the beacon/task loop and how it paces itself)"

# Accepts the vocabulary lab.md itself uses ("plain-string search") alongside the
# loader's own ("assembled at runtime") -- grade the idea, not one phrasing of it.
assert_file_contains_i "tour.md" "assembl|runtime|static scan|plain.?string|signature" \
  "tour.md — must name the evasion: strings assembled at runtime to defeat static scans"

# lab.md asks for the callback host and meta.json makes it an objective, so grade it:
# it is the one indicator from this loader that would go into a ticket.
assert_file_contains_i "tour.md" "fake-c2" \
  "tour.md — must record the defanged C2 host the config resolves to"

ck_summary
