# shellcheck shell=bash
# lib/state.sh — the ONLY reader/writer of .progress.json. Every write goes
# through state_apply, which installs a fully-formed, jq-validated document
# via a same-directory mktemp + mv (atomic rename), so .progress.json can
# never be observed half-written, no matter when SIGINT/SIGTERM arrives.

STATE_TMP=""

state_cleanup_tmp() {
  if [[ -n "$STATE_TMP" ]]; then
    rm -f -- "$STATE_TMP"
    STATE_TMP=""
  fi
}

now_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

state_default() {
  local now
  now="$(now_utc)"
  jq -n --arg now "$now" '{version: 1, created_at: $now, updated_at: $now, labs: {}, events: []}'
}

# Pure read: file-or-default. Never writes, never creates the file.
#
# Every caller is `state_read | jq ...` (never `x=$(state_read)`), so this
# function's own `die` (exit 2) only ever terminates that pipe's left-hand
# subshell directly — it reaches the real caller because jq exits 0 on
# empty stdin, `pipefail` then reports state_read's exit 2 as the
# pipeline's status (the rightmost *non-zero* exit wins), and that status
# propagates through `set -e` in every nested command substitution above
# it. This is correct and tested (corrupt/wrong-version .progress.json
# exits 2 cleanly from `lab status`/`lab hint`/etc.), but it depends on
# jq's empty-stdin-is-not-an-error behavior — if any caller ever wraps a
# `state_read | jq ...` call in its own `if`/`||`, or a filter stops being
# a no-op on empty input, this error path breaks silently.
state_read() {
  if [[ -f "$STATE_FILE" ]]; then
    jq -e '.version == 1' "$STATE_FILE" >/dev/null 2>&1 \
      || die "$STATE_FILE is unreadable or has an unsupported schema version — inspect or move it aside, then re-run"
    cat -- "$STATE_FILE"
  else
    state_default
  fi
}

state_gc_tmp() {
  local f
  for f in "$STATE_FILE".*.tmp; do
    [[ -e "$f" ]] || continue
    rm -f -- "$f"
  done
}

# state_apply '<jq filter>' [jq --arg/--argjson pairs...]
# The only code path that installs a new .progress.json.
state_apply() {
  local filter="$1"; shift
  local tmp
  tmp="$(mktemp -- "${STATE_FILE}.XXXXXX.tmp")" || die "cannot create state temp file"
  STATE_TMP="$tmp"
  if ! state_read | jq "$@" "$filter" > "$tmp" 2>/dev/null; then
    state_cleanup_tmp
    die "state update failed — .progress.json untouched"
  fi
  if ! jq -e '.version == 1 and (.labs | type == "object") and (.events | type == "array")' "$tmp" >/dev/null 2>&1; then
    state_cleanup_tmp
    die "state update produced an invalid document — .progress.json untouched"
  fi
  mv -f -- "$tmp" "$STATE_FILE"
  STATE_TMP=""
}

readonly _REC_DEFAULT='{status:null, skipped:false, attempts:0, hints_used:0, started_at:null, first_passed_at:null, last_attempt_at:null}'

state_lab_json() {
  local track="$1" id="$2"
  state_read | jq -c --arg t "$track" --arg i "$id" \
    ".labs[\$t + \"/\" + \$i] // $_REC_DEFAULT"
}

state_bulk_tsv() {
  local track="$1"
  state_read | jq -r --arg t "$track" '
    .labs | to_entries[]
    | select(.key | startswith($t + "/"))
    | (.key | split("/")) as $parts
    | [$parts[1], (.value.status // "null"), (.value.skipped | tostring)]
    | @tsv'
}

# state_record_start <track> <id> <skip_ids_json_array>
# One atomic write: permanently marks every id in skip_ids as skipped (⏭),
# then upserts <id> itself as a normal in_progress lab (never downgrades an
# already-passed lab).
state_record_start() {
  local track="$1" id="$2" skip_ids_json="$3" now
  now="$(now_utc)"
  state_apply "
    def defrec: $_REC_DEFAULT;
    def key(\$t; \$i): \$t + \"/\" + \$i;
    reduce (\$skip_ids[]) as \$sid (.;
      .labs[key(\$t; \$sid)] = ((.labs[key(\$t; \$sid)] // defrec) | .skipped = true)
    )
    | .labs[key(\$t; \$id)] = ((.labs[key(\$t; \$id)] // defrec)
        | .status = (if .status == \"passed\" then \"passed\" else \"in_progress\" end)
        | .started_at = (.started_at // \$now))
    | .updated_at = \$now
  " --arg t "$track" --arg id "$id" --arg now "$now" --argjson skip_ids "$skip_ids_json"
}

# state_record_check <track> <id> <pass:true|false> <recap_lines_json_array>
# One atomic write, at the very end of grading: bumps attempts always; on
# pass, marks status passed (sticky), stamps first_passed_at once, and
# appends a pass event carrying a snapshot of the recap lines.
state_record_check() {
  local track="$1" id="$2" pass="$3" recap_json="$4" now
  now="$(now_utc)"
  state_apply "
    def defrec: $_REC_DEFAULT;
    def key(\$t; \$i): \$t + \"/\" + \$i;
    .labs[key(\$t; \$id)] = ((.labs[key(\$t; \$id)] // defrec)
      | .attempts += 1
      | .last_attempt_at = \$now
      | .status = (if \$pass or .status == \"passed\" then \"passed\" else .status end)
      | .first_passed_at = (if \$pass and .first_passed_at == null then \$now else .first_passed_at end))
    | (if \$pass then
        .events += [{seq: ((.events | last // {seq:0}).seq + 1),
                      type: \"pass\", track: \$t, id: \$id, at: \$now, recap: \$recap}]
      else . end)
    | .updated_at = \$now
  " --arg t "$track" --arg id "$id" --arg now "$now" --argjson pass "$pass" --argjson recap "$recap_json"
}

# state_record_hint <track> <id> <total_hint_levels>
# <total_hint_levels> is the CALLER's count (lib/hints.sh reads hints.json
# itself) — never hardcoded here, so this file carries no independent
# opinion about how many hint levels a lab has to stay in sync with.
state_record_hint() {
  local track="$1" id="$2" total="$3" now
  now="$(now_utc)"
  state_apply "
    def defrec: $_REC_DEFAULT;
    def key(\$t; \$i): \$t + \"/\" + \$i;
    .labs[key(\$t; \$id)] = ((.labs[key(\$t; \$id)] // defrec)
      | .hints_used = ((.hints_used // 0) + 1 | if . > \$total then \$total else . end))
    | .updated_at = \$now
  " --arg t "$track" --arg id "$id" --arg now "$now" --argjson total "$total"
}

# Last pass event across all tracks, or empty if nothing has ever passed.
state_last_pass() {
  state_read | jq -c '.events | map(select(.type == "pass")) | last // empty'
}

# state_frontier <track> <order_json_array_of_ids>
# First id in track order that is neither passed nor skipped; empty if the
# whole track is complete.
state_frontier() {
  local track="$1" order_json="$2"
  state_read | jq -r --arg t "$track" --argjson order "$order_json" "
    . as \$st
    | \$order
    | map(select(
        (\$st.labs[\$t + \"/\" + .] // $_REC_DEFAULT) as \$r
        | (\$r.status != \"passed\") and (\$r.skipped != true)
      ))
    | first // empty"
}
