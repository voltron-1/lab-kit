# LAB-KIT — Planned Execution

## NEXT UP
Phase: bash p0+1 — Toolchain & Kit, then The Expansion Model. The plan
is written and committed; the build (scaffolding actual lab
directories under tracks/bash/phases/) has not started.
Next unstarted item: execute `docs/plans/bash-p01-plan.md` lab-by-lab
per the Phase Builder protocol (PROMPTS.md Prompt 2, TRACK: bash
PHASE: 0+1, step 4 onward — build, self-test, then tag `bash-p0` /
`bash-p1`).

## LAST SESSION
2026-07-13 — bash p0+1 build plan authored (one agent per lab) and
empirically verified (execution + ShellCheck on the baseline machine —
bash 5.2.21, `/bin/sh`→dash, shellcheck 0.9.0) against
docs/curriculum/bash-literacy-lab-curriculum-v1.md and
docs/kit-contracts.md. Committed & pushed as `docs/plans/bash-p01-plan.md`
(commit b61b60e). No lab content built yet — planning only.

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
- [~] bash p0 — Toolchain & Kit (3 labs) — plan: `docs/plans/bash-p01-plan.md` (commit b61b60e); build not started
- [~] bash p1 — The Expansion Model (8 labs) — plan: `docs/plans/bash-p01-plan.md` (commit b61b60e); build not started
- [ ] bash p2 — Control Flow & Silent Failure (8 labs)
- [ ] bash p3 — The Footgun Gallery (9 labs)
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
