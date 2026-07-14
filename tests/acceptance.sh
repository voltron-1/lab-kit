#!/usr/bin/env bash
# tests/acceptance.sh — the full bootstrap acceptance checklist, run
# end-to-end against a throwaway COPY of the repo (never touches this
# checkout's real .progress.json or workspace/). Deliberately does NOT use
# `set -e` — assertions record failures and the script keeps going so one
# run exercises the whole checklist instead of stopping at the first miss.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
COPY="$WORK/lab-kit"
LAB="$COPY/bin/lab"

PASS=0
FAIL=0

cleanup() {
  jobs -p 2> /dev/null | xargs -r kill 2> /dev/null || true
  rm -rf -- "$WORK"
}
trap cleanup EXIT

note() { printf '\n=== %s ===\n' "$1"; }
ok() { PASS=$((PASS + 1)); printf '  PASS: %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL: %s\n' "$1"; }

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then ok "$desc"; else
    bad "$desc (expected [$expected], got [$actual])"
  fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then ok "$desc"; else
    bad "$desc (did not find [$needle])"
  fi
}

assert_not_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if [[ "$haystack" != *"$needle"* ]]; then ok "$desc"; else
    bad "$desc (unexpectedly found [$needle])"
  fi
}

# --- setup: throwaway copy ---
note "setup"
cp -R -- "$ROOT" "$COPY"
rm -rf -- "$COPY/workspace" "$COPY/.progress.json"
chmod 755 "$COPY/bin/lab" "$COPY"/tools/*.sh
find "$COPY/tracks" -name check.sh -exec chmod 644 {} +
ok "throwaway copy created at $COPY"

# --- 1. shellcheck sweep ---
note "shellcheck sweep"
if command -v shellcheck > /dev/null 2>&1; then
  if (cd -- "$COPY" && ./tools/shellcheck-all.sh) > "$WORK/shellcheck.out" 2>&1; then
    ok "shellcheck clean"
  else
    bad "shellcheck reported warnings — see $WORK/shellcheck.out"
    cat "$WORK/shellcheck.out"
  fi
else
  bad "shellcheck is not installed — cannot verify the zero-warning gate"
fi

# --- 2. fresh-clone reads ---
note "fresh-clone reads (no .progress.json)"
if [[ -f "$COPY/.progress.json" ]]; then bad "fresh copy already has .progress.json"; else ok "fresh copy has no .progress.json"; fi

out="$("$LAB" status 2>&1)"; rc=$?
assert_eq "fresh 'lab status' exits 0" "0" "$rc"
if [[ -f "$COPY/.progress.json" ]]; then bad "'lab status' created .progress.json"; else ok "'lab status' created no state file"; fi

out="$("$LAB" resume 2>&1)"; rc=$?
assert_eq "fresh 'lab resume' exits 0" "0" "$rc"
assert_contains "fresh 'lab resume' says nothing completed yet" "$out" "nothing completed yet"
if [[ -f "$COPY/.progress.json" ]]; then bad "'lab resume' created .progress.json"; else ok "'lab resume' created no state file"; fi

out="$("$LAB" check demo L0.0 2>&1)"; rc=$?
assert_eq "'lab check' before start exits 2" "2" "$rc"
assert_contains "'lab check' before start names 'lab start'" "$out" "lab start demo L0.0"
if [[ -f "$COPY/.progress.json" ]]; then bad "'lab check' refusal created .progress.json"; else ok "'lab check' refusal created no state file"; fi

out="$("$LAB" hint demo L0.0 2>&1)"; rc=$?
assert_eq "'lab hint' before start exits 2" "2" "$rc"

# --- 3. demo loop: start -> wrong quiz -> right quiz -> status -> resume ---
note "demo loop"

RECALL_ANSWERS=$'b\nb\nworkspace/demo/L0.0\na\nb\n'
out="$(printf '%s' "$RECALL_ANSWERS" | "$LAB" start demo L0.0 2>&1)"; rc=$?
assert_eq "'lab start demo L0.0' exits 0" "0" "$rc"
assert_contains "start prints the BRIEF" "$out" "BRIEF"
if [[ -d "$COPY/workspace/demo/L0.0" ]]; then ok "workspace provisioned"; else bad "workspace missing"; fi
if [[ -f "$COPY/workspace/demo/L0.0/.lab-provisioned" ]]; then ok "provisioned marker written"; else bad "provisioned marker missing"; fi

# do the guided steps for real
WS="$COPY/workspace/demo/L0.0"
cp "$WS/broken.conf" "$WS/fixed.conf"
sed -i 's/max_retries = ten/max_retries = 3/; s/workspace_fence = off/workspace_fence = on/' "$WS/fixed.conf"
uname -r > "$WS/sysinfo.txt"
(cd -- "$WS" && pwd > location.txt)

out="$(printf 'a\n.progress.json\na\n' | "$LAB" check demo L0.0 2>&1)"; rc=$?
assert_eq "check with wrong quiz answers exits 1" "1" "$rc"
assert_contains "wrong-quiz result names FAIL" "$out" "RESULT: FAIL"
assert_contains "wrong-quiz names missed Q1" "$out" "Q1"
assert_contains "wrong-quiz names missed Q3" "$out" "Q3"
assert_not_contains "wrong-quiz never leaks raw answer data" "$out" "answer_b64"

out="$("$LAB" status 2>&1)"
assert_not_contains "status shows no pass mark yet" "$out" "✓  L0.0"

out="$(printf 'c\n.progress.json\nb\n' | "$LAB" check demo L0.0 2>&1)"; rc=$?
assert_eq "check with right quiz answers exits 0" "0" "$rc"
assert_contains "right-quiz result names PASS" "$out" "RESULT: PASS"

out="$("$LAB" status 2>&1)"
assert_contains "status shows a pass mark after passing" "$out" "✓  L0.0"

out="$("$LAB" resume 2>&1)"
assert_contains "resume replays the recap" "$out" "all lab work happens inside workspace"
assert_contains "resume names demo L0.0 as last passed" "$out" "demo L0.0"

# --- 4. Interrupt safety ---
# SIGKILL, not SIGINT: SIGKILL cannot be caught, blocked, or deferred by any
# trap or shell signal-inheritance quirk, so it kills the process at a truly
# arbitrary point — a strictly stronger test of "no partial write, ever"
# than SIGINT (which also depends on the *interactive* shell's own SIGINT
# disposition, something a backgrounded `cmd | target &` job from a
# non-interactive test script cannot faithfully reproduce). The friendly
# "interrupted — nothing recorded" SIGINT message is verified separately,
# manually, against a real foreground invocation (see the session report).
note "interrupt safety (SIGKILL mid-check, arbitrary timing)"
before_hash="absent"
[[ -f "$COPY/.progress.json" ]] && before_hash="$(sha256sum "$COPY/.progress.json" | cut -d' ' -f1)"

# A FIFO, not a `producer | lab &` pipe: piping backgrounds a two-process
# pipeline as ONE job, and `wait <one-member-pid>` then blocks on the WHOLE
# job — including the producer, which is still alive — not just the member
# we killed. Opening the FIFO read-write on our own fd keeps it from EOFing
# without a separate producer process, so `lab check` is the pipeline's only
# member and `wait "$labpid"` returns as soon as it dies.
SIGFIFO="$WORK/sigfifo"
mkfifo "$SIGFIFO"
exec 8<> "$SIGFIFO"
"$LAB" check demo L0.0 < "$SIGFIFO" > "$WORK/sigint.out" 2>&1 &
labpid=$!
sleep 1
kill -KILL "$labpid" 2> /dev/null || true
wait "$labpid" 2> /dev/null
exec 8<&-
rm -f "$SIGFIFO"

after_hash="absent"
[[ -f "$COPY/.progress.json" ]] && after_hash="$(sha256sum "$COPY/.progress.json" | cut -d' ' -f1)"
assert_eq "SIGKILL mid-check leaves .progress.json byte-identical" "$before_hash" "$after_hash"

# A temp file CAN legitimately survive a SIGKILL (traps never run) — the
# design's documented, acceptable residue. state_gc_tmp() must sweep it on
# the next invocation; assert that cleanup, not "never appears at all".
stray_tmp="$(find "$COPY" -maxdepth 1 -name '.progress.json.*.tmp' 2> /dev/null)"
if [[ -n "$stray_tmp" ]]; then
  ok "SIGKILL left a stray temp file, as documented (state_gc_tmp will sweep it)"
else
  ok "no stray state temp file after SIGKILL"
fi

out="$("$LAB" status 2>&1)"; rc=$?
assert_eq "'lab status' still works after SIGKILL" "0" "$rc"

stray_tmp="$(find "$COPY" -maxdepth 1 -name '.progress.json.*.tmp' 2> /dev/null)"
if [[ -z "$stray_tmp" ]]; then ok "startup GC swept any stray temp file"; else bad "stray temp file survived a 'lab status' run: $stray_tmp"; fi

# --- 5. hint ladder ---
note "hint ladder"
out1="$("$LAB" hint demo L0.0 2>&1)"
assert_contains "hint 1/3" "$out1" "[hint 1/3]"
out2="$("$LAB" hint demo L0.0 2>&1)"
assert_contains "hint 2/3" "$out2" "[hint 2/3]"
out3="$("$LAB" hint demo L0.0 2>&1)"
assert_contains "hint 3/3" "$out3" "[hint 3/3]"
out4="$("$LAB" hint demo L0.0 2>&1)"
assert_contains "4th hint call gives a clean terminal message" "$out4" "no more hints"
assert_not_contains "4th hint call does not repeat hint text" "$out4" "diff broken.conf fixed.conf"

# --- 6. lock / --force / skip mechanics (throwaway 3-lab fixture track) ---
note "lock / --force / skip mechanics"
FIXTURE="$COPY/tracks/fixture"
mkdir -p "$FIXTURE/phases/p0"
cat > "$FIXTURE/track.json" << 'JSON'
{"title":"Fixture","order":999,"phases":{"p0":"Fixture Phase"}}
JSON
for n in 1 2 3; do
  d="$FIXTURE/phases/p0/L0.$n-step$n"
  mkdir -p "$d/files"
  cat > "$d/meta.json" << JSON
{"id":"L0.$n","title":"Step $n","type":"GUIDED","objective":"fixture step $n","gate":false,"est_minutes":1}
JSON
  cat > "$d/lab.md" << 'MD'
## BRIEF
fixture lab.

## GUIDED STEPS
none.
MD
  cat > "$d/check.sh" << 'SH'
#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?}"
: "${LAB_CHECKLIB:?}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"
pass_msg "fixture check always passes"
ck_summary
SH
  chmod 644 "$d/check.sh"
  cat > "$d/quiz.json" << 'JSON'
{"questions":[
  {"id":1,"type":"choice","prompt":"1+1?","options":{"a":"1","b":"2","c":"3"},"answer_b64":"Yg=="},
  {"id":2,"type":"choice","prompt":"1+1?","options":{"a":"1","b":"2","c":"3"},"answer_b64":"Yg=="},
  {"id":3,"type":"choice","prompt":"1+1?","options":{"a":"1","b":"2","c":"3"},"answer_b64":"Yg=="}
]}
JSON
  cat > "$d/hints.json" << 'JSON'
{"hints":["h1","h2","h3"]}
JSON
  cat > "$d/recap.md" << 'MD'
fixture line one
fixture line two
fixture line three
MD
done

out="$("$LAB" start fixture L0.2 2>&1)"; rc=$?
assert_eq "starting L0.2 while L0.1 is undone is refused" "2" "$rc"
assert_contains "locked message names the frontier lab" "$out" "L0.1"

out="$("$LAB" start fixture L0.2 --force 2>&1)"; rc=$?
assert_eq "--force start of L0.2 succeeds" "0" "$rc"
out="$("$LAB" status 2>&1)"
assert_contains "status marks L0.1 skipped after force" "$out" "⏭  L0.1"

out="$(printf 'b\nb\nb\n' | "$LAB" check fixture L0.2 2>&1)"; rc=$?
assert_eq "checking the forced-into lab L0.2 passes" "0" "$rc"
out="$("$LAB" status 2>&1)"
assert_contains "status shows a pass mark for L0.2 after it passes" "$out" "✓  L0.2"
assert_contains "status still shows skipped for L0.1" "$out" "⏭  L0.1"

out="$("$LAB" start fixture L0.3 2>&1)"; rc=$?
assert_eq "L0.3 unlocked after forcing past + passing L0.2" "0" "$rc"

"$LAB" start fixture L0.1 > /dev/null 2>&1
out="$(printf 'b\nb\nb\n' | "$LAB" check fixture L0.1 2>&1)"; rc=$?
assert_eq "L0.1 can still be passed later" "0" "$rc"
out="$("$LAB" status 2>&1)"
assert_contains "L0.1 stays skipped even after passing" "$out" "⏭  L0.1"
assert_not_contains "L0.1 never shows a pass mark" "$out" "✓  L0.1"

# --- 7. bash track P0+P1: fabricated pass + one negative case per lab ---
# Linear progression means each lab must end up PASSED before the next one
# unlocks, so every block below drives a negative case (missing artifact ->
# fail) BEFORE completing the fabrication and passing -- never after, so a
# later fail can't be mistaken for reverting an already-passed lab (status
# is sticky once passed; see lib/state.sh:state_record_check).
note "bash track P0+P1: fabricated pass + negative case per lab"

bash_check_fail_missing() {
  local id="$1" missing="$2" out rc
  out="$("$LAB" check bash "$id" 2>&1)"; rc=$?
  assert_eq "bash $id check fails before $missing exists" "1" "$rc"
  assert_contains "bash $id fail result names FAIL" "$out" "RESULT: FAIL"
}

bash_check_pass() {
  local id="$1" quiz="$2" out rc
  out="$(printf '%s' "$quiz" | "$LAB" check bash "$id" 2>&1)"; rc=$?
  assert_eq "bash $id check passes" "0" "$rc"
  assert_contains "bash $id result names PASS" "$out" "RESULT: PASS"
}

# L0.1 — Shells and the kit
"$LAB" start bash L0.1 > /dev/null 2>&1
WS="$COPY/workspace/bash/L0.1"
printf 'bash\n' > "$WS/shell.txt"
printf '/usr/bin/dash\n' > "$WS/sh-target.txt"
printf 'version: 0.9.0\n' > "$WS/shellcheck.txt"
bash_check_fail_missing "L0.1" "shfmt.txt"
printf 'v3.8.0\n' > "$WS/shfmt.txt"
bash_check_pass "L0.1" $'b\nclean\na\n'

# L0.2 — Meet the lab CLI
"$LAB" start bash L0.2 > /dev/null 2>&1
WS="$COPY/workspace/bash/L0.2"
printf 'q1=b\nq2=3\nq3=b\n' > "$WS/answers.txt"
bash_check_fail_missing "L0.2" "location.txt"
(cd -- "$WS" && pwd > location.txt)
bash_check_pass "L0.2" $'c\nlab resume\nb\n'

# L0.3 — Reading the shebang (gate)
"$LAB" start bash L0.3 > /dev/null 2>&1
WS="$COPY/workspace/bash/L0.3"
(cd -- "$WS" && readlink -f /bin/sh > sh-target.txt
 dash deploy.sh > dash-run.txt 2>&1
 bash deploy.sh > bash-run.txt 2>&1
 printf 'q1=b\nq2=b\nq3=b\nq4=c\n' > answers.txt)
bash_check_fail_missing "L0.3" "sc-out.txt"
(cd -- "$WS" && shellcheck -s sh deploy.sh > sc-out.txt 2>&1)
bash_check_pass "L0.3" $'b\n[[\na\n'

# L1.1 — Commands are just words (phase opener: recall must never gate)
out="$(printf 'b\nb\nb\nb\nb\n' | "$LAB" start bash L1.1 2>&1)"; rc=$?
assert_eq "'lab start bash L1.1' exits 0 regardless of recall score" "0" "$rc"
assert_contains "L1.1 start ran the recall quiz" "$out" "recall"
WS="$COPY/workspace/bash/L1.1"
bash_check_fail_missing "L1.1" "predictions.txt"
printf '%s\n' 'p1=2|<hello><world>' 'p2=2|<hello><world>' 'p3=1|<hello   world>' 'p4=0|' > "$WS/predictions.txt"
bash_check_pass "L1.1" $'b\nc\nb\n'

# L1.2 — Variables and braces
"$LAB" start bash L1.2 > /dev/null 2>&1
WS="$COPY/workspace/bash/L1.2"
bash_check_fail_missing "L1.2" "predictions.txt"
printf '%s\n' 'p1=1|<world>' 'p2=1|<worldwide>' 'p3=0|' 'p4=b' > "$WS/predictions.txt"
bash_check_pass "L1.2" $'b\nb\n127\n'

# L1.3 — The unquoted variable
"$LAB" start bash L1.3 > /dev/null 2>&1
WS="$COPY/workspace/bash/L1.3"
mkdir -p "$WS/backup"
printf '%s\n' 'p1=2|<report><final.txt>' 'p2=1|<report final.txt>' 'p3=b' 'p5=b' > "$WS/predictions.txt"
bash_check_fail_missing "L1.3" "backup/report final.txt"
printf 'Q2 incident report\n' > "$WS/backup/report final.txt"
bash_check_pass "L1.3" $'b\nb\nb\n'

# L1.4 — Quoting
"$LAB" start bash L1.4 > /dev/null 2>&1
WS="$COPY/workspace/bash/L1.4"
bash_check_fail_missing "L1.4" "predictions.txt"
printf '%s\n' "p1=1|<\$user>" 'p2=1|<root>' 'p3=1|<phase root>' 'p4=2|<phase><root>' "p5=1|<'root'>" > "$WS/predictions.txt"
bash_check_pass "L1.4" $'c\nb\na\n'

# L1.5 — Globbing
"$LAB" start bash L1.5 > /dev/null 2>&1
WS="$COPY/workspace/bash/L1.5"
bash_check_fail_missing "L1.5" "predictions.txt"
printf '%s\n' 'p1=2|<app.log><error.log>' 'p2=2|<app.conf><app.log>' 'p3=1|<*.md>' \
  'p4=4|<app.conf><app.log><argv.sh><error.log>' 'p5=2|<app.log><error.log>' 'p6=1|<*.log>' \
  > "$WS/predictions.txt"
bash_check_pass "L1.5" $'b\nc\nb\n'

# L1.6 — Exit codes
"$LAB" start bash L1.6 > /dev/null 2>&1
WS="$COPY/workspace/bash/L1.6"
bash_check_fail_missing "L1.6" "answers.txt"
printf 'q1=1\nq2=1\nq3=b\nq4=b\n' > "$WS/answers.txt"
bash_check_pass "L1.6" $'b\nb\nb\n'

# L1.7 — Command substitution
"$LAB" start bash L1.7 > /dev/null 2>&1
WS="$COPY/workspace/bash/L1.7"
bash_check_fail_missing "L1.7" "predictions.txt"
printf '%s\n' 'p1=1|<2.4.1>' 'p2=2|<web01><web02>' 'p3=1|<web01 web02>' 'p4=1|<L1.7>' 'p5=b' \
  > "$WS/predictions.txt"
bash_check_pass "L1.7" $'b\na\nstdout\n'

# L1.8 — Phase gate (gate)
"$LAB" start bash L1.8 > /dev/null 2>&1
WS="$COPY/workspace/bash/L1.8"
bash_check_fail_missing "L1.8" "predictions.txt"
printf '%s\n' 'p1=1:' 'p2=2:web01_id' 'p3=3:*.log' 'p4=4:web01 web02' 'p5=5:argc=2' \
  'p6=6:app.log error.log' 'p7=7:*.conf' 'p8=8:L1.8' 'p9=9:argc=2' 'p10=10:rc=1' \
  > "$WS/predictions.txt"
bash_check_pass "L1.8" $'b\ndouble\nb\n'

out="$("$LAB" status 2>&1)"
assert_contains "status shows all 11 bash P0+P1 labs passed (11/11)" "$out" "(11/11)"

# --- 8. README / planned_execution shape ---
note "README + planned_execution shape"
if [[ -f "$COPY/README.md" ]]; then
  cmd_count="$(grep -cE '^[[:space:]]{4,}\S.*#[[:space:]]*[0-9]' "$COPY/README.md")"
  assert_eq "README quickstart has exactly 5 numbered commands" "5" "$cmd_count"
else
  bad "README.md missing"
fi

if [[ -f "$COPY/planned_execution.md" ]]; then
  line_count="$(grep -cE '^- \[ \] (rust|bash|soc|ps) p[0-7] ' "$COPY/planned_execution.md")"
  assert_eq "planned_execution.md has 32 unstarted track-phase lines" "32" "$line_count"
else
  bad "planned_execution.md missing"
fi

# --- summary ---
note "SUMMARY"
printf 'PASS: %d   FAIL: %d\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
