# LAB-KIT — `ps` Track, Phase 6 — Reading Real Security Tools — BUILD PLAN

**Status:** **APPROVED FOR BUILD** (v1.1, 2026-07-29 — every `[VERIFY-AT-BUILD]` item resolved
against real pwsh 7.6.4; see §7). Binding content spec:
`docs/curriculum/powershell-literacy-lab-curriculum-v1.md` (Phase 6, §6 lines 205–216).
Binding mechanical spec: `docs/kit-contracts.md`. Track conventions inherited unchanged
from `docs/plans/ps-p01-plan.md` (§2a/§2b/§2c) and ps-p2/3/4/5. Executes under
`TRACK: ps  PHASE: 6`.

> **How this plan was verified.** v1 was authored with **no pwsh available**, so every runtime
> claim was flagged rather than tested. **v1.1 (2026-07-29) ran them against real pwsh 7.6.4 on
> Linux** — see §7 for what each check actually returned, including one item (`Get-WinEvent` not
> existing off Windows) that constrains how L6.3 may be graded, and one (the Sigma rule's
> "what it misses" claim) tested concretely against the phase-5 artifacts rather than asserted.
> Phase 6
> is a **TOUR phase — tool navigation, not memorization** (map §6). Every lab reads
> **provided, sanitized tool code/output**; nothing is executed. The one offensive tool
> (PowerView, L6.1) is **name/structure-level and sanitized** exactly like Empire in L4.8 —
> function names + what data they collect, never a runnable offensive tool. Live behaviors
> that need Windows (AD queries, `Get-WinEvent` against Windows logs) are **read from shipped
> samples** and flagged `[WINDOWS-VARIANT]`; a **Sigma rule (L6.4) is plain YAML, fully
> cross-platform to read.** Runtime facts were flagged `[VERIFY-AT-BUILD]` and are now RESOLVED in §7. **The build
> session must run the per-lab adversarial correctness pass ps-p01 used before self-test.**

---

## 0. Context — why this plan exists

Phase 6 (map §6): *production PowerShell, defender and attacker — the goal is tool navigation,
not memorization.* The learner has read pipelines (P1), logic (P2), the Windows layer (P3),
attack patterns (P4), and can deobfuscate (P5); Phase 6 applies all of it to **real tools**:
PowerView (offensive AD enum), a PS IR collector, a threat-hunting script, and a PS-targeted
Sigma rule — closing back to the detection-engineering connection (map §6; cross-track to
bash/SOC). It ends on a **cold solo tour** of an unseen tool (L6.5).

**5 labs (L6.1–L6.5). All TOUR.**

### Two load-bearing facts this phase turns on (settled — build must honor)

1. **Everything is read, nothing is run.** Tours grade **comprehension of shipped, sanitized
   artifacts** (tool source excerpts, sample output, a Sigma YAML). PowerView is sanitized
   structure (map §6, like L4.8). `check.sh` executes **no** security tool. (§3a.)
2. **Reading a detection rule closes the loop.** L6.4 reads a **Sigma rule** (plain YAML,
   cross-platform) that targets the very PS behaviors Phases 4–5 taught — the explicit tie to
   detection engineering (cross-track: bash L7.5 posture, SOC detections; curriculum §7). (§3c.)

### Safety-by-design posture (carry-through)

Offensive content (PowerView) is **sanitized structure / function-name level** — no runnable
offensive capability (mirrors L4.8). Defensive tools (IR collector, threat-hunt, Sigma) are
readable but **not executed** by `check.sh`. Any host/URL/IP in samples is fictional/defanged.
Nothing that could enumerate a real domain or read real security logs is run.

---

## 1. Confirmed lab list (read from the map — ids/titles/types verbatim)

**Phase 6 — Reading Real Security Tools (5).** Gate: **L6.5**. No mid-phase gates.

