&& runs the right side only after success, || only after failure — both are $? wired into flow
a && b || c is NOT if/else: c fires on b's failure too — || pairs with the most recent verdict
cmd || exit 1 is the guard idiom (in scripts! at a prompt it closes your shell) — cd almost always wants it
