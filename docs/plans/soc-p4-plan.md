# SOC Track — Phase 4 Build Plan (v1)

**Mode:** plan only — produced 2026-07-20 per Phase Builder step 3 (PROMPTS.md Prompt 2),
inside a PLAN-AHEAD session that plans every remaining soc phase one at a time.
**This document is the deliverable for `docs/plans/soc-p4-plan.md`** (saved there verbatim on merge).
**Binding content spec:** `docs/curriculum/soc-analyst-lab-curriculum-v1.md` — Phase 4 (§6, lines 184–198).
**Binding mechanical spec:** `docs/kit-contracts.md` + the soc quality gates in `PROMPTS.md`.
**Predecessor plans (inherited conventions):** `soc-p01-plan.md` (§1 universe, §2 generator, §2.1 grading,
§2.2 id registry), `soc-p2-plan.md` (defanged-IOC regex-escape recipe, SO-overlay policy, HUNT-count
equality), `soc-p3-plan.md` (endpoint plane). Not re-derived; extended here.
**Scope:** 8 labs — L4.1–L4.8 (gate L4.8) — plus the `tools/genevidence/` extensions (VT-style /
passive-DNS mock enrichment emitters, alert-batch emitter, priority-key emitter).

## 0. Ground rules this plan follows

- Lab list is **map-exact** (§184–196): ids, titles, types, gate on L4.8 — no deviations.
- Evidence **generated, never hand-written**; generator emits evidence + key from one `scenario.yaml`.
- **Enrichment is fully mocked — nothing live-hostile** (PROMPTS.md soc gate): VT-style detection
  ratios, sandbox verdicts, WHOIS, and passive-DNS are **static committed artifacts** in `files/`; no
  network in the graded path (the check fence has none anyway). Hashes are deterministic seeded
  constants, never real malware.
- Grades **offline in the check fence** (§2.1 canonical pattern, `ck_summary` last).
- Raw evidence (alerts, enrichment reports, auth logs) **never defanged**; prose, keys, and learner IOC
  submissions **do** defang, graded with the soc-p2 §2 regex-escape recipe.
- **Flat-file first**; SO overlay is an ungraded appendix on the two queue-shift labs (L4.7/L4.8) only.
- ADHD contract: one concept per lab, est 10–20 min. **Pacing risk is real this phase** — L4.5 (10
  alerts), L4.7 (12 alerts), L4.8 (fresh queue) are the phase's heaviest labs; each is designed to a
  fixed, checkable answer set and flagged for honest self-test timing (see §3.5).

## 1. Universe additions — enrichment & the queue

Additive to `soc-p01-plan.md` §1; single source `tools/genevidence/universe.yaml`.

