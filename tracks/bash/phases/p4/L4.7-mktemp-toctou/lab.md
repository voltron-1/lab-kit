## BRIEF
`cache.sh` caches a value to a temp file, reads it back, and cleans up.
It has three flaws stacked in three lines: the temp *name* is
predictable (built from the PID, which anyone can see), it's created in
a directory every user can write to, and there's a **check-then-use
gap** — the script checks whether the path exists, then, separately,
writes to it. Between those two steps, an attacker who guessed the name
in advance can have already put something else there — a symlink to a
file they don't own — and the script will write through it. That gap
is **CWE-367, time-of-check to time-of-use (TOCTOU)**. On top of that,
cleanup only happens on the last line — anything that exits early
leaves the temp file behind forever. This is a **TAME** lab: edit
`cache.sh` in place.

## GUIDED STEPS

1. Read it:

       cat cache.sh

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   process() { wc -c < "$1"; }
   tmp=/tmp/acme-cache.$$
   if [ ! -e "$tmp" ]; then
     echo "$DATA" > "$tmp"
   fi
   process "$tmp"
   rm -f "$tmp"
   ```

2. Confirm ShellCheck's take:

       shellcheck cache.sh

   captured output: *(nothing — clean, no warnings)*

   Blind spot again — ShellCheck has no check for "this filename is
   guessable" or "there's a gap between checking and using this path."

3. See the predictability for yourself — the temp path is built from
   nothing but the shell's own PID, which is visible to anyone on the
   machine (`ps`, `/proc`, a race started right after this one):

       echo "would-be temp path for THIS shell: /tmp/acme-cache.$$"

   captured output (your PID will differ):

       would-be temp path for THIS shell: /tmp/acme-cache.467361

   An attacker doesn't need to see this script run — they only need to
   guess (or watch for) the next PID and pre-place something at that
   exact path before the script gets there.

4. Confirm there's no cleanup trap at all:

       grep -c '^trap' cache.sh

   captured output:

       0

   Cleanup (`rm -f "$tmp"`, the last line) only runs if the script
   reaches its last line. Any early exit — an error, a signal, a `set -e`
   death added later — skips it, and the temp file leaks forever.

5. Run it once to see the normal case work:

       DATA=hello bash cache.sh

   captured output:

       6

6. Name the flaw. Write `answers.txt`:

       flaw=toctou
       cwe=CWE-367

7. Edit `cache.sh` in place — three changes, one line each: replace the
   predictable name with `mktemp` (atomically creates an unpredictable
   path, closing the check-then-use gap entirely — there's no window
   left to race, because nothing is ever checked before it's created),
   add a cleanup `trap` on `EXIT` (fires on every way out, not just the
   last line — same lesson as L2.7), and keep everything else identical:

   ```bash
   #!/usr/bin/env bash
   process() { wc -c < "$1"; }
   set -euo pipefail
   tmp=$(mktemp)
   trap 'rm -f -- "$tmp"' EXIT
   echo "$DATA" > "$tmp"
   process "$tmp"
   ```

       shellcheck cache.sh

   Expect no warnings.

8. Prove the trap actually cleans up — even when the process is killed,
   not just when it exits normally. Point `TMPDIR` at a throwaway
   directory first so nothing real is ever touched:

       mkdir -p .tmp-demo
       TMPDIR="$PWD/.tmp-demo" bash -c 'tmp=$(mktemp); trap '"'"'rm -f -- "$tmp"'"'"' EXIT; sleep 5' &
       pid=$!; sleep 0.3; kill -INT "$pid"; wait "$pid" 2>/dev/null
       ls .tmp-demo

   captured output: *(nothing — the directory is empty)*

   The `EXIT` trap fires on every way out of a script, including a
   received signal that kills it — not just a clean `exit 0`. That's what
   closes the "leaks on early exit" half of the original bug.

9. Prove ordinary use still works, same output as step 5:

       rm -rf .tmp-demo && mkdir -p .tmp-demo
       TMPDIR="$PWD/.tmp-demo" DATA=hello bash cache.sh
       ls .tmp-demo

   captured output:

       6

   *(second line — the `ls` — prints nothing: the trap already removed the
   temp file.)*

10. `lab check bash L4.7`
