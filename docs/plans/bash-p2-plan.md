# BASH TRACK — Phase 2 Build Plan (v1): Control Flow & Silent Failure

Binding content spec: `docs/curriculum/bash-literacy-lab-curriculum-v1.md` (Phase 2
section). Binding mechanical spec: `docs/kit-contracts.md`. Format/style template:
`docs/plans/bash-p01-plan.md` (this plan inherits its §2 harness constraints and §3
track conventions wholesale; only deltas are restated here). Reference
implementation of every file format: the built `tracks/bash/phases/p0/` + `p1/`.
This plan is the single source of design judgment for the build session — build it
mechanically; where reality contradicts a claim marked `[VERIFY-AT-BUILD]`, fix the
content to match reality and note the deviation in the build report.

Plan-time machine baseline (2026-07-14): Ubuntu 24.04.4 LTS on WSL2 · bash
5.2.21(1)-release (verified this session) · `/bin/sh -> /usr/bin/dash`
0.5.12-6ubuntu5 · shellcheck 0.9.0 (verified this session) · shfmt 3.8.0 · GNU
coreutils 9.4 · GNU grep 3.11. Every expected output and every shellcheck finding
in §4 was executed and captured on this baseline at plan time unless tagged
`[VERIFY-AT-BUILD]`.

Precondition (verified at plan time): Phase 0+1 is complete — git tags `bash-p0`
and `bash-p1` exist; planned_execution.md marks both `[x]`; all 11 P0/P1 labs are
on disk. L2.1's recall.json below is inherited from the p01 plan's L1.8 entry
("FOR THE PHASE 2 BUILDER" block) and was re-verified question-by-question against
the built recap.md files on disk — every tested fact appears verbatim in shipped
P0/P1 content.

## 1. Lab list (from the map, exactly)

| id | title (meta.json `title`, backticks stripped) | type | gate | est_minutes | dir slug |
|---|---|---|---|---|---|
| L2.1 | if and test — [ ] vs [[ ]] vs (( )), and which to trust | DECODE | false | 15 | `L2.1-if-and-test` |
| L2.2 | The strict-mode preamble — set -euo pipefail and what each flag stops | DECODE | false | 20 | `L2.2-strict-mode-preamble` |
| L2.3 | Loops — for, while, and the correct way to read a file line by line | PREDICT | false | 15 | `L2.3-loops` |
| L2.4 | && and \|\| — short-circuit logic and the cmd \|\| exit idiom | PREDICT | false | 10 | `L2.4-short-circuit` |
| L2.5 | case statements | DECODE | false | 10 | `L2.5-case-statements` |
| L2.6 | Functions — local, and return (a code) vs echo (a value) | DECODE | false | 15 | `L2.6-functions` |
| L2.7 | trap — cleanup on exit, and why installers use it | DECODE | false | 15 | `L2.7-trap-cleanup` |
| L2.8 | Phase gate: a script that fails silently — trace it, find where it lied | FIX | **true** | 20 | `L2.8-phase-gate-silent-failure` |

Gate placement: the map marks L2.8 explicitly; no ambiguity. recall.json:
**L2.1 only** (phase opener; 5 questions inherited from the p01 plan's draft).
L2.8's entry drafts L3.1's recall.json so the Phase-3 build session inherits it.
est_minutes total: 120 across 8 labs, all inside the ADHD contract's 10–20 band,
the two heavyweight labs (L2.2, the map's "most important lab in the phase", and
the L2.8 gate) at the top of it.

## 2. Binding harness constraints — inherited, plus Phase-2 deltas

Everything in bash-p01-plan.md §2 applies unchanged (the fence, artifact-based
grading, lint-labs.sh bans, file contracts, quiz I/O, bash-track quality gates).
Verified again at plan time: `tools/lint-labs.sh` scans **check.sh only** (banned
tokens: `eval sudo curl wget nc ssh`, `sh -c`, `bash -c`, `pushd`, `bin/lab`,
`cd ..`/`cd ~`, absolute-path literals; mode 0644; collect-all; `ck_summary`
last). `files/` payloads are never scanned by lint or by tools/shellcheck-all.sh
— the `# TEACHING SAMPLE — intentionally flawed` header (line 2) plus meta.json
`teaching_samples` are what declare a flawed sample.

Phase-2 deltas (new conventions, decided here — see §6 for rationale):

1. **Run-capture convention.** Behavior evidence is captured as
   `bash <script> [args] > <name>.txt 2>&1; echo "exit=$?" >> <name>.txt` — one
   file per run, stderr folded in, exit code appended as a greppable
   `exit=N` line. check.sh asserts message substrings plus anchored `^exit=N$`.
2. **Flag isolation via the command line.** L2.2 demonstrates each strict-mode
   flag as a before/after pair on ONE script per flag: the "before" run is plain
   `bash <demo>.sh`, the "after" run is `bash -e <demo>.sh` / `bash -u <demo>.sh`
   / `bash -o pipefail <demo>.sh`. The only difference between the two runs is
   the flag itself. The in-script form (`set -euo pipefail` line 2) is shown by
   `hardened.sh`, which is byte-identical to e-demo.sh plus the preamble.
3. **Countable loops.** L2.3 grades loop behavior as line COUNTS (plus two exact
   single lines) — every loop body is a one-line `printf '[%s]\n'`-style wrapper
   so iterations are visible and countable. This keeps the one-key-one-line
   predictions.txt convention while making the 7-vs-2-vs-3 story the graded
   signal. argv.sh is NOT shipped in Phase 2 (no lab needs an argv oscilloscope).
4. **Behavioral FIX grading.** L2.8 (type FIX) grades the learner's edited
   workspace script by RUNNING it (happy path must succeed and produce the
   artifact; a sabotage input must fail honestly) — never by grepping the script
   text for a particular fix. Both the strict-mode preamble and explicit
   `|| exit` guards pass, as they should.
5. **Empty teaching_samples lists are meaningful.** Two flawed samples in this
   phase (e-demo.sh, archive-errors.sh) produce ZERO shellcheck findings —
   verified — because missing strict mode is invisible to static analysis. Their
   meta.json entries carry `[]`, and lab content teaches exactly that fact.
6. **Message text referenced by stable suffix.** Error prefixes vary by
   invocation context (`bash: line 1:` vs `<script>: line N:`); lab.md and hints
   quote only the stable suffixes (`[: too many arguments`,
   `unbound variable`, `No such file or directory`).
7. **Hint strings containing `$`** use double quotes with escaped `\$` (built
   P0/P1 precedent: single-quoted `$...` hints trip SC2016 under this shellcheck
   build, and `# shellcheck disable=` is banned repo-wide).
8. **Multi-line constructs typed at the prompt** are printed in lab.md as
   one-liners with `;` separators (e.g. `for h in a b; do printf '%s\n' "$h"; done`).

## 3. Track-wide conventions (inherited from p01 §3, applied to all 8 labs)

- DECODE labs grade `answers.txt`; PREDICT labs grade `predictions.txt`; the FIX
  gate grades `answers.txt` + behavioral asserts on the edited script. Same
  `key=value` grammar: exact lowercase keys, no spaces around `=`, anchored-ERE
  grep except values containing ERE metacharacters (`< > | [ ] * ? ( )`), which
  use `assert_file_contains_fixed` on the full line.
- Scripts run as `bash <name>` (plus the §2.2 flag forms), never `./<name>`.
- PREDICT protocol: predictions written BEFORE running; honor line verbatim in
  BRIEF: "the check can't tell whether you predicted first — you're only cheating
  your own reps." lab.md never reveals expected values; hint L3 says run-and-
  transcribe.
- Quiz ≠ graded answers (same concept, different angle). quiz.json exactly 3
  questions; hints.json exactly 3 escalating levels; recap.md exactly 3 lines.
- Determinism: no graded value depends on date/time/hostname/locale; the only
  $(pwd)-derived value would be the workspace basename (unused this phase). All
  shipped filenames lowercase ASCII.
- meta.json `objective` given per lab in §4; titles exactly as §1; quiz/recall
  answers base64-encoded by the builder (`printf '%s' 'answer' | base64 -w0`).

## 4. Lab entries

---

### L2.1 — if and test — [ ] vs [[ ]] vs (( )), and which to trust
**DECODE · gate:false · est 15 · files/: gatekeeper.sh · recall.json: YES (phase opener)**
**objective:** "Read any if line by naming which test construct it uses, what exit code it branches on, and which of [ ], [[ ]], and (( )) to trust for strings, numbers, and POSIX portability."

**recall.json — 5 questions, inherited verbatim from bash-p01-plan.md's L1.8 draft;
every fact re-verified against built P0/P1 recaps on disk at plan time:**
1. choice (source: "bash L0.1") — "On Debian/Ubuntu, /bin/sh is a symlink to which
   shell?" a) bash b) dash c) busybox sh → **b** (L0.1 recap line 2)
2. choice (source: "bash L1.3") — "An unquoted $var whose value contains spaces…"
   a) stays one word — the quotes are only style b) splits into multiple words on
   IFS whitespace — the #1 bash bug c) raises a syntax error → **b** (L1.3 recap line 1)
3. choice (source: "bash L1.5") — "A glob like *.conf that matches no file…"
   a) expands to an empty string b) stays the literal text *.conf c) aborts the
   command with an error → **b** (L1.5 recap line 2)
4. text (source: "bash L1.4") — "Which quoting style lets $var expand but stops the
   result from word-splitting?" → **double** (accept: `double quotes`,
   `double-quotes`) (L1.4 recap line 2)
5. choice (source: "bash L1.6") — "Right after a command, $? prints 0. That means…"
   a) it failed b) it succeeded — 0 is success, backwards from most languages
   c) it produced no output → **b** (L1.6 recap line 1)

**BRIEF gist (builder expands to ≤10 lines):** Phase 1's punchline becomes Phase 2's
engine: `if` runs a COMMAND and branches on its exit code (L1.6) — nothing else.
`[` is literally a command with an exit code; `[[` is bash syntax with parsing
superpowers (no word splitting inside); `(( ))` is arithmetic, where nonzero means
true — and that truth gets FLIPPED into exit-code convention (true → 0). The lab's
deliverable is a trust table: `[[ ]]` for strings/files, `(( ))` for numbers,
`[ ]` only when the script must run under POSIX sh (the L0.3 dash lesson). The
experiments show why: `[ ]` inherits every Phase-1 expansion bug; `[[ ]]` is immune
to the worst of them.

**files/gatekeeper.sh** (working sample, intent=clean, byte-exact — verified):
```bash
#!/usr/bin/env bash
# gatekeeper.sh — admit or deny a request: strings via [[ ]], numbers via (( )).
user="${1:-}"
load="${2:-0}"
if [[ -z "$user" ]]; then
  echo "usage: bash gatekeeper.sh <user> <load>" >&2
  exit 2
fi
if [[ "$user" != "admin" ]]; then
  echo "deny: $user is not admin"
  exit 1
fi
if (( load >= 8 )); then
  echo "deny: load $load too high"
  exit 1
fi
echo "admit: $user (load $load)"
```

**TEACHING ARTIFACT** — all outputs/exit codes verified at plan time.

*Part A — decode gatekeeper.sh (lab.md prose before the runs):* three ifs, three
constructs on display: `[[ -z "$user" ]]` string emptiness, `[[ "$user" != "admin" ]]`
string comparison, `(( load >= 8 ))` arithmetic comparison. Each if consumes only an
exit code. Exit codes are the script's API: 0 admit, 1 deny, 2 usage.

Run matrix (verified byte-exact):
| command | stdout | exit |
|---|---|---|
| `bash gatekeeper.sh admin 3` | `admit: admin (load 3)` | 0 |
| `bash gatekeeper.sh admin 12` | `deny: load 12 too high` | 1 |
| `bash gatekeeper.sh guest 3` | `deny: guest is not admin` | 1 |
| `bash gatekeeper.sh` | (stderr) `usage: bash gatekeeper.sh <user> <load>` | 2 |

