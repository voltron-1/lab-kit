awk sees the world as records (lines) split into fields ($1, $2, … and $0 for the whole line) — -F sets what character splits them.
pattern { action } pairs run the action on every line matching the pattern; a bare condition with no action defaults to "print the line."
BEGIN {} runs once before any input, END {} runs once after all input — everything else runs once per line, which is why a running total lives in an array touched every line and printed only in END.
