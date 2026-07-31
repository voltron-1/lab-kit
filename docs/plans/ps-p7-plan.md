# LAB-KIT — `ps` Track, Phase 7 — Directing & Auditing AI-Generated PowerShell — BUILD PLAN

**Status:** **APPROVED FOR BUILD** (v1.1, 2026-07-31 — every `[VERIFY-AT-BUILD]` item resolved
against real pwsh 7.6.4; see §7). Binding content spec:
`docs/curriculum/powershell-literacy-lab-curriculum-v1.md` (Phase 7, §6 lines 220–233).
Binding mechanical spec: `docs/kit-contracts.md`. Track conventions inherited unchanged
from `docs/plans/ps-p01-plan.md` (§2a/§2b/§2c) and ps-p2/3/4/5/6. Executes under
`TRACK: ps  PHASE: 7`.

> **How this plan was verified.** v1 was authored with **no pwsh available**, so every runtime
> claim was flagged rather than tested. **v1.1 (2026-07-31) ran them against real pwsh 7.6.4 on
> Linux** — see §7 for what each check actually returned, including two grep-pattern bugs that
> would have broken against this plan's own worked examples (§7) and the exact byte shape of a
> "PSSA-clean" file (genuinely empty, not header-only). Phase 7
> is the **capstone** — it formalizes the track thesis (*AI writes the code, you understand
> and audit it*). Two inherited facts govern grading: (1) **PSScriptAnalyzer is graded from
> learner-written file artifacts, never re-run live in `check.sh`** — under the `env -i`
> `HOME` redirect a live `Invoke-ScriptAnalyzer` sees nothing and false-fails (ps-p01 §2
> fact 2); PSSA install needs PSGallery egress with an offline `Save-Module` fallback
> (ps-p01 §3a) — **confirmed:** PSSA was not preinstalled on this machine, and
> `Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force` succeeded live against
> PSGallery (v1.25.0). (2) **Flawed AI scripts are audited statically — never executed**; the
> `iex`/hardcoded-cred samples are fictional/defanged. PSScriptAnalyzer itself is
> cross-platform (pwsh 7 Linux). Cross-track: L7.5 PSSA ↔ bash L7.5 ShellCheck (§7).
> Runtime facts were flagged `[VERIFY-AT-BUILD]` and are now RESOLVED in §7. **The build
> session must run the per-lab adversarial correctness pass ps-p01 used before self-test.**

---

## 0. Context — why this plan exists

Phase 7 (map §6): *your workflow, formalized. AI writes PS badly — no error handling, no
logging, weak validation, and it loves bare `iex`. Expert level means your specs force
auditable output.* Every prior phase feeds this: reading pipelines (P1), logic (P2), the
Windows layer (P3), attack recognition (P4), deobfuscation (P5), and tool navigation (P6)
are exactly what let a lead analyst **spec, review, and CI-gate** AI-generated PowerShell.
It ends on a **two-part capstone** (L7.6 direct + L7.7 gate): ship a hardened,
PSScriptAnalyzer-clean IR triage / log-collection script.

**7 labs (L7.1–L7.7).** Types (from the map): 4 AUDIT (L7.1, L7.3, L7.4, L7.7 gate), 2 DIRECT
(L7.2, L7.6 capstone), 1 GUIDED (L7.5). **This is the final phase — no forward-draft recall
after L7.7.**

### Two load-bearing facts this phase turns on (settled — build must honor)

1. **PSScriptAnalyzer is graded from a learner artifact, not a live `check.sh` run.** The
   learner runs `Invoke-ScriptAnalyzer` and writes the result to a file; `check.sh` greps that
   file (ps-p01 §2 fact 2 / §3a). Install needs PSGallery egress + a documented `Save-Module`
   offline fallback. PSSA runs cross-platform on pwsh 7.
2. **AI scripts are audited, never executed.** The recurring AI failure patterns — bare `iex`,
   no logging, hardcoded creds, weak/no parameter validation, no error handling — are read from
   **fictional, defanged** sample scripts; `check.sh` never runs them.

### Safety-by-design posture (carry-through)

Flawed AI samples (L7.1/L7.4) contain the anti-patterns as **static, fictional** text (bare
`iex`, plaintext creds, `$Env:` secrets) — audited, never executed; all IOCs defanged. The
hardened capstone artifact (L7.6/L7.7) is a **benign** IR log-collection script (no attack
content) graded by PSSA-cleanliness + structure. `check.sh` executes no flawed script and no
attack content.

---

## 1. Confirmed lab list (read from the map — ids/titles/types verbatim)

**Phase 7 — Directing & Auditing AI-Generated PowerShell (7).** Gate: **L7.7** (capstone gate).

| id | title | type | gate? | est_min |
|----|-------|------|-------|---------|
| L7.1 | Why AI PS is risky by default — recurring failures (iex, no logging, hardcoded creds) | AUDIT | no | 20 |
| L7.2 | The safe-PS spec — error handling, ScriptBlock logging on, no iex, `[CmdletBinding()]` | DIRECT | no | 20 |
| L7.3 | The AI-PS review checklist v1 | AUDIT | no | 20 |
| L7.4 | Review reps — 3 AI-generated scripts, find every flaw | AUDIT | no | 25 |
| L7.5 | CI guardrails — PSScriptAnalyzer as a merge gate (PS ShellCheck) | GUIDED | no | 20 |
| L7.6 | **Capstone:** direct + audit a PS IR triage / log-collection script | DIRECT | no | 30 |
| L7.7 | **Capstone gate:** ship a hardened, PSScriptAnalyzer-clean script w/ logging + error handling | AUDIT | **yes** | 30 |