*Part B — the prompt experiments (each typed as one line; answers.txt records the
observed values). All verified:*
1. `x=""; [ -n $x ]; echo $?` → **0** — the trap. `$x` expanded to nothing and
   vanished (L1.2's "silently became nothing"); `[` received ONE argument, `-n`,
   and a one-argument test asks "is that string non-empty?" — the string `-n` is
   non-empty, so TRUE. An empty variable just passed a non-empty check.
   Auth-bypass shaped.
2. `x=""; [[ -n $x ]]; echo $?` → **1** — `[[` is parsed before expansion; the
   operand position holds even when the expansion is empty. Correct answer, no
   quotes needed (quote anyway — the reflex stays).
3. `name="admin user"; [ $name = admin ]; echo $?` → **2**, stderr ends
   `[: too many arguments` — the unquoted split handed `[` three-plus operands
   (message prefix varies with invocation context; lab.md quotes the suffix only).
4. `[[ $name = admin ]]; echo $?` → **1** — same operands, no splitting inside
   `[[`: clean false instead of a broken test.
5. `[[ 10 > 9 ]]; echo $?` → **1** — inside `[[ ]]`, `>` is STRING comparison:
   "10" sorts before "9" lexically. The classic silent wrong-answer.
6. `(( 10 > 9 )); echo $?` → **0** — arithmetic comparison; and the flip:
   `(( 0 )); echo $?` → **1** (arithmetic 0 = false = exit 1). Also verified:
   `[ 10 -gt 9 ]` → 0 (`-gt` is the POSIX numeric operator).

*answers.txt (keys/answers for the builder; questions + q3 options printed in lab.md):*
- q1 (value) — exit code of experiment 1 → **q1=0**
- q2 (value) — exit code of experiment 2 → **q2=1**
- q3 (choice) — why did q1 say 0? a) `[ ]` treats empty strings as non-empty
  b) `$x` vanished before `[` ran — `[ -n ]` became a one-argument test, "is the
  literal string -n non-empty?", which is always true c) `-n` only works on quoted
  variables → **q3=b**
- q4 (value) — exit code of experiment 3 → **q4=2**
- q5 (value) — exit code of `[[ 10 > 9 ]]` → **q5=1**
- q6 (value) — exit code of `(( 10 > 9 ))` → **q6=0**

**SHELLCHECK STATUS:** files/gatekeeper.sh — clean: zero output from
`shellcheck -x -S style` (0.9.0), verified at plan time. No flawed files ship;
meta.json carries no `teaching_samples`. The prompt experiments deliberately type
unquoted `$x`/`$name` — typed at the prompt, never committed to a file, so not
shellcheck targets (in a file, SC2086 would flag them — that echo of L1.3 is
stated in lab.md in one clause).

**SANDBOX NOTE:** the only write in this lab is the learner's `answers.txt` inside
`workspace/bash/L2.1/`. gatekeeper.sh reads no files (arguments only); the
experiments touch no files at all. No system reads, no installs, no network,
nothing destructive. Decoy-tree helpers unused ([FUTURE-PHASE-ONLY], Phase 3+).

**GUIDED STEPS outline (13 commands):**
1. `cat gatekeeper.sh` — decode: find the three constructs, one per if. (1 cmd)
2. Run the four-row matrix; after each run `echo $?` is folded into the same line
   (`bash gatekeeper.sh admin 3; echo $?` etc.). (4 cmds)
3. Experiments 1–6, one line each, transcribing each exit code as you go. lab.md
   labels experiment 1 "the trap" and walks the mechanism AFTER the learner has
   seen the 0. (6 cmds)
4. Write `answers.txt` (six keys, q3 options printed in lab.md). (1 cmd/editor)
5. `lab check bash L2.1`. (1 cmd)

**CHECK LOGIC (check.sh):** standard preamble (shebang, `set -euo pipefail`, both
`: "${…:?}"` guards, `# shellcheck source=/dev/null` + `source "$LAB_CHECKLIB"`,
mode 0644), then:
```bash
assert_file_exists "answers.txt" \
  "step 4 — write keys q1..q6 into answers.txt, one key=value per line"
assert_file_contains "answers.txt" '^q1=0$' \
  "q1 — rerun experiment 1 and transcribe the digit; the empty expansion vanished before [ ran"
assert_file_contains "answers.txt" '^q2=1$' \
  "q2 — rerun experiment 2: [[ keeps its operand slot even when the expansion is empty"
assert_file_contains "answers.txt" '^q3=b$' \
  "q3 — one letter: how many arguments did [ actually receive in experiment 1?"
assert_file_contains "answers.txt" '^q4=2$' \
  "q4 — rerun experiment 3: the split hands [ too many operands; transcribe the exit code"
assert_file_contains "answers.txt" '^q5=1$' \
  "q5 — inside [[ ]], > compares STRINGS; which sorts first, 10 or 9?"
assert_file_contains "answers.txt" '^q6=0$' \
  "q6 — (( )) is arithmetic: the comparison is true, and true flips to exit 0"
assert_output_contains "gatekeeper admits admin at low load" 'admit: admin' \
  "run: bash gatekeeper.sh admin 3" -- bash -- gatekeeper.sh admin 3
assert_cmd_fails "gatekeeper denies non-admin" \
  "run: bash gatekeeper.sh guest 3 — read the deny branch" -- bash -- gatekeeper.sh guest 3
ck_summary
```
All patterns metacharacter-free anchored ERE. Hints avoid `$` where possible; the
q1/q2 hints as written carry no `$`. No absolute paths, no banned tokens.
CI fabrication: `printf 'q1=0\nq2=1\nq3=b\nq4=2\nq5=1\nq6=0\n' > answers.txt` —
gatekeeper.sh arrives via `lab start`'s files/ copy; both live proofs run it with
bash only.

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "`[ $name = admin ]` errors when name holds `admin user`, but
   `[[ $name = admin ]]` works. Why?" a) [[ auto-quotes everything b) [[ is parsed
   as syntax BEFORE expansion — its operand positions are fixed, so the result
   never word-splits; [ is just a command receiving whatever words survive
   expansion c) [ requires -s for strings → **b**
2. choice — "`(( 5 ))` exits 0 and `(( 0 ))` exits 1. What's going on?"
   a) a bash bug b) two opposite conventions meeting: in arithmetic nonzero is
   TRUE, and true is then reported as exit code 0 c) (( )) inverts every value →
   **b**
