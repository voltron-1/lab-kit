# LAB-KIT — Execution Prompt Pack v1.0

Prompts for building all three training tracks (Rust Literacy, Bash Literacy, SOC Analyst) with Claude Code on Dragon-Zord. Three prompts: **Bootstrap** (run once), **Phase Builder** (run once per phase), **Resume** (run any time a session dies).

---

## Setup (one time, ~2 minutes)

```bash
mkdir -p ~/projects/lab-kit/docs/curriculum && cd ~/projects/lab-kit
git init
```

Drop these four files in:

- `docs/curriculum/rust-literacy-lab-curriculum-v1.md`
- `docs/curriculum/bash-literacy-lab-curriculum-v1.md`
- `docs/curriculum/soc-analyst-lab-curriculum-v1.md`
- `PROMPTS.md` ← this file

Then start Claude Code in the repo and paste **Prompt 1**. Per your routing convention: run the planning/approval steps on your planning model, flip to Sonnet for the execution passes.

---

## PROMPT 1 — Bootstrap (run once)

```text
You are building LAB-KIT: a monorepo containing three terminal-based training
tracks — rust, bash, and soc — defined by three curriculum maps in
docs/curriculum/. Those maps are the BINDING SPEC. Read all three completely
before writing anything. Where this prompt and a map conflict, the map wins.

MISSION FOR THIS SESSION (bootstrap only — no track content yet):
1. Read all three curriculum maps end to end.
2. Enter plan mode. Propose the repo structure and the shared `lab` CLI design.
   Wait for my explicit approval before writing any code.
3. Build the shared `lab` CLI and check harness.
4. Build ONE demo lab (track: demo, id: L0.0) that exercises every mechanic.
5. Create planned_execution.md listing every phase of every track as an
   execution checklist (rust p0–p7, bash p0–p7, soc p0–p7), all unstarted.
6. Commit with clean history. Then STOP and report.

CLI REQUIREMENTS (from the maps — these are contracts, not suggestions):
- Pure bash + jq. Must pass shellcheck with zero warnings. Target: Ubuntu
  24.04 on WSL2.
- Commands:
    lab status                  # all tracks, phase map, ✓ / ○ / ⏭ per lab
    lab start <track> <id>      # e.g. lab start rust L1.3
    lab check <track> <id>      # grade: check.sh + interactive quiz
    lab resume                  # last completed lab + its recap card + next
                                # lab + one-line brief. Target: re-primed in
                                # under 30 seconds of reading.
    lab hint <track> <id>       # graduated: 3 levels, one per invocation
- Progression is linear within a track: `lab start` refuses labs past the
  next unlocked one. Provide --force as an escape hatch; status marks
  forced/skipped labs ⏭, never ✓.
- State lives in .progress.json (gitignored). Writes are atomic
  (temp file + mv). Ctrl-C at ANY moment must never corrupt state.

LAB CONTENT LAYOUT (every lab, every track):
  tracks/<track>/phases/p<N>/<id>-<slug>/
    meta.json     # title, type, objective, gate:true|false, est_minutes
    lab.md        # BRIEF (≤10 lines) + GUIDED STEPS with expected output
    quiz.json     # 3 questions + answers (base64 the answers so casual
                  # file browsing doesn't spoil)
    check.sh      # the grader; sources shared harness helpers
    hints.json    # exactly 3 levels, escalating, never the answer at L1
    recap.md      # 3-line recap card written to progress log on pass
    files/        # optional starter/evidence files copied to workspace
    recall.json   # phase-opener labs only: 5 spaced-recall questions
                  # drawn from EARLIER phases

SANDBOX CONTAINMENT (non-negotiable safety rule):
- `lab start` provisions workspace/<track>/<id>/ (gitignored) and copies
  files/ into it. All lab commands and all check.sh logic operate ONLY
  inside that workspace. No lab, hint, or check may read or write outside
  it. This will matter enormously for the bash track's destructive-command
  labs later — build the fence now.

BOOTSTRAP ACCEPTANCE CHECKLIST (verify each item yourself before reporting):
[ ] shellcheck clean across bin/ and harness
[ ] demo lab: start → check with wrong answers (fails, useful message) →
    check with right answers (passes) → status shows ✓ → resume replays
    the recap card correctly
[ ] kill -INT mid-check, then lab status — state intact
[ ] hint ladder: three invocations, three escalating hints, then a clean
    "no more hints" message
[ ] README.md: clone-to-first-lab in ≤5 commands
[ ] planned_execution.md exists with all 24 phase lines, all unstarted

STOP CONDITION: bootstrap complete + checklist green + committed. Do not
begin any track phase. Report what was built and wait.
```

---

## PROMPT 2 — Phase Builder (template — run once per phase)

Fill the two variables on the first line. First run for each track must be `PHASE: 0+1` (the maps bundle them).

