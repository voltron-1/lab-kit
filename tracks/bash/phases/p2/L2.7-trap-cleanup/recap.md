trap <handler> EXIT runs the handler on EVERY way out — the happy end, a set -e death, or Ctrl-C
register the trap BEFORE the risky commands: bottom-of-script cleanup is a promise, a trap is a guarantee
the trap doesn't overwrite the verdict — the failed run still reported grep's 1 to whoever called it
