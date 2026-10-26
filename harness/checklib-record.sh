# shellcheck shell=bash
# harness/checklib-record.sh — recording stand-in for harness/checklib.sh.
# tools/build-site.sh points LAB_CHECKLIB at this file and runs each lab's
# check.sh once against a pristine workspace. Instead of grading, every
# assert_* helper appends one JSON line to $LAB_RECORD_OUT describing the
# assertion, so the browser grader can replay the same checks. Same function
# names and argument order as harness/checklib.sh; anything the site cannot
# replay is a no-op returning 0. Never sourced by the real kit.

: "${LAB_WORKSPACE:?checklib-record: LAB_WORKSPACE must be set}"
: "${LAB_RECORD_OUT:?checklib-record: LAB_RECORD_OUT must be set}"

# _rec --arg key value ... — appends {key: value, ...} as one JSON line.
_rec() {
  # shellcheck disable=SC2016
  jq -nc '$ARGS.named' "$@" >> "$LAB_RECORD_OUT"
}

harness_err() {
  printf '!! harness error: %s\n' "$1" >&2
  exit 70
}

require_in_workspace() { return 0; }

ws_rel() {
  printf '%s\n' "${1#"$LAB_WORKSPACE"/}"
}

pass_msg() { return 0; }
fail() { return 0; }

assert_file_exists() {
  _rec --arg fn exists --arg path "$1" --arg hint "${2:-}"
}

assert_file_missing() { return 0; }
assert_dir_exists() { return 0; }

assert_file_contains() {
  _rec --arg fn contains --arg path "$1" --arg arg "$2" --arg hint "${3:-}"
}

assert_file_contains_i() {
  _rec --arg fn contains_i --arg path "$1" --arg arg "$2" --arg hint "${3:-}"
}

assert_file_contains_fixed() {
  _rec --arg fn contains_fixed --arg path "$1" --arg arg "$2" --arg hint "${3:-}"
}

assert_file_unmodified() { return 0; }

assert_file_not_contains() {
  _rec --arg fn not_contains --arg path "$1" --arg arg "$2" --arg hint "${3:-}"
}

# assert_cmd_ok "desc" "hint" -- cmd args...  (recorded, never executed)
assert_cmd_ok() {
  local desc="$1" hint="$2"
  shift 2
  [[ "${1:-}" == "--" ]] && shift
  _rec --arg fn cmd_ok --arg desc "$desc" --arg hint "$hint" --arg cmd "$*"
}

assert_cmd_fails() { return 0; }
assert_output_contains() { return 0; }
make_decoy_tree() { return 0; }
_decoy_matches_manifest() { return 0; }
decoy_intact() { return 0; }
decoy_changed() { return 0; }

ck_summary() {
  exit 0
}