- **Mock enrichment library** (`enrichment/` under each lab's `files/`, generated, static):
  - **VT-style report** — JSON `{indicator, type, last_analysis_stats:{malicious,suspicious,harmless,
    undetected}, first_submission_date, last_analysis_date, reputation, as_owner, country}`. Detection
    ratios are **authoring-chosen per scenario** (e.g. C2 IP 203.0.113.66 → 31/94 malicious; shared-CDN
    192.0.2.61 → 2/94 with a stale `last_analysis_date`).
  - **WHOIS report** — as L0.1's `whois-stonewick.txt` (registrar, creation date, registrant); reused
    for `stonewick.example` and added for the shared-hosting provider.
  - **Passive-DNS mock** — `{ip, resolutions:[{domain, first_seen, last_seen}]}` — the *shared-hosting*
    tell: 192.0.2.61 resolves 400+ unrelated domains; 203.0.113.66 resolves only `c2.stonewick.example`.
  - **Sandbox-style report** — reused/foreshadowed for Phase 5; Phase 4 uses only IP/domain/hash lookups.
- **Reputation-trap anchors** (declared so L4.3 is grounded, not invented): `updates.example`
  `192.0.2.61` on **shared hosting** (many-domains passive DNS, low but non-zero VT), a benign CDN edge
  `192.0.2.62` (Akamai-style, VT harmless, 300+ domains), and a **stale-score** case — a formerly-flagged
  IP `192.0.2.70` whose last analysis is 14 months old and now clean.
- **New attacker auth shape for L4.4:** a **credential-stuffing brute force** — many passwords against
  the *single* account `svc_web` on WEB01 from `198.51.100.71` (contrast to M1's spray: one password,
  many accounts). New motif **M4** (brute), distinct from M1 (spray).
- **The queue:** SIEM alert batches (`queue.json` = JSON array of the canonical alert shape) drawn from
  the full Coppermine incident set (M1/M2/M3/M4 + benign background), so L4.5/L4.7/L4.8 reuse one
  coherent universe instead of inventing disconnected alerts.

## 2. Generator extensions — `tools/genevidence/`

Prerequisite: `soc-p0…p3` tagged. Phase 4 adds three emitters + one verify invariant:

1. **`vt_mock`** / **`passivedns_mock`** — emit the enrichment JSON above from scenario-declared ratios
   and resolution lists (so a lab's "malicious 31/94" and "resolves 400 domains" are single-sourced and
   the answer key reads the same numbers).
2. **`alert_batch`** — emit `queue.json` (array of canonical alerts) from a scenario's alert list, each
   alert carrying `rule`, `entities`, `evidence.event_ids`, `severity`, `risk_score`, and a hidden
   `_key` block the generator strips into check.sh (verdict/priority/escalation), never shipped in the
   file.
3. **`priority_key`** — compute each alert's priority tier from a **fixed, declared formula**
   `priority = f(severity_weight, asset_criticality, confidence)` encoded in `universe.yaml` (so L4.5's
   ordering is deterministic and defensible, not taste). Asset criticality: DC01/FS01 = high, servers =
   med, workstations = low, per a pinned asset table.
4. **`verify.py` addition — enrichment↔evidence coherence:** every indicator in an enrichment report
   exists in the lab's evidence; every alert's `evidence.event_ids` ⊆ emitted events; the priority key
   is exactly `f(...)` recomputed by verify (key can't drift from the formula).

Grading conventions inherited verbatim (§2.1 pattern; §2 regex-escape for defanged IOCs; `harness_err`
only for a corrupt key block).

## 2.1 Canonical id additions (extends prior registries)

New Phase 4 events (M4 brute force, enrichment) use the **`CM-<MMDD>-07xx` band** (unused: P1 0002–0460,
P2 05xx, P3 06xx). Alerts use **`CM-A-4xx`**. Rule ids `CM-R-<nnnn>`. Reused canon (same events, now
triaged in a queue): all M1/M2/M3 ids from prior phases, plus:

| Canonical id | Event |
|---|---|
| `CM-0311-0710`+ | M4 brute-force burst: many `4625` for `svc_web` from `198.51.100.71`, WEB01, `2026-03-11T22:xx` |
| `CM-0311-0715` | M4 success: `4624`/`Accepted` for `svc_web` after the burst (the escalation-worthy one in L4.8) |
| `CM-A-401…412` | L4.7 Queue-Shift-I twelve alerts |
| `CM-A-421…432` | L4.8 Queue-Shift-II fresh queue |

`M4` (brute) and `M1` (spray) are pinned as **distinct motifs** in `universe-events.yaml` so L4.4's
"told apart by shape" can never collapse into one.

## 3. Decisions & flagged deviations (approve/veto with the plan)

1. **Priority grading uses a declared formula, not opinion.** L4.5 could be "rank 10 alerts" (hard to
   grade). Decision: grade a **priority tier (p1/p2/p3) per alert**, keyed by the pinned
   `f(severity, asset, confidence)` formula; lab.md teaches the formula so the learner reproduces it.
   This makes a taste question checkable. Veto to grade a full ordering instead.
2. **L4.6 tuning feedback graded as a structured exclusion token, not prose.** The job hook wants
   *specific* feedback ("exclude host X on command-line pattern Y"). Grading free prose isn't
   deterministic; decision: the learner submits `qNtune=` as a `field:value` exclusion
   (`host:srv-backup`, `cmdline:robocopy`, `user:t.aoki+window:chg`), keyed exactly. The recap shows a
   model prose version for calibration (REPORT-style honesty note). Veto to make L4.6 a rubric REPORT.
3. **L4.7/L4.8 evidence citations are scoped to keep them atomic.** Twelve full dispositions with a
   cited event id each is 24 graded values — over the ADHD ceiling if every one needs a pivot. Decision:
   **verdict for all 12** + **evidence citation for a keyed subset (the 4 that most need proof)**, with
   the rest graded verdict-only; L4.8 tightens to verdict+evidence on more, plus the escalation flag.
   This mirrors soc-p01's L1.7 pacing note. Flag for honest self-test timing; trim further only if tight.
4. **Enrichment is offline mocks** (map §269 default): live WHOIS/dig/VT are optional ungraded steps in
   L4.2 only. No graded path ever touches the network.
5. **SO overlay ungraded on L4.7/L4.8 only** (queue triage in the Hunt UI). Flat-file always graded.
6. **Defanged IOCs graded in every TRIAGE/GUIDED lab** with the §2 recipe.

## 3.5 Self-review corrections applied

- **Reputation must be *contradicted* by evidence, or L4.3 teaches "trust the score."** Fixed: each
  L4.3 trap pairs a misleading reputation with **evidence that overrides it** — the shared-CDN IP has a
  high-looking hit but passive DNS shows 400 domains and the actual session is a benign 200; the stale
  score is 14 months old with a clean recent re-scan. The verdict follows evidence, and qN captures
  *why the reputation is a trap*.
- **Brute vs spray needs both in one dataset.** L4.4 emits M1 (spray: 1 password × 40 accounts, 1
  success) and M4 (brute: many passwords × 1 account) in the same `auth-events.jsonl`, so the learner
  classifies by *shape* (distinct-accounts vs attempts-per-account), not by being handed one pattern.
- **Priority formula must be visible and total-order-free of ties that matter.** Fixed: the pinned
  formula yields a clean tier per alert; where two alerts tie on tier, both are keyed to that tier (no
  hidden tiebreak the learner can't derive). `verify.py` recomputes the key from the formula.
- **The escalation alert in L4.8 must be unambiguous.** Fixed: L4.8's escalation-worthy alert is the M4
  **success** (`CM-0311-0715`) — a confirmed credential compromise on a server, matching L0.3's
  escalation triggers (credential compromise + confirmed) so the "escalate" answer is defensible, not a
  judgment call.
- **Queue alerts must reconcile with earlier phases' verdicts.** The svc_backup robocopy is BTP
  everywhere (L0.3 c5, L1.7-adjacent, L4.6); the CHG-2143 PsExec is BTP; the mimikatz.pptx filename is
  FP (L1.7 c2). Fixed: L4.6/L4.7/L4.8 reuse these with the **same verdicts** so the universe stays
  self-consistent across phases.

---

## 4. Phase 4 — labs

### L4.1 — The triage method — the five questions, applied to one alert slowly

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L4.1 | The triage method — the five questions, applied to one alert slowly | DECODE | false | 15 |

Dir `tracks/soc/phases/p4/L4.1-triage-method/`. **One concept:** the fixed five-question sequence —
(1) what fired, (2) what's the actual evidence, (3) is this expected for this user/host, (4) what's the
scope, (5) verdict — walked slowly over ONE alert.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s4-triage-method`, RAW):
  - `alert.json` — the M2 alert `CM-A-401`, rule `CM-R-0159 "Office app spawned encoded PowerShell"`,
    critical/90, T1059.001, entities host WKS-ACCT-07 / user m.reyes / parent WINWORD.EXE, evidence
    `[CM-0311-0201, CM-0311-0179, CM-0311-0181]`.
  - `events.jsonl` — the three cited events (Sysmon 1 spawn, Sysmon 3 beacon, Sysmon 13 Run key) + one
    context event (m.reyes normal morning logon) proving the host is hers.
  - `asset-inventory.csv` — `host,role,criticality,owner`: WKS-ACCT-07 = workstation/low/m.reyes, etc.
    (feeds the scope/expected questions).
  - `answers.template.txt` — one `qN=` per triage question.
- **Learner task:** walk the five questions; answer. Template + grammar:
  ```
  q1=   # what FIRED: the rule id (lowercase)                                    -> cm-r-0159
  q2=   # the single event.id that is the strongest EVIDENCE of execution         -> cm-0311-0201
  q3=   # is a document spawning encoded powershell EXPECTED for this user? y|n   -> n
  q4=   # SCOPE: how many hosts show this activity (integer)                       -> 1
  q5=   # VERDICT (tp|fp|btp)                                                      -> tp
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; five anchored checks; `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L4.1", type:"DECODE", objective:"Apply the five triage questions — what fired,
    evidence, expected, scope, verdict — to one alert", gate:false, est_minutes:15}`
  - `quiz.json`:
    1. (choice) "The triage method is valuable because it is:" a) intuition, honed by experience b) a
       fixed question sequence anyone can apply fast and defend c) a SIEM feature d) optional → **b**
    2. (choice) "Question 3 ('is this expected for this user/host?') exists to catch:" a) malware b)
       authorized/benign activity that a rule flagged — the BTP category c) network errors d) typos → **b**
    3. (choice) "Why is 'verdict' the LAST question, not the first?" a) it isn't b) a verdict without
       evidence, expectation, and scope behind it is a guess — the sequence produces a defensible call
       c) verdicts are slow d) the SIEM sets it → **b**
  - `hints.json`: L1 "Answer the five questions in order; each has one source — the alert (q1), the
    events (q2), the asset/owner context (q3/q4), and your reasoning (q5)." L2 "q2: which event proves
    code actually ran (the Sysmon 1 spawn)? q4: count distinct hosts in the events. q3: does an AP
    workstation normally launch hidden encoded powershell from Word?" L3 "q1 cm-r-0159; q2 cm-0311-0201;
    q3 n; q4 1; q5 tp."
  - `recap.md` (3 lines): `Triage is a fixed sequence, not a hunch: what fired, what's the evidence, is
    it expected, what's the scope, then the verdict.` / `The verdict is the last question because the
    first four are what make it defensible to Tier 2.` / `Run the same five questions on every alert and
    speed comes for free — the method is the craft.`
  - **`recall.json`** (phase opener; 5, non-gating; **[VERIFY-AT-BUILD]** — Phase 3 unbuilt, sourced from
    the map's Phase 3 lab list (§167–178); matches the parked L4.1 draft in `soc-p3-plan.md` L3.7):
    1. (text) "Windows Security event.code for a successful logon?" → **key `4624`** — source **L3.1**.
    2. (text) "Which Sysmon field joins a child process to its parent?" → **key `parentprocessguid`**
       (accept `processguid`) — source **L3.2**.
    3. (choice) "Office spawning powershell is an example of anomalous ___." a) process ancestry b) logon
       type c) service → **key a** — source **L3.3**.
    4. (text) "Many SSH Failed then one Accepted from one IP is a ___ that succeeded." → **key
       `brute-force`** (accept `bruteforce`, `brute force`) — source **L3.5**.
    5. (text) "A trusted built-in tool used to attack (certutil, `powershell -enc`) is a ___." → **key
       `lolbin`** — source **L3.6**.

