one rule beats all others: never let untrusted input reach the command position — pass it as a quoted argument to a program, never as text a shell re-parses
layer the guards: allowlist-validate (case), quote ("$x"), end options (--), force literal where relevant (grep -F), and pin an absolute PATH
reject, don't sanitize: an allowlist of known-good characters is safer than trying to strip or escape known-bad ones, because it fails closed against attacks you didn't anticipate
