a script that keeps going after a failure will happily narrate success — exit 0 can lie (L1.6: it's just the LAST verdict)
2>/dev/null plus a trailing echo/exit 0 is how failure hides; set -euo pipefail (or || exit) is how it stops
shellcheck passed the liar with zero findings — the linter guards syntax; honesty is the reader's job
