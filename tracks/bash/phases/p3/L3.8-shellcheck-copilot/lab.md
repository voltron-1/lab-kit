## BRIEF
ShellCheck is a co-pilot, not a verdict. It emits dozens of codes — some
flag genuine security bugs (the exact bugs L3.1–L3.7 built labs around),
others are pure style. `sample.sh` is a script you never run — its whole
purpose is to trigger a spread of codes for you to read and sort into
**security-critical** (fix before shipping) versus **cosmetic** (style
only). The thesis: shellcheck-clean is necessary, not sufficient — some
real injection classes are invisible to it entirely.

## GUIDED STEPS

1. Read the script — do not run it, it's never meant to execute:

       cat sample.sh

   ```bash
   #!/bin/sh
   # TEACHING SAMPLE — intentionally flawed
   # sample.sh — a grab-bag of ShellCheck triggers to read and classify.
   dir=$1
   rm -rf "$dir/"                 # SC2115  (security-critical: empty $dir -> rm -rf /)
   cp $dir/*.log /backup          # SC2086  (security-critical: word-split/glob on untrusted path)
   rm *                           # SC2035  (security-critical: a -rf filename becomes a flag)
   files=`ls`                     # SC2006 (cosmetic: backticks) + SC2010/SC2012 (ls parsing, style)
   echo "found: $files"           # SC2086 on $files (context-dependent)
   if [ $# -gt 0 -a -n "$1" ]; then :; fi   # SC2166 (style: -a is legacy) + SC2086 on $#
   unused=42                      # SC2034 (cosmetic: unused variable)
   . ./site-config.sh              # SC1091 (informational: source target is missing/dynamic)
   ```

2. Run ShellCheck and read every line of its output:

       shellcheck -x -S style sample.sh

   captured output:

       In sample.sh line 5:
       rm -rf "$dir/"                 # SC2115  (security-critical: empty $dir -> rm -rf /)
              ^-----^ SC2115 (warning): Use "${var:?}" to ensure this never expands to / .

       In sample.sh line 6:
       cp $dir/*.log /backup          # SC2086  (security-critical: word-split/glob on untrusted path)
          ^--^ SC2086 (info): Double quote to prevent globbing and word splitting.

       In sample.sh line 7:
       rm *                           # SC2035  (security-critical: a -rf filename becomes a flag)
          ^-- SC2035 (info): Use ./*glob* or -- *glob* so names with dashes won't become options.

       In sample.sh line 8:
       files=`ls`                     # SC2006 (cosmetic: backticks) + SC2010/SC2012 (ls parsing, style)
             ^--^ SC2006 (style): Use $(...) notation instead of legacy backticks `...`.

       In sample.sh line 10:
       if [ $# -gt 0 -a -n "$1" ]; then :; fi   # SC2166 (style: -a is legacy) + SC2086 on $#
                     ^-- SC2166 (warning): Prefer [ p ] && [ q ] as [ p -a q ] is not well defined.

       In sample.sh line 11:
       unused=42                      # SC2034 (cosmetic: unused variable)
       ^----^ SC2034 (warning): unused appears unused. Verify use (or export if used externally).

       In sample.sh line 12:
       . ./site-config.sh              # SC1091 (informational: source target is missing/dynamic)
         ^--------------^ SC1091 (info): Not following: ./site-config.sh: openBinaryFile: does not exist (No such file or directory)

   Seven codes, seven lines. Notice what did *not* fire: `$files` on line 9 is
   already double-quoted, so no SC2086 there; `$#` on line 10 is a special
   parameter ShellCheck doesn't flag the same way. Read output precisely —
   don't assume every `$var` on a flagged line is itself the problem.

3. Classify each one — has this exact bug already cost a lab this phase,
   or is it purely cosmetic?

   - **SC2115** (line 5) — this is L3.2's catastrophe verbatim: an empty
     `$dir` turns `rm -rf "$dir/"` into `rm -rf /`. **Security-critical.**
   - **SC2086** (line 6) — this is L3.1's bug: an unquoted variable
     word-splits and globs. On an untrusted path, that's a real attack
     surface, not just a style nit. **Security-critical.**
   - **SC2035** (line 7) — this is L3.4's attack: `rm *` lets a file
     literally named `-rf` sort first and get parsed as flags.
     **Security-critical.**
   - **SC2006** (line 8) — backticks vs `$(...)`. Purely a readability /
     nesting preference. **Cosmetic.**
   - **SC2166** (line 10) — `[ … -a … ]` is a legacy, poorly-defined
     operator; prefer `[ … ] && [ … ]`. A portability/style nit, not
     something an attacker exploits. **Cosmetic** (not machine-graded
     this lab, but worth reading).
   - **SC2034** (line 11) — an unused variable. Dead code, not a
     vulnerability. **Cosmetic.**
   - **SC1090/SC1091** (line 12) — "can't follow source." `./site-config.sh`
     doesn't exist in this fixture, and more generally ShellCheck can't
     statically resolve a `source`/`.` target that's a variable or decided
     at runtime — that's normal, not a defect. This very lab's own
     `check.sh` sources a path from `$LAB_CHECKLIB` and silences the exact
     same warning with a `# shellcheck source=/dev/null` comment right
     above it (`cat check.sh` if you want to see it). **Informational, not
     a defect.**

4. Name a blind spot. ShellCheck emitted *zero* warnings on two of this
   phase's most dangerous scripts — L3.5's arithmetic command-substitution
   injection and L3.7's command-string re-parse (`eval`) — and it has no
   code for "you forgot `set -euo pipefail`" either (L2.8). A 100%-clean
   ShellCheck run tells you nothing about any of these.

5. Write `answers.txt`:

       sc2115=security
       sc2086=security
       sc2035=security
       sc2034=cosmetic
       sc2006=cosmetic
       blindspot=eval injection

   (`blindspot=` accepts naming any one of: the L3.7 re-parsing construct,
   arithmetic injection, or a missing strict-mode preamble.)

6. `lab check bash L3.8`