**EVIDENCE SPEC**
```yaml
scenario: s4-triage-method
lab: L4.1
window: {start: 2026-03-11T15:40:00Z, end: 2026-03-11T15:47:00Z}
hosts: {WKS-ACCT-07: {ip: 10.20.30.107, role: workstation, criticality: low, owner: m.reyes}}
alert: {id: CM-A-401, rule: CM-R-0159, sev: critical, tech: T1059.001, cites: [CM-0311-0201, CM-0311-0179, CM-0311-0181]}
emit: {alert: files/alert.json, events: files/events.jsonl, assets: files/asset-inventory.csv, answers_template: files/answers.template.txt}
answer_key: {q1: cm-r-0159, q2: cm-0311-0201, q3: n, q4: "1", q5: tp}
verify: [cited ids present in events.jsonl; single host in scope]
```

---

### L4.2 — Indicator enrichment — hash, IP, domain lookups; reading VT-style and WHOIS-style reports

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L4.2 | Indicator enrichment — hash, IP, domain lookups; reading VT-style and WHOIS-style reports | GUIDED | false | 15 |

Dir `tracks/soc/phases/p4/L4.2-enrichment/`. **One concept:** enrich an indicator by reading mock
VT/WHOIS/passive-DNS reports — extract detections, first-seen, registrar, resolutions. Grades produced
`jq` outputs + answers (GUIDED, per L0.1).

**TEACHING ARTIFACT**
- **Files staged** (`files/enrichment/`; generated `s4-enrichment`, RAW):
  - `vt-ip-203.0.113.66.json` — `{indicator:"203.0.113.66", last_analysis_stats:{malicious:31,
    suspicious:4, harmless:2, undetected:57}, first_submission_date:"2026-03-01", as_owner:"Stonewick
    Hosting", country:"XX", reputation:-44}`.
  - `whois-stonewick.txt` — reused from L0.1 (registrar Nimbus Domains, created 2026-02-27).
  - `pdns-203.0.113.66.json` — `{ip:"203.0.113.66", resolutions:[{domain:"c2.stonewick.example",
    first_seen:"2026-02-27"}]}` (single domain — dedicated infra).
  - `vt-hash.json` — mocked sha256 (M2 docm), `malicious:52/72`, `first_submission_date:"2026-03-10"`.
  - `answers.template.txt`.
- **Learner task (GUIDED STEPS, run for real; outputs graded):**
  1. `jq '.last_analysis_stats.malicious' enrichment/vt-ip-203.0.113.66.json > vt_mal.txt`
  2. `jq -r '.resolutions[].domain' enrichment/pdns-203.0.113.66.json > pdns_domains.txt`
  3. `grep 'Creation Date' enrichment/whois-stonewick.txt`
  4. `jq '.last_analysis_stats.malicious' enrichment/vt-hash.json`
  5. `cp answers.template.txt answers.txt` and fill:
     ```
     q1=   # VT malicious count for the C2 IP                                    -> 31
     q2=   # the one domain the C2 IP resolves to (DEFANGED)                      -> c2.stonewick[.]example
     q3=   # WHOIS creation date of stonewick.example (YYYY-MM-DD)                -> 2026-02-27
     q4=   # VT malicious count for the M2 attachment hash                        -> 52
     q5=   # one word: registrar/hosting/passive-dns — which source proved the IP
     #        hosts ONLY the C2 domain (dedicated infra)?                         -> passive-dns
     ```
  6. OPTIONAL UNGRADED: `dig +short`, `whois` live (network only; the fence has none).
- **Grading** (`check.sh`, §2.1 + produced-artifact): `assert_file_exists vt_mal.txt`, `pdns_domains.txt`,
  `answers.txt`; `assert_file_contains_fixed vt_mal.txt "31"` (tool output raw); normalize answers →
  anchored q1–q5 (q2 defanged, regex-escape); `ck_summary`.