**Gate placement.** L7.7 (`gate:true`) is the **capstone gate**; L7.6 is the capstone build.
L7.7 uses the worksheet + `answers.md` + 3-question gate quiz pattern **plus** artifact asserts
on the shipped hardened script (PSSA-clean, logging, error handling, no `iex`).

**Recall placement:**
- **L7.1** — Phase-7 opener → `recall.json`, 5 Qs from **Phase 5 + Phase 6** (both planned, not
  built → sourced from the curriculum's Phase 5/6 lab list, `[VERIFY-AT-BUILD]`, reconciled with
  the L7.1 recall **forward-drafted under ps-p6 §4 (L6.5)**).
- **No forward-draft** after L7.7 — Phase 7 is the final phase of the track.

---

## 2. Track-wide build conventions (inherited — restated, plus the PSSA-artifact rule)

**File set per lab** (kit-contracts): standard; dir grammar `tracks/ps/phases/p7/L7.<n>-<slug>/`.

**§2a grader architecture (inherited).** AUDIT/DIRECT labs grade **learner artifacts** (a
finding list, a spec, a checklist, a hardened script, a PSSA-output file). **PSScriptAnalyzer is
never re-run inside `check.sh`** — the learner runs it and writes the output; `check.sh` greps
that file (ps-p01 §2 fact 2). No flawed AI script is executed.

**§2b grader hygiene (inherited).** Real `assert_output_contains` signature; single-quote
`$`-literals (e.g. grep for `$Env:` or `Invoke-Expression`); `assert_file_exists` before every
`assert_file_not_contains` (used to prove `iex` was removed); `.NET`/dotted/decorator literals
via `assert_file_contains_fixed` (`[CmdletBinding()]`); free text via case/word-tolerant ERE.

**➕ §2c — Phase-7 rules (build MUST enforce, step-5 self-check):**
- No `check.sh` executes a flawed AI sample or runs `Invoke-ScriptAnalyzer` live; PSSA is graded
  from the learner's shipped output file.
- Flawed samples are fictional/defanged; the capstone artifact is benign (IR log collection).

**Windows-variant:** minimal. **PSScriptAnalyzer runs cross-platform** (pwsh 7 Linux). The IR
triage/log-collection capstone may *reference* Windows telemetry, but is graded on structure +
PSSA-cleanliness (cross-platform). Any Windows-only collection line is noted, not a grading
dependency. No lab is hard-flagged `[WINDOWS-VARIANT]`.

---

## 3. Phase-7-specific decisions

### 3a. PSScriptAnalyzer is graded from a learner file, not a live run (inherited, load-bearing)

L7.5 and L7.7 depend on PSSA. Per ps-p01 §2/§3a: the learner runs
`Invoke-ScriptAnalyzer -Path <script> | Select-Object RuleName,Severity,Line > pssa.txt` and
`check.sh` **greps `pssa.txt`** — it never runs PSSA (HOME redirect would blind a live run).
Install requires PSGallery egress; `lab.md` states the `Save-Module` offline fallback (ps-p01
§3a). "PSSA-clean" for the capstone = an **empty/no-warning** `pssa.txt` the learner produced.

### 3b. The AI-failure-pattern set is the spine of L7.1–L7.4

The recurring anti-patterns are a fixed set the phase builds around: **bare `iex`**, **no
error handling**, **no logging**, **hardcoded/plaintext creds** (L4.7), **weak/no parameter
validation** (`[Parameter()]`/`[ValidateSet]` from L2.4), and **unconstrained input**. L7.1
names them, L7.2 specs them away, L7.3 turns them into a checklist, L7.4 drills finding them.

### 3c. DIRECT labs grade the spec/checklist artifact, not free prose

L7.2 (safe-PS spec) and L7.6 (capstone direction) grade a **structured artifact** — the spec
must contain the required clauses (error handling, logging on, no `iex`, `[CmdletBinding()]`,
validated params, no hardcoded creds). `check.sh` greps for each required clause; the learner's
"spec" is a checklist/prompt file, not an essay.

### 3d. The L7.7 capstone gate: hardened script + PSSA-clean + worksheet quiz

L7.7 grades the **shipped hardened script** (`hardened.ps1`) on the safe-PS properties **and** a
learner-produced empty `pssa.txt`, plus a 3-question gate quiz (3/3). It is the track's final
checkpoint: the learner has *directed* AI to produce, and *audited* to hardened, a real SOC
artifact.

---

## 4. Phase 7 — lab-by-lab build spec

> Phase-7 spine: *spec it safe, review it like a lead, gate it in CI — then ship a hardened,
> PSSA-clean artifact.* AUDIT/DIRECT labs grade learner artifacts; nothing flawed is executed.

### L7.1 — Why AI PS is risky by default · AUDIT · **Phase-7 opener** · est 20m

