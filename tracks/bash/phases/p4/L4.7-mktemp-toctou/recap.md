predictable temp names in a shared directory are a symlink/TOCTOU trap — mktemp gives an unpredictable name created atomically, closing the race instead of just narrowing it
check-then-use is the race itself (CWE-367): don't test whether a path exists and then separately act on it — create it atomically and use the handle you got
pair mktemp with trap 'rm -f -- "$tmp"' EXIT (L2.7) so the temp file is removed on every way out — a signal, an error, or the happy path — not just the last line of the script
