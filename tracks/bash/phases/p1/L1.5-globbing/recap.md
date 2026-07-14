globs match names that exist in the cwd — expansion runs last, and only on unquoted words
no match? bash keeps the pattern as a literal word (nullglob would drop it — off by default)
* never recurses and skips dotfiles; double-quoting the word switches globbing off entirely