3. choice — "A script's shebang is #!/bin/sh and it must stay dash-safe (L0.3).
   Which test tool is available?" a) [[ ]] b) (( )) c) [ ] — the POSIX test
   command; [[ and (( are bashisms (shellcheck would say SC3010) → **c**
(Angles differ from graded keys: q3 graded the one-argument mechanism, quiz Q1
asks the parse-order reason; quiz Q2 generalizes q6; quiz Q3 is the portability
column of the trust table, graded nowhere.)

**RECAP:**
```
if branches on an exit code, nothing else — [ is a command, [[ is bash syntax, (( )) is arithmetic
[ ] inherits every expansion bug: empties vanish ([ -n ] passes!), spaces split; [[ ]] never splits its operands
trust [[ ]] for strings/files and (( )) for numbers — where nonzero is TRUE and flips to exit 0
```

**HINTS:** L1: "The grader reads answers.txt — six keys q1..q6, no spaces around =,
plus it runs gatekeeper.sh itself. Four keys are single digits you transcribe from
echo $? after the numbered experiments; q3 is a letter." L2: "q1/q2: what does an
EMPTY unquoted expansion leave behind for [ vs [[? q4: count the words [ receives
once the space-bearing value splits. q5: > inside [[ compares strings — '10' vs
'9' character by character. q6: (( )) reports arithmetic truth as exit 0." L3:
"Rerun each experiment exactly as printed and transcribe the digit after echo $?.
For q3, experiment 1 handed [ exactly one argument (-n itself) — pick the option
that says a one-argument test checks that string for non-emptiness."

---

### L2.2 — The strict-mode preamble — set -euo pipefail and what each flag stops
**DECODE · gate:false · est 20 · files/: e-demo.sh, u-demo.sh, p-demo.sh, hardened.sh · recall.json: no**
**objective:** "Explain what each of -e, -u, and pipefail individually stops, by watching the same three failures run silent without the flag and fatal with it."

The map calls this the most important lab in the phase; its security hook is quoted
in the BRIEF: understanding the preamble "is the difference between 'the script
ran' and 'the script did what it claimed'."

**Demonstration design (per-flag isolation):** one small flawed script per flag.
The "before" run is plain `bash <demo>.sh`; the "after" run re-runs the SAME file
with the one flag under study supplied on the command line (`bash -e`, `bash -u`,
`bash -o pipefail`) — so the only difference between the two runs is the flag
itself, and each flag is proven individually, never as a bundled preamble.
`hardened.sh` (e-demo.sh + the in-script preamble line) then proves
`set -euo pipefail` inside the file behaves identically to the command-line form.

**files/e-demo.sh** (TEACHING SAMPLE header line 2; expected SC codes: **none** —
see SHELLCHECK STATUS, the empty list is itself a teaching point):
```bash
#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# e-demo.sh — back up the report, then declare victory.
cp report.txt backup.txt
echo "backup complete"
```

**files/u-demo.sh** (TEACHING SAMPLE header line 2; expected SC codes: **SC2034,
SC2154** — verified):
```bash
#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# u-demo.sh — clean the release staging path.
release_dir="v2"
echo "cleaning staging/$relaese_dir"
```

**files/p-demo.sh** (TEACHING SAMPLE header line 2; expected SC codes: **SC2126** —
verified):
```bash
#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# p-demo.sh — count GET requests in the web log.
grep GET requests.log | wc -l
```

**files/hardened.sh** (clean, shellcheck-zero — verified):
```bash
#!/usr/bin/env bash
set -euo pipefail
# hardened.sh — e-demo.sh with the preamble in place.
cp report.txt backup.txt
echo "backup complete"
```

Deliberately NOT shipped: `report.txt` and `requests.log` — their absence IS each
failure. The workspace at run time contains only the four scripts plus learner
artifacts.

**TEACHING ARTIFACT** — all six runs verified byte-exact at plan time:

*Pair 1 — `-e` (fail on error):*
- `bash e-demo.sh` → stderr `cp: cannot stat 'report.txt': No such file or
  directory`, then stdout `backup complete`, **exit 0**. The backup does not
  exist; the script said it did; the exit code agrees with the lie.
- `bash -e e-demo.sh` → the same cp error, NO "backup complete", **exit 1** —
  the script died at the first failing command, carrying cp's code.

*Pair 2 — `-u` (fail on unset):*
- `bash u-demo.sh` → `cleaning staging/`, **exit 0**. The typo'd `$relaese_dir`
  expanded to nothing (L1.2's "silently became nothing") and the script "cleaned"
  a different path than anyone intended — the exact mechanism that turns
  `rm -rf "$DIR/"` into a catastrophe (detonated properly in Phase 3, L3.2).
- `bash -u u-demo.sh` → stderr `u-demo.sh: line 5: relaese_dir: unbound
  variable`, no stdout, **exit 1**. The typo is now fatal, named, and
  line-numbered.

*Pair 3 — `pipefail` (a pipeline reports any death):*
- `bash p-demo.sh` → stderr `grep: requests.log: No such file or directory`,
  stdout `0`, **exit 0**. Read that as an answer: "zero GET requests today" —
  a plausible-looking number manufactured by a dead pipeline. wc never knew;
  the pipeline's exit code is the LAST command's (wc's 0), so grep's death
  vanished.
- `bash -o pipefail p-demo.sh` → identical output (`0` still prints — pipefail
  changes the verdict, not the data flow), **exit 2** (grep's code: the
  rightmost nonzero in the pipe).

*The in-script form:* `bash hardened.sh` → cp error, no "backup complete",
**exit 1** — identical to `bash -e e-demo.sh`. One sentence in lab.md: the
command-line flags and the `set` line are the same switches; scripts carry the
line so every caller gets the protection.

*Verified boundary fact (q4's subject):* under `set -e`, a command tested by
`if`/`while`/`&&`/`||` is EXEMPT — verified: a `set -euo pipefail` script running
`if grep -q ERROR nofile.txt; then …; fi` prints grep's stderr, continues, and
exits 0. -e guards statements, not conditions. (This is why L2.4's `|| true`
idiom exists, and it returns in the L2.8 gate.)

*Evidence files (run-capture convention, §2.1) — six captures:*
`bash e-demo.sh > e-off.txt 2>&1; echo "exit=$?" >> e-off.txt` ·
`bash -e e-demo.sh > e-on.txt 2>&1; echo "exit=$?" >> e-on.txt` ·
`bash u-demo.sh > u-off.txt 2>&1; echo "exit=$?" >> u-off.txt` ·
`bash -u u-demo.sh > u-on.txt 2>&1; echo "exit=$?" >> u-on.txt` ·
`bash p-demo.sh > p-off.txt 2>&1; echo "exit=$?" >> p-off.txt` ·
`bash -o pipefail p-demo.sh > p-on.txt 2>&1; echo "exit=$?" >> p-on.txt`

*answers.txt (questions + options printed in lab.md):*
- q1 (choice) — "In `set -euo pipefail`, what is the `o`?" a) a flag named o,
  enabling 'option mode' b) it makes set read the NEXT word as an option name —
  the line is set -e, set -u, set -o pipefail in one breath c) shorthand for
  output → **q1=b**
- q2 (choice) — "Which flag turns u-demo.sh's typo into a hard stop?" a) -e
  b) pipefail c) -u → **q2=c**
- q3 (choice) — "Without pipefail, `grep GET requests.log | wc -l` exits with…"
  a) the last command's code — wc's 0, so grep's death vanishes b) the leftmost
  failure's code c) 1 whenever anything in the pipe fails → **q3=a**
- q4 (choice) — "Under set -e, a command that fails inside `if <cmd>; then`…"
  a) kills the script anyway b) does NOT kill the script — commands tested by
  if/while/&&/|| are exempt from -e c) prints a warning and continues → **q4=b**

**SHELLCHECK STATUS:**
- files/e-demo.sh — TEACHING SAMPLE, expected SC codes: **NONE** (verified: zero
  output, exit 0 from `shellcheck -x -S style`). meta.json carries
  `"teaching_samples": {"files/e-demo.sh": []}` — the empty list is deliberate
  and load-bearing: no SC code exists for "you forgot set -e"; missing strict
  mode is a runtime-behavior gap, invisible to static analysis. Quiz Q1 grades
  this insight.
- files/u-demo.sh — TEACHING SAMPLE, expected codes **SC2034** (release_dir
  appears unused) + **SC2154** (relaese_dir is referenced but not assigned —
  shellcheck 0.9.0 even suggests "did you mean 'release_dir'?"), verified.
  lab.md points at that output in one sentence: your co-pilot catches the typo
  statically; -u catches it at run time; hardened scripts want both.
- files/p-demo.sh — TEACHING SAMPLE, expected code **SC2126** (style: consider
  grep -c), verified. One clause in lab.md: SC2126 is about efficiency, not the
  bug — shellcheck does NOT flag the missing pipefail.
- files/hardened.sh — clean: zero output (verified).
- check.sh — must be clean; its hints below avoid `$` entirely.
meta.json: `"teaching_samples": {"files/e-demo.sh": [], "files/u-demo.sh":
["SC2034", "SC2154"], "files/p-demo.sh": ["SC2126"]}`.

**SANDBOX NOTE:** writes are the six capture files, backup.txt is never created
(cp always fails), and answers.txt — all inside `workspace/bash/L2.2/`. The
scripts read only workspace-relative names that don't exist (report.txt,
requests.log). u-demo.sh only echoes the staging path — nothing is deleted,
nothing outside the fence is touched. No installs, no network. Decoy-tree
helpers remain [FUTURE-PHASE-ONLY] (Phase 3+ — L3.2 is where the rm -rf version
of u-demo's bug detonates against a decoy).

**GUIDED STEPS outline (10 commands):**
1. `cat e-demo.sh` — read the lie-in-waiting; run the pair 1 captures (2 cmds +
   1 cat). After each capture, `cat` the evidence file and read it against the
   pair-1 narrative (folded into the same step).
2. Pair 2 captures for u-demo.sh (2 cmds) — lab.md walks the "silently wrong
   path" beat before revealing the -u run.
3. Pair 3 captures for p-demo.sh (2 cmds) — lab.md asks "what would you report
   if this landed in your triage queue?" before the pipefail rerun.
4. `bash hardened.sh` — the in-script form; compare against e-on.txt. (1 cmd)
5. `shellcheck e-demo.sh` — silence. The linter passes the liar; only strict
   mode catches it at run time. (1 cmd)
6. Write answers.txt (q1–q4), then `lab check bash L2.2`. (1 cmd + check)

**CHECK LOGIC (check.sh):** standard preamble, then:
```bash
assert_file_contains "e-off.txt" 'backup complete' \
  "pair 1 before-run: bash e-demo.sh > e-off.txt 2>&1 then append the exit= line (command printed in step 1)"
assert_file_contains "e-off.txt" '^exit=0$' \
  "e-off.txt needs the appended exit= line — rerun both step-1 commands"
assert_file_not_contains "e-on.txt" 'backup complete' \
  "pair 1 after-run must use the -e flag: with it, the script dies at cp and never echoes"
assert_file_contains "e-on.txt" '^exit=1$' \
  "e-on.txt — rerun: bash -e e-demo.sh, capture, append the exit= line"
assert_file_contains "u-off.txt" '^cleaning staging/$' \
  "pair 2 before-run: the typo'd variable expands to NOTHING — the captured line ends at the slash"
assert_file_contains "u-off.txt" '^exit=0$' \
  "u-off.txt needs the appended exit= line"
assert_file_contains "u-on.txt" 'unbound variable' \
  "pair 2 after-run must use the -u flag — the typo becomes a named, fatal error"
assert_file_contains "u-on.txt" '^exit=1$' \
  "u-on.txt — rerun: bash -u u-demo.sh, capture, append the exit= line"
assert_file_contains "p-off.txt" '^0$' \
  "pair 3 before-run: wc still prints its answer — capture stdout and stderr together (2>&1)"
assert_file_contains "p-off.txt" '^exit=0$' \
  "p-off.txt — without pipefail the pipeline exits with the LAST command's code"
assert_file_contains "p-on.txt" '^exit=2$' \
  "p-on.txt — rerun with -o pipefail: same output, different verdict (grep's own code)"
assert_file_contains "answers.txt" '^q1=b$' \
  "q1 — read the preamble as three set calls; what does -o consume?"
assert_file_contains "answers.txt" '^q2=c$' \
  "q2 — which flag is about UNSET variables?"
assert_file_contains "answers.txt" '^q3=a$' \
  "q3 — reread p-off.txt: whose exit code did the pipeline report?"
assert_file_contains "answers.txt" '^q4=b$' \
  "q4 — conditions are exempt: if/while/&&/|| test the command themselves"
ck_summary
```
16 numbered assertions → `checks 16/16`. All anchored ERE, metacharacter-free;
no `$` in any hint string (SC2016-safe); no absolute paths or banned tokens.
CI fabrication (bash+coreutils only, verified shapes): `printf 'cp: cannot stat
...\nbackup complete\nexit=0\n' > e-off.txt` etc. — concretely:
`printf '%s\n' 'x' 'backup complete' 'exit=0' > e-off.txt; printf '%s\n' 'x'
'exit=1' > e-on.txt; printf '%s\n' 'cleaning staging/' 'exit=0' > u-off.txt;
printf '%s\n' 'y: unbound variable' 'exit=1' > u-on.txt; printf '%s\n' 'z' '0'
'exit=0' > p-off.txt; printf '%s\n' 'z' '0' 'exit=2' > p-on.txt;
printf 'q1=b\nq2=c\nq3=a\nq4=b\n' > answers.txt`.

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "shellcheck gives e-demo.sh a completely clean pass, yet it lied
   about the backup. Why can't shellcheck catch this?" a) shellcheck only checks
   quoting b) missing strict mode is a runtime-behavior gap, not a syntax
   pattern — no SC code exists for 'you forgot set -e' c) it would, but only
   with -S error → **b**
2. choice — "Your script must also run under /bin/sh on Debian (dash — L0.3).
   Which part of the preamble breaks there?" a) -e b) -u c) -o pipefail — dash
   dies with 'Illegal option -o pipefail' (verified: exit 2) → **c**
3. text — "What single line does this track expect immediately after every
   shebang?" → **set -euo pipefail** (accept: `set -euo pipefail`; normalization
   handles case) 
(Angles differ from graded keys: q1 graded the -o mechanics, quiz Q3 asks for
the whole line; q3 graded pipeline exit-code sourcing, quiz Q2 is portability;
quiz Q1's linter-blindness is graded nowhere.)

**RECAP:**
```
set -e: a failing command STOPS the script instead of letting it keep narrating success
set -u: an unset or typo'd variable is fatal and named, instead of silently expanding to nothing
set -o pipefail: a pipeline reports the first death, not just the last command's verdict
```

**HINTS:** L1: "The grader reads six run captures (e-off, e-on, u-off, u-on,
p-off, p-on — all .txt) plus answers.txt with keys q1..q4. Each capture is one
command redirected with > name.txt 2>&1, then echo the exit= line onto it —
both commands are printed verbatim in the steps." L2: "Off-captures use plain
bash; on-captures add exactly one thing: -e, -u, or -o pipefail between bash
and the script name. The exit= lines must differ between each pair — if yours
match, the flag run didn't happen. Letters: q1 is about what -o consumes, q2
maps a flag to the typo, q3 names whose code a bare pipeline reports, q4 is
the if-condition exemption." L3: "Replay all six capture commands exactly as
printed in steps 1–3, cat each file to confirm the exit= line, then write
q1=b-shaped letter lines for the four questions — each one is answered by a
sentence printed beside its pair in lab.md."

---

### L2.3 — Loops — for, while, and the correct way to read a file line by line
**PREDICT · gate:false · est 15 · files/: tasks.txt, web01.conf, web02.conf, readlines.sh · recall.json: no**
**objective:** "Predict how many iterations each loop really runs — for iterates words, while read iterates lines, and a missing final newline silently eats the last one."

**BRIEF gist (builder expands to ≤10 lines):** `for` iterates over WORDS — however
they got there: a literal list, a glob, or (the trap) an unquoted `$(cat file)`,
which word-splits first (L1.7 + L1.3). `while read` iterates LINES — but plain
`read` drops a final line that lacks its newline, silently. The graded signal is
the iteration COUNT: the same 3-line file drives one loop 7 times, another 2,
and the correct one 3. readlines.sh ships the canonical pattern —
`while IFS= read -r line || [ -n "$line" ]` — keep it. Honor line verbatim: "the
check can't tell whether you predicted first — you're only cheating your own reps."

**files/tasks.txt** — exactly 42 bytes, three lines, NO trailing newline on the
last line (that absence IS the lab). Builder creates it with exactly:
`printf 'restart web01\ncheck disk space\nrotate keys' > files/tasks.txt`
```
restart web01
check disk space
rotate keys
```

**files/web01.conf** (one line + newline): `port=8081`
**files/web02.conf** (one line + newline): `port=8082`

**files/readlines.sh** (clean, shellcheck-zero — verified; usage guard verified:
no-arg run prints `…usage: bash readlines.sh <file>` on stderr, exit 1):
```bash
#!/usr/bin/env bash
set -euo pipefail
# readlines.sh — THE way to read a file line by line, byte-safe.
while IFS= read -r line || [ -n "$line" ]; do
  printf '[%s]\n' "$line"
done < "${1:?usage: bash readlines.sh <file>}"
```

**TEACHING ARTIFACT** — state pin: all samples run from `workspace/bash/L2.3/`;
inventory at run time is exactly readlines.sh, tasks.txt, web01.conf, web02.conf,
and the learner's predictions.txt (written first; no sample glob matches it).
All outputs verified at plan time. Prediction values are line counts unless
stated; lab.md defines "count = the number of lines the loop prints".

| # | sample line | exact behavior | key/value | mechanism |
|---|---|---|---|---|
| p1 | `for h in web01 web02 db01; do printf 'ping %s\n' "$h"; done` | 3 lines: `ping web01` / `ping web02` / `ping db01` | `p1=3` | for walks a word list; the loop variable is just each word in turn |
| p2 | `for f in *.conf; do printf 'loading %s\n' "$f"; done` | 2 lines; FIRST is `loading web01.conf` | `p2=loading web01.conf` (exact first line) | the glob expands to existing names (L1.5) and for walks the result |
| p3 | `for w in $(cat tasks.txt); do printf '[%s]\n' "$w"; done` | 7 lines: `[restart]` `[web01]` `[check]` `[disk]` `[space]` `[rotate]` `[keys]` | `p3=7` | unquoted `$(cat …)` word-splits (L1.7): for sees 7 WORDS, not 3 lines — the classic "process a file with for" bug |
| p4 | `while read -r line; do printf '[%s]\n' "$line"; done < tasks.txt` | 2 lines: `[restart web01]` `[check disk space]` — `rotate keys` NEVER prints | `p4=2` | read returns nonzero at EOF even though it filled $line — the unterminated last line is silently dropped. Phase theme in one loop |
| p5 | `bash readlines.sh tasks.txt` | 3 lines, ending `[rotate keys]` | `p5=3` | the `|| [ -n "$line" ]` guard runs the body one last time when read failed but delivered bytes; IFS= keeps leading/trailing whitespace intact (one clause in lab.md) |
| p6 | `for f in *.missing; do printf 'got %s\n' "$f"; done` | 1 line: `got *.missing` | `p6=got *.missing` (exact line) | no-match globs stay literal (L1.5) — the loop still runs ONCE, on the pattern itself; a loop "over files" can iterate over a filename that doesn't exist |

**SHELLCHECK STATUS:** files/readlines.sh — clean: zero output from
`shellcheck -x -S style` (0.9.0), verified at plan time. tasks.txt and the two
.conf files are data, not shellcheck targets. Typed sample lines are not
shellcheck targets (p3's unquoted `$(cat …)` would draw SC2046 in a file — that
bug being the lesson). No flawed files ship; meta.json carries no
`teaching_samples`.

**SANDBOX NOTE:** the only write is the learner's `predictions.txt` inside
`workspace/bash/L2.3/`. Every loop reads only workspace files; nothing is
deleted or modified. No system reads, no installs, no network, nothing
destructive. Decoy-tree helpers remain [FUTURE-PHASE-ONLY].

**GUIDED STEPS outline (10 commands):**
1. `ls` — inventory first (p2 and p6 are decided by what exists), then
   `cat tasks.txt` — note the prompt lands IMMEDIATELY after `rotate keys`: no
   final newline. lab.md shows this with the next prompt visibly glued on. (2 cmds)
2. `cat readlines.sh` — read the canonical pattern; the BRIEF explains IFS= and
   -r in one line each, the guard in two. (1 cmd)
3. Write ALL six predictions into predictions.txt before running anything —
   `p1`/`p3`/`p4`/`p5` are counts, `p2`/`p6` are exact output lines. (editor)
4. Run p1–p6 one at a time, comparing each against your prediction. (6 cmds)
5. Correct any missed key to observed truth; `lab check bash L2.3`. (1 cmd)

**CHECK LOGIC (check.sh):** standard preamble, then:
```bash
assert_file_exists "predictions.txt" \
  "step 3 — write keys p1..p6 into predictions.txt before running anything"
assert_file_contains "predictions.txt" '^p1=3$' \
  "p1 — count the lines the word-list loop prints; rerun sample p1"
assert_file_contains "predictions.txt" '^p2=loading web01.conf$' \
  "p2 — the FIRST line the glob loop prints; sorted glob order decides which .conf comes first"
assert_file_contains "predictions.txt" '^p3=7$' \
  "p3 — unquoted command substitution word-splits before for ever runs; count the WORDS in tasks.txt"
assert_file_contains "predictions.txt" '^p4=2$' \
  "p4 — plain read drops a final line that has no newline; rerun sample p4 and count"
assert_file_contains "predictions.txt" '^p5=3$' \
  "p5 — readlines.sh carries the guard that rescues the last line; rerun sample p5"
assert_file_contains_fixed "predictions.txt" 'p6=got *.missing' \
  "p6 — a glob that matches nothing stays literal, and the loop still runs once on it"
assert_output_contains "the guard rescues the unterminated last line" 'rotate keys' \
  "run: bash readlines.sh tasks.txt" -- bash -- readlines.sh tasks.txt
ck_summary
```
p6 is fixed-literal (`*` is an ERE metacharacter); the rest are anchored ERE
(dots in p2 stay ERE per p01 precedent). The live proof's pattern avoids the
`[ ]` bracket metacharacters by matching the payload text only. No `$` in
hints. CI fabrication: `printf '%s\n' 'p1=3' 'p2=loading web01.conf' 'p3=7'
'p4=2' 'p5=3' 'p6=got *.missing' > predictions.txt` — readlines.sh and
tasks.txt arrive via `lab start`'s files/ copy, so the live proof needs no
fabrication.

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "`for x in $(cat hosts.txt)` iterates over…" a) the lines of
   hosts.txt b) the whitespace-split (and glob-expanded) WORDS of hosts.txt —
   for never sees lines c) the bytes of hosts.txt → **b**
