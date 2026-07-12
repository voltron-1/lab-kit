# shellcheck shell=bash
# harness/checklib.sh — sourced by every lab's check.sh (never executed
# directly). Collect-all grader model: assert_* helpers never abort on
# their own; they record a numbered pass/fail line and keep going, so a
# learner sees every problem in one run instead of one-at-a-time. Call
# ck_summary as the LAST line of check.sh — it is the only function here
# allowed to exit nonzero (exit 1 = graded failure).
#
# Fence-strength note (read before trusting this as a security boundary):
# every helper below canonicalizes paths with `realpath -m` and refuses
# anything outside $LAB_WORKSPACE — this catches accidental relative-path
# bugs and `../` traversal in OUR OWN lab content. It cannot stop a
# check.sh that hardcodes an absolute path and calls coreutils directly,
# bypassing these helpers entirely — there is no OS sandbox here (no
# containers/chroot/bwrap). That residual risk is covered by
# tools/lint-labs.sh (bans absolute-path literals and dangerous tokens in
# every committed check.sh), not by this file. Every check.sh in this repo
# is first-party, shellcheck-clean, and lint-checked — treat this as a
# guardrail against authoring mistakes, not a sandbox against a hostile
# script. Destructive teaching labs must ALWAYS target make_decoy_tree
# output, never a real path.

: "${LAB_WORKSPACE:?checklib: LAB_WORKSPACE must be set — run this via 'lab check'}"

if [[ -t 1 ]]; then
  _CK_GRN=$'\033[32m'; _CK_RED=$'\033[31m'; _CK_RST=$'\033[0m'
else
  _CK_GRN=""; _CK_RED=""; _CK_RST=""
fi
MARK_OK="${_CK_GRN}✓${_CK_RST}"
MARK_BAD="${_CK_RED}✗${_CK_RST}"

CK_N=0
CK_PASS=0
CK_FAIL=0
REQ_PATH=""

harness_err() {
  printf '!! harness error: %s\n' "$1" >&2
  exit 70
}

