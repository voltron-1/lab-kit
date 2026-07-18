obfuscation hides intent until runtime — base64 plus eval, hex escapes, renamed variables — and has no legitimate reason to appear in a script you're auditing
triage statically: decode to a FILE and read it, base64 -d blob > out.txt, never base64 -d blob | sh — the decode step must never touch a shell
pull the IOCs: hardcoded addresses, hidden dotfiles, background launches, and cron/rc persistence are the checklist every triage pass should run through