**Teaching artifact (AUDIT — static, fictional).** Audit a representative AI-generated script
for the recurring failure patterns.

```powershell
# SHIPPED flawed AI script (read; never executed) — files/ai-sample.ps1:
function Get-Stuff($server) {                       # no [CmdletBinding()], untyped/unvalidated param
    $data = iex "Invoke-RestMethod http://$server/api"   # bare iex on interpolated input — injection + eval
    $pw = 'P@ssw0rd123'                              # hardcoded plaintext credential (L4.7)
    $data | Out-File "$env:TEMP\out.txt"            # no error handling, no logging
}
```

AUDIT focus: name every flaw — **bare `iex` on interpolated input** (eval + injection), **no
`[CmdletBinding()]`/param validation**, **hardcoded plaintext cred**, **no error handling**, **no
logging**. These are AI's default failure modes; recognizing them is the review skill.

**Environment note.** Static audit of a fictional script; nothing runs. Defanged host.

**check.sh grades** (static AUDIT):
- ship `files/ai-sample.ps1`. learner writes `findings.md` naming ≥4 flaws.
  `assert_file_exists findings.md`, `assert_file_contains findings.md 'iex|Invoke-Expression'`,
  `assert_file_contains findings.md '[Cc]red|[Pp]assword|plaintext'`,
  `assert_file_contains findings.md '[Ll]og'`, `assert_file_contains findings.md
  '[Ee]rror|try|catch|validat'`.

**Quiz (3):**
1. *(text)* Name two default AI-PS failure patterns. → **bare `iex`, no logging, hardcoded
   creds, no error handling, no validation** *(any two)*.
2. *(choice)* Why is `iex "…$server…"` doubly dangerous? → **it both evaluates arbitrary code
   and is injectable via the interpolated input**. *(distractor: "it's just slow")*
3. *(choice)* AI-generated PS should be treated as? → **untrusted input to review, not
   trusted output to run**. *(distractor: "safe because AI wrote it")*

**Recap (3 lines):**
```
AI PS fails by default: bare iex, no error handling, no logging, hardcoded creds, no param validation
iex on interpolated input is eval + injection — the highest-signal flaw to catch first
treat AI output as untrusted input to review like a lead analyst — not trusted code to run
```

**recall.json (L7.1 — 5 Qs from Phase 5 + 6) — `[VERIFY-AT-BUILD]` (reconcile with ps-p6 L6.5
forward-draft):**
1. `source: ps L6.4` — What does a Sigma rule's `detection.selection` specify? → **the match criteria against a logsource**.
2. `source: ps L6.1` — What does PowerView's `Get-NetUser` collect? → **domain user objects (AD recon)**.
3. `source: ps L5.7` — After reconstructing an obfuscated payload, what do you do? → **name the technique + escalate; never run it**.
4. `source: ps L6.3` — Which Event ID does the threat-hunt read? → **4104 (ScriptBlock)**.
5. `source: ps L5.1` — base64 in a 4104 blob decodes with which encoding? → **UTF-16LE**.

---

### L7.2 — The safe-PS spec · DIRECT · est 20m

**Teaching artifact (DIRECT).** Write a **spec** (a prompt/checklist you hand to AI) that forces
auditable output. The learner produces `safe-spec.md` with the required clauses.

```text
# safe-PS spec (the learner writes this — required clauses):
- [CmdletBinding()] + typed [Parameter(Mandatory)] with [ValidateSet]/[ValidateNotNullOrEmpty]
- NO Invoke-Expression / iex; call cmdlets directly with bound parameters
- try/catch with -ErrorAction Stop on risky calls; meaningful $_ handling
- logging ON: structured Write-Verbose / a transcript / an audit line per action
- NO hardcoded creds: use a vault / SecureString from a store, never plaintext or $Env: echo
- least privilege; validate/sanitize all external input
```

DIRECT moment: the spec **inverts** each L7.1 failure into a requirement. A good spec makes the
AI's output auditable **by construction** — the reviewer checks output against the spec.

**Environment note.** The learner authors a spec artifact; nothing runs.

**check.sh grades** (structured spec artifact):
- learner writes `safe-spec.md`. `assert_file_exists safe-spec.md`,
  `assert_file_contains_fixed safe-spec.md '[CmdletBinding()]'`,
  `assert_file_contains safe-spec.md '[Nn]o (iex|Invoke-Expression)|without iex'`,
  `assert_file_contains safe-spec.md 'try|catch|ErrorAction'`,
  `assert_file_contains safe-spec.md '[Ll]og|[Tt]ranscript|Verbose'`,
  `assert_file_contains safe-spec.md '[Vv]ault|SecureString|no.*plaintext'`.

**Quiz (3):**
1. *(choice)* A safe-PS spec should require which of these instead of `iex`? → **direct cmdlet
   calls with bound parameters**. *(distractor: "iex with a comment")*
2. *(text)* Name a validation attribute a spec should require on parameters. → **`[ValidateSet]`
   / `[ValidateNotNullOrEmpty]` / `[Parameter(Mandatory)]`** *(any)*.
3. *(choice)* Why spec logging on? → **so every action is auditable (4104/transcript) — the
   output can be reviewed and investigated**. *(distractor: "to make it run faster")*

