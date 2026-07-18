## BRIEF
`stage-upload.sh` moves an uploaded file — named by whoever uploaded it —
into a shared `staging/` directory. As long as filenames only ever contain
letters, this looks harmless. It isn't: a filename beginning with `-` is
not a path to `mv` at all, it's an **option**. `mv` has a `-t DIRECTORY`
flag whose argument can be bundled directly after it (`-tDIR`, no space),
so an uploaded "file" named `-t<anywhere-writable>` doesn't get moved
anywhere — it *redirects the move itself*, silently relocating the entire
`staging/` directory (everyone else's uploads included) to a location the
uploader chose. This is **CWE-88, argument injection**: untrusted input
read as an option to a program instead of as data. The same class of bug
turns `tar --checkpoint-action=exec=…` and `rsync -e …` into remote code
execution elsewhere. This demo stays entirely inside your lab workspace —
the "attacker directory" is just another folder here — so there is
nothing to fence.

## GUIDED STEPS

1. Read the script:

       cat stage-upload.sh

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   # stage-upload.sh — move an uploaded file (named by the client) into staging.
   f=$1                                          # UNTRUSTED filename from an upload form
   mv "$f" staging/                              # no --: an attacker-chosen "-t..." is parsed as an mv OPTION
   ```

   Line 5 is the flaw. `$f` is quoted — word-splitting isn't the issue
   here — but nothing tells `mv` where options end and paths begin. If
   `$f` starts with `-`, `mv` reads it as a flag, not a filename.

2. Confirm ShellCheck's take:

       shellcheck stage-upload.sh

   captured output: *(nothing — clean, no warnings)*

   Another blind spot: ShellCheck has no check for "this argument might be
   read as an option instead of data."

3. Normal use first:

       mkdir -p staging
       touch normal-upload.txt
       bash stage-upload.sh normal-upload.txt
       ls staging/

   captured output:

       normal-upload.txt

4. Now the injection — an uploader whose chosen filename is
   `-texfil-target/` (no space: `mv` accepts `-t`'s directory argument
   bundled directly onto the flag):

       mkdir -p exfil-target
       bash stage-upload.sh "-texfil-target/"; echo "rc=$?"
       ls staging/ 2>&1
       find exfil-target -type f

   captured output:

       rc=0
       ls: cannot access 'staging/': No such file or directory
       exfil-target/staging/normal-upload.txt

   `staging/` is gone from where it belongs. `-texfil-target/` was never
   treated as a filename at all — `mv` read it as `-t exfil-target/`,
   which means "the target directory is `exfil-target/`," leaving
   `staging/` (the only remaining argument) as the thing to move *into*
   it. The entire staging area — every upload in it — just relocated to a
   directory the "uploader" named. Nothing was deleted; it was
   **redirected**, which is exactly what makes this so easy to miss: no
   error, no crash, just files ending up somewhere else.

5. Name the flaw. Write `answers.txt`:

       line=5
       flaw=argument-injection
       cwe=CWE-88
       fix=mv -- "$f" staging/  (end-of-options guard)

6. Author `hardened.sh` from scratch — one token fixes it: `--` tells
   `mv` that everything after it is a path, never an option:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   f=$1
   mv -- "$f" staging/   # -- ends option parsing; $f is always treated as a path, never as an mv flag
   ```

       shellcheck hardened.sh

   Expect no warnings.

7. Prove it rejects the injection — rebuild `staging/` with something in
   it first, so a redirect would be obvious:

       mkdir -p staging exfil-target2
       touch staging/existing.txt
       bash hardened.sh "-texfil-target2/"; echo "exit=$?"
       ls staging/
       find exfil-target2 -type f

   captured output:

       mv: cannot stat '-texfil-target2/': No such file or directory
       exit=1
       existing.txt

   `mv` failed cleanly — with `--` in place, `-texfil-target2/` is just a
   path, and no file by that literal name exists. `staging/` never moved;
   `exfil-target2/` stays empty. The attack surface is gone, not just
   quieter.

8. Prove a *genuinely* dash-prefixed upload still works — the fix must
   not reject valid filenames that happen to start with `-`, only stop
   them from being read as options:

       touch -- "-flag.txt"
       bash hardened.sh "-flag.txt"; echo "exit=$?"
       ls staging/

   captured output:

       exit=0
       -flag.txt
       existing.txt

9. Prove ordinary use still works:

       touch another-upload.txt
       bash hardened.sh another-upload.txt; echo "exit=$?"
       ls staging/

   captured output:

       exit=0
       -flag.txt
       another-upload.txt
       existing.txt

10. `lab check bash L4.3`