2. choice — "Plain `while read -r line` dropped 'rotate keys'. Why?" a) read
   can't handle spaces b) the last line has no trailing newline: read fills
   $line but returns nonzero at EOF, so the loop body never runs for it — the
   `|| [ -n "$line" ]` guard is the fix c) while loops cap at the file's line
   count minus one → **b**
3. choice — "What does the IFS= in `while IFS= read -r line` buy you?" a) it
   speeds up the read b) it stops read from stripping leading/trailing
   whitespace, so the line arrives byte-exact c) it disables globbing → **b**
(Quiz Q2 re-asks p4's WHY where the graded key only demanded the count; Q1
generalizes p3; Q3's IFS= detail is graded nowhere.)

**RECAP:**
```
for iterates WORDS, wherever they came from — an unquoted $(cat f) hands it 7 split words, not 3 lines
plain read silently drops a last line that's missing its newline; the || [ -n "$line" ] guard rescues it
while IFS= read -r line is THE file-reading pattern — keep readlines.sh; you'll paste it for years
```

**HINTS:** L1: "The grader reads predictions.txt — six keys p1..p6, no spaces
around =. Four values are bare counts (how many lines the loop printed), two
are exact output lines (p2 the first glob-loop line, p6 the no-match loop's
only line)." L2: "Decide each count by what the loop iterates OVER: p1 a
3-word list; p3 the WORDS of tasks.txt after splitting (count them on paper);
p4 lines that end with a newline — check tasks.txt's last byte; p5 adds the
guard that rescues one more. p2/p6: replay L1.5's glob rules against ls." L3:
"Run each sample line exactly as printed and count the bracketed/prefixed
lines it prints; transcribe counts and the two exact lines into their keys.
The run is the legitimate answer sheet — then lab check bash L2.3."

---

### L2.4 — && and || — short-circuit logic and the cmd || exit idiom
**PREDICT · gate:false · est 10 · files/: guard.sh · recall.json: no**
**objective:** "Predict which side of && and || runs — including the a && b || c trap — and read the cmd || exit guard idiom that hardened scripts are built from."

**BRIEF gist (builder expands to ≤10 lines):** `&&` runs its right side only after
success; `||` only after failure — both read `$?` (L1.6's verdict, wired directly
into flow). They are equal-precedence and left-associative, so `a && b || c` is
NOT if/else: `c` also fires when `a` succeeded but `b` failed. The guard idiom
`cmd || exit 1` is how scripts refuse to continue past a failure — and it's one
of the two exemption-safe ways to handle errors under `set -e` (L2.2's q4). Safety
line, verbatim in lab.md: never type `… || exit` at your interactive prompt — if
the left side fails, it exits YOUR SHELL; that's why the exit samples live in
guard.sh. Honor line verbatim (PREDICT convention).

**files/guard.sh** (clean, shellcheck-zero — verified):
```bash
#!/usr/bin/env bash
# guard.sh — refuse to continue if the deploy dir is missing.
cd deploy_dir || exit 1
echo "deploying from $(basename "$(pwd)")"
```

**TEACHING ARTIFACT** — state pin: samples run from `workspace/bash/L2.4/`;
`deploy_dir` does not exist until step p6's mkdir. All outputs verified.

| # | sample line | exact output | key/value | mechanism |
|---|---|---|---|---|
| p1 | `false && echo up; echo "rc=$?"` | `rc=1` (only) | `p1=rc=1` | && short-circuits on failure; the compound's $? is false's 1 |
| p2 | `false || echo fallback` | `fallback` | `p2=fallback` | \|\| is the failure branch |
| p3 | `true && false || echo recovered` | `recovered` | `p3=recovered` | THE trap: a succeeded, b failed, \|\| pairs with the most recent verdict — c runs anyway. Not an if/else |
| p4 | `echo one && false && echo two || echo three` | `one` then `three` | choice → `p4=b` | left to right: echo one (0) → false (1) → && skips two → \|\| fires three |
| p5 | `bash guard.sh; echo $?` | stderr ending `cd: deploy_dir: No such file or directory`, then `1` | `p5=1` | cd failed → \|\| exit 1 → the echo line never ran; the script reported the failure upward (verified message: `guard.sh: line 3: cd: deploy_dir: No such file or directory`) |
| p6 | `mkdir deploy_dir` then `bash guard.sh` | `deploying from deploy_dir`, exit 0 | `p6=deploying from deploy_dir` | the guard passes and the deploy line runs — from the RIGHT directory, which is the whole point (basename keeps the value machine-independent) |

p4 options printed in lab.md: which lines print? a) `one` `two` `three` b) `one`
then `three` c) only `three` → **b**.

**SHELLCHECK STATUS:** files/guard.sh — clean: zero output from
`shellcheck -x -S style` (0.9.0), verified (the `cd … || exit` form is exactly
what SC2164 wants — worth one clause in lab.md: a bare `cd deploy_dir` would
draw SC2164 "use cd ... || exit in case cd fails"; guard.sh is the fix
shellcheck asks for). Typed sample lines are not shellcheck targets. No flawed
files; no `teaching_samples` key.

**SANDBOX NOTE:** writes: the learner's `predictions.txt` and the learner-made
`deploy_dir/` (empty), both inside `workspace/bash/L2.4/`. guard.sh's `cd` moves
into a workspace subdirectory only. Quiz Q2 DISCUSSES `cd staging && rm -f
*.tmp` — never executed, stated in prose only. No installs, no network, nothing
destructive; decoy-tree helpers remain [FUTURE-PHASE-ONLY].

**GUIDED STEPS outline (9 commands):**
1. Read the six samples printed in lab.md (with the p4 options); write ALL
   predictions into predictions.txt first. (editor)
2. Run p1–p4 at the prompt, comparing each. (4 cmds)
3. `cat guard.sh` — read the idiom; the safety line about `|| exit` at a prompt
   sits here. (1 cmd)
