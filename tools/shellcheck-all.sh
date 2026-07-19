#!/usr/bin/env bash
# tools/shellcheck-all.sh — the single definition of "shellcheck clean"
# for this repo. Run from anywhere; always sweeps from the repo root so
# `# shellcheck source=` directives resolve.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$ROOT"

command -v shellcheck >/dev/null 2>&1 || {
  echo "shellcheck is required — sudo apt-get install -y shellcheck" >&2
  exit 1
}

# lib/*.sh is deliberately NOT listed here: those files are only ever
# sourced (never run standalone), and `shellcheck -x bin/lab` already pulls
# them into one combined analysis via bin/lab's static `# shellcheck
# source=` directives — checking them a second time as independent top-level
# files makes shellcheck flag their shared globals as "unused" (it can't see
# that a sibling sourced file consumes them). harness/checklib.sh stays
# independent because check.sh sources it via a *dynamic* path
# ($LAB_CHECKLIB), which shellcheck can't follow.
# No "# TEACHING SAMPLE" exemption here: every glob below matches only
# top-level executables and check.sh — content a lab's check.sh grader
# ACTUALLY RUNS — never the files/ directory where deliberately-broken
# teaching samples live (that content is never swept by this glob and
# never executed by the harness, so it needs no exemption). A check.sh is
# always a real, executed grader and must always be shellcheck-clean.
# p5 is the one exception to the "files/ is never swept" rule above: unlike
# p3/p4, p5's files/ scripts are real, correct, executable reference
# samples that check.sh actually runs (see docs/plans/bash-p5-plan.md) —
# so they get swept too. This glob is scoped to phases/p5 only; p3/p4's
# files/ still holds deliberately-broken samples and must stay unswept.
# --cached (tracked) + --others --exclude-standard (untracked but not
# gitignored): a plain `git ls-files` alone only sees files that have been
# `git add`-ed at least once, so a brand-new script nobody staged yet would
# be silently skipped from the sweep — a false "0 warnings" clean bill.
mapfile -d '' -t files < <(
  git ls-files -z --cached --others --exclude-standard -- \
    'bin/lab' 'harness/*.sh' 'tools/*.sh' \
    'tracks/*/phases/*/*/check.sh' \
    'tracks/*/phases/p5/*/files/*.sh'
)

if [[ "${#files[@]}" -eq 0 ]]; then
  echo "no files matched the shellcheck sweep" >&2
  exit 1
fi

shellcheck -x -S style -- "${files[@]}"
