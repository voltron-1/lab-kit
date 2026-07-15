## BRIEF
A bash function is a mini-command (L1.6: scripts are commands too — so
are functions). It has exactly two ways to hand something back:
`return N` sets an exit code (one byte, consumed by if/&&/||) and
`echo` writes text (captured by `$(fn)` — L1.7). Confusing the
channels is a classic AI-bash bug: `out=$(fn)` where fn only returns
leaves out EMPTY. And without `local`, every assignment inside a
function silently edits the caller's variables. `healthcheck.sh` uses
both channels correctly — decode it, then break each rule at the
prompt and watch.

## GUIDED STEPS

1. Decode, then read the evidence it works on:

       cat healthcheck.sh
       cat app.log

   ```bash
   #!/usr/bin/env bash
   # healthcheck.sh — one function returns a VALUE (echo), the other a VERDICT (return).
   count_errors() {
     local n
     n=$(grep -c ERROR "$1")
     echo "$n"
   }
   is_healthy() {
     local n="$1"
     if (( n == 0 )); then
       return 0
     fi
     return 1
   }
   n=$(count_errors app.log)
   if is_healthy "$n"; then
     echo "status: healthy ($n errors)"
   else
     echo "status: degraded ($n errors)"
   fi
   ```

   `count_errors` delivers its answer by ECHO, harvested by
   `n=$(count_errors app.log)` — the L1.7 capture. `is_healthy`
   delivers by RETURN, consumed by `if is_healthy "$n"` — the L1.6
   verdict, now inside one script. Both declare `local n` — two
   different `n`s coexist; the caller's own `n` (set two lines below)
   is never touched by either function's internal `local n`.

2. Run it:

       bash healthcheck.sh

   expect:

       status: degraded (2 errors)

3. Four prompt experiments, one line each:

       h() { return 7; }; h; echo $?

   expect:

       7

   `return` sets the function's exit code, read like any command's.

       broken() { return 42; }; out=$(broken); echo "out=[$out] rc=$?"

   expect:

       out=[] rc=42

   The channel confusion, live: `$( )` captured stdout (there was
   none) while the 42 traveled the exit-code channel. `out` is EMPTY.

       g() { x=changed; }; x=start; g; echo $x

   expect:

       changed

   No `local` in `g` — the function silently edited the caller's
   variable.

       r() { return 300; }; r; echo $?

   expect:

       44

   The verdict channel is ONE BYTE wide (L1.6's "one-byte verdict",
   literally): `300 mod 256 = 44`. `return` cannot carry data — that
   is exactly what `echo` is for.

4. Write `answers.txt` — one `key=value` per line, no spaces around
   `=`:

   q1 (value). Experiment 1's digit?

   q2 (choice). Experiment 2: what landed in `out`?
   a) the string 42
   b) nothing — return sends a one-byte CODE up the exit channel,
      never text; $( ) captures only stdout
   c) the text "return 42"

   q3 (value). Experiment 3's printed word?

   q4 (value). Experiment 4's digit(s)?

   q5 (choice). In healthcheck.sh, count_errors hands its answer back
   via…
   a) return
   b) echo to stdout, captured by $( ) at the call site
   c) the global n

5. `lab check bash L2.6`
