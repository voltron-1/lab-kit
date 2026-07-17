#!/bin/sh
# TEACHING SAMPLE — intentionally flawed
# deploy.sh — clean the release dir, stage listed files, run a named build step.
run_build() { echo "building..."; }
run_test() { echo "testing..."; }

REL=$1
rm -rf "$REL/"                          # (A) L3.2: empty REL -> rm -rf /
for f in $(cat manifest.txt); do        # (B) L3.1/L3.3: $(cat) word-splits; spaced names break
  cp $f "$REL"                          # (C) L3.1: unquoted $f
done
rm *.tmp                                 # (D) L3.4: a -rf.tmp name could flag rm
scale=$2
workers=$(( scale * 2 ))                 # (E) L3.5: untrusted scale -> arithmetic injection
eval "run_$3"                            # (F) L3.7: eval on an untrusted action name
echo deployed
