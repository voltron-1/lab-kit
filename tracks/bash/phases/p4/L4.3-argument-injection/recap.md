Argument injection (CWE-88): untrusted input starting with - is read as an OPTION to the program, silently changing what it does — mv -t redirects the whole operation, tar --checkpoint-action=exec and rsync -e reach code execution
the guard is --: everything after it is a path, never an option — mv -- "$f" dir/, grep -- "$pat" file; quoting alone does not stop option parsing
this bug is quiet, not loud — a redirected mv exits 0 and prints nothing wrong; the damage is files ending up somewhere else, not a crash you'd notice
