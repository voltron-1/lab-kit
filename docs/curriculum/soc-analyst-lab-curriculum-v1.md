# SOC ANALYST LAB — Curriculum Map v1.0

**Triage. Investigate. Escalate. Verify.**
A terminal-based SOC Tier 1 analyst training course.

---

## 1. The Premise

This track is different from Rust and Bash in one fundamental way: those were *literacy* courses — read and audit, let AI write. **Tier 1 analysis is a doing job.** There is no "AI does the triage" cop-out here, because:

> **You can only supervise AI triage if you can do triage without it.**

Your own architecture is analyst-in-the-loop. This course puts you in the analyst's chair — the seat your platform is built around — and trains the full Tier 1 craft, ending with the skill that actually defines the modern analyst: **verifying machine-generated triage against raw evidence** instead of rubber-stamping it.

Four skills, in order:

1. **Triage** — take an alert queue and disposition every alert (true positive / false positive / benign true positive) with evidence, severity, and priority
2. **Investigate** — pivot from one indicator to the full story: user → host → process → network → timeline
3. **Escalate** — write the ticket Tier 2 actually wants: scoped, timestamped, defanged, actionable
4. **Verify** — grade an AI's triage summary against the raw logs, catch the hallucinated indicator, and know when to override

Everything runs in the terminal against a shipped **evidence pack** — real-format logs, PCAPs, phishing emails, and alert queues. You investigate with the same tools a working analyst uses (`jq`, `grep`, `tshark`, `dig`, `whois`), which means Phase 5 of your Bash track and this course reinforce each other.

---

## 2. How It Works (RedHat Academy Mechanics)

Same machinery as the Rust and Bash tracks. Clone into WSL2 on Dragon-Zord, everything in the terminal.

### The `lab` CLI

| Command | What it does |
|---|---|
| `lab status` | Phase map with ✓ marks — your progress bar |
| `lab start L4.2` | Opens the lab: prints the brief, stages the evidence |
| `lab check L4.2` | Grades the lab. Pass = next lab unlocked |
| `lab resume` | **Interruption recovery.** Where you stopped, last recap, re-primed in under 30 seconds |
| `lab hint L4.2` | Graduated hints (3 levels, never the full answer first) |

### The Evidence Pack

The kit ships with `data/` — a library of course-built artifacts in real formats:

- **Log bundles** — Linux auth/syslog, Windows Security events and Sysmon (JSON), Zeek `conn`/`dns`/`http` logs, all ECS-normalized where it matters
- **PCAPs** — small, synthetic captures built for each scenario
- **Phishing emails** — `.eml` files with full headers
- **Alert queues** — JSON alert batches with rule metadata, exactly the shape a SIEM emits
- **Mock enrichment reports** — VirusTotal-style, sandbox-style, WHOIS-style outputs, so labs never depend on live third-party services
- **Sigma rules** — the detection logic behind the alerts you triage

**Nothing in the pack is live-hostile.** No real malware, no live malicious infrastructure — attachments are inert simulacra, hashes and detonation reports are mocked. All indicators follow SOC defang discipline (`hxxp://`, `evil[.]com`) — a habit the course enforces because your reports will require it.

### Grading Mechanics

- **TRIAGE / HUNT / PIVOT labs** grade against answer keys: verdict codes, flag-style answers, indicator lists.
- **REPORT labs** grade on a required-elements rubric (timeline present, IOCs defanged, ATT&CK technique ID, verdict, recommendation) — then show you a model report for self-comparison. Honest limitation: the script checks structure, the model answer calibrates quality.
- **VERIFY labs** grade whether you caught the specific flaws planted in the AI summary — including whether its claims cite event IDs that actually exist in the evidence. (Grounding-in-event-IDs is the same contract your own platform holds its agents to.)

### Flat-File First, Security Onion Optional

Every investigation lab works against flat files in `data/` — no VM required, zero setup friction, fully interruption-proof. Selected labs also ship an **optional SO variant**: the same investigation run through the Hunt UI on your `cardinal-so` VM, for console reps when the VM is up. The flat-file path is always the graded path, so a powered-off VM never blocks progress.

---

## 3. Lab Types

Built for analyst work — only GUIDED and TOUR carry over from the code tracks.

