## BRIEF
`calc.sh` doubles a number given on the command line using `$(( n * 2 ))`.
Arithmetic evaluation in bash is *recursive*: the contents of `n` are
themselves re-evaluated as an expression, and an array-subscript reference
inside that expression — `a[$(cmd)]` — is command-substituted. `cmd` runs.
No `eval`, no `$(...)` in the visible source — just plain arithmetic on
untrusted input. The demo payload here only runs `id -u` (prints your uid to
stderr); nothing destructive, nothing that touches the filesystem.

## GUIDED STEPS

1. Read the script:

       cat calc.sh

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   # calc.sh — double a quantity supplied on the command line.
   n=$1                                  # UNTRUSTED
   result=$(( n * 2 ))                   # $(( )) evaluates n as an arithmetic EXPRESSION,
                                         # and an array subscript inside it runs command substitution
   echo "result=$result"
   ```

   Line 5, `result=$(( n * 2 ))`, is the flaw. `n` is never checked before it
   reaches `(( ))`.

2. Confirm normal use first:

       bash calc.sh 5

   captured output:

       result=10

3. Check what ShellCheck says:

       shellcheck calc.sh

   captured output: *(nothing — clean, no warnings)*

   This is the point: **ShellCheck has no dedicated warning for arithmetic
   command-substitution injection.** A clean ShellCheck run told you
   nothing about this bug. Keep that in mind — L3.8 comes back to exactly
   this blind spot.

4. Detonate it — for real, but harmlessly. The payload only runs `id -u`,
   which just prints your user id to stderr:

       bash calc.sh 'a[$(id -u >&2)]'

   captured output:

       1000
       result=0

   Your uid printed *before* `result=` was even computed — `id -u` ran as
   part of evaluating the arithmetic expression. `n` was never a number at
   all; bash parsed `a[$(id -u >&2)]` as a reference to array `a` whose
   subscript is a command substitution, ran it, and only then treated
   whatever `a[...]` evaluates to (unset → `0`) as the operand. Try a
   second payload to make it unmistakable:

       bash calc.sh 'z[$(echo INJECTED-CODE-RAN >&2)]'

   captured output:

       INJECTED-CODE-RAN
       result=0

   `echo` is not a command this script ever calls — the injected string
   ran it anyway.

5. Name the flaw. Write `answers.txt`:

       line=5
       flaw=arith-cmdsub
       fix=validate n is all-digit before it reaches (( )); reject anything else

6. Author `hardened.sh` from scratch — reject non-numeric input before any
   arithmetic runs:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   n=$1
   case "$n" in
     '' | *[!0-9]*) echo "refusing non-numeric input: $n" >&2; exit 2 ;;
   esac
   result=$(( n * 2 ))                   # now n is guaranteed all-digits
   echo "result=$result"
   ```

       shellcheck hardened.sh

   Expect no warnings.

7. Prove it rejects the injection and still does real work:

       bash hardened.sh 'a[$(id -u)]'; echo "exit=$?"

   captured output:

       refusing non-numeric input: a[$(id -u)]
       exit=2

   No `id` output this time — the guard fired before `(( ))` ever saw the
   payload.

       bash hardened.sh 5

   captured output:

       result=10

8. `lab check bash L3.5`