- **Kit files:**
  - `meta.json`: `{id:"L4.2", type:"GUIDED", objective:"Read mock VT/WHOIS/passive-DNS reports and
    extract detections, first-seen, registrar, and resolutions", gate:false, est_minutes:15}`
  - `quiz.json`:
    1. (choice) "A VT `malicious: 31/94` means:" a) the file is 31% malware b) 31 of 94 engines flagged
       it — a signal, not a verdict c) it was seen 31 times d) 31 detections remain → **b**
    2. (choice) "Passive DNS showing an IP resolves ONE domain suggests:" a) shared hosting b) dedicated
       infrastructure — the IP and domain move together c) a CDN d) nothing → **b**
    3. (choice) "Why does this lab grade against staged reports, not live VT?" a) VT is down b) the
       graded path is offline and deterministic; enrichment is mocked so labs never depend on a live
       service or a network c) live lookups are illegal d) speed → **b**
  - `hints.json`: L1 "Each fact is one jq path or one grep on a report in enrichment/. The stats live
    under .last_analysis_stats." L2 "q1/q4: `.last_analysis_stats.malicious`. q2: `.resolutions[].domain`
    (defang it). q3: grep Creation Date. q5: which report tied the IP to exactly one domain?" L3 "q1 31;
    q2 c2.stonewick[.]example; q3 2026-02-27; q4 52; q5 passive-dns."
  - `recap.md` (3 lines): `Enrichment answers 'what is this indicator' from three angles: VT-style
    detections, WHOIS ownership/age, and passive DNS resolutions.` / `A detection ratio is a signal, not
    a verdict, and a fresh registration or single-domain IP is often more telling than the score.` /
    `The graded path is offline mocks by design — real WHOIS/dig/VT are optional, so no lab ever depends
    on a live service.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s4-enrichment
lab: L4.2
indicators:
  - {type: ip, value: 203.0.113.66, vt_malicious: 31, vt_total: 94, first_seen: 2026-03-01,
     as_owner: "Stonewick Hosting", pdns: [c2.stonewick.example]}
  - {type: domain, value: stonewick.example, whois_created: 2026-02-27, registrar: "Nimbus Domains LLC"}
  - {type: sha256, value: <M2 docm seeded hash>, vt_malicious: 52, vt_total: 72, first_seen: 2026-03-10}
emit: {vt_ip: files/enrichment/vt-ip-203.0.113.66.json, whois: files/enrichment/whois-stonewick.txt,
       pdns: files/enrichment/pdns-203.0.113.66.json, vt_hash: files/enrichment/vt-hash.json, answers_template: files/answers.template.txt}
answer_key: {q1: "31", q2: c2.stonewick[.]example, q3: "2026-02-27", q4: "52", q5: passive-dns}
verify: [every enrichment indicator exists in the universe; counts match scenario-declared ratios]
```

---

### L4.3 — Reputation is not a verdict — enrichment traps: shared hosting, CDN IPs, stale scores

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L4.3 | Reputation is not a verdict — enrichment traps: shared hosting, CDN IPs, stale scores | TRIAGE | false | 20 |

Dir `tracks/soc/phases/p4/L4.3-reputation-traps/`. **One concept:** a reputation score is not a verdict
— shared hosting, CDN IPs, and stale scores mislead; the evidence overrides the number.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s4-reputation`, RAW): three mini-cases, each `caseN/` with an
  `alert.json`, the `enrichment/` reports, and an `events.jsonl`:
  - **case1 — shared hosting:** alert flags `192.0.2.61` (updates.example) as "known-bad IP"; VT 2/94
    but passive DNS shows **400+ domains** on it; the actual session is a benign `GET /patch.json 200`.
    Reputation trap = **shared-hosting**; verdict **fp** (the IP is shared; this session is benign).
  - **case2 — CDN:** alert flags `192.0.2.62` (CDN edge); VT harmless, 300+ domains; benign asset
    fetch. Trap = **cdn**; verdict **fp**.
  - **case3 — stale score:** alert flags `192.0.2.70`; VT last analysis **14 months old**, malicious
    then, clean on recent re-scan; current session benign. Trap = **stale**; verdict **fp** (or btp if
    the behavior were authorized — here it's benign traffic → fp).
  - (Contrast row for calibration, case0 in lab.md only: 203.0.113.66 — dedicated infra, high VT,
    single-domain pDNS, real beacon → **tp**; shows reputation and evidence *agreeing*.)
  - `answers.template.txt` — verdict + trap per case.
- **Learner task:** for each case, read the alert + enrichment + events; give verdict and name the trap.
  Template + grammar:
  ```
  # trap vocab: sharedhosting | cdn | stale | none
  q1=   # case1 verdict (tp|fp|btp)          -> fp
  q1t=  # case1 trap                          -> sharedhosting
  q2=   # case2 verdict                       -> fp
  q2t=  # case2 trap                          -> cdn
  q3=   # case3 verdict                       -> fp
  q3t=  # case3 trap                          -> stale
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; six anchored checks; `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L4.3", type:"TRIAGE", objective:"Override misleading reputation with evidence —
    recognize shared-hosting, CDN, and stale-score traps and verdict on behavior", gate:false,
    est_minutes:20}`
  - `quiz.json`:
    1. (choice) "An IP with a high VT score that passive DNS shows hosting 400 domains is probably:" a)
       dedicated C2 b) shared hosting — the score may reflect a different tenant, not this session c) a
       CDN only d) always malicious → **b**
    2. (choice) "A VT verdict last updated 14 months ago is:" a) authoritative b) stale — re-scan and
       weigh current evidence before trusting it c) always wrong d) irrelevant → **b**
    3. (choice) "Reputation is not a verdict because:" a) VT is unreliable b) the score describes an
       indicator's history, not what happened in YOUR evidence — the session's behavior decides c) scores
       are random d) it always lags → **b**
  - `hints.json`: L1 "For each case, don't stop at the score — read passive DNS (how many domains?), the
    analysis date (how old?), and the actual session in events.jsonl (what happened?)." L2 "case1: 400+
    domains on one IP = shared hosting. case2: CDN edge, harmless, benign fetch. case3: the score is 14
    months stale. In all three the session itself is benign." L3 "All three verdicts are fp; traps are
    sharedhosting, cdn, stale."
  - `recap.md` (3 lines): `Reputation describes an indicator's past, not your evidence — a score is a
    signal to weigh, never the verdict.` / `Shared hosting and CDN IPs carry other tenants' reputation;
    passive DNS (many domains) is the tell, and the actual session decides.` / `Stale scores go both
    ways — re-check the date, then let the behavior in your logs make the call.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s4-reputation
lab: L4.3
cases:
  - {n: 1, ip: 192.0.2.61, trap: sharedhosting, vt_malicious: 2, pdns_domains: 400, session: "GET /patch.json 200", verdict: fp}
  - {n: 2, ip: 192.0.2.62, trap: cdn, vt_malicious: 0, pdns_domains: 300, session: benign asset fetch, verdict: fp}
  - {n: 3, ip: 192.0.2.70, trap: stale, vt_last_analysis: 2025-01, vt_then: malicious, vt_now: clean, session: benign, verdict: fp}
emit: {cases: [files/case1/, files/case2/, files/case3/], answers_template: files/answers.template.txt}
answer_key: {q1: fp, q1t: sharedhosting, q2: fp, q2t: cdn, q3: fp, q3t: stale}
verify: [each case's enrichment single-sourced from scenario; sessions benign in all three]
```

---

### L4.4 — Brute force vs password spray — the auth-log classics, told apart by shape

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L4.4 | Brute force vs password spray — the auth-log classics, told apart by shape | TRIAGE | false | 20 |

