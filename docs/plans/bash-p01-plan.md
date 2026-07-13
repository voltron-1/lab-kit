# BASH TRACK — Phase 0 + Phase 1 Build Plan (v1)

Binding content spec: `docs/curriculum/bash-literacy-lab-curriculum-v1.md` (Phase 0 +
Phase 1 sections). Binding mechanical spec: `docs/kit-contracts.md`. Reference
implementation of every file format: `tracks/demo/phases/p0/L0.0-meet-the-kit/`.
This plan is the single source of design judgment for the build session — build it
mechanically; where reality contradicts a claim marked `[VERIFY-AT-BUILD]`, fix the
content to match reality and note the deviation in the build report.

Plan-time machine baseline (2026-07-13): Ubuntu 24.04.4 LTS on WSL2 · bash
5.2.21(1)-release · `/bin/sh -> /usr/bin/dash` · shellcheck 0.9.0 (installed) ·
shfmt NOT installed (apt candidate 3.8.0-1) · GNU coreutils. Every expected
output in §4 was executed and captured on this baseline by a verification agent
at plan time unless tagged `[VERIFY-AT-BUILD]`.

## 1. Lab list (from the map, exactly)

| id | title (meta.json `title`, backticks stripped) | type | gate | est_minutes | dir slug |
|---|---|---|---|---|---|
| L0.1 | Shells and the kit — which shell am I in, install ShellCheck & shfmt | GUIDED | false | 15 | `L0.1-shells-and-the-kit` |
| L0.2 | Meet the lab CLI — start, check, resume | GUIDED | false | 10 | `L0.2-meet-the-lab-cli` |
| L0.3 | Reading the shebang — #!/bin/bash vs #!/bin/sh vs dash, and why it matters | DECODE | **true** | 15 | `L0.3-reading-the-shebang` |
| L1.1 | Commands are just words — the shell splits, then runs | PREDICT | false | 10 | `L1.1-commands-are-words` |
| L1.2 | Variables — $VAR, ${VAR}, and when braces matter | PREDICT | false | 10 | `L1.2-variables-and-braces` |
| L1.3 | The unquoted variable — word splitting, the #1 Bash bug | PREDICT | false | 15 | `L1.3-the-unquoted-variable` |
| L1.4 | Quoting — single vs double vs none, decided by what you want expanded | PREDICT | false | 15 | `L1.4-quoting` |
| L1.5 | Globbing — * ? [...] and pathname expansion | PREDICT | false | 15 | `L1.5-globbing` |
| L1.6 | Exit codes — $?, and "success" is 0 (backwards from every language you know) | DECODE | false | 15 | `L1.6-exit-codes` |
| L1.7 | Command substitution — $(...) and reading nested commands | PREDICT | false | 15 | `L1.7-command-substitution` |
| L1.8 | Phase gate: predict the output of an expansion-heavy script, line by line | PREDICT | **true** | 20 | `L1.8-phase-gate-expansion` |

Gate placement judgment: the map marks L1.8 explicitly. Phase 0's exit-gate sentence
("given any script, you can say what interpreter it targets and whether bash-only
features will break under `/bin/sh`") is exactly L0.3's content, and demo + rust
precedent put `gate: true` on the phase-final lab — so L0.3 carries `gate: true`.

recall.json placement: **L1.1 only** (5 questions drawn from Phase 0, per the
spaced-recall contract; L0.1 gets none — no earlier phase exists in this track, and
the kit lints only recall.json's *position*, not its presence). L1.8's entry also
drafts L2.1's recall.json so the Phase-2 build session inherits it. Directory layout
per lab is fixed by `docs/kit-contracts.md`:
`tracks/bash/phases/p<N>/<slug>/{meta.json,lab.md,quiz.json,check.sh,hints.json,recap.md[,files/,recall.json]}`.
`tracks/bash/track.json` already exists (title, tagline, all eight phase names) — do
not touch it.

## 2. Binding harness constraints (why every check in §4 looks the way it does)

1. **The fence.** `lab check` runs check.sh as a separate process, cwd-pinned to
   `workspace/bash/<id>/`, under `env -i` with `PATH=/usr/local/bin:/usr/bin:/bin`,
   `HOME=<ws>/.home`, `TMPDIR=<ws>/.tmp`, stdin `/dev/null`, `timeout 120s`. All
   checklib path helpers realpath-guard into the workspace. There is no OS sandbox —
   `tools/lint-labs.sh` is the compensating control and every check.sh must pass it.
2. **Artifact-based grading.** Graded evidence is (a) `key=value` answer files,
   (b) learner-redirected command output files, (c) workspace scripts executed via
   `bash -- <file>` (allowed; `bash -c` is lint-banned). shellcheck sits on the fence
   PATH (`/usr/bin`), but no P0/P1 check.sh invokes it — shellcheck evidence is graded
   from learner-redirected output files instead. Every check is CI-fabricatable with
   bash + coreutils alone (echo the artifacts) — this keeps `tests/acceptance.sh`
   green on any machine.
3. **lint-labs.sh bans** (check.sh only): absolute-path literals (match `'dash$'`,
   never `/usr/bin/dash`), `eval`, `sudo`, `curl`, `wget`, ` nc `, `ssh `, `sh -c`,
   `bash -c`, `pushd`, `cd ..`/`cd ~`; mode 0644; `set -euo pipefail` +
   LAB_WORKSPACE/LAB_CHECKLIB guards + `source "$LAB_CHECKLIB"` mandatory;
   collect-all style; `ck_summary` is the last line. `# shellcheck disable=` is
   banned repo-wide.
4. **File contracts:** quiz.json exactly 3 questions; hints.json exactly 3 levels
   (level 1 never reveals); recap.md exactly 3 lines, no bullet prefix; lab.md has
   exactly the headings `## BRIEF` (≤10 lines of text) and `## GUIDED STEPS`;
   meta.json `{id,title,type,objective,gate,est_minutes}` with `id` equal to the
   directory id. Answers are base64 (`printf '%s' 'answer' | base64 -w0`); text
   answers stored lowercase with `accept_b64` variants where phrasing varies.
5. **Quiz I/O:** one line per question from stdin, no reprompting —
   `printf 'a\nb\nc\n' | lab check bash <id>` must behave identically to typing.
   recall runs at `lab start` on phase openers only and never gates.
6. **Bash-track quality gates (PROMPTS.md):** everything shipped is
   shellcheck-clean; deliberately flawed teaching samples carry the exact header
   `# TEACHING SAMPLE — intentionally flawed` (line 2) and list their expected SC
   codes in meta.json as `"teaching_samples": {"files/<name>": ["SCxxxx", ...]}`
   (an additive meta field; the lint checks required fields only —
   `tools/shellcheck-all.sh` skips files carrying the header). Destructive-command
   containment (decoy trees) is **[FUTURE-PHASE-ONLY]** — Phase 0–1 ships zero
   destructive commands.

## 3. Track-wide conventions (decided here, applied to all 11 labs)

- **Answer files.** PREDICT labs grade `predictions.txt`; DECODE labs grade
  `answers.txt`. `key=value` lines, no spaces around `=`, exact lowercase keys
  (`p1…`, `q1…`), created by the learner in the workspace root. Conceptual questions
  are lettered multiple choice printed in lab.md (learner writes `q1=b`); observable
  values are exact tokens. check.sh greps anchored ERE (`'^q1=b$'`) — except values
  containing ERE metacharacters (`< > | [ ] * ? ( )`), which use
  `assert_file_contains_fixed` on the full `pN=…` line.
- **The argv printer.** Every PREDICT lab ships `files/argv.sh`, byte-identical
  across labs — the track's oscilloscope for word splitting:

  ```bash
  #!/usr/bin/env bash
  # argv.sh — prints: <number of arguments>|<each argument in angle brackets>
  out=""
  for a in "$@"; do
    out+="<${a}>"
  done
  printf '%s|%s\n' "$#" "$out"
  ```

  Output format: `bash argv.sh a "b c"` → `2|<a><b c>`; zero arguments → `0|`.
  Learners predict that exact line, so word splitting becomes a graded, visible
  fact instead of an assertion. (A bare `printf '<%s>' "$@"` prints a misleading
  `<>` for zero args — the loop form is deliberate.)
- **Scripts run as `bash <name>`, never `./<name>`** — no reliance on exec bits
  surviving the `files/` copy, and it reinforces "the interpreter is a program that
  reads words." The one deliberate exception is L0.3's *discussion* of `./x`, where
  the shebang is the concept (the lab still runs everything via `bash`/`dash`
  explicitly).
- **PREDICT protocol.** lab.md prints every sample line; the learner writes ALL
  predictions into `predictions.txt` before running anything, then runs each line
  and compares. BRIEF carries the honor line once per lab: "the check can't tell
  whether you predicted first — you're only cheating your own reps." PREDICT lab.md
  never reveals expected values; hint L3 says "run it and transcribe" (the run is
  the legitimate answer source). Typed sample lines are not shellcheck targets;
  every `files/*.sh` is.
- **ShellCheck bar.** Every shipped `files/*.sh` with clean intent produces ZERO
  output from `shellcheck -x -S style` (0.9.0) — verified at plan time both bare and
  with a `shell=bash` rc adjacent. Flawed samples carry the exact
  `# TEACHING SAMPLE — intentionally flawed` header (line 2) and their verified SC
  codes in meta.json `teaching_samples`. The repo-root `.shellcheckrc` contains
  `shell=bash` and shellcheck discovers rc files upward from the target's directory,
  so workspace runs inherit it — dialect-sensitive demos pass `-s` explicitly
  (command line beats rc; L0.3 states the verified precedence rule).
- **Hints ladder shape** (all labs): L1 = which artifact/step to look at, never
  content; L2 = narrows to the exact line/command and expected shape; L3 =
  near-answer procedure (for PREDICT labs L3 says "run it and transcribe" — never
  prints prediction values).
- **Quiz vs answers separation.** quiz.json questions never duplicate the graded
  answer-file questions verbatim; same concept, different angle.
- **Determinism.** All shipped filenames are lowercase ASCII so C and en_US.UTF-8
  glob/collation order agree. Where a glob is predicted, the entry pins the exact
  workspace inventory at glob time (including argv.sh and the learner's own
  predictions.txt). No graded value depends on date/time/hostname/locale; the only
  $(pwd)-derived value is the workspace basename (`workspace/bash/<id>` → `<id>`).
- **Workspace hygiene.** Learner work happens in `workspace/bash/<id>/`; repo-root
  `.gitignore` already covers `/workspace/` (verified at plan time — the demo track's
  workspace is untracked).
- **meta.json `objective`** given per lab in §4; titles exactly as §1.

## 4. Lab entries

---

### L0.1 — Shells and the kit — which shell am I in, install ShellCheck & shfmt
**GUIDED · gate:false · est 15 · files/: hello.sh · recall.json: no**
**objective:** "Identify the shell you are running, prove /bin/sh is dash on this OS, and install ShellCheck and shfmt, leaving four redirected evidence files in the workspace."

**BRIEF gist (builder expands to ≤10 lines):** You already live in a shell — today you
learn to name it. `$$` is this shell's own PID; asking `ps` about that PID names the
shell you're actually in. Second fact, the one L0.3 is funded by: on Debian/Ubuntu
`/bin/sh` is dash, NOT bash — a script that works in your terminal can die under `sh`.
Then install the track's two co-pilots: ShellCheck (the closest thing to a compiler
Bash will ever give you) and shfmt. Every graded artifact is one redirected command
inside workspace/bash/L0.1/.

**files/hello.sh:**
```bash
#!/usr/bin/env bash
# hello.sh — the track's first script: clean, so shellcheck says nothing
printf 'hello from the bash track\n'
```

**TEACHING ARTIFACT (each command → real expected output on the baseline machine):**

1. `ps -p $$ -o comm=` → `bash` — `$$` expands to the current shell's PID before `ps`
   ever runs; `-o comm=` prints that process's executable name with the header
   suppressed. `comm` is the kernel's own name for the process (the value in
   /proc/PID/comm — not argv[0]), so even a login shell (argv[0] `-bash`) prints
   exactly `bash` — which is why check.sh can anchor `^bash$`.
2. `echo "$BASH_VERSION"` → `5.2.21(1)-release` `[VERIFY-AT-BUILD]` — a variable only
   bash sets; under dash it would be empty (light foreshadow, one clause in lab.md).
3. `readlink -f /bin/sh` → `/usr/bin/dash` — the raw symlink is just `dash`; `-f`
   canonicalizes the whole chain (usr-merge makes /bin itself a symlink), landing on
   /usr/bin/dash. One sentence in lab.md: on Debian/Ubuntu, sh is NOT bash — remember this.
4. `sudo apt-get update && sudo apt-get install -y shellcheck shfmt` — learner shell
   only (sudo+network allowed there, never in check.sh). Do NOT paste the transcript;
   show only the two last-line shapes: `shellcheck is already the newest version (0.9.0-1).`
   `[VERIFY-AT-BUILD]` and `Setting up shfmt (3.8.0-1) ...` `[VERIFY-AT-BUILD]`.
5. `ps -p $$ -o comm= > shell.txt` → no terminal output; shell.txt holds the single
   line `bash`.
6. `readlink -f /bin/sh > sh-target.txt` → sh-target.txt holds `/usr/bin/dash`.
7. `shellcheck --version > shellcheck.txt` → shellcheck.txt holds exactly 4 lines:
   ```
   ShellCheck - shell script analysis tool
   version: 0.9.0
   license: GNU General Public License, version 3
   website: https://www.shellcheck.net
   ```
8. `shfmt --version > shfmt.txt` → shfmt.txt holds `v3.8.0` `[VERIFY-AT-BUILD — shfmt
   not installed at plan time; check pattern also tolerates a bare 3.8.0]`.
9. `bash hello.sh` → `hello from the bash track`.
10. `shellcheck hello.sh` → NO output, exit 0. The lab.md line, verbatim concept:
    shellcheck prints nothing when a script is clean — silence is the pass state.
11. `lab check bash L0.1`.

**SHELLCHECK STATUS:** files/hello.sh — clean: zero output from `shellcheck -x -S style`
(0.9.0), verified at plan time; plain `shellcheck hello.sh` is also silent (the repo-root
`.shellcheckrc` `shell=bash` applies inside workspace/, and hello.sh's shebang says bash
anyway, so both agree). No flawed samples ship with this lab. The command lines typed in
lab.md are not shellcheck targets.

**SANDBOX NOTE:** every write lands inside workspace/bash/L0.1/ (shell.txt,
sh-target.txt, shellcheck.txt, shfmt.txt — plus nothing else). System READS only:
`ps` on the shell's own PID, `readlink` on /bin/sh, and the two `--version` queries.
The single sudo/network action (step 3 apt install) runs in the learner's own shell —
check.sh never installs anything, it only greps the four evidence files. No destructive
commands anywhere in this lab; decoy-tree tooling is [FUTURE-PHASE-ONLY] (Phase 3+).

**GUIDED STEPS outline (11 commands total):**
1. Name your shell: `ps -p $$ -o comm=` (expect `bash`), then `echo "$BASH_VERSION"`
   (expect `5.2.21(1)-release`-shaped). One line of prose: `$$` = this shell's PID.
2. The reveal: `readlink -f /bin/sh` (expect `/usr/bin/dash`). One sentence: on
   Debian/Ubuntu, sh is NOT bash — remember this.
3. Install the co-pilots: `sudo apt-get update && sudo apt-get install -y shellcheck shfmt`
   (last-line shapes shown per TEACHING ARTIFACT #4; no full transcript).
4. Leave evidence — four redirects run from the workspace root:
   `ps -p $$ -o comm= > shell.txt` · `readlink -f /bin/sh > sh-target.txt` ·
   `shellcheck --version > shellcheck.txt` · `shfmt --version > shfmt.txt`.
5. First taste of silence = clean: `bash hello.sh` (it greets), then `shellcheck hello.sh`
   — it prints nothing; that IS the pass state.
6. `lab check bash L0.1`.

**CHECK LOGIC (check.sh):** standard preamble (shebang, `set -euo pipefail`,
LAB_WORKSPACE/LAB_CHECKLIB guards, `source "$LAB_CHECKLIB"`, mode 0644), then exactly:
```bash
assert_file_contains "shell.txt" '^bash$' \
  'step 4 — run: ps -p $$ -o comm= > shell.txt from inside the workspace'
assert_file_contains "sh-target.txt" 'dash$' \
  'step 4 — sh-target.txt must name where the sh symlink resolves: rerun the step-4 readlink redirect'
assert_file_contains "shellcheck.txt" '^version: [0-9]+\.' \
  'step 4 — run: shellcheck --version > shellcheck.txt (step 3 installs the tools)'
assert_file_contains "shfmt.txt" '^v?3\.' \
  'step 4 — run: shfmt --version > shfmt.txt (fails? the step 3 install did not finish)'
ck_summary
```
Builder notes: the `$$` in hint 1 MUST stay single-quoted (double quotes would expand it
to the grader's PID); the sh-target pattern is `dash$` and its hint deliberately never
spells `/bin/sh` — both the pattern AND hint text are subject to the absolute-path-literal
lint ban; the word "sudo" must not appear anywhere in check.sh (banned token), so the
shfmt hint says "install" without naming the command.
CI fabrication (acceptance tests, bash+coreutils only): `printf 'bash\n' > shell.txt;
printf '/usr/bin/dash\n' > sh-target.txt; printf 'version: 0.9.0\n' > shellcheck.txt;
printf 'v3.8.0\n' > shfmt.txt`.

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "In `ps -p $$ -o comm=`, what does `$$` expand to?" a) the exit code of the
   last command b) the PID of the shell you are running c) the number of arguments the
   shell was given → **b**
