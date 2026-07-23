#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L6.4}"
: "${LAB_CHECKLIB:?run this via: lab check bash L6.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "answers.txt" '^thinyaml=parity$' \
  "thinyaml — why does the YAML stay thin with logic in this script?"
assert_file_contains "answers.txt" '^failstop=pipefail$' \
  "failstop — which mechanism makes any failing stage fail the whole job?"
assert_file_contains "answers.txt" '^fallback=git$' \
  "fallback — where does COMMIT_SHA come from when CI_COMMIT_SHA is unset?"
assert_file_contains "answers.txt" '^tarflags=reproducible$' \
  "tarflags — what property do the unusual tar flags give the artifact?"
assert_file_contains "answers.txt" '^integrity=sha256$' \
  "integrity — what lets a deploy job verify the tarball is what CI built?"
assert_file_contains "answers.txt" '^exposure=env$' \
  "exposure — what is the biggest secret-leak surface this script inherits?"

ck_summary
