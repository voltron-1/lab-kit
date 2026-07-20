# SOC Track — Phase 6 Build Plan (v1)

**Mode:** plan only — produced 2026-07-20 per Phase Builder step 3 (PROMPTS.md Prompt 2),
inside a PLAN-AHEAD session that plans every remaining soc phase one at a time.
**This document is the deliverable for `docs/plans/soc-p6-plan.md`** (saved there verbatim on merge).
**Binding content spec:** `docs/curriculum/soc-analyst-lab-curriculum-v1.md` — Phase 6 (§6, lines 218–230).
**Binding mechanical spec:** `docs/kit-contracts.md` + the soc quality gates in `PROMPTS.md`.
**Predecessor plans (inherited):** `soc-p01/p2/p3/p4/p5-plan.md` — universe, generator, §2.1 grading,
§2.2 ids, defang regex-escape recipe, enrichment mocks, and the **§2.3 REPORT-lab grading contract**
(rubric + defang gate + model report) established in Phase 5. Extended, not re-derived.
**Scope:** 6 labs — L6.1–L6.6 (gate L6.6) — plus a `tools/genevidence/` **multi-source investigation
bundle** emitter and the first **PIVOT-lab grading pattern**.

## 0. Ground rules this plan follows

- Lab list is **map-exact** (§223–228): ids, titles, types (PIVOT/PIVOT/HUNT/REPORT/DECODE/REPORT),
  gate on L6.6 — no deviations.
- Evidence **generated, never hand-written**; this phase mostly **re-stitches the existing Coppermine
  incident** (M1/M2/M3/M4 + lateral + Linux) into cross-source bundles, so ids/uids/ProcessGuids/
  timestamps stay consistent with Phases 1–5 (the whole point of investigation is one coherent story).
- Grades **offline in the check fence** (§2.1 for PIVOT/HUNT/DECODE; §2.3 rubric+defang for the two
  REPORT labs). Raw evidence never defanged; prose, keys, learner answers and reports **do** defang.
- **Flat-file first**; SO overlay ungraded on L6.6 only.
- ADHD contract: one concept per lab, est 10–20 min; L6.4/L6.6 (REPORT) and L6.2 (timeline) are the
  pacing risks — flagged for honest self-test.

## 1. Universe: the investigation view (no new attack, one coherent incident)

Additive to `soc-p01-plan.md` §1; single source `universe.yaml`. Phase 6 introduces **no new attacker
behavior** — it assembles the full **"Coppermine March intrusion"** from motifs already built, so the
learner investigates one real story:

- **The intrusion, end to end (all reused ids):** M1 spray → m.reyes credential compromise
  (`CM-0311-0142`); M2 phish → WKS-ACCT-07 macro exec (`CM-0311-0201`), beacon (`CM-0311-0179`/network
  `CM-0311-0501`), Run-key persistence (`CM-0311-0181`), staging to FS01 (L1.6 beat G); lateral → rogue
  admin `supportadmin` on FS01 (`CM-0311-0244`/`0245`); M3 → DNS tunnel from WKS-ENG-12
  (`CM-0312-0310…`); M4 + Linux → WEB01 root brute-force (`CM-0312-0455`), `websvc` UID-0 useradd
  (`CM-0312-0630`), cron persistence (`CM-0312-0457`).
- **Scope truth (pinned in `universe.yaml`, so L6.3 has a defensible answer):** the M2 macro/beacon
  affected **exactly one** workstation (WKS-ACCT-07); the credential compromise touched **one** account
  that then enabled the FS01 rogue admin (a **second** host); M3 is a **separate** host (WKS-ENG-12);
  the Linux foothold is WEB01 (a **fourth** host). "Scope of the M2 beacon indicator" = 1 host; "scope
  of the intrusion" = 4 hosts. The distinction is the L6.3 lesson.
- **Timestamp spread (for L6.2):** the bundle deliberately carries the three renderings from L1.2 —
  local-syslog (WEB01), Windows SystemTime UTC, ECS `@timestamp` — plus zeek ISO `ts`, so normalization
  to UTC is required before ordering. `event.ingested` ≠ occurrence (arrival out of order) is reused.
- **Escalation/comms facts (for L6.5):** the L0.3 SOC charter (tier duties, escalation triggers, shift
  handoff) is the reference; the analyst-to-Tier-2 package elements are the L6.4 rubric.

## 2. Generator extensions — `tools/genevidence/`

Prerequisite: `soc-p0…p5` tagged. Phase 6 adds one emitter + two verify invariants:

1. **`investigation_bundle`** — assemble a single `case/` tree pulling the relevant conn/dns/ssl/
   sysmon/security/auth rows for one incident from the shared registry, preserving uids, ProcessGuids,
   and `event.id`s **byte-identical** to how earlier phases emitted them (so a pivot in L6.1 lands on
   the same `CM-0311-0201` the learner may have seen in L1.4/L3.2). Emits a `timeline-key` (the true
   UTC-ordered id sequence) and a `scope-key` (the affected-host set) into check.sh.
