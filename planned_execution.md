# LAB-KIT — Planned Execution

## NEXT UP
Phase: bash p2 — Control Flow & Silent Failure. bash p0+1 is done (see
LAST SESSION). Next unstarted item: write the Phase 2 build plan
(docs/plans/bash-p2-plan.md) per the Phase Builder protocol (PROMPTS.md
Prompt 2, TRACK: bash PHASE: 2), then build lab-by-lab.

DEPENDENCY FLAGGED for whichever bash phase ships the first destructive
command (per the map, bash p3 — The Footgun Gallery): the decoy-tree /
shadowed-destructive-command containment mechanism was deliberately
NOT built in p0+1 (harness/checklib.sh already ships make_decoy_tree,
decoy_intact, decoy_changed as forward-compatible primitives, but no
lab exercises them yet). p3's build session must design and prove the
containment story before its first footgun lab, not rediscover the
requirement mid-build — see PROMPTS.md's bash-specific quality gates.

## LAST SESSION
2026-07-14 — bash p0+1 built, self-tested, and closed out: all 11 labs
(L0.1-L0.3, L1.1-L1.8) built lab-by-lab from
docs/plans/bash-p01-plan.md, each self-tested with real captured
output (fail path + pass path) on the baseline machine (Ubuntu
24.04.4, bash 5.2.21, `/bin/sh`→dash 0.5.12-6ubuntu5, shellcheck 0.9.0,
shfmt 3.8.0) and committed individually (11 commits, `bash L0.1:
...` through `bash L1.8: ...`). tools/lint-labs.sh clean throughout;
tests/acceptance.sh extended with a fabricated pass + negative case
per lab (commit 9a19c4f) — 96/96 assertions pass. `lab status` renders
11/11 ✓; `lab resume` verified after the L1.8 gate. Two minor deviations
from the plan (logged in docs/plans/bash-p01-plan.md's own decisions
log is the source; noted here for traceability): shfmt prints a bare
version string (no `v` prefix) — already tolerated by check.sh's
pattern; and three check.sh files (L1.3, L1.4, L1.8) needed
double-quoted+escaped hint strings instead of the plan's single-quoted
form to stay shellcheck-clean under this shellcheck build (SC2016).
Tagged `bash-p0` and `bash-p1` (see git tags).

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
- [ ] bash p2 — Control Flow & Silent Failure (8 labs)
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
