everything is text; the shell transforms it in a fixed order; quote unless you can say why not
tokenize → expand ($var, $(cmd)) → word-split unquoted results → glob — only then does anything run
no-match globs stay literal, quotes stop the machinery, and $? holds the LAST command's exit (0 = success)
