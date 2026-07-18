## BRIEF
`lookup.sh` looks up a user's greeting by name. It builds the `grep` call as
text and hands the whole thing to `bash -c`, which re-parses that text as a
brand-new command line. As long as `name` only ever contains letters, this
looks harmless. It isn't: `name` is spliced into the string completely
unquoted, so any shell metacharacter it contains — a semicolon, above all —
becomes real syntax the moment `bash -c` re-parses it. This is **CWE-78, OS
command injection**, Bash's signature vulnerability. The demonstration
includes a real, destructive payload (`rm -rf ~`), so it runs through the
same shadowed-`rm` fence used in Phase 3: `fence.sh` + `run-fenced.sh`
intercept any `rm` whose target resolves outside your lab workspace and log
it instead of running it.

## GUIDED STEPS

1. Read the script and mark the workspace as fenced before anything
   destructive:

       cat lookup.sh
       export LAB_WORKSPACE="$PWD"

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   # lookup.sh — print the greeting line for a named user.
   name=$1                                        # UNTRUSTED (e.g. from a web form)
   line=$(bash -c "grep ^$name: greetings.txt")   # $name spliced unquoted into a shell string, re-parsed
   echo "$line"
   ```

   Line 5 is the flaw. `$name` lands in the string handed to `bash -c` with
   **no quotes around it at all** — not even the defensive-looking escaped
   quotes you might expect. Whatever `$name` contains becomes literal text
   in a command line that a second, brand-new shell process re-parses from
   scratch.

2. Confirm ShellCheck's take:

       shellcheck lookup.sh

   captured output: *(nothing — clean, no warnings)*

   Same blind spot as `eval` (L3.7): ShellCheck has no dedicated check for
   "this constructs a command line from unquoted untrusted input and hands
   it to a shell to re-parse." It looks clean. It isn't.

3. Normal use first:

       bash lookup.sh alice

   captured output:

       alice:Hello, Alice!

4. Probe the injection — harmlessly. A semicolon in `name` should be just
   another character in a person's name. It isn't:

       bash lookup.sh 'x; echo INJECTED #' < /dev/null

   captured output:

       INJECTED

   `name` became part of the *command line itself*, not part of the
   argument to `grep`. `bash -c` re-parsed `grep ^x; echo INJECTED #:
   greetings.txt` as **two commands** — `grep ^x` (finds nothing) and
   `echo INJECTED` (the `#` comments out the rest) — and the second one is
   entirely attacker-chosen. Compare with a harmless value that contains no
   metacharacters: `bash lookup.sh nobody < /dev/null` just prints nothing
   (no matching line) — the injection needs a shell metacharacter to work,
   which is exactly why quoting the value would close it.

5. Detonate it for real, through the fence — same payload shape, a
   destructive command this time:

       bash -- run-fenced.sh lookup.sh 'x; rm -rf ~ #' < /dev/null
       cat fence.log

   captured output:

       (blank — lookup.sh printed nothing; both halves of the injected line produced no stdout)
       FENCE-BLOCKED: rm -rf /home/…

   The script printed nothing and exited clean — the fence made the
   would-be `rm -rf ~` a silent no-op, exactly like the real catastrophe
   would look from the outside (a lookup that "just found nothing").
   `fence.log` is the proof: the target canonicalized to your real home
   directory, outside `$LAB_WORKSPACE`, so the whole call was refused and
   logged instead of run. Nothing outside this workspace changed.

6. Name the flaw. Write `answers.txt`:

       line=5
       flaw=command-injection
       cwe=CWE-78
       fix=call grep directly, pass "$name" as a separate argument, no shell string

7. Author `hardened.sh` from scratch — no re-parsing, no `bash -c` at all.
   Call `grep` directly and let `$name` be *data*, never text a shell reads
   as syntax:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   name=$1
   line=$(grep -- "^$name:" greetings.txt || true)   # -- blocks option injection; "$name" is DATA, never re-parsed; || true keeps a no-match non-fatal
   echo "$line"
   ```

       shellcheck hardened.sh

   Expect no warnings.

8. Prove it rejects the injection — through the fence, for the strongest
   proof nothing reaches `rm`. Clear `fence.log` first — it still holds the
   one line from step 5, and this step needs to prove nothing *new* lands
   in it:

       : > fence.log
       bash -- run-fenced.sh hardened.sh 'x; rm -rf ~ #' < /dev/null; echo "exit=$?"
       cat fence.log

   captured output:

       (blank — hardened.sh found no matching line, so it printed nothing)
       exit=0
       (blank — fence.log stays empty)

   `fence.log` stays empty — `$name` never left the argument
   position, so `grep` just searched (and found nothing) for the literal
   nine-character string `x; rm -rf ~ #`. No re-parse, no injection,
   nothing for the fence to catch.

9. Prove it still works normally:

       bash hardened.sh alice

   captured output:

       alice:Hello, Alice!

10. `lab check bash L4.1`
