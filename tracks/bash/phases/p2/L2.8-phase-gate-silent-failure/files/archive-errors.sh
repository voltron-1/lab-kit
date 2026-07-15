#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# archive-errors.sh — extract the ERROR lines from a log and file them in archive/.
log="$1"
grep ERROR "$log" > errors.txt
cp errors.txt archiv/errors.txt 2>/dev/null
rm -f errors.txt
echo "archived: ERROR lines from $log are in archive/errors.txt"
exit 0
