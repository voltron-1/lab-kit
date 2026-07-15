#!/usr/bin/env bash
set -euo pipefail
# staged-install.sh — stage, verify, install; ALWAYS clean the staging file on the way out.
cleanup() {
  rm -f payload.staging
  echo "cleanup: staging file removed" >&2
}
trap cleanup EXIT
src="$1"
cp "$src" payload.staging
echo "staged: $src"
grep -q "version:" payload.staging
echo "verified: version line present"
mv payload.staging payload.installed
echo "installed: payload.installed"
