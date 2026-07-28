#!/usr/bin/env bash
# tests/acceptance.sh — the full bootstrap acceptance checklist, run
# end-to-end against a throwaway COPY of the repo (never touches this
# checkout's real .progress.json or workspace/). Deliberately does NOT use
# `set -e` — assertions record failures and the script keeps going so one
# run exercises the whole checklist instead of stopping at the first miss.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$PATH:$HOME/.cargo/bin"
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
# denominator is the full bash catalog on disk (P0-P7 = 54), not just the 11
# passed so far -- every phase's lab directories already exist on disk at
# this point, regardless of progress state.
assert_contains "status shows 11 of 54 bash labs passed so far (11/54)" "$out" "(11/54)"

# --- 7b. bash track P2: fabricated pass + one negative case per lab ---
note "bash track P2: fabricated pass + negative case per lab"

# L2.1 — if and test (phase opener: recall must never gate)
out="$(printf 'b\nb\nb\ndouble\nb\n' | "$LAB" start bash L2.1 2>&1)"; rc=$?
assert_eq "'lab start bash L2.1' exits 0 regardless of recall score" "0" "$rc"
assert_contains "L2.1 start ran the recall quiz" "$out" "recall"
WS="$COPY/workspace/bash/L2.1"
bash_check_fail_missing "L2.1" "answers.txt"
printf 'q1=0\nq2=1\nq3=b\nq4=2\nq5=1\nq6=0\n' > "$WS/answers.txt"
bash_check_pass "L2.1" $'b\nb\nc\n'

# L2.2 — The strict-mode preamble
"$LAB" start bash L2.2 > /dev/null 2>&1
WS="$COPY/workspace/bash/L2.2"
printf '%s\n' 'x' 'backup complete' 'exit=0' > "$WS/e-off.txt"
printf '%s\n' 'x' 'exit=1' > "$WS/e-on.txt"
printf '%s\n' 'cleaning staging/' 'exit=0' > "$WS/u-off.txt"
printf '%s\n' 'y: unbound variable' 'exit=1' > "$WS/u-on.txt"
printf '%s\n' 'z' '0' 'exit=0' > "$WS/p-off.txt"
printf 'q1=b\nq2=c\nq3=a\nq4=b\n' > "$WS/answers.txt"
bash_check_fail_missing "L2.2" "p-on.txt"
printf '%s\n' 'z' '0' 'exit=2' > "$WS/p-on.txt"
bash_check_pass "L2.2" $'b\nc\nset -euo pipefail\n'

# L2.3 — Loops
"$LAB" start bash L2.3 > /dev/null 2>&1
WS="$COPY/workspace/bash/L2.3"
bash_check_fail_missing "L2.3" "predictions.txt"
printf '%s\n' 'p1=3' 'p2=loading web01.conf' 'p3=7' 'p4=2' 'p5=3' 'p6=got *.missing' \
  > "$WS/predictions.txt"
bash_check_pass "L2.3" $'b\nb\nb\n'

# L2.4 — && and || short-circuit
"$LAB" start bash L2.4 > /dev/null 2>&1
WS="$COPY/workspace/bash/L2.4"
printf '%s\n' 'p1=rc=1' 'p2=fallback' 'p3=recovered' 'p4=b' 'p5=1' 'p6=deploying from deploy_dir' \
  > "$WS/predictions.txt"
bash_check_fail_missing "L2.4" "deploy_dir"
mkdir -p "$WS/deploy_dir"
bash_check_pass "L2.4" $'b\nb\nb\n'

# L2.5 — case statements
"$LAB" start bash L2.5 > /dev/null 2>&1
WS="$COPY/workspace/bash/L2.5"
bash_check_fail_missing "L2.5" "answers.txt"
printf 'q1=b\nq2=b\nq3=2\nq4=b\n' > "$WS/answers.txt"
bash_check_pass "L2.5" $'b\nb\nb\n'

# L2.6 — Functions, local, return vs echo
"$LAB" start bash L2.6 > /dev/null 2>&1
WS="$COPY/workspace/bash/L2.6"
bash_check_fail_missing "L2.6" "answers.txt"
printf 'q1=7\nq2=b\nq3=changed\nq4=44\nq5=b\n' > "$WS/answers.txt"
bash_check_pass "L2.6" $'b\nb\nb\n'

# L2.7 — trap cleanup
"$LAB" start bash L2.7 > /dev/null 2>&1
WS="$COPY/workspace/bash/L2.7"
printf '%s\n' 'staged: payload.txt' 'verified: version line present' \
  'installed: payload.installed' 'cleanup: staging file removed' 'exit=0' > "$WS/good-run.txt"
printf '%s\n' 'staged: payload-bad.txt' 'cleanup: staging file removed' 'exit=1' > "$WS/bad-run.txt"
printf 'name: x\n' > "$WS/payload.installed"
bash_check_fail_missing "L2.7" "answers.txt"
printf 'q1=b\nq2=1\nq3=b\nq4=b\n' > "$WS/answers.txt"
bash_check_pass "L2.7" $'b\nb\nb\n'

# L2.8 — Phase gate (gate, FIX): negative case is the shipped flawed script
# left UNEDITED (per the map's FIX-type intent), not a missing artifact.
"$LAB" start bash L2.8 > /dev/null 2>&1
WS="$COPY/workspace/bash/L2.8"
(cd -- "$WS" && bash archive-errors.sh app.log > broken-run.txt 2>&1; echo "exit=$?" >> broken-run.txt)
printf 'q1=b\nq2=b\nq3=b\nq4=a\n' > "$WS/answers.txt"
bash_check_fail_missing "L2.8" "the fix (script left unedited)"
cat > "$WS/archive-errors.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
# archive-errors.sh — extract the ERROR lines from a log and file them in archive/.
log="$1"
grep ERROR "$log" > errors.txt
cp errors.txt archive/errors.txt
rm -f errors.txt
echo "archived: ERROR lines from $log are in archive/errors.txt"
SCRIPT
bash_check_pass "L2.8" $'b\nb\nb\n'

# --- 7c. bash track P3 (The Footgun Gallery): fabricated pass + negative
# case per lab. Every AUDIT/TAME lab's negative case matches the FIX-type
# convention above (L2.8): leave the shipped flawed script unedited /
# artifacts absent, never a separately-deleted file. ---
note "bash track P3: fabricated pass + negative case per lab"

