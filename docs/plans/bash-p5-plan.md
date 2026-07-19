# Bash Track — Phase 5 Build Plan (Text Processing & Pipelines)

## Context

**Why this exists.** Phase 4 ("Untrusted Input & Injection," 8 labs) is **closed**
— marker `[x]`, git tag `bash-p4`, close-out commit merged 2026-07-18, all 8 lab
dirs on disk, `tests/acceptance.sh` extended, `(36/36)` catalog. Per
`planned_execution.md`'s NEXT UP line, the next unstarted item is **`bash p5 —
Text Processing & Pipelines` (6 labs)**, which "needs a PLAN session first (no
`docs/plans/bash-p5-plan.md` exists yet)." This is that plan session, run per
`PROMPTS.md`'s Phase Builder protocol (Prompt 2, steps 1–3: ORIENT → RE-READ the
curriculum map → PLAN and **wait for approval before building**). No `p5/`
directory exists on disk; no p5 commits/tag exist. `tracks/bash/track.json`
already lists `"p5": "Text Processing & Pipelines"`, so no track-registration
work is needed at build.

**What Phase 5 is.** From the curriculum map
(`docs/curriculum/bash-literacy-lab-curriculum-v1.md:195-208`): *"The reading
skills for the log-wrangling tools that SOC scripts are built from. You don't
need to write awk — you need to read the pipeline someone (or an AI) already
wrote."* Phase outcome (map `:97`): **read grep/sed/awk/jq log pipelines
fluently.** 6 labs, L5.1–L5.6. Security hook (map `:207`): L5.4 (`jq`) ties
straight to reading a filter that reshapes log JSON into ECS format — exactly
the glue code this learner reviews and directs day to day.

**How Phase 5 differs from Phase 3/4 — no destructive-content contract needed.**
Phases 3 and 4 required an entire safety apparatus (static-only samples, command
shadowing via `fence.sh`, "never executed" proofs) because their subject was
*dangerous* code: `rm -rf`, `eval`, injection droppers. **Phase 5's subject is
ordinary, safe, read-only text processing over static log/data files.** Every
reference script below is real, correct, `shellcheck`-clean, and **is meant to
be executed for real** — by the learner in GUIDED STEPS and, where a concrete
answer is graded, by `check.sh` itself. There is no flawed sample anywhere in
this phase; the skill being trained is *reading a pipeline someone already got
right*, not spotting a bug. This is a first for the bash track and is called out
explicitly so the build session doesn't reach for Phase 3/4 machinery
(`fence.sh`/`run-fenced.sh`, `make_decoy_tree`, "TEACHING SAMPLE — intentionally
flawed" banners) that Phase 5 has no use for.

**Intended outcome of the build that follows this plan.** Six labs authored to
the established directory/harness pattern (`meta.json`/`lab.md`/`check.sh`/
`quiz.json`/`hints.json`/`recap.md`/`files/`), where every sample pipeline,
`sed`/`awk`/`jq` filter, and reference script has been **actually run during
this planning session** (not written from memory) and its real captured output
is recorded verbatim below. All judgment (exact samples, exact answer keys,
exact check logic, quizzes, recaps) is fixed here so the build is mechanical.

---

## Phase 5 lab list (authoritative)

Source: curriculum map `:198-205`. Types are the map's own taxonomy (`:59-68`).
`est_minutes` is assigned here per the map's global 10–20 min contract (`:78`).

| id | slug (dir) | Title | Type | gate | est |
|----|------------|-------|------|------|-----|
| L5.1 | `L5.1-pipelines-core-tools` | Pipelines and the core tools — `grep`, `cut`, `sort`, `uniq`, `wc` | DECODE | no | 12 |
| L5.2 | `L5.2-sed-reading` | `sed` at reading level — substitution and the patterns you'll actually meet | DECODE | no | 12 |
| L5.3 | `L5.3-awk-reading` | `awk` at reading level — the tool that looks like magic, demystified | PREDICT | no | 15 |
| L5.4 | `L5.4-jq-pipelines` | `jq` — reading JSON pipelines (ECS / log territory) | DECODE | no | 15 |
| L5.5 | `L5.5-process-substitution` | Process substitution `<(...)`, here-docs, and here-strings | DECODE | no | 12 |
| L5.6 | `L5.6-phase-gate-pipeline` | **Phase gate:** decode a real log-processing pipeline top to bottom | DECODE | **yes** | 20 |

Type spread: 5×DECODE, 1×PREDICT (L5.3). One gate: **L5.6**. Total ≈86 min.

---

## Design conventions for Phase 5 (departs from Phase 3/4 where noted)

1. **No fence, no shadowing, no decoy tree.** Nothing in this phase is
   destructive. `harness/checklib.sh`'s `make_decoy_tree`/`decoy_intact` are not
   used anywhere in Phase 5. `files/` never contains `fence.sh`/`run-fenced.sh`.
2. **Reference scripts are real, executable, and correct.** Each script ships
   in `files/` at mode **755** (not Phase 3/4's non-executable `0644`), carries
   the banner `# REFERENCE SAMPLE — read, decode, and run for real.` on **line
   2**, and is itself `shellcheck`-clean — verified against real `shellcheck`
   output for every sample below, not asserted from memory.
3. **Static data files carry no banner** — `access.log`, `alerts.csv`,
   `events.jsonl`, `allowed.txt`/`seen.txt`, `allowed-ips.txt` are plain data,
   copied into the workspace alongside each lab's script.
