# LAB-KIT — `ps` Track, Phase 2 — Control Flow, Errors & Modules — BUILD PLAN

**Status:** PLAN ONLY (uncommitted, for review). Binding content spec:
`docs/curriculum/powershell-literacy-lab-curriculum-v1.md` (Phase 2, §6 lines 134–148).
Binding mechanical spec: `docs/kit-contracts.md`. Track conventions inherited
unchanged from `docs/plans/ps-p01-plan.md` (§2a grader architecture, §2b grader
hygiene, §2c attack-content ceiling). A later BUILD session executes this
mechanically under the Phase Builder protocol (`PROMPTS.md` Prompt 2,
`TRACK: ps  PHASE: 2`). This session was **plan-only**: nothing built, no pwsh run,
nothing committed.

> **How this plan was verified.** pwsh is **not installed** in the planning
> environment (same constraint ps-p01 flagged), so no output was executed. This plan
> was authored against (a) the curriculum map's Phase 2 lab list verbatim and (b) the
> settled ps-p01 grader architecture, PowerShell-fact corrections, and hygiene rules —
> so the known traps ps-p01 already paid for (SC2016 `$`-in-`-Command`, double-quoted
> `grep -F ""` false-pass, `.NET`-type-literal ERE wildcarding, `assert_output_contains`
> 4-arg signature, accelerator-vs-FullName type names) are **pre-avoided here, not
> rediscovered.** Every runtime-dependent PowerShell fact (exact exception strings,
> whether a probe's output is byte-stable) is flagged `[VERIFY-AT-BUILD]` in §7. **The
> build session must run the same per-lab adversarial correctness pass ps-p01 used
> (one PowerShell-7 + bash/harness reviewer per lab) before self-test.**

---

## 0. Context — why this plan exists

Phase 2 is the third `ps` build (Phase 0+1 shipped together first). Its job (map §6):
**read PS logic — the constructs that appear in every script, admin or attacker —
fluently.** Phase 1 taught the object pipeline; Phase 2 teaches the *control structures
wrapped around* that pipeline: conditionals and comparison operators, the (unusually
powerful) `switch`, the four loop forms, advanced functions with `[CmdletBinding()]`,
error handling, and modules/manifests. It closes on a **cold-read gate** (L2.7): a
60-line admin script the learner must read and explain with no prior exposure — the
first time the track asks the learner to integrate every construct at once.

**7 labs (L2.1–L2.7).** The phase is deliberately **DECODE-heavy (6 DECODE + 1
PREDICT)** — Phase 2 is about *reading* logic, not producing deterministic output.
The single PREDICT lab is L2.3 (loops), where trip-count is genuinely predictable.

### Three load-bearing facts this phase turns on (settled — build must honor)

1. **PS `switch` has no implicit break.** A single value can fire *multiple* case
   blocks (it tests every clause). This is the phase's biggest DECODE trap and is
   graded by a probe that prints two hits from one value (L2.2).
2. **Most cmdlet errors are non-terminating** and slip past `try/catch`; `-ErrorAction
   Stop` is what makes them catchable. A `try/catch` *without* `-EA Stop` only *looks*
   defensive — this is the reading trap graded in L2.5 and re-tested at the L2.7 gate.
3. **Decorators are a legitimacy costume, not a safety signal.** `[CmdletBinding()]` +
   `[Parameter()]` make a function look professional; malware wears the same scaffolding
   (map §6 security hook, L2.4). The phase teaches learners to read structure without
   inferring intent from it.

### Safety-by-design posture for this phase (carry-through)

Phase 2 executes **no attack content** — every teaching artifact is a benign admin
construct. Attack material stays **name-only** (§2c inherited): the L2.4 security hook
*names* that malware mimics `[CmdletBinding()]`; nothing malicious is run, downloaded,
or decoded. **Command-shadowing (the bash Phase-3/4 logging stand-in) is not required
in Phase 2** and is not introduced here — there is no dangerous execution to shadow.
It becomes relevant at **Phase 4 (attack surface)** and **Phase 5 (deobfuscation)**,
where "what would this do" demos will use a PowerShell shadow/logging stand-in (never
real execution) and static-text-only payload samples. Any hostname/URL/IP that ever
appears in prose is fictional and defanged (`hxxp`, `[.]`).

---

## 1. Confirmed lab list (read from the map — ids/titles/types verbatim)

**Phase 2 — Control Flow, Errors & Modules (7).** Gate: **L2.7**. No mid-phase gates.

| id | title | type | gate? | est_min |
|----|-------|------|-------|---------|
| L2.1 | `if`/`elseif`/`else` and comparison operators — `-eq`,`-ne`,`-like`,`-match` | DECODE | no | 15 |
| L2.2 | `switch` — regex, wildcard, file modes | DECODE | no | 20 |
| L2.3 | Loops — `for`, `foreach`, `while`, `do-while` | PREDICT | no | 15 |
| L2.4 | Functions & parameters — `[Parameter()]`, `[CmdletBinding()]` | DECODE | no | 20 |
| L2.5 | Error handling — `try/catch/finally`, `$Error`, `-ErrorAction`, `$?` | DECODE | no | 20 |
| L2.6 | Modules — `Import-Module`, `Get-Command`, `Get-Module`; reading a manifest | DECODE | no | 20 |
| L2.7 | **Phase gate:** read a 60-line admin script cold, answer 10 questions | DECODE | **yes** | 30 |

**Gate placement.** The map's Phase-2 outcome is a **cold comprehension read**, so the
gate *is* the last lab (L2.7, `gate:true`). The "answer 10 comprehension questions"
requirement is reconciled with the kit contract (`quiz.json` = **exactly 3**) exactly
as ps-p01's L1.8 gate did: the **10 questions live in the lab worksheet**, the learner
records answers in `answers.md` (graded for key facts by `check.sh`), and a **3-question
gate quiz enforces 3/3** as the hard checkpoint. See §3c.

**Recall placement** (kit-contract: `recall.json` only on a phase's first lab, drawn
from *earlier* phases):
- **L2.1** — Phase-2 opener → `recall.json`, 5 Qs spanning **Phase 0 + Phase 1**.
  Because Phase 1 is **not built**, these are **sourced from the curriculum map's
  Phase 0/1 lab list** (titles/one-line descriptions) and the settled ps-p01 anchors,
  and the whole block is marked **`[VERIFY-AT-BUILD]`** — reconcile against the actual
  built Phase 0/1 content at build time. It also reconciles with the L2.1 recall
  **already forward-drafted under ps-p01 §5 (L1.8)** — identical intent, same sources.
- **L3.1** — Phase-3 opener → its `recall.json` is **drafted during the L2.7 build**
  (Phase Builder step 6), speced under L2.7 as a build deliverable (5 Qs from Phase 1+2).

---

## 2. Track-wide build conventions (inherited from ps-p01 §2 — restated, unchanged)

**File set per lab** (kit-contracts): `meta.json`, `lab.md` (`## BRIEF` ≤10 lines +
`## GUIDED STEPS`), `quiz.json` (exactly 3), `check.sh` (0644, sources `$LAB_CHECKLIB`,
`ck_summary` last), `hints.json` (exactly 3, level 1 never the answer), `recap.md`
(exactly 3 lines, no bullet prefix), optional `files/`, `recall.json` only where §1
says. `meta.json.id` == dir id. Dir grammar
`tracks/ps/phases/p2/L2.<n>-<slug>/`. Phase dir: `tracks/ps/phases/p2`.
`tracks/ps/track.json` already exists (add `phases.p2:"Control Flow, Errors & Modules"`
if the manifest enumerates phases).

**§2a grader architecture (inherited).** **PREDICT (deterministic) labs: `check.sh`
re-runs the canonical construct itself** via `pwsh -NoProfile -NonInteractive -File
<probe>.ps1` (probe ships in `files/`) and grades the real output — SC2016-safe (no `$`
in a `pwsh -Command`), echo-cheat-proof, encoding/culture/newline-safe under the pinned
`LANG=C.UTF-8` + UTF-8-no-BOM/LF. **DECODE labs: `check.sh` grades a learner extraction
artifact** (a reading answer) plus the gating quiz. In Phase 2, DECODE labs *also* ship
a small **fact probe** where a single language behavior is deterministic (e.g. `switch`
fall-through, `-EA Stop` catchability) — the probe proves the concept by construction
so the grade doesn't rest on free text alone. Each `check.sh` exports
`POWERSHELL_TELEMETRY_OPTOUT=1` and `POWERSHELL_UPDATECHECK=Off` before any pwsh call.

**§2b grader hygiene (inherited — the rules that keep graders honest):**
- **Single-quote every literal pattern containing `$`** (`assert_file_contains_fixed x '$_'`),
  never `"$_"` (double-quotes expand → `grep -F ""` matches any non-empty file → false pass).
- **`assert_output_contains` signature is `"desc" pattern "hint" -- cmd…`** — it runs a
  *command*, not a filename. Use `-- pwsh -NoProfile -NonInteractive -File probe.ps1`.
- **`assert_file_not_contains` passes vacuously on a missing file** — always precede
  with `assert_file_exists` on the same path.
- **`.NET`/dotted literals use `assert_file_contains_fixed`** (grep `-F`); dots are ERE
  wildcards otherwise.
- **Free-text DECODE matches tolerate case/word-form** via ERE (`[Ee]xecut(e|es|ing|ion)`),
  **no `^`/`$` anchors on free text** (BOM/CRLF tolerance). Anchors only on numeric probe
  outputs `check.sh` itself produced.
- **Type names:** `.GetType().Name` → `Int32`/`String`; `Get-Member` → accelerators
  `int`/`string`. Grade whichever the probe prints; don't mix.
- Standard set-e traps: `n=$((n+1))` not `((n++))`; `IFS= read -r v || v=""`; guard
  `LAB_WORKSPACE`/`LAB_CHECKLIB` with `: "${V:?}"`.

**§2c attack-content ceiling (inherited, extended to Phase 2).** Attack material is
**name-only** and never executed. No `check.sh` ever calls `iex`/`DownloadString`/`-enc`.
Every artifact in this phase is benign admin PowerShell. Windows-only references that
appear (e.g. an `ActiveDirectory` module name in the L2.6 sample manifest) are **read as
static data** (`Import-PowerShellDataFile`, which does not execute module code), never
imported — so nothing here depends on a Windows-only module being present.

---

## 3. Phase-2-specific decisions

### 3a. DECODE-heavy phase → grade the *read*, not a capture

6 of 7 labs are DECODE. The failure mode is grading free text that a learner can
keyword-stuff. Mitigation, applied per lab: pair each DECODE artifact assertion with a
**deterministic fact probe** wherever the underlying language behavior is stable —
`switch` fall-through (L2.2), `-EA Stop` catchability (L2.5), advanced-function common
params (L2.4), manifest export list read as data (L2.6). The probe carries the concept;
the artifact + quiz carry the comprehension. The one true PREDICT lab (L2.3) grades
probe output directly.

### 3b. Windows-variant surface is minimal — Phase 2 is cross-platform

Control flow, operators, `switch`, loops, advanced functions, `try/catch`, and modules
are **language-level** features, identical on pwsh 7 / WSL2 and Windows PS. **The graded
path is pwsh 7 on WSL2 for every lab; there is no Windows grading dependency in this
phase.** The only Windows-flavored content is cosmetic and non-grading: L2.6's sample
manifest *names* `RequiredModules = @('ActiveDirectory')` (a Windows-only module) purely
to show a dependency line — graded by reading the `.psd1` as data, never by importing it.
No AMSI / CLM / Constrained Language Mode content appears until Phase 4. No lab is tagged
`[WINDOWS-VARIANT]`; the L2.6 manifest note is documented in §7 so the builder doesn't
try to import AD.

### 3c. The L2.7 gate: "10 comprehension questions" → worksheet + 3-question gate quiz

`quiz.json` is contractually **exactly 3**, but the map asks for **10** comprehension
questions. Resolution (mirrors ps-p01 L1.8): the 60-line script ships in `files/`; the
`lab.md` worksheet poses **10 numbered comprehension questions**; the learner writes
answers into `answers.md`; `check.sh` greps `answers.md` for **several load-bearing key
answers** (threshold-style, set-e-safe) as *engagement + comprehension* evidence; and the
**3-question `quiz.json` is the formal gate (3/3 required)**, chosen to force the exact
reading calls `answers.md` can't be faked into (the `-EA Stop` trap, the `[ValidateSet]`
binding-time rejection, and a branch-logic prediction). One **deterministic fact probe**
(`Get-HealthTag` in isolation) proves the branch logic by construction.

