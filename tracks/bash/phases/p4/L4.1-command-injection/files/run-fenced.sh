#!/usr/bin/env bash
# run-fenced.sh <script> [args…] — source the fence, then source the target
# script in this SAME shell so a runaway destructive command cannot escape
# the lab workspace. Sourcing (not exec'ing) the target keeps it in the
# process whose rm() the fence just shadowed; keeping 'source fence.sh' out
# of the teaching sample itself lets the flawed script read authentically.
set -uo pipefail
: "${LAB_WORKSPACE:?run-fenced.sh: LAB_WORKSPACE must be set}"
source ./fence.sh
target=$1
shift
# shellcheck source=/dev/null
source "$target" "$@"
