# LAB-KIT — Planned Execution

## NEXT UP
Phase: bash p2 — Control Flow & Silent Failure. The p2 build plan is
done and pushed (docs/plans/bash-p2-plan.md, commit b1a6512). Next
unstarted item: build p2 lab-by-lab from that plan per the Phase Builder
protocol (PROMPTS.md Prompt 2, TRACK: bash PHASE: 2) — the plan carries
all design judgment; the build session executes it mechanically.

DEPENDENCY FLAGGED for whichever bash phase ships the first destructive
command (per the map, bash p3 — The Footgun Gallery): the decoy-tree /
shadowed-destructive-command containment mechanism was deliberately
NOT built in p0+1 (harness/checklib.sh already ships make_decoy_tree,
decoy_intact, decoy_changed as forward-compatible primitives, but no
lab exercises them yet). p3's build session must design and prove the
containment story before its first footgun lab, not rediscover the
requirement mid-build — see PROMPTS.md's bash-specific quality gates and
the restatement with specifics in docs/plans/bash-p2-plan.md §7.

## LAST SESSION
2026-07-14 (2nd session) — bash p2 build plan written, reviewed, and
pushed: docs/plans/bash-p2-plan.md (commit b1a6512). Plan-only session
per the Phase Builder protocol: all L2.1–L2.8 teaching artifacts
machine-verified at plan time on the baseline (bash 5.2.21, shellcheck
0.9.0, dash 0.5.12); L2.1 recall.json inherited from bash-p01-plan.md's
L1.8 draft and re-verified against built P0/P1 content on disk; L3.1
recall drafted in the L2.8 entry; p2 ships zero destructive commands —
the p3 decoy-tree dependency is restated with specifics in the plan's
§7. One flagged interpretation call for review in the plan's §6: L2.2's
before/after flag demos use one script per flag with the flag toggled
on the command line (bash -e/-u/-o pipefail) rather than three off/on
file pairs. Earlier the same day (1st session): bash p0+1 built,
self-tested, and closed out — 11 labs, 96/96 acceptance assertions,
tagged `bash-p0`/`bash-p1` (full detail in this file's history at
commit 6ec3a48).

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
- [~] bash p2 — Control Flow & Silent Failure (8 labs) — plan done: `docs/plans/bash-p2-plan.md` (commit b1a6512); build not started
- [ ] bash p3 — The Footgun Gallery (9 labs) — depends on: decoy-tree/shadowed-destructive-command containment design (flagged in NEXT UP above; not yet built)
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
