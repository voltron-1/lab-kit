# SOC Track — Phase 7 Build Plan (v1)

**Mode:** plan only — produced 2026-07-20 per Phase Builder step 3 (PROMPTS.md Prompt 2),
inside a PLAN-AHEAD session that plans every remaining soc phase one at a time. **Final phase.**
**This document is the deliverable for `docs/plans/soc-p7-plan.md`** (saved there verbatim on merge).
**Binding content spec:** `docs/curriculum/soc-analyst-lab-curriculum-v1.md` — Phase 7 (§6, lines 234–247).
**Binding mechanical spec:** `docs/kit-contracts.md` + the soc quality gates in `PROMPTS.md`.
**Predecessor plans (inherited):** `soc-p01…p6-plan.md` — universe, generator, §2.1 grading, §2.2 ids,
defang regex-escape recipe, enrichment mocks, §2.3 REPORT rubric+defang gate, PIVOT pattern,
investigation bundle. Extended, not re-derived.
**Scope:** 7 labs — L7.1–L7.7 (capstone shift L7.6, capstone gate L7.7) — plus the `tools/genevidence/`
**AI-summary emitter** (with planted, scenario-declared flaws) and the track's **VERIFY-lab grading
contract** — the grounding check that gives the whole course its point.

## 0. Ground rules this plan follows

- Lab list is **map-exact** (§239–245): ids, titles, types (DECODE/VERIFY/DECODE/VERIFY/DECODE/TRIAGE/
  REPORT), capstone shift on L7.6, capstone gate on L7.7 — no deviations.
- Evidence **generated, never hand-written**; VERIFY labs ship an **AI summary whose planted flaws are
  declared in `scenario.yaml`**, including **≥1 claim citing a nonexistent event id** (PROMPTS.md soc
  gate). The generator emits the summary, the raw evidence, AND the flaw key from one source.
- Grades **offline in the check fence** (§2.1 for DECODE/VERIFY/TRIAGE; §2.3 rubric+defang for the
  REPORT gate). Raw evidence never defanged; prose, keys, answers, and the report **do** defang.
- **Flat-file first**; SO overlay ungraded on L7.6/L7.7 only.
- ADHD contract: one concept per lab; the capstone (L7.6) is **explicitly segmented and independently
  saved** (map §96) so it spans up to three sittings (§D2). est 15–20; L7.6/L7.7 are the pacing peaks.
- **This is the terminal phase:** L7.7's gate drafts **no next-opener recall** (there is no Phase 8);
  the close-out tags `soc-p7` and completes the track.

## 1. Universe: the machine in the loop (no new attack)

Additive to `soc-p01-plan.md` §1. Phase 7 introduces **no new attacker behavior** — it puts an **AI
triage assistant** beside the analyst over the same Coppermine March intrusion, and trains the human
half of the loop: verifying machine output against evidence.

- **The AI assistant is a mocked artifact.** Each VERIFY/capstone lab ships an `ai-summary.{md,json}`:
  a plausible, confident triage/investigation summary with **numbered claims**, each carrying a
  `cites:` event id. Some claims are **grounded** (the cited id exists and supports the claim); some are
  **flawed** by a declared type. Flaw taxonomy (pinned in `universe.yaml`):
  - **hallucinated** — cites an event id that **does not exist** in the evidence (e.g. `CM-9999-9999`,
    chosen outside every real band so `verify.py` can assert absence).
  - **wrongpivot** — cites a **real** id but draws the wrong connection (e.g. attributes the beacon to
    the wrong host).
  - **ungrounded** — a confident claim with **no citation** at all.
  - **contradicted** — cites a real id whose content **contradicts** the claim (e.g. "MFA satisfied"
    when the Entra record shows MFA absent).