| id | title | type | gate? | win-variant | est_min |
|----|-------|------|-------|-------------|---------|
| L6.1 | Tour: PowerView — AD enumeration functions, what data they collect & why | TOUR | **yes-gate?** no | **yes** (sanitized) | 20 |
| L6.2 | Tour: a PS IR collector — what telemetry it pulls, reading the output | TOUR | no | partial (shipped output) | 20 |
| L6.3 | Tour: a threat-hunting script — `Get-WinEvent` pipelines over security logs | TOUR | no | **yes** | 20 |
| L6.4 | Tour: a Sigma rule targeting PS (detection-engineering tie) | TOUR | no | no (YAML, cross-platform) | 20 |
| L6.5 | **Phase gate:** solo tour of an unseen PS security tool, answer cold | TOUR | **yes** | partial (shipped tool) | 25 |

**Gate placement.** L6.5 (`gate:true`) — a cold solo tour + Q&A. Worksheet + `answers.md` +
3-question gate quiz (3/3), per the established pattern. (L6.1 is a normal lab, not the gate.)

**Recall placement:**
- **L6.1** — Phase-6 opener → `recall.json`, 5 Qs from **Phase 4 + Phase 5** (both planned,
  not built → sourced from the curriculum's Phase 4/5 lab list, `[VERIFY-AT-BUILD]`,
  reconciled with the L6.1 recall **forward-drafted under ps-p5 §4 (L5.7)**).
- **L7.1** — Phase-7 opener → drafted during the **L6.5 build** (5 Qs from Phase 5 + 6).

---

## 2. Track-wide build conventions (inherited — restated, plus the Phase-6 read-only rule)

**File set per lab** (kit-contracts): standard; dir grammar `tracks/ps/phases/p6/L6.<n>-<slug>/`.

**§2a grader architecture (inherited).** TOUR labs grade a **learner comprehension artifact**
(`tour.md`/`readout.md`) extracted from a **shipped, sanitized** tool excerpt or sample output
in `files/`. No security tool is executed. Where a trivially safe, cross-platform sub-fact
exists (e.g. counting event-record fields in a shipped sample via a benign one-liner), a probe
may be used — but the default is static comprehension.

**§2b grader hygiene (inherited).** Real `assert_output_contains` signature; `.NET`/dotted and
function-name literals via `assert_file_contains_fixed` (e.g. `Get-NetUser`, `Get-WinEvent`);
free text via case/word-tolerant ERE; set-e traps.

**➕ §2c — Phase-6 read-only rule (build MUST enforce, step-5 self-check):**
- No `check.sh` executes PowerView / the IR collector / the threat-hunt script / any AD or
  `Get-WinEvent` query. PowerView content is **sanitized structure**; all samples are shipped,
  fictional/defanged, and read statically.

**➕ Windows-variant rule (inherited).** `[WINDOWS-VARIANT]` labs (L6.1 AD, L6.3 `Get-WinEvent`)
set `meta.json` `"windows_variant": true` and grade static reading of shipped samples; L6.2/
L6.5 read shipped output/tools (partial). L6.4 (Sigma YAML) is cross-platform to read.

---

## 3. Phase-6-specific decisions

### 3a. All-TOUR phase → grade navigation of shipped, sanitized artifacts

Five TOUR labs. The skill is *navigating an unfamiliar tool and stating what it does* — so each
lab ships a **sanitized excerpt** (function list, a piece of source, sample output, a YAML rule)
and grades the learner's `tour.md` for the load-bearing observations (which functions collect
what, which log a hunt reads, what a Sigma rule matches). Nothing is executed.

### 3b. PowerView is sanitized structure (like L4.8)

L6.1 ships PowerView's **function catalog + data-collected** at name level (`Get-NetUser`,
`Get-NetGroup`, `Get-NetComputer`, `Find-LocalAdminAccess`, `Get-NetGPO`, `Invoke-ShareFinder`)
— what each enumerates and why it matters to an attacker/defender — **not** a runnable copy.
Bridges to the map's "why PowerView" note (standard AD-enum tool) and Phase-4 Empire/PowerSploit.

### 3c. L6.4 (Sigma) closes the detection-engineering loop

A **Sigma rule** is provider-agnostic YAML — fully cross-platform to read. L6.4 ships a Sigma
rule targeting the PS behaviors Phases 4–5 taught (e.g. a `powershell.exe -enc` command line or
a 4104 `DownloadString`+`iex` ScriptBlock) and has the learner read `detection:`/`condition:` to
say **what it matches and what it would miss** — the same detection posture as bash L7.5 and the
SOC track (curriculum §7).

