$(( n )) and (( n )) evaluate their operand as an arithmetic EXPRESSION, and an array subscript inside it — a[$(cmd)] — command-substitutes: the cmd runs
so untrusted data in arithmetic is command injection; the fix is to validate it's all digits BEFORE the (( )), and reject anything else
ShellCheck has no warning for this — it's one of the blind spots that make "shellcheck-clean" necessary but not sufficient