2. text — "You run shellcheck on a script; it prints nothing and exits 0. In one word,
   what is the script's status?" → **clean** (accept: `pass`, `passed`, `ok`)
3. choice — "A script pastes fine into your bash terminal but dies when a container runs
   it with /bin/sh. Likeliest reason?" a) /bin/sh on Debian/Ubuntu is dash — bash-only
   syntax doesn't exist there b) /bin/sh refuses files without the execute bit c) the
   container strips environment variables → **a**

**RECAP:**
```
ps -p $$ -o comm= names your shell; $$ is that shell's own PID
/bin/sh on Debian/Ubuntu is dash, not bash — bash-only syntax dies under sh
shellcheck silence = clean; ShellCheck and shfmt ride along for the whole track
```

**HINTS:** L1: the grader reads exactly four files — shell.txt, sh-target.txt,
shellcheck.txt, shfmt.txt; `ls` the workspace and compare against step 4: one is
missing, empty, or misspelled. L2: each file is one step-4 command redirected with `>`
from inside workspace/bash/L0.1 — shell identity into shell.txt, the resolved sh
symlink into sh-target.txt, each tool's `--version` into its own file; if shfmt.txt is
the failure, run `shfmt --version` by itself first — "command not found" means the
step-3 install didn't finish. L3: replay verbatim from the workspace:
`ps -p $$ -o comm= > shell.txt; readlink -f /bin/sh > sh-target.txt; shellcheck --version > shellcheck.txt; shfmt --version > shfmt.txt` — then `lab check bash L0.1`.

---

### L0.2 — Meet the lab CLI — start, check, resume
**GUIDED · gate:false · est 10 · files/: kit-notes.txt · recall.json: no**
**objective:** "Drive every lab CLI mechanic once — status marks, the hint ladder, key=value answer files, the workspace fence, and resume — so the kit itself never slows down a later lab."

**BRIEF gist (builder expands to ≤10 lines):** L0.1 proved the toolchain; this lab proves the kit. Drive each mechanic once — status, hints, a graded answer file, the fence proof, check — so no later lab is your first contact with the machinery. Everything you touch lives in `workspace/bash/L0.2/`, the same fence Phase 3's footgun labs detonate inside. A failed check costs nothing but a rerun; a spent hint costs nothing but a look. Two track conventions debut here and never change: graded answers are key=value lines (exact lowercase keys, no spaces around `=`) and scripts run as `bash <script>`. Stuck? `lab hint bash L0.2`.

**files/kit-notes.txt** (plain text, NOT a script — 16 fact lines + 2 blanks, 18 lines, byte-exact; every graded answer and every quiz answer is a line in it):
```
KIT NOTES — every graded answer in this lab is a line in this file.

The lab CLI has five verbs:
  lab status              the phase map: every lab, its mark, what's next
  lab start <track> <id>  opens a lab — prints the brief, seeds the workspace
  lab check <track> <id>  grades a lab — runs check.sh, then a 3-question quiz
  lab hint <track> <id>   climbs the hint ladder one level per run
  lab resume              replays your last recap card and names the next lab

Re-entry after any gap — a day or a month — is: lab resume.
The check is all-or-nothing: grader passing AND quiz 3/3. A 2/3 quiz
fails the whole check; nothing is lost, you just rerun lab check.
The hint ladder has exactly 3 levels. Level 1 never gives the answer.
Status marks: ✓ passed · ▶ in progress · ○ not done · ⏭ skipped.
⏭ is permanent: a lab you forced past with --force never becomes ✓.
This track grades key=value answer lines. The grader greps for the exact
line: lowercase keys, no spaces around = — q1=b passes, Q1 = b fails.
This track runs every script as: bash <script> — never ./script.
```

**TEACHING ARTIFACT:** pinned state for every transcript: L0.1 passed, `lab start bash L0.2` already run (workspace seeded, status `in_progress`), nothing forced, zero hints spent, bash the only installed track. All output below was verifier-executed against `bin/lab` + `lib/*.sh` + `harness/checklib.sh` with this lab's real content and stub siblings; only values that depend on a sibling entry's meta are tagged `[VERIFY-AT-BUILD]`.

0. Precondition — `lab start bash L0.2` (from the repo root) printed the brief card, shape per `lib/render.sh:render_brief` (verified: the card opens with a blank line, and `catalog_lab_dir` resolves `$LAB_ROOT`-absolute, so the steps line prints the machine's absolute repo path — never a relative `tracks/...`):
   ```

   bash L0.2 — Meet the lab CLI — start, check, resume   GUIDED · ~10 min
   --------------------------------------------------------------
   objective  Drive every lab CLI mechanic once — status marks, the hint ladder, key=value answer files, the workspace fence, and resume — so the kit itself never slows down a later lab.
   workspace  workspace/bash/L0.2/

   BRIEF
   <the lab.md BRIEF block>

   steps  less <repo-root>/tracks/bash/phases/p0/L0.2-meet-the-lab-cli/lab.md
   next   lab check bash L0.2   (after finishing the GUIDED STEPS)
   ```
   No recall quiz fires — L0.2 is not a phase opener.

1. `lab status` (repo root) → the board, per `render_status`/`render_status_track`. The graded teaching beat is the ▶ on this lab's row. The L0.2 row is verified byte-exact (printf pads by **bytes**: the em-dash title is 41 UTF-8 bytes, `%-42s` adds 1 pad space, then the empty 4-byte GATE column → exactly 7 spaces before `~10m`); sibling rows take their spacing from their own titles `[VERIFY-AT-BUILD]`:
   ```
   LAB-KIT — status
   ══════════════════════════════════════════════════════════

   bash · Bash Literacy Lab   1 ✓ · 0 ⏭ · 10 ○  (1/11)
     p0 · Toolchain & Kit
       ✓  L0.1   <L0.1 title>  ~<L0.1 est>m
       ▶  L0.2   Meet the lab CLI — start, check, resume       ~10m
       ○  L0.3   <L0.3 title>  GATE ~<L0.3 est>m
     p1 · The Expansion Model
       ○  <eight rows, L1.1–L1.8>

   --------------------------------------------------------------
   ✓ passed   ▶ in progress   ○ not done   ⏭ forced (--force, never ✓)
   next: bash L0.2 — Meet the lab CLI — start, check, resume   run: lab start bash L0.2
   ```
   Sibling titles/ests come from their own entries `[VERIFY-AT-BUILD]`; track title "Bash Literacy Lab" is verified from the committed `tracks/bash/track.json`. Counts are exact for the pinned state: 11 labs installed (3+8), 1 passed → `1 ✓ · 0 ⏭ · 10 ○  (1/11)`. Footer names L0.2 because the frontier is the first non-completed lab and `in_progress` is not completed (verified). Caveat, verified: `catalog_tracks` orders by track.json `.order` — demo is 0, bash is 20 — so if the shipped zip installs tracks/demo with an unfinished L0.0, the demo block renders FIRST and the footer names `next: demo L0.0`, not bash L0.2; this transcript pins a bash-only install `[VERIFY-AT-BUILD: shipped zip contents]`.

2. `cd workspace/bash/L0.2` then `ls` → exactly:
   ```
   kit-notes.txt
   ```
   (`lab start` copies only `files/`; the fence dirs it also creates are dot-hidden). `cat kit-notes.txt` → the files/ block above, verbatim.

3. `lab hint bash L0.2` → byte-exact given hints.json below and zero hints spent (`lib/hints.sh:hint_next`, print-then-bump; leading blank line included; verified by execution):
   ```

   [hint 1/3] bash L0.2
     The grader wants exactly two files, both named in steps 4-5: answers.txt and location.txt. ls the workspace and compare it against the step list.

   (2 hints remaining — run lab hint bash L0.2 again for the next)
   ```
   Mechanism beat for lab.md: the level is persisted only after printing, a rerun shows `[hint 2/3]` (verified), and level 1 named artifacts, not answers. (If the builder rewords hints.json, the lab.md sample must show only the `[hint 1/3]` header + trailer shape, not stale hint text.)

4. `cat > answers.txt`, type three lines, finish with Ctrl-D on its own line; verify with `cat answers.txt` →
   ```
   q1=b
   q2=3
   q3=b
   ```
   These correct values are for the builder/grader only — lab.md prints the three questions with lettered options (see GUIDED STEPS outline), never the answer lines.

5. `pwd > location.txt` → no stdout; the file holds one absolute path ending `workspace/bash/L0.2` (prefix machine-variant). check.sh compares `realpath` canonical forms against `$LAB_WORKSPACE`, never a path literal. (Verified both ways: workspace pwd passes check [4]; a repo-root pwd fails it with the step-5 hint.)

6. `lab check bash L0.2` → exact transcript given the check.sh/quiz.json/recap.md below, verified by execution (learner keystrokes follow each `  > `; ✓ is ANSI-green on a tty, same text piped):
   ```

   checks — bash L0.2
   --------------------------------------------------------------
     ✓  [1] answers.txt matches: ^q1=b$
     ✓  [2] answers.txt matches: ^q2=3$
     ✓  [3] answers.txt matches: ^q3=b$
     ✓  [4] location.txt was written from inside the workspace
   checks 4/4

   quiz — 3 questions
   --------------------------------------------------------------
   Q1. A lab shows ⏭ in lab status. You go back, do the work, and pass its check. Its mark becomes…
         a) ✓ — a pass always upgrades the mark
         b) ▶ — in progress until the next lab passes
         c) ⏭ — skipped is permanent; it never becomes ✓
     > c
   Q2. Which command replays your last recap card?
     > lab resume
   Q3. Why must an answer line be exactly q1=b, never Q1 = b?
         a) style preference — the grader normalizes case and spacing
         b) check.sh greps the anchored pattern ^q1=b$ — any other spelling doesn't match and the check fails
         c) the CLI rewrites the file before grading
     > b

   quiz: 3/3

   RESULT: PASS — bash L0.2 · Meet the lab CLI — start, check, resume ✓

   recap
     · lab check = check.sh grader + quiz, all-or-nothing — a fail costs one rerun
     · graded answers are key=value lines: exact lowercase keys, no spaces around =
     · lab resume replays this recap card — 30-second re-entry after any gap

   unlocked → bash L0.3 — <L0.3 title from its meta.json>
   next     → lab start bash L0.3
   ```
   `[VERIFY-AT-BUILD: the L0.3 title value only — the unlocked line's shape and source (meta.json title, backticks stripped) are verified]`. Verified fail path: a 2/3 quiz fails the whole check (`RESULT: FAIL — bash L0.2 (quiz)`), status stays `in_progress`, attempts +1, and an immediate rerun passes — nothing lost. lab.md step 6 shows only the command plus the `checks 4/4` / `RESULT: PASS` / recap tail shape — never a filled quiz transcript.

7. Optional ungraded coda — `lab resume` now replays the card just earned (`render_resume`, verified; timestamp is UTC `YYYY-MM-DDTHH:MM:SSZ` per `lib/state.sh:now_utc`, value machine-variant; L0.3 block from its meta `[VERIFY-AT-BUILD]`):
   ```
   last passed  bash L0.2 — Meet the lab CLI — start, check, resume   (<UTC timestamp YYYY-MM-DDTHH:MM:SSZ>)

     recap
     · lab check = check.sh grader + quiz, all-or-nothing — a fail costs one rerun
     · graded answers are key=value lines: exact lowercase keys, no spaces around =
     · lab resume replays this recap card — 30-second re-entry after any gap

   next up      bash L0.3 — <L0.3 title>   (<L0.3 type>, ~<L0.3 est> min)
                <L0.3 objective>
                lab start bash L0.3
   ```
   (`lab resume`'s next-up prefers the last-passed track, so it names bash L0.3 even if a demo track is installed — verified.)

**SHELLCHECK STATUS:**
- `files/kit-notes.txt` — plain text, not a shell script, not a shellcheck target (the sweep covers kit scripts + `check.sh` only; files/ payloads are `*.sh`-only targets and this ships none). `meta.json` therefore carries no `teaching_samples` map.
- `check.sh` (spelled in full under CHECK LOGIC) — verified: zero output, exit 0 from `shellcheck -x -S style` (0.9.0), both in a bare directory and beside a `.shellcheckrc` containing `shell=bash`. Its fence block is copied from demo L0.0's check.sh, itself verified clean `[VERIFY-AT-BUILD: rerun tools/shellcheck-all.sh after build]`.
- Typed sample lines in lab.md (transcripts above) are not shellcheck targets.
- **Claims: none emitted, deliberately.** Every command in this lab exercises the lab CLI itself; that behavior needs the built track + harness and is owned/tested by `tests/acceptance.sh` — nothing here can be recreated in an empty cwd with bash+coreutils. (The plan verifier nevertheless assembled the kit with this entry's exact content and executed every transcript above — start, status, hint ×2, check pass, check 2/3-fail, fence-proof fail, accept-variant, resume.)

**SANDBOX NOTE:** learner writes exactly two files — `answers.txt`, `location.txt` — both inside `workspace/bash/L0.2/`. The only out-of-workspace write in the whole lab is the kit's own atomic `.progress.json` update at the repo root, performed by `bin/lab` via `lib/state.sh` on start/hint/check — kit-owned state, not a lab step escaping the fence, and check.sh itself never touches it (it runs under `env -i` with no `STATE_FILE`). System reads: none (kit-notes.txt is a workspace file). No network, no sudo, no installs (L0.1 owns installs, in the learner's own shell). No destructive commands anywhere in P0/P1; checklib's decoy-tree helpers stay `[FUTURE-PHASE-ONLY]` (Phase 3+).

**GUIDED STEPS outline** (9 commands + 1 optional; lab.md uses exact headings `## BRIEF` / `## GUIDED STEPS`):
1. From the repo root: `lab status` — find the bash block; this lab's row starts with ▶ because `lab start` marked it in progress. Read the legend line: ⏭ never becomes ✓. (Expected board shape printed, artifact item 1.)
2. `cd workspace/bash/L0.2` · `ls` (expect exactly `kit-notes.txt`) · `cat kit-notes.txt` — read all of it; every graded answer is one of its lines.
3. `lab hint bash L0.2` — spend hint level 1 for free; note the `[hint 1/3]` counter and that level 1 names artifacts, never answers (artifact item 3's shape printed).
4. Create `answers.txt` (`cat > answers.txt`, three lines, Ctrl-D; verify `cat answers.txt`). Questions printed in lab.md:
   - q1 (choice): "A month has passed since you last touched the kit. What's the first command back?" a) lab status b) lab resume c) lab hint → learner writes `q1=b`
   - q2 (value): "How many hint levels does every lab have?" → learner writes `q2=3`
   - q3 (choice): "Your quiz comes back 2/3. What just happened?" a) partial credit — the 2 correct answers are saved b) the whole check failed; nothing is lost — rerun lab check c) the lab resets and must be restarted → learner writes `q3=b`
5. `pwd > location.txt` — the fence proof.
6. `lab check bash L0.2` — type the quiz answers at each `  > ` prompt; watch `checks 4/4`, `quiz: 3/3`, the recap card, and L0.3 unlock. Optional coda after passing: `lab resume` replays the recap card you just earned.