**Recap (3 lines):**
```
the safe-PS spec inverts every AI failure into a requirement: [CmdletBinding()], no iex, try/catch, logging, no creds
a good spec makes AI output auditable BY CONSTRUCTION — you review output against the spec
you direct the AI; the spec is the contract that forces safety
```

**recall.json:** none.

---

### L7.3 — The AI-PS review checklist v1 · AUDIT · est 20m

**Teaching artifact (AUDIT).** Turn the spec into a **repeatable review checklist** — the
lead-analyst artifact used on every AI script.

```text
# ai-ps-review-checklist v1 (the learner writes this):
1. No Invoke-Expression / iex anywhere?                         (grep)
2. [CmdletBinding()] + validated, typed parameters?
3. try/catch with -ErrorAction Stop on every risky call?
4. Logging on (Write-Verbose / transcript / audit line)?
5. No hardcoded creds / plaintext secrets / echoed $Env: secrets?
6. Least privilege; no unnecessary admin / broad scope?
7. External input validated/sanitized (no injection)?
8. PSScriptAnalyzer clean (no warnings)?
```

AUDIT moment: a checklist makes review **consistent and fast** — each item is a concrete,
greppable check. Item 8 (PSSA) is the automated backstop for the human checklist.

**Environment note.** The learner authors the checklist; nothing runs.

**check.sh grades** (checklist artifact):
- learner writes `checklist.md` with ≥6 items covering the failure set.
  `assert_file_exists checklist.md`, `assert_file_contains checklist.md 'iex|Invoke-Expression'`,
  `assert_file_contains checklist.md 'try|catch|ErrorAction'`,
  `assert_file_contains checklist.md '[Ll]og'`,
  `assert_file_contains checklist.md 'PSScriptAnalyzer|PSSA'`,
  `assert_file_contains checklist.md '[Cc]red|[Ss]ecret'`.

**Quiz (3):**
1. *(choice)* Why turn the spec into a checklist? → **consistent, fast, repeatable review — each
   item a concrete check**. *(distractor: "checklists aren't needed if you have a spec")*
2. *(text)* Which checklist item is the automated backstop to the human review? → **PSScriptAnalyzer
   clean (no warnings)**.
3. *(choice)* The `iex` check is best done how? → **a grep for `iex`/`Invoke-Expression` (fast,
   unambiguous)**. *(distractor: "by running the script")*

**Recap (3 lines):**
```
the review checklist v1 makes AI-PS review consistent and fast — each item a concrete, greppable check
it covers: no iex, validated params, try/catch, logging, no creds, least privilege, input validation, PSSA-clean
PSScriptAnalyzer is the automated backstop to the human checklist
```

**recall.json:** none.

---

### L7.4 — Review reps — 3 AI-generated scripts · AUDIT · est 25m

**Teaching artifact (AUDIT — three shipped flawed scripts).** Apply the L7.3 checklist to three
AI scripts and find **every** flaw in each.

```text
# files/ai-1.ps1 : bare iex download cradle + no logging
# files/ai-2.ps1 : hardcoded PSCredential (plaintext) + no error handling
# files/ai-3.ps1 : unvalidated param used in a path/command (injection) + no [CmdletBinding()]
# (all fictional, defanged; read, never run)
```

AUDIT moment: repetition builds the reflex — each script has a distinct primary flaw plus
secondary ones; the checklist catches them consistently. This is the review-reps drill.

**Environment note.** Three static, fictional scripts; nothing runs.

**check.sh grades** (static AUDIT against a known flaw set):
- ship `files/ai-1.ps1`, `ai-2.ps1`, `ai-3.ps1`. learner writes `review.md` with the primary
  flaw per script. `assert_file_exists review.md`,
  `assert_file_contains review.md 'iex|Invoke-Expression|cradle'` (ai-1),
  `assert_file_contains review.md '[Cc]red|plaintext'` (ai-2),
  `assert_file_contains review.md '[Ii]njection|[Vv]alidat|unvalidated'` (ai-3),
  plus a set-e-safe ≥N-of-M for secondary flaws (`[Ll]og`, `try|catch`, `[CmdletBinding()]`).

**Quiz (3):**
1. *(choice)* ai-1's primary flaw (`iex (DownloadString ...)`)? → **a bare-`iex` download
   cradle**. *(distractor: "a missing semicolon")*
2. *(text)* ai-2 hardcodes a `PSCredential` from plaintext — the fix? → **use a vault /
   SecureString from a secret store; never plaintext in source**.
3. *(choice)* ai-3 uses an unvalidated param in a path — the risk? → **injection; fix with
   `[ValidateSet]`/`[ValidatePattern]` and bound parameters, not string building**. *(distractor:
   "none — params are always safe")*

**Recap (3 lines):**
```
review reps build the reflex: each AI script has a primary flaw (cradle / creds / injection) plus secondaries
the L7.3 checklist catches them consistently — grep for iex, scan params, check logging/creds
finding every flaw fast IS the lead-analyst review skill
```

**recall.json:** none.

---

### L7.5 — CI guardrails: PSScriptAnalyzer as a merge gate · GUIDED · est 20m

