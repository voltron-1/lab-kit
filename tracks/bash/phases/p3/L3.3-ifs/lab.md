## BRIEF
`IFS` (Internal Field Separator) is the variable that decides where an
*unquoted* expansion breaks into separate words — it's what every word-split
bug in this phase has actually been running on top of. `split-demo.sh` cuts
the SAME two pieces of data three different ways — default `IFS`,
`IFS=':'`, and an empty `IFS` — so you can see exactly what changes.
Then you'll demonstrate the attack angle for real: a script that
word-splits untrusted or inherited data can be *re-steered* by whoever
controls `IFS` before it runs.

## GUIDED STEPS

1. Read the data and the script:

       cat passwd.line
       cat split-demo.sh

   ```
   root:x:0:0:root:/root:/bin/bash
   ```

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally unquoted, to demonstrate what IFS controls
   # split-demo.sh — the SAME data, cut three ways, to show what IFS controls.
   line="$(cat passwd.line)"
   data='a b c'

   # 1) default IFS (space/tab/newline): whitespace splits, ':' does not
   set -- $data;        printf '1) default IFS, $data  -> argc=%d\n' "$#"

   # 2) IFS=':'  — now the colon is the separator, spaces are not
   IFS=':' read -ra f <<< "$line"
   printf '2) IFS=":" on passwd -> fields=%d first=%s shell=%s\n' "${#f[@]}" "${f[0]}" "${f[-1]}"

   # 3) IFS=''  — splitting DISABLED: the whole value stays one word
   IFS='' ; set -- $data; printf '3) IFS empty, $data      -> argc=%d\n' "$#"
   ```

   The two `set -- $data` lines are unquoted on purpose — that's the whole
   point of the demo, which is why the file carries the teaching-sample
   header even though nothing here is "broken."

2. Run it:

       bash split-demo.sh

   captured output:

       1) default IFS, $data  -> argc=3
       2) IFS=":" on passwd -> fields=7 first=root shell=/bin/bash
       3) IFS empty, $data      -> argc=1

   Same `data='a b c'`, three different `IFS` settings, three different
   answers: the default `IFS` (space/tab/newline) splits it into 3 words;
   `IFS=':'` doesn't touch it at all (no colons in `a b c`) but turns the
   passwd line into 7 fields; an empty `IFS` disables splitting entirely,
   so the whole 5-character string counts as exactly 1 word.

3. Confirm ShellCheck's read on the intentional splits:

       shellcheck split-demo.sh

   captured output:

       In split-demo.sh line 8:
       set -- $data;        printf '1) default IFS, $data  -> argc=%d\n' "$#"
              ^---^ SC2086 (info): Double quote to prevent globbing and word splitting.
                                   ^-- SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.

       Did you mean:
       set -- "$data";        printf '1) default IFS, $data  -> argc=%d\n' "$#"


       In split-demo.sh line 15:
       IFS='' ; set -- $data; printf '3) IFS empty, $data      -> argc=%d\n' "$#"
                       ^---^ SC2086 (info): Double quote to prevent globbing and word splitting.
                                     ^-- SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.

       Did you mean:
       IFS='' ; set -- "$data"; printf '3) IFS empty, $data      -> argc=%d\n' "$#"

       For more information:
         https://www.shellcheck.net/wiki/SC2016 -- Expressions don't expand in singl...
         https://www.shellcheck.net/wiki/SC2086 -- Double quote to prevent globbing ...

   Both are expected and both are `info`, not `warning`: SC2086 is
   ShellCheck noticing the deliberate unquoted split (that's the demo),
   and SC2016 is it noticing the printf format strings contain a literal
   `$data` that's meant to print as text, not expand — also deliberate.

4. Now demonstrate the attack angle for real — not just told. A script
   that word-splits an unquoted expansion inherits whatever `IFS` its
   caller set. Watch the SAME loop over the SAME path behave completely
   differently once something upstream changes `IFS` before your script
   ever runs:

       path=/usr/local/bin
       for p in $path; do echo "token: [$p]"; done
       IFS=/
       for p in $path; do echo "token: [$p]"; done
       unset IFS

   captured output:

       token: [/usr/local/bin]
       token: []
       token: [usr]
       token: [local]
       token: [bin]

   Under the normal, inherited `IFS`, `$path` has no whitespace in it, so
   the loop sees one token — the whole path. The moment `IFS` is set to
   `/` (something an attacker — or just a poorly-behaved caller — can do
   in your environment *before* invoking your script), the exact same
   unquoted `$path` splits into four tokens, one of them empty. Nothing
   in the loop's own code changed; only `IFS` did. That's the re-steering:
   whoever controls `IFS` at call time controls how your unquoted
   expansions get cut, and this is invisible from reading the loop alone.

5. Write `answers.txt` with your five keys:

       default_argc=3
       passwd_fields=7
       empty_argc=1
       ifs_controls=splitting
       attack=set IFS before a script runs and its unquoted for-loops split on your chosen character instead of whitespace

6. `lab check bash L3.3`