**CHECK LOGIC (check.sh):** standard template (`#!/usr/bin/env bash` · `set -euo pipefail` · both `: "${LAB_WORKSPACE:?run this via: lab check bash L0.2}"` / `: "${LAB_CHECKLIB:?run this via: lab check bash L0.2}"` guards · `# shellcheck source=/dev/null` + `source "$LAB_CHECKLIB"` · mode 0644), then exactly:
```bash
assert_file_contains "answers.txt" '^q1=b$' \
  "step 4 — q1: which verb re-primes you after a month away? the answer is a line in kit-notes.txt"
assert_file_contains "answers.txt" '^q2=3$' \
  "step 4 — q2: count the hint-ladder levels named in kit-notes.txt"
assert_file_contains "answers.txt" '^q3=b$' \
  "step 4 — q3: kit-notes.txt spells out the all-or-nothing check rule"
location_hint="step 5 — run: pwd > location.txt while inside workspace/bash/L0.2"
if [[ -f location.txt ]]; then
  recorded_dir="$(realpath -m -- "$(cat location.txt)")"
  workspace_dir="$(realpath -- "$LAB_WORKSPACE")"
  if [[ "$recorded_dir" == "$workspace_dir" ]]; then
    pass_msg "location.txt was written from inside the workspace"
  else
    fail "location.txt was written from inside the workspace" "$location_hint"
  fi
else
  fail "location.txt missing" "$location_hint"
fi

ck_summary
```
Hint gists: q1/q2/q3 failures each point at step 4 and the kit-notes.txt line that answers them without stating it; the location block's hint replays the exact step-5 command with the required cwd. Fence-proof block is demo L0.0 check.sh lines 15–26 verbatim except the hint string (step number + `workspace/bash/L0.2`) — verified against the file; line 27 there is the blank before `ck_summary` at 28, which is what the directive's "15–27" cites. No absolute-path literals anywhere (the realpath compare uses `$LAB_WORKSPACE`). Four numbered assertions → `checks 4/4`. CI fabrication (verifier-executed, passes): from the provisioned workspace, `printf 'q1=b\nq2=3\nq3=b\n' > answers.txt` and `pwd > location.txt`, then `printf 'c\nlab resume\nb\n' | lab check bash L0.2` — bash+coreutils only.

**QUIZ (plaintext answers; builder base64-encodes with `printf '%s' 'answer' | base64 -w0`):**
1. choice — "A lab shows ⏭ in lab status. You go back, do the work, and pass its check. Its mark becomes…" a) ✓ — a pass always upgrades the mark b) ▶ — in progress until the next lab passes c) ⏭ — skipped is permanent; it never becomes ✓ → **c**
2. text — "Which command replays your last recap card?" → **lab resume** (accept: `resume` — verified: the quiz engine lowercase-normalizes and grades accept variants)
3. choice — "Why must an answer line be exactly q1=b, never Q1 = b?" a) style preference — the grader normalizes case and spacing b) check.sh greps the anchored pattern ^q1=b$ — any other spelling doesn't match and the check fails c) the CLI rewrites the file before grading → **b**
(Same concepts as graded q1–q3, different angles: graded q1 asks which verb to run, quiz Q2 asks what resume replays; graded q3 asks what a 2/3 means, quiz Q3 asks the grep mechanism; quiz Q1's ⏭ permanence is graded nowhere in answers.txt.)

**RECAP:**
```
lab check = check.sh grader + quiz, all-or-nothing — a fail costs one rerun
graded answers are key=value lines: exact lowercase keys, no spaces around =
lab resume replays this recap card — 30-second re-entry after any gap
```

**HINTS:** L1: "The grader wants exactly two files, both named in steps 4-5: answers.txt and location.txt. ls the workspace and compare it against the step list." L2: "answers.txt needs exactly three lines shaped q1=<letter>, q2=<number>, q3=<letter> — lowercase keys, no spaces around =. location.txt must be pwd's output, written from inside workspace/bash/L0.2, not from the repo root." L3: "All three answers are single lines of kit-notes.txt: the re-entry verb, the hint-ladder count, and the all-or-nothing check rule. Write the three answer lines, run pwd > location.txt from the workspace, then rerun lab check bash L0.2."

---

### L0.3 — Reading the shebang — `#!/bin/bash` vs `#!/bin/sh` vs dash, and why it matters
**DECODE · gate:true · est 15 · files/: greet.sh, deploy.sh · recall.json: no**
**objective:** "Read a script's shebang to name its target interpreter, and demonstrate why bash-only syntax under #!/bin/sh detonates on Debian/Ubuntu, where sh is dash."

**Gate rationale (gate:true):** the map's Phase-0 exit-gate sentence — "given any script, you can say what interpreter it targets and whether bash-only features will break under `/bin/sh`" — is exactly this lab's content, and both the demo track (L0.0) and the rust plan (L0.3) put `gate: true` on the phase-final lab. meta.json: title with backticks stripped (`Reading the shebang — #!/bin/bash vs #!/bin/sh vs dash, and why it matters`), plus `"teaching_samples": {"files/deploy.sh": ["SC3010", "SC3059"]}`.

**BRIEF gist (builder expands to ≤10 lines):** quote the map's "Why L0.3 first" framing: "Security Onion runs scripts under different shells; Alpine containers use BusyBox `sh`; Debian/Ubuntu `/bin/sh` is dash, not bash. A script that works in your terminal can fail in a container for this reason alone." Two scripts, IDENTICAL `#!/bin/sh` shebangs — one honest (POSIX body), one lying (bash body). Run both under bash and dash, watch the liar detonate, let ShellCheck name the bashisms. This lab is the Phase-0 exit gate.

**files/greet.sh:**
```sh
#!/bin/sh
name="${1:-world}"
printf 'hello, %s\n' "$name"
```

**files/deploy.sh** (TEACHING SAMPLE header on line 2, per conventions; expected SC codes under `shellcheck -s sh`: **SC3010, SC3059** — exactly these two, verified on 0.9.0):
```sh
#!/bin/sh
# TEACHING SAMPLE — intentionally flawed
target="$1"
if [[ -z "$target" ]]; then
  target="prod"
fi
printf 'deploying to %s\n' "${target^^}"
```

**TEACHING ARTIFACT** — run matrix, decode, and answer key (every value below executed and captured on the baseline machine; dash error text verified byte-exact on the baseline dash 0.5.12-6ubuntu5 — the message prefix format is dash-version-variant, so re-verify on any other dash `[VERIFY-AT-BUILD]`):

1. `bash greet.sh` -> `hello, world` (exit 0). `${1:-world}` = use `$1`, or the literal `world` when `$1` is unset or empty — pure POSIX.
2. `dash greet.sh` -> `hello, world` (exit 0). Honest script: body matches the shebang's dialect, so every sh gives the same answer.
3. `bash deploy.sh` -> `deploying to PROD` (exit 0). No arg -> `$1` empty -> `[[ -z ]]` true -> `target=prod` -> `${target^^}` uppercases. Works only because bash has both bashisms.
4. `dash deploy.sh` -> exit **2**, two stderr lines, quoted exactly:
   ```
   deploy.sh: 4: [[: not found
   deploy.sh: 7: Bad substitution
   ```
   Mechanism, line by line: dash has no `[[` — line 4 parses as an ordinary command named `[[`, which doesn't exist (status 127). `if` reads that as false, so the body is SKIPPED and `target` silently stays EMPTY — quiet logic corruption *before* the crash. Line 7's `${target^^}` is not POSIX; dash aborts fatally with `Bad substitution`, script exit 2.
5. `readlink -f /bin/sh` -> `/usr/bin/dash` — the L0.1 reveal, now load-bearing: `./deploy.sh` (exec'd via its shebang) would run under dash here.
6. `shellcheck -s sh deploy.sh` -> exit 1, byte-exact output:
   ```
   
   In deploy.sh line 4:
   if [[ -z "$target" ]]; then
      ^----------------^ SC3010 (warning): In POSIX sh, [[ ]] is undefined.
   
   
   In deploy.sh line 7:
   printf 'deploying to %s\n' "${target^^}"
                               ^---------^ SC3059 (warning): In POSIX sh, case modification is undefined.
   
   For more information:
     https://www.shellcheck.net/wiki/SC3010 -- In POSIX sh, [[ ]] is undefined.
     https://www.shellcheck.net/wiki/SC3059 -- In POSIX sh, case modification is...
   ```
7. `shellcheck -s sh greet.sh` -> no output, exit 0.

**Dialect-precedence rule (settled empirically on 0.9.0; lab.md states it in one sentence):** command-line `-s` > nearest `.shellcheckrc` `shell=` > shebang. Verified three ways: with a `shell=bash` rc beside it, bare `shellcheck deploy.sh` exits 0 with ZERO findings (a false clean — the rc overrides the `#!/bin/sh` shebang); with an rc carrying no `shell=`, the shebang decides and both findings return; `-s sh` restores the findings even under the bash rc. lab.md note: "the repo's `.shellcheckrc` pins `shell=bash` and outranks the shebang, so we pass `-s sh` explicitly to ask 'is this valid POSIX sh?' — the command line outranks them both."

**Answer key — answers.txt (options printed verbatim in lab.md):**
- q1 (choice) "`./deploy.sh` — run via its shebang — executes under…" a) bash, it's the login shell b) `/bin/sh`, which is dash on this OS c) whatever `$SHELL` says -> **q1=b** (the kernel reads line 1; sh-target.txt is the evidence).
- q2 (choice) "Why can this script pass on a dev box yet die in a Debian/Alpine container?" a) containers block shell scripts b) the container's `/bin/sh` is dash/BusyBox — no `[[`, no `${var^^}` c) the exec bit is lost in the image -> **q2=b** (on the dev box someone ran `bash deploy.sh`, masking the lie).
- q3 (choice) "Is `[[ ]]` POSIX?" a) yes b) no — it's a bash/ksh extension c) only when the operands are quoted -> **q3=b** (SC3010's own wording: "In POSIX sh, [[ ]] is undefined").
- q4 (choice) "The smallest honest fix for deploy.sh?" a) change the shebang to `#!/bin/bash` b) rewrite the body POSIX (`test`/`[ ]` + `tr`) c) either a or b — match the shebang to the syntax or the syntax to the shebang -> **q4=c**.

**SHELLCHECK STATUS:**
- files/greet.sh — clean: zero output from `shellcheck -x -S style greet.sh` (0.9.0) AND from `shellcheck -s sh greet.sh` (both verified, including with the repo's `shell=bash` rc beside the file).
- files/deploy.sh — TEACHING SAMPLE — intentionally flawed (exact header line 2); expected codes under `shellcheck -s sh`: SC3010, SC3059 — nothing else. `tools/shellcheck-all.sh` never sweeps `files/` payloads at all (its globs cover only `bin/lab`, `harness/*.sh`, `tools/*.sh`, and lab `check.sh` graders — there is no header-based exemption in the tool), so the header + meta.json `teaching_samples` are what declare the flaw.
- Typed sample lines in lab.md are not shellcheck targets; both `files/*.sh` are.

**SANDBOX NOTE:** every write lands inside `workspace/bash/L0.3/`: dash-run.txt, bash-run.txt, sh-target.txt, sc-out.txt, answers.txt. System READS only: `readlink -f /bin/sh` (symlink inspection) and executing dash/shellcheck read-only from PATH. No installs (ShellCheck arrived in L0.1, learner shell), no network, zero destructive commands; decoy-tree tooling is [FUTURE-PHASE-ONLY].

**GUIDED STEPS outline (14 commands, ends with the check):**
1. `cat greet.sh` — read it: shebang `#!/bin/sh`, POSIX body.
2. `cat deploy.sh` — SAME shebang, but the body uses `[[ ]]` and `${target^^}`.
3. `bash greet.sh` -> `hello, world`
4. `dash greet.sh` -> `hello, world` — the honest script is dialect-proof.
5. `bash deploy.sh` -> `deploying to PROD`
6. `dash deploy.sh` -> the two error lines quoted above.
7. `echo $?` -> `2` — dash aborted; bash said exit 0 for the same file.
8. `dash deploy.sh > dash-run.txt 2>&1` — capture the evidence (exit 2 is expected).
9. `bash deploy.sh > bash-run.txt 2>&1`
10. `readlink -f /bin/sh > sh-target.txt` — file holds `/usr/bin/dash`.
11. `shellcheck -s sh deploy.sh > sc-out.txt 2>&1 || true` — with the one-sentence rc-precedence note.
12. `cat sc-out.txt` — read SC3010 and SC3059; they name both bashisms.
13. Write `answers.txt`: four lines `q1=` … `q4=` (options printed in lab.md; no spaces around `=`).
14. `lab check bash L0.3`

**CHECK LOGIC (check.sh):** standard preamble (`#!/usr/bin/env bash`, `set -euo pipefail`, LAB_WORKSPACE/LAB_CHECKLIB guards, `source "$LAB_CHECKLIB"`, mode 0644), then:
```bash
assert_file_exists "answers.txt" 'step 13 — record q1=<letter> through q4=<letter>, one per line, no spaces around ='
assert_file_contains "answers.txt" '^q1=b$' 'q1 — sh-target.txt already names the interpreter a ./deploy.sh exec would get'
assert_file_contains "answers.txt" '^q2=b$' 'q2 — what shell answers to sh inside a Debian or Alpine container?'
assert_file_contains "answers.txt" '^q3=b$' 'q3 — the SC3010 line in sc-out.txt answers this verbatim'
assert_file_contains "answers.txt" '^q4=c$' 'q4 — honest means shebang and syntax agree; count the directions that restore agreement'
assert_file_contains "dash-run.txt" 'not found' 'step 8 — dash deploy.sh > dash-run.txt 2>&1 must capture the line-4 [[ error'
assert_file_contains "dash-run.txt" 'Bad substitution' 'step 8 — the line-7 error belongs in dash-run.txt too (the 2>&1 does that)'
assert_file_contains "bash-run.txt" 'deploying to PROD' 'step 9 — bash deploy.sh > bash-run.txt 2>&1'
assert_file_contains "sh-target.txt" 'dash$' 'step 10 — readlink -f the sh symlink, redirected into sh-target.txt (exact command in lab.md)'
assert_file_contains "sc-out.txt" 'SC3010' 'step 11 — shellcheck -s sh deploy.sh > sc-out.txt 2>&1 || true — the -s sh flag is the point'
ck_summary
```
No absolute-path literals anywhere (`'dash$'`, never the full path). CI fabrication: `printf 'q1=b\nq2=b\nq3=b\nq4=c\n' > answers.txt; printf 'x: 4: [[: not found\nx: 7: Bad substitution\n' > dash-run.txt; printf 'deploying to PROD\n' > bash-run.txt; printf 'dash\n' > sh-target.txt; printf 'SC3010\nSC3059\n' > sc-out.txt`.

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "You run `bash deploy.sh` in your terminal. What does the `#!/bin/sh` line do?" a) forces the script to run under sh anyway b) nothing — it's a comment; the shebang only picks the interpreter when the file itself is exec'd (`./deploy.sh`) c) makes bash switch into POSIX mode -> **b**
2. text — "Name one bash-only construct from deploy.sh that dash rejects." -> **[[** (accept: `[[ ]]`, `double bracket`, `double brackets`, `${target^^}`, `${var^^}`, `^^`, `case modification`, `uppercase expansion`)
3. choice — "What is dash?" a) Debian's small, fast, POSIX-compliant sh — what /bin/sh points to on Debian/Ubuntu b) bash running in POSIX mode c) an obsolete shell that bash replaced -> **a**

**RECAP:**
```
the shebang picks the interpreter only when the file is exec'd — bash script.sh ignores it
on Debian/Ubuntu /bin/sh is dash: strict POSIX, no [[ ]], no ${var^^} — bashisms detonate at run time
shellcheck -s sh asks "is this POSIX?" — the -s flag outranks both .shellcheckrc and the shebang
```

**HINTS:** L1: the grader reads five artifacts — dash-run.txt, bash-run.txt, sh-target.txt, sc-out.txt, answers.txt; `ls` the workspace and compare against steps 8–13; answers.txt needs exactly four lowercase q-keys. L2: dash-run.txt must hold BOTH dash error lines (line 4's `[[: not found` and line 7's `Bad substitution`) — that requires the `2>&1` in step 8; sh-target.txt is the output of `readlink -f /bin/sh`; each answer is an exact line like `q1=x`, no spaces around `=`. L3: re-run steps 8–11 verbatim, then `cat dash-run.txt sc-out.txt sh-target.txt` — q1 is answered by sh-target.txt, q3 by the SC3010 wording, q2 by imagining the same run inside an Alpine container, and q4 by asking how many directions restore shebang-syntax agreement; write the four letters into answers.txt and re-check.

---

### L1.1 — Commands are just words — the shell splits, then runs
**PREDICT · gate:false · est 10 · files/: argv.sh · recall.json: YES (phase opener)**
**objective:** "Predict the exact argv — argument count and bytes — that a command line hands its program, before running it."

**recall.json — 5 questions, all sourced from Phase 0:**
1. choice (source: "bash L0.1") — "/bin/sh on Ubuntu is really…" a) bash b) dash
   c) zsh → **b**
2. choice (source: "bash L0.1") — "shellcheck prints nothing after checking your
   script — what does that mean?" a) it crashed b) clean — silence is the pass state
   c) you need to add -v → **b**
3. choice (source: "bash L0.3") — "The shebang line decides the interpreter when you
   run…" a) `bash script.sh` b) `./script.sh` c) `cat script.sh` → **b**
4. choice (source: "bash L0.2") — "lab check passes when…" a) the grader passes
   b) the grader passes AND the quiz is 3/3 c) the quiz is 2/3 → **b**
