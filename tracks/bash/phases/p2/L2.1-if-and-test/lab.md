## BRIEF
Phase 1's punchline becomes Phase 2's engine: `if` runs a COMMAND and
branches on its exit code (L1.6) — nothing else. `[` is literally a
command with an exit code; `[[` is bash syntax with parsing superpowers
(no word splitting inside); `(( ))` is arithmetic, where nonzero means
true — and that truth gets FLIPPED into exit-code convention (true → 0).
The lab's deliverable is a trust table: `[[ ]]` for strings/files,
`(( ))` for numbers, `[ ]` only when the script must run under POSIX sh
(the L0.3 dash lesson). The experiments show why: `[ ]` inherits every
Phase-1 expansion bug; `[[ ]]` is immune to the worst of them.

## GUIDED STEPS

1. Decode before running — find the three constructs, one per `if`:

       cat gatekeeper.sh

   ```bash
   #!/usr/bin/env bash
   # gatekeeper.sh — admit or deny a request: strings via [[ ]], numbers via (( )).
   user="${1:-}"
   load="${2:-0}"
   if [[ -z "$user" ]]; then
     echo "usage: bash gatekeeper.sh <user> <load>" >&2
     exit 2
   fi
   if [[ "$user" != "admin" ]]; then
     echo "deny: $user is not admin"
     exit 1
   fi
   if (( load >= 8 )); then
     echo "deny: load $load too high"
     exit 1
   fi
   echo "admit: $user (load $load)"
   ```

   Three `if`s, three constructs: `[[ -z "$user" ]]` tests string
   emptiness, `[[ "$user" != "admin" ]]` compares strings, `(( load >= 8 ))`
   compares numbers. Each `if` consumes only an exit code — nothing else.
   Exit codes are the script's API: 0 admit, 1 deny, 2 usage.

2. Run the four-row matrix, `echo $?` folded onto each line:

       bash gatekeeper.sh admin 3; echo $?
       bash gatekeeper.sh admin 12; echo $?
       bash gatekeeper.sh guest 3; echo $?
       bash gatekeeper.sh; echo $?

   expect:

       admit: admin (load 3)
       0
       deny: load 12 too high
       1
       deny: guest is not admin
       1
       usage: bash gatekeeper.sh <user> <load>
       2

3. Experiment 1 — THE TRAP. Type this exactly:

       x=""; [ -n $x ]; echo $?

   expect:

       0

   Read that again: `$x` is an EMPTY string, and `[ -n ]` (a test for
   "is this string non-empty") just said TRUE. Here's why: `$x` expanded
   to nothing and vanished before `[` ever ran (L1.2's "silently became
   nothing") — so `[` received exactly ONE argument, the literal text
   `-n`. A one-argument test asks "is that string non-empty?", and the
   string `-n` is non-empty. An empty variable just passed a non-empty
   check. Auth-bypass shaped.

4. Experiment 2 — the same intent, the bash-syntax construct:

       x=""; [[ -n $x ]]; echo $?

   expect:

       1

   `[[` is parsed as syntax BEFORE expansion happens — its operand
   positions are fixed no matter what `$x` expands to. Correct answer,
   and no quotes were even needed (quote anyway — the reflex stays).

5. Experiment 3 — a space-bearing value:

       name="admin user"; [ $name = admin ]; echo $?

   expect (exact error text is invocation-context-variant; the stable
   part is the suffix):

       ...: [: too many arguments
       2

   The unquoted `$name` split into two words before `[` ever ran, so
   `[` received THREE-PLUS operands where it expected one comparison —
   a broken test, not a false one.

6. Experiment 4 — same operands, the construct that doesn't split:

       [[ $name = admin ]]; echo $?

   expect:

       1

   No splitting inside `[[` — a clean false instead of a broken test.

7. Experiment 5 — the string-comparison trap:

       [[ 10 > 9 ]]; echo $?

   expect:

       1

   Inside `[[ ]]`, `>` is STRING comparison: `"10"` sorts before `"9"`
   character by character. The classic silent wrong answer.

8. Experiment 6 — arithmetic, and the truth flip:

       (( 10 > 9 )); echo $?
       (( 0 )); echo $?

   expect:

       0
       1

   `(( ))` is arithmetic comparison, and arithmetic TRUE becomes exit
   code 0 — the flip. (`(( 0 ))` is arithmetic FALSE, so it flips to
   exit 1.) For reference, the POSIX numeric operator gets it right in
   `[ ]` too: `[ 10 -gt 9 ]` also exits 0 — `-gt` is a numeric test,
   unlike the string `>`.

9. Write `answers.txt` — one `key=value` per line, no spaces around `=`:

   q1 (value). Exit code of experiment 1?

   q2 (value). Exit code of experiment 2?

   q3 (choice). Why did q1 say 0?
   a) `[ ]` treats empty strings as non-empty
   b) `$x` vanished before `[` ran — `[ -n ]` became a one-argument
      test, "is the literal string -n non-empty?", which is always true
   c) `-n` only works on quoted variables

   q4 (value). Exit code of experiment 3?

   q5 (value). Exit code of `[[ 10 > 9 ]]`?

   q6 (value). Exit code of `(( 10 > 9 ))`?

10. `lab check bash L2.1`