### 3d. The L6.5 gate: cold solo tour → worksheet + 3-question gate quiz

Ship an **unseen** sanitized PS security tool (e.g. a small log-forwarder or IOC-scanner
excerpt). The learner tours it cold: what it does, what it collects/matches, what subsystem it
touches. Worksheet → `answers.md` (set-e-safe ≥N-of-M threshold); 3-question gate quiz (3/3)
forces the load-bearing reads.

---

## 4. Phase 6 — lab-by-lab build spec

> Phase-6 spine: *navigate a real tool cold and state what it does.* Every lab reads a shipped,
> sanitized artifact; nothing is executed.

### L6.1 — Tour: PowerView · TOUR · **Phase-6 opener** · **`[WINDOWS-VARIANT]`** · est 20m

**Teaching artifact (TOUR — sanitized function catalog, static).** PowerView is the standard AD
enumeration tool. Read the **function names + what each collects**, not a runnable copy.

```text
# SANITIZED catalog (names + purpose only — no runnable tool):
Get-NetUser              → domain user objects (names, SPNs, lastlogon, description) — recon
Get-NetGroup             → group memberships (find Domain Admins, nested groups)
Get-NetComputer          → domain computers (OS, when-created) — targeting
Find-LocalAdminAccess    → hosts where the current user is local admin — lateral-movement mapping
Get-NetGPO / Get-NetOU   → GPO/OU structure — policy & delegation recon
Invoke-ShareFinder       → readable/writable network shares — data discovery
```

TOUR moment: PowerView's `Get-Net*` verbs enumerate **AD objects** (users, groups, computers,
GPOs, shares); `Find-LocalAdminAccess` maps lateral-movement paths. Reading the function name
tells you the **data collected** and the **ATT&CK phase** (T1087 Account Discovery, T1069 Groups,
T1135 Shares). Windows/domain-only at runtime.

**Environment note — `[WINDOWS-VARIANT]`.** AD queries need a domain; nothing runs on WSL2.
Graded path = static reading of the shipped catalog. `meta.json` `"windows_variant": true`. No
runnable PowerView is shipped.

**check.sh grades** (static comprehension):
- ship `files/powerview-catalog.txt`. learner writes `tour.md` mapping ≥3 functions → data
  collected + ATT&CK phase. `assert_file_exists tour.md`,
  `assert_file_contains_fixed tour.md 'Get-NetUser'`,
  `assert_file_contains tour.md '[Ee]numerat|[Rr]econ|AD|[Dd]omain'`,
  `assert_file_contains tour.md 'T1087|T1069|T1135|[Ll]ateral'`.

**Quiz (3):**
1. *(choice)* What does `Get-NetUser` collect? → **domain user objects (recon of accounts/SPNs/
   attributes)**. *(distractor: "local Linux users")*
2. *(text)* Which PowerView function maps where you're a local admin (lateral movement)? →
   **`Find-LocalAdminAccess`**.