---

## 4. Phase 2 — lab-by-lab build spec

> Phase-2 spine: *read the control structures wrapped around the pipeline.* Each DECODE
> lab pairs a learner reading-artifact with a deterministic fact probe (§3a); the one
> PREDICT lab grades probe output; the gate integrates all six constructs on a cold read.

### L2.1 — `if`/`elseif`/`else` and comparison operators · DECODE · **Phase-2 opener** · est 15m

**Teaching artifact (DECODE).** Read conditional logic and the PS comparison operators.
The three reading traps: `-eq` is **case-insensitive by default**; `-match` **fills
`$Matches`**; `-eq` **against an array filters** (returns the matches, not `$true`).

```powershell
if     ($p.WS -gt 100MB) { 'big' }
elseif ($p.WS -gt 10MB)  { 'medium' }
else                     { 'small' }

'Hello' -eq  'hello'            # → True    (-eq is case-INSENSITIVE by default)
'Hello' -ceq 'hello'            # → False   (-ceq / -clike / -cmatch are the case-sensitive forms)
'report.txt' -like  '*.txt'     # → True    (-like  = wildcards * ?)
'2026-07-18' -match '\d{4}'     # → True    (-match = regex; ALSO populates $Matches)
$Matches[0]                     # → 2026    (the regex capture from the last -match)
@('a','b','admin') -eq 'admin'  # → admin   (-eq on an ARRAY *filters* — returns matches, not a bool)
```