5. choice (source: "bash L0.3") — "`[[ -z \"$x\" ]]` under dash…" a) works b) fails —
   `[[` is a bash extension c) works if quoted → **b**

**BRIEF gist (builder expands to ≤10 lines):** One idea: the shell reads your line as
text, splits it into words on whitespace, then runs word 0 as the program with the
rest as arguments. The program never sees your spacing — only the finished word list.
Phase 1's map, stated once here: every line goes through a fixed sequence —
tokenize → expand → split → glob → execute — and Phase 1 walks that sequence lab by
lab; today is the split and the run. Ships `argv.sh`, a one-trick printer that shows
the argv it received as `<count>|<each-arg-in-angle-brackets>`. Honor line: the check
can't tell whether you predicted first — you're only cheating your own reps.

**files/argv.sh** (canonical printer, byte-identical across all PREDICT labs, per
track conventions §3):
```bash
#!/usr/bin/env bash
# argv.sh — prints: <number of arguments>|<each argument in angle brackets>
out=""
for a in "$@"; do
  out+="<${a}>"
done
printf '%s|%s\n' "$#" "$out"
```
Output format: `bash argv.sh a "b c"` prints `2|<a><b c>`; zero args prints `0|`.
All invocations use `bash argv.sh …`, never `./argv.sh` (no reliance on exec bits
surviving the files/ copy).

**TEACHING ARTIFACT** — each sample line → the EXACT output line → mechanism. No
state matters in this lab: no variables set, no globs, no files referenced — the
outputs below hold in any workspace.

1. `bash argv.sh hello world` → `2|<hello><world>` — whitespace splitting cuts the
   line into words; after words 0–1 name the interpreter and the script, `hello` and
   `world` arrive as $1 and $2.
2. `bash argv.sh hello      world` (a run of six spaces) → `2|<hello><world>` —
   byte-identical to line 1: a run of whitespace is ONE separator; splitting eats it,
   so the program cannot know how many spaces you typed.
3. `bash argv.sh "hello   world"` (exactly three spaces inside the quotes) →
   `1|<hello   world>` — double quotes suppress splitting: one argument, and the
   three interior spaces survive byte-for-byte.
4. `bash argv.sh` → `0|` — zero arguments is a legal argv: `$#` is 0, the loop body
   never runs, only the count and the pipe print.
5. Post-reveal demo, shown in lab.md AFTER the compare step, not graded:
   `echo one     two` (five spaces) → `one two` — the shell had already split the
   line into the two words `one` and `two` before echo started; echo merely joins its
   argv with single spaces. The "collapse" happened in the shell — not in echo, not
   in the terminal.

Predictions file the learner writes (values never shown in lab.md — this is the
grading key for the builder):
```
p1=2|<hello><world>
p2=2|<hello><world>
p3=1|<hello   world>
p4=0|
```

