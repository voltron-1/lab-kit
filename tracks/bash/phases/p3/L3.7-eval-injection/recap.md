building a string from untrusted input and then re-parsing it as shell source turns any metacharacter in that input into real syntax — a semicolon starts a new, attacker-chosen command
the fix is almost never "quote it better" — it's to remove the re-parse: dispatch through a case/array allowlist so input stays data and is never read as code
ShellCheck won't block this construct for you; it's the one place in this phase where the reviewer, not the linter, is the last line of defence
