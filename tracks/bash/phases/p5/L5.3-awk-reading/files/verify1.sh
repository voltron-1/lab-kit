#!/usr/bin/env bash
# check.sh helper, not a guided-step reference sample: reruns command 1 for
# real so check.sh can cross-verify predictions.txt without invoking awk via
# the lint-banned 'bash -c' (tools/lint-labs.sh:83).
set -euo pipefail
awk -F',' 'NR>1{count[$2]++} END{for (s in count) print s, count[s]}' alerts.csv | sort