| Type | What you do | Skill trained |
|---|---|---|
| **DECODE** | Read an artifact — log, alert, Sigma rule, email header, sandbox report — and answer questions | Artifact literacy |
| **TRIAGE** | Disposition alerts: verdict (TP/FP/BTP) + severity + evidence cited, graded | The core job |
| **HUNT** | Find the malicious events hiding in a log haystack; flag-style answers | Query craft, pattern eye |
| **PIVOT** | Start from one indicator, follow the chain, reconstruct the story and timeline | Investigation |
| **REPORT** | Write the escalation ticket / incident summary; rubric-graded | Communication |
| **VERIFY** | Grade an AI-generated triage summary against raw evidence; catch the planted flaw | **Human-in-the-loop discipline** |
| **TOUR** | Guided walkthrough — ATT&CK Navigator, Security Onion console | Tooling navigation |
| **GUIDED** | Straight follow-along (setup, enrichment tooling) | Environment ops |

**VERIFY is this track's signature type** — the analog of Rust's DIRECT and Bash's TAME. It exists because automation bias is the Tier 1 failure mode of the AI-SOC era, and no other course trains against it deliberately.

---

## 4. ADHD Design Contract

Unchanged from the other tracks — same commitments, honored every lab.

- **Atomic:** every lab completes in 10–20 minutes. "Varies wildly" sessions are the design target.
- **One concept per lab.** Never two.
- **Hard checkpoint every lab.** `lab check` passing = a real, saved win.
- **Re-entry in 30 seconds.** `lab resume` reorients you after a day or a month.
- **Hint ladder, not stuck-spirals.** Three graduated hints before frustration.
- **Zero prerequisite reading.** Everything you need is in the lab brief and the evidence pack.
- **Spaced recall.** The first lab of every phase opens with a 5-question quiz pulling from earlier phases.
- **Even the capstone "shift" is checkpointed.** The final full-shift simulation is segmented — queue, phish, incident — each independently saved, so a shift can span three sittings or one.

---

## 5. Phase Map (Overview)

| Phase | Name | Labs | After this phase you can… |
|---|---|---|---|
| **0** | Toolbelt & Kit | 3 | Run the analyst toolchain; state what Tier 1 owns vs escalates |
| **1** | How Attacks Become Alerts | 8 | Trace any alert back through rule → log → telemetry → adversary action |
| **2** | Network Triage Fundamentals | 7 | Read PCAPs and Zeek logs; spot beaconing and DNS abuse |
| **3** | Endpoint Triage Fundamentals | 7 | Read Windows/Sysmon/Linux telemetry; spot the wrong process tree |
| **4** | Triage Craft & the Queue | 8 | Work a mixed alert queue with defensible verdicts and priorities |
| **5** | Phishing & Malware Triage | 6 | Verdict a reported phish end-to-end; read a sandbox report |
| **6** | Investigation & Escalation | 6 | Pivot to a full timeline; write the escalation Tier 2 wants |
| **7** | The AI-Assisted Analyst | 7 | Verify machine triage against evidence. Capstone shift. |

**52 labs total.** No schedule, no deadlines — a chain of checkpoints. The progress bar waits for you.

---

## 6. Phase Detail

### Phase 0 — Toolbelt & Kit
*Plumbing: the kit, the tools, and the job description.*

| Lab | Title | Type |
|---|---|---|
| L0.1 | Analyst toolbelt — install/verify `jq`, `tshark`, `dig`, `whois`, `ripgrep` | GUIDED |
| L0.2 | Meet the lab CLI and the evidence pack — where everything lives | GUIDED |
| L0.3 | The SOC in one lab — tiers, the alert lifecycle, what Tier 1 owns vs escalates | DECODE |

**Exit gate:** tools respond; given five scenarios, you correctly split "Tier 1 handles" from "Tier 1 escalates."

---

### Phase 1 — How Attacks Become Alerts
*The single mental model that unlocks the job: every alert is the end of a pipeline — adversary action → telemetry → log → normalized event → detection rule → alert. Triage is walking that pipeline backwards. An analyst who understands the pipeline questions alerts; one who doesn't just believes them.*

| Lab | Title | Type |
|---|---|---|
| L1.1 | Telemetry sources — what gets logged where (network, endpoint, identity) | DECODE |
| L1.2 | Anatomy of a log — timestamps, UTC discipline, ECS field names | DECODE |
| L1.3 | Anatomy of an alert — rule metadata, severity, and the evidence behind it | DECODE |
| L1.4 | Reading a Sigma rule — logsource, detection block, condition (your DaC world, from the consumer side) | DECODE |
| L1.5 | MITRE ATT&CK — tactics vs techniques; mapping an alert to a technique ID | TOUR |
| L1.6 | Kill chain & Pyramid of Pain — where an alert sits, what an indicator costs the attacker | DECODE |
| L1.7 | The disposition taxonomy — true positive, false positive, benign true positive, with mini-cases | TRIAGE |
| L1.8 | **Phase gate:** five alerts — name the telemetry source, the technique, and the evidence you'd pull for each | DECODE |

