## BRIEF
Security Onion runs scripts under different shells; Alpine containers use
BusyBox sh; Debian/Ubuntu `/bin/sh` is dash, not bash. A script that works
in your terminal can fail in a container for this reason alone. Two
scripts below share the IDENTICAL `#!/bin/sh` shebang — one honest (a
POSIX body), one lying (a bash body). Run both under `bash` and `dash`,
watch the liar detonate, then let ShellCheck name the bashisms. This lab
is the Phase 0 exit gate: given any script, you should be able to say
what interpreter it targets and whether bash-only syntax will break under
`/bin/sh`. Stuck? `lab hint bash L0.3`.

## GUIDED STEPS

1. Read the honest script first.

       cat greet.sh

   ```sh
   #!/bin/sh
   name="${1:-world}"
   printf 'hello, %s\n' "$name"
   ```

2. Read the liar — same shebang, different body.

       cat deploy.sh

   ```sh
   #!/bin/sh
   # TEACHING SAMPLE — intentionally flawed
   target="$1"
   if [[ -z "$target" ]]; then
     target="prod"
   fi
   printf 'deploying to %s\n' "${target^^}"
   ```

3. Run the honest one under bash.

       bash greet.sh

   expect:

       hello, world

4. Run the honest one under dash.

       dash greet.sh

   expect:

       hello, world

   Same shebang, same behavior — the body matches the dialect it claims.

5. Run the liar under bash.

       bash deploy.sh

   expect:

       deploying to PROD

6. Run the liar under dash.

       dash deploy.sh

   expect (two stderr lines):

       deploy.sh: 4: [[: not found
       deploy.sh: 7: Bad substitution

7. Check the verdict.

       echo $?

   expect:

       2

   dash has no `[[` — line 4 parses as an ordinary command named `[[`,
   which doesn't exist (that alone is exit 127-shaped). `if` reads that as
   false, so the body is SKIPPED and `target` silently stays EMPTY — quiet
   logic corruption *before* the crash. Line 7's `${target^^}` is not
   POSIX; dash aborts fatally there instead, and the script's own exit
   code is 2.

8. Capture the dash run as evidence.

       dash deploy.sh > dash-run.txt 2>&1

   (exit 2 is expected — the redirect still captures both stderr lines.)

9. Capture the bash run as evidence.

       bash deploy.sh > bash-run.txt 2>&1

10. Name where `/bin/sh` really points.

        readlink -f /bin/sh > sh-target.txt

    `./deploy.sh` (exec'd via its shebang) would run under whatever this
    file names.

11. Ask ShellCheck to grade against POSIX sh, not bash.

        shellcheck -s sh deploy.sh > sc-out.txt 2>&1 || true

    Precedence rule, settled empirically: command-line `-s` outranks the
    nearest `.shellcheckrc` `shell=` setting, which outranks the shebang.
    This repo's `.shellcheckrc` pins `shell=bash` (it outranks the
    `#!/bin/sh` shebang for a bare `shellcheck deploy.sh`), so `-s sh`
    explicitly asks "is this valid POSIX sh?" — the command line outranks
    them both.

12. Read the findings.

        cat sc-out.txt

    Two warnings, each naming one of the two bashisms line 4 and line 7
    ran into under dash.

13. Write your answers. Four lines, `q1=` … `q4=`, no spaces around `=`:

    q1. `./deploy.sh` — run via its shebang — executes under…
        a) bash, it's the login shell
        b) `/bin/sh`, which is dash on this OS
        c) whatever `$SHELL` says

    q2. Why can this script pass on a dev box yet die in a Debian/Alpine
        container?
        a) containers block shell scripts
        b) the container's `/bin/sh` is dash/BusyBox — no `[[`, no `${var^^}`
        c) the exec bit is lost in the image

    q3. Is `[[ ]]` POSIX?
        a) yes
        b) no — it's a bash/ksh extension
        c) only when the operands are quoted

    q4. The smallest honest fix for deploy.sh?
        a) change the shebang to `#!/bin/bash`
        b) rewrite the body POSIX (`test`/`[ ]` + `tr`)
        c) either a or b — match the shebang to the syntax or the syntax
           to the shebang

14. Grade it.

        lab check bash L0.3
