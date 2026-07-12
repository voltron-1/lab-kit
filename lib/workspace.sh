# shellcheck shell=bash
# lib/workspace.sh — workspace provisioning (atomic, marker-based) and the
# fenced check.sh launcher. Every check.sh runs as a separate process, cwd
# pinned to the workspace, environment sanitized to a fixed allowlist. No
# containers are available in this environment, so the fence is: process
# separation + cwd + env -i allowlist + HOME/TMPDIR redirection + the
# realpath-canonicalizing path guards inside harness/checklib.sh. It stops
# accidental out-of-fence reads/writes by our own lab content; it is not a
# security boundary against a hostile grader (see harness/checklib.sh header).

ws_path() {
  printf '%s/%s/%s\n' "$WORKSPACE_DIR" "$1" "$2"
}

ws_exists() {
  local ws
  ws="$(ws_path "$1" "$2")"
  [[ -f "$ws/.lab-provisioned" ]]
}

# ws_provision <track> <id> <lab_dir> — mkdir + fence dirs + copy files/,
# marking done only as the LAST step. An interrupted provision (e.g. Ctrl-C
# mid-cp) leaves no marker, so the next `lab start` detects it and safely
# re-provisions instead of reporting "already provisioned, files preserved"
# over a half-copied workspace.
ws_provision() {
  local track="$1" id="$2" lab_dir="$3" ws
  ws="$(ws_path "$track" "$id")"
  if [[ -f "$ws/.lab-provisioned" ]]; then
    return 0
  fi
  mkdir -p -- "$ws/.home" "$ws/.tmp"
  if [[ -d "$lab_dir/files" ]]; then
    cp -R -- "$lab_dir/files/." "$ws/"
  fi
  : > "$ws/.lab-provisioned"
}

# ws_run_check <track> <id> <lab_dir> — runs check.sh as a separate,
# fenced process. Returns its exit code: 0 pass, 1 graded fail, 70 harness
# error, 124 timeout, >=128 interrupted. stdin is /dev/null so nothing
# inside check.sh can consume a piped quiz answer.
ws_run_check() {
  local track="$1" id="$2" lab_dir="$3" ws rc=0
  ws="$(ws_path "$track" "$id")"
  (
    cd -- "$ws" || exit 70
    exec env -i \
      PATH="/usr/local/bin:/usr/bin:/bin" \
      LANG="C.UTF-8" \
      TERM="${TERM:-dumb}" \
      HOME="$ws/.home" \
      TMPDIR="$ws/.tmp" \
      LAB_WORKSPACE="$ws" \
      LAB_CHECKLIB="$CHECKLIB" \
      LAB_TRACK="$track" \
      LAB_ID="$id" \
      timeout --kill-after=5s 120s \
      bash --noprofile --norc -euo pipefail -- "$lab_dir/check.sh" < /dev/null
  )
  rc=$?
  return "$rc"
}