- **The grounding contract (the course's thesis, map §247):** *every AI claim must cite an event id that
  exists in the evidence.* This is the same contract the analyst's own platform imposes on its agents;
  L7.4 grades exactly it.
- **Reused incident:** all AI summaries describe the M1/M2/M3/M4 + lateral + Linux intrusion with reused
  ids, so a learner who did Phases 1–6 recognizes when the machine is right and when it drifts.

## 2. Generator extensions — `tools/genevidence/`

Prerequisite: `soc-p0…p6` tagged. Phase 7 adds one emitter + one verify invariant:

1. **`ai_summary`** — emit an `ai-summary` from a scenario's declared claim list: each claim has
   `text`, `cites` (an event id or none), and a `flaw` (`grounded|hallucinated|wrongpivot|ungrounded|
   contradicted`). The emitter writes the human-facing summary **and** the flaw key into check.sh. The
   hallucinated id is drawn from a reserved never-used range so it can't accidentally collide with real
   evidence.
2. **`verify.py` addition — grounding-contract check:** for every claim, if `flaw==grounded` its cited
   id **must exist** in the lab's evidence and its content must support the claim; if
   `flaw==hallucinated` its cited id **must be absent** from all emitted evidence; `contradicted` cites a
   real id whose field genuinely opposes the claim. This makes the planted flaws real, not asserted —
   the same grounding the learner is taught to demand. Inherited defang/no-fang checks still run.

## 2.1 VERIFY-lab grading pattern (NEW — binding for L7.2, L7.4, and the L7.6 AI segment)

VERIFY labs grade **per-claim** via the §2.1 canonical pattern:
- For an N-claim summary, `qN=` a verdict `grounded|flawed`; for flawed claims, `qNf=` the flaw type
  (`hallucinated|wrongpivot|ungrounded|contradicted`), keyed from the generator's flaw list.
- A **catch question** proves the learner actually cross-checked: e.g. `q_hall=` the hallucinated event
  id itself (the learner must produce the fabricated id, showing they looked it up in the evidence and
  found it absent). `verify.py` guarantees that id is genuinely absent.
- Grading is anchored `assert_file_contains` per claim/flaw from the generated key; `ck_summary` last.
This is the analog of Bash's TAME and Rust's DIRECT — the track's signature type, existing to train
against automation bias deliberately.

## 2.2 (inherited) REPORT contract — unchanged (Phase 5 §2.3), extended for L7.7

L7.7 uses the REPORT rubric (required elements + defang gate + model report) **plus a required
`## Tuning Recommendation` section** graded as a structured exclusion (the L4.6 `field:value` token) —
the analyst-to-detection-engineering handoff. So L7.7's key = the §2.3 rubric ∪ {tuning-exclusion token}.

## 3. Decisions & flagged deviations (approve/veto with the plan)

1. **The AI assistant is a static mocked artifact, not a live model call.** VERIFY labs grade the
   learner's verification of a **fixed** summary whose flaws are known and generator-emitted — the
   graded path never calls an LLM (offline, deterministic, and the flaws are guaranteed real by
   `verify.py`). Veto only if you want a live-model variant (loses determinism and offline grading).
2. **Capstone shift (L7.6) is segmented into three independently-saved answer files** (map §96):
   `queue.answers`, `phish.answers`, `incident.answers` in the workspace. The kit's `lab resume`
   already persists the workspace, so a learner can do the queue now, the phish tomorrow, the incident
   next week; `check` grades whichever segments are complete and reports per-segment. One `check.sh`,
   three answer blocks. Veto to make it a single monolithic answers.txt (loses the three-sittings
   promise).
3. **L7.6 provides an AI summary the learner must VERIFY, not obey.** One of the three segments ships an
   `ai-summary` containing a planted flaw; passing requires the learner to **override** it — "the AI
   said benign" is not a verdict (map §235). This wires VERIFY into the capstone, not just L7.2/L7.4.
4. **L7.7 requires a tuning recommendation** as a graded structured exclusion (D of L4.6) on top of the
   §2.3 report rubric — the course's final deliverable is the full analyst→DE handoff.
5. **Terminal phase:** no parked next-opener recall (no Phase 8). Close-out tags `soc-p7` and the track
   is complete.
6. **SO overlay ungraded on L7.6/L7.7 only.** Flat-file always graded. Defang enforced throughout.

## 3.5 Self-review corrections applied

- **Planted flaws must be real, not just labeled.** If a "hallucinated" id happened to exist, the lab
  would teach the wrong lesson. Fixed: `verify.py`'s grounding-contract check asserts absent ids are
  absent and grounded ids are present-and-supporting, as a hard pre-commit gate; the hallucinated id
  comes from a reserved never-used range.
- **VERIFY must not be gameable by marking everything 'flawed'.** Fixed: each VERIFY lab includes
  **grounded claims too** (a mix), so a learner who flags everything fails the grounded ones; the
  catch-question (`q_hall`) requires producing the actual fabricated id, which only cross-checking
  yields.
- **The subtle-wrong summary in L7.2 must be genuinely subtle.** Fixed: the wrong summary of the three
  is *mostly correct* with one contradicted claim (cites a real id whose content opposes the claim —
  e.g. "no persistence observed" while `CM-0311-0181` is the Run key), so the learner must read the
  evidence, not just the summary's confidence.
- **Capstone segments must reconcile with prior verdicts.** The L7.6 queue/phish/incident reuse the
  canonical verdicts (svc_backup btp, M2 tp, MAIL-LEGIT legit, the M4-success escalation) so the
  capstone can't contradict the course; `verify.py` cross-checks.
- **L7.7 tuning rec must be checkable.** Fixed: graded as the L4.6 `field:value` exclusion token (e.g.
  the M2 detection tuning, or a false-positive suppression), keyed exactly, with the prose rationale
  calibrated by the shipped model.

---

## 4. Phase 7 — labs

### L7.1 — Automation bias — the documented failure modes of analysts supervising machines

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L7.1 | Automation bias — the documented failure modes of analysts supervising machines | DECODE | false | 15 |

Dir `tracks/soc/phases/p7/L7.1-automation-bias/`. **One concept:** the documented failure modes of
humans supervising machines — over-reliance, complacency, and the disappearance of vigilance.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s7-bias`, RAW):
  - `failure-modes.md` — static reference: **commission bias** (following a wrong automated action),
    **omission bias** (missing an event the automation didn't flag), **complacency** (reduced monitoring
    of a trusted system), **de-skilling** (losing the ability to work without the tool), **anchoring**
    (the AI's verdict biases yours before you read evidence).
  - `mini-cases.md` — 5 short vignettes, each an analyst behavior that exhibits one failure mode.
  - `answers.template.txt`.
- **Learner task:** match each vignette to its failure mode. Template + grammar (`qN=` one mode token):
  ```
  # modes: commission | omission | complacency | deskilling | anchoring
  q1=  # analyst closes an alert because the AI said benign, without reading evidence -> commission
  q2=  # analyst misses a real event the AI summary never mentioned                    -> omission
  q3=  # analyst stops spot-checking a tool that's "always right"                       -> complacency
  q4=  # analyst can no longer triage when the AI assistant is down                      -> deskilling
  q5=  # analyst's verdict matches the AI's first guess before opening the logs          -> anchoring
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; five anchored checks; `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L7.1", type:"DECODE", objective:"Name the documented failure modes of humans
    supervising automation — commission, omission, complacency, de-skilling, anchoring", gate:false,
    est_minutes:15}`
  - `quiz.json`:
    1. (choice) "Automation bias is:" a) a software bug b) the human tendency to over-trust automated
       output and under-verify it c) a SIEM setting d) always harmless → **b**
    2. (choice) "'The AI said benign, so I closed it' is:" a) efficient b) commission bias — acting on a
       wrong automated verdict without checking evidence c) fine at Tier 1 d) omission → **b**
    3. (choice) "Why does this course end on verifying AI instead of using it?" a) AI is bad b) you can
       only supervise AI triage if you can do triage without it — automation bias is the Tier-1 failure
       mode of the AI-SOC era c) it's tradition d) to save time → **b**
  - `hints.json`: L1 "Read failure-modes.md, then match each vignette to the one mode it shows. The verb
    matters: acting-on-wrong vs missing vs not-checking vs can't-without vs pre-deciding." L2 "Closing on
    the AI's say-so = commission; missing what it omitted = omission; not spot-checking a trusted tool =
    complacency; helpless without it = de-skilling; agreeing before reading = anchoring." L3 "q1
    commission; q2 omission; q3 complacency; q4 deskilling; q5 anchoring."
  - `recap.md` (3 lines): `Automation bias is over-trusting the machine: commission (acting on a wrong
    verdict), omission (missing what it didn't flag), complacency, de-skilling, and anchoring.` / `These
    are documented, predictable failure modes — naming them is the first defense.` / `You can only
    supervise AI triage if you can do triage without it; the rest of this phase proves you can.`
  - **`recall.json`** (phase opener; 5, non-gating; **[VERIFY-AT-BUILD]** — Phase 6 unbuilt, sourced from
    the map's Phase 6 lab list (§223–228); matches the parked L7.1 draft in `soc-p6-plan.md` L6.6):
    1. (text) "Pivoting follows join keys from user → host → process → ___." → **key `network`** —
       source **L6.1**.
    2. (text) "Before ordering events across hosts, normalize every timestamp to ___." → **key `utc`** —
       source **L6.2**.
    3. (choice) "The C2 beacon is on 1 host but the intrusion spans 4. Scope depends on:" a) the question
       asked b) severity c) the rule → **key a** — source **L6.3**.
    4. (text) "An escalation's required-elements list IS the checklist ___ triages it by (who?)." →
       **key `tier 2`** (accept `tier2`, `t2`) — source **L6.4**.
    5. (choice) "A confirmed DC compromise at 2am is communicated:" a) immediately to Tier 2 b) in the
       end-of-shift handoff c) to the user → **key a** — source **L6.5**.

