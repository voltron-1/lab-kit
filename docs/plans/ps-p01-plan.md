# LAB-KIT — `ps` Track, Phase 0 + Phase 1 — BUILD PLAN

**Status:** PLAN ONLY (uncommitted, for review). Binding content spec:
`docs/curriculum/powershell-literacy-lab-curriculum-v1.md` (Phase 0 + Phase 1).
Binding mechanical spec: `docs/kit-contracts.md`. A later BUILD session executes
this mechanically under the Phase Builder protocol (`PROMPTS.md` Prompt 2,
`TRACK: ps  PHASE: 0+1`). This session was **plan-only**: nothing built, no pwsh
run, nothing committed.

> **How this plan was verified.** pwsh is **not installed** in the planning
> environment, so no output could be executed. A 12-agent adversarial pass ran
> over all 11 labs — one PowerShell-7-correctness + bash/jq-harness-feasibility
> reviewer per lab, plus a cross-lab reconciler. Verdict: **fix-then-go** for both
> phases; all labs **feasible/risky**, none infeasible. Every correction it
> surfaced is folded into the specs below; the residual runtime-dependent items
> are collected in **§8** as `[VERIFY-AT-BUILD]`. The reviewer caught, among
> others: a bash `$name`-expansion false-pass and a wrong `assert_output_contains`
> signature (L0.2), an SC2016 lint trap (L0.1), and five PowerShell factual
> errors. Do not re-derive these — they are settled here.

---

## 0. Context — why this plan exists

The `ps` (PowerShell Literacy) track is the fourth of four LAB-KIT tracks. Its
thesis (map §1): **PowerShell pipelines pass objects, not text** — and that one
fact changes how you read every line of it. Phase 0 is plumbing (pwsh 7 on WSL2,
meet the kit, one honest conversation about Execution Policy). Phase 1 installs
the object-pipeline mental model that the whole rest of the track (Windows
internals, attack surface, deobfuscation) depends on. The map bundles Phase 0 +
Phase 1 into the first build (map §8, `planned_execution.md`): Phase 0 is unusable
alone, Phase 1 is the payload. **11 labs (3 + 8).**

### Three load-bearing environment facts (settled — build must honor)

