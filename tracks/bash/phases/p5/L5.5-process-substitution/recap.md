Process substitution <(cmd) makes a command's output look like a filename to whatever reads it — the classic use is diff <(cmd1) <(cmd2), comparing two live outputs with no temp files.
A here-string (<<< "$var") is the shortest way to feed one already-in-memory value to a command's stdin — no echo | pipe, no temp file.
A heredoc (<<EOF … EOF) is multi-line stdin written inline; it expands $variables and $(command) like double quotes, unless the opening delimiter is quoted (<<'EOF'), which makes it fully literal.
