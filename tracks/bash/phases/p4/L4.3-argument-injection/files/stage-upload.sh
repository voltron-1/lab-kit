#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# stage-upload.sh — move an uploaded file (named by the client) into staging.
f=$1                                          # UNTRUSTED filename from an upload form
mv "$f" staging/                              # no --: an attacker-chosen "-t..." is parsed as an mv OPTION