**EVIDENCE SPEC**
```yaml
scenario: s7-bias
lab: L7.1
modes: [commission, omission, complacency, deskilling, anchoring]
cases:
  - {n: 1, mode: commission}
  - {n: 2, mode: omission}
  - {n: 3, mode: complacency}
  - {n: 4, mode: deskilling}
  - {n: 5, mode: anchoring}
emit: {reference: files/failure-modes.md, cases: files/mini-cases.md, answers_template: files/answers.template.txt}
answer_key: {q1: commission, q2: omission, q3: complacency, q4: deskilling, q5: anchoring}
verify: [each vignette maps to exactly one documented mode]
```

---

### L7.2 — VERIFY reps I — three AI triage summaries vs raw evidence; one is subtly wrong

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L7.2 | VERIFY reps I — three AI triage summaries vs raw evidence; one is subtly wrong | VERIFY | false | 20 |

Dir `tracks/soc/phases/p7/L7.2-verify-reps-1/`. **One concept:** verify a machine summary against raw
evidence — two are right, one is subtly wrong; find it and name the flaw.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s7-verify-1`, RAW): three `summaryN/` each with
  `ai-summary.md` + the `evidence/` bundle it summarizes:
  - **summary1** (M1 spray) — all claims grounded → **grounded**.
  - **summary2** (M2 macro) — one **contradicted** claim: "no persistence observed" while the evidence
    holds the Run key `CM-0311-0181` → **flawed / contradicted**.
  - **summary3** (M3 tunnel) — all claims grounded → **grounded**.
  - `verify-method.md` — static: cross-check every claim's cited id against evidence; confidence ≠
    correctness; look for what the summary *omits*.
  - `answers.template.txt`.
- **Learner task:** verify each summary; flag the wrong one and its flaw. Template + grammar:
  ```
  q1=   # summary1 verdict: grounded | flawed                                      -> grounded
  q2=   # summary2 verdict                                                          -> flawed
  q2f=  # summary2 flaw type (hallucinated|wrongpivot|ungrounded|contradicted)      -> contradicted
  q2e=  # the event.id that CONTRADICTS summary2's false claim                       -> cm-0311-0181
  q3=   # summary3 verdict                                                          -> grounded
  ```
- **Grading** (`check.sh`, §2.1/§2.1-verify): presence + normalize; anchored checks; `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L7.2", type:"VERIFY", objective:"Verify three AI triage summaries against raw
    evidence and identify the one that is subtly wrong and why", gate:false, est_minutes:20}`
  - `quiz.json`:
    1. (choice) "A confident, well-written AI summary is:" a) correct by definition b) a claim to verify
       against evidence — fluency is not accuracy c) always wrong d) unverifiable → **b**
    2. (choice) "summary2 says 'no persistence' but the Run key CM-0311-0181 is in evidence. This is:" a)
       fine b) a contradicted claim — the cited/available evidence opposes the summary c) a
       hallucination d) grounded → **b**
    3. (choice) "The hardest AI error to catch is the one that:" a) is obviously wrong b) is mostly
       right with one subtle, confident error — you must read the evidence to find it c) has no citations
       d) is short → **b**
  - `hints.json`: L1 "For each summary, check every claim against its evidence bundle — and check what
    the summary DOESN'T say. Two are fully grounded." L2 "summary2 is the wrong one: it claims no
    persistence, but the evidence has a Run-key event. That's a contradicted claim." L3 "q1 grounded; q2
    flawed / contradicted / cm-0311-0181; q3 grounded."
  - `recap.md` (3 lines): `Verify every AI summary against the evidence — two of three here are right,
    and the wrong one is confident and subtle.` / `The dangerous error contradicts the evidence quietly:
    'no persistence' while the Run key sits in the logs.` / `Read what the summary omits as carefully as
    what it asserts; confidence is not correctness.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s7-verify-1
lab: L7.2
summaries:
  - {n: 1, incident: M1, verdict: grounded}
  - {n: 2, incident: M2, verdict: flawed, flaw: contradicted, contradicting_id: CM-0311-0181, false_claim: "no persistence observed"}
  - {n: 3, incident: M3, verdict: grounded}
emit: {summaries: [files/summary1/, files/summary2/, files/summary3/], method: files/verify-method.md, answers_template: files/answers.template.txt}
answer_key: {q1: grounded, q2: flawed, q2f: contradicted, q2e: cm-0311-0181, q3: grounded}
verify: [grounded summaries' claims all cite present-and-supporting ids; summary2's Run key genuinely present]
```