4. **Fictional-domain hygiene carried forward from Phase 4, as realism hygiene
   rather than a safety requirement.** Hostnames use RFC 2606 (`*.test`); IPs
   use RFC 5737 TEST-NET ranges (`192.0.2.0/24`, `198.51.100.0/24`,
   `203.0.113.0/24`). Nothing here needs an exemption from `tools/lint-labs.sh`
   or `tools/shellcheck-all.sh` — the samples aren't malicious, they're just
   kept fictional so a log sample never appears to reference real
   infrastructure.
5. **Because execution is safe, `check.sh` may run the shipped script for real**
   and cross-verify the learner's `answers.txt` against live output, using
   `assert_cmd_ok` / `assert_output_contains` (`harness/checklib.sh:153,186`) —
   used in L5.1, L5.2, L5.4, and L5.6 alongside the structural comprehension
   keys every lab grades. L5.3 (PREDICT) instead grades a `predictions.txt`
   written *before* the learner runs anything, per the track's established
   PREDICT pattern (L1.x, L3.6) — the values graded are the same real values
   captured in this plan, fixed at build time since the shipped data files
   never change.
6. **Banned-token check (`tools/lint-labs.sh:83-87`):** the whole-word bans are
   `eval`, `sudo`, `curl`, `wget`, `nc`, `ssh`, `sh -c`, `bash -c`, `pushd`,
   `bin/lab`. Phase 5's entire vocabulary — `pipeline`, `filter`, `field`,
   `redact`, `reshape`, `procsub`, `herestring`, `heredoc`, `offender`,
   `allowlist` — is clean by inspection; no lab below needs the literal-splitting
   escape hatch Phase 3/4 required.
7. **No absolute-path literals, no `cd ..`/`cd ~`** in any `check.sh` (inherited
   lint rule, `:37-62,:91-93`) — none of the checks below need either.

---

## Global build conventions (unchanged from Phase 3/4 except where noted above)

**Per-lab directory** `tracks/bash/phases/p5/L5.N-slug/` containing:

- `meta.json` — `{ "id","title","type","objective","gate":<bool>,"est_minutes":<int> }`
  (required-field lint: `tools/lint-labs.sh:120`).
- `lab.md` — `## BRIEF` (≤10 lines, no external reading) then `## GUIDED STEPS`
  (numbered walkthrough ending in `lab check bash L5.N`). Every command the
  learner is told to run has its **real captured output** pasted below —
  reused verbatim into `lab.md` at build time, not re-derived from memory.
- `check.sh` — mode **644**, non-executable. Canonical header: `#!/usr/bin/env
  bash` / `set -euo pipefail` / `: "${LAB_WORKSPACE:?…}"` /
  `: "${LAB_CHECKLIB:?…}"` / `# shellcheck source=/dev/null` /
  `source "$LAB_CHECKLIB"` … `ck_summary`.
- `quiz.json` — exactly **3** questions, `{"id","type":"choice","prompt",
  "options":{a,b,c},"answer_b64"}` (`printf '%s' 'b' | base64 -w0` → `Yg==`;
  `a` → `YQ==`; `c` → `Yw==`).
- `hints.json` — `{"hints":[…]}`, exactly **3** rungs, escalating, never the
  full answer at rung 1.
- `recap.md` — exactly **3** plain-text lines.
- `files/` — the static data file(s) + (every lab but L5.3) the reference
  script, mode 755.
- `recall.json` — **L5.1 only** (phase opener), **5** questions sourced from
  Phase 4, graded but never gates.

**Grading helpers** (`harness/checklib.sh`, sourced via `$LAB_CHECKLIB`, exact
signatures confirmed by reading the file this session):
`assert_file_exists <path> [hint]`, `assert_file_contains <path> <ERE> [hint]`,
`assert_file_contains_fixed <path> <literal> [hint]`,
`assert_file_not_contains <path> <ERE> [hint]`,
`assert_cmd_ok <desc> <hint> -- <cmd...>`,
`assert_cmd_fails <desc> <hint> -- <cmd...>`,
`assert_output_contains <desc> <ERE> <hint> -- <cmd...>`, and terminal
`ck_summary`.

**Comprehension answer-key vocabulary.** Learner writes flat `key=value` lines
to `answers.txt`; grader matches anchored ERE (`^key=value$`), following the
DECODE convention set by L4.6/L3.3 — short, single-word or fixed-token fields,
never free prose.

---

## Lab entries (build straight from these)

Per-lab template: **(1)** id/title/type/gate/est · **(2)** ARTIFACT (exact
script/data, real captured output) · **(3)** EXECUTION NOTE · **(4)** CHECK
LOGIC · **(5)** QUIZ (3) + RECAP (3). L5.1 also carries §6 (5 spaced-recall
questions). Every command shown below was **actually run this session**;
output is pasted verbatim, not reconstructed.

---

### L5.1 — Pipelines and the core tools — `grep`, `cut`, `sort`, `uniq`, `wc`
**DECODE · gate:false · est 12 · files/: `access.log`, `top-offenders.sh` · recall.json: YES (§6)**
**objective:** "Read a `grep | cut | sort | uniq -c | sort -rn` pipeline over a
log file and state what each stage does to the stream, then report the final
answer it computes."