2. **`verify.py` additions:** (a) **timeline coherence** — the `timeline-key` order equals the rows
   sorted by true `@timestamp`/UTC-normalized `ts`, and `event.ingested` is *not* used for ordering;
   (b) **scope coherence** — the `scope-key` host set equals the distinct hosts carrying the pivoted
   indicator in the bundle; (c) inherited no-defang-in-raw / no-fang-in-prose + REPORT defang gate.

## 2.1 PIVOT-lab grading pattern (NEW — binding for L6.1, L6.2)

PIVOT labs grade a **reconstructed chain / ordered timeline** as flag-style tokens via the §2.1
canonical pattern — no new machinery:
- **Chain answers** (L6.1): one `qN=` per hop (host, process ProcessGuid/event id, C2 dst defanged,
  persistence artifact, next host), each an anchored `assert_file_contains` from a generated key.
- **Ordering answers** (L6.2): `q_order=` a comma-joined sequence of event ids (or exercise labels)
  in true UTC order; keyed to the generator's `timeline-key`. A single anchored exact-line match on the
  normalized sequence (no spaces), plus per-question checks for the first/last event and the UTC
  conversion of one local timestamp (reusing L1.2's mechanic).

## 2.2 (inherited) REPORT contract — unchanged from Phase 5 §2.3

L6.4 and L6.6 use the Phase-5 REPORT rubric: required elements (scope, timeline, indicators-defanged,
ATT&CK id, verdict, recommendation) + the **defang gate** (`assert_file_not_contains` raw scheme/
domain/IP) + a shipped `model-report.md` printed on pass. L6.4's required-element set **is** the Tier-2
checklist (map job hook), so its rubric is the canonical escalation-package spec the gate (L6.6) reuses.

## 3. Decisions & flagged deviations (approve/veto with the plan)

1. **Phase 6 introduces no new attack — it investigates the existing one.** This is deliberate: the map
   frames Phase 6 as "from alert-handler to investigator," and investigation is only meaningful over a
   coherent, already-seen incident. Every id/uid/ProcessGuid is reused byte-identical. Veto if you'd
   rather a fresh, unseen incident (costs cross-phase continuity and a lot of new evidence).
2. **Scope has two correct numbers, and the lab grades both.** "Scope of the beacon indicator" (1 host)
   vs "scope of the intrusion" (4 hosts) — L6.3 keys each separately so the learner learns the question
   determines the answer. Veto to grade only one.
3. **L6.4 and L6.6 are both REPORT** (map). To keep them distinct: L6.4 grades the **escalation package
   for a scoped, pre-investigated incident** (you're handed the findings, you write the ticket); L6.6 is
   the **full loop** (one alert → you pivot/timeline/scope yourself → write the escalation). Both use
   §2.3; L6.6's rubric is tighter (requires scope + timeline + a cited event id in the timeline).
4. **L6.5 (comms) graded as audience+timing tokens, not prose** — deterministic and checkable; a model
   handoff note ships for calibration. Veto to make it a REPORT.
5. **SO overlay ungraded on L6.6 only.** Flat-file always graded.
6. **Defang enforced** in every answer and both reports (§2 recipe + §2.3 gate).

## 3.5 Self-review corrections applied

- **Pivot must land on stable ids, or L6.1 breaks across phases.** Fixed: `investigation_bundle` reuses
  registry ids byte-identical; `verify.py` asserts the pivoted `CM-0311-0201`/`0179`/`0181` match the
  canonical rows, not freshly minted ones.
- **Timeline order must be unambiguous.** If two events share a timestamp, ordering is undecidable.
  Fixed: the L6.2 bundle uses distinct UTC instants for every keyed event; where two are truly
  simultaneous they're keyed as an accepted alternation. `event.ingested` is present as the *trap*
  (arrival order ≠ occurrence) and is explicitly not the key.
- **Scope query must actually separate 1 from 4.** Fixed: the beacon indicator (203.0.113.66:443 SNI
  c2.stonewick.example) appears on exactly one host in the bundle; the *intrusion* spans four via
  distinct indicators — the learner runs a per-indicator host count, and the key reflects the emitted
  distinct-host sets.
- **REPORT labs must not be gameable by dumping the raw evidence.** The defang gate already fails a raw
  IOC; additionally L6.6 requires a **cited event id inside the Timeline section**, so a report has to
  reference the investigation, not just restate the alert. Model report passes; a raw-evidence dump
  fails the defang gate.
- **L6.5 audience/timing must be defensible against the charter.** Fixed: each comms case maps to an
  L0.3 charter rule (immediate escalation triggers vs routine/handoff), so "immediate to Tier 2" vs
  "note in handoff" is grounded, not taste.

---

## 4. Phase 6 — labs

### L6.1 — Pivoting — one indicator to the full story: user → host → process → network

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L6.1 | Pivoting — one indicator to the full story: user → host → process → network | PIVOT | false | 20 |

Dir `tracks/soc/phases/p6/L6.1-pivoting/`. **One concept:** start from one indicator and pivot through
the joins — user → host → process → network → persistence — to reconstruct the story.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s6-pivot`, RAW; the M2 investigation bundle):
  - `case/security.json`, `case/sysmon.json`, `case/zeek/{conn,dns,ssl}.log`, `case/entra-signin.json`
    — the M2 chain across sources, reused ids/uids/ProcessGuids.
  - `starting-indicator.txt` — the single seed: `alert CM-A-601 — user m.reyes flagged (spray success)`.
  - `pivot-map.md` — static: the join keys (user→logon `source.ip`/host; host→Sysmon ProcessGuid tree;
    process→Sysmon-3/zeek `uid` network; network→dns/ssl SNI; host→Run key persistence).
  - `answers.template.txt`.
- **Learner task:** pivot from m.reyes outward; answer each hop. Template + grammar:
  ```
  q1=   # the host m.reyes's compromised session landed on (from the exec)        -> wks-acct-07
  q2=   # event.id of the malicious process spawn on that host                     -> cm-0311-0201
  q3=   # the C2 destination the process beaconed to — DEFANGED                     -> c2.stonewick[.]example
  q4=   # the persistence artifact registry leaf set on that host                   -> onedriveupd
  q5=   # the NEXT host reached via the compromised account (lateral)               -> fs01
  q6=   # event.id of the rogue admin account creation on that next host            -> cm-0311-0244
  ```
- **Grading** (`check.sh`, §2.1/§2.1-pivot): presence + normalize; six anchored checks (q3 defanged);
  `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L6.1", type:"PIVOT", objective:"Pivot from one indicator through user→host→
    process→network→persistence→lateral to reconstruct the incident", gate:false, est_minutes:20}`
  - `quiz.json`:
    1. (choice) "Pivoting means:" a) guessing b) following join keys (user, host, ProcessGuid, uid, IP)
       from one indicator to the connected evidence c) closing the alert d) escalating → **b**
    2. (choice) "From a compromised USER, your first pivot is usually to:" a) the internet b) the
       host(s) and session(s) that credential touched c) the CFO d) the firewall → **b**
    3. (choice) "Why reconstruct the whole chain instead of verdicting the first alert?" a) you
       shouldn't b) one alert is one beat; scope, persistence, and lateral movement change the response
       entirely c) it's faster d) Tier 2 requires it → **b**
  - `hints.json`: L1 "Follow the joins in pivot-map.md: user → the logon's host, host → its Sysmon
    process tree, process → its network (uid/Sysmon-3), host → its Run key." L2 "m.reyes's exec is on
    WKS-ACCT-07 (CM-0311-0201); it beacons to the C2 (defang it) and sets a Run key; the same account
    then creates an admin on FS01." L3 "q1 wks-acct-07; q2 cm-0311-0201; q3 c2.stonewick[.]example; q4
    onedriveupd; q5 fs01; q6 cm-0311-0244."
  - `recap.md` (3 lines): `Pivoting turns one indicator into the whole story by following join keys:
    user→host, host→process (ProcessGuid), process→network (uid), host→persistence.` / `One alert is a
    single beat; the pivot reveals scope, persistence, and lateral movement the alert never mentioned.`
    / `The compromised credential is the thread — follow it to the second host, and the incident is
    bigger than the queue showed.`
  - **`recall.json`** (phase opener; 5, non-gating; **[VERIFY-AT-BUILD]** — Phase 5 unbuilt, sourced from
    the map's Phase 5 lab list (§207–212); matches the parked L6.1 draft in `soc-p5-plan.md` L5.6):
    1. (choice) "The Received chain reads which way to find the origin?" a) bottom-up b) top-down c) by
       date → **key a** — source **L5.1**.
    2. (text) "`xn--…` domains are encoded in ___." → **key `punycode`** — source **L5.2**.
    3. (text) "Extensions lie; what gives an attachment's true type? (two words)" → **key `magic bytes`**
       (accept `file`, `magic`) — source **L5.3**.
    4. (text) "You verdict a sample from a sandbox report without ___ it." → **key `running`** (accept
       `executing`, `touching`) — source **L5.4**.
    5. (choice) "A reported email that passes auth from an allowlisted vendor is ___." a) legit b) phish
       c) spam → **key a** — source **L5.5**.