---

### L7.3 — Directing AI in an investigation — evidence-first prompting; what AI is good and bad at mid-incident

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L7.3 | Directing AI in an investigation — evidence-first prompting; what AI is good and bad at mid-incident | DECODE | false | 15 |

Dir `tracks/soc/phases/p7/L7.3-directing-ai/`. **One concept:** direct AI with evidence-first prompts,
and know what it's good at (summarizing, correlating, drafting) vs bad at (inventing facts, verdicts
without evidence, real-time ground truth).

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s7-directing`, RAW):
  - `prompt-pairs.md` — 4 task pairs, each a weak prompt and an evidence-first prompt for the same goal
    (e.g. weak: "is this malicious?"; strong: "here are these 6 events by id — summarize the process
    tree and flag any claim you can't tie to an id").
  - `ai-tasks.md` — 5 mid-incident tasks to classify as good-for-AI or bad-for-AI.
  - `answers.template.txt`.
- **Learner task:** pick the better prompt per pair; classify each task. Template + grammar:
  ```
  # q1-q4: which prompt is evidence-first and safer? a | b
  q1=..q4=   -> (the evidence-first option per pair)
  # q5-q9: is this a GOOD or BAD use of AI mid-incident? good | bad
  q5=   # summarize a 200-line process tree into the parent-child chain   -> good
  q6=   # decide the final verdict with no evidence attached               -> bad
  q7=   # draft the escalation ticket from your confirmed findings         -> good
  q8=   # invent the attacker's next move as fact                          -> bad
  q9=   # correlate ids across conn/dns/ssl you paste in                   -> good
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; nine anchored checks; `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L7.3", type:"DECODE", objective:"Write evidence-first prompts and classify
    mid-incident tasks as good or bad uses of AI", gate:false, est_minutes:15}`
  - `quiz.json`:
    1. (choice) "An evidence-first prompt:" a) asks 'is this bad?' b) supplies the specific events/ids
       and asks the AI to summarize/correlate and flag anything it can't ground c) trusts the AI's
       memory d) is longer → **b**
    2. (choice) "AI is reliable mid-incident for:" a) inventing the verdict b) summarizing, correlating,
       and drafting from evidence YOU provide c) real-time ground truth d) replacing the analyst → **b**
    3. (choice) "AI is unreliable for:" a) formatting b) claims of fact you didn't give it and verdicts
       without attached evidence — it will confabulate confidently c) summarizing d) drafting → **b**
  - `hints.json`: L1 "The safer prompt supplies the evidence and asks the AI to ground every claim; the
    weak one asks for a conclusion with no evidence." L2 "Good AI uses transform evidence you provide
    (summarize, correlate, draft); bad uses ask it to originate facts or verdicts." L3 "q1-q4 the
    evidence-first option; q5 good; q6 bad; q7 good; q8 bad; q9 good."
  - `recap.md` (3 lines): `Direct AI with evidence-first prompts: give it the specific events and ask it
    to summarize, correlate, and flag anything it can't tie to an id.` / `AI is strong at transforming
    evidence you provide and weak at originating facts or verdicts — it confabulates confidently.` /
    `Keep the ground truth and the verdict yours; use the machine to go faster, never to decide.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s7-directing
lab: L7.3
prompt_pairs: [4 pairs; evidence-first option keyed per pair]
task_classes: {summarize-tree: good, verdict-no-evidence: bad, draft-ticket: good, invent-next-move: bad, correlate-ids: good}
emit: {pairs: files/prompt-pairs.md, tasks: files/ai-tasks.md, answers_template: files/answers.template.txt}
answer_key: {q1: "<ef>", q2: "<ef>", q3: "<ef>", q4: "<ef>", q5: good, q6: bad, q7: good, q8: bad, q9: good}
verify: [each pair has exactly one evidence-first option; task classes map to good/bad]
```