3. *(choice)* Why tour PowerView by function name? → **the name tells you the data collected and
   the ATT&CK phase — recognition in telemetry, without running it**. *(distractor: "to compile
   it")*

**Recap (3 lines):**
```
PowerView Get-Net* functions enumerate AD objects (users, groups, computers, GPOs, shares) — recon
Find-LocalAdminAccess maps lateral-movement paths; function name = data collected = ATT&CK phase
Windows/domain-only; you tour the sanitized catalog statically (T1087/T1069/T1135)
```

**recall.json (L6.1 — 5 Qs from Phase 4 + 5) — `[VERIFY-AT-BUILD]` (reconcile with ps-p5 L5.7
forward-draft):**
1. `source: ps L5.1` — After decoding a 4104 blob, what must you never do? → **pipe it to `iex`**.
2. `source: ps L5.3` — What does `-f` do in obfuscation? → **reorders indexed args to reassemble a keyword**.
3. `source: ps L4.5` — Which Event ID carries the decoded ScriptBlock? → **4104**.
4. `source: ps L5.4` — What does `$s[-1..-$s.Length] -join ''` do? → **reverses the string**.
5. `source: ps L4.6` — Name a LOLBin for download/proxy execution. → **`certutil`/`mshta`/`rundll32`/`regsvr32`**.

---

### L6.2 — Tour: a PS IR collector · TOUR · *(reads shipped output)* · est 20m

**Teaching artifact (TOUR — shipped collector excerpt + sample output).** An incident-response
collector gathers host evidence. Read **what it pulls** and **how to read the output**.

```powershell
# SHIPPED excerpt (read; not executed) — a triage collector's evidence set:
Get-Process | Select-Object Name,Id,Path                        # running processes
Get-CimInstance Win32_StartupCommand                            # autostart entries (persistence)
Get-WinEvent -FilterHashtable @{LogName='Security';Id=4624}      # logon events
Get-ChildItem "$env:TEMP" -Recurse -File | Select FullName,Length,LastWriteTime  # dropped files
# → writes a structured report (JSON/CSV) per section
```

TOUR moment: an IR collector = **processes + autostart + relevant events + suspicious files**,
serialized to a report. Reading the collector tells you **what evidence exists** and how to
read each section. Some cmdlets are cross-platform (`Get-Process`), some Windows (`Get-WinEvent`,
`Win32_StartupCommand`).

**Environment note.** Read a **shipped** collector excerpt + a **shipped** sample report; nothing
runs. Windows-only sections are read statically. `[VERIFY-AT-BUILD]`: sample report shape.

**check.sh grades** (static comprehension of shipped output):
- ship `files/collector.ps1` (excerpt, read-only) + `files/sample-report.json`. learner writes
  `readout.md` naming ≥3 evidence categories the collector pulls. `assert_file_exists readout.md`,
  `assert_file_contains readout.md '[Pp]rocess'`, `assert_file_contains readout.md
  '[Aa]utostart|[Ss]tartup|persist'`, `assert_file_contains readout.md '[Ll]ogon|4624|[Ee]vent'`.

**Quiz (3):**
1. *(text)* Name two evidence categories an IR collector pulls. → **processes, autostart,
   logon events, suspicious files** *(any two)*.
2. *(choice)* Why serialize to JSON/CSV? → **structured output an analyst (or SIEM) can parse
   and diff**. *(distractor: "to hide it from the user")*
3. *(choice)* Event ID 4624 in the collector means? → **successful logon events**. *(distractor:
   "process creation")*

**Recap (3 lines):**
```
a PS IR collector pulls processes, autostart, key events (e.g. 4624 logons), and suspicious files
it serializes each section to a structured report (JSON/CSV) for analyst/SIEM parsing
you tour it to know what evidence exists and how to read each section — never by running it
```

**recall.json:** none.

---

### L6.3 — Tour: a threat-hunting script · TOUR · **`[WINDOWS-VARIANT]`** · est 20m

**Teaching artifact (TOUR — shipped hunt script over event logs, static).** Threat hunts read
security logs with `Get-WinEvent` pipelines. Read **which log, which IDs, and what the pipeline
looks for**.

```powershell
# SHIPPED hunt (read; Get-WinEvent is Windows-only) — hunt for encoded PowerShell:
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-PowerShell/Operational';Id=4104} |
  Where-Object { $_.Message -match '-enc|FromBase64String|DownloadString' } |
  Select-Object TimeCreated, @{N='Script';E={$_.Message}}
```

TOUR moment: the hunt reads **4104 ScriptBlock** events (L4.5) and filters `Message` for the
obfuscation/cradle tells Phases 4–5 taught — a direct application of everything prior. `Get-WinEvent`
+ `-FilterHashtable` is the standard log-query idiom. Windows-only at runtime.

**Environment note — `[WINDOWS-VARIANT]`.** `Get-WinEvent` reads Windows event logs; nothing runs
on WSL2. Graded path = static reading of the shipped hunt (+ a shipped sample of matched rows).
`meta.json` `"windows_variant": true`.

**check.sh grades** (static comprehension):
- ship `files/hunt.ps1` (read-only). learner writes `readout.md`: which log/ID the hunt reads
  and what the `-match` filter looks for. `assert_file_exists readout.md`,
  `assert_file_contains readout.md '4104'`, `assert_file_contains_fixed readout.md 'Get-WinEvent'`,
  `assert_file_contains readout.md '[Ee]ncod|DownloadString|base64|cradle'`.

**Quiz (3):**
1. *(choice)* Which log/ID does this hunt read? → **the PowerShell/Operational log, Event ID
   4104 (ScriptBlock)**. *(distractor: "the Security log, 4624")*
2. *(text)* Which cmdlet + parameter is the standard event-query idiom? → **`Get-WinEvent
   -FilterHashtable`**.
3. *(choice)* What does the `-match` filter hunt for? → **obfuscation/cradle tells (`-enc`,
   `FromBase64String`, `DownloadString`) in the decoded ScriptBlock**. *(distractor: "failed
   logons")*

**Recap (3 lines):**
```
threat hunts read security logs with Get-WinEvent -FilterHashtable pipelines (Windows-only)
this hunt reads 4104 ScriptBlock events and -matches the -enc/base64/DownloadString tells (P4-P5)
you tour the hunt statically to see which log, which IDs, and what pattern it looks for
```

**recall.json:** none.

---

### L6.4 — Tour: a Sigma rule targeting PS · TOUR · est 20m

**Teaching artifact (TOUR — Sigma YAML, cross-platform to read).** Sigma is provider-agnostic
detection YAML. Read `detection:`/`condition:` to say **what it matches and what it misses**.

```yaml
# SHIPPED Sigma rule (read):
title: Suspicious PowerShell Download Cradle
logsource: { product: windows, service: powershell }   # maps to 4104 ScriptBlock
detection:
  selection:
    ScriptBlockText|contains:
      - 'DownloadString'
      - 'IEX'
      - 'FromBase64String'
  condition: selection
level: high
```

TOUR moment: a Sigma rule = `logsource` (which telemetry) + `detection.selection` (the match
criteria) + `condition` (how selections combine). This rule fires on a 4104 event whose
ScriptBlock contains cradle/decoder tells — encoding the exact recognition Phases 4–5 taught.
Reading it, you can also say what it **misses** (e.g. concat/format-string obfuscation that never
literally spells `IEX`). This is the detection-engineering tie (cross-track: bash L7.5, SOC).

**Environment note.** Plain YAML — **fully cross-platform to read**. No `[WINDOWS-VARIANT]`;
nothing runs. `[VERIFY-AT-BUILD]`: keep the YAML well-formed.

**check.sh grades** (static comprehension):
- ship `files/rule.yml`. learner writes `readout.md`: the logsource, the match strings, and one
  evasion the rule misses. `assert_file_exists readout.md`,
  `assert_file_contains readout.md '4104|[Ss]cript.?[Bb]lock|logsource'`,
  `assert_file_contains_fixed readout.md 'DownloadString'`,
  `assert_file_contains readout.md '[Mm]iss|[Ee]va(de|sion)|concat|format|obfusc'`.

**Quiz (3):**
1. *(choice)* What do a Sigma rule's `logsource` + `detection.selection` specify? → **which
   telemetry to read and the match criteria**. *(distractor: "the response action to take")*
2. *(choice)* This rule matches on which telemetry? → **4104 ScriptBlock text containing
   `DownloadString`/`IEX`/`FromBase64String`**. *(distractor: "network firewall logs")*
3. *(text)* Name an obfuscation this literal-string rule would MISS. → **concatenation /
   format-string / reversal that never literally spells the keyword** (L5.2–5.4).

**Recap (3 lines):**
```
Sigma is provider-agnostic detection YAML: logsource (telemetry) + detection.selection + condition
this rule fires on 4104 ScriptBlock text containing DownloadString/IEX/FromBase64String — the P4-P5 tells
reading it, you also see what it MISSES (concat/format/reversal) — the detection-engineering loop
```

**recall.json:** none.

---

### L6.5 — Phase gate: solo tour of an unseen PS security tool · TOUR · **GATE** · est 25m

**Teaching artifact (TOUR — the integrative gate, cold read).** Ship an **unseen**, sanitized PS
security tool (e.g. a small IOC scanner or log-forwarder excerpt) the learner tours cold: what it
does, what it collects/matches, which Windows subsystem(s) it touches, and its detection value.
Worksheet → `answers.md`; 3-question gate quiz (3/3).

`files/mystery-tool.ps1` (shipped, sanitized, defanged — e.g. an IOC scanner):
```powershell
# reads a hash/indicator list, scans processes + a directory, reports matches (read; not run)
$iocs = Get-Content ./iocs.txt
Get-Process | Where-Object { $iocs -contains $_.Path } | Select-Object Name,Id,Path
Get-ChildItem C:\Users -Recurse -File -ErrorAction SilentlyContinue |
  Get-FileHash | Where-Object { $iocs -contains $_.Hash } | Select-Object Path,Hash
```

**check.sh grades** (worksheet threshold; static; executes nothing):
- ship `files/mystery-tool.ps1` (+ `files/iocs.txt`). `assert_file_exists answers.md`, then a
  **set-e-safe ≥N-of-M threshold** over: `IOC|indicator`, `[Pp]rocess`, `[Hh]ash|Get-FileHash`,
  `[Ss]can|[Mm]atch`, `[Dd]etect` — require ≥3 of 5.

**Quiz (3) — the gate:**
1. *(choice)* What does the toured tool do? → **scans running processes and files against an IOC
   list and reports matches (an IOC scanner)**. *(distractor: "obfuscates a payload")*
2. *(text)* Which cmdlet computes file hashes for IOC matching? → **`Get-FileHash`**.
3. *(choice)* Touring an unseen tool, what do you state first? → **what it does + what it
   collects/matches + which subsystem it touches** — navigation, not memorization. *(distractor:
   "its exact line count")*

**Recap (3 lines):**
```
you can now tour an unseen PS security tool cold: what it does, what it collects/matches, which subsystem
an IOC scanner walks processes/files and compares against indicators (Get-FileHash) — read it, name it
tool navigation, not memorization — the skill that carries into reading anything in Phase 7
```

**recall.json:** none on L6.5 (gate). **Build deliverable (step 6): draft L7.1's `recall.json`**
— 5 Qs from Phase 5 + 6, all `[VERIFY-AT-BUILD]`:
1. `source: ps L6.4` — What does a Sigma rule's `detection.selection` specify? → **the match criteria against a logsource**.
2. `source: ps L6.1` — What does PowerView's `Get-NetUser` collect? → **domain user objects (AD recon)**.
3. `source: ps L5.7` — After reconstructing an obfuscated payload, what do you do? → **name the technique + escalate; never run it**.
4. `source: ps L6.3` — Which Event ID does the threat-hunt read? → **4104 (ScriptBlock)**.
5. `source: ps L5.1` — base64 in a 4104 blob decodes with which encoding? → **UTF-16LE**.

---

## 5. Build order, self-test, phase-close (Phase Builder protocol)

1. Scaffold `tracks/ps/phases/p6` (+ `phases.p6` in `track.json` if enumerated). Assumes Phases
   0–5 built first.
2. Build **lab by lab in id order** (L6.1 → L6.5). Commit each after self-test.
3. **Self-test (no-fiction rule):** these are static tours — the self-test confirms each `check.sh`
   grades the shipped artifact correctly (fail + pass). For `[WINDOWS-VARIANT]` tools (PowerView,
   `Get-WinEvent` hunt) the shipped samples are read on WSL2; no Windows session required. Resolve
   `[VERIFY-AT-BUILD]` (§7).
4. **shellcheck-zero + lint:** each `check.sh` passes `tools/shellcheck-all.sh` + `tools/lint-labs.sh`.
   Phase-6 graders are **pwsh-free static** (comprehension of shipped `files/`); ship every artifact
   (`powerview-catalog.txt`, `collector.ps1`+`sample-report.json`, `hunt.ps1`, `rule.yml`,
   `mystery-tool.ps1`+`iocs.txt`).
5. **Safety self-check (build gate):** grep the phase — **no** `check.sh` executes PowerView / the
   collector / the hunt / any AD or `Get-WinEvent` query; PowerView is sanitized structure; all
   samples fictional/defanged.
6. **Gate:** L6.5 `gate:true`; `quiz_run` requires 3/3.
7. **Recall:** L6.1's `recall.json` ships now (`[VERIFY-AT-BUILD]` vs built Phase 4/5); L7.1's is
   drafted now (§4, L6.5).
8. **Close out:** update `planned_execution.md` (`ps p6` → done + evidence); tag `ps-p6`.

**Phase Acceptance Checklist:** 5 labs, all TOUR, gate L6.5; the safety self-check (step 5) passes;
`[WINDOWS-VARIANT]` labs (L6.1, L6.3) flagged + statically graded; every artifact shipped and
comprehension-graded; shellcheck + lint clean; gate 3/3; L6.1 recall ships + L7.1 drafted;
`planned_execution.md` updated; tagged `ps-p6`.

---

## 6. Verification summary (authoring pass — corrections pre-folded from ps-p01..p5)

No pwsh executed this session. Carried-forward decisions:
- **Read-only tours (§3a, §5 step 5):** every lab grades comprehension of a shipped, sanitized
  artifact; no security tool is executed; PowerView is sanitized structure (like L4.8).
- **Detection-engineering tie (§3c):** L6.4 reads a Sigma rule (cross-platform YAML) targeting the
  P4–P5 tells and asks what it misses — the cross-track loop (bash L7.5, SOC).
- **Windows-variant (§2):** L6.1 (AD), L6.3 (`Get-WinEvent`) flagged, statically graded; L6.4 is
  cross-platform.
- **Hygiene (§2b):** function-name literals via `assert_file_contains_fixed` (`Get-NetUser`,
  `Get-WinEvent`); free text via case/word-tolerant ERE.
- **Recall rule honored:** L6.1 recall from the curriculum's Phase 4/5 lab list (`[VERIFY-AT-BUILD]`),
  reconciled with ps-p5's L5.7 forward-draft.

**The build session must still run the per-lab adversarial correctness pass ps-p01 used** and resolve
§7 before shipping.

---

## 7. `[VERIFY-AT-BUILD]` items — RESOLVED (verified against real pwsh 7.6.4 on Linux, 2026-07-29)

| lab | item | result |
|---|---|---|
| L6.1 | PowerView catalog sanitized; ATT&CK IDs accurate | **Confirmed.** T1087 Account Discovery, T1069 Permission Groups Discovery, T1135 Network Share Discovery are the right mappings for the enumeration families the catalog names. The catalog ships as names + purpose only — no runnable tool, nothing importable. Recall reconciled with the ps-p5 §8 forward-draft: same 5 questions, same sources (L5.1, L5.3, L4.5, L5.4, L4.6), same answers. **Ship §8's version verbatim** — it is already choice-typed where this plan's sketch used free text. |
| L6.2 | `sample-report.json` shape coherent; 4624 = logon | **Confirmed.** A four-section report (`processes`, `autostart`, `logons`, `tempFiles`) round-trips through `Get-Content -Raw \| ConvertFrom-Json` in pwsh 7.6.4 and the nested arrays address cleanly (`$r.sections.logons[0].EventId` → `4624`). 4624 is a successful logon. Build the shipped sample to that shape. |
| L6.3 | `Get-WinEvent` Windows-only; static grade holds | **Confirmed, and it constrains the build.** `Get-Command Get-WinEvent` returns nothing in pwsh 7.6.4 on Linux — the cmdlet does not exist off Windows. So `hunt.ps1` is read-only teaching material and **`check.sh` must never invoke it**; grading is static comprehension of the shipped script only. Same treatment L6.2's Windows-only sections get. |
| L6.4 | `rule.yml` well-formed Sigma; "what it misses" accurate | **Confirmed, both parts.** The rule parses as valid YAML (`logsource` + `detection.selection` + `condition` + `level`). The miss-claim was tested concretely rather than asserted: matching the rule's literal strings case-insensitively against the phase-5 artifacts, the **L5.2 concatenated form, the L5.3 format-string form, and the L5.7 gate blob all evade it**, while the decoded plaintext fires on `DownloadString`+`IEX`. That is exactly the lesson — and it means the "what it misses" answer can cite labs the learner has already done. |
| L6.5 | `Get-FileHash` IOC scan reads correctly | **Confirmed.** `Get-FileHash` exists and works cross-platform in pwsh 7.6.4 on Linux (SHA256 verified against a known input), so the gate's IOC-scan tour reads correctly on this machine and can genuinely be run if a lab wants to. |

### Build-time corrections this pass also fixes

`lib/quiz.sh` grades text answers by **exact normalized match plus an accept list** — no set logic,
no partial credit. Three quizzes as sketched are therefore ungradeable and must be narrowed at
build, the same correction already applied at L4.9, L5.5, L5.6 and L5.7:

- **L6.2 Q1** — "Name two evidence categories … *(any two)*" → ask for one category, or make it choice.
- **L6.4 Q3** — "Name an obfuscation this rule would MISS" → pin to a single token with an accept list.
- **L6.1 recall Q1/Q2/Q4** — free text as sketched here; ps-p5 §8 already converted them to choice. Use §8.

Also inherited from the p5 build and expected to apply here: every shipped read-only artifact a
grader executes must be byte-checked with `assert_file_unmodified` before it runs, and the run must
sit behind a `CK_FAIL -eq 0` guard. In this phase only L6.5's `Get-FileHash` tour could run anything
at all; the other four labs grade static comprehension and execute nothing.

---

*Plan v1 authored from curriculum §6 + the settled ps-p01..p5 template; **v1.1 (2026-07-29) resolves
every `[VERIFY-AT-BUILD]` item above against real pwsh 7.6.4 and marks this plan APPROVED FOR BUILD.**
Build proceeds lab by lab under this plan.*

---

## 8. Handoff: L7.1 `recall.json` (drafted during the L6.5 build, per §5 step 7)

Phase-7's opener carries the 5-question recall warm-up drawn from Phases 5 + 6. Drafted here at
the end of the p6 build so the p7 builder inherits it rather than re-deriving it. Every question
was checked against the lab that actually shipped, not against this plan's intentions — sources
are the merged L5.1/L5.7 (ps-p5) and L6.1/L6.3/L6.4 (ps-p6).

Q1–Q3 are choice-type rather than the free text §4 sketched: `lib/quiz.sh` grades text by exact
normalized match plus an accept list, so open "explain what X specifies" prompts are ungradeable.
Q4 and Q5 stay text because their answers are single pinned tokens. Same correction applied at
L4.9, L5.5, L5.6, L5.7 and throughout p6.

One thing to fix while shipping this: the equivalent L6.1 recall (drafted as ps-p5 §8) had its
first question ask what you must *never* do while grading the *safe* option correct, which pulls a
literal reader toward the wrong choice. That was corrected in the shipped `recall.json` but not in
the ps-p5 plan text. Don't reintroduce the inverted-stem shape here.

```json
{
  "questions": [
    {
      "id": 1,
      "source": "ps L6.4",
      "type": "choice",
      "prompt": "What does a Sigma rule's detection.selection specify?",
      "options": {
        "a": "The criteria that must match within the telemetry named by logsource",
        "b": "The response action to run when the rule fires"
      },
      "answer_b64": "YQ=="
    },
    {
      "id": 2,
      "source": "ps L6.1",
      "type": "choice",
      "prompt": "What does PowerView's Get-NetUser collect?",
      "options": {
        "a": "Local accounts on the host it runs from",
        "b": "Domain user objects — the AD account inventory"
      },
      "answer_b64": "Yg=="
    },
    {
      "id": 3,
      "source": "ps L5.7",
      "type": "choice",
      "prompt": "You have reconstructed an obfuscated payload's plaintext. What next?",
      "options": {
        "a": "Name the technique and escalate — you do not execute it",
        "b": "Run it in place to confirm the C2 is live"
      },
      "answer_b64": "YQ=="
    },
    {
      "id": 4,
      "source": "ps L6.3",
      "type": "text",
      "prompt": "Which Event ID does the threat hunt read?",
      "answer_b64": "NDEwNA=="
    },
    {
      "id": 5,
      "source": "ps L5.1",
      "type": "text",
      "prompt": "A base64 blob in a 4104 event decodes with which text encoding?",
      "answer_b64": "dXRmLTE2bGU=",
      "accept_b64": [
        "dXRmLTE2bGU=",
        "dXRmMTZsZQ==",
        "dW5pY29kZQ==",
        "dXRmLTE2"
      ]
    }
  ]
}
```