4. Run p5 (`bash guard.sh; echo $?`), then `mkdir deploy_dir`, then p6. (3 cmds)
5. Correct misses; `lab check bash L2.4`. (1 cmd)

**CHECK LOGIC (check.sh):** standard preamble, then:
```bash
assert_file_exists "predictions.txt" \
  "step 1 — write keys p1..p6 into predictions.txt before running anything"
assert_file_contains "predictions.txt" '^p1=rc=1$' \
  "p1 — the compound's verdict is false's own code; rerun sample p1"
assert_file_contains "predictions.txt" '^p2=fallback$' \
  "p2 — which side of || runs after a failure? rerun sample p2"
assert_file_contains "predictions.txt" '^p3=recovered$' \
  "p3 — || pairs with the most recent verdict, not with the first command; rerun sample p3"
assert_file_contains "predictions.txt" '^p4=b$' \
  "p4 — one letter: walk the line left to right, one verdict at a time"
assert_file_contains "predictions.txt" '^p5=1$' \
  "p5 — the guard fired: cd failed, exit 1 carried the failure upward; rerun sample p5"
assert_file_contains "predictions.txt" '^p6=deploying from deploy_dir$' \
  "p6 — after mkdir deploy_dir the guard passes; rerun sample p6 and transcribe"
assert_dir_exists "deploy_dir" \
  "step 4 — mkdir deploy_dir (p6 needs it to exist)"
assert_output_contains "the guard passes once the dir exists" 'deploying from deploy_dir' \
  "run: bash guard.sh" -- bash -- guard.sh
ck_summary
```
All anchored ERE, metacharacter-free; no `$` in hints. CI fabrication:
`mkdir -p deploy_dir; printf '%s\n' 'p1=rc=1' 'p2=fallback' 'p3=recovered'
'p4=b' 'p5=1' 'p6=deploying from deploy_dir' > predictions.txt` — guard.sh
arrives via lab start; the live proof runs it with the fabricated deploy_dir
present.

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "Why is `a && b || c` NOT the same as if a; then b; else c; fi?"
   a) it is the same b) c also runs when a succeeded but b FAILED — || reacts
   to the most recent verdict c) && binds tighter than || → **b**
2. choice — "A cleanup script runs `cd staging && rm -f *.tmp` (discussed, not
   run). What is the && buying?" a) speed — both run in parallel b) if cd fails,
   rm never runs — without &&, rm would happily delete *.tmp in whatever
   directory you were actually in c) nothing; ; would be identical → **b**
3. choice — "Under set -e (L2.2), what does `grep -q ERROR log || true` say?"
   a) nothing — it's dead code b) 'a no-match here is fine, don't die': the ||
   makes the failure handled, so -e lets the script continue c) it inverts
   grep's answer → **b**
(Quiz Q1 re-asks p3's mechanism; Q2 is the safety framing of the idiom; Q3
bridges back to L2.2's exemption rule and forward to the L2.8 gate.)

**RECAP:**
```
&& runs the right side only after success, || only after failure — both are $? wired into flow
a && b || c is NOT if/else: c fires on b's failure too — || pairs with the most recent verdict
cmd || exit 1 is the guard idiom (in scripts! at a prompt it closes your shell) — cd almost always wants it
```

**HINTS:** L1: "The grader reads predictions.txt — six keys p1..p6 — and checks
that deploy_dir exists (step 4's mkdir). p1/p2/p3/p6 are exact output lines,
p4 a letter, p5 a digit." L2: "Walk every line left to right keeping one
running verdict: && skips its right side after a failure, || skips after a
success, and each command replaces the verdict. For p5: the left side of ||
failed, so what does exit 1 make the SCRIPT report? For p6, basename trims the
path to just the directory name." L3: "Run every sample exactly as printed
(p5 and p6 use guard.sh — never type the exit sample at your bare prompt) and
transcribe each result into its key; the run is the answer sheet."

---

### L2.5 — case statements
**DECODE · gate:false · est 10 · files/: triage.sh · recall.json: no**
**objective:** "Read a case statement as glob patterns racing top-to-bottom for one word — first match wins, ;; stops, *) is the default, and no match at all is a silent success."

**BRIEF gist (builder expands to ≤10 lines):** `case` matches ONE word against
GLOB patterns (L1.5's `*`, `?`, `[...]` — not regex), top to bottom, and the
FIRST match wins: order is priority. `;;` ends an arm (no fallthrough);
`pat1|pat2` is alternation inside one arm; `*)` is the catch-all. The trap this
phase cares about: with no matching arm and no `*)`, case does NOTHING and exits
0 — a silent non-decision. triage.sh routes artifact filenames to handlers, and
it ships with a real ordering bug to find.

**files/triage.sh** (working sample, intent=clean, byte-exact — verified;
the `alert_*` ordering flaw is behavioral, not a shellcheck matter):
```bash
#!/usr/bin/env bash
# triage.sh — route an artifact filename to its handler.
f="${1:-}"
case "$f" in
  "") echo "usage: bash triage.sh <filename>" >&2; exit 2 ;;
  *.log) echo "route: plain log scanner" ;;
  *.json) echo "route: jq pipeline" ;;
  alert_*|ioc_*) echo "route: priority queue" ;;
  *) echo "route: quarantine (unknown type: $f)" ;;
esac
```

**TEACHING ARTIFACT** — run matrix, all verified byte-exact:
| command | output | exit |
|---|---|---|
| `bash triage.sh app.log` | `route: plain log scanner` | 0 |
| `bash triage.sh feed.json` | `route: jq pipeline` | 0 |
| `bash triage.sh alert_web.log` | `route: plain log scanner` | 0 |
| `bash triage.sh ioc_dump.bin` | `route: priority queue` | 0 |
| `bash triage.sh notes.txt` | `route: quarantine (unknown type: notes.txt)` | 0 |
| `bash triage.sh` | (stderr) `usage: bash triage.sh <filename>` | 2 |

The teaching beat is row 3: `alert_web.log` was supposed to be priority — it
matches BOTH `*.log` and `alert_*`, and case took the first. An alert just got
routed to the slow queue by pattern ORDER, not by anyone's intent. The fix
(decoded, not edited): move the `alert_*|ioc_*` arm above `*.log`. Also
verified and stated: a case with no matching arm and no `*)` exits **0** —
`case zz in a) : ;; esac; echo $?` → 0. Silent non-decision, phase theme.

*answers.txt (questions + options printed in lab.md):*
- q1 (choice) — "`bash triage.sh alert_web.log` printed…" a) route: priority
  queue — alert_* is more specific b) route: plain log scanner — *.log sits
  first and case takes the FIRST match, not the best c) route: quarantine →
  **q1=b**
- q2 (choice) — "The minimal fix so alerts win?" a) change *.log to *.LOG
  b) move the alert_*|ioc_* arm ABOVE *.log — order is priority c) replace ;;
  with ;& → **q2=b**
- q3 (value) — exit code of `bash triage.sh` (no argument) → **q3=2**
- q4 (choice) — "Delete the *) arm and feed a name no pattern matches. The
  case…" a) errors, exit 1 b) does nothing and the script exits 0 — a silent
  non-decision c) loops back to the first arm → **q4=b**

**SHELLCHECK STATUS:** files/triage.sh — clean: zero output from
`shellcheck -x -S style` (0.9.0), verified at plan time (the ordering flaw is
invisible to shellcheck — one clause in lab.md ties this to L2.2's lesson:
logic bugs are the reader's job). No flawed-header files; meta.json carries no
`teaching_samples` (the sample is clean-intent working code whose ordering is
the decode subject).

**SANDBOX NOTE:** the only write is the learner's `answers.txt` inside
`workspace/bash/L2.5/`. triage.sh reads no files — it pattern-matches its
argument string only (the filenames passed never need to exist). No system
reads, no installs, nothing destructive; decoy-tree helpers remain
[FUTURE-PHASE-ONLY].

**GUIDED STEPS outline (9 commands):**
1. `cat triage.sh` — decode: five arms, note the order. (1 cmd)
2. Run the six-row matrix (the no-arg row with `; echo $?`). Before row 3,
   lab.md asks: which arm SHOULD catch alert_web.log — and which will? (6 cmds)
3. Write answers.txt (q1–q4; options printed). (editor)
4. `lab check bash L2.5`. (1 cmd)

**CHECK LOGIC (check.sh):** standard preamble, then:
```bash
assert_file_exists "answers.txt" \
  "step 3 — write keys q1..q4 into answers.txt, one key=value per line"
assert_file_contains "answers.txt" '^q1=b$' \
  "q1 — rerun: bash triage.sh alert_web.log — which arm fired, and why that one?"
assert_file_contains "answers.txt" '^q2=b$' \
  "q2 — case takes the FIRST match; what single change makes alert_* win the race?"
assert_file_contains "answers.txt" '^q3=2$' \
  "q3 — rerun the no-argument row and transcribe the digit from echo \$?"
assert_file_contains "answers.txt" '^q4=b$' \
  "q4 — no arm matched, no catch-all: what verdict does the case leave behind?"
assert_output_contains "first match wins" 'route: plain log scanner' \
  "run: bash triage.sh alert_web.log" -- bash -- triage.sh alert_web.log
assert_cmd_fails "no argument is a usage error" \
  "run: bash triage.sh with no argument — read the first arm" -- bash -- triage.sh
ck_summary
```
The q3 hint contains `\$?` — double-quoted with escaped dollar (SC2016-safe,
built-track precedent). CI fabrication:
`printf 'q1=b\nq2=b\nq3=2\nq4=b\n' > answers.txt` — triage.sh arrives via lab
start; both live proofs run it bare.

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "case patterns are…" a) regular expressions b) glob patterns — the
   same *, ?, [...] rules as pathname expansion (L1.5), matched against a
   string instead of filenames c) literal strings only → **b**
2. choice — "What does ;; do at the end of an arm?" a) ends the whole case
   b) ends that arm with NO fallthrough — the next patterns are never tried
   after a match c) repeats the arm once → **b**
3. choice — "In `alert_*|ioc_*)`, the | is…" a) a pipe between two commands
   b) alternation: either pattern matches this one arm c) an OR of exit
   codes → **b**
(Quiz stays on mechanics; the graded keys own the ordering bug and the
silent-no-match verdict.)

**RECAP:**
```
case races GLOB patterns (not regex) top-to-bottom against one word — FIRST match wins, order is priority
;; ends an arm with no fallthrough; pat1|pat2 is alternation; *) is the catch-all default
no matching arm and no *) means case does nothing and exits 0 — a silent non-decision
```

**HINTS:** L1: "The grader reads answers.txt — keys q1..q4 (three letters and
one digit) — and runs triage.sh itself. Every answer comes from the run matrix
in step 2." L2: "q1/q2: alert_web.log matches TWO patterns; which one is
tried first, and what one edit changes that race? q3: rerun the no-arg row —
the usage arm names its own exit. q4: mentally delete the *) arm — what's
left to run, and what code does an un-entered case leave?" L3: "Rerun all six
matrix rows and transcribe: q1=b if the scanner arm fired, q2 is the
move-the-arm option, q3 is the digit echo \$? printed, q4 is the
exits-0-silently option."

---

### L2.6 — Functions — local, and return (a code) vs echo (a value)
**DECODE · gate:false · est 15 · files/: healthcheck.sh, app.log · recall.json: no**
**objective:** "Read a function and name its two output channels — return carries a one-byte verdict to if/&&/||, echo carries text to $( ) capture — and say why local keeps a function's variables out of the caller's world."

**BRIEF gist (builder expands to ≤10 lines):** A bash function is a mini-command
(L1.6: scripts are commands too — so are functions). It has exactly two ways to
hand something back: `return N` sets an exit code (one byte, consumed by
if/&&/||) and `echo` writes text (captured by `$(fn)` — L1.7). Confusing the
channels is a classic AI-bash bug: `out=$(fn)` where fn only returns leaves out
EMPTY. And without `local`, every assignment inside a function silently edits
the caller's variables. healthcheck.sh uses both channels correctly — decode it,
then break each rule at the prompt and watch.

