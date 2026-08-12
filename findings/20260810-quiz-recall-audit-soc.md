soc track: 52 labs checked, 3 labs with ≥1 BLOCKING quiz issue, 1 lab with ≥1 MINOR quiz issue, 1 lab with ≥1 recall GAP.

## Methodology note

Every lab's meta.json, lab.md, hints.json, quiz.json, recall.json (where
present), recap.md, and files/ (text fixtures read in full; binaries —
L0.1's fixtures.pcap, L2.4's/L2.7's capture.pcap — noted but not parsed)
were read in full.

**Calibration case (given, not re-reported):** L0.1's quiz.json Q2 asks which
two tools are graded on version output plus staged mock reports because
`check.sh` runs offline — that fact lives only in L0.1's recap.md line 2.
This is the reference bug pattern; L0.1's Q1 and Q3 were independently
checked and are OK (grounded in files/ and lab.md respectively). L0.1's
recall.json, a *separate* issue from the calibration Q2 bug, is reported
below.

**Same-track earlier-lab grounding:** the soc track's own CLI locks labs
sequentially per track (`lib/catalog.sh`'s `catalog_frontier()`), and the
task's recall.json rule explicitly treats any earlier same-track lab as
reachable. The task's quiz wording ("no other track") reads as the operative
exclusion, so this audit extended the same standard to quiz.json: a fact
taught in *any earlier same-track lab* (not just the current lab) counts as
legitimately grounded, including phase-gate labs (L0.3, L1.8, L2.7, L3.7,
L4.8, L5.6, L6.6, L7.7) explicitly testing cumulative phase knowledge.
Facts that exist *only* in the current lab's own recap.md, or nowhere at
all in reachable material, remain BLOCKING regardless of this allowance.

**Elimination credit:** several quiz questions have two options that are
self-contradictory, absurd on their face, or directly refuted by the lab's
own demonstrated material, leaving one substantive answer. These were
judged OK, not flagged, consistent with the calibration guidance that
reasonable inference isn't a bug. A list of the closer calls resolved this
way is below the findings table for a second opinion.

**recall.json schema drift:** L0.1, L1.1, and L2.1's recall.json questions
all carry an explicit `"source"` field. Starting at L3.1, all five
phase-opener recall.json files (L3.1, L4.1, L5.1, L6.1, L7.1) omit the
`"source"` field entirely on every question (verified by direct JSON
inspection — 0/5 keys present in each). Content-wise, every question in
these five files was manually traced to same-track earlier-phase material
(e.g., L4.1's five questions map cleanly to L3.1/L3.2/L3.3/L3.5/L3.6), so
this is not an exposure gap — but it is a data-completeness regression
against the schema the first three phase-openers established, and (per the
bash-track audit's finding of the identical defect) `recall_run()`-style
review pointers depend on a non-empty `source` field, so learners missing
these questions may not get a review pointer at all. Not counted toward the
GAP total since no cross-track exposure was found, but worth a fix.

## Findings

| lab id | file | question # | severity | issue | suggested fix |
|---|---|---|---|---|---|
| L0.1-analyst-toolbelt-install-verify-jq-tshark-dig-whois-ripgrep | recall.json | R1,R2,R3,R4,R5 | GAP | All 5 recall questions source from "README CLI table / L0.0", "L0.0 grading walkthrough", "README --force semantics", "L0.0 workspace-fence demo", "README hint ladder" — L0.0 is `tracks/demo/phases/p0/L0.0-meet-the-kit`, a **different track**. L0.1 is the very first lab in the soc track; a learner who starts directly on soc (no cross-track prerequisite is enforced) has never seen any of this material. | Either point these at soc-track material (there is none yet, since L0.1 is first) or drop/rewrite them to test the repo-root README directly by citing it as `"source": "README"` and confirming the README is shown to every learner regardless of track (if it is); otherwise defer these facts to a later soc lab's recall.json. |
| L1.3-anatomy-of-an-alert-rule-metadata-severity | quiz.json | 1 | BLOCKING | Asks which metric (rule.severity vs risk_score) changes if the same rule fires on 6 accounts instead of 42. The fact that `risk_score` is computed per-alert while `rule.severity` is static/set by the rule author exists only in recap.md line 2 ("rule.severity is static... risk_score is computed per alert — never confuse the two"). lab.md's BRIEF and GUIDED STEPS name both fields and tell the learner to inspect them but never state which one is static vs. dynamic, and no earlier lab (L0.1–L1.2) covers this distinction either. | Add a sentence to lab.md step 1 or the BRIEF stating that `rule.severity` is fixed by the rule definition while `risk_score` is computed per-alert (e.g., scales with `user.names_total`). |
| L3.5-linux-auth | quiz.json | 3 | BLOCKING | Asks about "Accepted publickey for d.okafor from 10.20.31.112" appearing "next to the brute force" — this exact event never appears anywhere in the lab's evidence. Grepped `files/auth.log` and `files/auditd.log` in full: neither "d.okafor" nor "publickey" nor "10.20.31.112" occurs in either file (auth.log only contains the admin brute-force failures, the root Accepted password, the websvc UID=0 creation, and the sudo curl command). The question asks the learner to reason about evidence that was never staged. | Either add the cited `Accepted publickey for d.okafor from 10.20.31.112 ...` line to files/auth.log so the learner can actually observe it, or rewrite Q3 to reference an event that is actually present in this lab's fixtures. |
| L4.2-enrichment | quiz.json | 3 | BLOCKING | Asks why the lab grades against staged reports instead of live VirusTotal; the answer ("the graded path is offline and deterministic") exists only in recap.md line 3 ("The graded path is offline mocks by design — real WHOIS/dig/VT are optional, so no lab ever depends on a live service."). lab.md's BRIEF only says the reports are "mock," never explaining the offline/deterministic grading rationale, and hints.json doesn't cover it either. This is the same underlying bug pattern as the L0.1 calibration case, recurring in a different lab. | Add a line to lab.md's BRIEF (or a step) stating that `lab check` always grades from these staged files, never live network lookups, mirroring what L0.1 should also state up front. |
| L5.6-gate-phish-report | quiz.json | 3 | MINOR | Asks why the lab "ships a model report" — this refers to `files/model-report.md`, which exists in the lab's files/ but is never mentioned anywhere in lab.md's GUIDED STEPS or in hints.json (only report-template.md, reported.eml, and sandbox-report.md are referenced). A learner following only the guided steps would not know a "model report" was provided at all. The question is still answerable by eliminating the two clearly-wrong options ("grading is impossible", "reports don't matter"), so it is not a hard blocker — but it references undocumented material. | Add a line to lab.md GUIDED STEPS (or hints.json) telling the learner that `files/model-report.md` is available as a worked-example reference for report quality/structure. |

## Notes on borderline cases resolved as OK (not listed above, but worth a second opinion)

- **L0.1 Q3** (tshark's non-root packet-capture prompt) — lab.md's step 1 note says "reading PCAP files requires no special privileges" without stating that *live capture* needs elevated privileges; the correct option is reachable by elimination against the other two absurd choices plus this partial statement. Judged OK.
- **L1.2 Q1** (`event.ingested` vs `@timestamp`) — the field is visible verbatim in the command output the guided steps direct the learner to run (`grep j.walsh ecs.jsonl | jq .` surfaces `event.ingested` on the matched line), and the name is self-descriptive against the lab's own framing of `@timestamp` as true occurrence time. Judged OK; L6.2 later states this distinction explicitly in its own lab.md, reinforcing it.
- **L1.4 Q3** (Sigma `level: high` meaning) — the raw `level: high` line is visible via the guided `cat` of the rule file, but its semantic meaning (author's estimate, not a verdict) is only in recap.md verbatim. Credited via L1.3 (immediately preceding lab), whose BRIEF states "A SIEM alert is a structured claim about underlying evidence" — directly transferable reasoning. Judged OK on backward-citation grounds; a stricter reviewer could flag this as BLOCKING since the specific word "level" is never explained in either lab.
- **L1.8 Q1** (telemetry pipeline ordering) — the specific 6-stage pipeline name sequence is only in recap.md, but the other two options are internally backwards/scrambled and eliminable by simple logic without needing the exact recap phrasing.
- **L3.1 Q3**, **L3.4 Q1/Q3**, **L4.4 Q3**, **L7.6 Q2** — each turns on a fact that is extremely well-established general IT/security knowledge (HKCU Run keys execute at logon, UID 0 = root, password spray evades per-account lockout, "independently-saved segments" implies resumability) rather than a SOC-specific hidden fact, combined with two clearly-absurd distractor options. Judged OK, distinct from the BLOCKING items above which require lab-specific staged facts unavailable anywhere in reachable material.
- **L3.6 Q3** — references "the Bash track" by name (a genuinely different track), but the correct answer ("same attack in victim telemetry — auth.log/auditd execve") is independently derivable from this lab's own commands.jsonl plus L3.5 (immediately preceding same-track lab), which already showed the identical `curl .../u.sh | bash` command in auditd.log. Judged OK; the cross-track mention is flavor text, not a hard dependency.
- **L7.1 Q3**, **L7.4 Q3**, **L7.6 Q2** — each has its precise phrasing only in recap.md, but each also echoes a theme repeated pervasively across nearly every phase-gate recap and several individual labs throughout the whole track (ground every claim, verify before trusting), and each has two options that are clearly weaker/dismissive. Judged OK via elimination plus track-wide thematic reinforcement rather than BLOCKING; a stricter reviewer could downgrade these.

If a stricter standard is preferred (no elimination credit, no same-track
backward-citation credit even for the recap-only wording), the BLOCKING
count would grow by several of the items listed above as "borderline,
resolved OK" — this audit chose the more lenient reading because the CLI
genuinely enforces the same-track prerequisite chain and because several
wrong options in this track are transparently non-viable rather than merely
"less likely."