# L3.1 — Word splitting, deep (TAME: edit stage.sh in place; phase opener:
# recall must never gate)
out="$(printf 'b\nb\nb\nb\nb\n' | "$LAB" start bash L3.1 2>&1)"; rc=$?
assert_eq "'lab start bash L3.1' exits 0 regardless of recall score" "0" "$rc"
assert_contains "L3.1 start ran the recall quiz" "$out" "recall"
WS="$COPY/workspace/bash/L3.1"
bash_check_fail_missing "L3.1" "the fix (stage.sh left unedited)"
cat > "$WS/stage.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
manifest=$1
archive=$2
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  mv -- "$f" "$archive"/
done < "$manifest"
echo staged
SCRIPT
bash_check_pass "L3.1" $'b\nb\nb\n'

# L3.2 — rm -rf "$DIR/" — the empty-variable catastrophe (AUDIT, fenced)
"$LAB" start bash L3.2 > /dev/null 2>&1
WS="$COPY/workspace/bash/L3.2"
bash_check_fail_missing "L3.2" "hardened.sh"
printf "line=5\\nflaw=empty-var-rm\\nfix=\${BUILD_DIR:?BUILD_DIR is empty}\\n" > "$WS/answers.txt"
printf 'FENCE-BLOCKED: rm -rf /\n' > "$WS/fence.log"
cat > "$WS/hardened.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
BUILD_DIR="${BUILD_DIR-$(dirname "$0")/build}"
rm -rf "${BUILD_DIR:?BUILD_DIR is empty — refusing to rm}/"
echo clean
SCRIPT
bash_check_pass "L3.2" $'b\nb\nb\n'

# L3.3 — IFS (DECODE: identification only, no hardened script)
"$LAB" start bash L3.3 > /dev/null 2>&1
WS="$COPY/workspace/bash/L3.3"
bash_check_fail_missing "L3.3" "answers.txt"
printf 'default_argc=3\npasswd_fields=7\nempty_argc=1\nifs_controls=splitting\nattack=IFS=/ before an unquoted for loop over a path splits it into extra tokens\n' \
  > "$WS/answers.txt"
bash_check_pass "L3.3" $'b\nb\nb\n'

# L3.4 — Filenames as attack surface (AUDIT, decoy only)
"$LAB" start bash L3.4 > /dev/null 2>&1
WS="$COPY/workspace/bash/L3.4"
bash_check_fail_missing "L3.4" "hardened.sh"
printf 'line=4\nflaw=dash-filename\nfix=rm -- ./* (or rm ./*) so a name can never be read as an option\n' \
  > "$WS/answers.txt"
cat > "$WS/hardened.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
find . -maxdepth 1 -type f -exec rm -- {} +
echo purged
SCRIPT
bash_check_pass "L3.4" $'b\nb\nb\n'

# L3.5 — Arithmetic injection (AUDIT, no decoy/fence)
"$LAB" start bash L3.5 > /dev/null 2>&1
WS="$COPY/workspace/bash/L3.5"
bash_check_fail_missing "L3.5" "hardened.sh"
printf 'line=5\nflaw=arith-cmdsub\nfix=validate n is all-digit before it reaches (( )); reject anything else\n' \
  > "$WS/answers.txt"
cat > "$WS/hardened.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
n=$1
case "$n" in
  '' | *[!0-9]*) echo "refusing non-numeric input: $n" >&2; exit 2 ;;
esac
result=$(( n * 2 ))
echo "result=$result"
SCRIPT
bash_check_pass "L3.5" $'b\nb\nb\n'

# L3.6 — Subshell var loss (PREDICT: predictions.txt only)
"$LAB" start bash L3.6 > /dev/null 2>&1
WS="$COPY/workspace/bash/L3.6"
bash_check_fail_missing "L3.6" "predictions.txt"
printf 'pipe=0\nprocsub=3\nwhy=the pipe runs the while in a subshell, so count changes are lost\n' \
  > "$WS/predictions.txt"
bash_check_pass "L3.6" $'b\nb\nb\n'

# L3.7 — eval injection (AUDIT, fenced)
"$LAB" start bash L3.7 > /dev/null 2>&1
WS="$COPY/workspace/bash/L3.7"
bash_check_fail_missing "L3.7" "hardened.sh"
printf 'line=5\nflaw=eval-injection\nfix=dispatch through a case/array allowlist — never build a string and re-parse it\n' \
  > "$WS/answers.txt"
cat > "$WS/hardened.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
action=$1
target=$2
case "$action" in
  stat) stat -- "$target" ;;
  size) wc -c -- "$target" ;;
  type) file -- "$target" ;;
  *) echo "unknown action: $action" >&2; exit 2 ;;
esac
SCRIPT
bash_check_pass "L3.7" $'b\nb\nb\n'

# L3.8 — ShellCheck as co-pilot (GUIDED: answers.txt only, no script executed)
"$LAB" start bash L3.8 > /dev/null 2>&1
WS="$COPY/workspace/bash/L3.8"
bash_check_fail_missing "L3.8" "answers.txt"
printf 'sc2115=security\nsc2086=security\nsc2035=security\nsc2034=cosmetic\nsc2006=cosmetic\nblindspot=eval injection\n' \
  > "$WS/answers.txt"
bash_check_pass "L3.8" $'b\nb\nb\n'

# L3.9 — Phase gate (TAME, gate, BOTH containment mechanisms): edit
# deploy.sh in place; fence.log must carry the flawed-run evidence too
# (deploy.sh is edited in place, so this can't be regenerated from the
# now-hardened script — see lab.md's deploy.sh.flawed snapshot approach).
"$LAB" start bash L3.9 > /dev/null 2>&1
WS="$COPY/workspace/bash/L3.9"
bash_check_fail_missing "L3.9" "the fix (deploy.sh left unedited) + fence.log evidence"
printf 'a_rmrf=8\nb_split=9\nc_unquoted=10\nd_dashname=12\ne_arith=14\nf_eval=15\n' > "$WS/answers.txt"
printf 'FENCE-BLOCKED: rm -rf /\n' > "$WS/fence.log"
cat > "$WS/deploy.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
run_build() { echo "building..."; }
run_test() { echo "testing..."; }