Dir `tracks/soc/phases/p4/L4.4-brute-vs-spray/`. **One concept:** shape distinguishes them — **brute
force** = many passwords vs ONE account; **spray** = ONE password vs MANY accounts. Classify by
distinct-accounts-vs-attempts-per-account.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s4-brute-spray`, RAW):
  - `auth-events.jsonl` — ~50 ECS auth events, two attacks + benign:
    - **M1 spray:** 4625 across 40+ accounts, ONE attempt each, from 203.0.113.66, one 4624 success
      (m.reyes, `CM-0311-0142`).
    - **M4 brute:** 4625 × ~30 attempts against the SINGLE account `svc_web` from 198.51.100.71
      (`CM-0311-0710`+), then one 4624 success `CM-0311-0715`.
    - benign: scattered single 4625 typos (j.walsh).
  - `answers.template.txt`.
- **Learner task:** classify each burst; answer. Template + grammar:
  ```
  q1=   # the 203.0.113.66 burst: brute or spray?                               -> spray
  q2=   # the 198.51.100.71 burst: brute or spray?                              -> brute
  q3=   # the single account targeted by the brute force                        -> svc_web
  q4=   # distinct accounts hit by the spray (integer, from the events)          -> <generator int>
  q5=   # verdict for the brute-force burst that SUCCEEDED (tp|fp|btp)            -> tp
  q6=   # source IP of the spray — DEFANGED                                      -> 203.0.113[.]66
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks; **q4 generator-emitted
  distinct-account count** (`verify.py` asserts == emitted); q6 defanged; `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L4.4", type:"TRIAGE", objective:"Tell brute force (many passwords, one account)
    from password spray (one password, many accounts) by shape, and verdict a success", gate:false,
    est_minutes:20}`
  - `quiz.json`:
    1. (choice) "One source, 40 accounts, one failed attempt each. This is:" a) brute force b) password
       spray — low-and-slow across accounts to dodge lockout c) credential stuffing d) MFA fatigue → **b**
    2. (choice) "One source hammering ONE account with 30 passwords is:" a) spray b) brute force c) a
       typo d) normal → **b**
    3. (choice) "Why does spray dodge account-lockout policies?" a) it doesn't b) one attempt per
       account stays under the per-account lockout threshold c) it's encrypted d) it's slow → **b**
  - `hints.json`: L1 "Group 4625s by source IP, then by target account. Count distinct accounts vs
    attempts-per-account for each source." L2 "One source spread thin across many accounts = spray; one
    source concentrated on a single account = brute. Each has a 4624 success after it." L3 "203.0.113.66
    = spray; 198.51.100.71 = brute against svc_web; q4 = distinct sprayed accounts; q5 tp; q6
    203.0.113[.]66."
  - `recap.md` (3 lines): `Spray and brute force are the same goal, opposite shapes: spray is one
    password across many accounts, brute is many passwords against one.` / `Classify by counting —
    distinct accounts per source versus attempts per account — not by the rule name.` / `Either that
    ends in a 4624 success is a confirmed credential compromise: tp, and usually an escalation.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s4-brute-spray
lab: L4.4
externals: {spray_src: 203.0.113.66, brute_src: 198.51.100.71}
attacks:
  - {motif: M1, kind: spray, src: 203.0.113.66, accounts: 40+, attempts_each: 1, success: {user: m.reyes, id: CM-0311-0142}}
  - {motif: M4, kind: brute, src: 198.51.100.71, account: svc_web, attempts: 30, success: {user: svc_web, id: CM-0311-0715}}
benign: [scattered single 4625 typos]
emit: {auth_events: files/auth-events.jsonl, answers_template: files/answers.template.txt}
answer_key: {q1: spray, q2: brute, q3: svc_web, q4: "<distinct_sprayed_accounts>", q5: tp, q6: 203.0.113[.]66}
verify: [q4 == emitted distinct sprayed-account count; both bursts present with a success each]
```

---

### L4.5 — Severity and priority — ten alerts, which first, and why

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L4.5 | Severity and priority — ten alerts, which first, and why | TRIAGE | false | 20 |

Dir `tracks/soc/phases/p4/L4.5-severity-priority/`. **One concept:** priority = f(severity, asset
criticality, confidence) — assign a tier per alert from the pinned formula (D1). Severity is not
priority.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s4-priority`, RAW):
  - `queue.json` — 10 canonical alerts spanning the incident: M2 critical on a workstation, M4 brute
    success on a server (WEB01), M1 spray on DC01, a shared-hosting FP (low asset), the svc_backup BTP,
    etc. Each carries `severity`, `risk_score`, and entity host.
  - `asset-inventory.csv` — host → criticality (DC01/FS01 high, WEB01/servers med, WKS low).
  - `priority-formula.md` — static: the pinned tiering rule (e.g. p1 = critical/high sev AND high/med
    asset AND confirmed; p3 = low sev OR low asset OR likely-FP; p2 = the rest), with a worked example.
  - `answers.template.txt` — `q1..q10` priority tier per alert.
- **Learner task:** apply the formula, assign a tier to each. Template grammar: `qN=` one of `p1|p2|p3`.
- **Grading** (`check.sh`, §2.1): presence + normalize; ten anchored checks from the priority key
  (generator-computed via `f(...)`, `verify.py` re-derives); `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L4.5", type:"TRIAGE", objective:"Assign a priority tier to ten alerts from the
    severity × asset-criticality × confidence formula — distinguishing severity from priority",
    gate:false, est_minutes:20}`
  - `quiz.json`:
    1. (choice) "Severity and priority differ because:" a) they're the same b) severity is the rule's
       static estimate of badness; priority is what YOU work first, factoring asset and confidence c)
       priority is set by the SIEM d) severity is dynamic → **b**
    2. (choice) "A 'critical' alert on a decommissioned test box vs a 'medium' on a domain controller —
       work first:" a) always the critical b) the medium — asset criticality lifts its priority c) both
       equally d) neither → **b**
    3. (choice) "A high-severity alert you're 90% sure is a false positive gets:" a) p1 always b) a lower
       priority — confidence it's benign pulls it down the queue c) escalated d) ignored → **b**
  - `hints.json`: L1 "Priority is not the severity field. Read priority-formula.md and score each alert
    on severity, the host's asset criticality, and your confidence it's real." L2 "p1 = high sev AND
    important asset AND confirmed/likely-real; p3 = low sev OR low-value asset OR likely-FP; everything
    else p2. Check the asset-inventory for each host." L3 "Work the formula per alert; the two on DC01/
    WEB01 with confirmed compromise are p1, the shared-hosting FP and svc_backup BTP are p3."
  - `recap.md` (3 lines): `Severity is the rule's guess at badness; priority is your decision about what
    to work first — they are not the same field.` / `Priority = severity weighted by asset criticality
    and your confidence the alert is real; a DC medium can outrank a workstation critical.` / `A
    high-severity likely-FP drops down the queue — confidence is part of the math.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s4-priority