# require_in_workspace <path> — sets $REQ_PATH to the canonicalized path
# (realpath -m: resolves symlinks in existing components, allows
# not-yet-created write targets) and hard-exits via harness_err if it
# escapes $LAB_WORKSPACE. Deliberately does NOT return the path via stdout
# — a caller capturing it with $(...) would run this function in a
# subshell, where harness_err's exit would only kill that subshell instead
# of the whole check.sh process.
require_in_workspace() {
  local raw="$1" canon
  canon="$(realpath -m -- "$raw" 2>/dev/null)" || harness_err "cannot resolve path: $raw"
  case "$canon" in
    "$LAB_WORKSPACE"|"$LAB_WORKSPACE"/*) : ;;
    *) harness_err "path escapes workspace fence: $raw -> $canon" ;;
  esac
  REQ_PATH="$canon"
}

ws_rel() {
  printf '%s\n' "${1#"$LAB_WORKSPACE"/}"
}

pass_msg() {
  CK_N=$((CK_N + 1))
  CK_PASS=$((CK_PASS + 1))
  printf '  %s  [%d] %s\n' "$MARK_OK" "$CK_N" "$1"
  return 0
}

fail() {
  local msg="$1" hint="${2:-}"
  CK_N=$((CK_N + 1))
  CK_FAIL=$((CK_FAIL + 1))
  printf '  %s  [%d] %s\n' "$MARK_BAD" "$CK_N" "$msg"
  [[ -n "$hint" ]] && printf '           look at: %s\n' "$hint"
  return 0
}

assert_file_exists() {
  local path="$1" hint="${2:-}"
  require_in_workspace "$path"
  if [[ -e "$REQ_PATH" ]]; then
    pass_msg "$(ws_rel "$REQ_PATH") exists"
  else
    fail "$(ws_rel "$REQ_PATH") missing" "$hint"
  fi
}

assert_file_missing() {
  local path="$1" hint="${2:-}"
  require_in_workspace "$path"
  if [[ ! -e "$REQ_PATH" ]]; then
    pass_msg "$(ws_rel "$REQ_PATH") correctly absent"
  else
    fail "$(ws_rel "$REQ_PATH") should not exist" "$hint"
  fi
}

assert_dir_exists() {
  local path="$1" hint="${2:-}"
  require_in_workspace "$path"
  if [[ -d "$REQ_PATH" ]]; then
    pass_msg "$(ws_rel "$REQ_PATH") is a directory"
  else
    fail "$(ws_rel "$REQ_PATH") is not a directory" "$hint"
  fi
}

assert_file_contains() {
  local path="$1" pattern="$2" hint="${3:-}"
  require_in_workspace "$path"
  if [[ ! -f "$REQ_PATH" ]]; then
    fail "$(ws_rel "$REQ_PATH") missing" "$hint"
    return 0
  fi
  if grep -Eq -- "$pattern" "$REQ_PATH"; then
    pass_msg "$(ws_rel "$REQ_PATH") matches: $pattern"
  else
    fail "$(ws_rel "$REQ_PATH") does not match: $pattern" "$hint"
  fi
}

assert_file_contains_fixed() {
  local path="$1" literal="$2" hint="${3:-}"
  require_in_workspace "$path"
  if [[ ! -f "$REQ_PATH" ]]; then
    fail "$(ws_rel "$REQ_PATH") missing" "$hint"
    return 0
  fi
  if grep -Fq -- "$literal" "$REQ_PATH"; then
    pass_msg "$(ws_rel "$REQ_PATH") contains: $literal"
  else
    fail "$(ws_rel "$REQ_PATH") does not contain: $literal" "$hint"
  fi
}

assert_file_not_contains() {
  local path="$1" pattern="$2" hint="${3:-}"
  require_in_workspace "$path"
  if [[ ! -f "$REQ_PATH" ]]; then
    pass_msg "$(ws_rel "$REQ_PATH") absent (vacuously does not contain: $pattern)"
    return 0
  fi
  if grep -Eq -- "$pattern" "$REQ_PATH"; then
    fail "$(ws_rel "$REQ_PATH") unexpectedly matches: $pattern" "$hint"
  else
    pass_msg "$(ws_rel "$REQ_PATH") does not match: $pattern"
  fi
}

# assert_cmd_ok "desc" "hint" -- cmd args...
assert_cmd_ok() {
  local desc="$1" hint="$2"
  shift 2
  [[ "${1:-}" == "--" ]] && shift
  local out rc=0
  out="$("$@" 2>&1)" || rc=$?
  if [[ "$rc" -eq 0 ]]; then
    pass_msg "$desc"
  else
    fail "$desc — command exited $rc: $*" "$hint"
    if [[ -n "$out" ]]; then
      printf '%s\n' "$out" | tail -n 5 | sed 's/^/           | /' || true
    fi
  fi
  return 0
}

# assert_cmd_fails "desc" "hint" -- cmd args...
assert_cmd_fails() {
  local desc="$1" hint="$2"
  shift 2
  [[ "${1:-}" == "--" ]] && shift
  local rc=0
  "$@" >/dev/null 2>&1 || rc=$?
  if [[ "$rc" -ne 0 ]]; then
    pass_msg "$desc"
  else
    fail "$desc — command unexpectedly succeeded" "$hint"
  fi
  return 0
}

# assert_output_contains "desc" "pattern" "hint" -- cmd args...
assert_output_contains() {
  local desc="$1" pattern="$2" hint="$3"
  shift 3
  [[ "${1:-}" == "--" ]] && shift
  local out
  out="$("$@" 2>&1)" || true
  if printf '%s' "$out" | grep -Eq -- "$pattern"; then
    pass_msg "$desc"
  else
    fail "$desc — output did not match: $pattern" "$hint"
    if [[ -n "$out" ]]; then
      printf '%s\n' "$out" | head -n 10 | sed 's/^/           | /' || true
    fi
  fi
  return 0
}

# --- decoy trees: the blessed target for future destructive-command labs ---
# Ships now (even though only the demo lab exists) so the bash track's
# rm -rf / IFS-attack / filename-attack labs inherit one pattern instead of
# reinventing it. A footgun must always run against make_decoy_tree output.

make_decoy_tree() {
  local name="$1" root manifest
  require_in_workspace "decoy-$name"
  root="$REQ_PATH"
  manifest="$root.manifest"
  mkdir -p -- "$root/subdir"
  printf 'alpha\n' > "$root/alpha.txt"
  printf 'beta\n' > "$root/subdir/beta.txt"
  : > "$root/-rf"
  : > "$root/--"
  ( cd -- "$root" && find . -type f -print0 | sort -z | xargs -0 sha256sum ) > "$manifest"
  return 0
}

_decoy_matches_manifest() {
  local name="$1" root manifest
  require_in_workspace "decoy-$name"
  root="$REQ_PATH"
  manifest="$root.manifest"
  [[ -f "$manifest" ]] || return 1
  ( cd -- "$root" 2>/dev/null && sha256sum -c --quiet "$manifest" ) >/dev/null 2>&1
}

decoy_intact() {
  local name="$1"
  if _decoy_matches_manifest "$name"; then
    pass_msg "decoy-$name is untouched"
  else
    fail "decoy-$name changed or its manifest is missing" ""
  fi
}

decoy_changed() {
  local name="$1"
  if _decoy_matches_manifest "$name"; then
    fail "decoy-$name unexpectedly unchanged — the footgun should have detonated" ""
  else
    pass_msg "decoy-$name changed as expected"
  fi
}

# Call as the LAST line of every check.sh. Prints the tally and exits 0
# (all passed) or 1 (graded failure) — the only nonzero exit path here.
ck_summary() {
  printf 'checks %d/%d\n' "$CK_PASS" "$CK_N"
  if [[ "$CK_FAIL" -gt 0 ]]; then
    exit 1
  fi
  exit 0
}
