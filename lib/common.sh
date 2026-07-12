# shellcheck shell=bash
# lib/common.sh — globals, error helpers, dependency check, color init

: "${LAB_ROOT:?common.sh: LAB_ROOT must be set before sourcing}"

readonly TRACKS_DIR="$LAB_ROOT/tracks"
readonly WORKSPACE_DIR="$LAB_ROOT/workspace"
readonly STATE_FILE="$LAB_ROOT/.progress.json"
readonly CHECKLIB="$LAB_ROOT/harness/checklib.sh"
readonly LAB_KIT_VERSION="0.1.0"

if [[ -t 1 && -z "${NO_COLOR:-}" && "${LAB_COLOR:-1}" != "0" ]]; then
  C_BOLD=$'\033[1m'; C_GRN=$'\033[32m'; C_RED=$'\033[31m'
  C_YLW=$'\033[33m'; C_CYN=$'\033[36m'; C_DIM=$'\033[2m'; C_RST=$'\033[0m'
else
  C_BOLD=""; C_GRN=""; C_RED=""; C_YLW=""; C_CYN=""; C_DIM=""; C_RST=""
fi
readonly C_BOLD C_GRN C_RED C_YLW C_CYN C_DIM C_RST

warn() {
  printf 'lab: %s\n' "$*" >&2
}

info() {
  printf '%s\n' "$*"
}

# Usage or state errors — exit 2 (the machine-readable "not a graded failure" code).
die() {
  printf 'lab: %s\n' "$*" >&2
  exit 2
}

require_deps() {
  command -v jq >/dev/null 2>&1 || die "jq is required — sudo apt-get install -y jq"
}