1. **`check.sh` runs under `env -i` with `PATH=/usr/local/bin:/usr/bin:/bin`.**
   pwsh must be reachable there. The Microsoft **apt/deb** package symlinks
   **`/usr/bin/pwsh`** → `/opt/microsoft/powershell/7/pwsh` (on the allowlist).
   **snap** (`/snap/bin`), **dotnet global tool** (`~/.dotnet/tools`), and
   **Homebrew** (`/home/linuxbrew/.linuxbrew/bin`) are all **off** the allowlist —
   bare `pwsh` will not resolve and every grader that calls pwsh will fail.
   → **L0.1 mandates the apt/deb install. This is a track-wide precondition**
   (already non-negotiable because L0.1's own version check needs bare `pwsh`).
   `check.sh` calls bare `pwsh`; it may **never** hardcode `/usr/bin/pwsh`
   (`tools/lint-labs.sh` bans absolute-path literals).

2. **`env -i` redirects `HOME` to `<workspace>/.home`.** A module installed with
   `Install-Module -Scope CurrentUser` lands under the learner's *real* `$HOME`,
   so a **live** `Get-Module -ListAvailable` / `Invoke-ScriptAnalyzer` inside
   `check.sh` sees nothing and false-fails. → PSScriptAnalyzer presence is graded
   from **learner-written file artifacts only**, never re-run live in `check.sh`.

3. **The harness is bash + jq; graders invoke `pwsh` as a subprocess.** pwsh
   cold-start is ~0.5–1 s — every grader stays far inside `timeout 120s`. `HOME`
   and `TMPDIR` are redirected into the *writable* workspace, so pwsh's cache /
   PSReadLine writes succeed. `LANG=C.UTF-8` is pinned, and pwsh 7 on Linux emits
   **UTF-8 no-BOM, LF** — so grader-produced files are anchor-safe.

---

## 1. Confirmed lab list (read from the map — ids/titles/types verbatim)

**Phase 0 — Toolchain & Kit (3).** Exit gate: classify EP / AMSI / CLM.

| id | title | type | gate? | est_min |
|----|-------|------|-------|---------|
| L0.1 | Install pwsh on WSL2; verify version; first command | GUIDED | no | 20 |
| L0.2 | Meet the lab CLI — start, check, resume for the ps track | GUIDED | no | 15 |
| L0.3 | PS 5.1 vs PS 7, Windows vs cross-platform, and Execution Policy — what it is and what it is NOT | DECODE | **yes** | 20 |

**Phase 1 — The Object Pipeline (8).** Gate: L1.8.

| id | title | type | gate? | est_min |
|----|-------|------|-------|---------|
| L1.1 | Cmdlets and the verb-noun pattern | DECODE | no | 15 |
| L1.2 | Objects, not text | PREDICT | no | 20 |
| L1.3 | `Get-Member` | DECODE | no | 15 |
| L1.4 | `Select-Object` and properties | PREDICT | no | 20 |
| L1.5 | `Where-Object` | PREDICT | no | 15 |
| L1.6 | `ForEach-Object` and `$_` / `$PSItem` | PREDICT | no | 15 |
| L1.7 | Variables, typing, and `$null` | DECODE | no | 20 |
| L1.8 | Phase gate: five pipelines | PREDICT | **yes** | 25 |

**Gate placement.** Phase-0 exit gate lives in **L0.3** (`gate:true`) — the
EP/AMSI/CLM classification *is* the last lab of the phase. Phase-1 gate is **L1.8**
(`gate:true`). No mid-phase gates.

**Recall placement** (kit-contract: `recall.json` only on a phase's first lab,
drawn from *earlier* phases):
- **L0.1** — first lab of the first phase → **no `recall.json`** (nothing earlier).
  Design decision, stated so the build doesn't invent one.
- **L1.1** — Phase-1 opener → `recall.json`, 5 Qs from **Phase 0**.
- **L2.1** — Phase-2 opener → its `recall.json` is **drafted during the L1.8
  build** (Phase Builder step 6), speced under L1.8 as a build deliverable.

---

## 2. Track-wide build conventions (apply to every lab)

**File set per lab** (kit-contracts): `meta.json`, `lab.md` (`## BRIEF` ≤10 lines
+ `## GUIDED STEPS`), `quiz.json` (exactly 3), `check.sh` (0644, sources
`$LAB_CHECKLIB`, `ck_summary` last), `hints.json` (exactly 3, level 1 never the
answer), `recap.md` (exactly 3 lines, no bullet prefix), optional `files/`,
`recall.json` only where §1 says. `meta.json.id` == dir id. Dir grammar
`tracks/ps/phases/p<N>/L<phase>.<n>-<slug>/`. Add `tracks/ps/track.json`
`{title:"PowerShell Literacy Lab", tagline:"Read. Deobfuscate. Audit. Direct.",
order:<after soc>, phases:{p0:"Toolchain & Kit", p1:"The Object Pipeline"}}`.

### 2a. The grading architecture (the review's biggest refinement)

**Deterministic labs (GUIDED + PREDICT): `check.sh` re-runs the canonical
pipeline itself and grades the real output.** It does so **only via
`pwsh -NoProfile -NonInteractive -File <probe>.ps1`** where `<probe>.ps1` ships in
the lab's `files/`. Rationale, all from the verification pass:

- **SC2016-safe.** A `pwsh -Command '… $_ …'` in `check.sh` puts a `$` inside
  single quotes → shellcheck **SC2016** fires, and `# shellcheck disable=` is
  banned repo-wide, so `tools/lint-labs.sh` rejects the commit. Calling `-File`
  keeps every `$` inside the `.ps1` (never in `check.sh`). **Rule: `check.sh`
  invokes pwsh only via `-File`, never `-Command` with a `$`.**
- **Echo-cheat-proof.** Grading a learner-produced capture lets
  `echo "10" > out.txt` pass without pwsh. Re-running the probe under the harness
  removes that loophole.
- **Encoding/culture/newline-proof.** Under the pinned `LANG=C.UTF-8` +
  UTF-8-no-BOM/LF, `^N$` anchors are safe. (A file the learner produced on Windows
  PS 5.1 would be BOM+CRLF and false-fail; re-running in `check.sh` sidesteps it.)
- **Exclusivity by construction.** Because `check.sh` runs the exact probe, the
  three-`^N$`-asserts "dump-all-values false-pass" cannot occur — output is right
  by construction. Still add negative asserts as belt-and-suspenders.

Each such `check.sh` exports, before the pwsh call (plain env, no path literals):
`POWERSHELL_TELEMETRY_OPTOUT=1` and `POWERSHELL_UPDATECHECK=Off` (hermetic, quiet,
no update-check latency). The learner still **predicts then runs** the pipeline in
`## GUIDED STEPS` (writing `prediction.txt`); the *grade* comes from the probe +
the gating quiz — we grade the run and the concept, not the free-text prediction.

**DECODE labs: `check.sh` grades a learner extraction artifact** (a type name, a
member, a bypass list) — reading comprehension can't be re-derived by pwsh. Plus
the gating quiz.

### 2b. Grader hygiene rules (kit-wide — from the review)

- **Single-quote every literal pattern that contains `$`** so bash doesn't expand
  it: `assert_file_contains_fixed fixed.ps1 '$name'` — **never** `"$name"`
  (double quotes expand to empty → `grep -F ""` matches any non-empty file → an
  unconditional **false pass**). This bug was caught in L0.2.
- **Real `assert_output_contains` signature is `"desc" pattern "hint" -- cmd…`.**
  It runs a *command*, not a filename. `assert_output_contains greeting.txt "…"`
  is wrong (filename becomes the desc, no `-- cmd`, `$out` empty → always fails).
  Use `-- cat file` or `-- pwsh -NoProfile -NonInteractive -File probe.ps1`.
- **`assert_file_not_contains` passes vacuously on a missing file** — always
  precede it with `assert_file_exists` on the same path.
- **Fully-qualified .NET type literals use `assert_file_contains_fixed`** (grep
  `-F`), never the ERE helper — dots are wildcards
  (`System.Diagnostics.Process` would match `SystemXDiagnosticsXProcess`; and
  `System.DateTime` is a substring of `System.DateTimeOffset`, so grade the probe
  output which prints the exact type via `.GetType().FullName`).
- **Type names from `.GetType().Name` = `Int32`/`String`; from `Get-Member` =
  the accelerators `int`/`string`.** Grade whichever the probe actually prints;
  do not mix. (This false-fail was caught at the L1.8 gate.)
- **Free-text DECODE matches tolerate case/word-form** via the ERE helper, e.g.
  `[Ee]xecut(e|es|ing|ion)` — the grep helpers have no `-i`.
- **No `^`/`$` anchors on free text** (BOM/CRLF tolerance); anchors are for the
  numeric probe outputs `check.sh` itself produced.
- Standard set-e traps (kit-contracts): `n=$((n+1))` not `((n++))`;
  `IFS= read -r v || v=""`; guard `LAB_WORKSPACE`/`LAB_CHECKLIB` with `: "${V:?}"`.

### 2c. Attack-content ceiling (Phase 0/1)

Attack material is **name-only** — `Invoke-Expression`/`iex` and
`System.Net.WebClient` are *named* as dangerous and forward-referenced to L3.5;
never executed, never a live payload. Defang any URL/IP in prose (`hxxp`, `[.]`).
No `check.sh` ever calls `DownloadString`/`iex`.

---

## 3. PowerShell-specific decisions the map asked us to make

### 3a. PSScriptAnalyzer belongs in **L0.1** — DECIDED YES (with a caveat)

Map open-item §9 defers the call to the Phase Builder. **Decision: install + verify
it in L0.1**, mirroring ShellCheck in bash L0.1 — it is the closest thing to a
compiler PowerShell gives you, and Phase 7's CI-gate lab (L7.5) should be
*recognition*, not first contact. Cross-track hook: **bash L7.5**.

**Caveat the build must accept and document:** `Install-Module` requires **PSGallery
network egress**, so Phase 0 is not fully offline-completable — unlike bash's
ShellCheck (an apt package). L0.1's `lab.md` states the network requirement and an
**offline fallback**: `Save-Module PSScriptAnalyzer` on a connected host and copy
the module folder, or a distro/OS package where available. `check.sh` itself needs
no network (it greps a learner file artifact).

### 3b. Execution Policy honesty (L0.3) — the classification exercise

The map's Phase-0 exit gate: classify **Execution Policy bypass**, **AMSI**, and
**Constrained Language Mode** as *"real control"* or *"speed bump."* Settled key:

| Behavior | Classification | Why (taught nuance) |
|---|---|---|
| **Execution Policy** | **Speed bump** | Not a security boundary; Microsoft documents it as anti-*accidental-run* safety. Trivially bypassed: `-ExecutionPolicy Bypass`, `-EncodedCommand`, pipe-to-stdin (`Get-Content x.ps1 \| pwsh -Command -`), `IEX (Get-Content x.ps1 -Raw)`, `Set-ExecutionPolicy -Scope Process Bypass`. |
| **AMSI** | **Real control — bypassable, and a telemetry source** | A genuine runtime scan surface (script content → Defender/AV). Bypassable (in-memory patch, reflection, obfuscation), but defeating it costs the attacker *and is itself detectable*. **Answer phrasing must carry this nuance, not a flat "boundary."** |
| **CLM** | **Real control when enforced by WDAC/AppLocker** | Genuinely blocks `.NET` type access, COM, `Add-Type`. Bare (env-var only, no enforcement engine) it is bypassable; under WDAC/AppLocker it is a real boundary. |

Teaching point: **only EP is pure theater.** AMSI and CLM cost the attacker and
generate detection opportunity. This trio maps onto L0.3's 3-question gate quiz;
distractors must make *EP-as-real-control*, *AMSI-as-mere-speed-bump*, and
*CLM-real-on-its-own* the wrong answers.

---

## 4. Phase 0 — lab-by-lab build spec

### L0.1 — Install pwsh on WSL2; verify version; first command · GUIDED · est 20m

**Teaching artifact.** Guided tooling (a toolchain lab is legitimately multi-step):
install pwsh 7 via apt, verify the version table, run a first *object-returning*
command, install + verify PSScriptAnalyzer.

Install (graded path — apt/deb repo → `/usr/bin/pwsh`, on the check PATH):

```bash
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common
source /etc/os-release
wget -q "https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb
sudo apt-get update && sudo apt-get install -y powershell
pwsh --version          # → PowerShell 7.x.y     [VERIFY-AT-BUILD exact patch]
```

> **Do not use snap / dotnet-tool / Homebrew** — those install off the check
> harness PATH allowlist and the grader's `pwsh` call will fail. (State this in
> `lab.md` with a `pwsh --version` preflight so the learner catches it early.)

