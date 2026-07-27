#!/bin/bash
# TEACHING SAMPLE — deliberately flawed. Never run this.
# It exists to be read and reviewed, not executed.
# Generates a quick failed-login report from your auth logs!

LOG_DIR=$1

for f in $(ls $LOG_DIR); do
    count=$(cat $LOG_DIR/$f | grep "FAILED LOGIN" | wc -l)
    echo "$f: $count failures"
done | sort -t: -k2 -rn
