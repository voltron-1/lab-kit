$(cmd) = run cmd, substitute its stdout, strip trailing newlines — then normal expansion rules resume
unquoted, the substituted text word-splits like any variable (L1.3 in a new mask); "$(...)" stays one word
read nested $() inside-out; only stdout is captured — stderr hits your terminal, $? carries the exit code