REL=${1:?release dir required}
scale=${2:?scale required}
step=${3:?build step required}

case "$scale" in '' | *[!0-9]*) echo "scale must be numeric" >&2; exit 2 ;; esac

rm -rf "${REL:?}/"
mkdir -p "$REL"
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  cp -- "$f" "$REL"/
done < manifest.txt
rm -f -- ./*.tmp
workers=$(( scale * 2 ))
case "$step" in
  build) run_build ;;
  test)  run_test ;;
  *) echo "unknown step: $step" >&2; exit 2 ;;
esac
echo "deployed with $workers workers"
SCRIPT
bash_check_pass "L3.9" $'b\nb\nb\n'

out="$("$LAB" status 2>&1)"
assert_contains "status shows all 28 bash P0-P3 labs passed, P4 still pending (28/54)" "$out" "(28/54)"

# --- 7d. bash track P4 (Untrusted Input & Injection): fabricated pass +
# negative case per lab. Every AUDIT/TAME lab's negative case matches the
# FIX-type convention above (L2.8/L3.x): leave the shipped flawed script
# unedited / artifacts absent, never a separately-deleted file. ---
note "bash track P4: fabricated pass + negative case per lab"

# L4.1 — Command injection (AUDIT, fenced real detonation; phase opener:
# recall must never gate)
out="$(printf 'b\nb\nb\nb\nb\n' | "$LAB" start bash L4.1 2>&1)"; rc=$?
assert_eq "'lab start bash L4.1' exits 0 regardless of recall score" "0" "$rc"
assert_contains "L4.1 start ran the recall quiz" "$out" "recall"
WS="$COPY/workspace/bash/L4.1"
bash_check_fail_missing "L4.1" "hardened.sh"
printf 'line=5\nflaw=command-injection\ncwe=CWE-78\nfix=call grep directly, pass "$name" as a separate argument, no shell string\n' \
  > "$WS/answers.txt"
cat > "$WS/hardened.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
name=$1
line=$(grep -- "^$name:" greetings.txt || true)
echo "$line"
SCRIPT
bash_check_pass "L4.1" $'b\nb\nc\n'

# L4.2 — The curl | bash audit (AUDIT, pure reading, nothing executed)
"$LAB" start bash L4.2 > /dev/null 2>&1
WS="$COPY/workspace/bash/L4.2"
bash_check_fail_missing "L4.2" "answers.txt"
printf 'verdict=unsafe\nflag1=remote-exec\nflag2=privilege\nflag3=http-binary\nflag4=persistence\nflag5=exfil\nsafe_alternative=download to a file, read it, pin a version, then run\n' \
  > "$WS/answers.txt"
bash_check_pass "L4.2" $'b\nb\nb\n'

# L4.3 — Argument injection and the -- guard (AUDIT, no fence)
"$LAB" start bash L4.3 > /dev/null 2>&1
WS="$COPY/workspace/bash/L4.3"
bash_check_fail_missing "L4.3" "hardened.sh"
printf 'line=5\nflaw=argument-injection\ncwe=CWE-88\nfix=mv -- "$f" staging/  (end-of-options guard)\n' \
  > "$WS/answers.txt"
cat > "$WS/hardened.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
f=$1
mv -- "$f" staging/
SCRIPT
bash_check_pass "L4.3" $'b\nb\nb\n'

# L4.4 — Environment attacks: PATH, IFS (AUDIT, no fence)
"$LAB" start bash L4.4 > /dev/null 2>&1
WS="$COPY/workspace/bash/L4.4"
bash_check_fail_missing "L4.4" "hardened.sh"
printf 'line=5\nflaw=untrusted-search-path\ncwe=CWE-426\nfix=pin an absolute, minimal PATH with no current-directory entry\nalso=IFS\n' \
  > "$WS/answers.txt"
cat > "$WS/hardened.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
PATH=/usr/bin:/bin
if pgrep -x acme-agent > /dev/null; then
  exit 0
fi
logger "acme-agent not running"
SCRIPT
bash_check_pass "L4.4" $'b\nb\nb\n'

# L4.5 — Reading obfuscated shell (AUDIT, decode-to-file, genuine-decode
# check.sh diffs the learner's decoded.txt against its own reference decode)
"$LAB" start bash L4.5 > /dev/null 2>&1
WS="$COPY/workspace/bash/L4.5"
bash_check_fail_missing "L4.5" "answers.txt"
printf 'verdict=malicious\nflag1=obfuscation\nflag2=remote-download\nflag3=hidden-file\nflag4=persistence\nc2=203.0.113.9\n' \
  > "$WS/answers.txt"
(cd -- "$WS" && base64 -d payload.b64 > decoded.txt)
bash_check_pass "L4.5" $'a\nb\nc\n'

# L4.6 — Handling untrusted input correctly (DECODE: comprehension only,
# safe-input.sh is correct reference code, never executed by check.sh)
"$LAB" start bash L4.6 > /dev/null 2>&1
WS="$COPY/workspace/bash/L4.6"
bash_check_fail_missing "L4.6" "answers.txt"
printf 'validation=allowlist\ngrep_f=literal\ndashdash=options\npath=absolute\nsafest=arguments\n' \
  > "$WS/answers.txt"
bash_check_pass "L4.6" $'c\na\nb\n'

# L4.7 — Temp files done right: mktemp and TOCTOU (TAME: edit cache.sh in
# place)
"$LAB" start bash L4.7 > /dev/null 2>&1
WS="$COPY/workspace/bash/L4.7"
bash_check_fail_missing "L4.7" "the fix (cache.sh left unedited)"
printf 'flaw=toctou\ncwe=CWE-367\n' > "$WS/answers.txt"
cat > "$WS/cache.sh" <<'SCRIPT'
#!/usr/bin/env bash
process() { wc -c < "$1"; }
set -euo pipefail
tmp=$(mktemp)
trap 'rm -f -- "$tmp"' EXIT
echo "$DATA" > "$tmp"
process "$tmp"
SCRIPT
bash_check_pass "L4.7" $'c\na\nb\n'

# L4.8 — Phase gate: audit a realistic malicious installer end to end
# (AUDIT, gate, pure reading, decode-to-file, genuine-decode + 9-finding
# line map + IOC)
"$LAB" start bash L4.8 > /dev/null 2>&1
WS="$COPY/workspace/bash/L4.8"
bash_check_fail_missing "L4.8" "answers.txt"
printf 'verdict=unsafe\nsearch_path=5\npredictable_temp=6\nremote_exec=8\nprivilege=9\nhttp_binary=11\narg_injection=13\nobfuscation=16\npersistence=17\nexfil=18\nc2=198.51.100.7\n' \
  > "$WS/answers.txt"
(cd -- "$WS" && base64 -d payload.b64 > decoded.txt)
bash_check_pass "L4.8" $'b\nc\na\n'

out="$("$LAB" status 2>&1)"
assert_contains "status shows all 36 bash P0-P4 labs passed (36/54)" "$out" "(36/54)"

# --- 7e. bash track P5 (Text Processing & Pipelines): fabricated pass per
# lab. Nothing in this phase is destructive -- every reference script is
# real, correct, and safe to execute for real, so there is no flawed-sample
# negative case; the negative case for every lab is simply the
# comprehension/prediction file not existing yet. ---
note "bash track P5: fabricated pass + negative case per lab"

# L5.1 -- Pipelines and the core tools (DECODE; phase opener: recall must
# never gate)
out="$(printf 'b\nb\nb\nb\nb\n' | "$LAB" start bash L5.1 2>&1)"; rc=$?
assert_eq "'lab start bash L5.1' exits 0 regardless of recall score" "0" "$rc"
assert_contains "L5.1 start ran the recall quiz" "$out" "recall"
WS="$COPY/workspace/bash/L5.1"
bash_check_fail_missing "L5.1" "answers.txt"
printf 'stage4=filter\nstage5=field\nstage6=order\nstage7=count\nstage8=rank\ntop_ip=203.0.113.7\ntop_count=4\n' \
  > "$WS/answers.txt"
bash_check_pass "L5.1" $'b\na\nb\n'

# L5.2 -- sed at reading level (DECODE)
"$LAB" start bash L5.2 > /dev/null 2>&1
WS="$COPY/workspace/bash/L5.2"
bash_check_fail_missing "L5.2" "answers.txt"
printf 'dash_e=extended\nflag_g=global\npurpose5=mask\npurpose6=reorder\nbackslash1=capture\n' \
  > "$WS/answers.txt"
bash_check_pass "L5.2" $'b\nb\nb\n'

# L5.3 -- awk at reading level (PREDICT)
"$LAB" start bash L5.3 > /dev/null 2>&1
WS="$COPY/workspace/bash/L5.3"
bash_check_fail_missing "L5.3" "predictions.txt"
printf 'predict1_line1=high 3\npredict1_line2=low 2\npredict1_line3=medium 1\npredict2_line1=2026-07-18T10:00:00Z host-a.test\npredict2_line2=2026-07-18T10:07:00Z host-a.test\npredict2_line3=2026-07-18T10:11:00Z host-b.test\npredict3=3 fields: timestamp,severity,host\n' \
  > "$WS/predictions.txt"
bash_check_pass "L5.3" $'b\nb\nb\n'

# L5.4 -- jq: reading JSON pipelines (DECODE)
"$LAB" start bash L5.4 > /dev/null 2>&1
WS="$COPY/workspace/bash/L5.4"
bash_check_fail_missing "L5.4" "answers.txt"
printf 'flag_c=compact\nkey_style=literal\nline9=derived\ntest_fn=regex\n' \
  > "$WS/answers.txt"
bash_check_pass "L5.4" $'b\na\nb\n'

# L5.5 -- process substitution, here-docs, here-strings (DECODE)
"$LAB" start bash L5.5 > /dev/null 2>&1
WS="$COPY/workspace/bash/L5.5"
bash_check_fail_missing "L5.5" "answers.txt"
printf 'construct4=procsub\nconstruct8=herestring\nconstruct14=heredoc\nexpands=yes\n' \
  > "$WS/answers.txt"
bash_check_pass "L5.5" $'b\na\na\n'

# L5.6 -- Phase gate: decode a real log-processing pipeline top to bottom
# (DECODE, gate)
"$LAB" start bash L5.6 > /dev/null 2>&1
WS="$COPY/workspace/bash/L5.6"
bash_check_fail_missing "L5.6" "answers.txt"
printf 'stage_grep=filter\nstage_awk=field\nstage_diff=procsub\nstage_sed=herestring\nstage_jq=reshape\nstage_heredoc=report\ntop_ip=203.0.113.7\ntop_count=4\nip_status=unknown\nnew_count=1\n' \
  > "$WS/answers.txt"
bash_check_pass "L5.6" $'b\nb\nc\n'

out="$("$LAB" status 2>&1)"
assert_contains "status shows all 42 bash P0-P5 labs passed (42/54)" "$out" "(42/54)"

# --- 7f. bash track P6 (Reading Real Deploy Scripts): fabricated pass per
# lab. TOUR labs carry clean reference code; the negative case for every lab is
# simply answers.txt not existing yet. ---
note "bash track P6: fabricated pass + negative case per lab"

# L6.1 -- Tour: a Security Onion-style installer/runbook (TOUR; phase opener:
# recall must never gate)
out="$(printf 'b\nb\nb\na\nb\n' | "$LAB" start bash L6.1 2>&1)"; rc=$?
assert_eq "'lab start bash L6.1' exits 0 regardless of recall score" "0" "$rc"
assert_contains "L6.1 start ran the recall quiz" "$out" "recall"
WS="$COPY/workspace/bash/L6.1"
bash_check_fail_missing "L6.1" "answers.txt"
printf 'idempotent=config_changed\natomic=mv\ngatekeeper=validate_config\nverify=active\nrisk=restart\ntrusted=staged\n' \
  > "$WS/answers.txt"
bash_check_pass "L6.1" $'b\na\na\n'

# L6.2 -- Tour: a Docker entrypoint.sh (TOUR)
"$LAB" start bash L6.2 > /dev/null 2>&1
WS="$COPY/workspace/bash/L6.2"
bash_check_fail_missing "L6.2" "answers.txt"
printf 'override=nothing\nprepend=log-relay\nheredoc=expands\nprobe=devtcp\nhandoff=exec\nexposure=listen\n' \
  > "$WS/answers.txt"
bash_check_pass "L6.2" $'b\nb\na\n'

# L6.3 -- Tour: a systemd unit + ExecStart script (TOUR)
"$LAB" start bash L6.3 > /dev/null 2>&1
WS="$COPY/workspace/bash/L6.3"
bash_check_fail_missing "L6.3" "answers.txt"
printf 'runuser=logrelay\npullin=wants\nenvdash=optional\nexecwhy=daemon\nwritegate=readwritepaths\ncrashguard=crashloop\n' \
  > "$WS/answers.txt"
bash_check_pass "L6.3" $'a\nb\nb\n'

# L6.4 -- Tour: a CI pipeline script (TOUR)
"$LAB" start bash L6.4 > /dev/null 2>&1
WS="$COPY/workspace/bash/L6.4"
bash_check_fail_missing "L6.4" "answers.txt"
printf 'thinyaml=parity\nfailstop=pipefail\nfallback=git\ntarflags=reproducible\nintegrity=sha256\nexposure=env\n' \
  > "$WS/answers.txt"
bash_check_pass "L6.4" $'b\nb\nb\n'

# L6.5 -- Phase gate: solo tour of an unseen deploy script (TOUR, gate)
"$LAB" start bash L6.5 > /dev/null 2>&1
WS="$COPY/workspace/bash/L6.5"
bash_check_fail_missing "L6.5" "answers.txt"
printf 'schedule=4\nlock=flock\nlockexit=0\npinpath=cron\ntmphome=atomic\nmustpass=jq\nfailmode=kept\nwarnwho=monitoring\n' \
  > "$WS/answers.txt"
bash_check_pass "L6.5" $'a\nb\nb\n'

out="$("$LAB" status 2>&1)"
assert_contains "status shows all 47 bash P0-P6 labs passed (47/54)" "$out" "(47/54)"

# --- 7g. bash track P7 (Directing & Auditing AI-Generated Bash): fabricated pass per
# lab. ---
note "bash track P7: fabricated pass + negative case per lab"

# L7.1 -- Why AI Bash is dangerous by default (AUDIT; phase opener: recall must never gate)
out="$(printf 'b\na\nb\na\nb\n' | "$LAB" start bash L7.1 2>&1)"; rc=$?
assert_eq "'lab start bash L7.1' exits 0 regardless of recall score" "0" "$rc"
assert_contains "L7.1 start ran the recall quiz" "$out" "recall"
WS="$COPY/workspace/bash/L7.1"
bash_check_fail_missing "L7.1" "answers.txt"
printf 'strictmode=pipefail\ncdrisk=wrongdir\nexecflaw=evalhook\nsc2164=sc2164\nsc2006=sc2006\nblindspot=evalhook\ntell=comments\n' \
  > "$WS/answers.txt"
bash_check_pass "L7.1" $'b\nb\na\n'

# L7.2 -- The safe-Bash spec (DIRECT)
"$LAB" start bash L7.2 > /dev/null 2>&1
WS="$COPY/workspace/bash/L7.2"
bash_check_fail_missing "L7.2" "spec.md"
printf 'whystrict=silentsuccess\nwhyaccept=mechanical\nwhyban=code\n' > "$WS/answers.txt"
cat > "$WS/spec.md" <<'SPEC'
# Safe-Bash Spec
## 1. Non-negotiable preamble
preamble=set -euo pipefail
## 2. Quoting rule
quoting=always
## 3. Input validation
validation=reject-unset
## 4. Forbidden constructs
forbidden=evalstring
## 5. Error handling
errors=fail-loud
## 6. Acceptance criteria
acceptance=shellcheck-clean
SPEC
bash_check_pass "L7.2" $'a\nb\na\n'

# L7.3 -- The AI-Bash review checklist v1 (AUDIT)
"$LAB" start bash L7.3 > /dev/null 2>&1
WS="$COPY/workspace/bash/L7.3"
bash_check_fail_missing "L7.3" "checklist.md"
printf 'firstcheck=c1-strictmode\nlastcheck=c8-shellcheck\ninvisible=c4-noeval\nadvisory=c7-cleanup\nanchoring=anchoring\n' \
  > "$WS/answers.txt"
cat > "$WS/checklist.md" <<'CHECKLIST'
c1-strictmode - Does line 1-3 set errexit, nounset, and pipefail?
c2-quoting - Is every expansion quoted unless splitting is explicitly wanted?
c3-input - Is every argument and env var validated before use?
c4-noeval - Is any string re-parsed as code by a shell builtin?
c5-cdguard - Does every cd have a failure guard, or is the script path-absolute?
c6-tempfiles - Are temp files created with mktemp, never a predictable path?
c7-cleanup - Is there a trap that cleans up on every exit path?
c8-shellcheck - Does shellcheck -x -S style emit zero findings?
CHECKLIST
bash_check_pass "L7.3" $'a\na\na\n'

# L7.4 -- Review reps: 3 AI-generated scripts (AUDIT)
"$LAB" start bash L7.4 > /dev/null 2>&1
WS="$COPY/workspace/bash/L7.4"
bash_check_fail_missing "L7.4" "answers.txt"
printf 's1_worst=unsetvar\ns1_savedby=nounset\ns2_findings=0\ns2_fetch=nofail\ns2_integrity=checksum\ns2_temppath=predictable\ns2_model=l6.5\ns3_severity=sc2045\ns3_breaks=spaces\ns3_useless=cat\ncleanest=gen2\nlesson=floor\n' \
  > "$WS/answers.txt"
bash_check_pass "L7.4" $'b\na\na\n'

# L7.5 -- CI guardrails: ShellCheck + shfmt (GUIDED)
"$LAB" start bash L7.5 > /dev/null 2>&1
WS="$COPY/workspace/bash/L7.5"
bash_check_fail_missing "L7.5" "answers.txt"
printf 'gatefail=sc2086\nwhyexit=exitcode\nfmtflag=-d\nstrictgate=failfast\nsweeptrap=untracked\n' \
  > "$WS/answers.txt"
cat > "$WS/scripts/bad.sh" <<'SCRIPT'
#!/bin/bash
set -euo pipefail
msg="hello from the gate demo"
echo "$msg"
SCRIPT
(cd "$WS" && shfmt -w scripts/)
bash_check_pass "L7.5" $'a\na\na\n'

# L7.6 -- Capstone: direct + audit a SOC-relevant script (DIRECT)
"$LAB" start bash L7.6 > /dev/null 2>&1
WS="$COPY/workspace/bash/L7.6"
bash_check_fail_missing "L7.6" "ingest-spec.md"
printf 'sc_count=3\nrealflaw=injection\nwhyquiet=quoted\ntempflaw=predictable\nappendbug=double\nchecklist=c4-noeval\n' \
  > "$WS/answers.txt"
cat > "$WS/ingest-spec.md" <<'SPEC'
# Log-Ingest Helper Spec
input=validate
temp=mktemp
filter=no-user-filter
malformed=skip-and-count
accept=shellcheck-clean
SPEC
bash_check_pass "L7.6" $'b\na\na\n'

# L7.7 -- Capstone gate: ship a hardened, shellcheck-clean script (AUDIT, gate)
"$LAB" start bash L7.7 > /dev/null 2>&1
WS="$COPY/workspace/bash/L7.7"
bash_check_fail_missing "L7.7" "hardened.sh"
printf 'loopform=redirect\nnotemp=herestring\nstreams=stderr\nnoinject=removing-the-filter\nexitnone=nonzero\n' \
  > "$WS/answers.txt"
cat > "$WS/hardened.sh" <<'SCRIPT'
#!/bin/bash
set -euo pipefail

usage() { echo "usage: $0 <input.ndjson>" >&2; exit 2; }

[[ $# -eq 1 ]] || usage
readonly INPUT="$1"
[[ -r $INPUT ]] || { echo "input not readable: $INPUT" >&2; exit 1; }

valid=0
skipped=0
while IFS= read -r line; do
    [[ -n $line ]] || continue
    if out=$(jq -ce 'select(.ts and .src and .action)
                     | {"@timestamp": .ts, "source.ip": .src, "event.action": .action}' \
                     <<<"$line" 2>/dev/null); then
        printf '%s\n' "$out"
        valid=$((valid + 1))
    else
        skipped=$((skipped + 1))
    fi
done < "$INPUT"

echo "valid=$valid skipped=$skipped" >&2
[[ $valid -gt 0 ]]
SCRIPT
chmod +x "$WS/hardened.sh"
bash_check_pass "L7.7" $'b\na\na\n'

out="$("$LAB" status 2>&1)"
assert_contains "status shows all 54 bash P0-P7 labs passed (54/54)" "$out" "(54/54)"

# --- 7h. rust track P0-P2: fabricated pass + negative case per lab ---
note "rust track P0-P2: fabricated pass + negative case per lab"

rust_check_fail_missing() {
  local id="$1" missing="$2" out rc
  out="$("$LAB" check rust "$id" 2>&1)"; rc=$?
  assert_eq "rust $id check fails before $missing exists" "1" "$rc"
  assert_contains "rust $id fail result names FAIL" "$out" "RESULT: FAIL"
}

rust_check_pass() {
  local id="$1" quiz="$2" out rc
  out="$(printf '%s' "$quiz" | "$LAB" check rust "$id" 2>&1)"; rc=$?
  assert_eq "rust $id check passes" "0" "$rc"
  assert_contains "rust $id result names PASS" "$out" "RESULT: PASS"
}

# L0.1 — Toolchain verification
"$LAB" start rust L0.1 > /dev/null 2>&1
WS="$COPY/workspace/rust/L0.1"
cat > "$WS/toolchain.txt" <<'EOF'
rustc 1.97.0
cargo 1.97.0
EOF
mkdir -p "$WS/hello_lab/src" "$WS/hello_lab/target/debug"
cat > "$WS/hello_lab/Cargo.toml" <<'EOF'
[package]
name = "hello_lab"
version = "0.1.0"
EOF
cat > "$WS/hello_lab/src/main.rs" <<'RS'
fn main() { println!("Hello, world!"); }
RS
cat > "$WS/first_run.txt" <<'EOF'
Hello, world!
EOF
rust_check_fail_missing "L0.1" "hello_lab/target/debug/hello_lab"
(cd -- "$WS/hello_lab" && rustc src/main.rs -o target/debug/hello_lab)
rust_check_pass "L0.1" $'b\ntarget/debug\nb\n'

# L0.2 — Meet the lab kit
"$LAB" start rust L0.2 > /dev/null 2>&1
WS="$COPY/workspace/rust/L0.2"
cat > "$WS/answers.txt" <<'EOF'
q1=b
q2=3
q3=b
EOF
rust_check_fail_missing "L0.2" "location.txt"
(cd -- "$WS" && pwd > location.txt)
rust_check_pass "L0.2" $'b\nlab status\nb\n'

# L0.3 — Repo anatomy (gate)
"$LAB" start rust L0.3 > /dev/null 2>&1
WS="$COPY/workspace/rust/L0.3"
cat > "$WS/answers.txt" <<'EOF'
q1=scanport
q2=src/main.rs
q3=src/lib.rs
q4=0
q5=b
q6=a
EOF
rust_check_fail_missing "L0.3" "run_out.txt"
cat > "$WS/run_out.txt" <<'EOF'
22 -> ok (port 22)
99999 -> INVALID
EOF
mkdir -p "$WS/scanport/target/doc/scanport"
touch "$WS/scanport/target/doc/scanport/index.html"
rust_check_pass "L0.3" $'b\ncargo doc --no-deps\nb\n'

# L1.1 — Reading rustc output (phase opener)
out="$(printf 'b\nb\nb\nb\nb\n' | "$LAB" start rust L1.1 2>&1)"; rc=$?
assert_eq "'lab start rust L1.1' exits 0 regardless of recall score" "0" "$rc"
assert_contains "L1.1 start ran the recall quiz" "$out" "recall"
WS="$COPY/workspace/rust/L1.1"
cat > "$WS/predictions.txt" <<'EOF'
x=12
count=15
label=3
error=E0384
EOF
rust_check_fail_missing "L1.1" "sample"
(cd -- "$WS" && rustc sample.rs -o sample)
rust_check_pass "L1.1" $'b\nc\nmut\n'

# L1.2 — Variables, let, mut
"$LAB" start rust L1.2 > /dev/null 2>&1
WS="$COPY/workspace/rust/L1.2"
cat > "$WS/predictions.txt" <<'EOF'
debug=panic
release=0
checked=None
wrapped=0
EOF
rust_check_fail_missing "L1.2" "debug_out.txt"
cat > "$WS/debug_out.txt" <<'EOF'
attempt to add with overflow
EOF
cat > "$WS/release_out.txt" <<'EOF'
bumped = 0
EOF
rust_check_pass "L1.2" $'b\nchecked_add\nb\n'

# L1.3 — Scalar types & inference
"$LAB" start rust L1.3 > /dev/null 2>&1
WS="$COPY/workspace/rust/L1.3"
cat > "$WS/predictions.txt" <<'EOF'
x=9
kind=well-known
parity=odd
error=E0308
EOF
rust_check_fail_missing "L1.3" "sample"
(cd -- "$WS" && rustc sample.rs -o sample)
rust_check_pass "L1.3" $'b\nb\n&str\n'

# L1.4 — Functions & ownership preview
"$LAB" start rust L1.4 > /dev/null 2>&1
WS="$COPY/workspace/rust/L1.4"
cat > "$WS/answers.txt" <<'EOF'
q1=b
q2=b
q3=E0382
EOF
rust_check_fail_missing "L1.4" "sample"
(cd -- "$WS" && rustc sample.rs -o sample)
rust_check_pass "L1.4" $'b\nc\n&str\n'

# L1.5 — Structs
"$LAB" start rust L1.5 > /dev/null 2>&1
WS="$COPY/workspace/rust/L1.5"
cat > "$WS/answers.txt" <<'EOF'
q1=b
q2=port,tls
q3=c
EOF
rust_check_fail_missing "L1.5" "sample"
(cd -- "$WS" && rustc sample.rs -o sample)
rust_check_pass "L1.5" $'#[derive(Debug)]\nb\nc\n'

# L1.6 — Enums carrying data
"$LAB" start rust L1.6 > /dev/null 2>&1
WS="$COPY/workspace/rust/L1.6"
cat > "$WS/answers.txt" <<'EOF'
q1=b
q2=b
q3=scan 1-1024
EOF
rust_check_fail_missing "L1.6" "sample"
(cd -- "$WS" && rustc sample.rs -o sample)
rust_check_pass "L1.6" $'b\nb\nscan 1-1024\n'

# L1.7 — Match exhaustiveness
"$LAB" start rust L1.7 > /dev/null 2>&1
WS="$COPY/workspace/rust/L1.7"
cat > "$WS/answers.txt" <<'EOF'
error_code=E0004
EOF
cat > "$WS/fixed.rs" <<'RS'
enum Severity { Info, Warning, Critical }
fn triage(s: Severity) -> &'static str {
    match s {
        Severity::Info => "log to file",
        Severity::Warning => "alert on-call",
        Severity::Critical => "isolate host",
    }
}
fn main() { println!("{}", triage(Severity::Critical)); }
RS
rust_check_fail_missing "L1.7" "fixed"
(cd -- "$WS" && rustc fixed.rs -o fixed)
rust_check_pass "L1.7" $'critical\nb\na\n'

# L1.8 — Option: not null
"$LAB" start rust L1.8 > /dev/null 2>&1
WS="$COPY/workspace/rust/L1.8"
cat > "$WS/predictions.txt" <<'EOF'
p1=Some(22)
p2=None
p3=0
p4=53
error=E0308
EOF
rust_check_fail_missing "L1.8" "sample"
(cd -- "$WS" && rustc sample.rs -o sample)
rust_check_pass "L1.8" $'b\nunwrap_or\na\n'

# L1.9 — Phase gate: read cold code (gate)
"$LAB" start rust L1.9 > /dev/null 2>&1
WS="$COPY/workspace/rust/L1.9"
cat > "$WS/answers.txt" <<'EOF'
q1=Benign
q2=Suspicious
q3=Hostile
q4=1
q5=18
q6=3389
q7=3
q8=b
q9=b
q10=b
EOF
rust_check_fail_missing "L1.9" "triage"
(cd -- "$WS" && rustc triage.rs -o triage)
rust_check_pass "L1.9" $'b\nb\n&\n'

# L2.1 — Move semantics (phase opener)
out="$(printf 'b\nb\nb\nb\nb\n' | "$LAB" start rust L2.1 2>&1)"; rc=$?
assert_eq "'lab start rust L2.1' exits 0 regardless of recall score" "0" "$rc"
assert_contains "L2.1 start ran the recall quiz" "$out" "recall"
WS="$COPY/workspace/rust/L2.1"
cat > "$WS/predictions.txt" <<'EOF'
beta=intrusion
size=7
delta=intrusion
error=E0382
EOF
rust_check_fail_missing "L2.1" "sample"
(cd -- "$WS" && rustc sample.rs -o sample)
rust_check_pass "L2.1" $'b\nc\nclone\n'

# L2.2 — Copy vs Clone
"$LAB" start rust L2.2 > /dev/null 2>&1
WS="$COPY/workspace/rust/L2.2"
cat > "$WS/predictions.txt" <<'EOF'
b=41
w=5
first=20
error=E0204
EOF
rust_check_fail_missing "L2.2" "sample"
(cd -- "$WS" && rustc sample.rs -o sample)
rust_check_pass "L2.2" $'b\nb\nno\n'

# L2.3 — Shared borrows
"$LAB" start rust L2.3 > /dev/null 2>&1
WS="$COPY/workspace/rust/L2.3"
cat > "$WS/predictions.txt" <<'EOF'
alias=bastion-01
max=11
error=E0596
EOF
rust_check_fail_missing "L2.3" "sample"
(cd -- "$WS" && rustc sample.rs -o sample)
rust_check_pass "L2.3" $'c\nb\nimmutable\n'

# L2.4 — Mutable borrows & Aliasing XOR Mutation
"$LAB" start rust L2.4 > /dev/null 2>&1
WS="$COPY/workspace/rust/L2.4"
cat > "$WS/answers.txt" <<'EOF'
error_code=E0502
q2=b
q3=b
EOF
cat > "$WS/fixed.rs" <<'RS'
fn main() {
    let mut queue = String::from("alert-1");
    let snapshot = &queue[..];
    println!("snapshot = {snapshot}");
    queue.push_str(",alert-2");
    println!("queue = {queue}");
}
RS
rust_check_fail_missing "L2.4" "fixed"
(cd -- "$WS" && rustc fixed.rs -o fixed)
rust_check_pass "L2.4" $'a\nb\n1\n'

# L2.5 — Borrow-error triage I
"$LAB" start rust L2.5 > /dev/null 2>&1
WS="$COPY/workspace/rust/L2.5"
cat > "$WS/answers.txt" <<'EOF'
e1=E0382
c1=a
e2=E0499
c2=b
e3=E0502
c3=c
EOF
cat > "$WS/fixed1.rs" <<'RS'
fn banner(text: &str) -> String { format!("== {text} ==") }
fn main() {
    let title = String::from("scan report");
    let framed = banner(&title);
    println!("{framed}");
    println!("original: {title}");
}
RS
cat > "$WS/fixed2.rs" <<'RS'
fn main() {
    let mut counters = vec![1, 2, 3];
    let first = &mut counters[0];
    *first += 10;
    let second = &mut counters[1];
    *second += 10;
    println!("{counters:?}");
}
RS
cat > "$WS/fixed3.rs" <<'RS'
fn main() {
    let mut log = vec![String::from("boot")];
    log.push(String::from("login"));
    let last = &log[0];
    println!("last = {last}");
    println!("entries = {}", log.len());
}
RS
rust_check_fail_missing "L2.5" "fixed1"
(cd -- "$WS" && rustc fixed1.rs -o fixed1 && rustc fixed2.rs -o fixed2 && rustc fixed3.rs -o fixed3)
rust_check_pass "L2.5" $'a\nb\ncompile\n'

# L2.6 — String vs &str
"$LAB" start rust L2.6 > /dev/null 2>&1
WS="$COPY/workspace/rust/L2.6"
cat > "$WS/answers.txt" <<'EOF'
q1=c
q2=https
q3=tcp
q4=18
q5=b
EOF
rust_check_fail_missing "L2.6" "sample"
(cd -- "$WS" && rustc sample.rs -o sample)
rust_check_pass "L2.6" $'b\nb\nbytes\n'

# L2.7 — Lifetimes
"$LAB" start rust L2.7 > /dev/null 2>&1
WS="$COPY/workspace/rust/L2.7"
cat > "$WS/answers.txt" <<'EOF'
q1=b
q2=credential-stuffing
q3=b
q4=b
q5=E0597
EOF
rust_check_fail_missing "L2.7" "sample"
(cd -- "$WS" && rustc sample.rs -o sample)
rust_check_pass "L2.7" $'a\nb\nfalse\n'

# L2.8 — The C++ crime scene
"$LAB" start rust L2.8 > /dev/null 2>&1
WS="$COPY/workspace/rust/L2.8"
cat > "$WS/answers.txt" <<'EOF'
q1=CWE-416
q2=b
q3=E0502
q4=b
q5=b
EOF
rust_check_fail_missing "L2.8" "rust_error.txt"
(cd -- "$WS" && rustc equivalent.rs 2> rust_error.txt || true)
rust_check_pass "L2.8" $'a\nb\nuse-after-free\n'

# L2.9 — Borrow-error triage II
"$LAB" start rust L2.9 > /dev/null 2>&1
WS="$COPY/workspace/rust/L2.9"
cat > "$WS/answers.txt" <<'EOF'
e1=E0106
c1=a
e2=E0515
c2=b
e3=E0597
c3=c
EOF
cat > "$WS/fixed1.rs" <<'RS'
fn first_token<'a>(line: &'a str, fallback: &'a str) -> &'a str {
    match line.split(',').next() { Some(t) => t, None => fallback }
}
fn main() { println!("{}", first_token("alert,high", "none")); }
RS
cat > "$WS/fixed2.rs" <<'RS'
fn stamp(prefix: &str) -> String { format!("{prefix}-4097") }
fn main() { println!("{}", stamp("sess")); }
RS
cat > "$WS/fixed3.rs" <<'RS'
fn main() {
    let newest;
    let batch = String::from("evt-9911");
    newest = &batch;
    println!("newest = {newest}");
}
RS
rust_check_fail_missing "L2.9" "fixed1"
(cd -- "$WS" && rustc fixed1.rs -o fixed1 && rustc fixed2.rs -o fixed2 && rustc fixed3.rs -o fixed3)
rust_check_pass "L2.9" $'b\nb\nowned\n'

# L2.10 — Phase gate: 5 rejections (gate)
"$LAB" start rust L2.10 > /dev/null 2>&1
WS="$COPY/workspace/rust/L2.10"
cat > "$WS/answers.txt" <<'EOF'
e1=E0382
c1=a
e2=E0499
c2=b
e3=E0502
c3=c
e4=E0515
c4=d
e5=E0597
c5=e
EOF
cat > "$WS/fixed5.rs" <<'RS'
fn main() {
    let survivor;
    let tmp = String::from("short-lived");
    survivor = &tmp;
    println!("{survivor}");
}
RS
rust_check_fail_missing "L2.10" "fixed5"
(cd -- "$WS" && rustc fixed5.rs -o fixed5)
rust_check_pass "L2.10" $'b\nb\nboth\n'

out="$("$LAB" status 2>&1)"
assert_contains "status shows all 22 rust P0-P2 labs passed (22/22)" "$out" "(22/22)"

# --- 8. README / planned_execution shape ---
note "README + planned_execution shape"
if [[ -f "$COPY/README.md" ]]; then
  cmd_count="$(grep -cE '^[[:space:]]{4,}\S.*#[[:space:]]*[0-9]' "$COPY/README.md")"
  assert_eq "README quickstart has exactly 5 numbered commands" "5" "$cmd_count"
else
  bad "README.md missing"
fi

if [[ -f "$COPY/planned_execution.md" ]]; then
  # 32 total track-phase lines; bash p0-p7 (8) + rust p0-p2 (3) are done ([x]), leaving 21
  # unstarted -- update this count whenever a phase's marker changes.
  line_count="$(grep -cE '^- \[ \] (rust|bash|soc|ps) p[0-7] ' "$COPY/planned_execution.md")"
  assert_eq "planned_execution.md has 21 unstarted track-phase lines" "21" "$line_count"
else
  bad "planned_execution.md missing"
fi

# --- summary ---
note "SUMMARY"
printf 'PASS: %d   FAIL: %d\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