**files/app.log** (4 lines, exactly 2 ERROR — drives the healthcheck output):
```
2026-07-13 10:00:01 INFO boot ok
2026-07-13 10:02:11 ERROR disk latency high
2026-07-13 10:02:12 ERROR retry queue full
2026-07-13 10:05:00 INFO heartbeat ok
```

**files/healthcheck.sh** (working sample, intent=clean, byte-exact — verified:
prints `status: degraded (2 errors)`, exit 0):
```bash
#!/usr/bin/env bash
# healthcheck.sh — one function returns a VALUE (echo), the other a VERDICT (return).
count_errors() {
  local n
  n=$(grep -c ERROR "$1")
  echo "$n"
}
is_healthy() {
  local n="$1"
  if (( n == 0 )); then
    return 0
  fi
  return 1
}
n=$(count_errors app.log)
if is_healthy "$n"; then
  echo "status: healthy ($n errors)"
else
  echo "status: degraded ($n errors)"
fi
```

**TEACHING ARTIFACT:**

*Part A — decode healthcheck.sh (lab.md prose):* `count_errors` delivers its
answer by ECHO, harvested by `n=$(count_errors app.log)` — the L1.7 capture.
`is_healthy` delivers by RETURN, consumed by `if is_healthy "$n"` — the L1.6
verdict (pulse.sh's pattern, now inside one script). Both declare `local n` —
two different n's coexist with the caller's `n` untouched. Run:
`bash healthcheck.sh` → `status: degraded (2 errors)`, exit 0.

*Part B — prompt experiments (one line each; all verified):*
1. `h() { return 7; }; h; echo $?` → **7** — return sets the function's exit
   code, read like any command's.
2. `broken() { return 42; }; out=$(broken); echo "out=[$out] rc=$?"` →
   **out=[] rc=42** — the channel confusion, live: $( ) captured stdout (there
   was none) while the 42 traveled the exit-code channel. out is EMPTY.
3. `g() { x=changed; }; x=start; g; echo $x` → **changed** — no local: the
   function silently edited the caller's variable.
4. `r() { return 300; }; r; echo $?` → **44** — the verdict channel is ONE
   BYTE (L1.6's "one-byte verdict", literally): 300 mod 256 = 44. return
   cannot carry data; that's what echo is for.

*answers.txt (questions + q2/q5 options printed in lab.md):*
- q1 (value) — experiment 1's digit → **q1=7**
- q2 (choice) — experiment 2: what landed in out? a) the string 42 b) nothing —
  return sends a one-byte CODE up the exit channel, never text; $( ) captures
  only stdout c) the text "return 42" → **q2=b**
- q3 (value) — experiment 3's printed word → **q3=changed**
- q4 (value) — experiment 4's digit(s) → **q4=44**
- q5 (choice) — in healthcheck.sh, count_errors hands its answer back via…
  a) return b) echo to stdout, captured by $( ) at the call site c) the global
  n → **q5=b**

**SHELLCHECK STATUS:** files/healthcheck.sh — clean: zero output from
`shellcheck -x -S style` (0.9.0), verified at plan time. app.log is data.
Typed experiment lines are not shellcheck targets (experiment 3's missing
local is the lesson — in a file, shellcheck stays silent about it anyway,
worth one clause in lab.md: the linter cannot see scope leaks; local is a
discipline, not a warning). No flawed files; no `teaching_samples`.

**SANDBOX NOTE:** the only write is the learner's `answers.txt` inside
`workspace/bash/L2.6/`. healthcheck.sh reads only ./app.log; the experiments
define throwaway functions in the learner's shell and touch no files. No
installs, no network, nothing destructive; decoy-tree helpers remain
[FUTURE-PHASE-ONLY].

**GUIDED STEPS outline (8 commands):**
1. `cat healthcheck.sh` then `cat app.log` — decode Part A; find both
   channels and both locals. (2 cmds)
2. `bash healthcheck.sh` — confirm `status: degraded (2 errors)`. (1 cmd)
3. Experiments 1–4, one line each, transcribing results. (4 cmds)
4. Write answers.txt (q1–q5); `lab check bash L2.6`. (editor + 1 cmd)

**CHECK LOGIC (check.sh):** standard preamble, then:
```bash
assert_file_exists "answers.txt" \
  "step 4 — write keys q1..q5 into answers.txt, one key=value per line"
assert_file_contains "answers.txt" '^q1=7$' \
  "q1 — rerun experiment 1 and transcribe the digit"
assert_file_contains "answers.txt" '^q2=b$' \
  "q2 — one letter: which channel does return use, and which does capture read?"
assert_file_contains "answers.txt" '^q3=changed$' \
  "q3 — rerun experiment 3: without local, whose variable did the function edit?"
assert_file_contains "answers.txt" '^q4=44$' \
  "q4 — the verdict channel is one byte wide: 300 wraps. rerun experiment 4"
assert_file_contains "answers.txt" '^q5=b$' \
  "q5 — reread the n= line in healthcheck.sh: what is being captured there?"
assert_output_contains "healthcheck names the state" 'status: degraded' \
  "run: bash healthcheck.sh — app.log carries two ERROR lines" -- bash -- healthcheck.sh
ck_summary
```
All anchored ERE, metacharacter-free, no `$` in hints. CI fabrication:
`printf 'q1=7\nq2=b\nq3=changed\nq4=44\nq5=b\n' > answers.txt` — healthcheck.sh
and app.log arrive via lab start; the live proof runs bash + grep (both on the
fence PATH).

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "Why does this track want local on every variable a function
   creates?" a) speed b) without it, every assignment lands in the caller's
   namespace — the function silently edits the world that called it c) bash
   requires it in strict mode → **b**
2. choice — "A function must hand back a hostname (a string). Which design?"
   a) return the hostname b) echo it and let the caller capture with $(fn) —
   return moves one byte of verdict, never text c) store it in $? → **b**
3. choice — "`if is_healthy "$n"; then` — what exactly does if consume?" a) the
   function's stdout b) the function's return/exit code — same as any command
   (pulse.sh, L1.6) c) the value of n → **b**
(Q1 re-frames graded q3; Q2 re-frames q2 as a design choice; Q3 ties the if
consumption back to L1.6 — graded nowhere.)

**RECAP:**
```
functions are commands: return sends a ONE-BYTE verdict to if/&&/|| — 300 wraps to 44, it can't carry data
echo sends text to $( ) capture — out=$(fn) stays EMPTY if fn only returns; never confuse the channels
local fences a function's variables; without it every assignment silently edits the caller's world
```

**HINTS:** L1: "The grader reads answers.txt — five keys q1..q5 — and runs
healthcheck.sh. q1/q3/q4 are transcribed from the experiments; q2/q5 are
letters about which channel carried what." L2: "Two channels, never mixed:
exit code (return, read by if and echo \$?) and stdout (echo, read by
capture). q2: what did the capture see when the function produced no stdout?
q4: exit codes are one byte — compute 300 mod 256. q3: no local means the
assignment escaped." L3: "Rerun each experiment exactly as printed and
transcribe: q1=7, q3 and q4 are what echo printed; for q2 and q5 pick the
option naming the stdout-capture channel."

---

### L2.7 — trap — cleanup on exit, and why installers use it
**DECODE · gate:false · est 15 · files/: staged-install.sh, payload.txt, payload-bad.txt · recall.json: no**
**objective:** "Read a trap … EXIT handler and explain why it runs on every way out — success, set -e death, or interrupt — which is exactly why installers stage work through one."

**BRIEF gist (builder expands to ≤10 lines):** `trap <handler> EXIT` registers a
command that runs on EVERY way out of the script: the happy last line, a set -e
death (L2.2), an explicit exit, or Ctrl-C. That guarantee is why real installers
are built around it — staging files, temp dirs, and half-written configs get
removed even when the install dies mid-flight. Cleanup written at the bottom of
a script is a promise; a trap is a guarantee. staged-install.sh stages a
payload, verifies it, installs it — and its trap keeps the workspace debris-free
on both the good and the bad path. The preamble from L2.2 is now load-bearing:
-e is what turns the bad path into an exit the trap can catch early.

**files/payload.txt** (3 lines — the good payload):
```
name: cardinal-agent
version: 2.4.1
payload: 7f3a
```

**files/payload-bad.txt** (2 lines — no version line; the bad payload):
```
name: cardinal-agent
payload: 7f3a
```

**files/staged-install.sh** (working sample, intent=clean, byte-exact — verified
on both paths):
```bash
#!/usr/bin/env bash
set -euo pipefail
# staged-install.sh — stage, verify, install; ALWAYS clean the staging file on the way out.
cleanup() {
  rm -f payload.staging
  echo "cleanup: staging file removed" >&2
}
trap cleanup EXIT
src="$1"
cp "$src" payload.staging
echo "staged: $src"
grep -q "version:" payload.staging
echo "verified: version line present"
mv payload.staging payload.installed
echo "installed: payload.installed"
```

**TEACHING ARTIFACT** — both runs verified byte-exact at plan time.

*Good path* — `bash staged-install.sh payload.txt` (captured as
`> good-run.txt 2>&1; echo "exit=$?" >> good-run.txt`):
```
staged: payload.txt
verified: version line present
installed: payload.installed
cleanup: staging file removed
exit=0
```
Decode beats: the cleanup line prints LAST — the trap fires after the script's
final statement, on the way out. `payload.installed` exists; `payload.staging`
does not (mv moved it; the trap's `rm -f` of the now-absent name is a no-op —
that's what -f is for).

*Bad path* — `bash staged-install.sh payload-bad.txt` (captured as
`> bad-run.txt 2>&1; echo "exit=$?" >> bad-run.txt`):
```
staged: payload-bad.txt
cleanup: staging file removed
exit=1
```
Decode beats, in order: `verified:` never printed — `grep -q version:` found no
match and exited 1; set -e (L2.2) killed the script right there; the trap STILL
ran (that's the guarantee) and removed payload.staging — no half-staged debris;
and the exit code is still grep's **1** — the trap ran but did NOT overwrite the
verdict (verified). One prose clause: had the trap been registered AFTER the cp,
a death in between would have skipped cleanup — register the trap BEFORE the
risky commands.

*answers.txt (questions + options printed in lab.md):*
- q1 (choice) — "cleanup ran on the bad path because…" a) rm is special
  b) trap … EXIT fires on EVERY way out — success, a set -e death, or an
  interrupt c) grep called it → **q1=b**
- q2 (value) — the bad run's exit code (from bad-run.txt's exit= line) →
  **q2=1**
- q3 (choice) — "after the bad run, payload.staging is…" a) still there,
  half-staged b) gone — the trap removed it on the way out; no debris for the
  next run to trip on c) renamed to payload.installed → **q3=b**
- q4 (choice) — "why register the trap BEFORE the cp/grep/mv?" a) style
  b) a death after staging but before registration would exit with NO cleanup —
  the guarantee only covers exits after the trap exists c) traps must be first
  or bash rejects them → **q4=b**

**SHELLCHECK STATUS:** files/staged-install.sh — clean: zero output from
`shellcheck -x -S style` (0.9.0), verified at plan time. The two payload files
are data. No flawed files ship; meta.json carries no `teaching_samples`.
check.sh must be clean; its hints below carry no `$`.

