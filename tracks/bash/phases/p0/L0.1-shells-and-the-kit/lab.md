## BRIEF
You already live in a shell — today you learn to name it. `$$` is this
shell's own PID; asking `ps` about that PID names the shell you're
actually in. Second fact, the one L0.3 is funded by: on Debian/Ubuntu
`/bin/sh` is dash, NOT bash — a script that works in your terminal can
die under `sh`. Then install the track's two co-pilots: ShellCheck (the
closest thing to a compiler Bash will ever give you) and shfmt. Every
graded artifact is one redirected command inside `workspace/bash/L0.1/`.

## GUIDED STEPS

1. Name your shell.

       ps -p $$ -o comm=

   expect:

       bash

   `$$` expands to the current shell's own PID before `ps` ever runs.

       echo "$BASH_VERSION"

   expect (a bash-only variable — empty under dash):

       5.2.21(1)-release

2. The reveal.

       readlink -f /bin/sh

   expect:

       /usr/bin/dash

   On Debian/Ubuntu, `sh` is NOT bash — remember this.

3. Install the co-pilots.

       sudo apt-get update && sudo apt-get install -y shellcheck shfmt

   Don't paste the full transcript — just confirm the last lines look
   like this shape (already installed on this machine):

       shellcheck is already the newest version (0.9.0-1).
       shfmt is already the newest version (3.8.0-1).

   On a machine without them yet, the shfmt line instead reads something
   like `Setting up shfmt (3.8.0-1) ...`.

4. Leave evidence — four redirects, run from inside the workspace root:

       ps -p $$ -o comm= > shell.txt
       readlink -f /bin/sh > sh-target.txt
       shellcheck --version > shellcheck.txt
       shfmt --version > shfmt.txt

5. First taste of silence = clean.

       bash hello.sh

   expect:

       hello from the bash track

       shellcheck hello.sh

   expect: nothing. Silence IS the pass state.

6. Grade it.

       lab check bash L0.1
