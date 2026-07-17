## BRIEF
Phase 3 opens with the bug that's been waiting under every unquoted `$var`
since L1.3: word splitting. `stage.sh` claims to move every file listed in
`manifest.txt` into `archive/` — but it reads the manifest with `$(cat)`
(splits into WORDS, not lines) and moves each name unquoted (splits AGAIN
on spaces inside a single name). Run it, watch a real filename get eaten
alive, then rewrite it using L2.3's `while read` pattern plus the quoting
reflex this whole phase drills.

## GUIDED STEPS

1. Read the claim, then look at what it's actually being asked to move:

       cat stage.sh
       cat manifest.txt
       ls -la

   `manifest.txt` lists three names — `alpha.txt`, `my report.txt` (note
   the space), and `subdir`. `stage.sh`:

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   # stage.sh — move every file listed in the manifest into the archive dir.
   manifest=$1
   archive=$2
   for f in $(cat $manifest); do        # $(cat) splits on IFS: every word, not every line
     mv $f $archive                     # unquoted $f: a spaced name splits into two args
   done
   echo staged
   ```

2. Run it and watch the manifest get word-split before your eyes:

       bash stage.sh manifest.txt archive

   captured output:

       mv: cannot stat 'my': No such file or directory
       mv: cannot stat 'report.txt': No such file or directory
       staged

   `$(cat manifest.txt)` didn't hand the loop 3 *lines* — it handed it 4
   *words* (`alpha.txt`, `my`, `report.txt`, `subdir`), because unquoted
   command substitution splits on `$IFS` same as any other unquoted
   expansion. `alpha.txt` and `subdir` happened to survive (no space in
   the name); `my report.txt` did not — the loop tried to `mv` two files
   named `my` and `report.txt` that don't exist, both calls failed loudly,
   and the real file was never touched. Confirm it:

       ls archive
       ls "my report.txt"

   `archive/` holds `alpha.txt` and `subdir/` — `my report.txt` is still
   sitting in the original directory, un-archived. And the script still
   printed `staged` and exited 0 — a second reminder (after Phase 2) that
   exit code and stdout don't audit themselves.

3. Two separate bugs, two separate fixes — name both before you touch the
   code:
   - the `for f in $(cat $manifest)` line splits the FILE into words —
     the fix is L2.3's pattern: `while IFS= read -r f; do … done < "$manifest"`
   - the `mv $f $archive` line splits EACH NAME again — the fix is
     quoting: `mv -- "$f" "$archive"/` (the `--` stops a name that starts
     with `-` from being read as an option — foreshadowing L3.4)

4. Edit `stage.sh` in place. Target shape (find your own edits — this is
   the goal, not a diff to paste):

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   manifest=$1
   archive=$2
   while IFS= read -r f; do
     [[ -n "$f" ]] || continue
     mv -- "$f" "$archive"/
   done < "$manifest"
   echo staged
   ```

5. Verify against a clean copy of the inputs (re-`cd` to a scratch copy or
   just re-run against what's left — a re-run only needs `my report.txt`
   still present, which it is):

       shellcheck stage.sh
       bash stage.sh manifest.txt archive
       ls archive

   Expect: shellcheck prints nothing, `staged` prints once, no `mv:`
   errors, and `archive/` now holds `my report.txt` — whole, with the
   space intact.

6. `lab check bash L3.1`