**SANDBOX NOTE:** staged-install.sh writes `payload.staging` and
`payload.installed` and its cleanup runs `rm -f payload.staging` — one -f
remove of one file the script itself created, inside `workspace/bash/L2.7/`.
This is the phase's only rm of any kind; it is script-owned, single-file,
non-recursive, and demonstrably fenced (both runs verified to touch nothing
outside the workspace). check.sh itself deletes nothing. Learner writes:
good-run.txt, bad-run.txt, answers.txt. No installs, no network. The rm -rf
style temp-DIR cleanup and mktemp arrive in Phase 4 (L4.7); destructive decoy
labs remain [FUTURE-PHASE-ONLY] (Phase 3).

**GUIDED STEPS outline (8 commands):**
1. `cat staged-install.sh` — decode: find the handler, the registration line,
   and the three risky commands below it. (1 cmd)
2. `cat payload.txt payload-bad.txt` — spot the difference (the version line). (1 cmd)
3. Good-path capture: `bash staged-install.sh payload.txt > good-run.txt 2>&1;
   echo "exit=$?" >> good-run.txt`, then `ls` — payload.installed exists, no
   .staging. (2 cmds)
4. Bad-path capture: `bash staged-install.sh payload-bad.txt > bad-run.txt
   2>&1; echo "exit=$?" >> bad-run.txt`, then `ls` — still no .staging: the
   trap cleaned up a FAILED run. (2 cmds)
5. Write answers.txt (q1–q4); `lab check bash L2.7`. (editor + 1 cmd)

**CHECK LOGIC (check.sh):** standard preamble, then:
```bash
assert_file_contains "good-run.txt" 'installed: payload.installed' \
  "step 3 — capture the good run: the payload.txt run installs and says so"
assert_file_contains "good-run.txt" '^exit=0$' \
  "good-run.txt needs the appended exit= line — rerun both step-3 commands"
assert_file_contains "bad-run.txt" 'cleanup: staging file removed' \
  "step 4 — capture the bad run with 2>&1: the trap's message travels on stderr"
assert_file_not_contains "bad-run.txt" 'verified' \
  "bad-run.txt should show the death BEFORE verification — did you run payload-bad.txt?"
assert_file_contains "bad-run.txt" '^exit=1$' \
  "the trap does not overwrite the verdict: the bad run reports grep's own code"
assert_file_missing "payload.staging" \
  "no staging debris may survive — the trap removes it on every exit; rerun step 4 and look"
assert_file_exists "payload.installed" \
  "step 3's good run installs the payload — rerun it if the file is missing"
assert_file_contains "answers.txt" '^q1=b$' \
  "q1 — one letter: what does EXIT mean in trap cleanup EXIT?"
assert_file_contains "answers.txt" '^q2=1$' \
  "q2 — transcribe the digit from bad-run.txt's exit= line"
assert_file_contains "answers.txt" '^q3=b$' \
  "q3 — ls after the bad run: what happened to payload.staging?"
assert_file_contains "answers.txt" '^q4=b$' \
  "q4 — imagine the trap registered AFTER the cp: which deaths would escape cleanup?"
ck_summary
```
11 assertions, all anchored ERE, metacharacter-free, no `$` in hints. Note the
`assert_file_not_contains "bad-run.txt" 'verified'` — it also catches a learner
who captured the wrong payload. CI fabrication: `printf '%s\n' 'staged: payload.txt'
'verified: version line present' 'installed: payload.installed'
'cleanup: staging file removed' 'exit=0' > good-run.txt; printf '%s\n'
'staged: payload-bad.txt' 'cleanup: staging file removed' 'exit=1' > bad-run.txt;
printf 'name: x\n' > payload.installed; printf 'q1=b\nq2=1\nq3=b\nq4=b\n' >
answers.txt` (payload.staging simply never created) — bash+coreutils only.

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "Cleanup written as the last lines of a script vs a trap on EXIT?"
   a) identical b) bottom-of-script cleanup never runs when the script dies
   early — the trap runs on every exit path; a promise vs a guarantee c) traps
   are faster → **b**
2. choice — "Why do installers in particular lean on trap?" a) tradition
   b) installs stage temp files/dirs and half-written configs; when an install
   dies mid-flight, the trap is what keeps the machine free of debris that
   would poison the next attempt c) package managers require it → **b**
3. choice — "Did the EXIT trap change the bad run's exit code?" a) yes — traps
   exit 0 b) no — the run still reported 1; a trap only changes the verdict if
   the handler itself calls exit c) it reports the trap's own last command →
   **b**
(Q1/Q2 are the map's "why installers use it" framing; Q3 re-checks graded q2's
mechanism from the other side.)

**RECAP:**
```
trap <handler> EXIT runs the handler on EVERY way out — the happy end, a set -e death, or Ctrl-C
register the trap BEFORE the risky commands: bottom-of-script cleanup is a promise, a trap is a guarantee
the trap doesn't overwrite the verdict — the failed run still reported grep's 1 to whoever called it
```

**HINTS:** L1: "The grader reads good-run.txt, bad-run.txt, answers.txt
(q1..q4), and the workspace itself: payload.installed must exist and
payload.staging must NOT. Both captures are printed verbatim in steps 3–4."
L2: "Each capture is the run redirected with 2>&1 (the cleanup line travels on
stderr) plus the appended exit= line. bad-run.txt must show staged + cleanup
but never verified. Letters: q1 names what EXIT covers, q3 what the trap did
to the staging file, q4 what a late registration would miss." L3: "Rerun steps
3 and 4 exactly as printed, ls after each, and transcribe: q2 is the digit on
bad-run.txt's exit= line; q1/q3/q4 are the every-exit-path, debris-removed,
and register-before-risk options."

---

### L2.8 — Phase gate: a script that fails silently — trace it, find where it lied
**FIX · gate:true · est 20 · files/: archive-errors.sh, app.log, archive/.gitkeep · recall.json: no (drafts L3.1's — see end of entry)**
**objective:** "Prove the phase is internalized: trace a script that reports success while doing nothing, name the exact command that failed and both mechanisms hiding it, then fix it so its exit code tells the truth."

Integration, nothing new: the bug is hidden by the ABSENCE of L2.2's preamble,
the trace runs on L1.6/L2.4 exit-code reasoning, and the fix is the preamble
(or L2.4's `|| exit` guards — both pass, see CHECK LOGIC).

**THE EXACT BUG (spec for the builder):** the script archives ERROR lines into
`archive/` — but the cp names the directory `archiv/` (typo), which does not
exist. cp fails; its stderr is swallowed by `2>/dev/null`; the next commands
(rm, echo) succeed; the explicit `exit 0` (and, without it, echo's success —
L1.6) makes the script report success. The archive stays empty while the
script prints a success message and exits 0. Verified end-to-end at plan time.

**files/app.log** (6 lines, exactly 3 ERROR — the graded count):
```
2026-07-13 09:00:01 INFO service started
2026-07-13 09:14:31 ERROR upstream timeout
2026-07-13 09:14:33 INFO retry 1 ok
2026-07-13 09:20:05 ERROR disk full on /var
2026-07-13 09:20:06 ERROR write failed
2026-07-13 09:30:00 INFO heartbeat ok
```

**files/archive/.gitkeep** — empty file; seeds the real `archive/` directory
into the workspace (same mechanism as L1.3's backup/, verified there).

**files/archive-errors.sh** (TEACHING SAMPLE header line 2; expected SC codes:
**none** — verified zero findings; the empty list is graded insight, see QUIZ):
```bash
#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# archive-errors.sh — extract the ERROR lines from a log and file them in archive/.
log="$1"
grep ERROR "$log" > errors.txt
cp errors.txt archiv/errors.txt 2>/dev/null
rm -f errors.txt
echo "archived: ERROR lines from $log are in archive/errors.txt"
exit 0
```

**TEACHING ARTIFACT** — all runs verified at plan time.

*Part 1 — run the liar and trace it.* Capture:
`bash archive-errors.sh app.log > broken-run.txt 2>&1; echo "exit=$?" >> broken-run.txt`
```
archived: ERROR lines from app.log are in archive/errors.txt
exit=0
```
Then `ls archive` → EMPTY. The script said success, exited 0, and did nothing —
and `rm -f errors.txt` even destroyed the intermediate evidence. Trace
questions (answers.txt): which command failed, where its error went, why the
exit code lied, which Phase-2 tool stops it. `shellcheck archive-errors.sh` →
**zero findings, exit 0** (verified): the linter passes the liar.

*Part 2 — fix it (edit the workspace copy of archive-errors.sh).* The minimal
fix, spelled in lab.md at hint-3 level of explicitness only (the lab text names
the GOALS, hints give the edits): add the L2.2 preamble, fix `archiv/` →
`archive/`, delete the `2>/dev/null`. Deleting the trailing `exit 0` is
recommended prose but not graded (under -e it is unreachable on failure).
Reference fixed script (verified: shellcheck-clean; happy run exits 0 and
archives 3 lines; `bash archive-errors.sh missing.log` exits 2 at the grep;
no-arg run dies on -u with `$1: unbound variable`, exit 1):
```bash
#!/usr/bin/env bash
set -euo pipefail
# archive-errors.sh — extract the ERROR lines from a log and file them in archive/.
log="$1"
grep ERROR "$log" > errors.txt
cp errors.txt archive/errors.txt
rm -f errors.txt
echo "archived: ERROR lines from $log are in archive/errors.txt"
```
An equally valid fix (accepted automatically by behavioral grading): keep no
preamble and guard each command with `|| exit 1` (L2.4). lab.md states the
track default is the preamble.

*answers.txt (questions + options printed in lab.md):*
- q1 (choice) — "The command that actually failed:" a) grep — no ERROR lines
  b) cp — its target directory archiv/ does not exist c) rm → **q1=b**
- q2 (choice) — "You saw no error because…" a) cp fails silently by design
  b) 2>/dev/null threw cp's report away c) the terminal ate it → **q2=b**
- q3 (choice) — "The exit code was 0 because…" a) cp failures don't set $?
  b) nothing made the failure STOP the script — rm and echo then succeeded,
  and the trailing exit 0 sealed the lie (even without it, echo's 0 would —
  L1.6) c) bash resets $? between lines → **q3=b**
- q4 (choice) — "The Phase-2 tool that stops the script AT the failing cp:"
  a) set -euo pipefail — the -e b) a case statement c) trap cleanup EXIT →
  **q4=a**

**SHELLCHECK STATUS:** files/archive-errors.sh — TEACHING SAMPLE — intentionally
flawed (header exactly line 2); expected codes under `shellcheck -x -S style`
(0.9.0): **NONE — zero findings, verified.** meta.json:
`"teaching_samples": {"files/archive-errors.sh": []}`. The empty list is the
gate's own lesson (quiz Q1): silent failure is a runtime-behavior bug class the
linter cannot see. The learner's FIXED workspace copy must also be
shellcheck-clean (verified for the reference fix) — but per track convention
check.sh does not invoke shellcheck; behavioral asserts carry the grade.
app.log and archive/.gitkeep are data.

**SANDBOX NOTE:** every write lands inside `workspace/bash/L2.8/`: broken-run.txt,
answers.txt, the learner's edited archive-errors.sh, errors.txt (transient),
archive/errors.txt. The script's `rm -f errors.txt` removes only its own
intermediate file. check.sh runs the learner's script twice (happy + sabotage
arg) — the sabotage is a MISSING input filename, not any filesystem damage; the
sad run may leave an empty errors.txt behind (harmless, noted). Nothing
destructive, no installs, no network. Decoy-tree helpers remain
[FUTURE-PHASE-ONLY] — see the Phase-3 flag in §7.

**GUIDED STEPS outline (11 commands):**
1. `cat archive-errors.sh` then `cat app.log` — read the claim before testing
   it. (2 cmds)
2. The broken-run capture (printed verbatim), then `ls archive` — empty. The
   gate question, verbatim in lab.md: "the script said success — find where it
   lied." (2 cmds)
3. `shellcheck archive-errors.sh` — silence. Your co-pilot vouches for the
   liar; the trace is on you. (1 cmd)