**(2) ARTIFACT** — `files/access.log` (8 lines, fictional TEST-NET clients):
```
198.51.100.23 - - [18/Jul/2026:10:12:01 +0000] "GET /login HTTP/1.1" 200 512
203.0.113.7 - - [18/Jul/2026:10:12:03 +0000] "GET /login HTTP/1.1" 401 128
198.51.100.23 - - [18/Jul/2026:10:12:05 +0000] "POST /login HTTP/1.1" 401 128
203.0.113.7 - - [18/Jul/2026:10:12:07 +0000] "GET /login HTTP/1.1" 401 128
203.0.113.7 - - [18/Jul/2026:10:12:09 +0000] "GET /login HTTP/1.1" 401 128
192.0.2.15 - - [18/Jul/2026:10:12:11 +0000] "GET /dashboard HTTP/1.1" 200 4096
203.0.113.7 - - [18/Jul/2026:10:12:13 +0000] "GET /login HTTP/1.1" 401 128
198.51.100.23 - - [18/Jul/2026:10:12:15 +0000] "GET /dashboard HTTP/1.1" 200 4096
```
`files/top-offenders.sh` (verified `shellcheck`-clean):
```bash
#!/usr/bin/env bash                                   # line 1
# REFERENCE SAMPLE — read, decode, and run for real.  # line 2
set -euo pipefail                                     # line 3
grep ' 401 ' access.log \                             # line 4  (1) filter: keep only failed-auth lines
  | cut -d' ' -f1 \                                   # line 5  (2) field: keep only the source-IP column
  | sort \                                             # line 6  (3) order: group equal IPs adjacently
  | uniq -c \                                          # line 7  (4) count: collapse each run, prefix with its count
  | sort -rn \                                         # line 8  (5) rank: numeric sort, largest count first
  | head -1                                             # line 9  (6) keep just the top offender
```
Real captured output (`./top-offenders.sh`):
```
      4 203.0.113.7
```
For `lab.md` illustration, the full ranked list before `head -1` (also
captured for real):
```
      4 203.0.113.7
      1 198.51.100.23
```
`wc -l < access.log` → `8`.

**(3) EXECUTION NOTE:** safe to run — GUIDED STEPS has the learner run
`./top-offenders.sh` for real and read the count/IP off the terminal.
`check.sh` also re-runs it to cross-verify.

**(4) CHECK LOGIC:**
- `assert_file_contains "answers.txt" '^stage4=filter$'`
- `assert_file_contains "answers.txt" '^stage5=field$'`
- `assert_file_contains "answers.txt" '^stage6=(order|group)$'`
- `assert_file_contains "answers.txt" '^stage7=count$'`
- `assert_file_contains "answers.txt" '^stage8=rank$'`
- `assert_file_contains "answers.txt" '^top_ip=203\.0\.113\.7$'`
- `assert_file_contains "answers.txt" '^top_count=4$'`
- `assert_cmd_ok "top-offenders.sh runs clean" "…" -- bash -- top-offenders.sh`
- `assert_output_contains "reports the real top offender" '203\.0\.113\.7' "…" -- bash -- top-offenders.sh`
- `ck_summary`

**(5) QUIZ + RECAP:**
- Q1: "In `sort | uniq -c`, `sort` runs first because…" a) it's alphabetical ·
  **b) `uniq -c` only collapses *adjacent* duplicate lines — sort must group
  identical lines together first** · c) `uniq` requires numeric input → `Yg==`
- Q2: "`cut -d' ' -f1` on an access-log line extracts…" **a) the first
  whitespace-delimited field — the client IP, in this log format** · b) the
  first character · c) the first word after a comma → `YQ==`
- Q3: "`sort -rn` after `uniq -c` ranks…" a) alphabetically · **b) numerically,
  largest count first** · c) by original file order → `Yg==`
- Recap:
  1. `A pipeline is a chain of single-purpose filters — each stage reads stdin, transforms it, and writes stdout to the next; read it top to bottom, one transformation at a time.`
  2. `uniq -c only collapses ADJACENT duplicate lines, which is why sort almost always comes right before it — unsorted input makes uniq silently undercount.`
  3. `grep filters rows, cut extracts columns, sort orders, uniq -c counts, a second sort -rn ranks — that shape covers most "what's happening the most" log questions.`

**(6) L5.1 SPACED-RECALL — `recall.json` (5 Q, all sourced from Phase 4).**
Same shape as L4.1's opener (`id`, `type:"choice"`, `source`, `prompt`,
`options{a,b,c}`, `answer_b64`). All five answers are **b → `Yg==`**, mirroring
the L4.1 precedent (`bash-p4-plan.md:254-273`). Graded but never gates.
1. source `bash L4.1` — "Untrusted data becomes executed code the instant it…"
   a) is stored in a variable · **b) is spliced into a string a shell
   re-parses and runs** · c) is logged
2. source `bash L4.2` — "Before piping a `curl | bash` installer, the safe move
   is to…" a) run it in a VM · **b) download and read the script first — never
   pipe unread text straight into a shell** · c) check the domain's TLS cert
3. source `bash L4.3` — "A `--` before positional arguments exists to…" a)
   improve readability · **b) mark the end of options, so a value starting
   with `-` can't be parsed as a flag** · c) escape spaces
4. source `bash L4.4` — "A writable or relative entry early in `PATH` is
   dangerous because…" a) it slows lookups · **b) an attacker can drop a
   same-named binary there and have it run instead of the real one** · c) it
   breaks tab-completion
5. source `bash L4.7` — "The fix for a TOCTOU race in temp-file handling is…"
   a) re-check the file exists right before using it · **b) create the file
   atomically with `mktemp` and never check-then-use a predictable path** · c)
   use a longer random name

---

### L5.2 — `sed` at reading level — substitution and the patterns you'll actually meet
**DECODE · gate:false · est 12 · files/: `access.log`, `redact.sh` · recall.json: no**
**objective:** "Read a two-stage `sed -E` script and name what each expression
does — the extended-regex flag, the global substitution flag, and how capture
groups reorder fields."