**Teaching artifact (GUIDED).** Wire PSScriptAnalyzer (the PS ShellCheck; installed in L0.1) as a
**merge gate** — the automated backstop. The learner runs PSSA on a sample, writes the output,
and drafts a CI step. Cross-track: **bash L7.5 ShellCheck** (curriculum §7).

```powershell
# the learner runs this and captures the output to a FILE (check.sh grades the file, per §3a):
Invoke-ScriptAnalyzer -Path ./candidate.ps1 |
  Select-Object RuleName, Severity, Line, Message > pssa.txt
# a CI step (the learner drafts ci-step.yml): fail the build if Invoke-ScriptAnalyzer returns any Error/Warning
```

GUIDED moment: PSSA is a static analyzer (linter) for PS — it flags aliases, uninitialized vars,
`Invoke-Expression`, plaintext-cred patterns, and more. As a merge gate it blocks non-conforming
PS from landing — the same posture as ShellCheck for bash. Runs cross-platform on pwsh 7.

**Environment note.** PSSA install needs PSGallery egress (offline `Save-Module` fallback, ps-p01
§3a). **`check.sh` grades the learner's `pssa.txt` + `ci-step.yml` artifacts — it never runs PSSA
live** (ps-p01 §2 fact 2). `[VERIFY-AT-BUILD]`: PSSA install/network; exact rule names are
version-dependent → don't grep specific rule names.

**check.sh grades** (learner artifacts; PSSA not re-run):
- `assert_file_exists pssa.txt` (the learner actually ran PSSA on the sample).
- learner writes `ci-step.yml` (a CI gate that fails on PSSA Error/Warning) + `notes.md`.
  `assert_file_exists ci-step.yml`, `assert_file_contains ci-step.yml
  'Invoke-ScriptAnalyzer|PSScriptAnalyzer'`, `assert_file_contains ci-step.yml
  '[Ff]ail|exit|[Ee]rror|[Ww]arning'`,
  `assert_file_contains notes.md '[Ss]hell[Cc]heck'` (names the cross-track equivalent).

**Quiz (3):**
1. *(choice)* PSScriptAnalyzer is the PS equivalent of which Bash tool? → **ShellCheck**.
   *(distractor: "bash -n")*
2. *(choice)* As a merge gate, PSSA should? → **fail the build if it returns any Error/Warning —
   blocking non-conforming PS**. *(distractor: "log warnings but always pass")*
3. *(text)* Name one thing PSSA flags. → **aliases / uninitialized vars / `Invoke-Expression` /
   plaintext-cred patterns** *(any)*.

**Recap (3 lines):**
```
PSScriptAnalyzer is the PS ShellCheck — a static analyzer you wire as a merge gate (bash L7.5 posture)
as a CI gate it fails the build on any Error/Warning, blocking non-conforming PS from landing
run PSSA, capture the output to a file, gate on it — the automated backstop to the human checklist
```

**recall.json:** none.

---

### L7.6 — Capstone: direct + audit a PS IR triage / log-collection script · DIRECT · est 30m

**Teaching artifact (DIRECT — capstone build).** Direct AI to produce a **PS IR triage /
log-collection script** using the L7.2 spec, then audit the output against the L7.3 checklist and
harden it. The learner produces `spec.md` (the direction) and `hardened.ps1` (the audited result).

```powershell
# hardened.ps1 — the learner's audited artifact (benign IR log collection), shape:
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$OutputPath
)
Start-Transcript -Path (Join-Path $OutputPath 'triage.log')      # logging ON
try {
    Get-Process | Select-Object Name,Id,Path | Export-Csv (Join-Path $OutputPath 'proc.csv') -NoTypeInformation -ErrorAction Stop
    # (Windows overlay: Get-WinEvent/Get-CimInstance sections, noted — cross-platform grade is on structure)
}
catch { Write-Error "collection failed: $($_.Exception.Message)" }   # error handling
finally { Stop-Transcript }
# NO iex; validated param; logging; try/catch/finally
```

DIRECT+AUDIT moment: this is the whole track in one artifact — a real SOC deliverable (map §6
"why this capstone"), *directed* by a spec and *audited* to safety. The Windows-only collection
lines are noted as overlays; the graded properties (structure, no `iex`, logging, error handling)
are cross-platform.

**Environment note.** The learner authors `spec.md` + `hardened.ps1`; `check.sh` grades the
artifacts (does not execute the collection). Benign script.

**check.sh grades** (spec + hardened-script structure):
- `assert_file_exists spec.md` (the direction) + `assert_file_exists hardened.ps1`.
- `assert_file_contains_fixed hardened.ps1 '[CmdletBinding()]'`,
  `assert_file_contains hardened.ps1 'try'` **and** `'catch'`,
  `assert_file_contains hardened.ps1 '[Ll]og|Transcript|Verbose'`,
  `assert_file_exists hardened.ps1` then `assert_file_not_contains hardened.ps1
  'Invoke-Expression|iex'` (proves no `iex`).

**Quiz (3):**
1. *(choice)* The capstone artifact is directed then? → **audited against the review checklist and
   hardened**. *(distractor: "shipped as the AI wrote it")*
2. *(text)* Name two safety properties the hardened script must have. → **`[CmdletBinding()]`,
   validated params, try/catch, logging, no `iex`** *(any two)*.
