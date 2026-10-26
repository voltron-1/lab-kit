#!/usr/bin/env bash
# tests/site.sh — verification for the generated SOC page (docs/site/soc.html).
#
#   1. bundle counts            2. in-page grader vs every lab's recorded checks
#   2b. simulated terminal vs the real tools
#   3. real-kit cross-check     4. Playwright smoke (skipped if not installed)
#   5. size budget              6. --check freshness, and that it can fail
#
# The real-kit cross-check runs against a throwaway COPY of the repo, never
# this checkout's .progress.json or workspace/. Like tests/acceptance.sh it
# records failures and keeps going instead of using `set -e`.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$ROOT" || exit 1
WORK="$(mktemp -d)"
PAGE="$ROOT/docs/site/soc.html"
MAX_BYTES=$((6 * 1024 * 1024))

PASS=0
FAIL=0
cleanup() { rm -rf -- "$WORK"; }
trap cleanup EXIT

note() { printf '\n=== %s ===\n' "$1"; }
ok() { PASS=$((PASS + 1)); printf '  PASS: %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL: %s\n' "$1"; }
assert_eq() {
  if [[ "$3" == "$2" ]]; then ok "$1"; else bad "$1 (expected '$2', got '$3')"; fi
}

for tool in jq node; do
  command -v "$tool" >/dev/null 2>&1 || { echo "tests/site.sh needs $tool" >&2; exit 1; }
done

note "1. bundle counts"
DATA="$WORK/data.json"
if ./tools/build-site.sh --data-only "$DATA" 2>"$WORK/build.err"; then ok "build-site.sh --data-only"; else bad "build-site.sh --data-only"; cat "$WORK/build.err"; fi
[[ -s "$WORK/build.err" ]] && sed 's/^/    build: /' "$WORK/build.err"
count() { jq -r "$1" "$DATA" 2>/dev/null; }
assert_eq "52 labs" 52 "$(count '.labs | length')"
assert_eq "8 distinct phases" 8 "$(count '[.labs[].phase] | unique | length')"
assert_eq "7 labs with recall" 7 "$(count '[.labs[] | select(.recall != null)] | length')"
assert_eq "156 quiz questions" 156 "$(count '[.labs[].quiz | length] | add')"
assert_eq "3 pcaps with a rendering" 3 "$(count '[.labs[].files[] | select(.kind == "pcap" and (.rendered | length > 0))] | length')"
assert_eq "no lab without assertions" 0 "$(count '[.labs[] | select(.assertions | length == 0)] | length')"
assert_eq "8 gate labs" 8 "$(count '[.labs[] | select(.meta.gate == true)] | length')"
assert_eq "L4.1 records 8 assertions" 8 "$(count '.labs[] | select(.id == "L4.1") | .assertions | length')"

note "2. in-page grader against every lab"
if node tests/site-grader.mjs "$DATA"; then ok "all labs pass with synthesized answers"; else bad "grader self-consistency"; fi

note "2b. simulated terminal against the real tools"
if node tests/site-term.mjs "$DATA" >"$WORK/term.out" 2>&1; then
  ok "site-term.mjs: $(tail -n 2 "$WORK/term.out" | head -n 1)"
else
  bad "site-term.mjs"
  sed 's/^/    | /' "$WORK/term.out" | head -n 40
fi

note "3. cross-check with the real kit (throwaway copy)"
COPY="$WORK/kit"
mkdir -p "$COPY"
cp -R bin lib harness tracks "$COPY/"
for id in L4.1 L6.4; do
  ws="$COPY/workspace/soc/$id"
  (cd "$COPY" && ./bin/lab start soc "$id" --force </dev/null >/dev/null 2>&1)
  if [[ ! -d "$ws" ]]; then bad "$id: workspace not provisioned"; continue; fi
  node tests/site-grader.mjs "$DATA" --emit "$id" "$ws"
  dir="$(jq -r ".labs[] | select(.id == \"$id\") | .dir" "$DATA")"
  quiz="$(find "$COPY/tracks/soc/phases" -path "*/$dir/quiz.json")"
  replies=""
  while IFS= read -r b64; do
    replies+="$(printf '%s' "$b64" | base64 -d)"$'\n'
  done < <(jq -r '.questions[].answer_b64' "$quiz")
  (cd "$COPY" && printf '%s' "$replies" | ./bin/lab check soc "$id" >"$WORK/check-$id.out" 2>&1)
  rc=$?
  assert_eq "$id: real ./bin/lab check exits 0 on the page's synthesized answers" 0 "$rc"
  [[ "$rc" -ne 0 ]] && sed 's/^/    | /' "$WORK/check-$id.out"
done

note "4. Playwright smoke"
if node -e "require('playwright')" >/dev/null 2>&1; then
  if SITE_EXPORT_OUT="$WORK/exported.json" node tests/site-smoke.mjs >"$WORK/smoke.out" 2>&1; then
    ok "site-smoke.mjs"
  else
    bad "site-smoke.mjs"
    grep -E 'FAIL|Error|failed' "$WORK/smoke.out" | sed 's/^/    | /'
  fi
  if [[ -s "$WORK/exported.json" ]]; then
    if jq -e '.version == 1 and (.labs | type == "object") and (.events | type == "array")' "$WORK/exported.json" >/dev/null 2>&1; then
      ok "exported progress.json passes the state_apply schema test"
    else
      bad "exported progress.json fails the state_apply schema test"
    fi
  else
    bad "no exported progress.json captured"
  fi
else
  echo "  playwright: skipped"
fi

note "5. size budget"
size="$(stat -c %s "$PAGE" 2>/dev/null || echo 0)"
if [[ "$size" -gt 0 && "$size" -lt "$MAX_BYTES" ]]; then ok "soc.html is $size bytes (< 6 MB)"; else bad "soc.html size $size outside (0, 6 MB)"; fi

note "6. freshness check"
if ./tools/build-site.sh --check >/dev/null 2>&1; then ok "--check is clean"; else bad "--check reports a stale page"; fi
LAB_SITE_SALT=x ./tools/build-site.sh --check >/dev/null 2>&1
assert_eq "--check exits 1 when the build differs" 1 "$?"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