**(2) ARTIFACT** — `files/access.log` (same 8 lines as L5.1). `files/redact.sh`
(verified `shellcheck`-clean):
```bash
#!/usr/bin/env bash                                                        # 1
# REFERENCE SAMPLE — read, decode, and run for real.                       # 2
set -euo pipefail                                                          # 3
sed -E \                                                                   # 4  (1) -E: extended regex — ( ) { } + ? work unescaped
  -e 's/([0-9]{1,3}\.){3}[0-9]{1,3}/[IP-REDACTED]/g' \                     # 5  (2) global: mask every IPv4 address on the line
  -e 's/^\[IP-REDACTED\] - - \[([^]]+)\] "([A-Z]+) ([^ ]+) [^"]+" ([0-9]{3}) .*/ts=\1 method=\2 path=\3 status=\4/' \  # 6  (3) anchored + capture groups: reorder into key=value
  access.log                                                               # 7
```
Real captured output (`./redact.sh`):
```
ts=18/Jul/2026:10:12:01 +0000 method=GET path=/login status=200
ts=18/Jul/2026:10:12:03 +0000 method=GET path=/login status=401
ts=18/Jul/2026:10:12:05 +0000 method=POST path=/login status=401
ts=18/Jul/2026:10:12:07 +0000 method=GET path=/login status=401
ts=18/Jul/2026:10:12:09 +0000 method=GET path=/login status=401
ts=18/Jul/2026:10:12:11 +0000 method=GET path=/dashboard status=200
ts=18/Jul/2026:10:12:13 +0000 method=GET path=/login status=401
ts=18/Jul/2026:10:12:15 +0000 method=GET path=/dashboard status=200
```

**(3) EXECUTION NOTE:** safe to run for real; `check.sh` re-runs it.

**(4) CHECK LOGIC** (comprehension `answers.txt`):
```
dash_e=extended
flag_g=global
purpose5=(mask|redact)
purpose6=reorder
backslash1=capture
```
- `assert_file_contains "answers.txt" '^dash_e=extended$'`
- `assert_file_contains "answers.txt" '^flag_g=global$'`
- `assert_file_contains "answers.txt" '^purpose5=(mask|redact)$'`
- `assert_file_contains "answers.txt" '^purpose6=reorder$'`
- `assert_file_contains "answers.txt" '^backslash1=capture$'`
- `assert_cmd_ok "redact.sh runs clean" "…" -- bash -- redact.sh`
- `assert_output_contains "redacted output shows the reordered fields" 'ts=18/Jul/2026:10:12:01' "…" -- bash -- redact.sh`
- `ck_summary`

**(5) QUIZ + RECAP:**
- Q1: "`sed -E` switches to…" a) silent mode · **b) extended regex, so `( )`,
  `{ }`, `+`, `?` work unescaped** · c) in-place editing → `Yg==`
- Q2: "The trailing `g` in `s/pat/repl/g` means…" a) global across the whole
  file at once · **b) replace every match on the line, not just the first** ·
  c) case-insensitive → `Yg==`
- Q3: "`\1` in the replacement text refers to…" a) line 1 · **b) whatever the
  first `( )` capture group matched** · c) the first word → `Yg==`
- Recap:
  1. `sed reads one line at a time and applies each -e expression in order — think of it as a small pipeline of substitutions, not one big rule.`
  2. `-E turns on extended regex (unescaped ( ) { } + ?), and a trailing /g on s/// applies the substitution to every match on the line, not just the first.`
  3. `Capture groups — ( ) in the pattern, \1 \2 … in the replacement — are how sed reorders or relabels fields instead of only deleting or masking them.`

---

### L5.3 — `awk` at reading level — the tool that looks like magic, demystified
**PREDICT · gate:false · est 15 · files/: `alerts.csv` · recall.json: no**
**objective:** "Predict the exact output of three `awk` one-liners over a CSV
before running them, using field-splitting, an accumulating array, and a
conditional pattern."

**(2) ARTIFACT** — `files/alerts.csv`:
```
timestamp,severity,host
2026-07-18T10:00:00Z,high,host-a.test
2026-07-18T10:05:00Z,low,host-b.test
2026-07-18T10:07:00Z,high,host-a.test
2026-07-18T10:09:00Z,medium,host-c.test
2026-07-18T10:11:00Z,high,host-b.test
2026-07-18T10:15:00Z,low,host-a.test
```
Three commands the learner predicts, in order (no wrapper script — PREDICT
labs present raw commands to run interactively, matching L1.x/L3.6):

1. `awk -F',' 'NR>1 {count[$2]++} END {for (s in count) print s, count[s]}' alerts.csv | sort`
2. `awk -F',' '$2=="high" {print $1, $3}' alerts.csv`
3. `awk -F',' 'NR==1 {print NF, "fields:", $0}' alerts.csv`

Real captured output (all three run for real this session):
```
$ awk -F',' 'NR>1 {count[$2]++} END {for (s in count) print s, count[s]}' alerts.csv | sort
high 3
low 2
medium 1

$ awk -F',' '$2=="high" {print $1, $3}' alerts.csv
2026-07-18T10:00:00Z host-a.test
2026-07-18T10:07:00Z host-a.test
2026-07-18T10:11:00Z host-b.test

$ awk -F',' 'NR==1 {print NF, "fields:", $0}' alerts.csv
3 fields: timestamp,severity,host
```
(Command 1 pipes through `sort` deliberately — `awk`'s associative-array
iteration order is unspecified, so the lab pins a deterministic order rather
than asking the learner to predict an implementation-defined ordering.)

