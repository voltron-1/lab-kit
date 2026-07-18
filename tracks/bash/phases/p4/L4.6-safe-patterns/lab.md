## BRIEF
`safe-input.sh` is the answer key for the rest of this phase — correct,
defensive handling of an untrusted `name` argument, layering every fix
L4.1–L4.5 taught: an allowlist, quoting, an end-of-options guard, a
literal-match flag, and a pinned `PATH`. This is a **DECODE** lab: the
code is already right. Your job is to read it and name *why* each line
works, not to find or fix a bug. It's safe to run — do.

## GUIDED STEPS

1. Read it:

       cat safe-input.sh

   ```bash
   #!/usr/bin/env bash
   # REFERENCE SAMPLE — correct, defensive handling of untrusted input.
   set -euo pipefail
   PATH=/usr/bin:/bin
   name=${1:?usage: safe-input.sh <name>}
   case $name in
     *[!a-zA-Z0-9_-]* ) printf 'rejected: %s\n' "$name" >&2; exit 2 ;;
   esac
   grep -F -- "$name" users.txt
   ```

   Four defensive layers, one per line: an **absolute, pinned `PATH`**
   (line 4 — no attacker-writable directory can ever be searched, per
   L4.4); a **required-argument guard** (line 5 — `${1:?msg}` fails loudly
   instead of silently continuing with an empty `name`); an **allowlist**
   (line 7 — accept only letters, digits, `_`, and `-`; reject everything
   else outright, don't try to sanitize it); and `grep -F --
   "$name"` (line 9 — `-F` treats `$name` as a **literal string**, never a
   regex, `--` **ends option parsing** so a leading `-` can never be read
   as a flag (per L4.3), and `"$name"` is a single **quoted argument** —
   data, never text a shell re-parses (per L4.1/L4.2/L4.5).

2. Confirm ShellCheck's take:

       shellcheck safe-input.sh

   captured output: *(nothing — clean, no warnings)*

   Correct code is ShellCheck-clean too — but remember from every AUDIT
   lab this phase: clean ShellCheck output never proved safety on its
   own. It's the *reasoning* above that does.

3. Run it normally:

       bash safe-input.sh alice

   captured output:

       alice:admin

4. Try the same injection-shaped name from L4.1:

       bash safe-input.sh 'x; rm -rf ~ #'; echo "rc=$?"

   captured output:

       rejected: x; rm -rf ~ #
       rc=2

   The allowlist refuses it outright — line 9's defenses never even run.
   Compare with L4.1's `lookup.sh`: same payload, opposite outcome,
   because nothing here ever hands `$name` to a shell to re-parse.

5. Try a name the allowlist accepts but that isn't in `users.txt`:

       bash safe-input.sh dave; echo "rc=$?"

   captured output:

       rc=1

   No match, no crash, no leak of anything about `grep`'s internals —
   `grep -F` just reports "not found" the same way it would for any other
   literal string.

6. Answer the comprehension check. Write `answers.txt`:

       validation=allowlist
       grep_f=literal
       dashdash=options
       path=absolute
       safest=arguments

7. `lab check bash L4.6`