**EVIDENCE SPEC**
```yaml
scenario: s6-pivot
lab: L6.1
seed: {indicator: user m.reyes, alert: CM-A-601}
chain:  # all reused ids
  - {hop: host, value: WKS-ACCT-07}
  - {hop: process, id: CM-0311-0201}
  - {hop: network, dst: c2.stonewick.example}
  - {hop: persistence, artifact: OneDriveUpd, id: CM-0311-0181}
  - {hop: lateral-host, value: FS01}
  - {hop: rogue-admin, id: CM-0311-0244}
emit: {case: files/case/, seed: files/starting-indicator.txt, pivot_map: files/pivot-map.md, answers_template: files/answers.template.txt}
answer_key: {q1: wks-acct-07, q2: cm-0311-0201, q3: c2.stonewick[.]example, q4: onedriveupd, q5: fs01, q6: cm-0311-0244}
verify: [pivoted ids byte-identical to registry canon; chain joins resolve in the bundle]
```

---

### L6.2 — Timeline building — normalize timestamps, order events, UTC everywhere

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L6.2 | Timeline building — normalize timestamps, order events, UTC everywhere | PIVOT | false | 20 |

Dir `tracks/soc/phases/p6/L6.2-timeline/`. **One concept:** normalize every timestamp to UTC, ignore
arrival order, and produce the true event sequence.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s6-timeline`, RAW): the M2 incident's key events across three
  renderings (reusing L1.2's mechanic):
  - `raw-syslog.txt` — WEB01 local-time lines (CDT, no year/tz) for the Linux foothold beats.
  - `windows.json` — Windows SystemTime UTC for the endpoint beats.
  - `ecs.jsonl` — ECS `@timestamp` (true UTC) + `event.ingested` (arrival, out of order) for 7 keyed
    incident events e1..e7 (macro exec, beacon, Run key, spray success, rogue admin, tunnel start,
    Linux root SSH) with `labels.exercise_id` and `event.id`.
  - `answers.template.txt`.
- **Learner task:** convert local → UTC, order by occurrence. Template + grammar:
  ```
  q1=   # UTC instant of the WEB01 syslog "Accepted password for root" (ISO lower) -> 2026-03-12t20:15:33z
  q_order=  # e1..e7 in true UTC chronological order, comma-joined, no spaces        -> <timeline-key>
  q2=   # the event.id of the EARLIEST attacker action in the window                 -> cm-0311-0142
  q3=   # which field must you NEVER order by (arrival, not occurrence)?             -> event.ingested
  q4=   # UTC offset of the WEB01 syslog collector during the scenario week          -> -05:00
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks; `q_order` an exact-line match
  on the normalized sequence from the generated `timeline-key`; `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L6.2", type:"PIVOT", objective:"Normalize mixed-format timestamps to UTC and
    order incident events by true occurrence, not arrival", gate:false, est_minutes:20}`
  - `quiz.json`:
    1. (choice) "Two events: `@timestamp 14:00Z`, `event.ingested 14:04Z`. It happened at:" a)
       @timestamp — occurrence b) event.ingested — arrival c) later of the two d) neither → **a**
    2. (choice) "Classic syslog `Mar 12 15:15:33` (Duluth) converts to UTC by:" a) doing nothing b)
       adding 5 hours (CDT is UTC−05:00) → 20:15:33Z c) subtracting 5 d) it's already UTC → **b**
    3. (choice) "Why UTC everywhere in the timeline?" a) style b) one clock orders events from hosts in
       any timezone without conversion errors c) SIEM requires it d) local is illegal → **b**
  - `hints.json`: L1 "Convert the WEB01 syslog line to UTC first (CDT = UTC−05:00, add 5h), then order
    by @timestamp — never by event.ingested." L2 "The spray success is the earliest attacker action;
    build the e1..e7 order by @timestamp only." L3 "q1 2026-03-12t20:15:33z; q_order = the UTC order
    (see timeline-key); q2 cm-0311-0142; q3 event.ingested; q4 -05:00."
  - `recap.md` (3 lines): `Normalize every timestamp to UTC before you order anything — local syslog has
    no year or offset, Windows and ECS are already UTC.` / `Order by occurrence (@timestamp), never by
    arrival (event.ingested) — ingestion lag scrambles the sequence.` / `The timeline is the spine of the
    escalation; get the order right and the story tells itself.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s6-timeline
lab: L6.2
events:  # e1..e7 with true UTC @timestamp; event.ingested deliberately out of order
  - {label: e4, id: CM-0311-0142, t: 2026-03-11T14:22:31Z, beat: spray-success}     # earliest
  - {label: e1, id: CM-0311-0201, t: 2026-03-11T15:41:07Z, beat: macro-exec}
  - {label: e2, id: CM-0311-0179, t: 2026-03-11T15:46:02Z, beat: beacon}
  - {label: e3, id: CM-0311-0181, t: 2026-03-11T15:46:35Z, beat: runkey}
  - {label: e5, id: CM-0311-0244, t: 2026-03-11T16:12:07Z, beat: rogue-admin}
  - {label: e6, id: CM-0312-0310, t: 2026-03-12T09:00:00Z, beat: tunnel}
  - {label: e7, id: CM-0312-0455, t: 2026-03-12T20:15:33Z, beat: web01-root-ssh}    # syslog local 15:15:33 CDT
emit: {syslog: files/raw-syslog.txt, windows: files/windows.json, ecs: files/ecs.jsonl, answers_template: files/answers.template.txt}
answer_key:
  q1: 2026-03-12t20:15:33z
  q_order: e4,e1,e2,e3,e5,e6,e7
  q2: cm-0311-0142
  q3: event.ingested
  q4: -05:00
verify: [timeline-key == rows sorted by @timestamp; event.ingested NOT used; syslog local+5h == UTC]
```