---

### L7.4 — VERIFY reps II — the hallucinated indicator, the wrong pivot, the ungrounded claim

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L7.4 | VERIFY reps II — the hallucinated indicator, the wrong pivot, the ungrounded claim (does every claim cite a real event ID?) | VERIFY | false | 20 |

Dir `tracks/soc/phases/p7/L7.4-verify-reps-2/`. **One concept (the course's thesis):** every AI claim
must cite an event id that exists in the evidence — catch the hallucinated id, the wrong pivot, and the
ungrounded claim.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s7-verify-2`, RAW): one `ai-summary.md` of the M2 incident with
  **5 numbered claims** + the `evidence/` bundle:
  - **c1** grounded — cites `CM-0311-0201` (macro exec), correct.
  - **c2** **hallucinated** — cites `CM-9999-9999` ("lateral movement to DC01") — that id **does not
    exist** in evidence.
  - **c3** grounded — cites `CM-0311-0181` (Run key), correct.
  - **c4** **wrongpivot** — cites real `CM-0311-0179` (beacon) but attributes it to **WKS-HD-03**, the
    wrong host (it's WKS-ACCT-07).
  - **c5** **ungrounded** — "the attacker exfiltrated 2GB" with **no citation** and no supporting event.
  - `answers.template.txt`.
- **Learner task:** verify each claim; produce the hallucinated id. Template + grammar:
  ```
  # per claim: grounded | flawed ; for flawed, flaw type
  q1=  -> grounded
  q2=  -> flawed    q2f=  -> hallucinated
  q3=  -> grounded
  q4=  -> flawed    q4f=  -> wrongpivot
  q5=  -> flawed    q5f=  -> ungrounded
  q_hall=  # the fabricated event id claim c2 cites (lowercase)   -> cm-9999-9999
  ```
- **Grading** (`check.sh`, §2.1/§2.1-verify): presence + normalize; anchored checks for the 5 verdicts,
  3 flaw types, and the hallucinated id; `ck_summary` last. `verify.py` guarantees `CM-9999-9999` is
  absent from evidence and c1/c3's ids are present.
- **Kit files:**
  - `meta.json`: `{id:"L7.4", type:"VERIFY", objective:"Apply the grounding contract — every AI claim
    must cite a real event id — and catch the hallucinated id, the wrong pivot, and the ungrounded
    claim", gate:false, est_minutes:20}`
  - `quiz.json`:
    1. (choice) "The grounding contract is:" a) AI must be polite b) every AI claim must cite an event
       id that exists in the evidence — no real id, no claim c) AI must be fast d) cite MITRE → **b**
    2. (choice) "A claim citing CM-9999-9999, which isn't in the evidence, is:" a) grounded b) a
       hallucination — a fabricated citation; reject the claim c) a wrong pivot d) fine if plausible → **b**
    3. (choice) "This grading rule matters because:" a) it's arbitrary b) it's the same grounding your
       own platform imposes on its agents — you're training the human half of the loop you designed c)
       MITRE says so d) it's easy → **b**
  - `hints.json`: L1 "For each claim, find its cited id in the evidence. No id (ungrounded), a
    non-existent id (hallucinated), or a real id used to claim the wrong thing (wrong pivot) all fail the
    grounding contract." L2 "c1/c3 check out. c2 cites an id that isn't in any evidence file. c4's id is
    real but the host is wrong. c5 cites nothing." L3 "q1 grounded; q2 flawed/hallucinated; q3 grounded;
    q4 flawed/wrongpivot; q5 flawed/ungrounded; q_hall cm-9999-9999."
  - `recap.md` (3 lines): `The grounding contract: every AI claim must cite an event id that exists in
    the evidence — no real id, no claim.` / `Three ways it fails: a fabricated id (hallucination), a real
    id used for the wrong connection (wrong pivot), and a confident claim with no citation (ungrounded).`
    / `This is the exact contract your architecture holds its own agents to — verifying it by hand is the
    skill the whole course was built to teach.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s7-verify-2
lab: L7.4
claims:
  - {c: 1, cites: CM-0311-0201, flaw: grounded}
  - {c: 2, cites: CM-9999-9999, flaw: hallucinated}      # id reserved, never in evidence
  - {c: 3, cites: CM-0311-0181, flaw: grounded}
  - {c: 4, cites: CM-0311-0179, flaw: wrongpivot, wrong_attr: WKS-HD-03, true_host: WKS-ACCT-07}
  - {c: 5, cites: none, flaw: ungrounded}
emit: {summary: files/ai-summary.md, evidence: files/evidence/, answers_template: files/answers.template.txt}
answer_key: {q1: grounded, q2: flawed, q2f: hallucinated, q3: grounded, q4: flawed, q4f: wrongpivot,
             q5: flawed, q5f: ungrounded, q_hall: cm-9999-9999}
verify: [CM-9999-9999 absent from ALL evidence; c1/c3 ids present-and-supporting; c4 id present but host mismatch]
```

---

### L7.5 — Override discipline — when to accept, when to override, and how your feedback improves the detections

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L7.5 | Override discipline — when to accept, when to override, and how your feedback improves the detections | DECODE | false | 15 |

Dir `tracks/soc/phases/p7/L7.5-override-discipline/`. **One concept:** accept the AI when evidence
supports it, override when it doesn't, and turn every override into feedback that improves detection.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s7-override`, RAW): `override-cases.md` — 5 cases pairing an AI
  verdict with the evidence; `feedback-loop.md` (static: override → tuning/label → better detection).
  `answers.template.txt`.
