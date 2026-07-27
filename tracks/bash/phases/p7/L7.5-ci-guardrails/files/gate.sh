#!/bin/bash
# gate.sh — the merge gate: lint everything under scripts/, fail on any finding.
set -euo pipefail
shellcheck -x -S style scripts/*.sh
shfmt -d scripts/
echo "gate: clean"