**Job hook:** L1.7's taxonomy is the vocabulary of every verdict you'll ever write. "Benign true positive" (the rule worked, the behavior was authorized) is the category new analysts miss — and the source of half of all bad tickets.

---

### Phase 2 — Network Triage Fundamentals
*TCP/IP for analysts — not the full networking stack, just the layer you need to read a conversation and call it hostile or not.*

| Lab | Title | Type |
|---|---|---|
| L2.1 | Ports, protocols, and conversations — reading a connection log like a sentence | DECODE |
| L2.2 | DNS, the analyst's favorite log — queries, NXDOMAIN storms, tunneling signs, DGA smell | HUNT |
| L2.3 | HTTP and TLS in logs — methods, status codes, user-agents, SNI | DECODE |
| L2.4 | `tshark` first contact — carving answers out of a PCAP from the command line | GUIDED |
| L2.5 | Zeek logs — `conn`, `dns`, `http`, and the fields that carry the verdict | DECODE |
| L2.6 | Beaconing — periodicity, jitter, and C2 shapes in connection logs | HUNT |
| L2.7 | **Phase gate:** one PCAP + Zeek bundle — reconstruct the full session story | HUNT |

**Job hook:** L2.6 is the classic "machine caught it, human confirms it" detection — beacon math is exactly the kind of anomaly your platform surfaces and a Tier 1 analyst must be able to sanity-check by hand.

---

### Phase 3 — Endpoint Triage Fundamentals
*The other half of the telemetry world. Windows event IDs are the analyst's multiplication tables — a small set you simply know cold.*

| Lab | Title | Type |
|---|---|---|
| L3.1 | Windows events that matter — 4624/4625 and logon types, 4688 process creation, 4720 new account | DECODE |
| L3.2 | Sysmon — process trees, parent-child relationships, command lines | DECODE |
| L3.3 | The wrong child — spotting anomalous process ancestry (Office spawning a shell) | HUNT |
| L3.4 | Persistence spots — run keys, scheduled tasks, services, cron | DECODE |
| L3.5 | Linux auth and audit logs — SSH brute force, sudo abuse, new users | HUNT |
| L3.6 | LOLBins — when the attack is a legitimate tool (encoded PowerShell, certutil, `curl \| bash` from the other side) | DECODE |
| L3.7 | **Phase gate:** endpoint log bundle — find the full compromise chain | HUNT |

**Job hook:** L3.6 closes a loop with your Bash track — Phase 4 there taught you to *audit* a `curl | bash` installer; here you learn what one looks like *in victim telemetry*. Same attack, both sides of the glass.

---

### Phase 4 — Triage Craft & the Queue
*The core job, formalized. Triage is not intuition — it's a fixed question sequence applied fast: what fired, what's the actual evidence, is this expected for this user/host, what's the scope, verdict.*

| Lab | Title | Type |
|---|---|---|
| L4.1 | The triage method — the five questions, applied to one alert slowly | DECODE |
| L4.2 | Indicator enrichment — hash, IP, domain lookups; reading VT-style and WHOIS-style reports | GUIDED |
| L4.3 | Reputation is not a verdict — enrichment traps: shared hosting, CDN IPs, stale scores | TRIAGE |
| L4.4 | Brute force vs password spray — the auth-log classics, told apart by shape | TRIAGE |
| L4.5 | Severity and priority — ten alerts, which first, and why | TRIAGE |
| L4.6 | The false-positive mines — noisy rules, admin behavior, and writing tuning feedback | TRIAGE |
| L4.7 | **Queue shift I** — twelve mixed alerts, full dispositions with evidence, graded | TRIAGE |
| L4.8 | **Phase gate: Queue shift II** — new queue, tighter grading, includes one alert that deserves escalation | TRIAGE |

**Job hook:** L4.6 is where the analyst becomes valuable to detection engineering — a Tier 1 who writes *specific* tuning feedback ("exclude host X's backup job, matched on command-line pattern Y") feeds the rule lifecycle instead of just draining the queue. That feedback loop is a pillar of your own platform design.

---

### Phase 5 — Phishing & Malware Triage
*Bread-and-butter Tier 1: the user-reported phish. Full pipeline from raw email to verdict — headers, URLs, attachments, detonation report.*

