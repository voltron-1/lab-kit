## BRIEF
One real deploy script, six footguns from this whole phase at once. Find
every one, then harden it *in place* — same file, edited, not rewritten
from scratch. Because line (A) can turn into `rm -rf /`, you demonstrate
the flawed script's catastrophe through the same shadowed-`rm` fence as
L3.2/L3.7 **before** you touch anything, then do the real hardening work
inside a decoy release directory so the fixed script's real `rm`/`cp`
calls stay contained too.

## GUIDED STEPS

1. Read the script, mark the workspace as fenced before anything
   destructive, and keep a permanent snapshot of the original flawed
   version — you'll edit `deploy.sh` in place from here on, and the
   snapshot is what lets you re-demonstrate the catastrophe later without
   undoing your own hardening work:

       cat deploy.sh
       export LAB_WORKSPACE="$PWD"
       cp deploy.sh deploy.sh.flawed

   ```bash
   #!/bin/sh
   # TEACHING SAMPLE — intentionally flawed
   # deploy.sh — clean the release dir, stage listed files, run a named build step.
   run_build() { echo "building..."; }
   run_test() { echo "testing..."; }

   REL=$1
   rm -rf "$REL/"                          # (A) L3.2: empty REL -> rm -rf /
   for f in $(cat manifest.txt); do        # (B) L3.1/L3.3: $(cat) word-splits; spaced names break
     cp $f "$REL"                          # (C) L3.1: unquoted $f
   done
   rm *.tmp                                 # (D) L3.4: a -rf.tmp name could flag rm
   scale=$2
   workers=$(( scale * 2 ))                 # (E) L3.5: untrusted scale -> arithmetic injection
   eval "run_$3"                            # (F) L3.7: eval on an untrusted action name
   echo deployed
   ```

2. Confirm ShellCheck's take on the shipped script:

       shellcheck deploy.sh

   captured output:

       In deploy.sh line 8:
       rm -rf "$REL/"                          # (A) L3.2: empty REL -> rm -rf /
              ^-----^ SC2115 (warning): Use "${var:?}" to ensure this never expands to / .

       In deploy.sh line 9:
       for f in $(cat manifest.txt); do        # (B) L3.1/L3.3: $(cat) word-splits; spaced names break
                ^-----------------^ SC2013 (info): To read lines rather than words, pipe/redirect to a 'while read' loop.

       In deploy.sh line 10:
         cp $f "$REL"                          # (C) L3.1: unquoted $f
            ^-- SC2086 (info): Double quote to prevent globbing and word splitting.

       In deploy.sh line 12:
       rm *.tmp                                 # (D) L3.4: a -rf.tmp name could flag rm
          ^-- SC2035 (info): Use ./*glob* or -- *glob* so names with dashes won't become options.

       In deploy.sh line 14:
       workers=$(( scale * 2 ))                 # (E) L3.5: untrusted scale -> arithmetic injection
       ^-----^ SC2034 (warning): workers appears unused. Verify use (or export if used externally).

   Five codes fire — every one of them is a callback to an earlier lab
   this phase, except line (F). ShellCheck emits **nothing** on the
   `eval` line — the blind spot L3.7/L3.8 already taught you: a clean
   ShellCheck run is not proof of safety.

3. Detonate the empty-`REL` catastrophe — for real, through the fence,
   using the snapshot. This is the evidence `lab check` will look for:

       bash -- run-fenced.sh deploy.sh.flawed "" 4 build

   captured output:

       cat: manifest.txt: No such file or directory
       rm: cannot remove '*.tmp': No such file or directory
       building...
       deployed

       cat fence.log

   captured output:

       FENCE-BLOCKED: rm -rf /

   The script printed `deployed` and exited 0 — a "successful" deploy
   from the outside — while the fence quietly caught a real `rm -rf /`
   along the way. `fence.log`'s line is the proof. (The `cat`/`rm`
   errors above are the *other* footguns misbehaving without a real
   `manifest.txt` yet — expected, and not what this step is grading.)

4. Name each footgun. Write `answers.txt`:

       a_rmrf=8
       b_split=9
       c_unquoted=10
       d_dashname=12
       e_arith=14
       f_eval=15

5. Harden `deploy.sh` **in place** — same file, edited, not a fresh
   rewrite. Six changes, one per footgun:

   - Strict-mode preamble: `#!/usr/bin/env bash` + `set -euo pipefail`.
   - **(A)** `REL=${1:?release dir required}`, then
     `rm -rf "${REL:?}/"` — empty is fatal before `rm` ever runs. Add
     `mkdir -p "$REL"` right after: `rm -rf` deletes the directory
     itself, not just its contents, so the release dir has to be
     recreated before anything can be staged into it.
   - **(B)/(C)** replace the `for f in $(cat …)` loop with
     `while IFS= read -r f; do [[ -n "$f" ]] || continue; cp -- "$f" "$REL"/; done < manifest.txt`
     — lines, not split words; quoted, `--`-guarded `cp`.
   - **(D)** `rm -f -- ./*.tmp` — `--` and `./` so a `-rf.tmp` name can
     never be read as a flag.
   - **(E)** validate `scale` before the arithmetic:
     `case "$scale" in '' | *[!0-9]*) echo "scale must be numeric" >&2; exit 2 ;; esac`
   - **(F)** replace the dynamic dispatch with a `case` allowlist:

     ```bash
     case "$step" in
       build) run_build ;;
       test)  run_test ;;
       *) echo "unknown step: $step" >&2; exit 2 ;;
     esac
     ```

   `REL`, `scale`, and `step` need their own `${2:?...}` / `${3:?...}`
   guards too, matching `REL`'s.

       shellcheck deploy.sh

   Expect no warnings.

6. Prove it aborts before any `rm` when `REL` is empty — watch that
   `fence.log` does NOT grow past the one line from step 3, the same
   proof style L3.2 uses:

       bash -- run-fenced.sh deploy.sh "" 4 build; echo "exit=$?"
       cat fence.log

   captured output:

       deploy.sh: line 7: 1: release dir required
       exit=1
       FENCE-BLOCKED: rm -rf /

   Still just the one `FENCE-BLOCKED` line — the same one from step 3,
   not a new one. The `:?` guard fired *before* the fence was ever
   needed this time: that's the difference between "the fence caught it"
   (step 3, the flawed snapshot) and "the bug never happened" (this step,
   the hardened `deploy.sh`).

7. Prove it does real, correct work — inside a throwaway dir so nothing
   important is at risk:

       mkdir -p rel
       printf 'alpha.txt\n' > manifest.txt
       : > alpha.txt
       bash -- run-fenced.sh deploy.sh rel 4 build; echo "exit=$?"
       ls rel

   captured output:

       building...
       deployed with 8 workers
       exit=0
       alpha.txt

8. `lab check bash L3.9`

   `check.sh` grades `fence.log` twice: once for step 3's persisted
   evidence, then it clears the file itself to re-test your hardened
   script in isolation. That means a **second** `lab check` run always
   needs step 3's evidence regenerated first — re-run it against your
   permanent snapshot, never against the now-hardened `deploy.sh`:

       bash -- run-fenced.sh deploy.sh.flawed "" 4 build

   (the same behavior L3.2's check.sh already has, minus the part where
   L3.2 never edits its flawed sample in the first place)