```text
TRACK: <rust | bash | soc>     PHASE: <0+1 | 2 | 3 | 4 | 5 | 6 | 7>

You are continuing LAB-KIT. Binding spec: docs/curriculum/ map for this
track. Protocol for this session:

1. ORIENT. Open planned_execution.md. Confirm the target phase is the next
   unstarted phase for this track. If it isn't, stop and tell me.
2. RE-READ the curriculum map's section for this phase. The lab list is
   binding: titles, types, count, gate placement. If you believe any lab
   should change, propose the deviation and WAIT for approval — never
   silently deviate.
3. PLAN. For each lab, one line: the concrete content (what code sample /
   what evidence / what the check grades). Present the whole phase plan.
   WAIT for my approval before building.
4. BUILD lab by lab. After each lab passes its own self-test, commit it
   individually: "<track> <id>: <title>".
5. SELF-TEST EVERY LAB — the no-fiction rule:
   - Execute every command in lab.md yourself and paste the REAL captured
     output into the doc. Never write expected output from memory.
   - Run check.sh twice: once simulating wrong/incomplete work (must fail
     with a message that tells the learner what to look at), once
     simulating correct work (must pass).
   - Time-budget sanity: if the guided steps exceed ~15 commands or the
     lab.md exceeds ~180 lines, split or trim. Atomic means atomic.
6. PHASE GATE: the last lab must integrate the phase per the map, and its
   recall.json (next phase's opener) gets drafted now while context is hot.
7. CLOSE OUT: update planned_execution.md, tag <track>-p<N>, report against
   the acceptance checklist, STOP. One phase per session — hard rule.

TRACK-SPECIFIC QUALITY GATES:

If TRACK = rust:
- Pin the toolchain: rust-toolchain.toml at repo root; record rustc
  version in the track README. PREDICT and FIX labs depend on exact
  compiler behavior.
- Every code sample must be run: it compiles and behaves exactly as
  lab.md claims, or it fails with EXACTLY the error the lab teaches
  (error codes like E0382 verified against real rustc output, pasted in).
- Samples live in files/ as cargo projects; check.sh uses cargo output.

If TRACK = bash:
- Everything you write (harness, checks, correct examples) is
  shellcheck-clean. Deliberately-broken teaching samples carry a
  "# TEACHING SAMPLE — intentionally flawed" header and their expected
  SC codes listed in meta.json.
- Destructive-command labs (the rm -rf empty-var lab, IFS attacks,
  filename attacks) run against a DECOY TREE generated inside the
  workspace sandbox, and/or a shadowed function that logs instead of
  destroys. Prove containment in the self-test: run the footgun,
  verify nothing outside the workspace changed.
- Every "dangerous" sample must be demonstrably dangerous INSIDE the
  fence — the learner must see the damage happen to the decoy.

If TRACK = soc:
- Evidence is GENERATED, not hand-written. Build tools/genevidence/:
  each scenario is a scenario.yaml (actors, hosts, IPs, timeline,
  attacker actions) and the generator emits BOTH the evidence files
  (logs / pcap / eml / alert JSON) AND the answer key from that single
  source of truth. Keys can never drift from evidence.
- Consistency check in CI-style script: every timestamp inside the
  scenario window, every IP/host consistent across zeek + pcap +
  alerts, every answer-key event ID present in the evidence.
- PCAPs via scapy; keep them small and synthetic. .eml files carry
  full realistic headers. Nothing live-hostile: hashes, detonation
  reports, and reputation lookups are mocked artifacts in files/.
- Prose defangs every IOC (hxxp, [.]); raw evidence files do NOT
  defang (evidence must look real). check.sh for REPORT labs enforces
  defanging in the learner's submission.
- VERIFY labs (phase 7): the planted AI-summary flaws are specified in
  scenario.yaml too — including at least one claim citing a
  nonexistent event ID.

PHASE ACCEPTANCE CHECKLIST (report each item):
[ ] Lab count, titles, types match the map (or approved deviation noted)
[ ] Every lab self-tested: real outputs pasted, fail path + pass path run
[ ] shellcheck clean (all tracks — the checks themselves are bash)
[ ] Gate lab present and integrative; recall.json drafted for next phase
[ ] lab status renders the phase correctly; resume works mid-phase
[ ] planned_execution.md updated; phase tagged
```

---

## PROMPT 3 — Resume (paste after any interruption)

```text
LAB-KIT session recovery. Open planned_execution.md and .git log. Report:
current track, current phase, last completed item, next unstarted item.
If a lab was mid-build, show its state and finish its self-test before
anything else. Then continue under the Phase Builder protocol in
PROMPTS.md. One phase per session maximum. Plan-and-approve rules still
apply.
```

---

## Suggested build order

1. **Bootstrap** (Prompt 1) — one session, gives you the working CLI and demo lab
2. **bash 0+1** — you use Bash daily, so wins land immediately, and building it first battle-tests the sandbox fence the other tracks rely on
3. **rust 0+1**, then **soc 0+1** — all three tracks open; from there, alternate phases by mood (the kit doesn't care, that's the point)

Optional: after each SOC phase and bash Phase 3/4, one pass with your security-auditor sub-agent over the evidence generators and footgun labs — cheap insurance that the teaching-danger stays fenced.

---

*v1.0 — pairs with the three curriculum maps. The maps stay the spec; this file is just the engine that builds them.*