- **The 5 cases:**
  1. AI says malicious, evidence agrees (grounded TP) → **accept**.
  2. AI says benign, but a Run key is in evidence → **override** (accept-then-verify catches it).
  3. AI hallucinates an id to justify escalation → **override**.
  4. AI says FP on svc_backup BTP; evidence = authorized backup → **accept** (correct disposition, feed
     a tuning note anyway).
  5. AI's confident verdict has no cited evidence → **override** (ungrounded).
- **Learner task:** accept or override each, and name what feedback an override produces. Template:
  ```
  # q1-q5: accept | override
  q1= -> accept   q2= -> override   q3= -> override   q4= -> accept   q5= -> override
  q6=   # one word: an override that reveals a noisy/brittle rule should feed ___
  #        back to detection engineering (tuning|nothing|escalation)               -> tuning
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; six anchored checks; `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L7.5", type:"DECODE", objective:"Decide accept vs override on AI verdicts against
    evidence, and turn overrides into detection-improving feedback", gate:false, est_minutes:15}`
  - `quiz.json`:
    1. (choice) "You override an AI verdict when:" a) never b) the evidence doesn't support it — a
       missing citation, a contradiction, or a hallucinated id c) always d) it's slow → **b**
    2. (choice) "'The AI said benign' is:" a) a verdict b) not a verdict — you own the call, backed by
       evidence c) sufficient at Tier 1 d) an escalation → **b**
    3. (choice) "A good override does more than fix one alert; it:" a) closes faster b) feeds tuning/
       labels back so the detection (or the model) improves — closing the loop c) escalates d) nothing → **b**
  - `hints.json`: L1 "Accept when evidence supports the AI; override when it doesn't (no citation,
    contradiction, hallucination). Then ask what the override teaches the detection pipeline." L2 "Cases
    1 and 4 are supported (accept); 2, 3, 5 fail on evidence (override). Overrides that expose a noisy
    rule feed tuning." L3 "q1 accept; q2 override; q3 override; q4 accept; q5 override; q6 tuning."
  - `recap.md` (3 lines): `Accept the AI when the evidence supports it; override when it doesn't — a
    missing citation, a contradiction, or a hallucinated id.` / `'The AI said benign' is never a verdict;
    you own the call, and the evidence backs it.` / `Every override is feedback — tuning a brittle rule
    or labeling a model error closes the loop and makes the next shift's automation better.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s7-override
lab: L7.5
cases:
  - {n: 1, ai: malicious, evidence: supports, decision: accept}
  - {n: 2, ai: benign, evidence: runkey-present, decision: override}
  - {n: 3, ai: escalate, evidence: hallucinated-id, decision: override}
  - {n: 4, ai: fp, evidence: svc_backup-authorized, decision: accept}
  - {n: 5, ai: confident-verdict, evidence: none-cited, decision: override}
emit: {cases: files/override-cases.md, loop: files/feedback-loop.md, answers_template: files/answers.template.txt}
answer_key: {q1: accept, q2: override, q3: override, q4: accept, q5: override, q6: tuning}
verify: [each accept is evidence-supported; each override fails on a specific evidence gap]
```

---

### L7.6 — Capstone shift — a full segmented shift: alert queue + phish + one real incident, AI assist available, everything graded

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L7.6 | Capstone shift — a full segmented shift: alert queue + phish + one real incident, AI assist available, everything graded | TRIAGE | false | 20 (×3 segments) |

Dir `tracks/soc/phases/p7/L7.6-capstone-shift/`. **Integrative capstone:** a full shift in three
independently-saved segments — queue, phish, incident — with an AI assistant you must verify, not obey.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s7-capstone-shift`, RAW):
  - `queue/` — 6 alerts + evidence (reused verdicts) → `queue.answers` (6 verdicts).
  - `phish/` — 1 reported `.eml` + enrichment + a provided `ai-summary.md` (with a planted flaw) →
    `phish.answers` (verdict + the caught flaw).
  - `incident/` — one real incident bundle + `alert.json` → `incident.answers` (disposition + escalation
    flag + a cited event id).
  - `shift-brief.md` (the three segments, "resume any time"), `answers` templates per segment.
- **Learner task (three sittings, workspace persists via `lab resume`):**
  - **Segment queue:** verdict 6 alerts (tp|fp|btp).
  - **Segment phish:** verdict the email (phish|legit|spam) AND flag the AI summary's planted flaw
    (`q_flaw=` type) — passing requires **overriding** the AI.
  - **Segment incident:** disposition (tp) + escalation flag (y/n) + a cited event id.
- **Grading** (`check.sh`, §2.1, per-segment): grades whichever `*.answers` exist; reports per segment;
  all three required to fully pass; `ck_summary` last. The phish segment's flaw-catch is mandatory (the
  AI-verification wired into the capstone).
- **Kit files:**
  - `meta.json`: `{id:"L7.6", type:"TRIAGE", objective:"Work a full segmented shift — queue, phish,
    incident — with an AI assistant you verify rather than obey, everything graded", gate:false,
    est_minutes:20}`
  - `quiz.json`:
    1. (choice) "The phish segment ships an AI summary. Your job is to:" a) obey it b) verify it against
       evidence and override it if it's wrong — 'the AI said so' isn't a verdict c) ignore it d) escalate
       → **b**
    2. (choice) "The shift is segmented and independently saved so that:" a) it's harder b) a real shift
       can span three sittings — queue now, phish later, incident next — without losing progress c) it
       grades faster d) it's shorter → **b**
    3. (choice) "Everything is graded because the capstone proves you can:" a) use AI b) do the whole
       Tier-1 job — triage, phish, investigate, and verify the machine — end to end c) write reports d)
       memorize codes → **b**
  - `hints.json`: L1 "Do the segments in any order across any sittings; lab resume keeps your workspace.
    Fill queue.answers, phish.answers, incident.answers." L2 "Queue = the five questions per alert;
    phish = verdict + catch the AI summary's flaw (check its cited ids); incident = disposition +
    escalation + a cited id." L3 "Per-segment answers and the AI flaw type are listed here; override the
    AI where the evidence doesn't back it."
  - `recap.md` (3 lines): `The capstone is the whole job in three saved segments — a queue, a reported
    phish, and one real incident — everything graded.` / `The AI assistant is available but never
    trusted: you verify it against evidence and override it when it's wrong.` / `Segmented and
    resumable, a shift can span three sittings — the way a real one does.`
  - No `recall.json`.
  - **`## SECURITY ONION (OPTIONAL)`**: run the shift in the `cardinal-so` Hunt UI; flat-file graded.

