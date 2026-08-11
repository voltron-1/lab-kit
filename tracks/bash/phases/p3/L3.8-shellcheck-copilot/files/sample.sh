#!/bin/sh
# TEACHING SAMPLE — intentionally flawed
# sample.sh — a grab-bag of ShellCheck triggers to read and classify.
dir=$1
rm -rf "$dir/"                 # SC2115  (security-critical: empty $dir -> rm -rf /)
cp $dir/*.log /backup          # SC2086  (security-critical: word-split/glob on untrusted path)
rm *                           # SC2035  (security-critical: a -rf filename becomes a flag)
files=`ls`                     # SC2006 (cosmetic: backticks) + SC2010/SC2012 (ls parsing, style)
echo "found: $files"           # SC2086 on $files (context-dependent)
if [ $# -gt 0 -a -n "$1" ]; then :; fi   # SC2166 (style: -a is legacy) + SC2086 on $#
unused=42                      # SC2034 (cosmetic: unused variable)
. ./site-config.sh              # SC1091 (informational: source target is missing/dynamic)