---

### L6.3 — Scoping — one host or ten? The queries that answer it

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L6.3 | Scoping — one host or ten? The queries that answer it | HUNT | false | 20 |

Dir `tracks/soc/phases/p6/L6.3-scoping/`. **One concept:** scope is a query, not a guess — count the
distinct hosts carrying an indicator, and know that the beacon's scope and the intrusion's scope are
different questions.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s6-scoping`, RAW): a multi-host bundle:
  - `zeek/conn.log`, `zeek/ssl.log` — beacon rows to 203.0.113.66 (SNI c2.stonewick.example) from
    exactly ONE host (WKS-ACCT-07); benign traffic from others.
  - `security.json`, `sysmon.json`, `auth.log` — the four affected hosts' incident events (WKS-ACCT-07,
    FS01, WKS-ENG-12, WEB01) plus many unaffected hosts' benign activity.
  - `scope-method.md` — static: distinct-host counting per indicator; the difference between an
    indicator's scope and an incident's scope.
  - `answers.template.txt`.
- **Learner task:** query scope; answer. Template + grammar:
  ```
  q1=   # how many hosts beaconed to the C2 IP? (indicator scope, integer)        -> 1
  q2=   # the one beaconing host                                                   -> wks-acct-07
  q3=   # how many DISTINCT hosts are involved in the whole intrusion? (integer)   -> 4
  q4=   # comma-joined lowercase host list of the intrusion (any order accepted
  #        via generator alternation)                                              -> fs01,web01,wks-acct-07,wks-eng-12
  q5=   # is the C2 beacon CONTAINED to one host or SPREAD? (contained|spread)      -> contained
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks; q4 keyed as a sorted
  comma-joined set (normalize sorts the learner's list before matching, or generator emits an
  alternation of accepted orderings — build note: sort in the normalize step); `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L6.3", type:"HUNT", objective:"Answer scope with queries — count distinct hosts
    per indicator, and distinguish an indicator's scope from the incident's scope", gate:false,
    est_minutes:20}`
  - `quiz.json`:
    1. (choice) "How do you answer 'one host or ten'?" a) intuition b) count distinct hosts carrying the
       indicator with a query — sort | uniq the source hosts c) ask Tier 2 d) check severity → **b**
    2. (choice) "The C2 beacon is on one host but the intrusion spans four. Scope is:" a) one number b)
       relative to the question — the beacon indicator's scope is 1, the incident's is 4 c) always the
       larger d) always the smaller → **b**
    3. (choice) "Getting scope wrong (calling a 4-host intrusion 'one host') causes:" a) nothing b)
       under-scoped containment — the attacker keeps the other footholds c) over-escalation d) a tuning
       note → **b**
  - `hints.json`: L1 "For the beacon: which hosts have a conn/ssl row to 203.0.113.66? `awk` the source
    host, sort | uniq. For the incident: which hosts have ANY attacker event?" L2 "Exactly one host
    beacons (WKS-ACCT-07); four hosts carry attacker activity (add FS01 rogue admin, WKS-ENG-12 tunnel,
    WEB01 root SSH)." L3 "q1 1; q2 wks-acct-07; q3 4; q4 the four hosts; q5 contained."
  - `recap.md` (3 lines): `Scope is a query, not a hunch — count the distinct hosts carrying an
    indicator with sort | uniq.` / `An indicator's scope and an incident's scope are different questions:
    the beacon is on one host, the intrusion spans four.` / `Under-scoping leaves the attacker footholds
    the containment misses — the query is what makes the number defensible.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s6-scoping
lab: L6.3
scope_truth:
  beacon_indicator: {ioc: 203.0.113.66, hosts: [WKS-ACCT-07]}          # 1
  intrusion: {hosts: [WKS-ACCT-07, FS01, WKS-ENG-12, WEB01]}           # 4
emit: {zeek: files/zeek/, security: files/security.json, sysmon: files/sysmon.json, auth: files/auth.log,
       method: files/scope-method.md, answers_template: files/answers.template.txt}
answer_key: {q1: "1", q2: wks-acct-07, q3: "4", q4: "fs01,web01,wks-acct-07,wks-eng-12", q5: contained}
verify: [scope-key host sets == emitted distinct-host sets per indicator; beacon on exactly one host]
```

