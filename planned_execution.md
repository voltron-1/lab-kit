# LAB-KIT — Planned Execution

## NEXT UP
Phase: bash p3 — The Footgun Gallery. The p3 PLAN session is done — the
build plan is written and pushed (docs/plans/bash-p3-plan.md, commit
8796cb3; see LAST SESSION). Next unstarted item: bash p3's BUILD session
(Phase Builder protocol, PROMPTS.md Prompt 2, TRACK: bash PHASE: 3,
BUILD) — execute the plan lab by lab (L3.1–L3.9), self-test each with
real captured output (fail + pass paths), and re-prove containment in
the self-test before shipping any footgun lab. The containment design is
already decided and approved (see DEPENDENCY RESOLVED below), so the
build executes it rather than re-deriving it.

DEPENDENCY RESOLVED for bash p3 — The Footgun Gallery: the decoy-tree /
shadowed-destructive-command containment mechanism is now designed and
proved in the p3 plan (docs/plans/bash-p3-plan.md §3). Two mechanisms:
(A) the inherited make_decoy_tree / decoy_intact / decoy_changed helpers
(real, fenced decoy deletion for the word-splitting and filename-attack
labs), and (B) a NEW fail-closed shadowed-rm fence (files/fence.sh —
APPROVED 2026-07-15) for the labs whose footgun targets `/` itself (L3.2
empty-variable rm -rf, L3.7 eval, the L3.9 gate). Both were exercised at
plan time in an isolated scratchpad — empty-variable `rm -rf "$DIR/"`
(= `rm -rf /`) was intercepted and logged, real filesystem untouched.
The BUILD session ships fence.sh + run-fenced.sh and must re-prove
containment in its own self-test per PROMPTS.md's bash gate.

## LAST SESSION
2026-07-15 — bash p3 PLAN session: the Phase 3 (The Footgun Gallery)
build plan was written and pushed (docs/plans/bash-p3-plan.md, 1393
lines, commit 8796cb3). All nine labs (L3.1–L3.9) are fully specified —
exact vulnerable/hardened scripts, check.sh logic, quizzes, recaps —
plus the L3.1 phase-opener recall (5 questions, all sourced from and
validated against the Phase-2 recap cards on disk). Containment was
designed AND proved this session (see DEPENDENCY RESOLVED above): the
footgun behaviors and the NEW fail-closed shadowed-rm fence were
verified empirically in an isolated scratchpad (no repo / real-FS
writes), and the fence was approved. SC-code sets per teaching sample
were left [VERIFY-AT-BUILD] against the build machine's shellcheck
0.9.0. Plan only — no lab files built; this planned_execution.md refresh
was made afterward at my request (the plan session itself touched only
bash-p3-plan.md).
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
- [~] bash p3 — The Footgun Gallery (9 labs) — plan written & pushed (`docs/plans/bash-p3-plan.md`, commit 8796cb3); containment design approved (see DEPENDENCY RESOLVED); labs not yet built — next is the BUILD session
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