lab: L4.5
asset_table: {DC01: high, FS01: high, WEB01: med, WKS-ACCT-07: low, WKS-HD-03: low}
priority_formula: "p1 if sev>=high AND asset>=med AND confidence>=likely; p3 if sev<=low OR asset==low-and-FP OR confidence==likely-fp; else p2"
alerts:  # 10; generator computes priority_key = f(sev, asset, confidence)
  - {id: CM-A-405, motif: M2, host: WKS-ACCT-07, sev: critical, confidence: confirmed}   # -> p1 (confirmed exec even on low asset)
  - {id: CM-A-406, motif: M4, host: WEB01, sev: high, confidence: confirmed}              # -> p1
  - {id: CM-A-407, motif: M1, host: DC01, sev: high, confidence: likely}                  # -> p1
  - {id: CM-A-408, trap: sharedhosting, host: WKS-HD-03, sev: high, confidence: likely-fp}# -> p3
  - {id: CM-A-409, btp: svc_backup, host: FS01, sev: medium, confidence: likely-fp}       # -> p3
  # ... 5 more spanning p2 ...
emit: {queue: files/queue.json, assets: files/asset-inventory.csv, formula: files/priority-formula.md, answers_template: files/answers.template.txt}
answer_key: {q1: p1, q2: p1, q3: p1, q4: p3, q5: p3, "...": "..."}   # generator-computed from f()
verify: [priority key == f(sev,asset,confidence) recomputed by verify.py for all 10]
```

---

### L4.6 — The false-positive mines — noisy rules, admin behavior, and writing tuning feedback

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L4.6 | The false-positive mines — noisy rules, admin behavior, and writing tuning feedback | TRIAGE | false | 20 |

Dir `tracks/soc/phases/p4/L4.6-fp-mines/`. **One concept:** recognize FP/BTP from noisy rules and admin
behavior, and write **specific** tuning feedback (the job hook) as a structured exclusion.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s4-fp-mines`, RAW): four `caseN/` bundles:
  - **case1 — svc_backup robocopy** (mass-file-copy rule): BTP; tuning = exclude `host:SRV-BACKUP`
    matched on `cmdline:robocopy` in the 02:00Z window.
  - **case2 — CHG-2143 PsExec** (remote-admin rule): BTP; tuning = allowlist `user:t.aoki` under
    `window:CHG` (change ticket).
  - **case3 — mimikatz.pptx** (filename-substring rule, from L1.7 c2): FP (POWERPNT opening a training
    deck); tuning = the rule matches a filename substring — exclude `path:SecurityAwareness` /
    fix the selector.
  - **case4 — real M2** (control): TP, **no tuning** (this one is not a mine).
  - `answers.template.txt` — verdict + tuning exclusion per case.
- **Learner task:** verdict each, and for the FPs/BTPs give the exclusion. Template + grammar:
  ```
  # verdict: tp|fp|btp ; tune: field:value exclusion, or 'none' for a real TP
  q1=   -> btp     q1t=  # tuning exclusion -> host:srv-backup
  q2=   -> btp     q2t=  #                  -> user:t.aoki
  q3=   -> fp      q3t=  #                  -> path:securityawareness
  q4=   -> tp      q4t=  #                  -> none
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize (lowercase makes `host:SRV-BACKUP` →
  `host:srv-backup`); eight anchored checks; the tuning tokens keyed exactly (accept a small alternation
  where a case has two defensible exclusion fields, e.g. `q1t=(host:srv-backup|cmdline:robocopy)`);
  `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L4.6", type:"TRIAGE", objective:"Verdict noisy-rule and admin-behavior false
    positives and write a specific tuning exclusion that feeds detection engineering", gate:false,
    est_minutes:20}`
  - `quiz.json`:
    1. (choice) "Good tuning feedback is:" a) 'this rule is noisy' b) a specific exclusion — host, user,
       path, or command pattern — that suppresses the benign case without blinding the rule c) 'disable
       the rule' d) a password reset → **b**
    2. (choice) "The mimikatz-filename FP happened because the rule matched:" a) a real mimikatz binary
       b) the substring 'mimikatz' in a training-deck filename — a brittle selector c) a hash d) an IP
       → **b**
    3. (choice) "Closing svc_backup's 02:00Z copy as BTP should produce:" a) an incident ticket b) a
       tuning note to suppress the scheduled backup job, and no ticket c) nothing d) a firewall block
       → **b**
  - `hints.json`: L1 "For each case: did the named behavior happen (fp if the rule matched something
    else), and if it did, was it authorized (btp)? Then write what to exclude so the rule stops firing
    on THIS benign case." L2 "case1 is the nightly backup (exclude the host/command); case2 is a change-
    ticketed PsExec (allowlist the user/window); case3 matched a filename substring (exclude the path);
    case4 is the real attack — no tuning." L3 "q1 btp/host:srv-backup; q2 btp/user:t.aoki; q3 fp/
    path:securityawareness; q4 tp/none."
  - `recap.md` (3 lines): `False-positive mines are noisy rules and authorized admin behavior — verdict
    them fp or btp, never escalate them.` / `The value you add is specific tuning feedback: exclude host
    X on pattern Y, allowlist user Z under change window — precise enough to suppress the noise without
    blinding the rule.` / `That feedback is the analyst-to-detection-engineering loop; a brittle
    filename-substring rule is exactly what your note fixes.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s4-fp-mines
lab: L4.6
cases:
  - {n: 1, rule: mass-file-copy, actor: svc_backup, host: SRV-BACKUP, verdict: btp, tune: "host:srv-backup", alt: "cmdline:robocopy"}
  - {n: 2, rule: remote-admin, actor: t.aoki, ticket: CHG-2143, verdict: btp, tune: "user:t.aoki", alt: "window:chg"}
  - {n: 3, rule: filename-substring-mimikatz, host: WKS-HD-03, verdict: fp, tune: "path:securityawareness"}
  - {n: 4, motif: M2, host: WKS-ACCT-07, verdict: tp, tune: none}
emit: {cases: [files/case1/, ..., files/case4/], answers_template: files/answers.template.txt}
answer_key:
  q1: btp
  q1t: (host:srv-backup|cmdline:robocopy)
  q2: btp
  q2t: (user:t.aoki|window:chg)
  q3: fp
  q3t: path:securityawareness
  q4: tp
  q4t: none