**(3) EXECUTION NOTE:** the learner **predicts before running** (the PREDICT
contract) — writes `predictions.txt`, then runs the three commands for real to
self-check, then submits. `check.sh` grades `predictions.txt` against the fixed
real values above (the shipped `alerts.csv` never changes) and separately
re-runs command 1 for real as a tamper check.

**(4) CHECK LOGIC** (`predictions.txt`):
```
predict1_line1=high 3
predict1_line2=low 2
predict1_line3=medium 1
predict2_line1=2026-07-18T10:00:00Z host-a.test
predict2_line2=2026-07-18T10:07:00Z host-a.test
predict2_line3=2026-07-18T10:11:00Z host-b.test
predict3=3 fields: timestamp,severity,host
```
- `assert_file_contains "predictions.txt" '^predict1_line1=high 3$'`
- `assert_file_contains "predictions.txt" '^predict1_line2=low 2$'`
- `assert_file_contains "predictions.txt" '^predict1_line3=medium 1$'`
- `assert_file_contains "predictions.txt" '^predict2_line1=2026-07-18T10:00:00Z host-a\.test$'`
- `assert_file_contains "predictions.txt" '^predict2_line2=2026-07-18T10:07:00Z host-a\.test$'`
- `assert_file_contains "predictions.txt" '^predict2_line3=2026-07-18T10:11:00Z host-b\.test$'`
- `assert_file_contains "predictions.txt" '^predict3=3 fields: timestamp,severity,host$'`
- Re-verification avoids `bash -c` (lint-banned) via a tiny checked-in
  `files/verify1.sh` wrapper, mode 755 (`awk -F',' 'NR>1{count[$2]++} END{for
  (s in count) print s, count[s]}' alerts.csv | sort`):
  `assert_cmd_ok "verify1.sh runs clean" "…" -- bash -- verify1.sh`
- `assert_output_contains "command 1 reproduces the predicted counts" 'high 3' "…" -- bash -- verify1.sh`
- `ck_summary`

**(5) QUIZ + RECAP:**
- Q1: "In `awk`, `-F','` sets…" a) the output separator · **b) the input field
  separator, so `$1 $2 …` split on commas** · c) a filter pattern → `Yg==`
- Q2: "`NR` inside an `awk` program is…" a) the number of fields in the current
  line · **b) the current input record (line) number, running across the
  file** · c) a user-defined variable → `Yg==`
- Q3: "An `awk` program's `END { }` block runs…" a) once per line, last ·
  **b) exactly once, after all input has been read** · c) only if no pattern
  matched → `Yg==`
- Recap:
  1. `awk sees the world as records (lines) split into fields ($1, $2, … and $0 for the whole line) — -F sets what character splits them.`
  2. `pattern { action } pairs run the action on every line matching the pattern; a bare condition with no action defaults to "print the line."`
  3. `BEGIN {} runs once before any input, END {} runs once after all input — everything else runs once per line, which is why a running total lives in an array touched every line and printed only in END.`

---

### L5.4 — `jq` — reading JSON pipelines (ECS / log territory)
**DECODE · gate:false · est 15 · files/: `events.jsonl`, `reshape-ecs.sh` · recall.json: no**
**objective:** "Read a `jq` object-construction filter that reshapes raw JSON
log lines into ECS-style dotted fields, and name what each part of the filter
does — compact output, literal dotted keys, and an inline conditional."

**(2) ARTIFACT** — `files/events.jsonl`:
```
{"ts":"2026-07-18T10:00:00Z","src_ip":"203.0.113.7","user":"alice","action":"login_failed"}
{"ts":"2026-07-18T10:00:05Z","src_ip":"203.0.113.7","user":"alice","action":"login_failed"}
{"ts":"2026-07-18T10:00:10Z","src_ip":"198.51.100.23","user":"bob","action":"login_success"}
```
`files/reshape-ecs.sh` (verified `shellcheck`-clean, real `jq` version `jq-1.7`):
```bash
#!/usr/bin/env bash                                                         # 1
# REFERENCE SAMPLE — read, decode, and run for real.                        # 2
set -euo pipefail                                                           # 3
jq -c '{                                                                    # 4  (1) -c: one compact JSON object per line out
  "@timestamp":    .ts,                                                    # 5  (2) rename ts -> @timestamp (ECS convention)
  "source.ip":     .src_ip,                                                # 6  (3) literal dotted key, NOT a nested path — ECS field naming
  "user.name":     .user,                                                  # 7
  "event.action":  .action,                                                # 8
  "event.outcome": (if (.action | test("failed")) then "failure" else "success" end)  # 9  (4) derived field via inline conditional + regex test
}' events.jsonl                                                            # 10
```
Real captured output (`./reshape-ecs.sh`):
```
{"@timestamp":"2026-07-18T10:00:00Z","source.ip":"203.0.113.7","user.name":"alice","event.action":"login_failed","event.outcome":"failure"}
{"@timestamp":"2026-07-18T10:00:05Z","source.ip":"203.0.113.7","user.name":"alice","event.action":"login_failed","event.outcome":"failure"}
{"@timestamp":"2026-07-18T10:00:10Z","source.ip":"198.51.100.23","user.name":"bob","event.action":"login_success","event.outcome":"success"}
```

**(3) EXECUTION NOTE:** safe to run for real; `check.sh` re-runs it.