3. *(choice)* Why is an IR triage/log-collection script a fitting capstone? → **it's a real SOC
   artifact a Tier-1 analyst runs — building it safely closes the loop across all four tracks**.
   *(distractor: "it's the shortest to write")*

**Recap (3 lines):**
```
the capstone: DIRECT a PS IR triage/log-collection script from the safe-PS spec, then AUDIT + harden it
the hardened artifact has [CmdletBinding()], validated params, try/catch/finally, logging, and NO iex
a real SOC deliverable, produced by directing AI and auditing the output — the whole track in one script
```

**recall.json:** none.

---

### L7.7 — Capstone gate: ship a hardened, PSScriptAnalyzer-clean script · AUDIT · **GATE** · est 30m

**Teaching artifact (AUDIT — the capstone gate).** Ship the L7.6 `hardened.ps1` **verified clean**:
the learner runs PSScriptAnalyzer, captures an **empty/no-warning** result, and the script carries
logging + error handling + no `iex`. Worksheet → `answers.md`; 3-question gate quiz (3/3); plus
artifact asserts.

```powershell
# the learner produces pssa-clean.txt (per §3a — check.sh greps the file, never runs PSSA):
Invoke-ScriptAnalyzer -Path ./hardened.ps1 | Select-Object RuleName,Severity > pssa-clean.txt
# a clean run → the file has NO Warning/Error rows  [VERIFY-AT-BUILD what "clean" prints]
```

**check.sh grades** (hardened artifact + learner PSSA-clean file + worksheet quiz):
- `assert_file_exists hardened.ps1`, `assert_file_contains_fixed hardened.ps1 '[CmdletBinding()]'`,
  `assert_file_contains hardened.ps1 'try'` and `'catch'`,
  `assert_file_contains hardened.ps1 '[Ll]og|Transcript'`,
  `assert_file_exists hardened.ps1` then `assert_file_not_contains hardened.ps1
  'Invoke-Expression|iex'`.
- `assert_file_exists pssa-clean.txt` then `assert_file_not_contains pssa-clean.txt
  'Warning|Error'` (learner-produced clean PSSA output; `[VERIFY-AT-BUILD]` exact "clean" format —
  if PSSA prints nothing on clean, assert the file is empty or contains only a header).
- `assert_file_exists answers.md` (worksheet — self-audit against the checklist).

**Quiz (3) — the gate:**
1. *(choice)* "PSScriptAnalyzer-clean" means? → **PSSA returns no Error/Warning findings on the
   script**. *(distractor: "the script has comments")*
2. *(choice)* The shipped script must have which safety properties? → **`[CmdletBinding()]`,
   validated params, try/catch, logging, and no `iex`**. *(distractor: "just no syntax errors")*
3. *(text)* You directed AI and audited the output — what is the track's core lesson? → **AI
   writes the code; you understand, audit, and harden it (never trust it unread)**.

**Recap (3 lines):**
```
the capstone gate: a hardened, PSScriptAnalyzer-clean script with logging, error handling, and no iex
you ran PSSA and captured a clean result; the script passes the L7.3 checklist end to end
the track's thesis, proven: AI writes the code — you read, audit, and harden it into something safe to run
```

**recall.json:** none on L7.7 (gate). **No forward-draft** — L7.7 is the final lab of the track.

---

## 5. Build order, self-test, phase-close (Phase Builder protocol)

1. Scaffold `tracks/ps/phases/p7` (+ `phases.p7` in `track.json` if enumerated). Assumes Phases
   0–6 built first.
2. Build **lab by lab in id order** (L7.1 → L7.7). Commit each after self-test.
3. **Self-test (no-fiction rule):** run PSSA-related steps in real pwsh 7 (PSSA is cross-platform)
   and paste the REAL `Invoke-ScriptAnalyzer` output written to file; confirm a clean `hardened.ps1`
   yields a clean `pssa-clean.txt`. Audit labs self-test that `check.sh` grades the shipped flawed
   samples (fail + pass). Resolve `[VERIFY-AT-BUILD]` (§7).
4. **shellcheck-zero + lint:** each `check.sh` passes `tools/shellcheck-all.sh` +
   `tools/lint-labs.sh`. **`check.sh` never runs PSSA or a flawed sample** — it greps learner
   artifacts. Ship every sample (`ai-sample.ps1`, `ai-1..3.ps1`) and the capstone scaffolding.
5. **Safety self-check (build gate):** grep the phase — **no** `check.sh` executes a flawed AI
   sample or runs `Invoke-ScriptAnalyzer` live; PSSA graded from the learner file; samples
   fictional/defanged; the capstone artifact benign.
6. **Gate:** L7.7 `gate:true`; `quiz_run` requires 3/3.
7. **Recall:** L7.1's `recall.json` ships now (`[VERIFY-AT-BUILD]` vs built Phase 5/6); **no
   forward-draft after L7.7** (final phase).
8. **Close out:** update `planned_execution.md` (`ps p7` → done + evidence); tag `ps-p7`. **This
   completes the ps track (Phases 0–7, 54 labs).**

