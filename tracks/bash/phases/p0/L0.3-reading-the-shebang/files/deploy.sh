#!/bin/sh
# TEACHING SAMPLE — intentionally flawed
target="$1"
if [[ -z "$target" ]]; then
  target="prod"
fi
printf 'deploying to %s\n' "${target^^}"