**(4) CHECK LOGIC** (comprehension `answers.txt`):
```
flag_c=compact
key_style=literal
line9=derived
test_fn=regex
```
- `assert_file_contains "answers.txt" '^flag_c=compact$'`
- `assert_file_contains "answers.txt" '^key_style=literal$'`
- `assert_file_contains "answers.txt" '^line9=derived$'`
- `assert_file_contains "answers.txt" '^test_fn=regex$'`
- `assert_cmd_ok "reshape-ecs.sh runs clean" "…" -- bash -- reshape-ecs.sh`
- `assert_output_contains "alice's two failed logins reshape correctly" '"event.outcome":"failure"' "…" -- bash -- reshape-ecs.sh`
- `assert_output_contains "bob's success reshapes correctly" '"event.outcome":"success"' "…" -- bash -- reshape-ecs.sh`
- `ck_summary`

**(5) QUIZ + RECAP:**
- Q1: "`jq -c` prints each JSON object…" a) pretty-printed across many lines ·
  **b) compact, one object per line — the natural shape for piping to other
  line-oriented tools** · c) as a single array → `Yg==`
- Q2: "In `{"source.ip": .src_ip}`, `"source.ip"` is…" **a) a literal string
  key containing a dot — not a nested path** · b) shorthand for `.source.ip` ·
  c) a jq type annotation → `YQ==`
- Q3: "`if (.action | test("failed")) then … end` inside a jq filter…" a) is
  invalid syntax · **b) branches on a regex match against the piped-in value,
  producing a derived field** · c) filters out non-matching records → `Yg==`
- Recap:
  1. `jq filters transform one JSON value into another; -c prints each result compact (one line), the natural shape for streaming NDJSON logs.`
  2. `Object-construction keys are just strings — "source.ip" is one literal key with a dot in its name, which is exactly how flat schemas like ECS represent what looks like nesting.`
  3. `jq has real control flow (if/then/else, functions like test()) usable inline inside a filter — a reshape pipeline is a small program, not just field selection.`

---

### L5.5 — Process substitution `<(...)`, here-docs, and here-strings
**DECODE · gate:false · est 12 · files/: `allowed.txt`, `seen.txt`, `compare-hosts.sh` · recall.json: no**
**objective:** "Read a script using all three input-without-a-temp-file
constructs — process substitution, a here-string, and a heredoc — and name
what each one is for."

**(2) ARTIFACT** — `files/allowed.txt`:
```
host-a.test
host-b.test
host-c.test
```
`files/seen.txt`:
```
host-b.test
host-a.test
host-x.test
```
`files/compare-hosts.sh` (verified `shellcheck`-clean):
```bash
#!/usr/bin/env bash                                                  # 1
# REFERENCE SAMPLE — read, decode, and run for real.                  # 2
set -euo pipefail                                                     # 3
new_hosts=$(diff <(sort allowed.txt) <(sort seen.txt) \               # 4  (1) process substitution: two command outputs read as if they were files
  | grep '^>' | cut -d' ' -f2 || true)                                # 5  ("|| true" — diff exits 1 on real differences, not an error; guards set -e)

last_event="login_failed host-x.test"                                 # 7
if grep -q 'failed' <<< "$last_event"; then                           # 8  (2) here-string: feed one variable's value to stdin, no echo | or temp file
  verdict=flagged                                                     # 9
else                                                                   # 10
  verdict=clear                                                       # 11
fi                                                                     # 12

cat <<REPORT                                                          # 14  (3) heredoc: inline multi-line text; $vars still expand (unquoted delimiter)
=== Host Check ===
new hosts seen:  ${new_hosts:-none}
last event:      $last_event
verdict:         $verdict
REPORT                                                                # 19
```
Real captured output (`./compare-hosts.sh`):
```
=== Host Check ===
new hosts seen:  host-x.test
last event:      login_failed host-x.test
verdict:         flagged
```

**(3) EXECUTION NOTE:** safe to run for real; `check.sh` re-runs it. The `||
true` on line 5 is itself worth one guided-step callout — `diff` returns
nonzero when it finds a difference (that's not a failure), and under `set -e`
an unguarded `$(diff … | …)` would abort the script before it ever reaches the
heredoc. Same silent-failure family as Phase 2's `set -euo pipefail` lesson,
resurfacing here.

**(4) CHECK LOGIC** (comprehension `answers.txt`):
```
construct4=procsub
construct8=herestring
construct14=heredoc
expands=yes
```
- `assert_file_contains "answers.txt" '^construct4=procsub$'`
- `assert_file_contains "answers.txt" '^construct8=herestring$'`
- `assert_file_contains "answers.txt" '^construct14=heredoc$'`
- `assert_file_contains "answers.txt" '^expands=yes$'`
- `assert_cmd_ok "compare-hosts.sh runs clean" "…" -- bash -- compare-hosts.sh`
- `assert_output_contains "flags the unexpected host" 'host-x\.test' "…" -- bash -- compare-hosts.sh`
- `ck_summary`

**(5) QUIZ + RECAP:**
- Q1: "`diff <(sort a.txt) <(sort b.txt)` avoids…" a) reading the files twice ·
  **b) creating temp files just to diff two command outputs — each `<(...)`
  acts like a filename** · c) sorting errors → `Yg==`
- Q2: "A here-string (`cmd <<< "$var"`) is best for…" **a) feeding one
  variable's value to a command's stdin without `echo | cmd` or a temp file** ·
  b) reading multiple files at once · c) suppressing output → `YQ==`
- Q3: "Inside an unquoted heredoc (`<<EOF`), `$variables`…" **a) still expand,
  exactly like double quotes** · b) are printed literally · c) cause a syntax
  error → `YQ==`