**EVIDENCE SPEC**
```yaml
scenario: s7-capstone-shift
lab: L7.6
segments:
  queue:    {alerts: 6, verdicts: [tp/fp/btp reused canon]}
  phish:    {mail: reported.eml, verdict: phish, ai_summary_flaw: {type: contradicted, catch: q_flaw}}
  incident: {bundle: M2-full, disposition: tp, escalate: y, cite: cm-0311-0201}
emit: {queue: files/queue/, phish: files/phish/, incident: files/incident/, brief: files/shift-brief.md,
       answers_templates: [files/queue.answers.template, files/phish.answers.template, files/incident.answers.template]}
answer_key: {queue: "[6 verdicts]", phish: {verdict: phish, q_flaw: contradicted}, incident: {disp: tp, esc: y, cite: cm-0311-0201}}
verify: [each segment gradeable independently; phish AI summary flaw real; verdicts reconcile with course canon]
```

---

### L7.7 — Capstone gate: incident report + tuning recommendation — the analyst-to-detection-engineering handoff, complete

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L7.7 | Capstone gate: incident report + tuning recommendation — the analyst-to-detection-engineering handoff, complete | REPORT | true | 20 |

Dir `tracks/soc/phases/p7/L7.7-capstone-gate/`. **Terminal capstone (REPORT):** the final deliverable —
a complete incident report **and** a tuning recommendation, closing the analyst→detection-engineering
loop the whole course was built around.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s7-capstone-gate`, RAW): the full M2 incident bundle +
  enrichment + `report-template.md` (`## Summary / ## Scope / ## Timeline / ## Indicators (defanged) /
  ## ATT&CK / ## Verdict / ## Recommendation / ## Tuning Recommendation`) + `model-capstone.md` (shipped).
- **Learner task:** write `report.md` — the complete incident report (scope, timeline citing event ids,
  defanged indicators, ATT&CK, verdict, recommendation) **plus** a `## Tuning Recommendation` with a
  specific structured exclusion (the L4.6 `field:value` — e.g. tune the brittle rule, or suppress the
  benign case observed).
- **Grading** (`check.sh`, **REPORT rubric §2.3 + §2.2 tuning extension**): required elements (Scope,
  Timeline with ≥1 cited `cm-` id, Indicators-defanged, ≥1 real ATT&CK id, verdict, Recommendation,
  **Tuning Recommendation with a `field:value` exclusion**) + the **defang gate** (reject raw scheme/
  domain/IP); `ck_summary` last; quiz gates 3/3. On pass, points to `model-capstone.md` and prints the
  course-complete recap.
- **Kit files:**
  - `meta.json`: `{id:"L7.7", type:"REPORT", objective:"Write the complete incident report and a
    specific tuning recommendation — the analyst-to-detection-engineering handoff", gate:true,
    est_minutes:20}`
  - `quiz.json` (gates 3/3):
    1. "The capstone deliverable adds, beyond the escalation report, a:" a) screenshot b) tuning
       recommendation — the specific detection change your investigation justifies c) longer summary d)
       nothing → **b**
    2. "A good tuning recommendation is:" a) 'fix the rule' b) a specific exclusion or selector change
       (exclude host X on pattern Y; tie the rule to ancestry not a filename substring) c) 'disable it'
       d) a password reset → **b**
    3. "This handoff completes the loop because:" a) it's the last lab b) the analyst's findings become a
       concrete detection improvement — Tier 1 feeding the rule lifecycle, the pillar of the platform c)
       it's graded d) it's a report → **b**
  - `hints.json`: L1 "Write every section of report-template.md AND the Tuning Recommendation. The tuning
    rec is a specific field:value exclusion or selector fix your investigation justifies." L2 "Scope +
    timeline (cite an event id) + defanged IOCs + ATT&CK + verdict + recommendation + tuning (e.g. tie
    the Office-spawn rule to ancestry, or exclude the known-good backup job)." L3 "If the check fails: a
    missing section, no cited id in the timeline, a raw IOC, or a vague tuning rec. Compare to
    model-capstone.md after you pass."
  - `recap.md` (3 lines): `The capstone handoff is the full package: a scoped, timelined, defanged
    incident report AND a specific tuning recommendation.` / `The tuning rec turns your investigation
    into a concrete detection improvement — Tier 1 feeding the rule lifecycle, not just draining the
    queue.` / `Course complete: you triage, investigate, escalate, and verify the machine — the human
    half of the analyst-in-the-loop the whole platform is built around.`
  - **`recall.json`: none** — terminal gate; there is no Phase 8.
  - **`## SECURITY ONION (OPTIONAL)`**: assemble the report from the `cardinal-so` case; flat-file is the
    graded gate.
  - `model-capstone.md` — shipped worked example (defanged, cites ids, includes a tuning exclusion).

