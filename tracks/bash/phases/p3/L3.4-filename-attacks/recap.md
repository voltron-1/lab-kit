the shell expands and SORTS a glob before the command sees it, so a file named -rf leads the argv and rm reads it as flags — flat delete goes recursive
two reflexes defuse it: rm -- * (end option parsing) and rm ./* (every name starts with a path, so no name can lead with -)
filenames (and their newlines and dashes) are attacker-controlled data — ShellCheck SC2035 flags exactly this
