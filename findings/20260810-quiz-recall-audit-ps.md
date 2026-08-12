# ps track: quiz/recall answerability audit

ps track: 54 labs checked, 2 labs with ≥1 BLOCKING quiz issue, 0 labs with ≥1 MINOR quiz issue, 0 labs with ≥1 recall GAP.

Audit method: for every lab in `tracks/ps/phases/*/*/` (54 total), read `meta.json`,
`lab.md`, `hints.json`, `quiz.json`, `recall.json` (where present), `recap.md`, and all
`files/*` fixtures (text files read in full; binaries noted only). Each quiz question was
checked against whether its answer is grounded in the lab's own BRIEF/GUIDED STEPS, a
files/ fixture the guided steps direct the learner to read, or directly observable output
of a guided-step command — reachable *before* the `lab check` gate. Each recall.json
question's `source` field was checked for same-track-and-earlier-lab compliance.

Two genuine BLOCKING bugs were found, both following the confirmed calibration pattern
(SOC L0.1 Q2): a fact tested by the gating quiz that the learner has no way to have seen
before the gate. One additional **schema bug** (not a grounding issue) was found in
`L2.1`'s `recall.json` and is called out separately below because it defeats this
kit's own review-pointer mechanism (traced through `lib/quiz.sh`).

Every lab's `recall.json` (7 labs have one: L1.1, L2.1, L3.1, L4.1, L5.1, L6.1, L7.1)
sources exclusively from earlier labs within the `ps` track itself — no cross-track or
generic-README sourcing was found anywhere in this track, so the recall-GAP count is 0.

## Findings

| lab id | file | question # | severity | issue | suggested fix |
|---|---|---|---|---|---|
| L0.2-meet-the-lab-cli | quiz.json | Q2 | BLOCKING | "If `lab start` refuses a lab past the frontier, what overrides it, at what cost?" (answer: `--force`; skipped labs are marked ⏭ permanently). Nothing in this lab's `lab.md` BRIEF/GUIDED STEPS, `hints.json`, `files/broken.ps1`, or even `recap.md` ever mentions the frontier concept, the `--force` flag, or the ⏭ marker. Compare the demo track's equivalent lab (`tracks/demo/phases/p0/L0.0-meet-the-kit`), whose `files/README-first.txt` explicitly spells out "⏭ forced (--force) — ⏭ never becomes ✓" before its quiz asks the same kind of question — the ps track's "meet the CLI" lab omits that grounding text entirely. This is worse than the SOC calibration case: the fact isn't even in recap.md, so there's no path to it at all. | Add a short frontier/`--force`/⏭ explainer to `lab.md`'s BRIEF (or a `files/` fixture the guided steps point at), mirroring `tracks/demo/phases/p0/L0.0-meet-the-kit/files/README-first.txt`. |
| L1.7-variables-typing-and-null | quiz.json | Q2 | BLOCKING | "Why is writing `$null -eq $x` (null on the left) recommended over `$x -eq $null`?" (answer: because if `$x` is an array, `$x -eq $null` filters elements instead of a scalar compare). The BRIEF only says the lab will "decode... why `$null -eq $var` is best practice" without ever giving the reason. Neither `interp.ps1` (null-interpolation demo) nor `ntype.ps1` (type-coercion demo) demonstrates the array-filtering behavior, and `hints.json`'s three hints only cover running those two scripts and writing `decode.txt` about null interpolation — never the array trap. The actual reason ("dodge the array-filtering trap") appears *only* in `recap.md`, which is shown only after the gating quiz passes. | Add a short demo/explanation of the array-filtering trap (e.g. `@(1,2,$null) -eq $null` vs `$null -eq @(1,2,$null)`) to `lab.md` step 1 or a new `files/` fixture, before the quiz. |

## Additional issue (schema bug, not a grounding gap)

| lab id | file | question # | severity | issue | suggested fix |
|---|---|---|---|---|---|
| L2.1-if-elseif-else-and-comparison-operators | recall.json | all 5 | SCHEMA BUG | Every other `recall.json` in this track (L1.1, L3.1, L4.1, L5.1, L6.1, L7.1) keys the source lab as `"source"`. L2.1's `recall.json` instead uses `"source_lab"` for all 5 questions. Traced through `lib/quiz.sh:111` (`recall_run()`): it does `jq -r '.source // empty'` to build the "review: ..." pointer printed on a missed recall question. Because L2.1 has no `.source` key, this always evaluates to empty, so a learner who misses any of L2.1's recall questions gets no "review:" pointer at all — the non-gating review-nudge feature is silently broken for this lab only. (The underlying source labs referenced — ps L1.2, L1.3, L1.5, L0.3, L1.4 — are all correctly same-track/earlier, so this is a pure key-name typo, not a content/sourcing problem.) | Rename `"source_lab"` to `"source"` in `tracks/ps/phases/p2/L2.1-if-elseif-else-and-comparison-operators/recall.json` (all 5 occurrences) to match the schema `lib/quiz.sh` actually reads. |

## Labs checked with no findings (50 of 54)

All other labs in `p0` (L0.1, L0.3), `p1` (L1.1–L1.6, L1.8), `p2` (L2.2–L2.7), `p3`
(L3.1–L3.8), `p4` (L4.1–L4.9), `p5` (L5.1–L5.7), `p6` (L6.1–L6.5), and `p7` (L7.1–L7.7)
had every quiz question grounded in that lab's own BRIEF/GUIDED STEPS text, a files/
fixture the guided steps explicitly direct the learner to read/run, or directly
observable command output from following the guided steps — and every recall.json
question sourced from an earlier lab in the same track. This track is unusually
disciplined about grounding: most labs' `lab.md` GUIDED STEPS spell out the exact facts
tested by the quiz almost verbatim (e.g. explicit "static reference" blocks in Phase
4–7 labs), which is why only 2 genuine gaps turned up across 54 labs x 3 questions each.