---

### L6.4 — Writing the ticket — the escalation package: scope, timeline, indicators, technique, recommendation

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L6.4 | Writing the ticket — the escalation package: scope, timeline, indicators, technique, recommendation | REPORT | false | 20 |

Dir `tracks/soc/phases/p6/L6.4-writing-the-ticket/`. **One concept:** the escalation package Tier 2
triages by — scope, timeline, indicators (defanged), ATT&CK technique, recommendation. You're handed
the findings; you write the ticket.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s6-ticket`, RAW): `findings.md` (the pre-investigated M2
  incident: scope = 2 hosts, timeline of the M2 beats, indicators list, techniques), `ticket-template.md`
  (sections `## Summary / ## Scope / ## Timeline / ## Indicators (defanged) / ## ATT&CK / ## Verdict /
  ## Recommendation`), `model-ticket.md` (shipped, shown on pass), enrichment mocks for the IOCs.
- **Learner task:** write `report.md` — the escalation ticket — from the findings, every section filled,
  every IOC defanged.
- **Grading** (`check.sh`, **REPORT rubric §2.2/§2.3**): required elements — a `## Scope` section, a
  `## Timeline` section, ≥1 real ATT&CK id (`t1059.001`), a verdict token, a `## Recommendation`
  section, ≥1 defanged IOC — plus the **defang gate** (reject raw `http://[a-z]`, `c2.stonewick.example`,
  `203.0.113.66`); `ck_summary` last. On pass, points to `model-ticket.md`.
