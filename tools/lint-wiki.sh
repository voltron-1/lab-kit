#!/usr/bin/env bash
# tools/lint-wiki.sh [wiki-dir] — check the wiki's lab references against tracks/.
# With no argument, shallow-clones this repo's wiki (origin URL + .wiki.git) into
# a temp dir. Needs python3 (stdlib only). Not part of lint-labs.sh on purpose:
# that would make every normal lint run depend on network access to a second repo.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd)"
command -v python3 > /dev/null 2>&1 || {
  echo "lint-wiki: python3 is required" >&2
  exit 2
}

wiki="${1:-}"
if [[ -z "$wiki" ]]; then
  origin="$(git -C "$ROOT" remote get-url origin)"
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "$tmp"' EXIT
  git clone --quiet --depth 1 "${origin%.git}.wiki.git" "$tmp/wiki" || {
    echo "lint-wiki: could not clone ${origin%.git}.wiki.git — pass a wiki checkout path instead" >&2
    exit 2
  }
  wiki="$tmp/wiki"
fi

python3 -I "$ROOT/tools/lint_wiki.py" "$wiki"
