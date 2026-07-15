#!/usr/bin/env bash
# gatekeeper.sh — admit or deny a request: strings via [[ ]], numbers via (( )).
user="${1:-}"
load="${2:-0}"
if [[ -z "$user" ]]; then
  echo "usage: bash gatekeeper.sh <user> <load>" >&2
  exit 2
fi
if [[ "$user" != "admin" ]]; then
  echo "deny: $user is not admin"
  exit 1
fi
if (( load >= 8 )); then
  echo "deny: load $load too high"
  exit 1
fi
echo "admit: $user (load $load)"
