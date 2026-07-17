## BRIEF
`purge.sh` deletes every file in the current directory — flat, non-recursive,
or so it claims. The shell expands and *sorts* a glob before any command ever
sees it, and a file literally named `-rf` sorts ahead of ordinary names. `rm`
then reads that leading `-rf` as the options `-r -f`, not a filename — a flat
delete goes recursive. Build a small demo dir, watch it happen for real, name
the flaw, then author a hardened purge that can never read a name as a flag.

## GUIDED STEPS

1. Read the script:

       cat purge.sh

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   # purge.sh — delete every file in the current dir (flat, non-recursive… supposedly).
   rm *                                  # a file named -rf sorts FIRST and becomes a FLAG
   echo purged
   ```

   Line 4, `rm *`, is the flaw. Nothing here is inherently unsafe about
   `rm *` in isolation — the danger is that a *filename* can be attacker-
   or accident-controlled data, and an unguarded `rm` reads it as syntax.

2. Confirm ShellCheck already flags this exact pattern:

       shellcheck purge.sh

   captured output:

       In purge.sh line 4:
       rm *                                  # a file named -rf sorts FIRST and becomes a FLAG
          ^-- SC2035 (info): Use ./*glob* or -- *glob* so names with dashes won't become options.

   **SC2035** is the load-bearing code — one of the few footguns in this
   phase ShellCheck actually catches on its own.

3. Build a demo directory and detonate it — for real. This stays entirely
   inside your lab workspace (a relative glob can't climb out of the
   current directory), so no fence is needed for this one:

       mkdir -p demo/subdir
       printf 'alpha\n' > demo/alpha.txt
       printf 'beta\n'  > demo/subdir/beta.txt
       : > demo/-rf
       cp purge.sh demo/
       ( cd demo && printf '%s\n' * )

   captured output (glob expansion order — this is the whole attack):

       -rf
       alpha.txt
       purge.sh
       subdir

   `-rf` sorts first. Now run it:

       ( cd demo && bash purge.sh ); find demo -mindepth 1 | sort

   captured output:

       purged
       demo/-rf

   `alpha.txt`, `purge.sh`, and the entire `subdir/` (with `beta.txt`
   inside it) are gone — a *directory* was deleted by a script whose own
   comment claims "non-recursive." Only the file literally named `-rf`
   survives, because it was consumed as an argument to itself, never
   passed to `rm` as a name to delete. That is the detonation: `rm *`
   became `rm -rf alpha.txt purge.sh subdir` the instant the glob sorted
   `-rf` into first position.

4. Name the flaw. Write `answers.txt`:

       line=4
       flaw=dash-filename
       fix=rm -- ./* (or rm ./*) so a name can never be read as an option

5. Author `hardened.sh` from scratch. The lesson is "a flat purge must
   never recurse and must never let a name lead with `-`" — a bare
   `rm -- ./*` still errors on a directory argument under `set -e` (it
   isn't `-r`), so scope it to files only:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   find . -maxdepth 1 -type f -exec rm -- {} +   # files only; no name can ever be read as a flag
   echo purged
   ```

       shellcheck hardened.sh

   Expect no warnings.

6. Prove it purges files but never recurses. Rebuild a fresh demo dir with
   the same hostile filename:

       rm -rf demo && mkdir -p demo/subdir
       printf 'alpha\n' > demo/alpha.txt
       printf 'beta\n'  > demo/subdir/beta.txt
       : > demo/-rf
       cp hardened.sh demo/
       ( cd demo && bash hardened.sh ); find demo -mindepth 1 | sort

   captured output:

       purged
       demo/subdir
       demo/subdir/beta.txt

   The `-rf` file and `alpha.txt` are gone (purged as plain files, exactly
   as intended) and `subdir/` — with `beta.txt` still inside it — survived
   untouched. Compare to step 3: same hostile filename, but nothing can be
   read as a flag anymore, so nothing recurses.

7. `lab check bash L3.4`
