bash track: 54 labs checked, 6 labs with ≥1 BLOCKING quiz issue, 0 labs with ≥1 MINOR quiz issue, 1 lab with ≥1 recall issue.

## Methodology note

Every lab's meta.json, lab.md, hints.json, quiz.json, recall.json (where present),
recap.md, and files/ (text fixtures read in full; binaries — L5.4's events.jsonl,
L7.7's sample.ndjson — noted but not parsed) were read in full.

One judgment call, stated up front because it changes results: for the eight
**phase-gate** labs (meta.json `"gate": true` — L0.3, L1.8, L2.8, L3.9, L4.8,
L5.6, L6.5, L7.7), these labs are explicitly designed as cumulative reviews of
everything already taught in that phase, and the CLI enforces that a learner
has already passed every earlier lab in the track (`lib/catalog.sh`'s
`catalog_frontier()` gates sequentially per track) before reaching a gate lab.
So for gate labs only, a fact taught in *any earlier same-track lab* counts as
legitimately reachable — consistent with the same-track rule the task already
specifies for recall.json. For all 46 non-gate labs, grounding was required
within that lab's own lab.md / hints.json / files/ / directly observable
command output, per the strict letter of the instructions. Answers reachable
only by rejecting one or two options that are absurd or self-contradictory on
their face (not merely "less likely") were counted OK via elimination, not
flagged — this matches several questions' evident design (two throwaway
distractors, one substantive answer).

No recall.json question in the entire bash track cites a source outside the
bash track — the track is disciplined about this. The one recall finding below
is a different, structural defect (see L7.1).

## Findings

| lab id | file | question # | severity | issue | suggested fix |
|---|---|---|---|---|---|
| L1.2-variables-and-braces | quiz.json Q2 | 2 | BLOCKING | Prompt is explicitly labeled "(Teaser for L1.4)" and asks what `echo '$v'` prints. Single-quote behavior is never mentioned anywhere in L1.2 — not lab.md, not hints.json, not even recap.md (verified by grep: the only "quote"-adjacent recap line is about unset variables, unrelated). L1.2's own material is 100% about `$name`/`${name}` boundary rules; single quotes are a completely different, untaught mechanism. | Either move this question to L1.4 (where single-quote behavior is actually taught), or add one line to L1.2's lab.md/recap stating that single quotes suppress all expansion. |
| L1.7-command-substitution | quiz.json Q1 | 1 | BLOCKING | Asks "Backticks `cmd` versus $(cmd)?" and requires knowing backticks are the same feature as $(...), run in the same shell (not a subshell), but don't nest without escaping. The word "backtick" appears nowhere in L1.7 except inside quiz.json itself (grep-verified) — not lab.md, not hints.json, not files/, not even recap.md. | Add a line to lab.md or recap.md introducing backticks as the legacy equivalent of $(...) before asking about them, or drop the question. |
| L2.2-strict-mode-preamble | quiz.json Q2 | 2 | BLOCKING | Asks which part of `set -euo pipefail` breaks under dash (L0.3), answer being `-o pipefail` specifically (dash: "Illegal option -o pipefail", exit 2). The word "dash" appears nowhere in L2.2 outside quiz.json itself (grep-verified) — the lab's own six captured-output pairs never test any of the three flags under dash, only under plain bash vs. flagged bash. A learner cannot derive which of the three flags is the non-POSIX one from anything shown. | Add a step (mirroring L0.3's honest/liar-under-dash demo) that runs `dash -c 'set -euo pipefail'` or shows the actual dash error, or state the fact directly in lab.md. |
| L3.8-shellcheck-copilot | quiz.json Q3 | 3 | BLOCKING | Asks what SC1090/SC1091 ("can't follow source") means. This is the exact confirmed bug pattern: the fact ("informational, not a defect — dynamic source paths are normal; our own harness uses a shellcheck source= directive") exists **only in recap.md**, which per bin/lab's cmd_check only prints after the quiz already passed. sample.sh (the lab's only files/ fixture) triggers six other SC codes (2115/2086/2035/2006/2166/2034) but never SC1090/SC1091, and lab.md's own walkthrough (steps 1-4) never mentions it either. | Add a `source ./somefile` line to sample.sh (or a callout in lab.md step 3/4) that actually triggers SC1090/SC1091 so the learner sees and reads about it before the gate. |
| L6.3-systemd-unit-tour | quiz.json Q1 | 1 | BLOCKING | Asks what `Type=simple` means (service considered "started" the instant ExecStart forks, no readiness signal). `Type=simple` appears once, in files/log-relay.service line 13, with zero explanation anywhere — lab.md's guided steps (step 1: User/Group/After/Wants/EnvironmentFile/ExecStart; step 2: NoNewPrivileges/ProtectSystem/ReadWritePaths) never once mention the `Type=` directive, and neither do hints.json or recap.md. None of the other lesson content gives a basis to eliminate options b/c either. | Add a bullet to guided step 1 explaining `Type=simple`'s semantics (no readiness protocol vs. Type=notify/forking), matching the treatment every other directive on the unit gets. |
| L7.5-ci-guardrails | quiz.json Q3 | 3 | BLOCKING | Asks why `tools/shellcheck-all.sh` (a real repo tool, not shown in files/ or pasted into lab.md) scans untracked files in addition to tracked ones. lab.md and hints.json only ever give the bare answer token `sweeptrap=untracked` for answers.txt, never the reasoning; recap.md gives the general concept ("sweep untracked files too, or a brand-new script ships unchecked") but never names or shows tools/shellcheck-all.sh's actual behavior. The learner is never directed to open this file. | Either paste the relevant tools/shellcheck-all.sh snippet (the git-ls-files-vs-glob logic) into lab.md as a guided step, or point the learner to read it directly (`cat ../../../tools/shellcheck-all.sh` or similar), before asking about it. |
| L7.1-ai-bash-failure-patterns | recall.json (all 5 Qs) | — | GAP (schema defect) | All 5 questions restate material from L6.1–L6.5 (content matches one-for-one) but every question is missing the `"source"` field that every other phase-opener's recall.json has (verified: L1.1/L2.1/L3.1/L4.1/L5.1/L6.1 all have 5/5 questions with `"source": "bash L#.#"`; L7.1 has 0/5). This isn't a cross-track exposure gap — the content is legitimately same-track and earlier — but it is a functional regression: `lib/quiz.sh`'s `recall_run()` only prints a `review: <source>` pointer when `.source` is non-empty (`[[ -n "$src" ]] && miss_src+=("$src")`), so a learner who misses any L7.1 recall question gets no review pointer at all, unlike every other phase in the track. | Add `"source": "bash L6.1"` through `"bash L6.5"` to L7.1's five recall.json questions, matching the pattern used by every other phase-opener. |