| Lab | Title | Type |
|---|---|---|
| L5.1 | Email headers — reading the Received chain; SPF, DKIM, DMARC results | DECODE |
| L5.2 | URL analysis — redirect chains, lookalike domains, punycode, defang discipline | DECODE |
| L5.3 | Attachment triage — true file types vs extensions, hashes, macro risk, safe-handling rules | DECODE |
| L5.4 | Reading a sandbox report — verdicting from a detonation summary without touching the sample | DECODE |
| L5.5 | The phish queue — six reported emails, verdict each (including the legitimate one) | TRIAGE |
| L5.6 | **Phase gate:** full phish investigation — email → indicators → enrichment → verdict → report | REPORT |

**Job hook:** L5.5 includes a *legitimate* email on purpose. Calling everything malicious is as much a failure as missing the phish — false positives on user reports burn helpdesk trust.

---

### Phase 6 — Investigation & Escalation
*From alert-handler to investigator: pivoting, timelines, scoping, and the writing that makes Tier 2 respect your tickets.*

| Lab | Title | Type |
|---|---|---|
| L6.1 | Pivoting — one indicator to the full story: user → host → process → network | PIVOT |
| L6.2 | Timeline building — normalize timestamps, order events, UTC everywhere | PIVOT |
| L6.3 | Scoping — one host or ten? The queries that answer it | HUNT |
| L6.4 | Writing the ticket — the escalation package: scope, timeline, indicators, technique, recommendation | REPORT |
| L6.5 | Incident communication — what you say, to whom, when; the shift handoff | DECODE |
| L6.6 | **Phase gate:** full investigation — from one alert to a graded escalation report | REPORT |

**Job hook:** L6.4's rubric *is* the required-elements checklist Tier 2 triages your ticket by. A great investigation with a bad writeup is a bad investigation, operationally.

---

### Phase 7 — The AI-Assisted Analyst
*The chair your platform is built around. AI triage summaries are fast, confident, and sometimes wrong — and "the AI said benign" is not a verdict. Expert level here means the machine makes you faster without ever making the call for you.*

| Lab | Title | Type |
|---|---|---|
| L7.1 | Automation bias — the documented failure modes of analysts supervising machines | DECODE |
| L7.2 | **VERIFY reps I** — three AI triage summaries vs raw evidence; one is subtly wrong | VERIFY |
| L7.3 | Directing AI in an investigation — evidence-first prompting; what AI is good and bad at mid-incident | DECODE |
| L7.4 | **VERIFY reps II** — the hallucinated indicator, the wrong pivot, the ungrounded claim (does every claim cite a real event ID?) | VERIFY |
| L7.5 | Override discipline — when to accept, when to override, and how your feedback improves the detections | DECODE |
| L7.6 | **Capstone shift** — a full segmented shift: alert queue + phish + one real incident, AI assist available, everything graded | TRIAGE |
| L7.7 | **Capstone gate:** incident report + tuning recommendation — the analyst-to-detection-engineering handoff, complete | REPORT |

**Job hook:** L7.4's grading rule — *every AI claim must cite an event ID that exists in the evidence* — is the same grounding contract your architecture imposes on its own agents. You're training the human half of the loop you designed.

---

## 7. Delivery Plan

Built **one phase at a time**, same as the other tracks. Each delivery is interruption-safe.

1. **You approve this map** (edits welcome — labs can be added, cut, or reordered).
2. **First build ships Phase 0 + Phase 1 together** — plumbing plus the mental-model phase, as a zip: working `lab` CLI, evidence pack, all check scripts. Unzip into WSL2, run `lab status`.
3. **Each later phase ships as a drop-in folder** + one command to register it. Your progress file is never touched.
4. Between phases, anything can be adjusted based on what worked.

The `lab` CLI and check harness are **shared across all three tracks** — Rust, Bash, and this one register into the same tooling, and `lab status` shows every track side by side.

---

## 8. Open Items for Your Review

- **Name:** `soc-analyst-lab` is a working title. Rename freely.
- **Security Onion mode:** currently an optional overlay on selected labs (flat-file path is always the graded path). Say the word to make SO variants first-class in Phases 2–4, or to drop them entirely.
- **Certification alignment:** the curriculum can carry loose mapping tags to CySA+ / BTL1 / Security+ objectives (you've done SY0-701 mapping before with Adversary-in-a-Box). Off by default — one line per lab if you want it.
- **Enrichment:** mock reports by default (offline-proof). Optional live-lookup variants (real WHOIS/dig, real VT web checks) can be added to L4.2.
- **Audience fork:** this map is built for you, at full depth. A TLT/intern edition — same kit, gentler pacing, added scaffolding — is a straightforward fork if you ever want it.

---

*v1.0 — awaiting approval before Phase 0+1 build.*
