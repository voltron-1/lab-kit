#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L4.8}"
: "${LAB_CHECKLIB:?run this via: lab check ps L4.8}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "tour.md" \
  "tour.md — name the stager stages and >=2 PowerSploit/PowerView function families"

assert_file_contains "tour.md" '[Ss]tager|[Ll]auncher|[Bb]eacon' \
  "tour.md — must mention the stager, launcher, or beacon (Empire's structure)"

assert_file_contains "tour.md" '[Ii]nvoke-|[Gg]et-[Nn]et|[Pp]ower[Vv]iew|[Gg]et-GPPPassword|[Ff]ind-LocalAdmin' \
  "tour.md — must name a PowerSploit/PowerView function family"

assert_file_contains "tour.md" '[Cc]2|[Ee]numerat|[Cc]red' \
  "tour.md — must mention C2, enumeration, or credential theft (what a named function does)"

ck_summary
