if branches on an exit code, nothing else — [ is a command, [[ is bash syntax, (( )) is arithmetic
[ ] inherits every expansion bug: empties vanish ([ -n ] passes!), spaces split; [[ ]] never splits its operands
trust [[ ]] for strings/files and (( )) for numbers — where nonzero is TRUE and flips to exit 0