**Phase Acceptance Checklist:** 7 labs, types match the map (4 AUDIT + 2 DIRECT + 1 GUIDED, gate
L7.7); the safety self-check (step 5) passes; **PSSA graded from learner artifacts, never re-run
in `check.sh`**; the capstone ships a hardened, PSSA-clean script (logging + error handling + no
`iex`); shellcheck + lint clean; gate 3/3; L7.1 recall ships; `planned_execution.md` updated;
tagged `ps-p7`; track complete.

---

## 6. Verification summary (authoring pass — corrections pre-folded from ps-p01..p6)

No pwsh executed during the v1 authoring session this section describes; v1.1's real pwsh run
against every `[VERIFY-AT-BUILD]` item is §7, not this section. Carried-forward decisions:
- **PSSA-from-artifact (§3a, ps-p01 §2/§3a):** `check.sh` greps a learner-produced
  `Invoke-ScriptAnalyzer` output file; it never runs PSSA (HOME redirect blinds a live run);
  install has a `Save-Module` offline fallback.
- **Audit-never-execute (§2c, §5 step 5):** flawed AI samples are static/fictional; the capstone
  artifact is benign; nothing flawed runs.
- **Failure-pattern spine (§3b):** L7.1–L7.4 build around the fixed AI-failure set; L7.2/L7.3
  invert it into a spec/checklist; L7.6/L7.7 produce the hardened artifact.
- **Cross-track (§7):** L7.5 PSSA ↔ bash L7.5 ShellCheck.
- **Hygiene (§2b):** `[CmdletBinding()]` via `assert_file_contains_fixed`; `assert_file_exists`
  before `assert_file_not_contains 'iex'`; free text via case/word-tolerant ERE.
- **Recall rule honored:** L7.1 recall from the curriculum's Phase 5/6 lab list (`[VERIFY-AT-BUILD]`),
  reconciled with ps-p6's L6.5 forward-draft; **no forward-draft after L7.7**.

**The build session must still run the per-lab adversarial correctness pass ps-p01 used** and
resolve §7 before shipping.

---

## 7. `[VERIFY-AT-BUILD]` items — RESOLVED (verified against real pwsh 7.6.4 on Linux, 2026-07-31)