DECODE moment: comparisons are `-eq -ne -gt -lt -ge -le -like -match -contains -in`
(never `==`/`>`); default case-**insensitivity** and the `-c…` case-sensitive forms are
a real triage detail (a password/hash compare that *should* be case-sensitive but uses
`-eq` is a bug); `-eq` on an array changes what an `if` condition *means*.

**Environment note.** Clean pwsh 7 (operators are language-level, cross-platform).

**check.sh grades** (DECODE artifact + two deterministic fact probes):
- ship `files/caseq.ps1`:
  ```powershell
  if ('Hello' -ceq 'hello') { 'ceq-MATCH' } else { 'ceq-differs' }
  if ('Hello' -eq  'hello') { 'eq-MATCH'  } else { 'eq-differs'  }
  ```
  `assert_output_contains "-eq is case-insensitive; -ceq is not" "ceq-differs" "run: pwsh -File caseq.ps1" -- pwsh -NoProfile -NonInteractive -File caseq.ps1`
  **and** a second assert for `eq-MATCH` (both tokens prove the learner ran the real probe).
- ship `files/match.ps1` (`'2026-07-18' -match '\d{4}' | Out-Null; $Matches[0]`):
  `assert_output_contains "-match fills \$Matches" "2026" "run: pwsh -File match.ps1" -- pwsh -NoProfile -NonInteractive -File match.ps1`.
- DECODE extraction: learner writes `verdict.txt` explaining why `@('a','b','admin') -eq
  'admin'` returns `admin`, not `True`. `assert_file_exists verdict.txt`, then
  `assert_file_contains verdict.txt '[Aa]rray'` **and** `assert_file_contains verdict.txt
  '[Ff]ilter'` (case/word-tolerant; no anchors).

**Quiz (3):**
1. *(choice)* Is `-eq` case-sensitive by default? → **No — case-insensitive; `-ceq` is
   the case-sensitive form**. *(distractor: "yes, case-sensitive")*
2. *(text)* Which operator does **wildcard** matching (`*`, `?`)? → **`-like`** *(accept
   `-like`; `-match` is regex)*.
3. *(choice)* `@('a','b','admin') -eq 'admin'` returns? → **the string `admin` — `-eq`
   on an array filters and returns the matching elements, not `$true`**. *(distractor:
   "`$true`")*

**Recap (3 lines):**
```
PS comparisons are -eq -ne -gt -lt -like (wildcard) -match (regex) — never == or >
-eq is case-INSENSITIVE by default; the -c prefix (-ceq/-clike/-cmatch) is case-sensitive
-eq against an array FILTERS (returns matches); -match fills $Matches — both change what an if means
```

