# shellcheck shell=bash
# fence.sh — teaching fence. Source before running a footgun so a runaway
# destructive command cannot escape the lab workspace. NOT a security sandbox;
# a teaching guardrail that logs the would-be catastrophe instead of doing it.
# rm() is redefined FAIL-CLOSED: if ANY target canonicalizes outside
# $LAB_WORKSPACE (or fails to canonicalize), the WHOLE call is refused and
# recorded in fence.log; only fully-in-workspace calls reach the real rm.
#
# L4.1-specific: this lab's injection travels through `bash -c "…"`, a real
# exec into a NEW bash process — unlike p3's fence targets (eval, or a
# directly-sourced script), which stayed in the same process. A plain shell
# function is invisible to an exec'd child, so LAB_WORKSPACE/LAB_FENCE_LOG
# are explicitly exported and rm is exported as a function (`export -f`) so
# the shadow still applies inside that nested bash -c. Verified: without
# this, the injected rm would run for real, uncaught.
#
# `realpath` is called with the `command` prefix for the same fail-closed
# reason `rm` itself is invoked with `command rm` below: an injected payload
# that runs in-process (this is a teaching fence, not a sandbox — anything
# the learner's own injected command defines is visible here too) could
# otherwise shadow `realpath` with a function that lies about a target being
# in-workspace. `command` skips function/alias resolution for both calls.
: "${LAB_WORKSPACE:?fence.sh: LAB_WORKSPACE must be set}"
: "${LAB_FENCE_LOG:=fence.log}"
export LAB_WORKSPACE LAB_FENCE_LOG

rm() {
  local arg canon blocked=0
  for arg in "$@"; do
    case "$arg" in
      -*) continue ;;                       # an option, not a path
    esac
    canon="$(command realpath -m -- "$arg" 2>/dev/null)" || canon=""
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
export -f rm
