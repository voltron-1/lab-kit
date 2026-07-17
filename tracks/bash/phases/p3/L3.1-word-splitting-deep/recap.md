$(cat file) and $var without quotes are word-split on IFS — a filename with a space becomes two arguments and the wrong thing moves
the fixes are muscle memory: quote every expansion ("$f"), read lines with while IFS= read -r (L2.3), and end options with --
the shell will not warn you — you quote by reflex, and ShellCheck's SC2086 is the backstop, not the other way round
