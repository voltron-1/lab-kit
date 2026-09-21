#!/usr/bin/env bash
# tests/session.sh — acceptance for the interactive session flow
# (`lab` with no arguments / `lab session`).
#
# Runs against a throwaway COPY of the repo, never this checkout's real
# .progress.json or workspace/. Like tests/acceptance.sh it deliberately does
# NOT use `set -e`: assertions record failures and the run continues.
#
# The session only opens on a terminal, so every interactive case is driven
# through `script`, which hands the CLI a pty and feeds it our keystrokes.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
COPY="$WORK/lab-kit"
LAB="$COPY/bin/lab"

PASS=0
FAIL=0

cleanup() { rm -rf -- "$WORK"; }
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

# drive the session on a pty: session_keys "<keystrokes>" [args...]
# The timeout is part of the assertion: a session that stops consuming input
# would otherwise wedge the whole run, since EOF on a pty never arrives.
session_keys() {
  local keys="$1"
  shift
  printf '%s' "$keys" | timeout 30 script -qec "$LAB $*" /dev/null 2> /dev/null | tr -d '\r'
}

# --- setup -------------------------------------------------------------------
note "setup"
command -v script > /dev/null 2>&1 || { printf 'FAIL: `script` (bsdutils) is required to test the pty flow\n'; exit 1; }
cp -R -- "$ROOT" "$COPY"
rm -rf -- "$COPY/workspace" "$COPY/.progress.json"
chmod 755 "$COPY/bin/lab"
find "$COPY/tracks" -name check.sh -exec chmod 644 {} +
ok "throwaway copy created"

# --- 1. non-interactive fallback ---------------------------------------------
note "no terminal on stdin keeps the old behaviour"
out="$("$LAB" < /dev/null 2>&1)"; rc=$?
assert_eq "bare 'lab' with no tty exits 0" "0" "$rc"
assert_contains "bare 'lab' with no tty prints usage" "$out" "usage: lab"
assert_contains "usage documents the interactive session" "$out" "interactive session"
out="$("$LAB" session < /dev/null 2>&1)"; rc=$?
assert_eq "'lab session' with no tty exits 0" "0" "$rc"
assert_contains "'lab session' with no tty prints usage" "$out" "usage: lab"
out="$("$LAB" help 2>&1)"
assert_contains "'lab help' still documents the five commands" "$out" "lab check [track] <id>"

# --- 2. step 1: track selection ----------------------------------------------
note "step 1 — track selection"
out="$(session_keys $'q\n')"
assert_contains "session lists the installed tracks" "$out" "Select a track"
assert_contains "track menu is numbered" "$out" "1)"
assert_contains "track menu names a track" "$out" "soc"
assert_contains "track menu shows per-track progress" "$out" "/52"
assert_contains "q at the track menu leaves cleanly" "$out" "nothing selected"

out="$(session_keys $'nosuchtrack\nq\n')"
assert_contains "an unknown track is rejected, not accepted" "$out" "no such track"

out="$(session_keys $'soc\nq\n')"
assert_contains "a track can be chosen by name" "$out" "SOC Analyst Lab"

# --- 3. step 2: the checkpoint decision --------------------------------------
note "step 2 — the checkpoint decision node"
out="$(session_keys $'soc\nq\n')"
assert_contains "checkpoint offers resume" "$out" "1) Resume from last saved checkpoint"
assert_contains "checkpoint offers start-from-the-beginning" "$out" "2) Start from the beginning"
assert_contains "a fresh track reports no checkpoint yet" "$out" "last checkpoint  none yet"
assert_contains "start-over promises progress is kept" "$out" "are kept"

# --- 4. step 3: resume restores the last active point ------------------------
note "step 3 — resume"
out="$(session_keys $'soc\n1\nquit\n')"
assert_contains "resume opens the frontier lab" "$out" "soc L0.1"
assert_contains "resume prints the lab brief" "$out" "BRIEF"
assert_contains "the session names its own commands" "$out" "check · hint · brief · files · show · edit · skip · quit"
assert_contains "quit says progress is saved" "$out" "progress saved"

