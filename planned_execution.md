# LAB-KIT — Planned Execution

## NEXT UP
Phase: bash p3 — The Footgun Gallery, BUILD session in progress (Phase
Builder protocol, PROMPTS.md Prompt 2, TRACK: bash PHASE: 3, BUILD).
2 of 9 labs built and committed (L3.1 `c25da72`, L3.2 `4535599`). Next
unstarted item: **L3.3 — `IFS`** (DECODE) — what it controls and how
changing it breaks (or attacks) a script (docs/plans/bash-p3-plan.md
§6 L3.3). One lab per session (gated); wait for go-ahead before each.
Containment (decoy tree + the shadowed-rm fence) is designed, approved,
and now proven twice — at plan time in an isolated scratchpad, and for
real in-repo during L3.2's build (`ls / | wc -l`: 28 before/after the
fenced flawed-script run) — so remaining labs execute it rather than
re-deriving or re-proving it from scratch.

## LAST SESSION
2026-07-16 — bash p3 BUILD, L3.2 (`rm -rf "$DIR/"` — the empty-variable
catastrophe, AUDIT): built check.sh/lab.md/meta.json/quiz.json/
hints.json/recap.md from the plan spec, self-tested end-to-end through
the real `lab` CLI (fail path 8/9 — missing `hardened.sh` correctly
blocked — then pass path 9/9 + quiz 3/3), committed `4535599`. Running
the guided demo for real (not just in a scratchpad) caught a real bug in
the draft lab.md — the guided steps had the learner reset `fence.log`
before testing the hardened script, which erased the evidence check.sh
needed from the earlier flawed-script demo and produced a false FAIL;
fixed by dropping the reset and reframing the proof as "the file doesn't
grow." Re-proved containment for real in this repo's workspace: fenced
`rm -rf /` intercepted, `fence.log` got `FENCE-BLOCKED: rm -rf /`, real
`/` entry count unchanged (28 → 28). `tools/lint-labs.sh` clean;
`tests/acceptance.sh` 128/131 — the 3 failures are pre-existing stale
counts from the L3.1 session (confirmed via `git stash` against HEAD
before this session), deferred to the phase's close-out step along with
extending acceptance.sh and re-tagging. L3.1 + L3.2 shipped via PR #1
(branch `bash-p3-l3.1-l3.2`, merge commit `c0ede9e`) — the repo's first
PR; branch deleted post-merge, back to direct-to-main for routine work.
Earlier, 2026-07-15 same-day: bash p3 PLAN session wrote and pushed the
Phase 3 build plan (docs/plans/bash-p3-plan.md, 1393 lines, commit
8796cb3) — all nine labs (L3.1–L3.9) fully specified, containment
designed and proved in an isolated scratchpad, SC-code sets flagged
[VERIFY-AT-BUILD]; then, later the same day, **L3.1** (word splitting,
TAME) was built, self-tested, and committed (`c25da72`) — this file's
refresh lagged that by a day and is now caught up.
Earlier the same week: bash p2 built, self-tested, and closed out (all
8 labs L2.1–L2.8 from docs/plans/bash-p2-plan.md, 8 individual commits,
tests/acceptance.sh at 131/131, `lab status` 19/19 ✓, tagged `bash-p2`);
bash p0+1 built and closed out (11 labs, tagged `bash-p0`/`bash-p1`);
and the p2/p0+1 build plans written and pushed. Full detail for those in
this file's history at commits 0e7e647, 6ec3a48, and 0db647e.

## BOOTSTRAP
- [x] Bootstrap: lab CLI, check harness, demo lab (L0.0), README,
      planned_execution.md — see git log (docs + feat + test commits,
      2026-07-12)

## TRACKS

### rust — Rust Literacy Lab (63 labs)
- [ ] rust p0 — Toolchain & Kit (3 labs)
- [ ] rust p1 — Reading Basic Rust (9 labs)
- [ ] rust p2 — Ownership, Borrowing, Lifetimes (10 labs)
- [ ] rust p3 — Types, Traits, Error Handling (10 labs)
- [ ] rust p4 — Security-Critical Rust (10 labs)
- [ ] rust p5 — Concurrency & Async (8 labs)
- [ ] rust p6 — Reading Real Security Tools (6 labs)
- [ ] rust p7 — Directing & Auditing AI Rust (7 labs)

### bash — Bash Literacy Lab (54 labs)
- [x] bash p0 — Toolchain & Kit (3 labs) — tag `bash-p0`; plan: `docs/plans/bash-p01-plan.md` (commit b61b60e)
- [x] bash p1 — The Expansion Model (8 labs) — tag `bash-p1`; plan: `docs/plans/bash-p01-plan.md` (commit b61b60e)
- [x] bash p2 — Control Flow & Silent Failure (8 labs) — tag `bash-p2`; plan: `docs/plans/bash-p2-plan.md` (commit b1a6512)
- [~] bash p3 — The Footgun Gallery (9 labs) — plan: `docs/plans/bash-p3-plan.md` (commit 8796cb3); containment proven (scratchpad + in-repo); 2/9 built — L3.1 word splitting, L3.2 empty-var rm -rf — merged via PR #1 (`c0ede9e`); next is L3.3 IFS
- [ ] bash p4 — Untrusted Input & Injection (8 labs)
- [ ] bash p5 — Text Processing & Pipelines (6 labs)
- [ ] bash p6 — Reading Real Deploy Scripts (5 labs)
- [ ] bash p7 — Directing & Auditing AI Bash (7 labs)

### soc — SOC Analyst Lab (52 labs)
- [ ] soc p0 — Toolbelt & Kit (3 labs)
- [ ] soc p1 — How Attacks Become Alerts (8 labs)
- [ ] soc p2 — Network Triage Fundamentals (7 labs)
- [ ] soc p3 — Endpoint Triage Fundamentals (7 labs)
- [ ] soc p4 — Triage Craft & the Queue (8 labs)
- [ ] soc p5 — Phishing & Malware Triage (6 labs)
- [ ] soc p6 — Investigation & Escalation (6 labs)
- [ ] soc p7 — The AI-Assisted Analyst (7 labs)

### ps — PowerShell Literacy Lab (54 labs)
- [ ] ps p0 — Toolchain & Kit (3 labs)
- [ ] ps p1 — The Object Pipeline (8 labs)
- [ ] ps p2 — Control Flow, Errors & Modules (7 labs)
- [ ] ps p3 — The Windows Integration Layer (8 labs)
- [ ] ps p4 — PowerShell as Attack Surface (9 labs)
- [ ] ps p5 — Deobfuscation & Malware Reading (7 labs)
- [ ] ps p6 — Reading Real Security Tools (5 labs)
- [ ] ps p7 — Directing & Auditing AI PowerShell (7 labs)

## DEFERRED
- (none)

---

Markers: `[ ]` todo · `[~]` in-progress · `[x]` done (link PR/tag/evidence) · `[!]` blocked.
Completion source of truth: git tags `<track>-p<N>` per the Phase Builder
protocol in `PROMPTS.md`; this file is the sequenced view derived from
them, never the other way around.
