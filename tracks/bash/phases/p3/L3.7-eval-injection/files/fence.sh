# shellcheck shell=bash
# fence.sh — teaching fence. Source before running a footgun so a runaway
# destructive command cannot escape the lab workspace. NOT a security sandbox;
# a teaching guardrail that logs the would-be catastrophe instead of doing it.
# rm() is redefined FAIL-CLOSED: if ANY target canonicalizes outside
# $LAB_WORKSPACE (or fails to canonicalize), the WHOLE call is refused and
# recorded in fence.log; only fully-in-workspace calls reach the real rm.
: "${LAB_WORKSPACE:?fence.sh: LAB_WORKSPACE must be set}"
: "${LAB_FENCE_LOG:=fence.log}"

rm() {
  local arg canon blocked=0
  for arg in "$@"; do
    case "$arg" in
      -*) continue ;;                       # an option, not a path
    esac
    canon="$(realpath -m -- "$arg" 2>/dev/null)" || canon=""
    case "$canon" in
      "$LAB_WORKSPACE" | "$LAB_WORKSPACE"/*) : ;;   # inside the fence — allowed
      *) blocked=1 ;;                                # escapes (incl. "" and /) — refuse
    esac
  done
  if (( blocked )); then
    printf 'FENCE-BLOCKED: rm %s\n' "$*" >> "$LAB_FENCE_LOG"
    return 0                                # mimic the silent "success" of the real disaster
  fi
  command rm "$@"
}
