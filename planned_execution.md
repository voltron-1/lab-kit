# LAB-KIT — Planned Execution

## NEXT UP
Phase: bash p3 — The Footgun Gallery, BUILD session in progress (Phase
Builder protocol, PROMPTS.md Prompt 2, TRACK: bash PHASE: 3, BUILD),
running lab-to-lab through to phase close-out per explicit go-ahead
(2026-07-17) — no longer gating for a fresh approval between each lab,
but still one commit/PR per lab, self-tested before every commit, and
stopping immediately on a break, a real design decision, or two
consecutive self-test failures.
6 of 9 labs built and committed (L3.1 `c25da72`, L3.2 `4535599`, L3.3
`bfc11d3`, L3.4 `9aad58a` via PR #228, L3.5 `b24968d` via PR #229, L3.6
`cf798ed`). Next unstarted item: **L3.7 — eval** (AUDIT) — why it's
almost always the wrong answer (docs/plans/bash-p3-plan.md §6 L3.7),
uses `fence.sh`/`run-fenced.sh` again; the injection vector is the
unquoted `$action` slot, not `$target` (correction already noted after
L3.1). Containment
(decoy tree + the shadowed-rm fence) is designed, approved, and proven
twice — at plan time in an isolated scratchpad, and for real in-repo
during L3.2's build (`ls / | wc -l`: 28 before/after the fenced
flawed-script run) — so remaining labs execute it rather than
re-deriving or re-proving it from scratch.

