#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check bash L7.7}"
: "${LAB_CHECKLIB:?run this via: lab check bash L7.7}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_exists "answers.txt"
assert_file_contains "answers.txt" '^loopform=redirect$'
assert_file_contains "answers.txt" '^notemp=herestring$'
assert_file_contains "answers.txt" '^streams=stderr$'
assert_file_contains "answers.txt" '^noinject=removing-the-filter$'
assert_file_contains "answers.txt" '^exitnone=nonzero$'

assert_file_exists "hardened.sh"
chmod +x hardened.sh || true

# 1. Real ShellCheck sweep on hardened.sh
sc_out="$(shellcheck -x -S style hardened.sh 2>&1)" || fail "hardened.sh is not shellcheck-clean:\n$sc_out"

out_file="tmp.out"
err_file="tmp.err"

# 2. Usage error contract (0 args -> exit 2; 2 args -> exit 2)
status=0
bash hardened.sh > "$out_file" 2> "$err_file" || status=$?
[[ $status -eq 2 ]] || fail "expected exit 2 when called with 0 args, got $status"

status=0
bash hardened.sh sample.ndjson extra_arg > "$out_file" 2> "$err_file" || status=$?
[[ $status -eq 2 ]] || fail "expected exit 2 when called with 2 args (rejecting extra filter arg), got $status"

# Nonexistent file -> exit 1
status=0
bash hardened.sh nonexistent_file.ndjson > "$out_file" 2> "$err_file" || status=$?
[[ $status -eq 1 ]] || fail "expected exit 1 for nonexistent file, got $status"

# 3. Test against sample.ndjson
status=0
bash hardened.sh sample.ndjson > "$out_file" 2> "$err_file" || status=$?
[[ $status -eq 0 ]] || fail "expected exit 0 for sample.ndjson, got $status"

line_count="$(wc -l < "$out_file")"
[[ $line_count -eq 3 ]] || fail "expected 3 output records on stdout for sample.ndjson, got $line_count"
grep -q "valid=" "$err_file" || fail "expected summary on stderr for sample.ndjson"

# 4. Test against allbad.ndjson
status=0
bash hardened.sh allbad.ndjson > "$out_file" 2> "$err_file" || status=$?
[[ $status -ne 0 ]] || fail "expected nonzero exit for allbad.ndjson, got 0"
line_count="$(wc -l < "$out_file")"
[[ $line_count -eq 0 ]] || fail "expected 0 output records on stdout for allbad.ndjson, got $line_count"

# 5. Anti-gaming check: dynamic fixture test
dyn_file="dyn.ndjson"
cat << 'EOF' > "$dyn_file"
{"ts":"2026-07-26T12:00:00Z","src":"10.0.0.1","action":"login"}
invalid line 1
{"ts":"2026-07-26T12:00:02Z","src":"10.0.0.2","action":"logout"}
invalid line 2
EOF

status=0
bash hardened.sh "$dyn_file" > "$out_file" 2> "$err_file" || status=$?
rm -f "$dyn_file" "$out_file" "$err_file"
[[ $status -eq 0 ]] || fail "expected exit 0 for dynamic fixture, got $status"

ck_summary
