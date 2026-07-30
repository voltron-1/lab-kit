#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L6.5}"
: "${LAB_CHECKLIB:?run this via: lab check ps L6.5}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# The phase gate, and still a TOUR: this grader executes nothing. It runs no pwsh
# and never invokes the shipped tool -- the entire skill being graded is reading it.

lab_dir="$(dirname -- "${BASH_SOURCE[0]}")"

assert_file_exists "mystery-tool.ps1" \
  "mystery-tool.ps1 — the shipped tool under tour must exist"

assert_file_exists "reference-list.txt" \
  "reference-list.txt — the shipped list the tool reads must exist"

# Both shipped files are read-only reference material and the whole exercise is
# reading them as given, so byte-anchor both: a gutted tool or a swapped list would
# otherwise leave every assertion below still passing. Same anchor as the p5 labs.
assert_file_unmodified "mystery-tool.ps1" "$lab_dir/files/mystery-tool.ps1" \
  "mystery-tool.ps1 — tour it as shipped; restore the original if you edited it"

assert_file_unmodified "reference-list.txt" "$lab_dir/files/reference-list.txt" \
  "reference-list.txt — tour it as shipped; restore the original if you edited it"

assert_file_exists "answers.md" \
  "answers.md — tour the tool cold: what it does, what it matches on, what it touches"

# Naming WHAT the tool compares against is mandatory. A tour that never works that
# out has not identified the tool, whatever else it got right -- the same reason
# L5.7 makes naming the payload mandatory rather than one point among several.
assert_file_contains_i "answers.md" "ioc|indicator|known.bad|hash list|threat intel" \
  "answers.md — must say what the tool compares against (an IOC or indicator list)"

# The rest is a threshold, because a cold tour is written in the learner's own
# words: >= 3 of the 4 remaining topics. Each test is a compound-command
# condition, so a miss cannot trip set -e.
matches=0
if grep -Eiq 'process' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
if grep -Eiq 'hash|sha256|sha-256' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
if grep -Eiq 'scan|match|compar' answers.md 2>/dev/null; then matches=$((matches + 1)); fi
if grep -Eiq 'detect|triage|hunt|respon' answers.md 2>/dev/null; then matches=$((matches + 1)); fi

if [[ "$matches" -ge 3 ]]; then
  pass_msg "answers.md — covered at least 3 of the 4 remaining tour topics ($matches/4)"
else
  fail "answers.md — covered only $matches/4 of the remaining tour topics (expected >= 3)" \
    "say what the tool walks, how it decides something matches, and what the output is for"
fi

ck_summary