4. Write answers.txt (q1–q4) — the trace, BEFORE fixing. (editor)
5. Fix the workspace archive-errors.sh (editor). Verify yourself:
   `bash archive-errors.sh app.log; echo $?` (expect the message and 0),
   `grep -c ERROR archive/errors.txt` (expect 3),
   `bash archive-errors.sh missing.log; echo $?` (expect a loud grep error and
   a NONZERO code — the honesty test). (3 cmds)
6. `lab check bash L2.8`. (1 cmd)

**CHECK LOGIC (check.sh):** standard preamble, then:
```bash
assert_file_contains "broken-run.txt" 'archived: ERROR lines' \
  "step 2 — capture the ORIGINAL broken run before fixing (the lie is evidence)"
assert_file_contains "broken-run.txt" '^exit=0$' \
  "broken-run.txt needs the appended exit= line — the lie includes the code"
assert_file_contains "answers.txt" '^q1=b$' \
  "q1 — which command's TARGET does not exist? read each line's operands again"
assert_file_contains "answers.txt" '^q2=b$' \
  "q2 — where does 2>/dev/null send a command's complaints?"
assert_file_contains "answers.txt" '^q3=b$' \
  "q3 — nothing stopped the script, and the commands after the failure all succeeded"
assert_file_contains "answers.txt" '^q4=a$' \
  "q4 — which lab of this phase exists to stop scripts at their first failure?"
assert_cmd_ok "fixed script succeeds on the shipped log" \
  "step 5 — your fixed script must archive app.log and exit 0" \
  -- bash -- archive-errors.sh app.log
assert_file_exists "archive/errors.txt" \
  "the archive the team reads is archive/ — the typo'd directory name is part of the bug"
assert_output_contains "all three ERROR lines archived" '^3$' \
  "archive/errors.txt must hold exactly the 3 ERROR lines from app.log" \
  -- grep -c ERROR archive/errors.txt
assert_cmd_fails "honesty test: a missing log must be FATAL, not narrated over" \
  "run: bash archive-errors.sh missing.log — a dead grep must stop the script (L2.2 preamble or || exit guards)" \
  -- bash -- archive-errors.sh missing.log
ck_summary
```
10 assertions. Order matters: the happy behavioral run (7–9) precedes the
honesty run (10) so the sad run's transient empty errors.txt cannot confuse
anything. All patterns anchored ERE except none need fixed form; no `$` in
hints; no banned tokens (check.sh itself never deletes or creates anything —
both live runs execute the learner's script, same trust model as P0/P1's
pulse.sh/report.sh live proofs). CI fabrication (bash+coreutils only): after
`lab start` seeds the flawed files, overwrite the script with the reference
fixed content via printf, then `printf '%s\n' 'archived: ERROR lines from
app.log are in archive/errors.txt' 'exit=0' > broken-run.txt; printf
'q1=b\nq2=b\nq3=b\nq4=a\n' > answers.txt` — the three live asserts then run
the fixed script for real. Negative case for tests/acceptance.sh: leave the
shipped flawed script unedited → assert 10 fails (exit 0 from the liar).

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "shellcheck printed NOTHING for the broken script. The lesson?"
   a) shellcheck is useless b) silent failure is invisible to static analysis —
   strict mode at run time plus your own tracing are what catch it; the linter
   guards syntax, not honesty c) always run shellcheck twice → **b**
2. choice — "After your fix, someone runs it on a log with ZERO error lines.
   What happens?" a) clean success — empty archive b) grep exits 1 on no-match
   (L1.6), so under -e the script DIES: 'no errors' needs an explicit decision,
   e.g. grep … || true (L2.4), if empty-is-fine c) cp fails again → **b**
3. choice — "The trust rule this phase installs:" a) always read exit codes
   twice b) a script's exit code is only meaningful if every failure inside it
   either stops the script or is explicitly handled — otherwise 0 just means
   'the last line ran' c) never trust echo → **b**
(Q1 grades the linter-blindness insight; Q2 is the deliberate overreach nuance
of -e — the next thing a hardened reader must know; Q3 is the phase thesis.)

**RECAP:**
```
a script that keeps going after a failure will happily narrate success — exit 0 can lie (L1.6: it's just the LAST verdict)
2>/dev/null plus a trailing echo/exit 0 is how failure hides; set -euo pipefail (or || exit) is how it stops
shellcheck passed the liar with zero findings — the linter guards syntax; honesty is the reader's job
```

**HINTS:** L1: "Two deliverables: the trace (broken-run.txt captured BEFORE the
fix, plus answers.txt q1..q4) and the fix (the grader runs your edited script
against app.log, checks archive/errors.txt holds all 3 ERROR lines, and runs
it against missing.log expecting a NONZERO exit)." L2: "Trace: follow each
line's operands — one command names a directory that doesn't exist; its
complaint went where 2>/dev/null sends things; then ask what the LAST verdict
was (L1.6). Fix: the goals are (1) failures must stop the script — L2.2's
preamble is the track default, (2) the real directory is archive/, (3) errors
must be allowed to reach your eyes." L3: "Three edits: insert set -euo
pipefail after the header comment; change archiv/ to archive/; delete
2>/dev/null (and, ideally, the trailing exit 0). Then rerun the three step-5
verification commands and lab check bash L2.8."

**FOR THE PHASE 3 BUILDER — L3.1 recall.json draft (5 questions; all-P2
consolidation before the footgun phase — the P0/P1 classics return inside the
footguns themselves; do NOT ship any of this in L2.8):**
1. choice (source: "bash L2.2") — "Which strict-mode flag makes an unset or
   typo'd variable fatal?" a) -e b) -u c) pipefail → **b**
2. choice (source: "bash L2.4") — "`true && false || echo X` — does X print?"
   a) no — || pairs with true's success b) yes — || reacts to the most recent
   verdict, false's failure c) syntax error → **b**
3. choice (source: "bash L2.7") — "A trap registered on EXIT runs…" a) only
   after exit 0 b) only on errors c) on every way out — success, failure, or
   interrupt → **c**
4. choice (source: "bash L2.6") — "out=$(f) where f's body is only `return 3`
   leaves out holding…" a) 3 b) nothing — return sends a one-byte code, not
   text; $( ) captures stdout only c) the string 'return 3' → **b**
5. choice (source: "bash L2.3") — "`for w in $(cat file)` iterates over…"
   a) the file's lines b) the whitespace-split words of the file c) exactly
   one item → **b**

## 5. Build-session protocol (execute in this order)

1. Scaffold the 8 lab directories under `tracks/bash/phases/p2/` per §1 slugs.
   `tracks/bash/track.json` already names p2 ("Control Flow & Silent Failure")
   — do not touch it.
2. Author content straight from §4. Base64 every quiz/recall answer
   (`printf '%s' 'answer' | base64 -w0`); text answers lowercase with listed
   accept_b64 variants. tasks.txt (L2.3) must be created with the exact printf
   in its entry — the missing final newline is load-bearing; add a build-report
   note confirming `wc -c files/tasks.txt` = 42.
3. **Self-test sweep (PROMPTS.md no-fiction rule).** Execute every command in
   every lab.md yourself and paste the REAL captured output — never from
   memory, and never from this plan (this plan's values were machine-verified
   at plan time on 2026-07-14, but the build machine's run is authoritative).
   Re-verify each `[VERIFY-AT-BUILD]`-class item: exact error-message prefixes
   (they vary by invocation context — lab.md quotes stable suffixes only), the
   SC code sets on the build machine's shellcheck, and every exit code in §4's
   tables.
4. Shellcheck gate: every clean-intent `files/*.sh` (gatekeeper.sh,
   hardened.sh, readlines.sh, guard.sh, triage.sh, healthcheck.sh,
   staged-install.sh) → zero output from `shellcheck -x -S style`; every
   TEACHING SAMPLE (e-demo.sh, u-demo.sh, p-demo.sh, archive-errors.sh) →
   exactly its meta.json `teaching_samples` codes (including the two
   deliberately EMPTY lists). Then `./tools/lint-labs.sh` must pass clean.
5. Acceptance: extend `tests/acceptance.sh` per the P0/P1 pattern — for each
   lab, fabricate passing artifacts with bash+coreutils only (each entry's CI
   fabrication recipe), run `printf 'a\nb\nc\n' | lab check bash <id>`
   expecting pass, plus one negative case per lab (delete/corrupt one artifact
   → graded fail, exit 1). L2.8's negative case: leave the shipped flawed
   script unedited. For L2.1, drive `lab start bash L2.1` with 5 piped recall
   answers and assert it never gates.
6. Run the phase end-to-end manually once (author's own `lab check` per lab,
   quiz typed) before tagging `bash-p2` per PROMPTS.md.
7. Update `planned_execution.md` (mark bash p2 done with tag evidence, refresh
   NEXT UP/LAST SESSION) — the build session's job, not this plan's.

## 6. Decisions & deviations log (for the reviewer)

- **L2.2 before/after = one script per flag, flag toggled on the command line**
  (`bash -e/-u/-o pipefail <demo>.sh`), not three off/on file pairs. Guarantees
  the only delta between runs is the flag; halves the file count; hardened.sh
  covers the in-script preamble form and is verified to behave identically to
  `bash -e e-demo.sh`. This is the plan's one interpretation call on the
  phase-spec's "three small before/after scripts, one per flag" — the three
  scripts exist, and each is demonstrated before/after; flag it in review if
  literal file pairs are preferred.
- **Loop predictions grade line COUNTS** (plus two exact lines): keeps the
  one-key-one-line predictions.txt convention for inherently multi-line
  output, and makes the 7-vs-2-vs-3 iteration story the graded signal.
  argv.sh is not shipped anywhere in p2.
- **L2.8 graded behaviorally** (three live runs of the learner's edited
  script), never by grepping for a specific fix — both the preamble and
  `|| exit` guards pass, as both are correct. The "find where it lied"
  requirement is carried by the four trace questions + the pre-fix
  broken-run.txt capture.
- **Empty `teaching_samples` lists** on e-demo.sh and archive-errors.sh are
  deliberate and verified (zero findings on 0.9.0): the linter's blindness to
  silent failure is itself graded content (L2.2 quiz Q1, L2.8 quiz Q1).
- **L2.7 ships the phase's only rm** (`rm -f payload.staging` — single
  script-created file, non-recursive, in-fence, verified both paths). Chosen
  over an rm -rf temp-dir cleanup to keep p2 free of recursive deletion;
  mktemp/temp-dir hygiene is L4.7's job per the map.
- **Interactive-safety line in L2.4** (never `|| exit` at a prompt) added
  because the lab would otherwise invite learners to exit their own shells.
- **Quiz/graded answer letters shuffled** (L2.2's graded run is b/c/a/b) to
  avoid all-b patterns.
- **est_minutes total: 120** across 8 labs (map gives no per-lab estimates;
  all within the 10–20 ADHD band; L2.2 and the gate at 20).

## 7. Forward flags for Phase 3 ([FUTURE-PHASE-ONLY])

Phase 2 ships zero destructive commands and never touches the decoy-tree
helpers. Phase 3 cannot make that claim: per the map, **L3.2 (rm -rf
empty-variable catastrophe), L3.3 (IFS attacks), L3.4 (filename attacks), and
the L3.9 gate all require the decoy-tree / shadowed-destructive-command
containment mechanism** — `make_decoy_tree` / `decoy_intact` / `decoy_changed`
exist in harness/checklib.sh but no lab has ever exercised them. This is
already flagged in planned_execution.md's NEXT UP; the p3 PLAN session must
design and prove the containment story (decoy targeting + self-test proof that
nothing outside the workspace changed) BEFORE speccing its first footgun lab.
Two p2 labs foreshadow the p3 material verbally only (L2.2's u-demo names the
`rm -rf "$DIR/"` mechanism; L2.4's quiz discusses `cd && rm`): both are
prose-only, nothing executed — that boundary must hold in the build.