Verify + first command, inside `pwsh` — the learner writes deterministic artifacts:

```powershell
"{0} {1} {2}" -f $PSVersionTable.PSVersion, $PSVersionTable.PSEdition, $PSVersionTable.Platform > psversion.txt
# → e.g. "7.4.6 Core Unix"        [VERIFY-AT-BUILD exact version]
Get-Date                          # first command → System.DateTime (a live, locale-formatted timestamp — do NOT grade its text)
```

PSScriptAnalyzer (the PS "ShellCheck"; **network/PSGallery** — flagged):

```powershell
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted     # -InstallationPolicy is NOT positional
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
Get-Module -ListAvailable PSScriptAnalyzer | Select-Object -ExpandProperty Name > pssa.txt   # → "PSScriptAnalyzer" (deterministic, no table truncation)
'gci | ForEach-Object { $_ }' | Set-Content sample.ps1
Invoke-ScriptAnalyzer -Path sample.ps1 | Select-Object -ExpandProperty RuleName > findings.txt  # flawed sample → >=1 rule (e.g. PSAvoidUsingCmdletAliases)
```

**Environment note.** Clean on pwsh 7 (WSL2). **Network dependency** on
`Install-Module` (see §3a fallback). No Windows variant. The `>=7` / `PowerShell
7.` checks also pass on *Windows* PS7 — the **`Unix` / `Linux`** greps are what
pin the Linux build.

**check.sh grades** (pwsh-free except one bare `pwsh --version`; see §2a note):
- `assert_output_contains "pwsh is v7+ and on PATH" '^PowerShell 7\.' "install via the apt repo (step 1); snap/dotnet/brew are off the check PATH" -- pwsh --version` — the SC2016-safe replacement for the inline exit-code trick; also proves bare `pwsh` resolves (the apt gate).
- `assert_file_contains psversion.txt 'Core'` **and** `'Unix'` **and** `'7\.'`
  (learner-written file; `Unix`+`Linux` pin platform).
- `assert_file_contains_fixed pssa.txt "PSScriptAnalyzer"` — hint: "run the
  Install-Module step (needs network); see the offline fallback in the brief."