**SHELLCHECK STATUS:** files/argv.sh — clean: zero output from
`shellcheck -x -S style` (0.9.0), verified at plan time on the baseline machine.
Typed sample lines (p1–p4 and the echo demo) are not shellcheck targets; argv.sh is
the only files/*.sh and the only shellcheck target in this lab.

**SANDBOX NOTE:** every command reads and writes inside `workspace/bash/L1.1/` only
— argv.sh is seeded there by `lab start` and executed in place; the sole write is the
learner's `predictions.txt`. No system reads, no installs, no network, nothing
destructive. Decoy-tree helpers unused ([FUTURE-PHASE-ONLY], Phase 3+).

**GUIDED STEPS outline** (9 commands total, ≤15 budget):
1. `cd workspace/bash/L1.1` (seeded by `lab start bash L1.1`), then `cat argv.sh` —
   read the printer: it reports `<count>|<each argument in angle brackets>`, e.g.
   two args `a` and `b c` print `2|<a><b c>`.
2. Predict FIRST. lab.md prints the four sample lines exactly as in the TEACHING
   ARTIFACT (spacing preserved, outputs never shown) and the file format skeleton
   (`p1=` … `p4=`, full output line as the value, no spaces around `=`). Learner
   writes all four predictions into `predictions.txt` before running anything
   (1 command / editor session).
3. Run each of the four lines (4 commands); compare each real line against the
   prediction. Mismatch = the mental model was wrong — fix the file AND note which
   split rule you missed.
4. The reveal demo: `echo one     two` (1 command). Question posed in lab.md: who
   collapsed the spaces? Answer beat: the shell split before echo ran.
5. `lab check bash L1.1` (1 command).

**CHECK LOGIC (check.sh):** standard template (`#!/usr/bin/env bash`,
`set -euo pipefail`, LAB_WORKSPACE/LAB_CHECKLIB guards, `source "$LAB_CHECKLIB"`,
mode 0644), then:
```bash
assert_file_exists "predictions.txt" \
  "step 2 — write p1..p4 into predictions.txt before running anything"
assert_file_contains_fixed "predictions.txt" "p1=2|<hello><world>" \
  "p1 — rerun: bash argv.sh hello world, transcribe the WHOLE line as the value"
assert_file_contains_fixed "predictions.txt" "p2=2|<hello><world>" \
  "p2 — the run of spaces is one separator; rerun the line and transcribe"
assert_file_contains_fixed "predictions.txt" "p3=1|<hello   world>" \
  "p3 — quotes keep the three interior spaces inside ONE argument; transcribe exactly"
assert_file_contains_fixed "predictions.txt" "p4=0|" \
  "p4 — zero arguments still prints a line; rerun: bash argv.sh"
assert_output_contains "argv.sh splits on whitespace" '2\|<hello><world>' \
  "run: bash argv.sh hello world" -- bash -- argv.sh hello world
ck_summary
```
Fixed literals (not ERE) for p1–p4 because the values contain `|` `<` `>`; the live
proof's ERE escapes the pipe (`2\|<hello><world>` — verified matching at plan time).
No absolute-path literals anywhere. CI fabrication: `printf '%s\n'
'p1=2|<hello><world>' 'p2=2|<hello><world>' 'p3=1|<hello   world>' 'p4=0|' >
predictions.txt` — argv.sh arrives via `lab start`'s files/ copy; bash+coreutils
only.

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "The shell splits a line into words. What does word 0 become?" a) the
   first argument b) the program that runs c) the shell's prompt → **b**
2. choice — "You type `echo one     two` and see `one two`. Who collapsed the
   whitespace?" a) echo trims repeated spaces from its input string b) the terminal
   rewrites the line as you type c) the shell split the line into two words before
   echo ran; echo just joins its argv with single spaces → **c**
3. choice — "Quoting `\"hello   world\"` changes…" a) which program runs b) what the
   program receives — one argument instead of two c) nothing; quotes are stripped
   before anything else happens → **b**

**RECAP:**
```
the shell splits a line on whitespace: word 0 = the program, the rest = its argv
runs of spaces vanish in the split — the program never sees your spacing
quotes suppress splitting: "a   b" travels as ONE argument, bytes intact
```

**HINTS:** L1: the grader reads `predictions.txt` — four keys p1–p4, no spaces
around `=`, each value the complete line argv.sh prints; compare your file against
the four sample lines in lab.md. L2: every value has the shape
`N|<arg><arg>…` — the count, a pipe, then each argument in its own angle brackets;
count words as the shell would (separators collapse), and remember quotes make their
contents ONE word, spacing intact; p4 still prints a line. L3: run each of the four
lines and transcribe each output byte-for-byte as the value (`p1=` + the full line),
then re-run `lab check bash L1.1` — the run is the legitimate answer sheet.

---

### L1.2 — Variables — `$VAR`, `${VAR}`, and when braces matter
**PREDICT · gate:false · est 10 · files/: argv.sh · recall.json: no**
**objective:** "Predict exactly which words reach a command when $v, ${v}wide, and $vwide expand, and explain why v = world with spaces runs a command instead of assigning."
(meta.json title, backticks stripped per conventions §12: `Variables — $VAR, ${VAR}, and when braces matter`; no `teaching_samples` key — no flawed files ship.)

**BRIEF gist (builder expands to ≤10 lines):** One concept: `$name` is replaced by its
text BEFORE anything runs. After `$` the shell takes the LONGEST run of identifier
characters (letters, digits, underscore) as the name; `${…}` draws the boundary
yourself. Assignment is `name=value` with NO spaces — add spaces and it stops being an
assignment at all. Honor line (once, verbatim): "the check can't tell whether you
predicted first — you're only cheating your own reps."

**files/argv.sh** (byte-identical convention copy — conventions §3):
```bash
#!/usr/bin/env bash
# argv.sh — prints: <number of arguments>|<each argument in angle brackets>
out=""
for a in "$@"; do
  out+="<${a}>"
done
printf '%s|%s\n' "$#" "$out"
```
Contract reminder printed in lab.md (learner formats predictions against it):
`bash argv.sh a "b c"` → `2|<a><b c>`; zero arguments → `0|`.

**TEACHING ARTIFACT** (plan-only — lab.md prints the sample lines and the p4 options,
NEVER these outputs; PREDICT protocol). State pin: every line runs after `v=world` in
the same shell; no variable named `vwide` exists anywhere.

1. p1: `bash argv.sh $v` → `1|<world>` — parameter expansion replaces `$v` with
   `world` before argv.sh is even launched; one word survives.
2. p2: `bash argv.sh ${v}wide` → `1|<worldwide>` — the braces end the name at `v`;
   the expanded text glues onto the literal `wide` inside the same word, so argv.sh
   receives ONE argument, `worldwide`.
3. p3: `bash argv.sh $vwide` → `0|` — longest-identifier rule: the shell reads the
   name as `vwide` (`w` is a valid identifier char, so nothing stops the name at `v`),
   finds it unset, expands it to empty — and an unquoted empty expansion is removed
   entirely during word splitting, so the argument count drops to zero. This is the
   phase's first "silently became nothing" moment — the same mechanism that turns
   `rm -rf "$DIR/"` into a filesystem-root wipe when `DIR` is unset, detonated
   properly in Phase 3 (L3.2).
4. p4 (multiple choice, printed in lab.md; graded as `p4=b`): what does `v = world`
   (with spaces) do?
   a) assigns `world` to `v`
   b) runs a command named `v` with arguments `=` and `world` → "command not found"
   c) syntax error, nothing runs
   → **b** — assignment grammar is position-sensitive: `name=value` counts as an
   assignment only as a single word with no spaces; spaced, the first word `v` becomes
   a command name and `=` / `world` its arguments.
5. Post-reveal demo (run only AFTER predictions are locked in; NOT graded):
   `v = world` → stderr ends `v: command not found`, then `echo $?` → `127`.
   Verifier-confirmed 2026-07-13 on the baseline machine (Ubuntu 24.04.4, bash
   5.2.21): the interactive command-not-found handler prints exactly
   `v: command not found` for `v` (no prefix); non-interactive bash prints
   `bash: line 1: v: command not found`. The suffix and exit 127 hold in both modes
   [VERIFY-AT-BUILD: wording is command-not-found-handler-dependent — re-confirm only
   if building on a non-baseline machine]. lab.md describes the message by its stable
   suffix only.

**SHELLCHECK STATUS:**
- `files/argv.sh` — clean: zero output from `shellcheck -x -S style` (0.9.0),
  verifier-confirmed in a bare directory and beside a `shell=bash` .shellcheckrc.
- Typed sample lines are not shellcheck targets (conventions §4) — the unquoted `$v`
  at the prompt is the teaching point; committed to a script it would draw SC2086,
  which L1.3 makes the whole lesson.
- check.sh note for the builder: the p1–p3 failure hints mention `$v`/`${v}wide`, and
  single-quoting them trips SC2016 (info) under the repo sweep with `# shellcheck
  disable=` banned — use double-quoted hints with escaped `\$` exactly as written in
  CHECK LOGIC below (verifier-confirmed: the full check.sh below produces zero
  shellcheck output, bare and beside the repo rc).

**SANDBOX NOTE:** the only write in this lab is `predictions.txt` inside
`workspace/bash/L1.2/` (lab start seeds argv.sh there). The three argv.sh runs and the
`v = world` demo perform PATH lookups only — no system reads, no installs, nothing
written outside the workspace. Destructive-command tooling: none in P0/P1
([FUTURE-PHASE-ONLY]).

**GUIDED STEPS outline** (11 commands total):
1. `cd workspace/bash/L1.2` then `ls` → `argv.sh`. lab.md re-prints the argv.sh
   contract line (`bash argv.sh a "b c"` → `2|<a><b c>`; zero args → `0|`).
2. Read the four items: sample lines p1–p3 plus the p4 choice, all printed in lab.md —
   expected outputs never shown.
3. Write ALL FOUR predictions into `predictions.txt` BEFORE running anything
   (`nano predictions.txt`; heredoc users must use the quoted form `<<'EOF'` so `$`
   stays literal). Format block printed in lab.md, keys only:
   `p1=<the exact line you expect argv.sh to print>` … `p4=<one letter: a, b, or c>`,
   no spaces around `=`.
4. `v=world` — one assignment, reused by every following line.
5. `bash argv.sh $v` — compare against your p1.
6. `bash argv.sh ${v}wide` — compare against your p2.
7. `bash argv.sh $vwide` — compare against your p3. Where did the argument go?
8. The p4 reveal: `v = world` then `echo $?` — watch what the shell tried to do.
9. Correct any missed key in `predictions.txt` to the observed truth — the miss is
   the lesson; the file records what actually ran.
10. `lab check bash L1.2`

**CHECK LOGIC (check.sh):** standard template (shebang, `set -euo pipefail`, both
`: "${…:?}"` guards, `# shellcheck source=/dev/null` directly above
`source "$LAB_CHECKLIB"` — the directive line is load-bearing: without it the repo
sweep emits SC1090 — mode 0644), then exactly:
```bash
assert_file_exists 'predictions.txt' 'step 3 — write keys p1..p4 into predictions.txt before running anything'
assert_file_contains_fixed 'predictions.txt' 'p1=1|<world>' "p1 — rerun step 5 (v=world, then: bash argv.sh \$v) and transcribe the exact output line"
assert_file_contains_fixed 'predictions.txt' 'p2=1|<worldwide>' "p2 — rerun step 6 (bash argv.sh \${v}wide) and transcribe the exact output line"
assert_file_contains_fixed 'predictions.txt' 'p3=0|' "p3 — rerun step 7 (bash argv.sh \$vwide) and transcribe the exact output line"
assert_file_contains 'predictions.txt' '^p4=b$' 'p4 — one lowercase letter; rerun step 8 (v = world, with spaces) and watch what the shell tries to do'

ck_summary
```
Hint gists: existence → step 3 (write before running); p1–p3 → rerun the numbered
step and transcribe; p4 → single letter, rerun the demo. Fixed literals because
`| < >` are on the ERE-metacharacter list (conventions §2); `'^p4=b$'` anchored ERE.
Deliberately NO live `bash -- argv.sh` proof — check.sh performs no expansion of its
own, so re-running argv.sh proves nothing about the learner's predictions (directive).
CI fabrication: `printf 'p1=1|<world>\np2=1|<worldwide>\np3=0|\np4=b\n' > predictions.txt`
(argv.sh is seeded by lab start and never asserted).

**QUIZ (plaintext answers; builder base64-encodes with `printf '%s' 'answer' | base64 -w0`):**
1. choice — "`name=report` is set and you want the string `report_backup`. Which
   gets it?" a) `"$name_backup"` b) `"${name}_backup"` c) either one → **b**
   (underscore is a valid identifier character, so `$name_backup` looks up a variable
   named `name_backup` — unset, empty).
2. choice — "Teaser for L1.4: after `v=world`, what does `echo '$v'` print?"
   a) `world` b) `$v` c) nothing → **b**.
3. text — "The p4 demo made the shell search for a command named v and fail. What
   number did `echo $?` print?" → **127** (no accept variants needed).

**RECAP (exactly 3 lines):**
```
$name grabs the longest identifier after $ — ${name} draws the boundary yourself
unset variables expand to nothing, and an unquoted nothing vanishes from the command
assignment is name=value with NO spaces — v = world runs a command named v (exit 127)
```

**HINTS:** L1: "The grader reads exactly one artifact: predictions.txt with keys p1,
p2, p3, p4 — values are the exact lines argv.sh printed (p4 is a single letter), no
spaces around =." L2: "For each line ask: how far past the $ does a valid name run
(letters, digits, underscore)? ${v}wide stops the name at v; $vwide does not stop at
v. For p4: bash treats name=value as an assignment only when it contains no spaces."
L3: "Run v=world, then run each printed line exactly as shown and transcribe each
output line verbatim into predictions.txt; for p4, run v = world, read what the shell
says it tried to do, and record the matching letter."

---

### L1.3 — The unquoted variable — word splitting, the #1 Bash bug
**PREDICT · gate:false · est 15 · files/: argv.sh, report final.txt, backup/.gitkeep · recall.json: no**
**objective:** "Predict exactly how an unquoted $var splits into multiple words, and prove with argv.sh and cp that double quotes are what keep one filename one argument."

**BRIEF gist (builder expands to ≤10 lines):** This is THE #1 Bash bug — the map
says so. After `$var` expands, the *result* is split on whitespace, so one
variable can become several words and a program receives arguments its caller
never intended. Map's security hook, quoted in spirit: "a filename with a space,
a newline, or a leading dash silently changes what a command does — you'll meet
it here and hunt it for the rest of the course." Honor line (once, in BRIEF):
"the check can't tell whether you predicted first — you're only cheating your
own reps."

**files/argv.sh** (byte-identical to every PREDICT lab's copy, per track convention):
```bash
#!/usr/bin/env bash
# argv.sh — prints: <number of arguments>|<each argument in angle brackets>
out=""
for a in "$@"; do
  out+="<${a}>"
done
printf '%s|%s\n' "$#" "$out"
```

**files/report final.txt** (yes, the filename contains a space — that IS the lab; one line + trailing newline):
```
Q2 incident report
```

**files/backup/.gitkeep** — empty file (zero bytes). Its only job: `lab start`'s
`cp -R -- files/. <ws>/` seeds a `backup/` directory (containing only `.gitkeep`)
into the workspace (verified: `lib/workspace.sh:34` copies recursively).

**TEACHING ARTIFACT** — pinned state: every line runs from the workspace root
(`workspace/bash/L1.3/`); the learner has typed `f="report final.txt"` in the
current shell first (and `opt=-n` before p5); `backup/` contains only `.gitkeep`
until p4. All outputs verified on bash 5.2.21 / GNU coreutils 9.4 / Ubuntu 24.04.

| # | sample line | exact result | mechanism |
|---|---|---|---|
| p1 | `bash argv.sh $f` | `2\|<report><final.txt>` | `$f` expands FIRST to `report final.txt`; the unquoted result is then split on IFS whitespace into two words — argv.sh receives argc=2 |
| p2 | `bash argv.sh "$f"` | `1\|<report final.txt>` | double quotes suppress word splitting of the expansion result — one word, space intact |
| p3 | `cp $f backup/` | two stderr lines (below), exit 1 | after the split, cp's argv is `cp` `report` `final.txt` `backup/` — TWO source operands, neither exists |
| p4 | `cp "$f" backup/` then `ls backup` | cp: silent, exit 0; `ls backup` piped → `report final.txt` | quoted expansion = one source argument; graded by existence of `backup/report final.txt`, not by prediction |
| p5 | `opt=-n; bash argv.sh $opt` then `echo $opt` | `1\|<-n>` then NOTHING (zero bytes) | splitting a whitespace-free value yields exactly one word — the shell delivered `-n` faithfully; echo then *consumed* it as its suppress-newline option, leaving zero operands and no newline |

p3's REAL error text (byte-exact, GNU coreutils 9.4, exit code 1):
```
cp: cannot stat 'report': No such file or directory
cp: cannot stat 'final.txt': No such file or directory
```
p3 is a choice question printed in lab.md: a) copies the file b) cp is handed
TWO source names, `report` and `final.txt` — neither exists → two "cannot stat"
errors c) shell syntax error. **p3=b.**

p4 display note for lab.md: at an interactive terminal GNU ls shell-quotes the
name — the learner sees `'report final.txt'` (ls itself warning about the
space); piped/raw form is `report final.txt`. Verified at a real pty (via
`script(1)`) and via `ls --quoting-style=shell-escape` (the tty default since
coreutils 8.25).

p5 is a choice question printed in lab.md: `bash argv.sh $opt` prints `1|<-n>` —
the shell delivered exactly one word. So `echo $opt` prints…? a) -n b) nothing —
echo parsed its argument as an option c) $opt. **p5=b.** One sentence in lab.md:
quoting can't help here — `echo "$opt"` emits the identical zero bytes (same
argv, verified); a dash-word turning into an option is argument-injection
territory, formalized with the `--` guard in Phases 3–4.

**SHELLCHECK STATUS:** files/argv.sh — clean: zero output from
`shellcheck -x -S style` (0.9.0), verified both in a bare directory and with the
repo-style `.shellcheckrc` (`shell=bash`) adjacent. `report final.txt` and
`backup/.gitkeep` are data, not shellcheck targets. The typed sample lines
deliberately use unquoted `$f`/`$opt` — typed at the prompt, never committed as
files, so they are not shellcheck targets (in a file, SC2086 would flag every
one — which is this lab's whole point). No flawed files ship; meta.json carries
no `teaching_samples`.

**SANDBOX NOTE:** every write lands inside `workspace/bash/L1.3/`:
`predictions.txt` (learner-created) and `backup/report final.txt` (p4's cp).
p3's failed cp writes nothing anywhere. No system reads, no network, no
installs, no destructive commands — decoy-tree tooling stays [FUTURE-PHASE-ONLY]
(Phase 3+).

**GUIDED STEPS outline (12 commands, ends with the check):**
1. `f="report final.txt"` — one variable holding ONE string with a space in it
   (assignments are never word-split).
2. Write ALL predictions into `predictions.txt` before running anything —
   `p1=`/`p2=` take the full `N|<...>` argv.sh line, `p3=`/`p5=` take a single
   letter (both choice questions printed in lab.md with options a/b/c).
3. `bash argv.sh $f` — compare against p1.
4. `bash argv.sh "$f"` — compare against p2.
5. `cp $f backup/` — read both error lines; compare against p3.
6. `cp "$f" backup/` — silence is success.
7. `ls backup` — the artifact proves the quoted copy worked (a tty shows
   `'report final.txt'` — ls warning you the name has a space).
8. `opt=-n`
9. `bash argv.sh $opt` — lab.md states this prints `1|<-n>`: the shell handed
   over exactly one word.
10. `echo $opt` — compare against p5.
11. `echo "$opt"` — identical result: same argv, so quoting can't fix option
    parsing.
12. `lab check bash L1.3`

**CHECK LOGIC (check.sh)** — standard template (shebang, `set -euo pipefail`,
LAB_WORKSPACE/LAB_CHECKLIB guards, `source "$LAB_CHECKLIB"`, mode 0644), then:
- `assert_file_exists 'predictions.txt' 'write all four predictions (p1, p2, p3, p5) before running anything — step 2'` — hint: the answer file is missing.
- `assert_file_contains_fixed 'predictions.txt' 'p1=2|<report><final.txt>' 'p1 — bash argv.sh $f: the expansion result is split on whitespace before argv.sh ever runs'` — fixed match: value contains `|` `<` `>`.
- `assert_file_contains_fixed 'predictions.txt' 'p2=1|<report final.txt>' 'p2 — bash argv.sh "$f": double quotes stop the split'` — fixed match, same reason.
- `assert_file_contains 'predictions.txt' '^p3=b$' 'p3 — one letter: trace the exact words cp receives after $f expands unquoted'` — anchored ERE.
- `assert_file_contains 'predictions.txt' '^p5=b$' 'p5 — one letter: rerun echo $opt and look closely at what printed'` — anchored ERE.
- `assert_file_exists 'backup/report final.txt' 'step p4 — run the QUOTED copy: cp "$f" backup/'` — the artifact gate for p4.
- `ck_summary`
(Hint strings single-quoted in check.sh so `$f`/`$opt` stay literal. No absolute
paths, no banned tokens.) CI fabrication: `mkdir -p backup; printf 'Q2 incident report\n' > 'backup/report final.txt'; printf '%s\n' 'p1=2|<report><final.txt>' 'p2=1|<report final.txt>' 'p3=b' 'p5=b' > predictions.txt` — verified all six assertions' greps pass against exactly this.

**QUIZ (plaintext answers; builder base64-encodes with `printf '%s' 'answer' | base64 -w0`):**
1. choice — "`bash argv.sh $f` became two arguments. Which pipeline step
   manufactured the second word?" a) tokenization of the line you typed — the
   space was always a separator b) word splitting of the unquoted expansion
   RESULT, after $f was replaced c) pathname expansion matched two files → **b**
2. choice — "The reflex rule this course drills from here on:" a) quote a
   variable only when you know it contains spaces b) double-quote every
   expansion unless you can say exactly why not c) prefer single quotes around
   $var → **b**
3. choice — "Which characters in pure DATA (say, a filename) can change what a
   command does?" a) only shell metacharacters you type yourself, like ; and |
   b) a space, a newline, or a leading dash c) none — data is inert once it's
   inside a variable → **b**

**RECAP:**
```
unquoted $var = expand, THEN split the result — one variable can become several words
double quotes stop the split: "$f" stays one argument, space and all
data attacks commands: a space, newline, or leading dash in a filename changes what runs
```

**HINTS:** L1: The grader reads predictions.txt — four keys (p1, p2, p3, p5), no
spaces around `=` — plus one file it expects to find inside backup/. `ls` the
workspace and compare against the step list. L2: p1 and p2 are full argv.sh
output lines in `N|<...>` form — decide how many words the shell hands over once
$f is replaced by its value, unquoted vs quoted; p3 and p5 are single letters;
the backup/ file only appears if your cp used quotes. L3: Run each line and
transcribe: `f="report final.txt"; bash argv.sh $f; bash argv.sh "$f"; cp $f backup/; cp "$f" backup/; ls backup; opt=-n; bash argv.sh $opt; echo $opt` —
the run is the legitimate answer sheet; copy the two argv.sh lines into p1/p2
verbatim and pick the letters matching what you saw.

---

### L1.4 — Quoting — single vs double vs none, decided by what you want expanded
**PREDICT · gate:false · est 15 · files/: argv.sh · recall.json: no**
**objective:** "Choose between single, double, and no quotes by predicting exactly which expansions fire and how many words reach the command."

**BRIEF gist (builder expands to ≤10 lines):** One question decides every quoting
choice: *what do you want expanded?* Single quotes: nothing, ever. Double quotes: `$`
expands, but the result stays one word — no splitting, no globbing. Bare: expand, then
split, then glob. Five one-line experiments against argv.sh, one variable
(`user=root`), and the decision rule falls out. Honor line verbatim: "the check can't
tell whether you predicted first — you're only cheating your own reps."

**files/argv.sh** (byte-identical to every other PREDICT lab's copy, per track convention):
```bash
#!/usr/bin/env bash
# argv.sh — prints: <number of arguments>|<each argument in angle brackets>
out=""
for a in "$@"; do
  out+="<${a}>"
done
printf '%s|%s\n' "$#" "$out"
```

**TEACHING ARTIFACT:**

State pin: every sample line runs in a shell where the learner has already typed
`user=root` (same shell, same session — GUIDED step 2). No `export` needed: argv.sh
never reads `user`; the *parent* shell performs all expansion before argv.sh even
starts. predictions.txt keys are `p1`–`p5`; each value is the complete line argv.sh
prints, byte-exact.

1. `bash argv.sh '$user'` -> `1|<$user>` — single quotes: NOTHING expands; the five
   bytes `$user` travel as one literal word.
2. `bash argv.sh "$user"` -> `1|<root>` — double quotes: `$user` expands to `root`,
   and the result is never re-split — exactly one word.
3. `bash argv.sh "phase $user"` -> `1|<phase root>` — expansion happens *inside* the
   quoted word; the space is literal, so still exactly one word.
4. `bash argv.sh phase $user` -> `2|<phase><root>` — quoting is per-word: `phase` and
   `$user` were already separate words before expansion; bare `$user` expands (and
   would then split on IFS whitespace — `root` contains none, so it stays whole).
5. `bash argv.sh "'$user'"` -> `1|<'root'>` — inside double quotes, single quotes are
   ordinary characters; they protect nothing, the `$` still expands, and the word
   delivered is `'root'`.

The decision table (this is the lab's takeaway — lab.md prints it after the runs):

| you want | reach for |
|---|---|
| the literal characters, zero expansion | single quotes |
| expansion, delivered as exactly one word | double quotes — the default |
| expansion PLUS the shell splitting/globbing the result | bare — rare, deliberate; say why in a comment |

Close by restating the L1.3 reflex as the phase rule: **default to double quotes
around every expansion.** Single quotes when you mean "no expansion at all." Bare is
not a non-choice — it is a request for splitting and globbing, and it should look
intentional.

**SHELLCHECK STATUS:**
- files/argv.sh — clean: zero output from `shellcheck -x -S style` (0.9.0). Verified at plan time (bare directory and with the repo's `.shellcheckrc shell=bash` beside it).
- Typed sample lines are not shellcheck targets (line 1's `'$user'` would trip SC2016 if it lived in a file; it never does — the learner types it).
- check.sh — clean, with two landmines spelled out for the builder: (1) the p1 pattern MUST be written `"p1=1|<\$user>"` (escaped dollar inside double quotes). The natural single-quoted form `'p1=1|<$user>'` trips SC2016 (info) under `-S style` on 0.9.0, and `# shellcheck disable=` is banned repo-wide. Both forms verified at plan time. All other patterns carry no `$` and use plain double quotes. (2) the clean sweep also depends on the kit template's `# shellcheck source=/dev/null` directive on the line above `source "$LAB_CHECKLIB"` — without it SC1090 (warning) fires; that directive is a source hint, not a banned disable (precedent: tracks/demo/phases/p0/L0.0-meet-the-kit/check.sh). Verified both ways by execution.

**SANDBOX NOTE:** the only write in this lab is `predictions.txt` inside
`workspace/bash/L1.4/` (plus editor temp files, same directory). Sample lines execute
the workspace copy of argv.sh; check.sh writes nothing and reads only workspace files.
No system reads, no installs, no network. Destructive-command tooling: none in P0/P1 —
decoy-tree helpers are [FUTURE-PHASE-ONLY].

**GUIDED STEPS outline (8 commands total):**
1. `lab start bash L1.4` seeded argv.sh. Read the five sample lines printed in lab.md
   (commands only — never the outputs). BRIEF carries the honor line.
2. `user=root` — set the variable in THIS shell; every sample line runs in the same
   session. Troubleshooting note in lab.md: if any run prints `1|<>`, you forgot this
   step in the current shell.
3. Before running anything, write all five predictions into `predictions.txt`: keys
   `p1=` through `p5=`, no spaces around `=`, each value the exact line argv.sh will
   print. lab.md shows the format with the already-public generic example only
   (`bash argv.sh a "b c"` -> `2|<a><b c>`), never a p1–p5 value.
4.–8. Run sample lines 1–5 one at a time; after each, compare the real line against
   your prediction before moving to the next.
9. Where you missed, correct predictions.txt to the observed line — the run is the
   legitimate answer source; the miss is the lesson (honor system).
10. `lab check bash L1.4`.

**CHECK LOGIC (check.sh):**
```bash
assert_file_exists "predictions.txt" \
  "step 3 — write all five predictions before running anything (keys p1..p5)"
assert_file_contains_fixed "predictions.txt" "p1=1|<\$user>" \
  "p1 — single quotes: rerun sample line 1 and transcribe the whole output line"
assert_file_contains_fixed "predictions.txt" "p2=1|<root>" \
  "p2 — double quotes: rerun sample line 2 and transcribe the whole output line"
assert_file_contains_fixed "predictions.txt" "p3=1|<phase root>" \
  "p3 — expansion inside one quoted word: rerun sample line 3 and transcribe"
assert_file_contains_fixed "predictions.txt" "p4=2|<phase><root>" \
  "p4 — two separate words: rerun sample line 4 and transcribe"
assert_file_contains_fixed "predictions.txt" "p5=1|<'root'>" \
  "p5 — single quotes inside doubles are plain characters: rerun line 5 and transcribe"
assert_output_contains 'double quotes keep one word' '1\|<phase root>' \
  'run: bash argv.sh "phase root"' -- bash -- argv.sh 'phase root'

ck_summary
```
All five value asserts are fixed-literal (every value contains ERE metacharacters
`| < >`); the live proof passes the *already-expanded* text `phase root` — it
demonstrates the argv, not the expansion, and its ERE escapes the pipe (`1\|`). This
exact assertion set was executed against harness/checklib.sh at plan time AND
re-executed at verify time under the fence env (`env -i`, pinned PATH/HOME/TMPDIR,
stdin=/dev/null): 7/7 pass.
CI fabrication (bash+coreutils only): `mkdir -p workspace/bash/L1.4 && cp tracks/bash/phases/p1/L1.4-quoting/files/argv.sh workspace/bash/L1.4/ && printf '%s\n' 'p1=1|<$user>' 'p2=1|<root>' 'p3=1|<phase root>' 'p4=2|<phase><root>' "p5=1|<'root'>" > workspace/bash/L1.4/predictions.txt` (quiz driven via stdin as usual).

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "When is a BARE (unquoted) expansion the right call?" a) whenever the
   value contains no spaces b) never — always quote everything c) when you
   deliberately want the shell to split or glob the result — e.g. a variable holding a
   glob pattern that should match files; rare, and it should look intentional → **c**
2. choice — "Inside `"'$user'"` (double quotes outermost), what do the single quotes
   do?" a) they block the expansion — the argument is literally $user b) nothing
   special — they are ordinary characters there, and $user still expands c) it is a
   syntax error: quotes cannot appear inside quotes → **b**
3. choice — "(L1.7 preview) Does `"$(hostname)"` still run hostname inside double
   quotes?" a) yes — command substitution expands inside double quotes; the quotes
   only stop splitting/globbing of its output b) no — double quotes make it literal
   text c) only when the shell is interactive → **a**

**RECAP:**
```
single quotes: nothing expands — what you typed is the word the command gets
double quotes: $ expands, result stays one word — the default around every expansion
bare means "please split and glob" — rare, deliberate, and it should look that way
```

**HINTS:**
L1: "The grader reads predictions.txt: five keys p1–p5, no spaces around =, each value
the complete line argv.sh printed — count, pipe, and angle brackets included."
L2: "One rule per line: single = literal always (line 1); double = expand but keep one
word (lines 2, 3); bare words expand separately (line 4); inside double quotes a
single quote is just a character and the $ still fires (line 5). Re-check your word
count on p4 and your quote characters on p5."
L3: "With user=root set in this shell, run each sample line exactly as printed and
transcribe each output line verbatim as its key's value — run, copy, paste, all five.
The run is the answer sheet."

---

### L1.5 — Globbing — `*` `?` `[...]` and pathname expansion
**PREDICT · gate:false · est 15 · files/: argv.sh, app.log, error.log, app.conf, notes.txt, sub/readme.md · recall.json: no**
**objective:** "Predict exactly which filenames each glob expands to against a pinned workspace — including the no-match-stays-literal trap and quotes turning globbing off — before running anything."

meta.json title (map title with backticks stripped, per conventions §12): `Globbing — * ? [...] and pathname expansion`. No flawed files ship, so meta.json carries no `teaching_samples` key.

**files/argv.sh** (byte-identical to every other PREDICT lab's copy — conventions §3):
```bash
#!/usr/bin/env bash
# argv.sh — prints: <number of arguments>|<each argument in angle brackets>
out=""
for a in "$@"; do
  out+="<${a}>"
done
printf '%s|%s\n' "$#" "$out"
```

**files/app.log** (payload — content never graded, one line + trailing newline; same for the next four files):
```
app: started ok
```

**files/error.log:**
```
error: disk full (demo line)
```

**files/app.conf:**
```
retries=3
```

**files/notes.txt:**
```
scratch notes, payload only
```

**files/sub/readme.md** (the bait for p3 — one level down, invisible to top-level globs):
```
readme lives in sub/, not the top level
```

**TEACHING ARTIFACT:**

CRITICAL STATE PIN — at glob time (steps 3–8) the workspace contains EXACTLY seven entries: `app.conf`, `app.log`, `argv.sh`, `error.log`, `notes.txt`, `predictions.txt` (the learner already wrote it — lab.md orders predictions FIRST), and the directory `sub/` (containing only `readme.md`). Every match list below accounts for all seven; `notes.txt` (n…), `predictions.txt` (p…), and `sub` (s…) match none of the six patterns by design. Any dotfiles the kit adds (`.home`, `.tmp` appear at check time) are irrelevant — `*` skips dotfiles. All names are plain lowercase ASCII so C and en_US.UTF-8 collation give the same order.

Format reminder printed above the table in lab.md: `bash argv.sh a "b c"` → `2|<a><b c>`; zero args → `0|`.

| # | sample line (learner types) | exact output | mechanism |
|---|---|---|---|
| p1 | `bash argv.sh *.log` | `2|<app.log><error.log>` | pathname expansion replaces the unquoted pattern with every EXISTING name ending in `.log`, sorted |
| p2 | `bash argv.sh app.*` | `2|<app.conf><app.log>` | the `.` is literal; `*` covers both suffixes; `argv.sh` has no `app.` prefix, so it's out |
| p3 | `bash argv.sh *.md` | `1|<*.md>` | zero matches at the top level — `readme.md` is inside `sub/` and `*` never recurses; a no-match pattern survives as the LITERAL word (bash default; `nullglob` would delete it instead, off by default). THE gotcha of this lab |
| p4 | `bash argv.sh [ae]*` | `4|<app.conf><app.log><argv.sh><error.log>` | `[ae]` = exactly one char, `a` or `e`; argv.sh matches its own glob — expansion runs on whatever is really in the cwd, the tool sees itself |
| p5 | `pat="*.log"; bash argv.sh $pat` | `2|<app.log><error.log>` | order of expansions: `$pat` expands FIRST to `*.log`; the result is unquoted, so globbing then runs on it — identical to p1 |
| p6 | `bash argv.sh "$pat"` (same shell — `pat` still set from p5) | `1|<*.log>` | double quotes suppress pathname expansion of the expansion's result: one literal argument |

All six lines exit 0. Sort-order note on p4 (state it in lab.md): the order is plain byte order — `app.conf` < `app.log` (char 5: `c` < `l`), both `app.*` names < `argv.sh` (char 2: `p` 0x70 < `r` 0x72), `argv.sh` < `error.log` (char 1: `a` < `e`). Verified identical under LC_ALL=C and LC_ALL=C.UTF-8 (the baseline shell's default LANG; the `env -i` check fence carries no LANG at all, so it runs under C/POSIX — irrelevant anyway, since no glob runs at check time). en_US.UTF-8 is not installed on the baseline machine (`locale -a`: C, C.utf8, POSIX); invoking p4 with LC_ALL=en_US.UTF-8 while it is missing adds exactly two `bash: warning: setlocale` stderr lines and leaves the output line unchanged — verified. Re-check the order only if that locale is ever generated `[VERIFY-AT-BUILD]`.

**SHELLCHECK STATUS:** files/argv.sh — clean: zero output from `shellcheck -x -S style` (0.9.0), verified both in a bare directory and beside a `.shellcheckrc` containing `shell=bash`. The five payload files (.log/.conf/.txt/.md) are not shell scripts and are not shellcheck targets. Typed sample lines (p1–p6) are not shellcheck targets per conventions §4. No flawed files in this lab.

**SANDBOX NOTE:** every command reads only the cwd listing and runs `bash` on a workspace file; the sole write is the learner's own `predictions.txt` — everything lands inside `workspace/bash/L1.5/`. No system reads, no network, no installs. Quiz Q1's `rm *.log` is DISCUSSED, never executed. Destructive-command tooling (decoy trees) is [FUTURE-PHASE-ONLY] — none here.

**BRIEF gist (builder expands to ≤10 lines):** Globbing (pathname expansion) turns `*`, `?`, and `[...]` into filenames that actually exist in the current directory. It runs LAST — after variable expansion and word splitting — and only on unquoted words. A pattern that matches nothing stays literal (bash default; `nullglob` exists to drop it instead, off by default). `*` never recurses into subdirectories and skips dotfiles; `?` matches exactly one character. Honor line (mandatory, conventions §4): "the check can't tell whether you predicted first — you're only cheating your own reps."

**GUIDED STEPS outline (9 commands total):**
1. `ls` — take inventory BEFORE predicting. Expect (one per line when piped; your terminal shows columns): `app.conf app.log argv.sh error.log notes.txt sub`. Note `sub` is a directory; `readme.md` hides inside it.
2. Write all six predictions into `predictions.txt` — keys `p1=` … `p6=`, no spaces around `=`, each value the FULL line argv.sh will print. Saving this file adds `predictions.txt` to the directory — count it when you walk each pattern (none of today's six patterns matches it, by design).
3. `bash argv.sh *.log`
4. `bash argv.sh app.*`
5. `bash argv.sh *.md`
6. `bash argv.sh [ae]*`
7. `pat="*.log"; bash argv.sh $pat`
8. `bash argv.sh "$pat"` — same shell, `pat` is still set.
9. Compare each real line against your prediction; correct any misses in `predictions.txt` (the rep was the prediction — the grade needs the true lines). Then: `lab check bash L1.5`

**CHECK LOGIC (check.sh):** no live glob at check time — the workspace state has changed by then (learner artifacts accumulated, fence created `.home`/`.tmp`), so the grader asserts six fixed literal lines only. All values contain ERE metacharacters (`| < > * [ ]`), so every line assert is `assert_file_contains_fixed` (conventions §2). All literal/hint arguments single-quoted (values contain `*`, `[`, `$`, `|` — no expansion allowed).
- `assert_file_exists 'predictions.txt' 'step 2 — write the six p<N>= prediction lines before running anything'`
- `assert_file_contains_fixed 'predictions.txt' 'p1=2|<app.log><error.log>' 'p1 — re-run: bash argv.sh *.log and transcribe the exact output line'`
- `assert_file_contains_fixed 'predictions.txt' 'p2=2|<app.conf><app.log>' 'p2 — re-run: bash argv.sh app.* and transcribe the exact output line'`
- `assert_file_contains_fixed 'predictions.txt' 'p3=1|<*.md>' 'p3 — readme.md sits inside sub/ and * never recurses; re-run: bash argv.sh *.md'`
- `assert_file_contains_fixed 'predictions.txt' 'p4=4|<app.conf><app.log><argv.sh><error.log>' 'p4 — four entries start with a or e, and argv.sh sees itself; re-run: bash argv.sh [ae]*'`
- `assert_file_contains_fixed 'predictions.txt' 'p5=2|<app.log><error.log>' 'p5 — pat expands first, then the unquoted result globs; re-run line p5 and transcribe'`
- `assert_file_contains_fixed 'predictions.txt' 'p6=1|<*.log>' 'p6 — double quotes suppress the glob; re-run line p6 and transcribe'`
- `ck_summary`
CI fabrication recipe: `printf '%s\n' 'p1=2|<app.log><error.log>' 'p2=2|<app.conf><app.log>' 'p3=1|<*.md>' 'p4=4|<app.conf><app.log><argv.sh><error.log>' 'p5=2|<app.log><error.log>' 'p6=1|<*.log>' > predictions.txt` in the workspace, then drive the quiz with `printf 'b\nc\nb\n' | lab check bash L1.5`.

**QUIZ (plaintext answers; builder base64-encodes with `printf '%s' 'answer' | base64 -w0`):**
1. choice — "A directory contains NO .log files and you run `rm *.log`. What does rm actually receive?" a) nothing — the glob expands to zero words and rm silently succeeds b) the literal string `*.log` — rm then fails: `rm: cannot remove '*.log': No such file or directory` c) the shell aborts with a no-match error and rm never runs → **b** (a is nullglob behavior, off by default; c is zsh/failglob behavior)
2. choice — "In this workspace, what does `bash argv.sh "*"` print?" a) `0|` b) `7|<app.conf><app.log><argv.sh><error.log><notes.txt><predictions.txt><sub>` c) `1|<*>` → **c** (b is what the UNQUOTED `bash argv.sh *` prints — verified)
3. choice — "`pat="*.log"`, then `bash argv.sh $pat` (unquoted). Which happens first?" a) globbing, then `$pat` expansion b) `$pat` expansion first — globbing then operates on its result because it is unquoted c) neither: a variable's value can never be globbed → **b**

**RECAP:**
```
globs match names that exist in the cwd — expansion runs last, and only on unquoted words
no match? bash keeps the pattern as a literal word (nullglob would drop it — off by default)
* never recurses and skips dotfiles; double-quoting the word switches globbing off entirely
```

**HINTS:** L1: the grader reads predictions.txt — six keys p1…p6, no spaces around `=`, each value the FULL line argv.sh prints in `N|<…>` format; start from a fresh `ls`, because every answer is determined by what is actually in this directory. L2: inventory at run time is app.conf, app.log, argv.sh, error.log, notes.txt, predictions.txt, sub/ — walk each pattern against that list in byte order; remember readme.md sits INSIDE sub/ (p3), argv.sh itself starts with `a` (p4), and quotes change what expands (p5 vs p6). L3: run each of the six printed lines exactly as shown and transcribe each output line verbatim into predictions.txt — the run is the legitimate answer source; then `lab check bash L1.5`.

---

### L1.6 — Exit codes — `$?`, and "success" is 0 (backwards from every language you know)
**DECODE · gate:false · est 15 · files/: app.log, pulse.sh · recall.json: no**
**objective:** "Decode a health probe that turns a log scan into an exit code, and prove that $? holds one command's verdict only until the very next command overwrites it."

meta.json title (backticks stripped, per conventions §12): `Exit codes — $?, and "success" is 0 (backwards from every language you know)`

**BRIEF gist (builder expands to ≤10 lines):** Every command leaves a one-byte verdict
behind in `$?`: 0 means success — backwards from every language you know, where 0 is
false — and nonzero means some flavor of failure (each tool picks its own: grep says 1
for "no match", GNU ls says 2 for "serious trouble"). Two rules carry this lab: `if`
consumes the CODE, not the output; and EVERY command overwrites `$?` — including the
echo you just used to look at it. pulse.sh turns a log scan into an exit code because
scripts are commands too: its `exit 1` is a report to whoever calls it.

**files/app.log:** (data file — six lines: five INFO, one ERROR, zero FATAL anywhere)
```
2026-07-12 09:00:01 INFO service started pid=4312
2026-07-12 09:00:02 INFO config loaded ok
2026-07-12 09:00:05 INFO listener up on port 8443
2026-07-12 09:14:31 ERROR upstream timeout after 30s
2026-07-12 09:14:33 INFO retry 1 succeeded
2026-07-12 09:30:00 INFO heartbeat ok
```

**files/pulse.sh:** (working sample, intent=clean, byte-exact)
```bash
#!/usr/bin/env bash
# pulse.sh — tiny health probe: scan a log, report, exit accordingly.
log="app.log"
if grep -q "ERROR" "$log"; then
  echo "status: degraded"
  exit 1
fi
echo "status: healthy"
exit 0
```

**TEACHING ARTIFACT:**

*Decoding pulse.sh — comprehension notes (printed in lab.md before the run steps):*
- `grep -q "ERROR" "$log"` — `-q` silences all output because nobody reads it: the exit
  code IS the answer. grep's contract: 0 = match found, 1 = no match, 2 = real error
  (e.g. `grep -q FATAL nolog.txt` prints `grep: nolog.txt: No such file or directory`
  and exits 2).
- `"$log"` is quoted — the L1.3 reflex, one clause: a space-bearing value stays one
  argument instead of splitting into several.
- `if grep -q …; then` — `if` runs the command and branches on its exit code alone.
  grep -q prints nothing, so there is nothing else it COULD test.
- `exit 1` / `exit 0` — the script propagates the verdict upward: scripts are commands
  too. A cron job, a CI step, or another `if` reads pulse.sh's code exactly the way
  pulse.sh reads grep's. On a log with no ERROR line it prints `status: healthy` and
  exits 0; on the shipped log it prints `status: degraded` and exits 1.

*Run transcript — REAL outputs, executed and verified on the baseline machine
(bash 5.2.21, GNU coreutils 9.4, GNU grep 3.11):*

1. `bash pulse.sh`
   ```
   status: degraded
   ```
   exit code 1 — grep -q found the ERROR line, the if-branch printed and ran `exit 1`.
   The message is stdout; the verdict is the code — two separate channels.
2. `echo $?` (typed immediately after, nothing in between)
   ```
   1
   ```
   `$?` still holds pulse.sh's exit code — it persists until the next command runs.
3. `grep -q INFO app.log; echo $?`
   ```
   0
   ```
   Match present; `-q` suppressed all output — the code carries the entire answer.
4. `grep -q FATAL app.log; echo $?`
   ```
   1
   ```
   No match: no output, no error message, and yet a definite verdict.
5. `ls ghost.txt; echo $?`
   ```
   ls: cannot access 'ghost.txt': No such file or directory
   2
   ```
   GNU ls exits 2 for "serious trouble" (a nonexistent command-line operand) — a
   different tool picks a different nonzero flavor. `[VERIFY-AT-BUILD: exact ls message
   text is machine/locale-variant — verified byte-exact, exit 2, on baseline coreutils
   9.4]`
6. THE AHA — run `ls ghost.txt` once more (fresh failure), then on the next line
   `echo $?; echo $?`:
   ```
   ls: cannot access 'ghost.txt': No such file or directory
   ```
   then
   ```
   2
   0
   ```
   The first echo reports ls's 2 — and by succeeding, overwrites `$?` with 0. The
   second echo is reporting the FIRST ECHO's success. Every command writes `$?`, even
   the one you used to look at it.

*answers.txt (workspace root, `key=value`, no spaces around `=`; q3/q4 options printed
in lab.md step 8):*
- q1 (value) — exit code of `bash pulse.sh` on the shipped log → **q1=1**
- q2 (value) — exit code of `grep -q FATAL app.log` → **q2=1**
- q3 (choice) — in step 6, why does the second `echo $?` print 0?
  a) `$?` resets to 0 every time it is read
  b) the first echo succeeded and overwrote it — every command writes `$?`
  c) echo always returns 0, so `$?` is meaningless after any echo
  → **q3=b** (c is the almost-true distractor: echo does return 0, but that is WHY the
  overwrite happens, not evidence that `$?` is meaningless)
- q4 (choice) — in `if grep -q "ERROR" "$log"; then …`, what does `if` actually test?
  a) grep's stdout text
  b) grep's exit code
  c) whether app.log is nonempty
  → **q4=b**

**SHELLCHECK STATUS:** files/pulse.sh — clean: zero output, exit 0, from
`shellcheck -x -S style` (0.9.0), verified both in a bare directory and with a
`.shellcheckrc` containing `shell=bash` adjacent (the repo-root rc situation).
files/app.log is data, not a shellcheck target. Typed sample lines in lab.md are not
shellcheck targets.

**SANDBOX NOTE:** The only write in this lab is answers.txt in `workspace/bash/L1.6/`.
`ls ghost.txt` is a failed read of a relative path inside the workspace and creates
nothing. No system reads, no installs, no destructive commands anywhere in the lab;
checklib's decoy-tree helpers remain [FUTURE-PHASE-ONLY].

**GUIDED STEPS outline (15 commands total, incl. the check — at the convention cap):**
1. `cat pulse.sh` — decode before running (DECODE discipline): find the three
   load-bearing pieces — `grep -q`, `exit 1`, `exit 0`.
2. `cat app.log` — the evidence: five INFO lines, one ERROR line, no FATAL anywhere.
3. `bash pulse.sh` then, on the next line with nothing in between, `echo $?` —
   expect `status: degraded` then `1`. Message = stdout; verdict = code.
4. `grep -q INFO app.log; echo $?` — quiet grep, match present → `0`.
5. `grep -q FATAL app.log; echo $?` — quiet grep, no match → `1`. Total silence still
   carries an answer.
6. `ls ghost.txt; echo $?` — a different tool, a different failure flavor: the ls
   error line, then `2`.
7. Run `ls ghost.txt` once more, then on the next line `echo $?; echo $?` — watch `2`
   then `0`. Explain it to yourself before moving on (this is q3).
8. lab.md prints the four questions with q3/q4 options here; learner writes the four
   keys into `answers.txt` (one `key=value` per line, no spaces around `=`) with any
   editor or printf.
9. `lab check bash L1.6`

**CHECK LOGIC (check.sh):**
```
assert_file_exists "answers.txt" "step 8 — write answers.txt in the workspace root: keys q1..q4, one key=value per line"
assert_file_contains "answers.txt" '^q1=1$' "q1 wants a digit — step 3: bash pulse.sh, then echo \$? with nothing in between"
assert_file_contains "answers.txt" '^q2=1$' "q2 wants a digit — step 5: grep -q FATAL app.log; echo \$? — silence still has a verdict"
assert_file_contains "answers.txt" '^q3=b$' "q3 — step 7: which command ran LAST before the second echo, and did it succeed?"
assert_file_contains "answers.txt" '^q4=b$' "q4 — grep -q prints nothing at all; reread pulse.sh line 4"
assert_cmd_fails "pulse.sh exits nonzero on a degraded log" "run: bash pulse.sh — the shipped log has an ERROR line" -- bash -- pulse.sh
assert_output_contains "pulse.sh names the state" 'status: degraded' "read the if-branch in pulse.sh" -- bash -- pulse.sh
ck_summary
```
Failure-hint gists: q1/q2 → rerun the named step and transcribe the digit; q3 → point
at the first echo as the last-run command; q4 → point back at the `if` line; live
proofs → run the shipped script. All EREs are metacharacter-free, so
`assert_file_contains` (anchored ERE) is correct throughout; no absolute paths.
`assert_output_contains` captures the command's output with `|| true`, so pulse.sh's
exit-1 cannot abort the check — verified against harness/checklib.sh.
CI fabrication: `printf 'q1=1\nq2=1\nq3=b\nq4=b\n' > answers.txt`; pulse.sh and
app.log arrive via `lab start`'s files/ copy, so the two live proofs need no
fabrication — they run under bash + grep, both on the fence PATH (checklib's own
assert_file_contains already shells out to grep, so this adds no new dependency).

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "You type: `true; false; echo $?` — what prints?"
   a) `0` b) `1` c) nothing — `false` stops the line → **b** (`$?` holds the LAST
   command's code; false exits 1, and `;` never stops a line)
2. choice — "A script ends without any explicit `exit`. Its exit code is…"
   a) always 0 b) the exit code of the last command it ran c) undefined until you set
   it → **b** (demo: a one-line script containing only `grep -q FATAL app.log` exits 1
   on the shipped log)
3. choice — "Why do hardened scripts write `if grep -q ERROR log` instead of running
   grep and then testing `[ $? -eq 0 ]`?"
   a) purely style — the two are identical in every way
   b) `if cmd` reads the code directly, leaving no window for another command to
   overwrite `$?`
   c) `[ ]` cannot compare numbers → **b** (L2 foreshadow: the `$?`-juggling pattern is
   exactly the kind of fragile line Phase 2 strict mode exists to kill)

**RECAP:**
```
every command leaves a one-byte verdict in $? — 0 means success, nonzero means some flavor of failure
EVERY command overwrites $? — including the echo you just used to look at it
if consumes the exit code, not the output; scripts are commands too — exit 1 is pulse.sh reporting upward
```

**HINTS:** L1: "The grader reads four keys from answers.txt (q1–q4) and runs pulse.sh
itself. Each answer comes from one numbered step — rerun the step whose number the
question names before guessing." L2: "q1 and q2 want the single digit `$?` holds
immediately after the command — run it, then `echo $?` with nothing in between (or on
the same line: `cmd; echo $?`). q3: list every command that ran between the ls and the
second echo. q4: look at pulse.sh line 4 — `if` runs grep and reads exactly one thing
back from it." L3: "Transcribe reality: `bash pulse.sh; echo $?` gives q1's digit and
`grep -q FATAL app.log; echo $?` gives q2's. For q3, the first echo is itself a command
that exits 0 — pick the option that says it overwrote `$?`. For q4, grep -q produces no
stdout at all, so text cannot be what `if` tests — pick the exit-code option."

---

### L1.7 — Command substitution — `$(...)` and reading nested commands
**PREDICT · gate:false · est 15 · files/: argv.sh, version.txt, servers.txt · recall.json: no**
**objective:** "Predict exactly what $(...) substitutes — the command's stdout with trailing newlines stripped — and whether the result splits or stays one word, reading nested substitutions inside-out."

meta.json title (backticks stripped per conventions §12): `Command substitution — $(...) and reading nested commands`. No `teaching_samples` key — no flawed file ships.

**BRIEF gist (builder expands to ≤10 lines; must carry the honor line):** `$(cmd)` runs cmd and replaces itself with cmd's stdout, trailing newlines stripped — then the normal expansion rules resume: unquoted, the result word-splits (L1.3's bug wearing a new mask); double-quoted, it stays one word. Nested substitutions read inside-out, innermost first. Only stdout is captured — stderr goes to your terminal and `$?` carries the exit code. Honor line verbatim: "the check can't tell whether you predicted first — you're only cheating your own reps."

**files/argv.sh** (byte-identical to every other PREDICT lab's copy, conventions §3):
```bash
#!/usr/bin/env bash
# argv.sh — prints: <number of arguments>|<each argument in angle brackets>
out=""
for a in "$@"; do
  out+="<${a}>"
done
printf '%s|%s\n' "$#" "$out"
```

**files/version.txt** (exactly this one line plus a trailing newline — 6 bytes):
```
2.4.1
```

**files/servers.txt** (exactly this one line plus a trailing newline; single space between the names — 12 bytes):
```
web01 web02
```

**TEACHING ARTIFACT** (plan-only — lab.md prints the five sample lines, both data-file contents, and the p5 options; it NEVER prints these expected values):

1. `bash argv.sh $(cat version.txt)` -> `1|<2.4.1>` — cat's stdout is `2.4.1` plus a newline; `$()` substitutes it with the trailing newline stripped, and the single whitespace-free token survives word splitting as one argv word.
2. `bash argv.sh $(cat servers.txt)` -> `2|<web01><web02>` — the substituted text `web01 web02` is UNQUOTED, so IFS word-splitting cuts the RESULT into two argv words; nothing about `$()` protects it (L1.3's bug wearing a new mask).
3. `bash argv.sh "$(cat servers.txt)"` -> `1|<web01 web02>` — double quotes suppress splitting of the substituted text: one word, interior space preserved.
4. `bash argv.sh $(basename $(pwd))` -> `1|<L1.7>` — read inside-out; the workspace dir name is the deterministic anchor (learner cwd is `workspace/bash/L1.7`, conventions §9 allows basename-derived answers):

   ```
   bash argv.sh $(basename $(pwd))
                          └─────┘  runs FIRST : pwd          -> …/workspace/bash/L1.7
                └───────────────┘  runs SECOND: basename …   -> L1.7
   words the shell finally runs:   bash argv.sh L1.7         -> 1|<L1.7>
   ```

   The result `L1.7` has no whitespace, so the unquoted substitution survives as one word.
5. p5 — conceptual choice, printed in lab.md exactly as:

   ```
   p5. missing.txt does not exist. You run:  v=$(cat missing.txt)
       What happens?
       a) v gets the literal text "cat: missing.txt: No such file or directory"
       b) cat's error prints to YOUR terminal (stderr is not captured); v is empty; $? is cat's exit code 1
       c) the shell aborts with an error
   ```

   Answer `p5=b` — one clause: `$()` captures stdout only. Real transcript (verified on the baseline machine, GNU coreutils cat):

   ```
   $ v=$(cat missing.txt)
   cat: missing.txt: No such file or directory
   $ echo $?
   1
   $ bash argv.sh $v
   0|
   ```

   The error line traveled on stderr straight to the terminal — it was never inside `v`; `v` is empty, so unquoted `$v` expands to zero words (`0|`); the assignment's `$?` is cat's exit code, 1.

**SHELLCHECK STATUS:**
- `files/argv.sh` — clean: zero output from `shellcheck -x -S style` (0.9.0), verified both bare and with the repo's `.shellcheckrc` (`shell=bash`) adjacent.
- `files/version.txt`, `files/servers.txt` — data files, not shellcheck targets.
- Typed sample lines are not shellcheck targets (conventions §4). If p4's line appeared in a SCRIPT, shellcheck 0.9.0 would flag BOTH substitutions with SC2046 ("Quote this to prevent word splitting" — verified: exactly two SC2046 annotations, one per unquoted substitution; count with `shellcheck -f gcc … | grep -c SC2046` -> 2 — the default tty format's wiki footer names SC2046 a third time); that unquoted result IS the lesson, so the builder must NOT quote-"fix" any sample line.

**SANDBOX NOTE:** the lab's only write is the learner creating `predictions.txt` inside `workspace/bash/L1.7/`. Every sample line only reads workspace files (`version.txt`, `servers.txt`, the deliberately absent `missing.txt`) and the cwd via `pwd`; the failing `cat` creates nothing (verified — workspace listing unchanged after it). check.sh reads `predictions.txt` and runs `bash -- argv.sh web01 web02`, all inside the fence. No installs, no system reads beyond cwd resolution. Destructive-command tooling: none in P0/P1 — `[FUTURE-PHASE-ONLY]`.

**GUIDED STEPS outline** (10 commands total):
1. Inspect the inputs (these are not graded sample lines): `cat version.txt` then `cat servers.txt` (2 cmds) — lab.md also prints both contents; exact bytes are needed to predict.
2. Write ALL five predictions into `predictions.txt` BEFORE running any sample line — keys `p1`…`p5`, no spaces around `=`; p1–p4 take the full output line in the `N|<...>` format, p5 takes a letter (editor, 0 cmds).
3. Run p1: `bash argv.sh $(cat version.txt)` — compare (1 cmd).
4. Run p2: `bash argv.sh $(cat servers.txt)` — compare; count the argv words (1 cmd).
5. Run p3: `bash argv.sh "$(cat servers.txt)"` — compare against p2 (1 cmd).
6. Run p4: `bash argv.sh $(basename $(pwd))` — read it inside-out before running (1 cmd).
7. Run the p5 transcript one line at a time: `v=$(cat missing.txt)` / `echo $?` / `bash argv.sh $v` (3 cmds) — watch which stream carried the error and how many words `$v` produced.
8. `lab check bash L1.7` (1 cmd).

**CHECK LOGIC (check.sh):** standard template (shebang, `set -euo pipefail`, both `:?` guards, `source "$LAB_CHECKLIB"`, mode 0644), then:
```
assert_file_exists "predictions.txt" "write p1..p5 into predictions.txt before running anything — one key=value per line"
assert_file_contains_fixed "predictions.txt" "p1=1|<2.4.1>" "p1 — rerun sample line p1 and transcribe its whole output line, | and <> included"
assert_file_contains_fixed "predictions.txt" "p2=2|<web01><web02>" "p2 — rerun sample line p2 and count the argv words the unquoted result produced"
assert_file_contains_fixed "predictions.txt" "p3=1|<web01 web02>" "p3 — rerun sample line p3; the double quotes change the word count vs p2"
assert_file_contains_fixed "predictions.txt" "p4=1|<L1.7>" "p4 — rerun sample line p4 from the workspace root and read it inside-out"
assert_file_contains "predictions.txt" '^p5=b$' "p5 — rerun the three-line transcript and watch which stream the error text used"
assert_output_contains "substitution feeds argv" '2\|<web01><web02>' "step p2 — the unquoted result splits into two argv words" -- bash -- argv.sh web01 web02
ck_summary
```
p1–p4 use `assert_file_contains_fixed` because every value contains ERE metacharacters (`| < >`); p5 is anchored ERE per conventions §2. The live proof runs the same argv the p2 expansion produced. No absolute-path literals, no banned tokens; `bash -- argv.sh` is the allowed invocation form. (Verified: this exact assertion sequence run under the fence — `env -i`, cwd-pinned, real checklib — passes 7/7 exit 0 on the fabricated workspace and fails with exit 1 on wrong values.) CI fabrication: `printf 'p1=1|<2.4.1>\np2=2|<web01><web02>\np3=1|<web01 web02>\np4=1|<L1.7>\np5=b\n' > predictions.txt` plus writing argv.sh (conventions §3 content, via heredoc) into the fabricated workspace — bash+coreutils only.

**QUIZ (plaintext answers; builder base64-encodes with `printf '%s' 'answer' | base64 -w0`):**
1. choice — "Backticks \`cmd\` versus `$(cmd)`?" a) different features — backticks also capture stderr b) the same feature — but `$(...)` nests without escaping, so prefer it c) backticks run in the current shell, `$()` in a subshell → **b**
2. choice — "In `echo "now: $(date)"`, does the substitution still run inside the double quotes?" a) yes — double quotes permit `$`-expansions; single quotes would not b) no — any quotes make it literal text c) only if date is exported → **a**
3. text — "`$(cmd)` captures exactly one of cmd's output streams — which one?" → **stdout** (accept: `standard output`, `standard out`, `stdout only`)

(No verbatim overlap with graded keys: p5 grades the outcome of a failing substitution; q3 asks which stream is captured in general — same concept, different angle per conventions §7.)

**RECAP:**
```
$(cmd) = run cmd, substitute its stdout, strip trailing newlines — then normal expansion rules resume
unquoted, the substituted text word-splits like any variable (L1.3 in a new mask); "$(...)" stays one word
read nested $() inside-out; only stdout is captured — stderr hits your terminal, $? carries the exit code
```

**HINTS:** L1: "The grader reads predictions.txt: five keys p1..p5, no spaces around =. p1–p4 take the whole argv.sh output line in the N|<...> format; p5 takes a single letter." L2: "Substitute first: $(...) becomes the command's stdout minus trailing newlines. Then apply L1.3's rule — unquoted results split on whitespace, double-quoted results stay one word. For p4 work inside-out: what does pwd print, and which part does basename keep? For p5, ask which stream $() actually captures." L3: "Run each sample line and transcribe its output byte-for-byte, | and <> included. For p5 run the transcript in your shell — v=$(cat missing.txt), then echo $?, then bash argv.sh $v — and note where the error text appeared, what $? held, and how many words $v produced."

---

### L1.8 — Phase gate: predict the output of an expansion-heavy script, line by line
**PREDICT · gate:true · est 20 · files/: report.sh, hosts.txt, app.log, error.log · recall.json: no**
**objective:** "Prove the Phase 1 expansion model is internalized by predicting all ten numbered output lines of an expansion-heavy script before running it once."

Nothing new — integration. One 18-line script fires every mechanism from L1.1–L1.7; the
learner predicts its ENTIRE output into predictions.txt (p1…p10, full lines including the
`N:` prefix) before running `bash report.sh` exactly once. The gate's breadth rides
predictions.txt — quiz.json stays hard-capped at 3. argv.sh is deliberately NOT shipped
(directive: the gate script is self-contained; splitting is made visible with `set -- … ; $#`).

**files/report.sh** (TEACHING SAMPLE header on line 2 — the unquoted expansions ARE the
lesson; expected SC codes SC2046, SC2086, SC2154, see SHELLCHECK STATUS):
```bash
#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# L1.8 phase gate: predict all ten numbered lines BEFORE running.
host="web01"
printf '1:%s\n' "$host_id"
printf '2:%s\n' "${host}_id"
hosts=$(cat hosts.txt)
printf '3:%s\n' '*.log'
printf '4:%s\n' "$hosts"
set -- $hosts
printf '5:argc=%s\n' "$#"
printf '6:%s %s\n' *.log
printf '7:%s\n' *.conf
printf '8:%s\n' "$(basename "$(pwd)")"
set -- $(cat hosts.txt)
printf '9:argc=%s\n' "$#"
grep -q FATAL app.log
printf '10:rc=%s\n' "$?"
```

**files/hosts.txt** (binding: exactly one line, single space, trailing newline):
```
web01 web02
```

**files/app.log** (one line; must NOT contain the string `FATAL` — line 17 depends on it):
```
INFO boot ok
```

**files/error.log** (one line; content irrelevant — its *presence* feeds the `*.log` glob):
```
ERROR disk low
```

**TEACHING ARTIFACT — the phase's summary table.** Pinned state when the script runs: cwd is
`workspace/bash/L1.8`; files present are exactly report.sh, hosts.txt, app.log, error.log,
and the learner's predictions.txt (neither glob matches the `.txt` files or report.sh).
Verified end-to-end on the baseline machine (bash 5.2.21); `bash report.sh` prints exactly
these 10 lines and exits 0 (the last printf succeeds):

| key | script line(s) | exact output | mechanism (which lab taught it) |
|---|---|---|---|
| p1 | 5 `printf '1:%s\n' "$host_id"` | `1:` | `_` is a name character — `$host_id` is ONE identifier, not `$host` + `_id`; it is unset, expands to empty; double quotes deliver one empty arg (L1.2). SC2154 is shellcheck naming exactly this bug. |
| p2 | 6 `printf '2:%s\n' "${host}_id"` | `2:web01_id` | `${host}` — the closing brace ends the name; `_id` is literal text (L1.2). |
| — | 7 `hosts=$(cat hosts.txt)` | (no output) | Command substitution; the trailing newline is stripped. The right side of an assignment is NEVER word-split — no quotes needed in assignment context (L1.7). |
| p3 | 8 `printf '3:%s\n' '*.log'` | `3:*.log` | Single quotes suppress every expansion — this pattern WOULD match two files, but quoted it stays the literal five characters (L1.4/L1.5). Contrast line 12. |
| p4 | 9 `printf '4:%s\n' "$hosts"` | `4:web01 web02` | Double quotes: expansion yes, word splitting no — one argument with its inner space intact (L1.4). |
| p5 | 10–11 `set -- $hosts` + `printf '5:argc=%s\n' "$#"` | `5:argc=2` | Bare `$hosts` expands, then the result splits on IFS whitespace into 2 words; `set --` makes the split countable as `$#` (L1.3). |
| p6 | 12 `printf '6:%s %s\n' *.log` | `6:app.log error.log` | Pathname expansion runs BEFORE printf: `*.log` → `app.log error.log` (sorted; plain-ASCII names, C and en_US collation agree); the two `%s` consume both words (L1.5). |
| p7 | 13 `printf '7:%s\n' *.conf` | `7:*.conf` | No file matches → bash leaves the pattern literal (default, nullglob off) (L1.5). |
| p8 | 14 `printf '8:%s\n' "$(basename "$(pwd)")"` | `8:L1.8` | Nested substitution: inner `$(pwd)` runs first (`…/workspace/bash/L1.8`), then basename trims to the workspace dir name; quoted, so no splitting (L1.7). |
| p9 | 15–16 `set -- $(cat hosts.txt)` + `printf '9:argc=%s\n' "$#"` | `9:argc=2` | Unquoted `$(cmd)` output is text that then gets word-split — the SAME bug as an unquoted `$var` (L1.7/L1.3). |
| p10 | 17–18 `grep -q FATAL app.log` + `printf '10:rc=%s\n' "$?"` | `10:rc=1` | app.log has no FATAL → grep exits 1; `$?` holds the LAST command's code; 0 = success, 1 here = "not found" (L1.6). |

**SHELLCHECK STATUS:** files/report.sh — TEACHING SAMPLE — intentionally flawed (header
exactly on line 2). Expected codes under `shellcheck -x -S style` (0.9.0, dialect bash from
the shebang; repo `.shellcheckrc` `shell=bash` agrees), verified at plan time on the baseline
machine: **SC2154** (line 5, host_id referenced but not assigned), **SC2086** (line 10,
unquoted `$hosts`), **SC2046** (line 15, unquoted `$(cat hosts.txt)`) — exactly three, none
others. meta.json therefore carries
`"teaching_samples": {"files/report.sh": ["SC2046", "SC2086", "SC2154"]}`.
Design note: line 8 uses a single-quoted glob (`'*.log'`), not `'$hosts'` — the `$`-in-single-
quotes variant adds a fourth code (SC2016, verified) over the ≤3 cap; the single-quote lesson
is unchanged. hosts.txt/app.log/error.log are data, not shellcheck targets; typed sample
lines in lab.md are not shellcheck targets; check.sh must be shellcheck-clean.

**SANDBOX NOTE:** report.sh reads only `./hosts.txt` and `./app.log` and queries `pwd`; it
writes NOTHING (pure stdout). The learner creates exactly one file, `predictions.txt`, inside
`workspace/bash/L1.8/`. check.sh reads predictions.txt and re-runs `bash -- report.sh`
cwd-pinned in the fence. No system reads, no installs, no destructive commands anywhere;
checklib's decoy-tree helpers remain [FUTURE-PHASE-ONLY].

**lab.md BRIEF (builder copies verbatim; 10 lines):**
```
The Phase 1 gate. Nothing new — one 18-line script, report.sh, fires
everything you have learned: ${} name boundaries, all three quoting
modes, word splitting, a glob that matches and one that does not,
nested and unquoted command substitution, and a final $?.
The phase model, verbatim: everything is text, and the shell transforms
that text through a fixed sequence of expansions before it runs anything.
Write ALL ten predictions into predictions.txt BEFORE you run the script
once. The check can't tell whether you predicted first — you're only
cheating your own reps. report.sh is flawed on purpose: its unquoted
expansions are the lesson (shellcheck names three of them).
```

**GUIDED STEPS outline (7 commands total):**
1. Read the script and its data — lab.md prints report.sh in full here (the sample lines the
   learner predicts; never the outputs): `cat report.sh` · `cat hosts.txt` ·
   `cat app.log error.log`. State the pinned state: you run from `workspace/bash/L1.8`; do
   not create extra files first — `predictions.txt` (next step) matches neither glob.
2. Predict: create `predictions.txt` with keys p1…p10, one per numbered output line, value =
   the FULL line including its `N:` prefix, no spaces around `=`. Format example (not an
   answer): `p1=1:whatever-you-predict`. Editor of choice: `nano predictions.txt`.
3. Run exactly once: `bash report.sh`.
4. Compare `cat predictions.txt` against the run — every miss is the lesson; correct the key
   to the real line byte-for-byte (the honor line already did its work in the BRIEF).
5. `lab check bash L1.8`.

**CHECK LOGIC (check.sh):** standard preamble (`#!/usr/bin/env bash`, `set -euo pipefail`,
both `: "${LAB_WORKSPACE:?…}"`/`: "${LAB_CHECKLIB:?…}"` guards, `source "$LAB_CHECKLIB"`,
mode 0644), then:
```bash
assert_file_exists "predictions.txt" 'step 2 — create predictions.txt with keys p1..p10 before running the script'
assert_file_contains "predictions.txt" '^p1=1:$' 'p1 — line 5: is $host_id one variable name, or $host plus _id? (L1.2)'
assert_file_contains "predictions.txt" '^p2=2:web01_id$' 'p2 — line 6: what does ${host} change about where the name ends? (L1.2)'
assert_file_contains_fixed "predictions.txt" 'p3=3:*.log' 'p3 — line 8: single quotes suppress every expansion, even a pattern that would match (L1.4)'
assert_file_contains "predictions.txt" '^p4=4:web01 web02$' 'p4 — line 9: double quotes expand but never split (L1.4)'
assert_file_contains "predictions.txt" '^p5=5:argc=2$' 'p5 — lines 10-11: bare $hosts splits on IFS whitespace; how many words? (L1.3)'
assert_file_contains "predictions.txt" '^p6=6:app.log error.log$' 'p6 — line 12: which files match *.log, in sorted order, and both %s get used (L1.5)'
assert_file_contains_fixed "predictions.txt" 'p7=7:*.conf' 'p7 — line 13: what happens to a glob that matches nothing? (L1.5)'
assert_file_contains "predictions.txt" '^p8=8:L1.8$' 'p8 — line 14: inner $(pwd) runs first; the lab runs from workspace/bash/L1.8 (L1.7)'
assert_file_contains "predictions.txt" '^p9=9:argc=2$' 'p9 — lines 15-16: unquoted $(cat hosts.txt) splits exactly like an unquoted variable (L1.7)'
assert_file_contains "predictions.txt" '^p10=10:rc=1$' 'p10 — lines 17-18: app.log contains no FATAL, and $? is the exit of the LAST command (L1.6)'
assert_output_contains 'report.sh really prints line 1' '^1:$' 'run it once from the workspace: bash report.sh' -- bash -- report.sh
ck_summary
```
Fixed-literal asserts only where the value carries ERE metachars (`*` in p3/p7); dots are not
on the conventions' route-to-fixed list, so p6/p8 stay anchored ERE. All hint strings are
single-quoted (safe under `set -u`; `$host_id` etc. never expand). No absolute paths;
`bash -- report.sh` is the explicitly allowed form.
CI fabrication: `lab start` seeds files/; then
`printf '%s\n' 'p1=1:' 'p2=2:web01_id' 'p3=3:*.log' 'p4=4:web01 web02' 'p5=5:argc=2' 'p6=6:app.log error.log' 'p7=7:*.conf' 'p8=8:L1.8' 'p9=9:argc=2' 'p10=10:rc=1' > predictions.txt`
— the live proof just runs the seeded report.sh (bash+coreutils only; verified to satisfy
every assert pattern above).

**QUIZ (plaintext answers; builder base64-encodes — integrative, never the graded keys):**
1. choice — "A command line is transformed in a fixed order before anything runs. Which
   order?" a) split into words → glob → expand variables b) tokenize → expand ($var, $(cmd))
   → word-split the unquoted results → glob c) glob → expand → split → tokenize → **b**
2. text — "Which quoting style lets $var expand but stops the result from being word-split?"
   → **double** (accept: `double quotes`, `double-quotes`)
3. choice — "Why is an unquoted $(cmd) the same bug as an unquoted $var?" a) both re-run the
   command once per output word b) both produce text that then gets word-split and
   glob-expanded c) command substitution ignores surrounding quotes → **b**

**RECAP:**
```
everything is text; the shell transforms it in a fixed order; quote unless you can say why not
tokenize → expand ($var, $(cmd)) → word-split unquoted results → glob — only then does anything run
no-match globs stay literal, quotes stop the machinery, and $? holds the LAST command's exit (0 = success)
```

**HINTS:** L1: "The grader reads one artifact: predictions.txt — ten keys p1..p10, no spaces
around =, each value the FULL output line including its N: prefix. Check every key exists and
is spelled exactly pN." L2: "Replay the fixed order on each line: expand ($var, ${var},
$(cmd)) → word-split whatever came out unquoted → glob. Four traps: $host_id is ONE name; the
hosts= assignment never splits; a glob with no match stays literal; the last line prints $?
of grep -q FATAL app.log — recall which number means success." L3: "Predict all ten first,
then run bash report.sh once — the run is the answer sheet. Transcribe every line you missed
into its key exactly, N: prefix included, then re-run lab check bash L1.8."

**FOR THE PHASE 2 BUILDER — L2.1 recall.json draft (5 questions, sources across P0+P1; do
NOT ship any of this in L1.8):**
1. choice (source: "bash L0.1") — "On Debian/Ubuntu, /bin/sh is a symlink to which shell?"
   a) bash b) dash c) busybox sh → **b**
2. choice (source: "bash L1.3") — "An unquoted $var whose value contains spaces…" a) stays
   one word — the quotes are only style b) splits into multiple words on IFS whitespace — the
   #1 bash bug c) raises a syntax error → **b**
3. choice (source: "bash L1.5") — "A glob like *.conf that matches no file…" a) expands to an
   empty string b) stays the literal text *.conf c) aborts the command with an error → **b**
4. text (source: "bash L1.4") — "Which quoting style lets $var expand but stops the result
   from word-splitting?" → **double** (accept: `double quotes`, `double-quotes`)
5. choice (source: "bash L1.6") — "Right after a command, $? prints 0. That means…" a) it
   failed b) it succeeded — 0 is success, backwards from most languages c) it produced no
   output → **b**

---

## 5. Build-session protocol (execute in this order)

1. Scaffold all 11 lab directories under `tracks/bash/phases/p0/` and `p1/` per §1
   slugs. `tracks/bash/track.json` already exists — do not touch it.
2. Author content straight from §4. Base64 every quiz/recall answer with
   `printf '%s' 'answer' | base64 -w0`; text answers lowercase-normalized, with the
   `accept_b64` variants listed here. argv.sh is byte-identical in every PREDICT
   lab's `files/` (copy from §3).
3. **Self-test sweep (PROMPTS.md no-fiction rule).** Execute every command in every
   lab.md yourself and paste the REAL captured output into the doc — never from
   memory, and never from this plan (the plan's values were machine-verified at plan
   time, but the build machine's run is authoritative). Resolve every
   `[VERIFY-AT-BUILD]` tag: `shfmt --version` after the L0.1 install; the apt
   transcript shapes; re-confirm dash's exact error lines and every argv/glob/exit
   value. Fix content to reality and log deviations in the build report.
4. Shellcheck gate: every shipped `files/*.sh` with clean intent → zero output from
   `shellcheck -x -S style`; every flawed sample → exactly the meta.json
   `teaching_samples` codes under the dialect the lab states. Then
   `./tools/lint-labs.sh` (includes the repo sweep) must pass clean.
5. Acceptance: extend `tests/acceptance.sh` per its demo pattern — for each lab,
   fabricate passing artifacts with bash+coreutils only (echo answer files and
   redirect-artifacts; `mkdir -p backup` + spaced filename for L1.3), run
   `printf 'a\nb\nc\n' | lab check bash <id>` expecting pass, plus one negative case
   per lab (delete one artifact → graded fail, exit 1). For L1.1, drive
   `lab start bash L1.1` with 5 piped recall answers and assert it never gates.
6. Run both phases end-to-end manually once (the author's own `lab check` pass per
   lab, quiz typed) before tagging `bash-p0` / `bash-p1` per PROMPTS.md.
7. Update `planned_execution.md` (mark bash p0/p1 done with evidence) — the build
   session's job, not this plan's.

## 6. Decisions & deviations log (for the reviewer)

- **gate:true on L0.3** — the map's Phase-0 exit-gate sentence is L0.3's exact
  content; demo + rust precedent put `gate:true` on the phase-final lab.
- **No recall.json on L0.1** — no earlier phase exists in this track; the kit lints
  only recall.json's position, not its presence (rust plan set the precedent).
- **argv.sh as a track-wide instrument** — one consistent, graded representation of
  word splitting (`N|<a><b>`) beats per-lab ad-hoc echo demos; the zero-arg `0|`
  case is why it's a loop, not a bare printf.
- **All scripts invoked as `bash <file>`** — exec-bit survival through the files/
  copy is uncertain and irrelevant to Phase 0–1 concepts; L0.3 teaches what `./x`
  *would* do via the shebang without depending on it.
- **check.sh never invokes shellcheck in P0/P1** — shellcheck evidence is graded
  from learner-redirected output files; keeps every check CI-fabricatable with
  bash+coreutils alone.
- **L1.8's breadth rides predictions.txt, not quiz.json** — the kit hard-caps
  quiz.json at 3 questions; the gate's line-by-line coverage lives in the graded
  prediction keys (same rationale as the rust gate's answers.txt).
- **L1.8's gate script is a TEACHING SAMPLE** — its unquoted expansions are the
  phase's point; it carries the header and its verified SC codes in meta.json
  rather than pretending to be clean.
- **est_minutes total: 155** across 11 labs (map gives no per-lab estimates; all
  within the ADHD contract's 10–20 band, gate labs at the top of it).