## Notes on borderline cases resolved as OK (not listed above, but worth flagging for a second opinion)

- **L1.4 Q3** ("(L1.7 preview)" — does `"$(hostname)"` expand inside double quotes) — forward reference to unlearned material, but L1.4's own BRIEF states the general rule generically ("double quotes: $ expands, but the result stays one word") which directly transfers to any `$`-construct, including one not yet named. Judged OK as a fair generalization, unlike L1.2 Q2 which had no analogous in-lab principle to generalize from.
- **L2.4 Q3** (`grep -q ERROR log || true` under `set -e`) — not taught in L2.4 itself, but explicitly and correctly backward-cited to L2.2 (a completed, same-track earlier lab that literally forward-references "this is why L2.4's `cmd || true` idiom exists"). Judged OK on backward-citation grounds distinct from L1.2/L1.7/L2.2's forward-reference or nowhere-at-all failures.
- **L2.8 Q2**, **L3.3 Q3**, **L6.4 Q2** — each has its precise remediation phrasing only in recap.md, but each is answerable by eliminating two options that are either self-contradictory or directly refuted by what the guided steps just demonstrated. Judged OK via elimination rather than BLOCKING; a stricter reviewer could reasonably downgrade these to MINOR.

If a stricter standard is preferred (no credit for elimination-based reasoning, no backward-citation credit even for gate labs), the BLOCKING count would grow by treating L1.8's Q1/Q2 and several phase-gate questions as BLOCKING too, since their exact wording lives in an earlier lab, not the gate lab itself — this audit chose the more lenient, phase-gate-aware reading because the CLI genuinely enforces that prerequisite chain.
