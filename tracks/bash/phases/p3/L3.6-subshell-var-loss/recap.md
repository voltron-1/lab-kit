the right-hand side of a pipe runs in a SUBSHELL, so cmd | while read … any variable you set inside the loop is lost when it exits (count stays 0)
keep the loop in the current shell with process substitution: while read …; done < <(cmd) → the variable survives (count=3)
ShellCheck SC2030/SC2031 flag exactly this "modified in a subshell, change may be lost" — a warning worth reading, not muting