## LAST SESSION
2026-07-17 — bash p3 BUILD, L3.6 (subshells vs current shell — why
`… | while read` eats your variables, PREDICT): `cmd | while read … done`
runs the loop in a subshell, so its variable changes are lost when the
subshell exits (`count` stays `0`); `while read … done < <(cmd)` keeps the
loop in the current shell, so the variable survives (`count=3`). Verified
for real; ShellCheck's SC2030/SC2031 fire exactly on this and ARE the
lesson. `code-reviewer` sub-agent caught a real issue: the first-draft
lab.md revealed the actual output values and handed the learner the
literal correct `predictions.txt` content, letting the lab be "solved" by
transcription without ever running `counter.sh` — a break from every
other shipped PREDICT-type lab's convention (checked all 9: L1.1-L1.8,
L2.3, L2.4). Fixed to match: guided steps tell the learner what to run
and to compare against their own prediction, never printing the answer.
Self-tested fail path (0/4), pass path (4/4 + 3/3 quiz), negative case
(`pipe=3` correctly fails just that one assertion). Shipped via its own
branch+PR+merge (`bash-p3-l3.6`).
Also this session, bash p3 BUILD, L3.5 (`(( ))` arithmetic — the injection
people forget it allows, AUDIT): `result=$(( n * 2 ))` on untrusted `n`
runs an attacker's command, because arithmetic evaluation is recursive
and an array-subscript reference inside it — `a[$(cmd)]` — is
command-substituted. Verified for real: `id -u` and a distinct marker
payload both actually executed under a harmless read-only demo payload;
ShellCheck emitted zero warnings on the flawed sample (no dedicated rule
for this class — a documented blind spot, not a gap in this lab). Hardened
fix validates `n` is all-digit before it ever reaches `(( ))`. Self-tested
fail path (1/7), pass path (7/7 + 3/3 quiz), and a negative case (flawed
`calc.sh` swapped in as `hardened.sh` correctly fails the reject-assert).
`code-reviewer` sub-agent pass: approved, no fixes needed. Shipped via its
own branch+PR+merge (`bash-p3-l3.5`).
Also this session: bash p3 BUILD, L3.4 (filenames as attack surface —
`-rf`/`--`/newline names turning `rm *` recursive, AUDIT): real-behavior
finding during self-test — the shared `make_decoy_tree` seeds both `-rf`
and `--` together, and `--` sorts alphabetically first, which neutralizes
`-rf` as an attack in that exact combination (verified: `rm *` becomes
`rm -- -rf alpha.txt subdir`, so nothing recurses). Resolved by giving the
guided detonation demo its own learner-built directory containing only
`-rf` (no shared decoy), which reproduces the real recursive-delete attack
cleanly; the shared decoy (unmodified) still backs check.sh's
hardened-behavior assertions, which don't depend on sort order. Hardened
reference is a files-only `find . -maxdepth 1 -type f -exec rm -- {} +`,
per the plan's own build-time refinement note for this lab. `code-reviewer`
sub-agent pass caught one real issue (a hand-rolled compound check was
silently discarding diagnostic output and its failure message presupposed
the wrong cause for a plausible near-miss submission) — fixed before
merge, re-verified against the exact near-miss case. Shipped via PR #228
(`9aad58a`).
Also this session: corrected planned_execution.md's stale bash p3 status
(it said 2/9 done when L3.3 was already merged) via its own branch+PR
(#227) — the standing git-workflow instruction ("Pull → Branch → Work →
Stage → Commit → Push → PR → Merge, every unit of work, no exceptions")
now applies to doc-only fixes too.
Earlier, 2026-07-16 — bash p3 BUILD, L3.3 (`IFS` — what it controls and how
changing it breaks or attacks a script, DECODE): split the same data
three ways under default/colon/empty IFS, predicted argc/field counts,
demonstrated the re-steering attack for real (`IFS=/` before an
unquoted for-loop over a path splits it into 4 tokens instead of 1). No
destructive command, so no decoy/fence needed. Committed `bfc11d3`
directly to `main` — the last direct-to-main push under the old default,
superseded the same day by the standing Pull→Branch→...→Merge instruction.
Earlier the same day, bash p3 BUILD, L3.2 (`rm -rf "$DIR/"` — the empty-variable
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
board: [LAB-KIT: Rust Literacy Lab](https://github.com/users/voltron-1/projects/19) — 63 issues, 8 milestones, 264 pts
- [ ] rust p0 — Toolchain & Kit (3 labs)
- [ ] rust p1 — Reading Basic Rust (9 labs)
- [ ] rust p2 — Ownership, Borrowing, Lifetimes (10 labs)
- [ ] rust p3 — Types, Traits, Error Handling (10 labs)
- [ ] rust p4 — Security-Critical Rust (10 labs)
- [ ] rust p5 — Concurrency & Async (8 labs)
- [ ] rust p6 — Reading Real Security Tools (6 labs)
- [ ] rust p7 — Directing & Auditing AI Rust (7 labs)

### bash — Bash Literacy Lab (54 labs)
board: [LAB-KIT: Bash Literacy Lab](https://github.com/users/voltron-1/projects/18) — 54 issues, 8 milestones, 238 pts, 22 closed
- [x] bash p0 — Toolchain & Kit (3 labs) — tag `bash-p0`; plan: `docs/plans/bash-p01-plan.md` (commit b61b60e)
- [x] bash p1 — The Expansion Model (8 labs) — tag `bash-p1`; plan: `docs/plans/bash-p01-plan.md` (commit b61b60e)
- [x] bash p2 — Control Flow & Silent Failure (8 labs) — tag `bash-p2`; plan: `docs/plans/bash-p2-plan.md` (commit b1a6512)
- [~] bash p3 — The Footgun Gallery (9 labs) — plan: `docs/plans/bash-p3-plan.md` (commit 8796cb3); containment proven (scratchpad + in-repo); 6/9 built — L3.1 word splitting, L3.2 empty-var rm -rf (PR #1, `c0ede9e`), L3.3 IFS (`bfc11d3`), L3.4 filename attacks (PR #228, `9aad58a`), L3.5 arithmetic injection (PR #229, `b24968d`), L3.6 subshell var loss (`cf798ed`); next is L3.7 eval
- [ ] bash p4 — Untrusted Input & Injection (8 labs)
- [ ] bash p5 — Text Processing & Pipelines (6 labs)
- [ ] bash p6 — Reading Real Deploy Scripts (5 labs)
- [ ] bash p7 — Directing & Auditing AI Bash (7 labs)

### soc — SOC Analyst Lab (52 labs)
board: [LAB-KIT: SOC Analyst Lab](https://github.com/users/voltron-1/projects/20) — 52 issues, 8 milestones, 232 pts
- [ ] soc p0 — Toolbelt & Kit (3 labs)
- [ ] soc p1 — How Attacks Become Alerts (8 labs)
- [ ] soc p2 — Network Triage Fundamentals (7 labs)
- [ ] soc p3 — Endpoint Triage Fundamentals (7 labs)
- [ ] soc p4 — Triage Craft & the Queue (8 labs)
- [ ] soc p5 — Phishing & Malware Triage (6 labs)
- [ ] soc p6 — Investigation & Escalation (6 labs)
- [ ] soc p7 — The AI-Assisted Analyst (7 labs)

### ps — PowerShell Literacy Lab (54 labs)
board: [LAB-KIT: PowerShell Literacy Lab](https://github.com/users/voltron-1/projects/21) — 54 issues, 8 milestones, 237 pts
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

Each track also has a GitHub Projects v2 board (linked under its heading
above) — one issue per lab as a user story (`sp:N` story points, Fibonacci
by lab type; milestone = phase), for granular tracking below the
phase-level view this file gives. Boards mirror this file's completion
state; they do not compete with git tags as the source of truth either —
a lab's issue is closed when its commit/tag lands, not the other way
around.