# --- 5. step 3: start from the beginning is non-destructive ------------------
note "step 3 — start from the beginning keeps history"
# manufacture history: pass demo L0.0 so there is something to preserve
"$LAB" start soc L0.1 < /dev/null > /dev/null 2>&1
"$LAB" start soc L0.3 --force < /dev/null > /dev/null 2>&1   # marks L0.2 skipped
before_skipped="$(jq '[.labs | to_entries[] | select(.value.skipped == true)] | length' "$COPY/.progress.json")"
out="$(session_keys $'soc\n2\nquit\n')"
after_skipped="$(jq '[.labs | to_entries[] | select(.value.skipped == true)] | length' "$COPY/.progress.json")"
assert_contains "start-over opens the track's first lab" "$out" "soc L0.1"
assert_eq "start-over clears no skip marks" "$before_skipped" "$after_skipped"
out="$("$LAB" status 2>&1)"
assert_contains "status still shows the forced skip" "$out" "⏭"

# resume restores context, not just the pointer. A seeded pass event is the
# fixture here: this asserts what the menu renders, not how a lab is graded
# (tests/acceptance.sh owns grading), and demo is a single-lab track so passing
# it for real leaves nothing to resume.
rm -rf -- "$COPY/workspace" "$COPY/.progress.json"
"$LAB" status > /dev/null 2>&1
jq -n '{
  version: 1, created_at: "2026-03-01T00:00:00Z", updated_at: "2026-03-01T00:00:00Z",
  labs: { "soc/L0.1": { status: "passed", skipped: false, attempts: 1, hints_used: 0,
          started_at: "2026-03-01T00:00:00Z", first_passed_at: "2026-03-01T00:00:00Z",
          last_attempt_at: "2026-03-01T00:00:00Z" } },
  events: [ { seq: 1, type: "pass", track: "soc", id: "L0.1", at: "2026-03-01T00:00:00Z",
            recap: ["jq reads json, grep reads lines", "defang before you paste", "cite the event id"] } ]
}' > "$COPY/.progress.json"
out="$(session_keys $'soc\n1\nq\n')"
assert_contains "resume names the checkpoint it found" "$out" "last checkpoint  L0.1"
assert_contains "resume replays the last recap for context" "$out" "where you left off"
assert_contains "resume prints the recap text itself" "$out" "defang before you paste"
assert_contains "resume opens the lab after the checkpoint" "$out" "soc L0.2"
rm -f -- "$COPY/.progress.json"

# --- 6. step 4: the labs drive from here -------------------------------------
note "step 4 — working labs without typing an id"
out="$(session_keys $'soc\n1\ncheck\nquit\n')"
assert_contains "check runs the real grader" "$out" "checks — soc"
assert_contains "a failed check keeps you on the same lab" "$out" "RESULT: FAIL"
assert_not_contains "a failed check does not advance" "$out" "soc L0.2"

out="$(session_keys $'soc\n1\nhint\nquit\n')"
assert_contains "hint works inside the session" "$out" "[hint 1/3]"

out="$(session_keys $'soc\n1\nbrief\nquit\n')"
assert_contains "brief reprints the lab brief" "$out" "BRIEF"

out="$(session_keys $'soc\n1\nnonsense\nquit\n')"
assert_contains "an unknown command lists the real ones" "$out" "commands: check"

# --- 6b. workspace files without leaving the session --------------------------
note "workspace files without leaving the session"

out="$(session_keys $'soc\n1\nfiles\nquit\n')"
assert_contains "files lists a known fixture" "$out" "whois-stonewick.txt"
assert_contains "files lists a nested fixture with its subpath" "$out" "notes/triage-notes.txt"

out="$(session_keys $'soc\n1\nshow whois-stonewick.txt\nquit\n')"
assert_contains "show prints a fixture's contents" "$out" "Domain Name: STONEWICK.EXAMPLE"

out="$(session_keys $'soc\n1\nshow files/whois-stonewick.txt\nquit\n')"
assert_contains "show accepts a files/ prefix, same as without it" "$out" "Domain Name: STONEWICK.EXAMPLE"