**EVIDENCE SPEC**
```yaml
scenario: s7-capstone-gate
lab: L7.7
bundle: M2-full-incident (all sources, reused ids)
required_report_elements: [scope, timeline(cited cm- id), indicators(defanged), attack_id, verdict,
                           recommendation, tuning_recommendation(field:value)]
defang_gate: [no raw http://, no raw c2.stonewick.example, no raw 203.0.113.66, no raw 198.51.100.71]
emit: {bundle: files/incident/, enrichment: files/enrichment/, template: files/report-template.md,
       model: files/model-capstone.md, key_block: check.sh}
answer_key:
  required_sections: [scope, timeline+cited_id, attack_id: t1059.001, verdict_token, recommendation,
                      tuning: "(cmdline:winword->powershell|host:srv-backup|path:securityawareness)", defanged_ioc]
  reject_raw: [http://, c2.stonewick.example, 203.0.113.66, 198.51.100.71]
verify: [model-capstone passes rubric+defang gate, cites >=1 real id, and carries a field:value tuning exclusion]
```

---

## 5. Build order (one session, Phase Builder protocol)

Prerequisite: `soc-p0…p6` tagged.

1. **Generator extensions** — `ai_summary` emitter + the **grounding-contract `verify.py` invariant**
   (hallucinated ids provably absent, grounded ids present-and-supporting); reserve the `CM-9999-*`
   never-used range; self-test on a throwaway scenario; confirm the REPORT+tuning rubric passes the two
   new model reports.
2. **p7 scenarios** in map order — `s7-bias`, `s7-verify-1`, `s7-directing`, `s7-verify-2`, `s7-override`,
   `s7-capstone-shift`, `s7-capstone-gate` → L7.1…L7.7. Build lab by lab (§2.1/§2.1-verify for VERIFY;
   §2.3+tuning for L7.7); self-test each (fail + pass, real outputs pasted; VERIFY negatives = marking a
   grounded claim flawed and vice-versa; the capstone-shift per-segment; the L7.7 raw-IOC and
   missing-tuning negatives); commit per lab (`soc L7.x: <title>`), one branch+PR+merge each via an
   isolated worktree.
3. **Capstone (L7.6/L7.7)** — verify the shift grades each segment independently and the phish segment's
   AI flaw must be caught; confirm L7.7 rejects a report missing the tuning rec and passes the model.
   **No next-opener recall to draft (terminal).**
4. **Close-out (track-complete):** `verify.py` green across `s7-*` (grounding contract); lint/shellcheck/
   acceptance green (extend `acceptance.sh` with a P7 section — 7 labs, pass + negative each; VERIFY and
   REPORT negatives as above); `lab status`/`resume` render p7; update `planned_execution.md` (mark the
   soc track done); tag `soc-p7`. **The SOC Analyst Lab is complete (52 labs, Phases 0–7).** Gate per lab.

## 6. Acceptance checklist mapping (PROMPTS.md §174–181)

- **Lab count/titles/types match the map** — §4 is map-exact (7 labs; DECODE/VERIFY/DECODE/VERIFY/
  DECODE/TRIAGE/REPORT; capstone shift L7.6, capstone gate L7.7).
- **Every lab self-tested, real outputs pasted** — build-order step 2; VERIFY + REPORT negatives.
- **shellcheck clean** — §2.1/§2.1-verify/§2.3 patterns; no `disable=`.
- **VERIFY labs' planted flaws specified in scenario.yaml, incl. a nonexistent-event-id claim** — §2
  `ai_summary` + the grounding-contract `verify.py` invariant (L7.2 contradicted, L7.4 hallucinated/
  wrongpivot/ungrounded).
- **Gate integrative** — L7.7 (terminal; no next-opener recall — there is no Phase 8).
- **Evidence generated + consistency-verified** — grounding contract + inherited defang/coherence checks.
- **`lab status`/`resume`; capstone segmented + independently saved** — L7.6 per-segment answers.
- **Flat-file first / SO overlay** — all 7 grade on `files/`; SO ungraded on L7.6/L7.7 only.
- **REPORT enforces defanging + tuning handoff** — §2.3 defang gate + L7.7's tuning-exclusion element.

---

## Session control (PLAN-AHEAD — final phase)

Phase 7 is the **last** phase of the plan-ahead pass (2→3→4→5→6→7), commit-and-continue (memory
`feedback_plan_ahead_commit_and_continue`). **Phases 2–6 planned and merged** (`soc-p2` #254, `soc-p3`
#260, `soc-p4` #261, `soc-p5` #265, `soc-p6` #268). Nothing built. Commit goes through an **isolated git
worktree** (shared working tree has concurrent writers). **After Phase 7 merges, every remaining soc
phase has a plan file on `main` and this plan-ahead session is complete** — the soc track is fully
planned (Phases 0–7), ready for phase-by-phase BUILD sessions. Plans only; no building, no tags, no
`planned_execution.md` edits.
