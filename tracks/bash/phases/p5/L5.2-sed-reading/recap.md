sed reads one line at a time and applies each -e expression in order — think of it as a small pipeline of substitutions, not one big rule.
-E turns on extended regex (unescaped ( ) { } + ?), and a trailing /g on s/// applies the substitution to every match on the line, not just the first.
Capture groups — ( ) in the pattern, \1 \2 … in the replacement — are how sed reorders or relabels fields instead of only deleting or masking them.