- **Kit files:**
  - `meta.json`: `{id:"L6.4", type:"REPORT", objective:"Write the escalation ticket Tier 2 triages by:
    scope, timeline, defanged indicators, ATT&CK, verdict, recommendation", gate:false, est_minutes:20}`
  - `quiz.json`:
    1. (choice) "L6.4's required-elements list is:" a) a suggestion b) literally the checklist Tier 2
       triages your ticket by — a great investigation with a bad writeup is operationally a bad
       investigation c) optional d) for management → **b**
    2. (choice) "The Scope line in an escalation tells Tier 2:" a) the severity b) how many hosts/
       accounts are affected — what to contain c) the rule name d) the time → **b**
    3. (choice) "A recommendation section should:" a) be omitted b) state concrete next actions (isolate
       host X, reset account Y, block IOC Z, hunt for the beacon) c) restate the alert d) hedge → **b**
  - `hints.json`: L1 "Fill every section of ticket-template.md from findings.md; the required sections
    are Scope, Timeline, Indicators (defanged), ATT&CK, Verdict, Recommendation." L2 "Scope = affected
    hosts/accounts; Timeline = the ordered beats; Indicators = every IOC defanged; ATT&CK = the
    techniques (T1059.001, T1547.001); Recommendation = concrete containment actions." L3 "If the check
    fails on defang, find any raw http:// or unbracketed domain/IP. Compare to model-ticket.md after you
    pass."
  - `recap.md` (3 lines): `The escalation ticket is the deliverable Tier 2 acts on — scope, timeline,
    defanged indicators, ATT&CK, verdict, recommendation, every time.` / `Its required elements ARE the
    checklist Tier 2 triages by; a great investigation with a bad writeup is operationally a bad
    investigation.` / `Concrete recommendations (isolate, reset, block, hunt) turn your findings into
    the responder's next actions.`
  - No `recall.json`.
  - `model-ticket.md` — shipped worked example (defanged).

**EVIDENCE SPEC**
```yaml
scenario: s6-ticket
lab: L6.4
findings: {incident: M2, scope_hosts: [WKS-ACCT-07, FS01], timeline: [macro-exec, beacon, runkey, rogue-admin],
           indicators: [c2.stonewick.example, 203.0.113.66, invoice_2026-03.docm, OneDriveUpd],
           techniques: [T1566.001, T1059.001, T1547.001, T1136.001]}
required_report_elements: [scope, timeline, indicators(defanged), attack_id, verdict, recommendation]
defang_gate: [no raw http://, no raw c2.stonewick.example, no raw 203.0.113.66]
emit: {findings: files/findings.md, template: files/ticket-template.md, model: files/model-ticket.md,
       enrichment: files/enrichment/, key_block: check.sh}
answer_key: {required_sections: [scope, timeline, attack_id: t1059.001, verdict_token, recommendation, defanged_ioc],
             reject_raw: [http://, c2.stonewick.example, 203.0.113.66]}
verify: [model-ticket passes its own rubric + defang gate]
```

---

### L6.5 — Incident communication — what you say, to whom, when; the shift handoff

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L6.5 | Incident communication — what you say, to whom, when; the shift handoff | DECODE | false | 15 |

Dir `tracks/soc/phases/p6/L6.5-incident-comms/`. **One concept:** match the message to the audience and
the timing, and know what belongs in a shift handoff.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s6-comms`, RAW): `comms-cases.md` (four mini-scenarios) +
  `handoff-template.md` (open investigations, pending escalations, watch-items) + `charter-comms.md`
  (static, from L0.3: who owns what, escalation triggers). `answers.template.txt`.
- **The four cases:**
  1. confirmed domain-controller compromise at 02:30 → **tier2**, **immediate**.
  2. a low-sev BTP you closed with a tuning note → **handoff**, **eos** (end of shift).
  3. a user asks about their quarantined adware file → **user**, **routine**.
  4. an in-progress investigation you can't finish this shift → **handoff**, **eos** (with watch-items).
- **Learner task:** for each case, give audience + timing. Template + grammar:
  ```
  # audience vocab: tier2 | user | mgmt | handoff   ; timing vocab: immediate | eos | routine
  q1a= q1t=   -> tier2 / immediate
  q2a= q2t=   -> handoff / eos
  q3a= q3t=   -> user / routine
  q4a= q4t=   -> handoff / eos
  q5=   # one word: what an in-progress case MUST carry into the handoff so the next
  #        shift can resume (open|watch|status) — the watch-items                   -> watch
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks; `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L6.5", type:"DECODE", objective:"Match incident communications to audience and
    timing, and identify shift-handoff essentials", gate:false, est_minutes:15}`
  - `quiz.json`:
    1. (choice) "A confirmed DC compromise at 2am goes to:" a) the shift handoff b) Tier 2 / IR
       immediately — it meets an escalation trigger and can't wait c) the user d) marketing → **b**
    2. (choice) "A shift handoff exists to:" a) fill time b) let the next analyst resume open
       investigations, pending escalations, and watch-items without losing context c) log hours d)
       replace tickets → **b**
    3. (choice) "Telling a user their file was quarantined is:" a) an escalation b) routine
       communication — reassure and close, no incident c) confidential d) Tier 2's job → **b**
  - `hints.json`: L1 "For each case ask: does it meet an escalation trigger (→ Tier 2, now) or is it
    routine/closeable (→ user or the handoff at end of shift)?" L2 "DC compromise = immediate Tier 2; a
    closed BTP and an unfinished investigation = handoff at end of shift; a user's file question =
    routine to the user." L3 "q1 tier2/immediate; q2 handoff/eos; q3 user/routine; q4 handoff/eos; q5
    watch."
  - `recap.md` (3 lines): `Incident comms is audience + timing: confirmed compromise goes to Tier 2
    immediately; routine matters go to the user or the end-of-shift handoff.` / `The shift handoff
    carries open investigations, pending escalations, and watch-items so the next analyst resumes
    without losing context.` / `Say the right thing, to the right person, at the right time — over-
    escalating and under-communicating both cost the SOC.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s6-comms
lab: L6.5
cases:
  - {n: 1, event: dc-compromise-0230, audience: tier2, timing: immediate}
  - {n: 2, event: closed-btp-tuning, audience: handoff, timing: eos}
  - {n: 3, event: user-quarantine-question, audience: user, timing: routine}
  - {n: 4, event: unfinished-investigation, audience: handoff, timing: eos}
emit: {cases: files/comms-cases.md, handoff: files/handoff-template.md, charter: files/charter-comms.md, answers_template: files/answers.template.txt}
answer_key: {q1a: tier2, q1t: immediate, q2a: handoff, q2t: eos, q3a: user, q3t: routine, q4a: handoff, q4t: eos, q5: watch}
verify: [each case's audience/timing maps to an L0.3 charter rule]
```