- Recap:
  1. `Process substitution <(cmd) makes a command's output look like a filename to whatever reads it — the classic use is diff <(cmd1) <(cmd2), comparing two live outputs with no temp files.`
  2. `A here-string (<<< "$var") is the shortest way to feed one already-in-memory value to a command's stdin — no echo | pipe, no temp file.`
  3. `A heredoc (<<EOF … EOF) is multi-line stdin written inline; it expands $variables and $(command) like double quotes, unless the opening delimiter is quoted (<<'EOF'), which makes it fully literal.`

---

### L5.6 — Phase gate: decode a real log-processing pipeline top to bottom
**DECODE · gate:true · est 20 · files/: `access.log`, `allowed-ips.txt`, `triage-summary.sh` · recall.json: no**
**objective:** "Decode a realistic triage script that chains every Phase 5
construct — grep/cut/sort/uniq, awk, sed via a here-string, jq, process
substitution, and a heredoc report — stage by stage, and report the concrete
values it computes."

**(2) ARTIFACT** — `files/access.log` (same 8 lines as L5.1). `files/allowed-ips.txt`:
```
192.0.2.15
198.51.100.23
```
`files/triage-summary.sh` (verified `shellcheck`-clean — every construct from
L5.1–L5.5 appears at least once):
```bash
#!/usr/bin/env bash                                                      # 1
# REFERENCE SAMPLE — read, decode, and run for real.                     # 2
set -euo pipefail                                                        # 3
LOG=access.log                                                           # 4
ALLOWLIST=allowed-ips.txt                                                # 5
                                                                          # 6 (blank)
top_offender=$(grep ' 401 ' "$LOG" | cut -d' ' -f1 | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')     # 7  grep/cut/sort/uniq (L5.1) + awk (L5.3) pulls just the IP
offender_count=$(grep ' 401 ' "$LOG" | cut -d' ' -f1 | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')   # 8  same pipeline, awk pulls the count instead
                                                                          # 9 (blank)
if grep -qxF "$top_offender" "$ALLOWLIST"; then                          # 10  if-block spans lines 10-14
  status=known                                                           # 11
else                                                                     # 12
  status=unknown                                                        # 13
fi                                                                        # 14
                                                                          # 15 (blank)
new_ips=$(diff <(cut -d' ' -f1 "$LOG" | sort -u) <(sort "$ALLOWLIST") | grep '^<' | cut -d' ' -f2 || true)  # 16  process substitution (L5.5)
                                                                          # 17 (blank)
redacted=$(sed -E 's/[0-9]+$/xxx/' <<< "$top_offender")                  # 18  sed + here-string (L5.2 + L5.5)
                                                                          # 19 (blank)
jq -n --arg ip "$top_offender" --arg cnt "$offender_count" --arg status "$status" \    # 20  jq (L5.4), built from bash vars via --arg
  '{"source.ip": $ip, "event.count": ($cnt|tonumber), "ip.known": $status}'            # 21
                                                                          # 22 (blank)
cat <<REPORT                                                             # 23  heredoc report (L5.5)
=== Triage Summary ===
top offender:   $redacted ($status)
failed logins:  $offender_count
new IPs seen:   $(printf '%s\n' "$new_ips" | grep -c .)
REPORT                                                                    # 28
```
Line numbers above were read directly off a real `cat -n` of the script this
session (not estimated) — the trailing `# N` annotations exist purely for
plan-to-build cross-reference and are not part of the shipped file's own
inline comments. **[VERIFY-AT-BUILD]:** re-confirm against the shipped file
once it's copied into its final `files/` location, same discipline as every
prior phase.

Real captured output (`./triage-summary.sh`):
```
{
  "source.ip": "203.0.113.7",
  "event.count": 4,
  "ip.known": "unknown"
}
=== Triage Summary ===
top offender:   203.0.113.xxx (unknown)
failed logins:  4
new IPs seen:   1
```

**(3) EXECUTION NOTE:** safe to run for real; `check.sh` re-runs it.

**(4) CHECK LOGIC** (comprehension + concrete-value `answers.txt`):
```
stage_grep=filter
stage_awk=field
stage_diff=procsub
stage_sed=herestring
stage_jq=reshape
stage_heredoc=report
top_ip=203.0.113.7
top_count=4
ip_status=unknown
new_count=1
```
- `assert_file_contains "answers.txt" '^stage_grep=filter$'`
- `assert_file_contains "answers.txt" '^stage_awk=field$'`
- `assert_file_contains "answers.txt" '^stage_diff=procsub$'`
- `assert_file_contains "answers.txt" '^stage_sed=herestring$'`
- `assert_file_contains "answers.txt" '^stage_jq=reshape$'`
- `assert_file_contains "answers.txt" '^stage_heredoc=report$'`
- `assert_file_contains "answers.txt" '^top_ip=203\.0\.113\.7$'`
- `assert_file_contains "answers.txt" '^top_count=4$'`
- `assert_file_contains "answers.txt" '^ip_status=unknown$'`
- `assert_file_contains "answers.txt" '^new_count=1$'`
- `assert_cmd_ok "triage-summary.sh runs clean" "…" -- bash -- triage-summary.sh`
- `assert_output_contains "reports the correct top offender and status" '203\.0\.113\.xxx \(unknown\)' "…" -- bash -- triage-summary.sh`
- `ck_summary`

**(5) QUIZ + RECAP:**
- Q1: "`top_offender=$(… | awk '{print $2}')` at the end of that pipeline
  exists because…" a) awk sorts the input · **b) `uniq -c` prints `"  count
  ip"`, and awk pulls out just the second field (the IP) after ranking is
  done** · c) awk is faster than cut here → `Yg==`