**recall.json (L2.1 — 5 Qs from Phase 0 + Phase 1) — `[VERIFY-AT-BUILD]` (Phase 0/1 not
yet built; sourced from the curriculum map's Phase 0/1 lab list + settled ps-p01 anchors;
reconcile with the built content and with ps-p01's L1.8 forward-draft at build time):**
1. `source: ps L1.2` — Does a PS pipeline pass text or objects? → **objects**.
2. `source: ps L1.3` — Which cmdlet reveals an object's TypeName and methods? → **Get-Member**.
3. `source: ps L1.5` — `1..10 | Where-Object { $_ % 2 -eq 0 }` → ? → **2 4 6 8 10**.
4. `source: ps L0.3` — Execution Policy: boundary or speed bump? → **speed bump**.
5. `source: ps L1.4` — What does `Select-Object -ExpandProperty` do? → **unwraps to the
   bare underlying value**.

---

### L2.2 — `switch` — regex, wildcard, file modes · DECODE · est 20m

**Teaching artifact (DECODE).** The PS `switch` is more powerful than most languages':
**no implicit break** (fall-through), plus `-Wildcard` / `-Regex` / `-File` matching modes.

```powershell
switch ('report.exe') {
    '*.txt' { 'text file' }
    '*.exe' { 'executable' }
    default { 'unknown' }
}
# WITHOUT -Wildcard the labels are EXACT literals → 'unknown'.  With -Wildcard → 'executable'.

switch -Regex ('4104') {
    '^\d+$' { 'all-digits' }
    '41'    { 'contains-41' }     # ← ALSO matches (unanchored regex) — switch has no auto-break
    default { 'no-match' }
}
# → BOTH 'all-digits' AND 'contains-41' run (fall-through) unless a `break` stops after the first.

switch -File ./events.log {       # reads the file LINE BY LINE; $_ = each line
    'FAILED' { "auth failure: $_" }
}
```

DECODE moment: (1) one value can fire **several** case blocks — `break`/`continue`
control it; (2) `-Wildcard`/`-Regex`/`-File` change matching semantics, and with **no**
modifier the labels are exact (case-insensitive) equality; (3) `switch -File` is a
line-reader, common in log-triage scripts (foreshadows Phase 4/5 log reading).

**Environment note.** Clean pwsh 7. `switch -File` needs a shipped `files/events.log`.
Cross-platform.

**check.sh grades** (DECODE artifact + fall-through probe + file-mode probe):
- ship `files/fallthrough.ps1` (the `-Regex ('4104')` switch above, blocks emitting
  `DIGITS` and `HAS41`):
  `assert_output_contains "switch falls through — 4104 hits BOTH cases" "DIGITS" "run: pwsh -File fallthrough.ps1" -- pwsh -NoProfile -NonInteractive -File fallthrough.ps1`
  **and** a second assert for `HAS41` (proves fall-through by construction).
- ship `files/events.log` (2–3 lines incl. `FAILED`) + `files/scanlog.ps1`
  (`switch -File ./events.log { 'FAILED' { "HIT:$_" } }`):
  `assert_output_contains "switch -File reads lines" "HIT:" "run: pwsh -File scanlog.ps1" -- pwsh -NoProfile -NonInteractive -File scanlog.ps1`.
- DECODE extraction: learner writes `notes.txt` explaining why the regex switch printed
  two lines. `assert_file_exists notes.txt`, then `assert_file_contains notes.txt
  '[Bb]reak|[Ff]all'` (names the no-auto-break / fall-through behavior).

**Quiz (3):**
1. *(choice)* Does PS `switch` stop after the first matching case? → **No — it falls
   through; multiple cases can run unless `break`/`continue` is used**. *(distractor:
   "yes, like C/Java")*
2. *(text)* Which `switch` option makes the labels regular expressions? → **`-Regex`**.
3. *(choice)* `switch -File $path { … }` does what with the file? → **reads it line by
   line, testing each line as `$_`**. *(distractor: "matches against the file's name")*

**Recap (3 lines):**
```
PS switch has NO implicit break — one value can fire several case blocks (use break/continue)
-Wildcard / -Regex / -File change matching; with no option the labels are exact literals
switch -File reads a file line by line ($_ = each line) — a log-triage pattern you'll see again
```

**recall.json:** none (not the opener).

---

### L2.3 — Loops — `for`, `foreach`, `while`, `do-while` · PREDICT · est 15m

**Teaching artifact (PREDICT).** Predict the output of the four loop forms; the key
insight is **`do-while` runs at least once** even when the condition is false up front,
and the **`foreach` statement is not the `ForEach-Object` cmdlet** (L1.6).

```powershell
for ($i = 1; $i -le 3; $i++) { $i }          # → 1 2 3
foreach ($n in 2,4,6) { $n + 1 }             # → 3 5 7   (foreach STATEMENT — in-memory, no pipeline)
$i = 0; while ($i -lt 3) { $i; $i++ }        # → 0 1 2
$i = 5; do { $i; $i++ } while ($i -lt 3)     # → 5       (do-while runs ONCE despite the false test)
```

**Deterministic anchors** (unique per construct): `for` → **1 2 3**; `foreach` →
**3 5 7**; `while` → **0 1 2**; `do-while` → **5** (the run-once anchor). Contrast to
L1.6: the `foreach` *statement* iterates a collection already in memory (`$_` is **not**
used); `ForEach-Object` is the pipeline cmdlet that binds `$_`.

**Environment note.** Clean pwsh 7.

**check.sh grades** (PREDICT — shipped probes, exact by construction; §2a):
- ship `files/forloop.ps1` (`for ($i=1;$i -le 3;$i++){$i}`): asserts `^1$ ^2$ ^3$`
  via `-- pwsh -NoProfile -NonInteractive -File forloop.ps1`.
- ship `files/foreachstmt.ps1` (`foreach ($n in 2,4,6){$n+1}`): asserts `^3$ ^5$ ^7$`.
- ship `files/dowhile.ps1` (`$i=5; do { $i; $i++ } while ($i -lt 3)`): assert `^5$`
  present **and** (belt) that the loop did **not** continue — no `^6$`
  (`assert_file_exists` the captured out then `assert_file_not_contains … '^6$'`, or an
  explicit run-once check). Because `check.sh` runs the probe, the run-once fact is
  proven, not asserted on faith.
- `assert_file_exists prediction.txt` (learner predicted before running).

**Quiz (3):**
1. *(text)* `$i=5; do { $i; $i++ } while ($i -lt 3)` → output? → **5** *(runs once even
   though the condition is already false)*.
2. *(choice)* Difference between the `foreach` **statement** and the `ForEach-Object`
   **cmdlet**? → **the statement iterates an in-memory collection (no pipeline); the
   cmdlet streams pipeline input and binds `$_`**. *(distractor: "they are identical")*
3. *(text)* `for ($i=1; $i -le 3; $i++) { $i }` → ? → **1 2 3**.

**Recap (3 lines):**
```
for / foreach / while / do-while all exist in PS; do-while (and do-until) always run at least once
the foreach STATEMENT (foreach($x in $c){}) is NOT the ForEach-Object CMDLET ($_ in a pipeline)
read the loop header to know the trip count before you read the body
```

**recall.json:** none.

---

### L2.4 — Functions & parameters — `[Parameter()]`, `[CmdletBinding()]` · DECODE · est 20m

**Teaching artifact (DECODE).** Read an advanced function and name what its decorators
do. Map §6 security hook: **sophisticated malware uses `[CmdletBinding()]` and proper
parameter decorators to look legitimate** — the learner must read structure without
inferring safety from it.

`files/tool.ps1` (shipped; the learner reads it):
```powershell
function Get-SuspiciousProcess {
    [CmdletBinding()]                             # → advanced function: gains -Verbose/-ErrorAction/… + $PSCmdlet
    param(
        [Parameter(Mandatory)]
        [string]$Name,                            # required, typed [string]

        [Parameter(ValueFromPipeline)]
        [int]$MinWorkingSetMB = 100,              # optional, pipeline-bindable, default 100

        [ValidateSet('Stop','Continue','Ignore')]
        [string]$OnFound = 'Continue'             # constrained to 3 allowed values (rejected at binding otherwise)
    )
    process {
        Get-Process -Name $Name |
            Where-Object { $_.WS -gt ($MinWorkingSetMB * 1MB) }
    }
}
```

DECODE moment: `[CmdletBinding()]` promotes a function to an **advanced function**
(common parameters `-Verbose`/`-ErrorAction`/…, plus `$PSCmdlet`); `[Parameter(Mandatory)]`
forces the argument; `ValueFromPipeline` binds pipeline input; `[ValidateSet()]` restricts
values (invalid input is rejected **before the body runs**). Security read: this
scaffolding is a **legitimacy costume** — its presence is not a safety signal.

**Environment note.** Clean pwsh 7 (language feature, cross-platform). `[VERIFY-AT-BUILD]`:
common parameters appear when *either* `[CmdletBinding()]` *or* any `[Parameter()]`
attribute is present — the probe below proves "advanced function," which this function is
by both routes; keep the quiz answer about `[CmdletBinding()]`'s role, not exclusivity.

**check.sh grades** (DECODE artifact + advanced-function fact probe):
- ship `files/probe.ps1` (dot-sources the function, checks it gained a common param):
  ```powershell
  . ./tool.ps1
  (Get-Command Get-SuspiciousProcess).Parameters.ContainsKey('Verbose')   # → True
  ```
  `assert_output_contains "advanced function exposes the common param -Verbose" "True" "run: pwsh -File probe.ps1" -- pwsh -NoProfile -NonInteractive -File probe.ps1`.
  *(Dot-sourcing `tool.ps1` only defines the function; it is not invoked — no side effects.)*
- DECODE extraction: learner writes `answers.txt` identifying the mandatory parameter,
  what `[CmdletBinding()]` adds, and the `[ValidateSet]` values.
  `assert_file_exists answers.txt`, `assert_file_contains_fixed answers.txt 'Name'`,
  `assert_file_contains answers.txt '[Mm]andator'`, `assert_file_contains answers.txt
  '[Vv]erbose|[Cc]ommon'`.

**Quiz (3):**
1. *(choice)* What does `[CmdletBinding()]` do to a function? → **makes it an advanced
   function — adds the common parameters (`-Verbose`, `-ErrorAction`, …) and `$PSCmdlet`**.
   *(distractor: "declares it a compiled C# cmdlet")*
2. *(text)* In `[Parameter(Mandatory)]`, what does `Mandatory` enforce? → **the caller
   must supply that parameter (PS prompts if it's missing)**.
3. *(choice)* Why do these decorators matter in malware triage? → **they make a malicious
   function look like legitimate, structured code — presence of decorators is not a
   safety signal**. *(distractor: "they prove the script is safe/signed")*

**Recap (3 lines):**
```
[CmdletBinding()] promotes a function to an advanced function: common params (-Verbose/-ErrorAction), $PSCmdlet
[Parameter(Mandatory)], ValueFromPipeline, and [ValidateSet()] declare and constrain inputs
professional decorators are a legitimacy costume — malware wears them too; they are not a safety signal
```

**recall.json:** none.

---

### L2.5 — Error handling — `try/catch/finally`, `$Error`, `-ErrorAction`, `$?` · DECODE · est 20m

**Teaching artifact (DECODE).** The core reading fact: **most cmdlet errors are
non-terminating and slip past `try/catch`** — `-ErrorAction Stop` is what makes them
catchable. A `try/catch` without `-EA Stop` only *looks* defensive.

```powershell
try {
    Get-Content './missing.txt' -ErrorAction Stop    # -EA Stop → terminating → CATCHABLE
}
catch {
    "caught: $($_.Exception.GetType().Name)"          # $_ / $PSItem in catch = the ErrorRecord
}
finally {
    'cleanup runs no matter what'                     # finally ALWAYS runs
}

Get-Content './missing.txt'      # WITHOUT -EA Stop → NON-terminating → not caught; execution CONTINUES
$?                               # → False   (the last command's success flag)
$Error[0]                        # the most recent error record ($Error is an auto array)
```

DECODE moment: terminating vs non-terminating is *the* PS error-handling reading skill;
`-ErrorAction Stop` (or `$ErrorActionPreference='Stop'`) converts non-terminating →
terminating; `$_` in `catch` is the ErrorRecord; `$?` is a boolean; `finally` always
runs. Security read: a risky call wrapped in `try/catch` *without* `-EA Stop` is a false
tell of robustness — the error still leaks and the script sails on.

**Environment note.** Clean pwsh 7. `[VERIFY-AT-BUILD]`: exact exception type for
`Get-Content` on a missing path on Linux pwsh (`ItemNotFoundException` vs
`FileNotFoundException`) — the probe below greps a fixed marker (`CAUGHT`/`FINALLY`), not
the type string, so it's tolerant; the DECODE artifact must not require the exact type.

**check.sh grades** (DECODE artifact + terminating/non-terminating probes):
- ship `files/catch.ps1`
  (`try { Get-Content './nope.txt' -ErrorAction Stop } catch { 'CAUGHT' } finally { 'FINALLY' }`):
  `assert_output_contains "-EA Stop makes the error catchable" "CAUGHT" "run: pwsh -File catch.ps1" -- pwsh -NoProfile -NonInteractive -File catch.ps1`
  **and** a second assert for `FINALLY`.
- ship `files/nocatch.ps1`
  (`try { Get-Content './nope.txt' } catch { 'CAUGHT' }` then `'REACHED-END'`):
  the non-terminating error is **not** caught; `REACHED-END` prints and `CAUGHT` does not.
  `assert_output_contains "a non-terminating error is not caught — execution continues" "REACHED-END" "run: pwsh -File nocatch.ps1" -- pwsh -NoProfile -NonInteractive -File nocatch.ps1`.
  `[VERIFY-AT-BUILD]`: confirm the harness captures **stdout** and that the cmdlet's error
  goes to stderr (so `REACHED-END` is the graded stdout line, `CAUGHT` genuinely absent).
- DECODE extraction: learner writes `why.txt` explaining why the second `try/catch` didn't
  fire. `assert_file_exists why.txt`, then `assert_file_contains why.txt
  '[Nn]on.?terminat|[Ee]rror.?[Aa]ction|[Ss]top'`.

**Quiz (3):**
1. *(choice)* Does a plain `try/catch` catch a normal cmdlet error like `Get-Content` on
   a missing file? → **No — most cmdlet errors are non-terminating; add `-ErrorAction
   Stop` to make them catchable**. *(distractor: "yes, always")*
2. *(text)* What does `$?` hold after a command runs? → **a boolean — whether the last
   command succeeded (`True`/`False`)**.
3. *(choice)* When does the `finally` block run? → **always — whether or not an error was
   thrown or caught**. *(distractor: "only when an error is caught")*

**Recap (3 lines):**
```
most PS cmdlet errors are NON-terminating and slip past try/catch — add -ErrorAction Stop to catch them
$_ in catch is the ErrorRecord; $Error[0] is the most recent; $? is the last command's success bool
finally always runs; a try/catch without -EA Stop only LOOKS defensive
```

**recall.json:** none.

---

### L2.6 — Modules — `Import-Module`, `Get-Command`, `Get-Module`; reading a manifest · DECODE · est 20m

**Teaching artifact (DECODE).** Read a module **manifest** (`.psd1`) to learn a module's
surface before reading a line of its code: what it exports, its version, and its
dependencies. Distinguish `.psd1` (manifest/metadata) from `.psm1` (the code).

`files/AdminTools.psd1` (shipped; read as data, never imported live):
```powershell
@{
    RootModule        = 'AdminTools.psm1'                        # the code file this manifest fronts
    ModuleVersion     = '1.2.0'
    GUID              = 'a1b2c3d4-1111-2222-3333-444455556666'
    Author            = 'IT Ops'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Get-DiskReport','Restart-AppPool')   # the real public surface (explicit list)
    CmdletsToExport   = @()
    RequiredModules   = @('ActiveDirectory')                    # a dependency (Windows-only — named only, not imported)
}
```
Reading commands (shown in `lab.md`; the graded probe uses the data-only reader):
```powershell
$m = Import-PowerShellDataFile ./AdminTools.psd1   # parses the .psd1 as a hashtable — does NOT run module code
$m.FunctionsToExport                               # → Get-DiskReport, Restart-AppPool
$m.ModuleVersion                                   # → 1.2.0
# (live equivalents, for reference: Import-Module ./AdminTools.psd1 ; Get-Command -Module AdminTools ; Get-Module AdminTools)
```

DECODE moment: `.psd1` = manifest (a metadata hashtable); `.psm1` = the code;
`RootModule` names the code that loads; `FunctionsToExport` is the real public surface
(`'*'` = "everything — read the code to know it"); `RequiredModules` = dependencies.
`Get-Command -Module <Name>` lists a *loaded* module's exports; `Get-Module` shows what's
loaded vs `-ListAvailable`. Reading the manifest first maps the surface cheaply.

**Environment note.** Clean pwsh 7. The graded probe uses **`Import-PowerShellDataFile`**
(reads the `.psd1` as data — no module execution, no `ActiveDirectory` dependency, offline).
`[VERIFY-AT-BUILD]`: confirm `Import-PowerShellDataFile ./AdminTools.psd1` returns the
hashtable with `FunctionsToExport` intact under the harness `HOME`/PATH redirect. A tiny
`files/AdminTools.psm1` (two trivial `function` stubs) ships alongside so the manifest is
internally consistent, but it is never imported by `check.sh`.

**check.sh grades** (DECODE artifact + manifest-read probe):
- ship `files/readmanifest.ps1`
  (`$m = Import-PowerShellDataFile ./AdminTools.psd1; $m.FunctionsToExport; $m.ModuleVersion`):
  `assert_output_contains "the manifest exports Get-DiskReport" "Get-DiskReport" "run: pwsh -File readmanifest.ps1" -- pwsh -NoProfile -NonInteractive -File readmanifest.ps1`,
  a second assert for `Restart-AppPool`, and a third for `1.2.0`.
- DECODE extraction: learner writes `notes.txt` distinguishing `.psd1` vs `.psm1` and
  naming `RootModule`. `assert_file_exists notes.txt`,
  `assert_file_contains_fixed notes.txt '.psm1'`, `assert_file_contains_fixed notes.txt
  'RootModule'`, `assert_file_contains notes.txt '[Mm]anifest'`.

**Quiz (3):**
1. *(choice)* What is a `.psd1` file? → **a module manifest — a hashtable of metadata
   (version, exports, dependencies); the `.psm1` holds the actual code**. *(distractor:
   "the compiled module binary")*
2. *(text)* Which cmdlet lists the commands a **loaded** module exports? → **`Get-Command
   -Module <Name>`**.
3. *(choice)* In a manifest, `FunctionsToExport = '*'` means? → **export everything — the
   real surface is hidden, so you must read the code to know it**. *(distractor: "export
   nothing / the module is empty")*

**Recap (3 lines):**
```
.psd1 = manifest (metadata hashtable: version, exports, RequiredModules); .psm1 = the code
Import-Module loads it; Get-Command -Module lists exports; Get-Module shows what's loaded
read the manifest first — RootModule, FunctionsToExport, RequiredModules map the surface before the code
```

**recall.json:** none.

---

### L2.7 — Phase gate: read a 60-line admin script cold · DECODE · **GATE** · est 30m

**Teaching artifact (DECODE — the integrative gate).** A ~60-line **benign** admin
script (`files/health-snapshot.ps1`) the learner reads cold, exercising every Phase-2
construct: comparison operators + `if/elseif` (L2.1), `switch` (L2.2), a `foreach` loop
(L2.3), an advanced function with `[CmdletBinding()]`/`[ValidateSet]` (L2.4), a
`try/catch` **without** `-EA Stop` (L2.5, the reading trap), and `Import-Module` (L2.6).
The worksheet poses **10 numbered comprehension questions** (§3c); answers go in
`answers.md`.

Shipped script (skeleton — the build fleshes comments/validation to ~60 lines; all
behavior benign, no destructive action, no network):
```powershell
#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Quick','Full')]
    [string]$Mode,
    [int]$TopN = 5
)

Import-Module Microsoft.PowerShell.Management     # built-in; Get-Process/etc. (named to show an import)

function Get-HealthTag {
    param([double]$WorkingSetMB)
    if     ($WorkingSetMB -gt 500) { 'CRITICAL' }
    elseif ($WorkingSetMB -gt 100) { 'WARN' }
    else                           { 'OK' }
}

$report = foreach ($p in Get-Process | Sort-Object WS -Descending | Select-Object -First $TopN) {
    $mb  = [math]::Round($p.WS / 1MB, 1)
    [pscustomobject]@{ Name = $p.ProcessName; MB = $mb; Tag = (Get-HealthTag -WorkingSetMB $mb) }
}

switch ($Mode) {
    'Quick' { $report | Select-Object Name, Tag }
    'Full'  { $report | Format-Table -AutoSize }
    default { throw "unknown mode: $Mode" }        # unreachable: ValidateSet rejects invalid $Mode first
}

try {
    $report | ConvertTo-Json | Out-File './health.log'   # NOTE: no -ErrorAction Stop
}
catch {
    Write-Warning "log write failed: $($_.Exception.Message)"   # only fires on a TERMINATING error
}

$critical = @($report | Where-Object { $_.Tag -eq 'CRITICAL' })
if ($critical.Count -gt 0) { "escalate: $($critical.Count) critical process(es)" }
else                       { 'all clear' }
```

The **10 worksheet questions** target, in order: (1) the two `[ValidateSet]` values;
(2) the `CRITICAL` threshold (500 MB); (3) the tag for a 250 MB process (WARN); (4) what
`[CmdletBinding()]` grants; (5) why the `switch default` (`throw`) is effectively
**unreachable** (ValidateSet rejects invalid `$Mode` at binding); (6) whether the
`try/catch` around `Out-File` catches a **non-terminating** write error (**no** — missing
`-EA Stop`); (7) what `@(… )` wrapping guarantees for `.Count` (array even for 0/1 item —
L1.7 callback); (8) `foreach` **statement** vs the L1.6 cmdlet; (9) the object type in
`$report` (`pscustomobject`); (10) what `Sort-Object WS -Descending | Select-Object -First
$TopN` selects (the $TopN heaviest processes).

**Environment note.** Clean pwsh 7. `Get-Process` output is non-deterministic, so the
**script itself is not run for a graded capture**; determinism comes from an isolated
fact probe (below). `[VERIFY-AT-BUILD]`: confirm a mandatory-param + `ValidateSet` script
does not prompt/hang under the harness when the probe avoids invoking it directly.

**check.sh grades** (§3c: worksheet artifact threshold + one deterministic fact probe;
the 3-question quiz is the true gate):
- ship `files/tagprobe.ps1` (the `Get-HealthTag` function in isolation + two calls):
  ```powershell
  function Get-HealthTag { param([double]$WorkingSetMB)
    if ($WorkingSetMB -gt 500) {'CRITICAL'} elseif ($WorkingSetMB -gt 100) {'WARN'} else {'OK'} }
  Get-HealthTag -WorkingSetMB 600    # → CRITICAL
  Get-HealthTag -WorkingSetMB 250    # → WARN
  Get-HealthTag -WorkingSetMB 50     # → OK
  ```
  `assert_output_contains "600MB tags CRITICAL" "CRITICAL" "run: pwsh -File tagprobe.ps1" -- pwsh -NoProfile -NonInteractive -File tagprobe.ps1`,
  plus asserts for `WARN` and `OK` (proves the learner can predict the branch logic).
- `assert_file_exists answers.md`, then a **set-e-safe ≥N-of-M threshold** (kit idiom:
  `n=$((n+1))`, `if grep -Eiq …`) over the load-bearing answers — e.g. `500`,
  `Quick`/`Full`, `[Nn]on.?terminat|-?ErrorAction|Stop`, `throw`, `WARN`, `pscustomobject`
  — requiring, say, ≥4 of 6 (comprehension evidence; `answers.md` is keyword-stuffable, so
  the quiz owns the gate).

**Quiz (3) — the gate** (forces the reads `answers.md` can't fake):
1. *(choice)* The `try/catch` around `Out-File` has no `-ErrorAction Stop`. If the write
   fails with a normal non-terminating error, what happens? → **the `catch` does NOT fire
   (the non-terminating error slips past); the script continues**. *(distractor:
   "`Write-Warning` runs")*
2. *(choice)* The script is called with `-Mode Verbose`. What happens? → **PS rejects it
   at parameter binding (`ValidateSet` allows only `Quick`/`Full`) — the body never runs,
   and the `switch default`/`throw` is never reached**. *(distractor: "it hits the switch
   `default` and throws `unknown mode`")*
3. *(text)* In `Get-HealthTag`, a process using **250 MB** returns which tag? → **`WARN`**
   *(250 > 100 but not > 500)*.

**Recap (3 lines):**
```
you can now read an admin script cold: params/validation, branch logic, loops, switch, try/catch, modules
watch the reading traps: try/catch without -EA Stop isn't defensive; ValidateSet rejects before the body runs
naming what each construct does — not guessing from how professional it looks — is Phase 2 fluency
```

**recall.json:** none on L2.7 (gate, not opener). **Build deliverable (Phase Builder
step 6): draft L3.1's `recall.json` now** — 5 Qs spanning Phase 1 **and** 2, all marked
`[VERIFY-AT-BUILD]` (reconcile with built Phase 1/2 content):
1. `source: ps L2.1` — Is `-eq` case-sensitive by default? → **No — case-insensitive
   (`-ceq` is the case-sensitive form)**.
2. `source: ps L2.2` — Does a PS `switch` stop after the first match? → **No — it falls
   through unless `break`**.
3. `source: ps L2.5` — What makes a non-terminating error catchable by `try/catch`? →
   **`-ErrorAction Stop`**.
4. `source: ps L2.4` — What does `[CmdletBinding()]` add to a function? → **advanced-
   function common parameters (`-Verbose`, `-ErrorAction`, …) + `$PSCmdlet`**.
5. `source: ps L1.3` — Which cmdlet reveals an object's TypeName and methods? →
   **`Get-Member`**.

---

## 5. Build order, self-test, phase-close (Phase Builder protocol)

1. Scaffold `tracks/ps/phases/p2` (add `phases.p2` to `tracks/ps/track.json` if it
   enumerates phases). **Phase 2 assumes Phase 0+1 are built first** — if not, build
   ps-p01 before this phase (recall + `lab status` continuity depend on it).
2. Build **lab by lab in id order** (L2.1 → L2.7). Commit each after its self-test:
   `ps <id>: <title>`.
3. **Self-test every lab (no-fiction rule):** run every `lab.md` command in real pwsh 7;
   paste REAL output, resolving every `[VERIFY-AT-BUILD]` (§7). Run `check.sh` twice —
   wrong/incomplete work (fails with a useful hint) and correct (passes). Trim any
   `lab.md` > ~180 lines or > ~15 commands.
4. **shellcheck-zero + lint:** every `check.sh` passes `tools/shellcheck-all.sh` **and**
   `tools/lint-labs.sh` (no absolute paths, no banned tokens, **no `$` in a `pwsh
   -Command` — use `-File`**). Ship every probe `.ps1`, `events.log`, `AdminTools.psd1`
   /`.psm1`, `tool.ps1`, and `health-snapshot.ps1` in each lab's `files/`.
5. **Gate:** L2.7 carries `gate:true`; verify `quiz_run` requires 3/3.
6. **Recall:** L2.1's `recall.json` ships now (5 Qs, still `[VERIFY-AT-BUILD]` against
   built Phase 0/1); L3.1's is drafted now (§4, L2.7).
7. **Close out:** `lab status` renders Phase 2; `lab resume` works mid-phase; update
   `planned_execution.md` (`ps p2` → done + evidence); tag `ps-p2`; report against the
   checklist below. One phase per session from here (map §8).

**Phase Acceptance Checklist (report each):** lab count/titles/types match the map (7,
6 DECODE + 1 PREDICT, gate at L2.7); every lab self-tested (real outputs pasted, fail +
pass paths run); shellcheck + lint clean; the gate is present + integrative and its quiz
requires 3/3; L2.1 recall ships + L3.1 recall drafted; `lab status`/`resume` correct;
`planned_execution.md` updated; phase tagged `ps-p2`.

---

## 6. Verification summary (authoring pass — corrections pre-folded from ps-p01)

No pwsh was executed this session (not installed — as in ps-p01). Rather than
rediscover ps-p01's settled traps, this plan **carries them forward**:
- **Grader architecture (§2a):** PREDICT (L2.3) grades a re-run `pwsh -File` probe; DECODE
  labs grade a learner extraction artifact **plus** a deterministic fact probe wherever
  the language behavior is stable (L2.1 case-eq, L2.2 fall-through, L2.4 advanced-fn,
  L2.5 `-EA Stop`, L2.6 manifest-as-data, L2.7 branch logic).
- **SC2016 avoided:** every pwsh call is `-File`; no `$` ever sits inside a `pwsh -Command`.
- **False-pass avoided:** single-quoted `$`-literals; `assert_file_exists` before every
  `assert_file_not_contains`; `.NET`/dotted literals via `assert_file_contains_fixed`;
  free-text DECODE via case/word-tolerant ERE with no anchors.
- **The real `assert_output_contains "desc" pattern "hint" -- cmd` 4-arg signature** is
  used everywhere; probe outputs are anchored (`^5$`), free text is not.
- **Type-name accelerator trap** is dodged (Phase 2 grades constructs/behavior, not
  `int`/`string` text from `Get-Member`).
- **Recall sourcing rule honored:** L2.1 recall is drafted from the curriculum's Phase
  0/1 lab list (Phase 1 unbuilt) and marked `[VERIFY-AT-BUILD]`.

**The build session must still run the per-lab adversarial correctness pass ps-p01 used**
(one PowerShell-7 + bash/harness reviewer per lab) and resolve §7 before shipping — that
pass, not this plan, is where runtime-exact strings get pinned.

---

## 7. Open `[VERIFY-AT-BUILD]` items (confirm against real pwsh 7.4 at build)

| lab | item |
|---|---|
| L2.1 | `caseq.ps1` prints `ceq-differs` + `eq-MATCH`; `$Matches[0]` = `2026` after a successful `-match`; byte-stability of both under `LANG=C.UTF-8` |
| L2.2 | `switch -Regex ('4104')` fires **both** `^\d+$` and `41` (unanchored regex substring) → two lines; `switch -File` reads `events.log` line by line and `$_` is each line |
| L2.3 | `for`→`1 2 3`, `foreach`(stmt)→`3 5 7`, `while`→`0 1 2`, `do-while`→`5` (run-once, no `6`); each on its own line for `^N$` anchors |
| L2.4 | `(Get-Command Get-SuspiciousProcess).Parameters.ContainsKey('Verbose')` = `True` after dot-sourcing; confirm common params come from `[CmdletBinding()]`/`[Parameter()]` and the function is not invoked by dot-sourcing |
| L2.5 | exact `Get-Content` missing-file exception type on Linux (`ItemNotFoundException` vs `FileNotFoundException`) — grade the `CAUGHT`/`FINALLY`/`REACHED-END` markers, **not** the type; confirm the harness captures stdout while the non-terminating error goes to stderr |
| L2.6 | `Import-PowerShellDataFile ./AdminTools.psd1` returns the hashtable with `FunctionsToExport` = `Get-DiskReport`,`Restart-AppPool` and `ModuleVersion` = `1.2.0` under the harness HOME/PATH redirect; **AD module is named-only, never imported** |
| L2.7 | the 60-line `health-snapshot.ps1` reads cleanly cold; `Get-HealthTag` probe → `CRITICAL`/`WARN`/`OK`; confirm a mandatory-param+`ValidateSet` script does not prompt/hang under the harness (probe never invokes it directly) |

---

*Plan v1 (authored from curriculum §6 + the settled ps-p01 template) — awaiting review.
PLAN ONLY; nothing built, nothing committed.*
