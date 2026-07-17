#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# stage.sh — move every file listed in the manifest into the archive dir.
manifest=$1
archive=$2
for f in $(cat $manifest); do        # $(cat) splits on IFS: every word, not every line
  mv $f $archive                     # unquoted $f: a spaced name splits into two args
done
echo staged
