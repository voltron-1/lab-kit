# LAB-KIT — Planned Execution

## NEXT UP
Phase: bash p3 — The Footgun Gallery. bash p2 is done (see LAST
SESSION). Next unstarted item: bash p3's PLAN session (Phase Builder
protocol, PROMPTS.md Prompt 2, TRACK: bash PHASE: 3) — its first job is
to design and prove the decoy-tree containment mechanism (see
DEPENDENCY FLAGGED below) before speccing L3.2 (the rm -rf
empty-variable lab) or any other footgun lab.

DEPENDENCY FLAGGED for bash p3 — The Footgun Gallery, still unresolved:
the decoy-tree / shadowed-destructive-command containment mechanism was
deliberately NOT built in p0+1 or p2 (harness/checklib.sh already ships
make_decoy_tree, decoy_intact, decoy_changed as forward-compatible
primitives, but no lab exercises them yet — p2 confirmed it stayed at
zero destructive commands throughout, per its own build report below).
p3's PLAN session must design and prove the containment story before
its first footgun lab, not rediscover the requirement mid-build — see
PROMPTS.md's bash-specific quality gates and the restatement with
specifics in docs/plans/bash-p2-plan.md §7.

## LAST SESSION
2026-07-15 — bash p2 built, self-tested, and closed out: all 8 labs
(L2.1-L2.8) built lab-by-lab from docs/plans/bash-p2-plan.md, each
self-tested with real captured output (fail path + pass path) on the
baseline machine (Ubuntu 24.04.4, bash 5.2.21, shellcheck 0.9.0, dash
0.5.12-6ubuntu5) and committed individually (8 commits, `bash L2.1:
...` through `bash L2.8: ...`). tools/lint-labs.sh and
tools/shellcheck-all.sh clean throughout (one mid-build catch: a
check.sh hint in L2.8 spelled out the literal path `/dev/null` and the
absolute-path-literal lint correctly flagged it — reworded, no
`lint-allow.txt` entry needed). tests/acceptance.sh extended with a
fabricated pass + one negative case per lab (commit 158566a) —
131/131 assertions pass; L2.8's negative case is the FIX-type-
appropriate one (the shipped flawed script left unedited fails the
honesty-test assertion), not a generic missing artifact. Also verified
L2.8's behavioral grading independently accepts BOTH valid fixes (the
`set -euo pipefail` preamble and bare `|| exit` guards), per design.
`lab status` renders 19/19 ✓ across the full bash catalog; `lab resume`
verified after the L2.8 gate. p2 shipped zero destructive commands —
decoy-tree helpers remain untouched, as required (see DEPENDENCY
FLAGGED above). One flagged interpretation call from the plan session,
carried through unchanged in the build (logged in
docs/plans/bash-p2-plan.md §6 for reference): L2.2's before/after
strict-mode demos use one script per flag with the flag toggled on the
command line, not three separate off/on file pairs. Tagged `bash-p2`.
Earlier the same week: bash p0+1 built and closed out (11 labs, tagged
`bash-p0`/`bash-p1`), and the bash p2 build plan written and pushed
(`docs/plans/bash-p2-plan.md`, commit b1a6512) — full detail in this
file's history at commits 6ec3a48 and 0db647e.

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