- Q2: "`diff <(cut … | sort -u) <(sort "$ALLOWLIST")` finds new IPs by…" a)
  checking each IP against a regex · **b) comparing two sorted, deduplicated
  lists and reporting lines that appear on only one side** · c) hashing every
  IP → `Yg==`
- Q3: "The final `cat <<REPORT … REPORT` block is…" a) reading a report file
  from disk · b) a jq template · **c) a heredoc — inline multi-line text with
  `$variables` expanded, printed to stdout** → `Yw==`
- Recap:
  1. `A real triage script is Phase 5's tools chained end to end — grep filters, cut/awk extract fields, sort/uniq rank, sed via a here-string reshapes a single value, jq emits structured output, a heredoc renders the human report.`
  2. `Read a long pipeline the same way regardless of length: find where each variable is assigned, trace what pipeline computed it, then follow how it's used downstream — one assignment at a time, not the whole script at once.`
  3. `diff exits nonzero when it finds differences (not an error) — under set -euo pipefail a bare $(diff … | …) can abort the script unless guarded with || true, the same silent-failure lesson from Phase 2 resurfacing in Phase 5's tooling.`

---

## Build-session protocol (execute in this order — gate at each lab per CLAUDE.md)

1. **Scaffold** `tracks/bash/phases/p5/` with the 6 lab dirs (slugs in the
   table above). No `track.json` edit needed — `"p5": "Text Processing &
   Pipelines"` is already registered.
2. **No containment step.** Unlike Phase 3/4, there is no fence to ship first —
   go straight to authoring L5.1.
3. **Author content straight from the entries above.** Every reference script
   gets the `# REFERENCE SAMPLE — read, decode, and run for real.` banner on
   **line 2**, mode **755**. Base64 every quiz/recall answer (`printf '%s' 'b'
   | base64 -w0`). Ship `recall.json` in L5.1 only.
4. **Self-test sweep (no-fiction rule).** Execute every `lab.md` command
   yourself in the real workspace and paste the **real** captured output —
   this plan's captured output was produced against a scratch sandbox, not the
   final workspace path, so re-capture once files are copied into
   `workspace/bash/L5.N/` by `lab start`. Run `check.sh` twice per lab: an
   incomplete/wrong `answers.txt`/`predictions.txt` → **FAIL** with a useful
   hint; the correct artifact → **PASS**. **[VERIFY-AT-BUILD]** re-confirm
   every asserted line number against the shipped file.
5. **Lint + shellcheck gate.** Run `tools/lint-labs.sh` (644 mode, preamble/
   guards, no banned tokens, no absolute paths; quiz=3, hints=3, meta fields)
   then `tools/shellcheck-all.sh`. Every reference script in this plan already
   passed a real `shellcheck` run this session — re-run after the files are in
   their final repo location to catch any transcription error.
6. **Extend `tests/acceptance.sh`** with a P5 block mirroring the P4 block: per
   lab, `lab start` → assert FAIL before the artifact exists → fabricate the
   correct `answers.txt`/`predictions.txt` via heredocs → assert PASS. Exercise
   L5.1's opener recall (assert it never gates). **[VERIFY-AT-BUILD]** bump
   catalog counts `(36/36)`→`(42/42)` and any "P0–P4 = 36" style comments.
7. **Stop-and-review after each lab** (CLAUDE.md multi-phase gating). Do not
   chain all 6 labs unattended; surface what changed per lab and wait for
   go-ahead. Commit/push and the `planned_execution.md` `[x]`/tag update happen
   only under this repo's Pull→Branch→Work→Commit→Push→PR→Merge loop, not in
   this plan session.

---

## Verification (how to confirm the built phase is correct)

- **Structural:** `tools/lint-labs.sh` and `tools/shellcheck-all.sh` exit
  clean, now covering 6 new reference scripts that (unlike Phase 3/4) *are*
  swept by `shellcheck-all.sh` since they're real, correct, executable code.
- **Per-lab behavioral:** for each L5.N, `lab start bash L5.N`, then `lab check
  bash L5.N` with (a) missing/incorrect artifact → `RESULT: FAIL` naming the
  missing piece, (b) correct artifact → `RESULT: PASS`.
- **Real-execution proof:** unlike Phase 3/4's "never-executed" proof, Phase 5
  confirms the opposite — grep the 6 `check.sh` files to confirm each one
  (except L5.3, PREDICT) actually invokes its shipped reference script via
  `assert_cmd_ok`/`assert_output_contains` and that the live output matches
  the values recorded in this plan.
- **End-to-end:** `tests/acceptance.sh` passes with the P5 block and shows the
  bash catalog at `(42/42)`.
- **Fictional-data audit:** confirm every hostname/IP in every sample is RFC
  2606 / RFC 5737 fictional.

---

## Open items to confirm at build (not blockers)

- `tracks/bash/track.json` already lists p5 — no registration change expected,
  but confirm at build in case the file shape changed since this plan was
  written.
- L5.3's `files/verify1.sh` wrapper (item 4 of its CHECK LOGIC) is a new
  pattern — a tiny checked-in re-run script used only so `check.sh` never
  needs `bash -c` (lint-banned) to re-verify a PREDICT answer. Confirm
  `tools/lint-labs.sh` has no objection to a `files/*.sh` being invoked from
  `check.sh` (Phase 3/4 never did this, since their `files/` scripts were
  never meant to run); if it does, fall back to grading `predictions.txt`
  alone with no live re-verification for L5.3.
- Whether `est_minutes` totals need to appear anywhere beyond each
  `meta.json` — assume per-lab only, consistent with Phase 3/4.
