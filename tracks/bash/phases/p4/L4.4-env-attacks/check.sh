#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L4.4}"
: "${LAB_CHECKLIB:?run this via: lab check bash L4.4}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

# --- identification (answers.txt) ---
assert_file_contains "answers.txt" '^line=5$' \
  "which line lets the current directory be searched for commands before the trusted ones?"
assert_file_contains "answers.txt" '^flaw=untrusted-search-path$' \
  "name the flaw class (see the brief's slug list)"
assert_file_contains "answers.txt" '^cwe=CWE-426$' \
  "name the CWE for untrusted search path"
assert_file_contains "answers.txt" '^fix=' \
  "state the fix — a pinned, minimal search path with no current-directory entry"
assert_file_contains "answers.txt" '(absolute|minimal|no.?dot)' \
  "the fix must remove the current directory from the search path entirely, not just reorder it"
assert_file_contains "answers.txt" '^also=IFS$' \
  "name the sibling footgun — a hostile inherited variable that re-steers a different kind of lookup (see L3.3)"

assert_file_exists "hardened.sh" \
  "author hardened.sh from scratch — reassign PATH before the first command lookup"
assert_file_contains "hardened.sh" 'PATH=' \
  "hardened.sh must pin its own PATH — inheriting whatever the caller passed in is the bug"

# --- decoy commands planted in the workspace (standing in for a writable spool
# dir) must never fire, even when the inherited PATH searches "." first. No
# shebang line: an interpreter-less-but-executable file still runs via the
# calling shell's ENOEXEC fallback, which keeps this heredoc lint-clean.
# marker is reset first: ws_run_check reuses the SAME persisted workspace
# across every "lab check" invocation, so a leftover marker from an earlier,
# still-broken hardened.sh would otherwise fail a learner's next, correct
# attempt for the wrong reason. ---
rm -f marker
cat > 'ps' <<'DECOY'
touch marker
DECOY
chmod +x ps
cat > 'pgrep' <<'DECOY'
touch marker
exit 1
DECOY
chmod +x pgrep

poisoned_path=".:$PATH"
assert_cmd_ok "hardened healthcheck runs safely under a poisoned inherited PATH" \
  "your fix must not depend on the caller's PATH being safe — pin your own" \
  -- env "PATH=$poisoned_path" bash -- hardened.sh
assert_file_missing "marker" \
  "the decoy ps/pgrep in the current directory must never run — hardened.sh must resolve the real commands, not the planted ones"

# --- a script that merely SKIPS the lookup (never calls ps/pgrep at all)
# would also leave the decoy untouched — trace execution to prove the real
# check actually ran, not just that nothing bad happened ---
assert_output_contains "hardened.sh actually calls a process-lookup command, not a no-op stub" \
  '^\+ (pgrep|ps) ' \
  "a script that never calls ps or pgrep at all isn't a real healthcheck, even if it exits 0" \
  -- env "PATH=$poisoned_path" bash -x -- hardened.sh
ck_summary