verify: [verdicts match cross-phase canon (svc_backup btp, chg-2143 btp, mimikatz fp, M2 tp)]
```

---

### L4.7 — Queue shift I — twelve mixed alerts, full dispositions with evidence, graded

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L4.7 | Queue shift I — twelve mixed alerts, full dispositions with evidence, graded | TRIAGE | false | 20 |

Dir `tracks/soc/phases/p4/L4.7-queue-shift-1/`. **Integrative:** work a real 12-alert queue — verdict
each, cite evidence for the ones that need proof. First full shift.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s4-queue-1`, RAW):
  - `queue.json` — 12 canonical alerts `CM-A-401…412` drawn from the whole incident: M1 spray success
    (tp), M2 exec (tp), M3 tunnel (tp), M4 brute success (tp), svc_backup BTP, CHG-2143 BTP, mimikatz
    FP, shared-hosting FP, NTP-as-C2 FP (L1.7 c6), a real Run-key persistence (tp), a stale-score FP, an
    adware-quarantine BTP (contained).
  - `events/` — per-alert evidence bundles (the cited events).
  - `asset-inventory.csv`, `answers.template.txt` (12 verdicts + 4 keyed evidence citations).
- **Learner task:** disposition all 12; cite evidence on the 4 flagged. Template + grammar:
  ```
  # qN = verdict tp|fp|btp for alert CM-A-40N ; qNe (only for N in {1,3,5,10}) = deciding event.id
  q1=..q12=      # verdicts
  q1e= q3e= q5e= q10e=   # cited event ids for the four that most need proof
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; 12 verdict checks + 4 evidence checks (evidence
  keyed as alternations where multiple events are defensible); `ck_summary` last. Per D3 the other 8 are
  verdict-only to keep the lab atomic.
- **Kit files:**
  - `meta.json`: `{id:"L4.7", type:"TRIAGE", objective:"Work a 12-alert queue: verdict each and cite
    deciding evidence for the ones that need it", gate:false, est_minutes:20}`
  - `quiz.json`:
    1. (choice) "Working a queue, you hit an alert identical to one you closed FP yesterday. You:" a)
       auto-close it b) re-verify against THIS alert's evidence — yesterday's verdict isn't this
       alert's c) escalate d) skip → **b**
    2. (choice) "Half your queue is BTP/FP. That means:" a) you're doing it wrong b) normal Tier 1 —
       most alerts aren't incidents; the skill is fast, defensible dispositions and tuning feedback c)
       the SIEM is broken d) escalate all → **b**
    3. (choice) "A 12-alert shift with two real TPs among BTP/FP noise trains:" a) speed only b) the core
       loop — triage fast, don't miss the real ones, don't over-escalate the benign c) reporting d)
       enrichment → **b**
  - `hints.json`: L1 "Run the five questions on each alert; most are BTP/FP mines you've seen — backup
    jobs, change-ticketed admin, filename substrings, NTP, shared hosting." L2 "The real TPs are the M1
    success, M2 exec, M3 tunnel, M4 brute success, and the Run-key persistence. Cite the success/spawn
    event for those you're asked to prove." L3 "See the per-alert rationale in hints L3 (verdicts +
    cite ids listed for q1e/q3e/q5e/q10e)."
  - `recap.md` (3 lines): `A shift is the job at volume: run the five questions on every alert, fast and
    defensibly.` / `Most alerts are BTP/FP mines — the skill is disposing them quickly without missing
    the real TPs or over-escalating the benign.` / `Cite the one event a skeptic couldn't argue with;
    that citation is what makes your verdict a ticket, not an opinion.`
  - No `recall.json`.
  - **`## SECURITY ONION (OPTIONAL)`**: work the same queue in the `cardinal-so` Hunt UI; flat-file graded.

**EVIDENCE SPEC**
```yaml
scenario: s4-queue-1
lab: L4.7
alerts:  # CM-A-401..412; verdict + (subset) cite
  - {id: CM-A-401, motif: M1-success, verdict: tp, cite: cm-0311-0142}     # q1 + q1e
  - {id: CM-A-402, btp: svc_backup, verdict: btp}
  - {id: CM-A-403, motif: M3-tunnel, verdict: tp, cite: cm-0312-0310}      # q3 + q3e
  - {id: CM-A-404, fp: mimikatz-filename, verdict: fp}
  - {id: CM-A-405, motif: M2-exec, verdict: tp, cite: cm-0311-0201}        # q5 + q5e
  - {id: CM-A-406, btp: chg-2143, verdict: btp}
  - {id: CM-A-407, fp: ntp-as-c2, verdict: fp}
  - {id: CM-A-408, fp: sharedhosting, verdict: fp}
  - {id: CM-A-409, btp: adware-quarantine, verdict: btp}
  - {id: CM-A-410, motif: runkey-persist, verdict: tp, cite: cm-0311-0181} # q10 + q10e
  - {id: CM-A-411, fp: stale-score, verdict: fp}
  - {id: CM-A-412, motif: M4-brute-success, verdict: tp}
emit: {queue: files/queue.json, events: files/events/, assets: files/asset-inventory.csv, answers_template: files/answers.template.txt}
answer_key:
  q1: tp; q1e: cm-0311-0142; q2: btp; q3: tp; q3e: cm-0312-0310; q4: fp; q5: tp; q5e: cm-0311-0201
  q6: btp; q7: fp; q8: fp; q9: btp; q10: tp; q10e: cm-0311-0181; q11: fp; q12: tp
verify: [all cited ids present; verdicts consistent with cross-phase canon]
```
*(answer_key rendered one-key-per-line in the real file — shown compact here.)*

---

### L4.8 — Phase gate: Queue shift II — new queue, tighter grading, includes one alert that deserves escalation

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L4.8 | Phase gate: Queue shift II — new queue, tighter grading, includes one alert that deserves escalation | TRIAGE | true | 20 |

