## BRIEF
`cleanup.sh` wipes a build output directory before a fresh build — one line,
`rm -rf "$BUILD_DIR/"`. If `BUILD_DIR` is ever empty (a failed `dirname`, a
stripped cron env, a refactor that drops the assignment), that quoted string
collapses to the filesystem root and the command becomes `rm -rf /`. This lab
runs that exact detonation — for real — but through a fail-closed fence that
intercepts and logs any `rm` whose target resolves outside your lab workspace
instead of letting it run. Find the line, name the flaw and the one-token
fix, then author a hardened version from scratch and prove it aborts safely.

## GUIDED STEPS

1. Read the script and mark the workspace as fenced before you touch
   anything destructive:

       cat cleanup.sh
       export LAB_WORKSPACE="$PWD"

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   # cleanup.sh — wipe the build output dir before a fresh build.
   BUILD_DIR="${BUILD_DIR-$(dirname "$0")/build}"   # if this ever arrives empty, the next line is fatal
   rm -rf "$BUILD_DIR/"                              # empty BUILD_DIR => rm -rf "/"  ← the catastrophe
   echo clean
   ```

   Line 5 is the catastrophe: `rm -rf "$BUILD_DIR/"`. Line 4 only *sets*
   `BUILD_DIR` — it never protects the `rm` on the next line from an empty
   value. `LAB_WORKSPACE` is what `fence.sh` checks every `rm` target
   against, so it must be set before you run anything through the fence.

2. Confirm ShellCheck already flags this exact pattern:

       shellcheck cleanup.sh

   captured output:

       In cleanup.sh line 5:
       rm -rf "$BUILD_DIR/"                              # empty BUILD_DIR => rm -rf "/"  ← the catastrophe
              ^-----------^ SC2115 (warning): Use "${var:?}" to ensure this never expands to / .

   **SC2115** is the load-bearing code here — this is one of the few
   footguns in this phase ShellCheck actually catches on its own.

3. Detonate it — for real, through the fence. Force `BUILD_DIR` empty and
   run the script via the shipped `run-fenced.sh` wrapper, which sources
   `fence.sh` (shadowing `rm` fail-closed) before sourcing your target:

       BUILD_DIR="" bash -- run-fenced.sh cleanup.sh
       cat fence.log

   captured output:

       clean
       FENCE-BLOCKED: rm -rf /

   The script still printed `clean` and exited 0 — the fence made the
   would-be `rm -rf /` a silent no-op instead of letting it fail loudly,
   exactly like the real catastrophe would look from the outside (a
   cleanup script that "succeeded"). `fence.log` is the proof: the target
   canonicalized to `/`, which is outside `$LAB_WORKSPACE`, so the whole
   call was refused and logged instead of run. Nothing outside this
   workspace changed.

4. Name the flaw. Write `answers.txt`:

       line=5
       flaw=empty-var-rm
       fix=${BUILD_DIR:?BUILD_DIR is empty}

5. Author `hardened.sh` from scratch — three goals: strict mode, a `:?`
   guard on `BUILD_DIR` that fires *before* `rm`, otherwise behave exactly
   like `cleanup.sh`:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   BUILD_DIR="${BUILD_DIR-$(dirname "$0")/build}"
   rm -rf "${BUILD_DIR:?BUILD_DIR is empty — refusing to rm}/"   # :? aborts before rm if empty
   echo clean
   ```

       shellcheck hardened.sh

   Expect no warnings — the `:?` guard is exactly what SC2115 asked for.

6. Prove it fails SAFE with an empty `BUILD_DIR` — the fence should never
   even see an `rm` call, because the script must abort first. `fence.log`
   still has the one line from step 3 — watch that it does NOT grow:

       BUILD_DIR="" bash -- run-fenced.sh hardened.sh; echo "exit=$?"
       cat fence.log

   captured output:

       hardened.sh: line 4: BUILD_DIR: BUILD_DIR is empty — refusing to rm
       exit=1
       FENCE-BLOCKED: rm -rf /

   Still just the one `FENCE-BLOCKED` line — the same one from step 3, not
   a new one. The guard fired *before* the fence was ever needed: that's
   the difference between "the fence caught it" (step 3, `cleanup.sh`) and
   "the bug never happened" (this step, `hardened.sh`).

7. Prove it still works normally — unset `BUILD_DIR` entirely (the
   script's own default takes over, same as `cleanup.sh`'s original
   behavior):

       mkdir -p build && touch build/artifact.txt
       unset BUILD_DIR
       bash -- run-fenced.sh hardened.sh; echo "exit=$?"
       ls build 2>&1 || echo "build/ correctly removed"

   captured output:

       clean
       exit=0
       ls: cannot access 'build': No such file or directory
       build/ correctly removed

8. `lab check bash L3.2`
