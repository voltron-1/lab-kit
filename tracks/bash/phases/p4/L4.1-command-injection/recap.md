Command injection (CWE-78) is data reaching the command position: the instant untrusted input is spliced unquoted into a string a shell re-parses (bash -c, eval, backticks), its metacharacters become your syntax
the fix is structural, not more quoting — pass the value as a separate quoted argument to the program (grep -- "$name"), so it can never be read as code
ShellCheck cannot see this class of bug — a clean shellcheck run means nothing about command-injection safety; you have to read the data flow yourself