- `assert_file_exists findings.txt` (PSSA actually ran on the flawed sample; exact
  rule names are version-dependent → don't grep them).

**Quiz (3):**
1. *(choice)* `$PSVersionTable.PSEdition` on pwsh 7 reports? → **Core** (5.1 = Desktop).
2. *(text)* Cmdlet that installs a module from the PowerShell Gallery? → **Install-Module**.
3. *(choice)* PSScriptAnalyzer is the PowerShell equivalent of which Bash tool? → **ShellCheck**.

**Recap (3 lines):**
```
pwsh 7 is PSEdition Core, Platform Unix on WSL2; $PSVersionTable is your version truth
Install-Module pulls from PSGallery (needs network); PSScriptAnalyzer is your PS linter
PSScriptAnalyzer = ShellCheck for PowerShell — your compiler-substitute from day one
```

**recall.json:** none (first lab of the first phase).

---

### L0.2 — Meet the lab CLI — start, check, resume for the ps track · GUIDED · est 15m

**Teaching artifact.** The kit driving itself in the `ps` context (mirror of demo
`L0.0`), lightly PowerShell-flavored so it doubles as a first `pwsh -File` rep and
seeds L1.7's `$null` lesson.

`files/broken.ps1` (ships into the workspace):

```powershell
# broken.ps1 — greet the analyst
Write-Output "Hello, $naem"
```

Running it prints `Hello, ` — the typo `$naem` is an **unassigned variable →
`$null` → empty string** (default, non-strict mode; L1.7 opens this up). The learner
copies to `fixed.ps1`, removes the typo, and assigns the variable:

```powershell
$name = "analyst"
Write-Output "Hello, $name"
```

```powershell
pwsh -File fixed.ps1        # → "Hello, analyst"  (learner sees it live)
pwd > location.txt          # prove you're inside the fence
```

**Environment note.** Clean pwsh 7. No Windows variant. Both L0.2 and L1.7 assume
**default (non-strict) mode** so undefined-var → `$null` holds; `Set-StrictMode`
is *named* as the guard L1.7 discusses, never enabled here.

**check.sh grades** (runs the learner's `fixed.ps1` itself — defeats echo-cheat):
- `assert_file_exists fixed.ps1` (hint: `cp broken.ps1 fixed.ps1`).
- `assert_file_contains_fixed fixed.ps1 '$name'` — **single-quoted** literal.
- `assert_file_exists fixed.ps1` then `assert_file_not_contains fixed.ps1 '\$naem'`
  — forces the typo's removal (closes the partial-fix loophole).
- `assert_output_contains "fixed.ps1 greets the analyst" "Hello, analyst" "run: pwsh -File fixed.ps1" -- pwsh -NoProfile -NonInteractive -File fixed.ps1` — **unanchored** substring (BOM/whitespace tolerant); real 4-arg signature.
- location.txt written from inside the workspace (reuse the demo `L0.0`
  realpath-compare idiom verbatim).

**Quiz (3):**
1. *(choice)* Which command re-primes you after time away? → **`lab resume`**.
2. *(choice)* `lab start ps L0.2` refuses a lab past the frontier — what overrides
   it, at what cost? → **`--force`; skipped labs are marked `⏭` permanently**.
3. *(text)* Where does all `ps`-track lab work happen? (path, no trailing slash) →
   **`workspace/ps/L0.2`** (accept `workspace/ps/L0.2/`).

**Recap (3 lines):**
```
lab start / check / hint / resume work identically for ps as every track
all ps work lives in workspace/ps/<id>/ — the fence
a typo'd $var is silently $null → empty output (you'll meet this again in L1.7)
```

**recall.json:** none (not the phase opener).

---

### L0.3 — PS 5.1 vs PS 7 + Execution Policy honesty · DECODE · **GATE** · est 20m

**Teaching artifact (DECODE).** Two readings; **no live EP commands on the graded
path** (see environment note).

*(a) Edition/version reading* — a provided side-by-side the learner decodes:

| | PS 5.1 (Windows PowerShell) | PS 7 (PowerShell) |
|---|---|---|
| PSEdition | Desktop | Core |
| Runtime | .NET Framework 4.x | .NET (Core) |
| Platform | Windows only | Windows / Linux / macOS |
| Effective ExecutionPolicy | Restricted (client OS default) | Unrestricted / unenforced on non-Windows |
| Ships in-box | Yes (Windows) | No (install) |

*(b) Execution Policy honesty* — the learner reads an annotated bypass list (each a
documented, first-class technique) and extracts why EP is not a boundary:

```text
powershell.exe -ExecutionPolicy Bypass -File x.ps1     # flag overrides it
powershell.exe -EncodedCommand <base64-UTF16LE>        # encoded; policy N/A
Get-Content x.ps1 | powershell.exe -Command -          # pipe source to stdin
IEX (Get-Content x.ps1 -Raw)                           # read+eval; EP never consulted
Set-ExecutionPolicy -Scope Process Bypass              # per-process, no admin (Windows)
```

**The gate (map's Phase-0 exit gate)** = the 3-question quiz classifying EP / AMSI /
CLM per **§3b**.

**Environment note — `[WINDOWS-VARIANT]`.** EP, AMSI, and CLM are **Windows-only
runtime behaviors**. On the graded pwsh-7/WSL2 path, `Get-ExecutionPolicy` returns
**`Unrestricted`** (EP is *unenforced* off-Windows — itself the honest hook), and
**`Set-ExecutionPolicy` writes a non-terminating ERROR** — `Set-ExecutionPolicy:
Operation is not supported on this platform. (0x80131539)` — it does **not**
no-op or merely warn. `Set-ExecutionPolicy -Scope Process Bypass` therefore errors
on Linux; teach it as a Windows-context rep. `meta.json` gets
`"windows_variant": true`. The lab **teaches EP from provided evidence + the
classification quiz — it never depends on running EP/AMSI/CLM live.**
`[VERIFY-AT-BUILD]`: confirm whether pwsh-on-Linux even accepts the
`-ExecutionPolicy` startup parameter without erroring (treat as Windows-only if
not).

**check.sh grades** (extraction; complementary to the quiz — no double-count):
- `assert_file_exists bypasses.txt`, then a hand-rolled **≥3-of-4** threshold
  (set-e-safe: `n=$((n+1))`, `if grep …`), case/alias-insensitive, over
  `-ExecutionPolicy Bypass | -EncodedCommand/-enc | IEX/iex | Get-Content/gc`.
  The quiz owns *classification*; `bypasses.txt` owns the *bypass enumeration*.
- `assert_file_contains verdict.md '[Nn]ot a security boundary|[Ss]peed bump'`
  (the learner's one-line verdict on EP).

**Quiz (3) — the gate:**
1. *(choice)* Execution Policy = `Restricted`. Is it a security boundary? → **No —
   a speed bump; documented bypasses exist**. *(distractor: "yes, a real control")*
2. *(choice)* AMSI — control or speed bump? → **A real security control — a genuine
   scan surface and telemetry source (bypassable, but defeating it is detectable)**.
   *(distractor: "just a speed bump")*
3. *(choice)* CLM enforced by WDAC/AppLocker — control or speed bump? → **A real
   security control**. *(distractor: "real on its own, without an enforcement engine")*

**Recap (3 lines):**
```
PS 7 = Core / .NET / cross-platform; PS 5.1 = Desktop / .NET Framework / Windows-only
Execution Policy is NOT a boundary — a speed bump with documented bypasses
AMSI and CLM (with WDAC/AppLocker) ARE real controls — bypassable, but they cost attackers and log
```

**recall.json:** none (L0.3 is the gate, not the opener).

---

## 5. Phase 1 — lab-by-lab build spec

> Phase-1 spine: *cmdlets return .NET objects; the pipeline passes objects; screen
> text is only the default display.* Deterministic anchors are chosen so no two
> PREDICT labs share an answer, and every deterministic grade is produced by
> `check.sh` re-running a shipped probe (§2a).

### L1.1 — Cmdlets and the verb-noun pattern · DECODE · **Phase-1 opener** · est 15m

**Teaching artifact (DECODE).** Read cmdlet names as `Verb-Noun`, where the verb
signals the *side-effect class*.

```powershell
Get-Process                       # Get    → read-only
Get-ChildItem                     # Get    → read-only
Set-Location                      # Set    → changes state (cwd)
Invoke-Expression                 # Invoke → EXECUTES an arbitrary string  ⚠  (→ L3.5)
New-Object System.Net.WebClient   # New    → instantiates a .NET object
Get-Verb                          # lists the approved verbs
```

Mapping the learner extracts: **Get/Measure/Select/Test = read**;
**Set/New/Remove/Stop/Start = change/act**; **Invoke/Start = execute**.
`Invoke-Expression` is the flagged danger (foreshadows **L3.5** `iex`; cross-links
**bash L3.7** `eval`). *Do not* rely on `ls`→`Get-ChildItem` (a Windows-only alias).

**Environment note.** Clean pwsh 7.

**check.sh grades:** ship a fixed-format starter `files/decode.txt` (one row per
cmdlet: `Get-Process | Get | read`) the learner fills in, and grade per-token:
- `assert_file_exists verbs.txt`, then `assert_file_contains` for **several** real
  verbs — `Get`, `Set`, `Invoke`, `Remove`, `Stop`, `New` — so hand-faking is hard
  (learner: `Get-Verb | Select-Object -ExpandProperty Verb > verbs.txt`).
- `assert_file_contains decode.txt 'Invoke-Expression'` **and**
  `assert_file_contains decode.txt '[Ee]xecut(e|es|ing|ion)'` (case/word-tolerant).

**Quiz (3):**
1. *(text)* In `Stop-Service`, name the verb and the noun. → **verb Stop, noun Service**.
2. *(text)* Which cmdlet lists all approved verbs? → **Get-Verb**.
3. *(choice)* A line begins with `Invoke-`. What does that verb class signal? →
   **it executes/runs something (a side effect, not read-only)**.

**Recap (3 lines):**
```
PS cmdlets are Verb-Noun; the verb signals the side-effect class
Get- is read-only; Set-/Remove-/Stop- change state; Invoke-/Start- execute
Get-Verb lists the approved verbs — verb literacy = reading side effects at a glance
```

**recall.json (L1.1 — 5 Qs, all sourced from Phase 0):**
1. `source: ps L0.1` — PSEdition pwsh 7 reports? → **Core**.
2. `source: ps L0.1` — PSScriptAnalyzer is the PS equivalent of which Bash tool? → **ShellCheck**.
3. `source: ps L0.3` — Is Execution Policy a security boundary? → **No — a speed bump**.
4. `source: ps L0.3` — AMSI: control or speed bump? → **A real control — bypassable,
   but a genuine scan surface + telemetry** *(phrasing aligned to L0.3's taught
   nuance; the flat "boundary" answer is a distractor)*.
5. `source: ps L0.2` — Where does all `ps`-track lab work happen? → **`workspace/ps/<id>/`**.

---

### L1.2 — Objects, not text · PREDICT · est 20m

**The signature lab.** Predict the *type* out of two superficially-similar lines.

```powershell
# A) filter the OBJECTS by property — the object survives
Get-Process | Where-Object { $_.ProcessName -eq 'pwsh' }
#   Get-Process → [System.Diagnostics.Process] stream; Where-Object → same objects, filtered
#   display      → the default process table   [VERIFY-AT-BUILD columns/values]

# B) filter the TEXT (the Bash reflex)
Get-Process | grep pwsh
#   objects are rendered to the default table TEXT; STRINGS pipe to external grep
#   → matching text lines [String] — lossy, positional, breaks on 15-char /proc/comm truncation
```

**Predict:** out of **A** flows a `System.Diagnostics.Process` object (you can still
do `| Select-Object Id`); out of **B** flows **text** (the object is gone). *Note
the spiral:* `Where-Object` (full treatment L1.5) and `Select-Object` (L1.4) appear
here only as the *contrast to grep* and the *object-survival proof* — used as black
boxes, **not graded on those cmdlets**. The graded fact is the object type.

**Environment note.** Clean pwsh 7 — Linux `grep` *existing* is the point: the Bash
reflex "works" but on the wrong thing (the text shadow). `Get-Process pwsh`
self-matches (the lab runs inside pwsh); `/proc/<pid>/comm` truncates to 15 chars,
`pwsh` (4) fits. Minor `[WINDOWS-VARIANT]`: 5.1 has no `grep` (`Select-String`).

**check.sh grades** (runs a shipped probe — no learner-authored Where/Select needed):
- ship `files/type.ps1`: `@(Get-Process -Name pwsh)[0].GetType().FullName`.
- `assert_output_contains "Get-Process emits Process objects" "System.Diagnostics.Process" "run: pwsh -File type.ps1 (the probe)" -- pwsh -NoProfile -NonInteractive -File type.ps1` — **fixed** substring via the command's output.
- `assert_file_exists prediction.txt` (learner engaged with the predict step).

**Quiz (3):**
1. *(text)* What .NET type does `Get-Process` emit per row? → **System.Diagnostics.Process**.
2. *(choice)* Why does `| Where-Object { $_.WS -gt 100MB }` work but grep can't filter
   that way? → **Where-Object filters live objects by property; grep sees only the
   text projection**.
3. *(choice)* `Get-Process | grep pwsh` — what reaches grep's stdin? → **text
   (strings), the formatted display — not objects**.

**Recap (3 lines):**
```
PS pipelines pass .NET OBJECTS; the screen text is just the default display
Where-Object filters objects by property; grep filters the lossy text projection
reach for grep in PS and you're filtering the shadow, not the object
```

---

### L1.3 — `Get-Member` · DECODE · est 15m

**Teaching artifact (DECODE).** `| Get-Member` (gm) is the single most useful
reading tool: **TypeName** first, then Properties and Methods.

```powershell
Get-Process pwsh | Get-Member
#   (output opens with a blank line, then 3-space-indented "   TypeName: System.Diagnostics.Process", blank, then the table)
#   Name          MemberType      Definition          ← column order is Name, MemberType, Definition
#   Id            Property        int Id {get;}
#   ProcessName   Property        string ProcessName {get;}
#   WS            AliasProperty   WS = WorkingSet64    ← NOT a plain Property (PowerShell ETS alias)
#   Kill          Method          void Kill(), void Kill(bool entireProcessTree)
#   ...                                                 [VERIFY-AT-BUILD full member list]

(Get-Date) | Get-Member          # TypeName: System.DateTime → Year/Month/Day (Property), AddDays()/ToString() (Method)
```

DECODE moment (from the review): the display columns `Handles NPM PM WS VM` are
**AliasProperty**, `CPU/Path/SI` are **ScriptProperty** — both added by PowerShell's
extended type system (cross-platform), *not* raw .NET properties. `Id` and
`ProcessName` are the real instance Properties. An object's **methods are its
verbs** — `Process.Kill()`, `WebClient.DownloadString()`.

**Environment note.** Clean pwsh 7 (member set is cross-platform).

**check.sh grades** (learner extraction; no anchors — leading blank line):
- `assert_file_contains_fixed members.txt "System.Diagnostics.Process"` **and**
  `assert_file_contains members.txt 'Method'` **and** `'Property'` (learner:
  `Get-Process pwsh | Get-Member | Out-String > members.txt`).
- `assert_file_contains_fixed decode.txt "System.DateTime"` (learner records the
  `Get-Date` TypeName; `[VERIFY-AT-BUILD]`: DateTimeOffset near-miss — prefer
  grading the full TypeName line or a probe if flakiness appears).

**Quiz (3):**
1. *(choice)* The first line of `Get-Member` output always tells you what? → **the
   TypeName (.NET type)**.
2. *(text)* Name two `MemberType` kinds `Get-Member` groups by. → **Property,
   Method** (also AliasProperty, ScriptProperty, Event…).
3. *(choice)* You hit an unfamiliar object in a script — which cmdlet reveals its
   type and methods? → **Get-Member**.

**Recap (3 lines):**
```
| Get-Member (gm) reveals any object's TypeName, properties, and methods
the TypeName line tells you exactly which .NET type you're holding
reading unfamiliar PS = pipe it to Get-Member and see what it really is
```

---

### L1.4 — `Select-Object` and properties · PREDICT · est 20m

**Teaching artifact (PREDICT).** `Select-Object` *projects* which properties flow
onward; `-ExpandProperty` *unwraps* to the raw value type.

```powershell
Get-Process | Select-Object -First 3 Name, Id, WS                 # A) 3-col table, 3 rows
Get-Process -Name pwsh | Select-Object -First 1 -ExpandProperty Id  # B) a bare Int32 (no header)
Get-Process | Select-Object -First 2 Name, @{Name='MB';Expression={[math]::Round($_.WS/1MB,1)}}  # C) columns Name, MB
```

**Predict + settled facts:** **B** yields a bare **`Int32`**; **A** yields a
*selection* object whose **`.GetType().Name` is `PSCustomObject`** (both PS7 and
5.1) — the ETS name `Selected.System.Diagnostics.Process` comes only from
`Get-Member`/`$obj.PSObject.TypeNames[0]`, **not** from `GetType()`. Teach both.
`-ExpandProperty` is how attackers pull clean value lists for exfil.

**Environment note.** Clean pwsh 7. `1MB` literal + `[math]::Round` are introduced
here (the calc-property is this lab's named objective — so it is graded).

**check.sh grades** (shipped probes → encoding/culture under the harness):
- ship `files/expand.ps1`: `Get-Process -Name pwsh | Select-Object -First 1 -ExpandProperty Id`.
  `assert_output_contains "ExpandProperty unwraps to a bare Int32" '^[0-9]+$' "run: pwsh -File expand.ps1" -- pwsh -NoProfile -NonInteractive -File expand.ps1`, and (belt) a probe emitting `.GetType().Name` → `assert_output_contains … "Int32" … -- pwsh … -File itype.ps1`.
- ship `files/calc.ps1` emitting the calc-property (header + one value):
  `assert_output_contains "calculated property adds an MB column" "MB" … -- pwsh … -File calc.ps1` (grade the objective, not just ExpandProperty).
- resolve the type identity: ship `files/seltype.ps1`:
  `(Get-Process | Select-Object -First 1 Name,Id).GetType().Name` →
  `assert_output_contains … "PSCustomObject" … -- pwsh … -File seltype.ps1`.

**Quiz (3):**
1. *(choice)* `Select-Object Name,Id` vs `Select-Object -ExpandProperty Name` —
   output type difference? → **first: an object with Name+Id; second: the bare
   underlying value (String/Int32)**.
2. *(choice)* `(… | Select-Object Name,Id).GetType().Name` returns? → **PSCustomObject**
   *(distractor: Selected.System.Diagnostics.Process — that's the PSTypeNames value)*.
3. *(text)* How do you add a computed column? → **a calculated-property hashtable
   `@{Name='X';Expression={…}}`**.

**Recap (3 lines):**
```
Select-Object projects/limits which properties flow onward
-ExpandProperty unwraps to the raw underlying value (String, Int32, …)
a projection's GetType() is PSCustomObject; calc props @{Name=;Expression={}} add columns
```

---

### L1.5 — `Where-Object` · PREDICT · est 15m

**Teaching artifact (PREDICT).** Filter the stream; type is preserved (pure filter —
emits the original objects unchanged).

```powershell
Get-Process | Where-Object { $_.WS -gt 50MB }     # subset of [Process] (count varies)
Get-Process | Where-Object Id -gt 1               # simplified comparison syntax
1..10 | Where-Object { $_ % 2 -eq 0 }             # DETERMINISTIC → 2 4 6 8 10  (one per line)
```

**Deterministic anchor** (unique to this lab): **2, 4, 6, 8, 10**, `[Int32]`.
Operators `-gt -lt -eq -ne -ge -le -like -match`; `$_` = current object (`$PSItem`).

**Environment note.** Clean pwsh 7.

**check.sh grades** (shipped probe → exact output by construction):
- ship `files/evens.ps1`: `1..10 | Where-Object { $_ % 2 -eq 0 }`.
- `assert_output_contains` on `-- pwsh -NoProfile -NonInteractive -File evens.ps1`
  for each of `^2$ ^4$ ^6$ ^8$ ^10$` (single asserts), plus one that the odds are
  absent — since `check.sh` runs the probe, a "dump-all" false-pass is impossible.

**Quiz (3):**
1. *(text)* `1..10 | Where-Object { $_ % 2 -eq 0 }` → output? → **2 4 6 8 10**.
2. *(choice)* Does `Where-Object` change the object type flowing through? → **No —
   it filters; type is preserved**.
3. *(text)* What does `$_` refer to inside the filter? → **the current pipeline
   object (alias `$PSItem`)**.

**Recap (3 lines):**
```
Where-Object filters the stream by a boolean test; the type is preserved
$_ (or $PSItem) is the current object; operators are -gt -eq -like -match ...
1..10 | Where-Object {$_ % 2 -eq 0} → 2 4 6 8 10
```

---

### L1.6 — `ForEach-Object` and `$_` / `$PSItem` · PREDICT · est 15m

**Teaching artifact (PREDICT).** The block runs once per object; compute or call
methods on each.

```powershell
1..3 | ForEach-Object { $_ * $_ }                     # DETERMINISTIC → 1 4 9
'a','bb','ccc' | ForEach-Object { $_.Length }         # DETERMINISTIC → 1 2 3
Get-Process | ForEach-Object { $_.ProcessName } | Select-Object -First 3  # up-to-3 names [VERIFY]
```

**Deterministic anchors** (unique): squares **1, 4, 9**; lengths **1, 2, 3**.
Contrast L1.5: **Where filters; ForEach transforms/acts** (math, `.ToUpper()`,
`.Kill()`). `$PSItem` is the long form of `$_`.

**Environment note.** Clean pwsh 7.

**check.sh grades** (shipped probes):
- ship `files/squares.ps1` (`1..3 | ForEach-Object { $_ * $_ }`) →
  `assert_output_contains … -- pwsh … -File squares.ps1` for `^1$ ^4$ ^9$`.
- ship `files/lengths.ps1` (`'a','bb','ccc' | ForEach-Object { $_.Length }`) →
  for `^1$ ^2$ ^3$`.

**Quiz (3):**
1. *(text)* `1..3 | ForEach-Object { $_ * $_ }` → ? → **1 4 9**.
2. *(choice)* Difference between `Where-Object` and `ForEach-Object`? → **Where
   filters (keep/drop); ForEach runs an action/transform on each**.
3. *(text)* The long alias for `$_`? → **`$PSItem`**.

**Recap (3 lines):**
```
ForEach-Object runs its block once per pipeline object; $_ / $PSItem is each item
Where-Object filters; ForEach-Object transforms or acts (math, methods)
1..3 | ForEach-Object {$_*$_} → 1 4 9
```

---

### L1.7 — Variables, typing, and `$null` · DECODE · est 20m

**Teaching artifact (DECODE).** PS variables are dynamically typed (type follows the
value); an unassigned variable is silently `$null`; `$null` interpolates as empty —
the L0.2 bug, opened up.

```powershell
$x = 5
$x = "now a string"     # type follows the value — no error
$y                       # never assigned → $null
"value: $y"             # → "value: "   (empty interpolation)  ← the silent bug
$null -eq $z            # → True   (null on the LEFT — best practice)
@($null).Count          # → 1      (array wrapper → 1 element)
($null).Count           # → 0      (PS7 unified-Count)     [VERIFY-AT-BUILD version-scoped]
[int]$n = "42"          # coerced → Int32 42
[int]$bad = "notanumber"   # → RuntimeException  [VERIFY-AT-BUILD exact text; .NET-version-dependent]
```

Key reads: unassigned/typo'd → `$null` → empty string (L0.2 callback);
`[type]$var` constrains/coerces; **compare with `$null` on the left** because
`$x -eq $null` filters element-wise if `$x` is an array. `[int]$bad="notanumber"`
is the DECODE-with-error moment (default, non-strict mode assumed — consistent
with L0.2).

**Environment note.** Clean pwsh 7.

**check.sh grades** (shipped probes for the deterministic facts; extraction for the
comprehension):
- ship `files/interp.ps1` (`$y = $null; "value:[$y]"`) →
  `assert_output_contains "empty interpolation" "value:[]" … -- pwsh … -File interp.ps1`.
- ship `files/ntype.ps1` (`[int]$n = "42"; $n.GetType().Name`) →
  `assert_output_contains … "Int32" … -- pwsh … -File ntype.ps1`.
- `assert_file_exists decode.txt` then `assert_file_contains decode.txt '[Nn]ull'`
  (learner's one-line explanation of why `"value: $y"` is empty).

**Quiz (3):**
1. *(text)* You reference `$user` but never assigned it — its value, and how does
   `"hi $user"` render? → **`$null`; renders "hi " (empty)**.
2. *(choice)* Why write `$null -eq $x` not `$x -eq $null`? → **if `$x` is an array,
   `$x -eq $null` filters element-wise; null on the left forces a scalar compare**.
3. *(text)* What does `[int]$n = "42"` do? → **constrains/coerces `$n` to Int32
   (42); a non-numeric string throws a conversion error**.

**Recap (3 lines):**
```
PS variables are dynamically typed — the type follows the last value assigned
an unassigned/typo'd variable is $null and interpolates as empty (silent bug)
compare with $null -eq $x (null on the left) to dodge the array-filtering trap
```

---

### L1.8 — Phase gate: five pipelines · PREDICT · **GATE** · est 25m

**Teaching artifact (PREDICT — the integrative gate).** Five pipelines; for each,
name **(1) input object type, (2) operation, (3) output**. Chosen to exercise
L1.1–L1.7 with two fully deterministic graders.

| # | pipeline | input type | operation | output |
|---|----------|-----------|-----------|--------|
| 1 | `Get-Process \| Where-Object { $_.WS -gt 100MB } \| Select-Object Name, Id` | `System.Diagnostics.Process` | filter by working set, project 2 props | selection objects `Name,Id` `[VERIFY rows]` |
| 2 | `1..5 \| ForEach-Object { $_ * 10 }` | `Int32` | ×10 each | **10 20 30 40 50** (deterministic) |
| 3 | `Get-ChildItem \| Where-Object { -not $_.PSIsContainer } \| Select-Object -ExpandProperty Name` | `System.IO.FileSystemInfo` | keep non-dirs, unwrap Name | bare filenames `[String]` — **unordered on Linux** |
| 4 | `'chrome','pwsh','sshd' \| ForEach-Object { $_.ToUpper() }` | `String` | uppercase each | **CHROME PWSH SSHD** (deterministic) |
| 5 | `Get-Process \| Select-Object -First 1 \| Get-Member -MemberType Method` | `System.Diagnostics.Process` | take one, list methods | method rows (`Kill`, `Start`, …) |

Pipeline 3 needs a **seeded `files/` tree** (its output is workspace-dependent) and
`Get-ChildItem` order is **not guaranteed on Linux** — so it is **not** a graded
capture; grade set membership or `Sort-Object` only if ever used. `PSIsContainer` is
provided cross-platform by the FileSystem provider (`$true` dirs / `$false` files).

**check.sh grades** (shipped probes for the two deterministic pipelines; the 3/3
quiz is the true gate):
- ship `files/p2.ps1` (`1..5 | ForEach-Object { $_ * 10 }`) →
  `assert_output_contains … -- pwsh … -File p2.ps1` for `^10$ ^20$ ^30$ ^40$ ^50$`.
- ship `files/p4.ps1` (`'chrome','pwsh','sshd' | ForEach-Object { $_.ToUpper() }`) →
  `assert_output_contains … "CHROME" / "PWSH" / "SSHD"` (fixed).
- `assert_file_exists answers.md`, then `assert_file_contains_fixed answers.md
  "System.Diagnostics.Process"` (grep `-F`; the ERE helper's dots would wildcard).
  Treat `answers.md` as *engagement* — it is keyword-stuffable, so the **quiz is the
  gate**.

**Quiz (3) — the gate** (forces the type calls that answers.md can't):
1. *(text)* `1..5 | ForEach-Object { $_ * 10 }` → output? → **10 20 30 40 50**.
2. *(choice)* Pipeline 1 — what TYPE enters the `Where-Object` stage? →
   **System.Diagnostics.Process**.
3. *(choice)* In pipeline 1's `Select-Object Name, Id`, what are the types of `Id`
   vs `Name`? → **`Id` is Int32, `Name` is String** *(distractors mix them or say
   "both String")* — the type-accelerator false-fail is avoided by grading the
   concept in the quiz, not `int`/`string` text from Get-Member.

**Recap (3 lines):**
```
every PS pipeline = objects in → filter / project / transform → objects out
name the input type (Get-Member), the operation (Where/Select/ForEach), the output
you can now read any PS pipeline as data flow, not text
```

**recall.json:** none on L1.8. **Build deliverable (Phase Builder step 6): draft
L2.1's `recall.json` now** — 5 Qs spanning Phase 0 **and** 1:
1. `source: ps L1.2` — Does a PS pipeline pass text or objects? → **objects**.
2. `source: ps L1.3` — Which cmdlet reveals an object's TypeName and methods? → **Get-Member**.
3. `source: ps L1.5` — `1..10 | Where-Object { $_ % 2 -eq 0 }` → ? → **2 4 6 8 10**.
4. `source: ps L0.3` — Execution Policy: boundary or speed bump? → **speed bump**.
5. `source: ps L1.4` — What does `Select-Object -ExpandProperty` do? → **unwraps to
   the bare underlying value**.

---

## 6. Build order, self-test, phase-close (Phase Builder protocol)

1. Scaffold `tracks/ps/track.json` + `tracks/ps/phases/p0`, `p1`.
2. Build **lab by lab in id order** (L0.1 → L1.8). Commit each after its self-test:
   `ps <id>: <title>`.
3. **Self-test every lab (no-fiction rule):** run every `lab.md` command in real
   pwsh 7; paste REAL output, resolving every `[VERIFY-AT-BUILD]` (§8). Run
   `check.sh` twice — wrong/incomplete work (fails with a useful hint) and correct
   (passes). Trim any `lab.md` > ~180 lines or > ~15 commands.
4. **shellcheck-zero + lint:** every `check.sh` passes `tools/shellcheck-all.sh`
   **and** `tools/lint-labs.sh` (no absolute paths, no banned tokens, **no `$` in a
   `pwsh -Command` — use `-File`**). Ship every probe `.ps1` in the lab's `files/`.
5. **Gates:** L0.3 + L1.8 carry `gate:true`; verify `quiz_run` requires 3/3.
6. **Recall:** L1.1's `recall.json` ships now; L2.1's is drafted now (§5, L1.8).
7. **Close out:** `lab status` renders both phases; `lab resume` works mid-phase;
   update `planned_execution.md` (`ps p0`, `ps p1` → done + evidence); tag `ps-p0`
   and `ps-p1`; report against the checklist below. The map bundles 0+1 for the
   first `ps` build (otherwise one phase per session).

**Phase Acceptance Checklist (report each):** lab count/titles/types match the map
(3 + 8); every lab self-tested (real outputs pasted, fail + pass paths run);
shellcheck + lint clean; both gates present + integrative; L1.1 recall ships +
L2.1 recall drafted; `lab status`/`resume` correct; `planned_execution.md` updated;
phases tagged `ps-p0`, `ps-p1`.

---

## 7. Verification summary (12-agent adversarial pass — corrections already folded in)

Verdict **fix-then-go** for both phases; all labs feasible/risky, none infeasible.
Corrections now baked into §2–§5:

- **Grader architecture:** `check.sh` grades deterministic labs by re-running a
  shipped `pwsh -File probe.ps1` (SC2016-safe, echo-cheat-proof, encoding-safe) —
  §2a. DECODE labs grade learner extraction files.
- **Two grader bugs fixed (L0.2):** single-quote `'$name'` (double-quoted `"$name"`
  → bash-expands to empty → `grep -F ""` → unconditional pass); use the real
  `assert_output_contains "desc" pat "hint" -- cmd` form; add
  `assert_file_not_contains '\$naem'` after an `assert_file_exists`.
- **SC2016 (L0.1):** replaced the inline `-Command '…$PSVersionTable…'` with
  `pwsh --version` + `assert_output_contains '^PowerShell 7\.'`.
- **Five PowerShell facts corrected:** `Set-ExecutionPolicy` on Linux **errors**
  (not no-op/warn) — L0.3; `Set-PSRepository -Name … -InstallationPolicy Trusted`
  (not positional) — L0.1; `Get-Member` column order is **Name, MemberType,
  Definition** and **`WS` is an AliasProperty** — L1.3; a `Select-Object` projection's
  `GetType().Name` is **`PSCustomObject`** — L1.4; `Get-Member` prints type
  **accelerators `int`/`string`** (not `Int32`/`String`) — L1.8 grades the concept
  in the quiz instead.
- **One-concept inversion (L1.2)** resolved: L1.2 grades only the object-*type* fact
  (shipped `type.ps1`); `Where-Object`/`Select-Object` appear as taught-later black
  boxes, not graded here.
- **Kit-wide hygiene** (§2b): `assert_file_exists` before every
  `assert_file_not_contains`; `assert_file_contains_fixed` for every .NET type
  literal; case/word-tolerant ERE for free-text DECODE markers.
- **L0.3 gate** de-duplicated (quiz owns classification, `bypasses.txt` owns
  enumeration) with a set-e-safe ≥3-of-4 threshold; **L1.1 AMSI recall** answer
  aligned to L0.3's "real-but-bypassable + telemetry" nuance.

---

## 8. Open `[VERIFY-AT-BUILD]` items (must be confirmed against real pwsh 7.4)

| lab | item |
|---|---|
| L0.1 | exact `pwsh --version` / `$PSVersionTable` version text; that apt→`/usr/bin/pwsh` resolves as bare `pwsh` under the check PATH; PSSA exact rule names (don't grep) |
| L0.2 | exact bytes of `pwsh -File` output (reasoned UTF-8/LF, `"Hello, analyst"`) — grader uses unanchored substring, safe either way |
| L0.3 | exact `Set-ExecutionPolicy` error string; whether pwsh-on-Linux accepts the `-ExecutionPolicy` startup param without erroring |
| L1.2 | `Get-Process` default table columns/values; `.GetType().FullName` = `System.Diagnostics.Process` |
| L1.3 | full `Get-Member` member list + the leading blank line; `System.DateTime` vs `System.DateTimeOffset` near-miss (grade full line if flaky) |
| L1.4 | `(Select-Object Name,Id).GetType().Name` = `PSCustomObject`; `-ExpandProperty Id` = bare Int32; `MB` calc-column value format under `LANG=C.UTF-8` |
| L1.7 | `($null).Count → 0` (PS7 version-scoped); exact `[int]$bad="notanumber"` error text (.NET-version-dependent) |
| L1.8 | `PSIsContainer` on the Linux FileSystem provider; seeded `files/` tree for pipeline 3; `Get-ChildItem` unordered on Linux (never grade ordered lines) |

---

*Plan v2 (verification folded in) — awaiting review. PLAN ONLY; nothing built,
nothing committed.*