---

### L6.6 — Phase gate: full investigation — from one alert to a graded escalation report

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L6.6 | Phase gate: full investigation — from one alert to a graded escalation report | REPORT | true | 20 |

Dir `tracks/soc/phases/p6/L6.6-gate-full-investigation/`. **Integrative (REPORT):** one alert → you
pivot, build the timeline, scope it, and write the full escalation yourself.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s6-gate`, RAW): `alert.json` (the M2 spray-success alert
  `CM-A-660`), the **full investigation bundle** (`case/` across all sources, all reused ids),
  `enrichment/` mocks, `escalation-template.md` (Scope/Timeline/Indicators/ATT&CK/Verdict/
  Recommendation), and `model-escalation.md` (shipped).
- **Learner task:** starting from one alert, pivot → timeline → scope, then write `report.md` — a
  complete escalation with scope, an ordered timeline **citing at least one event id**, defanged
  indicators, ≥1 ATT&CK id, a verdict, and a recommendation.
- **Grading** (`check.sh`, **REPORT rubric §2.3, tighter**): required elements (Scope, Timeline with
  ≥1 `cm-` event id cited, Indicators-defanged, ≥1 real ATT&CK id, verdict, Recommendation) + the
  **defang gate** (reject raw scheme/domain/IP) ; `ck_summary` last; quiz gates 3/3. On pass, points to
  `model-escalation.md`.
- **Kit files:**
  - `meta.json`: `{id:"L6.6", type:"REPORT", objective:"Investigate one alert end to end — pivot,
    timeline, scope — and write the graded escalation report", gate:true, est_minutes:20}`
  - `quiz.json` (gates 3/3):
    1. "A full investigation starts from one alert and produces:" a) a verdict only b) a scoped,
       timelined escalation with defanged IOCs, ATT&CK, verdict, and recommendation — the whole package
       c) a closed alert d) a tuning note → **b**
    2. "Your escalation cites event ids in the timeline because:" a) length b) grounding — a cited
       timeline is verifiable; an uncited one is a story c) MITRE requires it d) it's faster → **b**
    3. "Phase 6 turned you from alert-handler into:" a) a manager b) an investigator who pivots,
       timelines, scopes, and writes the escalation Tier 2 respects c) Tier 3 d) a rule author → **b**
  - `hints.json`: L1 "Run the loop: pivot from the alert (user→host→process→network→lateral), order the
    events into a UTC timeline, count scope, then write every section." L2 "Your timeline must cite at
    least one cm- event id; every IOC defanged; techniques include T1059.001/T1547.001; scope names the
    affected hosts; recommendation gives containment actions." L3 "If the check fails: missing a section,
    no cited event id in the timeline, or a raw IOC. Compare to model-escalation.md after you pass."
  - `recap.md` (3 lines): `A full investigation is the whole loop: one alert → pivot → timeline → scope
    → a written escalation Tier 2 acts on.` / `Cite event ids in the timeline and defang every IOC — a
    grounded, safe report is what makes you an investigator, not an alert-closer.` / `Phase 6 complete:
    you pivot, build timelines, scope, communicate, and write the ticket — Phase 7 puts the machine in
    the loop and teaches you to verify it.`
  - **`recall.json`: none** (not opener). **Parked draft for L7.1** (drafted now; **[VERIFY-AT-BUILD]**):
    1. (text) "Pivoting follows join keys from user → host → process → ___ (one word)." → **key
       `network`** — source **L6.1**.
    2. (text) "Before ordering events across hosts, normalize every timestamp to ___." → **key `utc`** —
       source **L6.2**.
    3. (choice) "The C2 beacon is on 1 host but the intrusion spans 4. Scope depends on:" a) the question
       asked b) severity c) the rule → **key a** — source **L6.3**.
    4. (text) "The required-elements list of an escalation IS the checklist ___ triages it by (who?)."
       → **key `tier 2`** (accept `tier2`, `t2`) — source **L6.4**.
    5. (choice) "A confirmed DC compromise at 2am is communicated:" a) immediately to Tier 2 b) in the
       end-of-shift handoff c) to the user → **key a** — source **L6.5**.
  - **`## SECURITY ONION (OPTIONAL)`**: run the investigation in the `cardinal-so` case view; flat-file
    report is the graded gate.
  - `model-escalation.md` — shipped worked example (defanged, cites event ids).