Dir `tracks/soc/phases/p4/L4.8-gate-queue-shift-2/`. **Integrative gate:** a fresh queue, verdict +
evidence on more alerts, and correctly flag the ONE that must escalate to Tier 2.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s4-queue-2`, RAW):
  - `queue.json` — 10 fresh alerts `CM-A-421…430`, new evidence bundles, same universe. Includes the
    **M4 brute-force SUCCESS on WEB01** (`CM-0311-0715`) — the escalation-worthy alert (confirmed
    credential compromise on a server → L0.3 triggers a+c).
  - `events/`, `asset-inventory.csv`, `escalation-criteria.md` (the L0.3 four triggers restated).
  - `answers.template.txt` — verdict + evidence per alert + one escalation flag.
- **Learner task:** disposition all 10 with evidence; set the escalation flag on the one that qualifies.
  Template + grammar:
  ```
  # qN = verdict (tp|fp|btp) ; qNe = deciding event.id ; qNesc = does THIS alert escalate? y|n
  q1=..q10=  qNe (keyed subset)  qNesc (exactly one alert = y)
  ```
- **Grading** (`check.sh`, §2.1, tighter): 10 verdicts + evidence on a larger keyed subset + the
  escalation flag (exactly one `y`, keyed to the M4-success alert); `ck_summary` last; quiz gates 3/3.
- **Kit files:**
  - `meta.json`: `{id:"L4.8", type:"TRIAGE", objective:"Work a fresh queue with verdicts and evidence,
    and correctly escalate the one confirmed compromise", gate:true, est_minutes:20}`
  - `quiz.json` (gates 3/3):
    1. "Which alert in a Tier-1 queue escalates to Tier 2?" a) any high-severity one b) a confirmed
       compromise, multi-host scope, credential compromise, or one needing containment authority — the
       L0.3 triggers c) every TP d) none → **b**
    2. "A brute force that SUCCEEDED against a service account on a server is:" a) fp b) a confirmed
       credential compromise — tp AND escalate c) btp d) low priority → **b**
    3. "Escalating every TP instead of only those meeting the triggers:" a) is correct b) floods Tier 2
       and devalues real escalations — most TPs Tier 1 dispositions and documents c) is required d) is
       faster → **b**
  - `hints.json`: L1 "Verdict all ten first; then ask which one meets an L0.3 escalation trigger
    (confirmed compromise / >1 host / credential compromise / needs containment)." L2 "Most TPs here
    Tier 1 handles; the brute-force SUCCESS on a server account is a confirmed credential compromise —
    that's the escalation." L3 "The escalation flag is y on the M4-success alert (CM-0311-0715); all
    others n. Verdicts and cite ids in the per-alert list."
  - `recap.md` (3 lines): `A shift ends with the right escalations, not the most: verdict everything,
    escalate only what meets the triggers.` / `A brute force or spray that succeeded is a confirmed
    credential compromise — tp and escalate.` / `Phase 4 complete: you run the five questions, enrich
    without trusting reputation, tell brute from spray, prioritize, tune, and work a queue — Phase 5 is
    the reported phish.`
  - **`recall.json`: none** (not opener). **Parked draft for L5.1** (drafted now; **[VERIFY-AT-BUILD]**
    against built Phase 4):
    1. (text) "The five triage questions end by producing a ___ (one word)." → **key `verdict`** — L4.1.
    2. (choice) "A high VT score on an IP hosting 400 domains is likely a ___ trap." a) shared-hosting b)
       dedicated c2 c) stale → **key a** — L4.3.
    3. (text) "One password against many accounts is a password ___ (one word)." → **key `spray`** — L4.4.
    4. (text) "Closing a noisy-rule false positive should produce ___ feedback to detection engineering."
       → **key `tuning`** — L4.6.
    5. (choice) "Severity is the rule's estimate; ___ is what you work first." a) priority b) risk_score
       c) confidence → **key a** — L4.5.
  - **`## SECURITY ONION (OPTIONAL)`**: work the gate queue in the Hunt UI; flat-file is the graded gate.

**EVIDENCE SPEC**
```yaml
scenario: s4-queue-2
lab: L4.8
alerts:  # CM-A-421..430; one escalation
  - {id: CM-A-425, motif: M4-brute-success, host: WEB01, verdict: tp, cite: cm-0311-0715, escalate: y}   # the one
  - {id: "...9 more...", verdicts: [tp/fp/btp mix], escalate: n}
escalation_triggers: [confirmed-compromise, multi-host, credential-compromise, needs-containment]
emit: {queue: files/queue.json, events: files/events/, assets: files/asset-inventory.csv,
       criteria: files/escalation-criteria.md, answers_template: files/answers.template.txt, key_block: check.sh}
answer_key: {"...": "10 verdicts + subset cites + qNesc (exactly one y = CM-A-425)"}
verify: [exactly one escalate=y, keyed to the confirmed credential compromise; cited ids present]
```

---

## 5. Build order (one session, Phase Builder protocol)

Prerequisite: `soc-p0…p3` tagged.

1. **Generator extensions** — `vt_mock`, `passivedns_mock`, `alert_batch`, `priority_key` emitters + the
   enrichment↔evidence + priority-formula `verify.py` invariants; append the §2.1 ids + asset table +
   priority formula to `universe-events.yaml`; self-test on a throwaway scenario.
2. **p4 scenarios** in map order — `s4-triage-method`, `s4-enrichment`, `s4-reputation`, `s4-brute-spray`,
   `s4-priority`, `s4-fp-mines`, `s4-queue-1`, `s4-queue-2` → L4.1…L4.8. Build lab by lab with the §2.1
   pattern; self-test each (fail + pass, real outputs pasted); **time L4.5/L4.7/L4.8 honestly** and apply
   the D3 evidence-subset trim if over 20 min; commit per lab (`soc L4.x: <title>`), one branch+PR+merge
   each (isolated worktree, given the shared-tree concurrency).
3. **Gate (L4.8)** integrates + drafts L5.1 recall (parked above); confirm exactly one escalation.
4. **Close-out:** `verify.py` green across `s4-*`; lint/shellcheck/acceptance green (extend
   `acceptance.sh` with a P4 section — 8 labs, pass + negative each — and fix catalog counts); `lab
   status`/`resume` render p4; update `planned_execution.md`; tag `soc-p4`. Gate per lab per the
   multi-phase rule.

## 6. Acceptance checklist mapping (PROMPTS.md §174–181)

- **Lab count/titles/types match the map** — §4 is map-exact (8 labs, L4.8 gate; DECODE/GUIDED/TRIAGE).
- **Every lab self-tested, real outputs pasted** — build-order step 2.
- **shellcheck clean** — §2.1 + §2 regex-escape; no `disable=`.
- **Gate integrative + next-opener recall drafted** — L4.8 (+ parked L5.1, [VERIFY-AT-BUILD]).
- **Evidence generated + consistency-verified** — §2 emitters + `verify.py` (enrichment↔evidence,
  priority-formula recompute, HUNT/count equality, in-window, entity resolution, defang rules).
- **`lab status`/`resume`** — close-out.
- **Nothing live-hostile** — all enrichment mocked; hashes seeded constants; no network in graded path.
- **Flat-file first / SO overlay** — all 8 grade on `files/`; SO ungraded on L4.7/L4.8 only.

---

## Session control (PLAN-AHEAD, all remaining soc phases)

Phase 4 of a plan-ahead pass (2→3→4→5→6→7), one at a time, **commit-and-continue** (no per-phase stop —
see memory `feedback_plan_ahead_commit_and_continue`). **Phases 2 and 3 are planned and merged**
(`soc-p2-plan.md` PR #254, `soc-p3-plan.md` PR #260). Nothing built. Commits go through an **isolated
git worktree** (the shared working tree has concurrent writers from other track sessions). After Phase 4
merges, continue to Phase 5 (Phishing & Malware Triage). Plans only; no building, no tags, no
`planned_execution.md` edits.
