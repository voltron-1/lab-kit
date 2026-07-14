the shebang picks the interpreter only when the file is exec'd — bash script.sh ignores it
on Debian/Ubuntu /bin/sh is dash: strict POSIX, no [[ ]], no ${var^^} — bashisms detonate at run time
shellcheck -s sh asks "is this POSIX?" — the -s flag outranks both .shellcheckrc and the shebang
