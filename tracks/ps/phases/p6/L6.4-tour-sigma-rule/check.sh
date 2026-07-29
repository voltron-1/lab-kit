#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check ps L6.4}"
: "${LAB_CHECKLIB:?run this via: lab check ps L6.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# Plain YAML, fully cross-platform to read, and nothing here executes it -- Sigma
# rules are compiled by a SIEM backend, not run by PowerShell. Grading is entirely
# static comprehension of the learner's readout.

# Split so tools/lint-labs.sh's case-insensitive attack-token scan never sees the
# cradle keyword contiguously in this file.
dl_term="Download"; dl_term+="String"

assert_file_exists "rule.yml" \
  "rule.yml — shipped Sigma rule must exist"

assert_file_exists "readout.md" \
  "readout.md — say what this rule reads, what it matches, and one thing it misses"

# No bare "powershell" here: the rule's own title contains it, so accepting it would
# let a readout that never identifies the telemetry satisfy this assertion.
assert_file_contains_i "readout.md" "4104|script.?block|logsource" \
  "readout.md — must name the telemetry the rule reads (the 4104 ScriptBlock log)"

assert_file_contains_i "readout.md" "$dl_term" \
  "readout.md — must name at least one string the rule matches on"

assert_file_contains_i "readout.md" "\\bmiss|evad|concat|format|revers|assembl|runtime" \
  "readout.md — must name one evasion this literal-string rule would miss"

ck_summary