| lab | item | result |
|---|---|---|
| L7.1 | `ai-sample.ps1` flaws are unambiguous + fictional/defanged; audit-only grade (never executed) | **Confirmed.** A representative sample (bare `iex "Invoke-RestMethod http://$server/api"` on an untyped/unvalidated param, plus a hardcoded plaintext var) parses and runs cleanly through a real `Invoke-ScriptAnalyzer` pass with no syntax errors — valid, PSSA-analyzable PowerShell, suitable as static AUDIT content. It flags real, version-current rule names (see L7.5 row) — nothing here depends on PSSA output for grading, but the sample is genuinely representative of what PSSA would catch, which is the point of the lesson. |
| L7.2 | `safe-spec.md` required clauses grep correctly (`[CmdletBinding()]`, no-iex, try/catch, logging, no-cred) | **Bug found and fixed.** The sketched pattern `'[Nn]o (iex\|Invoke-Expression)\|without iex'` does **not** match this plan's own worked example text ("NO Invoke-Expression / iex; call cmdlets directly…") — `[Nn]o` requires a lowercase second letter, and the example uses all-caps "NO". Verified fix: `'[Nn][Oo] (iex\|Invoke-Expression)\|without iex'` (tested against the exact worked example — matches). The other four clause patterns (`try\|catch\|ErrorAction`, `[Ll]og\|[Tt]ranscript\|Verbose`, `[Vv]ault\|SecureString\|no.*plaintext`, `[CmdletBinding()]` fixed) all matched the worked example as sketched. |
| L7.3 | `checklist.md` covers ≥6 of the failure set incl. PSSA-clean item | **Confirmed.** The sketched 8-item checklist and its grep set (`iex\|Invoke-Expression`, `try\|catch\|ErrorAction`, `[Ll]og`, `PSScriptAnalyzer\|PSSA`, `[Cc]red\|[Ss]ecret`) all match the worked checklist text as written — no case-sensitivity gap here (both alternatives in each pair are already case-classed). |
| L7.4 | `ai-1/2/3.ps1` each carry a distinct primary flaw (cradle / creds / injection); defanged | **Confirmed, with a minor consistency nit.** `'[Cc]red\|plaintext'` (ai-2) leaves "plaintext" bare/lowercase-only while its sibling is case-classed; it happens not to break because "credential" already satisfies `[Cc]red` in every plausible phrasing, but for consistency with the rest of the phase's case-tolerant patterns, build should use `[Pp]laintext`. Same nit applies to L7.1's `'[Cc]red\|[Pp]assword\|plaintext'`. |
| L7.5 | PSSA install/PSGallery egress + `Save-Module` fallback; `check.sh` greps `pssa.txt`/`ci-step.yml`, never runs PSSA; don't grep version-specific rule names | **Confirmed, install path tested live.** PSSA was not preinstalled; `Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force` succeeded against live PSGallery egress on this machine (v1.25.0, user module path). A representative flawed sample surfaced real, current rule names — `PSAvoidUsingInvokeExpression`, `PSUseDeclaredVarsMoreThanAssignments`, `PSAvoidUsingCmdletAliases`, all `Severity: Warning` — confirming these **are** version-dependent identifiers and the plan's own caution against grepping them by name (rather than the generic `Warning\|Error`) is correct. The offline `Save-Module` fallback (ps-p01 §3a) was not independently re-tested here (no offline environment available) — inherited as-is. |
| L7.6 | `hardened.ps1` structure greps correctly; `assert_file_not_contains 'iex'` after `assert_file_exists`; Windows collection lines are noted overlays, not graded | **Security-critical bug found and fixed, plus two lesser findings.** The gate itself — `assert_file_not_contains hardened.ps1 'Invoke-Expression\|iex'`, the one check the whole capstone exists to enforce — is case-sensitive (`grep -Eq`, `harness/checklib.sh:184`) and **does not catch `IEX $payload`**, the single most common real-world capitalization of the alias (verified: `printf 'IEX $payload' \| grep -Eq -- 'Invoke-Expression\|iex'` → no match). Fix: `'[Ii]nvoke-[Ee]xpression\|[Ii][Ee][Xx]'`. Lesser: `'[Ll]og\|Transcript\|Verbose'` does **not** match a `hardened.ps1` that logs via valid, execution-legal lowercase `start-transcript`/`stop-transcript` — same case-sensitivity defect class already fixed at L4.6/L4.7/L5.4/L4.8. Fix: `'[Ll]og\|[Tt]ranscript\|[Vv]erbose'`; also tighten `[Ll]og` alone, which is a bare substring match a comment like `# TODO: add logging` would satisfy without adding any — prefer `Start-Transcript\|Write-Verbose\|Write-Information` (or route both through `assert_file_contains_i`). Separately, `assert_file_contains_fixed '[CmdletBinding()]'` is a case-sensitive literal match (`grep -F`, no case-insensitive sibling in `harness/checklib.sh`) and will reject a learner's valid `[cmdletbinding()]` — build must decide whether to require canonical PascalCase (defensible) or switch to a case-insensitive escaped-ERE check via `assert_file_contains_i` (consistent with the rest of the track). The `assert_file_exists` → `assert_file_not_contains 'iex'` ordering is confirmed load-bearing, not stylistic: `assert_file_not_contains` on a *missing* file vacuously PASSes (`harness/checklib.sh:177-189`), so without the exists-check first, an entirely absent `hardened.ps1` would incorrectly satisfy "no iex". |
| L7.7 | exact "clean" PSSA output format (empty vs header-only) so `assert_file_not_contains 'Warning\|Error'` (or empty-file check) is correct; capstone gate quiz 3/3 | **Resolved, load-bearing.** `Invoke-ScriptAnalyzer -Path clean.ps1 \| Select-Object RuleName,Severity,Line,Message > pssa-clean.txt` on a genuinely clean script produces a **literal 0-byte file** — not header-only, not blank-line-only. `assert_file_not_contains 'Warning\|Error'` is correct as sketched; build should also consider tightening to an explicit empty-file check (`[[ ! -s pssa-clean.txt ]]`), which is a stronger and unambiguous bar for "clean" than absence-of-keyword. This gate greps the same `hardened.ps1` as L7.6, so the **same security-critical `IEX`-bypass, the `[Ll]og` substring weakness, and the `[CmdletBinding()]` case-sensitivity finding from the L7.6 row all apply here too** — this is the track's final checkpoint, so the case-insensitive `iex` fix is non-negotiable here specifically. |

### Build-time corrections this pass also fixes

`lib/quiz.sh` grades text answers by **exact normalized match plus an accept list** — no set
logic, no partial credit. Two quizzes as sketched ask for **"any two"** of a fixed set, which is
combinatorial and therefore ungradeable by that mechanism — the same correction already applied
at L4.9, L5.5, L5.6, L5.7, and (for a different pair of labs) ps-p6's own plan-verify pass:

- **L7.1 Q1** — "Name two default AI-PS failure patterns *(any two)*" → narrow to naming one
  pattern with an accept-list, or convert to choice.
- **L7.6 Q2** — "Name two safety properties the hardened script must have *(any two)*" → same fix.

(L7.2 Q2 and L7.3 Q2's bare "*(any)*" singular-answer prompts are fine as sketched — a flat
accept-list covers a single free-text answer; the "any two" shape is what breaks.)

**L7.1's `recall.json` is already drafted and build-ready** — `docs/plans/ps-p6-plan.md` §8,
written during the L6.5 build per that plan's own step-7 handoff. Same 5 sources this plan's §189
sketch names (L6.4, L6.1, L5.7, L6.3, L5.1), already correctly choice-typed for Q1–Q3 (the free
text §189 sketched is ungradeable for open "explain what X specifies" prompts, same reason as
above), and it carries an explicit warning against reintroducing an inverted-stem question shape
that had to be corrected post-hoc in the L6.1 recall. **Ship §8's JSON verbatim** rather than
re-deriving from §189.

---

*Plan v1 authored from curriculum §6 + the settled ps-p01..p6 template; **v1.1 (2026-07-31)
resolves every `[VERIFY-AT-BUILD]` item above against real pwsh 7.6.4 and marks this plan
APPROVED FOR BUILD.** Build proceeds lab by lab under this plan. This completes planning for the
ps track (Phases 0–7).*