**EVIDENCE SPEC**
```yaml
scenario: s6-gate
lab: L6.6
seed: {alert: CM-A-660, indicator: spray-success m.reyes CM-0311-0142}
bundle: full-investigation (all sources, reused ids; scope 4 hosts; timeline e1..e7 from L6.2)
required_report_elements: [scope, timeline(with cited cm- id), indicators(defanged), attack_id, verdict, recommendation]
defang_gate: [no raw http://, no raw c2.stonewick.example, no raw 203.0.113.66, no raw 198.51.100.71]
emit: {alert: files/alert.json, case: files/case/, enrichment: files/enrichment/,
       template: files/escalation-template.md, model: files/model-escalation.md, key_block: check.sh}
answer_key: {required_sections: [scope, timeline+cited_id, attack_id: t1059.001, verdict_token, recommendation, defanged_ioc],
             reject_raw: [http://, c2.stonewick.example, 203.0.113.66, 198.51.100.71]}
verify: [model-escalation passes its own rubric+defang gate and cites >=1 real event id]
```

---

## 5. Build order (one session, Phase Builder protocol)

Prerequisite: `soc-p0…p5` tagged.

1. **Generator extensions** — `investigation_bundle` emitter + timeline/scope `verify.py` invariants
   (reusing registry ids byte-identical); self-test on a throwaway scenario; confirm the REPORT rubric
   helper (§2.3) still passes the two new model reports.
2. **p6 scenarios** in map order — `s6-pivot`, `s6-timeline`, `s6-scoping`, `s6-ticket`, `s6-comms`,
   `s6-gate` → L6.1…L6.6. Build lab by lab (§2.1/§2.1-pivot for PIVOT/HUNT/DECODE; §2.3 for the two
   REPORT labs); self-test each (fail + pass, real outputs pasted; REPORT labs include a raw-IOC
   negative and a missing-section negative); commit per lab (`soc L6.x: <title>`), one branch+PR+merge
   each via an isolated worktree.
3. **Gate (L6.6)** integrates + drafts L7.1 recall (parked above); confirm the timeline-cited-id
   requirement fails a report with no cited id and passes the model.
4. **Close-out:** `verify.py` green across `s6-*` (timeline + scope coherence); lint/shellcheck/
   acceptance green (extend `acceptance.sh` with a P6 section — 6 labs, pass + negative each; REPORT
   negatives = raw-IOC and missing-section); `lab status`/`resume` render p6; update
   `planned_execution.md`; tag `soc-p6`. Gate per lab.

## 6. Acceptance checklist mapping (PROMPTS.md §174–181)

- **Lab count/titles/types match the map** — §4 is map-exact (6 labs, L6.6 REPORT gate; PIVOT/HUNT/
  DECODE/REPORT).
- **Every lab self-tested, real outputs pasted** — build-order step 2; REPORT + defang negatives.
- **shellcheck clean** — §2.1/§2.3 patterns; no `disable=`.
- **Gate integrative + next-opener recall drafted** — L6.6 (+ parked L7.1, [VERIFY-AT-BUILD]).
- **Evidence generated + consistency-verified** — `investigation_bundle` reuses canon ids; `verify.py`
  timeline/scope coherence + inherited defang checks.
- **`lab status`/`resume`** — close-out.
- **Flat-file first / SO overlay** — all 6 grade on `files/`; SO ungraded on L6.6 only.
- **REPORT enforces defanging + grounding** — §2.3 defang gate + L6.6's cited-event-id requirement.

---

## Session control (PLAN-AHEAD, all remaining soc phases)

Phase 6 of a plan-ahead pass (2→3→4→5→6→7), one at a time, **commit-and-continue** (memory
`feedback_plan_ahead_commit_and_continue`). **Phases 2–5 planned and merged** (`soc-p2` #254, `soc-p3`
#260, `soc-p4` #261, `soc-p5` #265). Nothing built. Commits go through an **isolated git worktree**
(shared working tree has concurrent writers). After Phase 6 merges, continue to Phase 7 (The AI-Assisted
Analyst) — the final phase. Plans only; no building, no tags, no `planned_execution.md` edits.
