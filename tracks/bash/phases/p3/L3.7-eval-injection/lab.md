## BRIEF
`dispatch.sh` builds a command string out of an "action" and a "target" and
hands the whole thing to `eval`, which re-parses it as shell source. Any
shell metacharacter that ends up **unquoted** in that built string becomes
real syntax — a semicolon starts a brand-new command, chosen entirely by
whoever controlled the input. The demonstration includes a real,
destructive payload (`rm -rf ~`), so it runs through the same shadowed-`rm`
fence as L3.2: `fence.sh` + `run-fenced.sh` intercept any `rm` whose target
resolves outside your lab workspace and log it instead of running it.

## GUIDED STEPS

1. Read the script and mark the workspace as fenced before anything
   destructive:

       cat dispatch.sh
       export LAB_WORKSPACE="$PWD"

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   # dispatch.sh — look up a file's info; the "action" comes from the caller.
   action=$1                             # UNTRUSTED (e.g. from a web form / filename)
   target=$2
   eval "$action \"$target\""            # eval re-parses the whole string as a command line
   ```

   Line 5 is the flaw. Look closely at *how* the two inputs land in the
   built string: `target` sits inside escaped quotes (`\"$target\"`), but
   `action` does not — it's dropped straight into the string unquoted.
   That asymmetry matters more than it looks like it should.

2. Confirm ShellCheck's take:

       shellcheck dispatch.sh

   captured output: *(nothing — clean, no warnings)*

   No dedicated "this eval is injectable" code exists. This is a blind
   spot ShellCheck cannot see (L3.8 comes back to it).

3. Normal use first:

       bash dispatch.sh echo hello

   captured output:

       hello

4. Try to inject through `target` — the slot that looks unsafe at a
   glance, because its value is attacker-controlled too:

       bash dispatch.sh echo 'hello; echo TARGET-INJECTED'

   captured output:

       hello; echo TARGET-INJECTED

   Nothing ran. `target`'s escaped quotes survive into the string `eval`
   re-parses, so `echo` sees one literal argument — the whole string,
   semicolon included — not two commands. **This is the surprising part:
   quoting `target` actually works.**

5. Now try `action` — the slot with no quoting at all:

       bash dispatch.sh 'echo hi; echo ACTION-INJECTED' hello

   captured output:

       hi
       ACTION-INJECTED hello

   Two commands ran. `action`'s semicolon was never inside any quotes, so
   `eval` re-parsed it as a real command separator — `echo hi`, then a
   second, attacker-chosen command that even picked up `target` as its
   own argument. **The injectable slot is `action`, not `target`** —
   the reverse of what the quoting at a glance suggests.

6. Detonate it for real, through the fence — `action` carrying a
   destructive payload this time:

       bash -- run-fenced.sh dispatch.sh 'ls; rm -rf ~' file.txt
       cat fence.log

   captured output:

       dispatch.sh
       fence.sh
       run-fenced.sh
       FENCE-BLOCKED: rm -rf /home/… file.txt

   `ls` ran (it's the first half of the injected command and lists your
   workspace), then the injected `rm -rf ~` fired for real — and was
   caught. `fence.log`'s line is the proof: the target canonicalized to
   your real home directory, outside `$LAB_WORKSPACE`, so the whole call
   was refused and logged instead of run. Nothing outside this workspace
   changed.

7. Name the flaw. Write `answers.txt`:

       line=5
       flaw=eval-injection
       fix=dispatch through a case/array allowlist — never build a string and re-parse it

8. Author `hardened.sh` from scratch — no re-parsing at all, just a
   direct dispatch through a small allowlist:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   action=$1
   target=$2
   case "$action" in
     stat) stat -- "$target" ;;          # direct invocation; "$target" is DATA, never re-parsed
     size) wc -c -- "$target" ;;
     type) file -- "$target" ;;
     *) echo "unknown action: $action" >&2; exit 2 ;;
   esac
   ```

       shellcheck hardened.sh

   Expect no warnings.

9. Prove it rejects the injection-shaped action — through the fence,
   for the strongest proof nothing reaches `rm`:

       : > fence.log
       bash -- run-fenced.sh hardened.sh 'x; rm -rf ~' harmless-target; echo "exit=$?"
       cat fence.log

   captured output:

       unknown action: x; rm -rf ~
       exit=2

   `fence.log` stays empty — the `case` allowlist refused the whole
   action before anything resembling `rm` was ever built, let alone run.

10. Prove a real verb still works:

        printf hi > f.txt
        bash -- hardened.sh size f.txt

    captured output:

        2 f.txt

11. `lab check bash L3.7`
