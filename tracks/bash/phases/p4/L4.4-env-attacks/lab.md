## BRIEF
`healthcheck.sh` is installed by a monitoring agent and runs from cron —
often as root. It checks whether `acme-agent` is running by calling `ps`.
As long as `PATH` only ever points at trusted directories, this looks
harmless. It isn't: the script's own `PATH` assignment puts the *current
directory* first, and cron jobs commonly run from group-writable spool
directories. Anyone who can drop a file named `ps` in that directory gets
it executed instead of the real `ps` — with whatever privilege the cron
job has. This is **CWE-426, untrusted search path**. `IFS` is the sibling
footgun in this family: a hostile inherited `IFS` re-steers how unquoted
expansions split (L3.3), the same way a hostile `PATH` re-steers which
program a bare command name resolves to.

## GUIDED STEPS

1. Read the script:

       cat healthcheck.sh

   ```bash
   #!/usr/bin/env bash
   # TEACHING SAMPLE — intentionally flawed
   # healthcheck.sh — installed by the agent; runs from cron as root.
   # CWD at run time is /var/spool/acme, which is group-writable.
   PATH=.:/usr/local/bin:$PATH
   if ps aux | grep -q acme-agent; then
     exit 0
   fi
   logger "acme-agent not running"
   ```

   Line 5 is the flaw: `.` — the current directory — is searched **first**,
   ahead of every trusted directory in the inherited `PATH`.

2. Confirm ShellCheck's take:

       shellcheck healthcheck.sh

   captured output:

       In healthcheck.sh line 6:
       if ps aux | grep -q acme-agent; then
          ^----^ SC2009 (info): Consider using pgrep instead of grepping ps output.

   ShellCheck found *something* — but it's a style suggestion about parsing
   `ps` output, not the security bug. The `PATH` line gets no warning at
   all. Don't mistake "ShellCheck said something" for "ShellCheck found
   the flaw" — SC2009 here is a distractor, not the lesson (same idea as
   L3.8's security-vs-cosmetic triage).

3. Demonstrate it. Drop a decoy `ps` in the current directory — standing in
   for the group-writable spool dir — and run the script exactly as cron
   would, with `.` leading the inherited `PATH`:

       printf 'touch marker\n' > ps
       chmod +x ps
       PATH=".:$PATH" bash healthcheck.sh; echo "rc=$?"
       ls marker

   captured output:

       rc=0
       marker

   `healthcheck.sh` never called the real `ps`. It ran whatever file named
   `ps` happened to be first on the search path — in this demo, a
   one-line script that just touched a file, but it could be anything,
   running with the cron job's own privilege.

4. Name the flaw. Write `answers.txt`:

       line=5
       flaw=untrusted-search-path
       cwe=CWE-426
       fix=pin an absolute, minimal PATH with no current-directory entry
       also=IFS

5. Author `hardened.sh` from scratch — pin an absolute, minimal `PATH`
   before any command lookup happens, so the inherited value never
   matters:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   PATH=/usr/bin:/bin   # absolute, minimal — no . and no inherited entries survive
   if pgrep -x acme-agent > /dev/null; then
     exit 0
   fi
   logger "acme-agent not running"
   ```

       shellcheck hardened.sh

   Expect no warnings — switching to `pgrep` also clears the SC2009
   distractor from step 2, though that was never the actual fix.

6. Prove it resists the same attack — a decoy `pgrep` this time, same
   poisoned `PATH`:

       rm -f marker
       printf 'touch marker\nexit 1\n' > pgrep
       chmod +x pgrep
       PATH=".:$PATH" bash hardened.sh; echo "rc=$?"
       ls marker 2>&1

   captured output:

       rc=0
       ls: cannot access 'marker': No such file or directory

   `marker` was never created — `hardened.sh` pinned its own `PATH` before
   ever looking up `pgrep`, so the decoy in the current directory was
   never even considered.

7. `lab check bash L4.4`
