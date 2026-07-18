#!/bin/sh
# TEACHING SAMPLE — intentionally flawed / obfuscated (malware-style). Do NOT run.
# dropper.sh — shows the SHAPE of the obfuscation. Read-only reference.
P="$(cat payload.b64)"
eval "$(printf '%s' "$P" | base64 -d)"
