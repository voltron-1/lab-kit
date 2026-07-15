## BRIEF
`trap <handler> EXIT` registers a command that runs on EVERY way out of
the script: the happy last line, a `set -e` death (L2.2), an explicit
`exit`, or Ctrl-C. That guarantee is why real installers are built
around it — staging files, temp dirs, and half-written configs get
removed even when the install dies mid-flight. Cleanup written at the
bottom of a script is a promise; a trap is a guarantee.
`staged-install.sh` stages a payload, verifies it, installs it — and
its trap keeps the workspace debris-free on both the good and the bad
path.

## GUIDED STEPS

1. Decode: find the handler, the registration line, and the three
   risky commands below it.

       cat staged-install.sh

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   # staged-install.sh — stage, verify, install; ALWAYS clean the staging file on the way out.
   cleanup() {
     rm -f payload.staging
     echo "cleanup: staging file removed" >&2
   }
   trap cleanup EXIT
   src="$1"
   cp "$src" payload.staging
   echo "staged: $src"
   grep -q "version:" payload.staging
   echo "verified: version line present"
   mv payload.staging payload.installed
   echo "installed: payload.installed"
   ```

2. Spot the difference between the two payloads:

       cat payload.txt payload-bad.txt

   `payload-bad.txt` is missing the `version:` line.

3. Good-path capture:

       bash staged-install.sh payload.txt > good-run.txt 2>&1; echo "exit=$?" >> good-run.txt
       cat good-run.txt
       ls

   expect (`good-run.txt`):

       staged: payload.txt
       verified: version line present
       installed: payload.installed
       cleanup: staging file removed
       exit=0

   The cleanup line prints LAST — the trap fires after the script's
   final statement, on the way out. `payload.installed` now exists;
   `payload.staging` does not (`mv` moved it; the trap's `rm -f` of
   the now-absent name is a no-op — that's what `-f` is for).

4. Bad-path capture:

       bash staged-install.sh payload-bad.txt > bad-run.txt 2>&1; echo "exit=$?" >> bad-run.txt
       cat bad-run.txt
       ls

   expect (`bad-run.txt`):

       staged: payload-bad.txt
       cleanup: staging file removed
       exit=1

   In order: `verified:` never printed — `grep -q "version:"` found
   no match and exited 1; `set -e` (L2.2) killed the script right
   there; the trap STILL ran (that's the guarantee) and removed
   `payload.staging` — no half-staged debris; and the exit code is
   still grep's **1** — the trap ran but did NOT overwrite the
   verdict. Had the trap been registered AFTER the `cp`, a death in
   between would have skipped cleanup — register the trap BEFORE the
   risky commands.

5. Write `answers.txt` — one `key=value` per line, no spaces around
   `=`:

   q1 (choice). cleanup ran on the bad path because…
   a) rm is special
   b) trap … EXIT fires on EVERY way out — success, a set -e death, or
      an interrupt
   c) grep called it

   q2 (value). The bad run's exit code (from bad-run.txt's exit= line)?

   q3 (choice). After the bad run, payload.staging is…
   a) still there, half-staged
   b) gone — the trap removed it on the way out; no debris for the
      next run to trip on
   c) renamed to payload.installed

   q4 (choice). Why register the trap BEFORE the cp/grep/mv?
   a) style
   b) a death after staging but before registration would exit with
      NO cleanup — the guarantee only covers exits after the trap
      exists
   c) traps must be first or bash rejects them

6. `lab check bash L2.7`