out="$(session_keys $'soc\n1\nshow ../../../etc/passwd\nquit\n')"
assert_contains "show refuses a path that escapes the workspace" "$out" "no such file in this lab's workspace"
assert_not_contains "show never prints real /etc/passwd" "$out" "root:"

out="$(session_keys $'soc\n1\nshow nope.txt\nquit\n')"
assert_contains "show on a missing file names it, not a crash" "$out" "no such file: nope.txt"

# edit: EDITOR=cat turns the command into a non-interactive pass-through the
# pty harness can assert against (a real interactive editor would hang the
# 30s timeout, per session_keys' own comment above).
export EDITOR=cat
out="$(session_keys $'soc\n1\nedit whois-stonewick.txt\nquit\n')"
assert_contains "edit opens the confined file in \$EDITOR" "$out" "Domain Name: STONEWICK.EXAMPLE"

# edit must never even invoke $EDITOR on a path that escapes the workspace —
# EDITOR=false would exit non-zero if called, but confinement rejects the
# path before that, so no "editor exited non-zero" warning should appear.
out="$(session_keys $'soc\n1\nedit ../outside\nstatus\nquit\n')"
assert_contains "edit refuses a path that escapes the workspace" "$out" "no such file in this lab's workspace"
assert_not_contains "edit never launches \$EDITOR on a rejected path" "$out" "editor exited non-zero"
assert_contains "the session survives a rejected edit and keeps taking commands" "$out" "══════"
unset EDITOR

# skip: confirmed, and it marks the lab permanently
before_skipped="$(jq '[.labs | to_entries[] | select(.value.skipped == true)] | length' "$COPY/.progress.json")"
out="$(session_keys $'soc\n1\nskip\ny\nquit\n')"
after_skipped="$(jq '[.labs | to_entries[] | select(.value.skipped == true)] | length' "$COPY/.progress.json")"
assert_contains "skip warns that the mark is permanent" "$out" "permanently"
if [[ "$after_skipped" -gt "$before_skipped" ]]; then
  ok "skip records a permanent skip mark"
else
  bad "skip recorded no skip mark (before=$before_skipped after=$after_skipped)"
fi

# declining the skip changes nothing
before_skipped="$after_skipped"
out="$(session_keys $'soc\n1\nskip\nn\nquit\n')"
after_skipped="$(jq '[.labs | to_entries[] | select(.value.skipped == true)] | length' "$COPY/.progress.json")"
assert_eq "declining the skip records nothing" "$before_skipped" "$after_skipped"

# --- 7. passing a lab advances the session -----------------------------------
note "passing a lab advances to the next one"
rm -rf -- "$COPY/workspace" "$COPY/.progress.json"
WS="$COPY/workspace/demo/L0.0"
"$LAB" start demo L0.0 < /dev/null > /dev/null 2>&1
cp "$WS/broken.conf" "$WS/fixed.conf"
sed -i 's/max_retries = ten/max_retries = 3/; s/workspace_fence = off/workspace_fence = on/' "$WS/fixed.conf"
uname -r > "$WS/sysinfo.txt"
printf '%s\n' "$WS" > "$WS/location.txt"
# demo L0.0 carries a recall.json, so opening it runs a 5-question recall
# before the session prompt appears — those five answers come first, then the
# session command, then the lab's own 3-question quiz.
# demo is a single-lab track: passing it ends the track cleanly
out="$(session_keys $'demo\n1\nb\nb\nworkspace/demo/L0.0\na\nb\ncheck\nc\n.progress.json\nb\n')"
assert_contains "a passing check is graded inside the session" "$out" "checks 5/5"
assert_contains "the session reports the end of the track" "$out" "track complete"

# --- 8. the five commands still behave --------------------------------------
note "the five commands are untouched"
for cmd in status resume; do
  "$LAB" "$cmd" < /dev/null > /dev/null 2>&1
  assert_eq "'lab $cmd' still exits 0" "0" "$?"
done
out="$("$LAB" bogus 2>&1)"; rc=$?
assert_eq "an unknown command still exits 2" "2" "$rc"
assert_contains "an unknown command still names itself" "$out" "bogus"

printf '\n=== SUMMARY ===\nPASS: %s   FAIL: %s\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
