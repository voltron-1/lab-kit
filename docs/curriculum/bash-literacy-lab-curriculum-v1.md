# BASH LITERACY LAB — Curriculum Map v1.0

**Read. Audit. Harden. Direct.**
A terminal-based Bash comprehension course for security work.

---

## 1. The Premise

Same goal as the Rust track — you are training to be a **reader and auditor** who directs AI, not a script author. But Bash is a different animal, and the course reflects it:

- **You already use Bash daily.** Security Onion installers, runbooks, CI scripts, git hooks, Docker entrypoints, cron. This isn't a new language — it's the one that already bites you. That makes every lab immediately relevant.
- **Bash has zero safety net.** Rust rejects unsafe code at compile time. Bash runs it, silently, and hopes for the best. An unquoted variable, an empty `$DIR` in `rm -rf "$DIR/"`, a stray `eval` — Bash will not warn you. **The compiler that Rust gave you for free, you have to *become*.**
- **Bash's signature vulnerability is injection, not memory corruption.** Untrusted data flowing into a command string is the shell equivalent of a buffer overflow. Most of the security phase lives here.

Four skills, in order:

1. **Expansion literacy** — read any line and know exactly what words the shell will actually run
2. **Footgun recognition** — spot the quoting, splitting, and silent-failure traps on sight
3. **Injection & script auditing** — read a `curl | bash` installer or a suspicious script and judge whether it's safe to run
4. **AI direction** — write specs that produce *hardened* Bash, and review the output (AI writes Bash badly by default)

You will type in labs — but only enough to make it stick. Every lab is built around code that already exists: predict it, decode it, fix it, harden it, or audit it.

---

## 2. How It Works (RedHat Academy Mechanics)

Identical machinery to the Rust track. Clone into WSL2 on Dragon-Zord, everything in the terminal.

### The `lab` CLI

| Command | What it does |
|---|---|
| `lab status` | Phase map with ✓ marks — your progress bar |
| `lab start L2.3` | Opens the lab: prints the brief, sets up files |
| `lab check L2.3` | Grades the lab (runs checks + quiz). Pass = next lab unlocked |
| `lab resume` | **Interruption recovery.** Where you stopped, last recap, context re-primed in under 30 seconds |
| `lab hint L2.3` | Graduated hints (3 levels, never the full answer first) |

### Anatomy of Every Lab

1. **OBJECTIVE** — one sentence. What you can do after.
2. **BRIEF** — ≤10 lines of context. No external reading, ever.
3. **GUIDED STEPS** — terminal follow-along with expected output shown.
4. **KNOWLEDGE CHECK** — 3 active-recall questions, graded by `lab check`.
5. **RECAP CARD** — 3-line summary written to your progress log (this is what `lab resume` replays).

Progress lives in `.progress.json`. Nothing is lost mid-session. Ever.

**ShellCheck is installed in Phase 0 and used from that point on.** In the Rust course, Clippy was a late-phase tool. Here, ShellCheck is your co-pilot from the start — because Bash itself tells you nothing, ShellCheck is the closest thing to a compiler you get, and reading its warnings *is* a core literacy skill.

---

## 3. Lab Types

Mostly shared with Rust, plus one new type built for Bash's specific danger model.

| Type | What you do | Skill trained |
|---|---|---|
| **PREDICT** | Read a line/script, predict *exactly what runs* before executing | Expansion literacy |
| **DECODE** | Working script + "what does this do and why?" | Comprehension |
| **FIX** | A *broken* script — read the misbehavior, apply the minimal fix | Debugging |
| **TAME** | A *working but dangerous* script — harden it (quote, strict-mode, de-inject) | **The safety reflex** |
| **AUDIT** | Find the security flaw — injection, unquoted var, privilege, race | Security review |
| **TOUR** | Guided walkthrough of a real production script | Codebase navigation |
| **DIRECT** | Write a spec for AI, then grade the output against a checklist | Your actual workflow |
| **GUIDED** | Straight follow-along (tooling) | Environment ops |

**TAME is the type that doesn't exist in the Rust course.** In Rust, dangerous code usually doesn't compile. In Bash, the dangerous code *works* — it just detonates later. Taking a working-but-unsafe script and hardening it is a distinct, central skill.

---

## 4. ADHD Design Contract

Unchanged from the Rust track — same commitments, honored every lab.

- **Atomic:** every lab completes in 10–20 minutes. "Varies wildly" sessions are the design target.
- **One concept per lab.** Never two.
- **Hard checkpoint every lab.** `lab check` passing = a real, saved win.
- **Re-entry in 30 seconds.** `lab resume` reorients you after a day or a month.
- **Hint ladder, not stuck-spirals.** Three graduated hints before frustration.
- **Zero prerequisite reading.** Everything you need is in the lab brief.
- **Spaced recall.** The first lab of every phase opens with a 5-question quiz pulling from *earlier* phases.

---

## 5. Phase Map (Overview)

| Phase | Name | Labs | After this phase you can… |
|---|---|---|---|
| **0** | Toolchain & Kit | 3 | Run the kit; tell bash/sh/dash apart from a shebang |
| **1** | The Expansion Model | 8 | Predict exactly what words any line runs |
| **2** | Control Flow & Silent Failure | 8 | Read any script's logic; explain why `set -euo pipefail` exists |
| **3** | The Footgun Gallery | 9 | Spot every classic Bash trap on sight |
| **4** | Untrusted Input & Injection | 8 | Audit a `curl \| bash` installer; triage suspicious shell |
| **5** | Text Processing & Pipelines | 6 | Read grep/sed/awk/jq log pipelines fluently |
| **6** | Reading Real Deploy Scripts | 5 | Tour installers, entrypoints, systemd, CI cold |
| **7** | Directing & Auditing AI Bash | 7 | Spec, review, and CI-gate AI-generated Bash. Capstone. |

**54 labs total.** No schedule, no deadlines — a chain of checkpoints. The progress bar waits for you.

---

## 6. Phase Detail

### Phase 0 — Toolchain & Kit
*Get the environment, the kit, and ShellCheck working. Plumbing.*

| Lab | Title | Type |
|---|---|---|
| L0.1 | Shells and the kit — which shell am I in, install ShellCheck & shfmt | GUIDED |
| L0.2 | Meet the lab CLI — start, check, resume | GUIDED |
| L0.3 | Reading the shebang — `#!/bin/bash` vs `#!/bin/sh` vs dash, and why it matters | DECODE |

**Exit gate:** given any script, you can say what interpreter it targets and whether bash-only features will break under `/bin/sh`.

**Why L0.3 first:** Security Onion runs scripts under different shells; Alpine containers use BusyBox `sh`; Debian/Ubuntu `/bin/sh` is dash, not bash. A script that works in your terminal can fail in a container for this reason alone. Shebang literacy is a real reading skill from day one.

---

### Phase 1 — The Expansion Model
*The single mental model that unlocks Bash: everything is text, and the shell transforms that text through a fixed sequence of expansions before it runs anything. Almost every Bash bug is a misunderstanding of this sequence.*

| Lab | Title | Type |
|---|---|---|
| L1.1 | Commands are just words — the shell splits, then runs | PREDICT |
| L1.2 | Variables — `$VAR`, `${VAR}`, and when braces matter | PREDICT |
| L1.3 | **The unquoted variable** — word splitting, the #1 Bash bug | PREDICT |
| L1.4 | Quoting — single vs double vs none, decided by what you want expanded | PREDICT |
| L1.5 | Globbing — `*` `?` `[...]` and pathname expansion | PREDICT |
| L1.6 | Exit codes — `$?`, and "success" is 0 (backwards from every language you know) | DECODE |
| L1.7 | Command substitution — `$(...)` and reading nested commands | PREDICT |
| L1.8 | **Phase gate:** predict the output of an expansion-heavy script, line by line | PREDICT |

**Security hook:** L1.3 is introduced *early and deliberately*. The unquoted variable is where word-splitting bugs become security bugs — a filename with a space, a newline, or a leading dash silently changes what command runs. You'll meet it here and hunt it for the rest of the course.

---

### Phase 2 — Control Flow & Silent Failure
*Bash control flow is genuinely weird (`[ ]` vs `[[ ]]` vs `(( ))`), and its default failure behavior is a security problem: a script whose middle command fails but that keeps running and reports success has done the wrong thing, quietly.*

| Lab | Title | Type |
|---|---|---|
| L2.1 | `if` and test — `[ ]` vs `[[ ]]` vs `(( ))`, and which to trust | DECODE |
| L2.2 | **The strict-mode preamble** — `set -euo pipefail` and what each flag stops | DECODE |
| L2.3 | Loops — `for`, `while`, and the correct way to read a file line by line | PREDICT |
| L2.4 | `&&` and `\|\|` — short-circuit logic and the `cmd \|\| exit` idiom | PREDICT |
| L2.5 | `case` statements | DECODE |
| L2.6 | Functions — `local`, and `return` (a code) vs `echo` (a value) | DECODE |
| L2.7 | `trap` — cleanup on exit, and why installers use it | DECODE |
| L2.8 | **Phase gate:** a script that fails silently — trace it, find where it lied | FIX |

**Security hook:** L2.2 is the most important lab in the phase. Every hardened script you'll ever read opens with `set -euo pipefail` (or should). Understanding *why* — fail on error, fail on undefined variable, fail on broken pipe — is the difference between "the script ran" and "the script did what it claimed."

---

### Phase 3 — The Footgun Gallery
*This phase has no Rust equivalent. It is a guided tour of the specific, famous ways Bash detonates. Every lab is a real bug class you will see in the wild.*

| Lab | Title | Type |
|---|---|---|
| L3.1 | Word splitting, deep — the classic bugs and their quoted fixes | TAME |
| L3.2 | **`rm -rf "$DIR/"`** — the empty-variable catastrophe | AUDIT |
| L3.3 | `IFS` — what it controls and how changing it breaks (or attacks) a script | DECODE |
| L3.4 | Filenames as attack surface — files named `-rf`, `--`, or with newlines | AUDIT |
| L3.5 | Arithmetic — `(( ))` and the injection people forget it allows | AUDIT |
| L3.6 | Subshells vs current shell — why `... \| while read` eats your variables | PREDICT |
| L3.7 | **`eval`** — why it's almost always the wrong answer | AUDIT |
| L3.8 | ShellCheck as co-pilot — reading SC codes, and which ones are security-critical | GUIDED |
| L3.9 | **Phase gate:** one script, every footgun — find and harden them all | TAME |

**Security hook:** the entire phase. L3.2 alone has wiped production systems (the empty-variable `rm -rf` is a genuine outage classic). L3.8 formalizes ShellCheck as your reviewer — by the end you'll know which warnings are cosmetic and which mean "this is exploitable."

---

### Phase 4 — Untrusted Input & Injection
*The security phase — the Bash analog of Rust's unsafe/FFI chapter. Command injection (CWE-78) is Bash's signature vulnerability: the moment untrusted data touches a command string, you have a potential shell. This is also where you learn to audit the scripts you're handed.*

| Lab | Title | Type |
|---|---|---|
| L4.1 | Command injection — how untrusted data becomes executed code (CWE-78) | AUDIT |
| L4.2 | **The `curl \| bash` audit** — reading an installer *before* you pipe it to a shell | AUDIT |
| L4.3 | Argument injection and the `--` end-of-options guard (CWE-88) | AUDIT |
| L4.4 | Environment attacks — `PATH`, `IFS`, and untrusted search paths (CWE-426) | AUDIT |
| L4.5 | Reading obfuscated shell — `base64 \| bash`, hex, and malware-triage basics | AUDIT |
| L4.6 | Handling untrusted input *correctly* — the safe patterns | DECODE |
| L4.7 | Temp files done right — `mktemp` and TOCTOU races (CWE-367) | TAME |
| L4.8 | **Phase gate:** audit a realistic malicious installer end to end | AUDIT |

**Security hook:** L4.2 and L4.5 are the labs that pay off in your actual job. Auditing a `curl | bash` one-liner before running it, and recognizing an obfuscated malware dropper for what it is, are daily security tasks — and both are pure reading skills.

---

### Phase 5 — Text Processing & Pipelines
*The reading skills for the log-wrangling tools that SOC scripts are built from. You don't need to write awk — you need to read the pipeline someone (or an AI) already wrote.*

| Lab | Title | Type |
|---|---|---|
| L5.1 | Pipelines and the core tools — `grep`, `cut`, `sort`, `uniq`, `wc` | DECODE |
| L5.2 | `sed` at reading level — substitution and the patterns you'll actually meet | DECODE |
| L5.3 | `awk` at reading level — the tool that looks like magic, demystified | PREDICT |
| L5.4 | `jq` — reading JSON pipelines (ECS / log territory you already live in) | DECODE |
| L5.5 | Process substitution `<(...)`, here-docs, and here-strings | DECODE |
| L5.6 | **Phase gate:** decode a real log-processing pipeline top to bottom | DECODE |

**Security hook:** L5.4 ties straight to your pipeline work — reading a `jq` filter that reshapes log JSON into ECS format is exactly the kind of glue code you'll be reviewing and directing.

---

### Phase 6 — Reading Real Deploy Scripts
*TOUR phase — production shell, no toy code. These are the script archetypes you meet in your own stack.*

| Lab | Title | Type |
|---|---|---|
| L6.1 | Tour: a Security Onion–style installer/runbook script — the `so-*` pattern | TOUR |
| L6.2 | Tour: a Docker `entrypoint.sh` — the container-startup idioms | TOUR |
| L6.3 | Tour: a systemd unit + its `ExecStart` script | TOUR |
| L6.4 | Tour: a CI pipeline script — what the runner actually executes | TOUR |
| L6.5 | **Phase gate:** solo tour of an unseen deploy script, answer questions cold | TOUR |

**Why these:** every one of these is something you already depend on in CARDINAL/Security Onion. By the end you can open an installer or entrypoint you've never seen and explain what it does and where it's risky.

---

### Phase 7 — Directing & Auditing AI-Generated Bash
*Your workflow, formalized. AI writes Bash **badly by default** — unquoted variables, no strict mode, no error handling, cheerful `eval`. Expert level here means your specs force safe output, and nothing sloppy gets past your review.*

| Lab | Title | Type |
|---|---|---|
| L7.1 | Why AI Bash is dangerous by default — the recurring failure patterns | AUDIT |
| L7.2 | The safe-Bash spec — strict mode, quoting, and *shellcheck-clean as acceptance criteria* | DIRECT |
| L7.3 | The AI-Bash review checklist v1 | AUDIT |
| L7.4 | Review reps — 3 AI-generated scripts, find every flaw | AUDIT |
| L7.5 | CI guardrails — ShellCheck + shfmt as a merge gate | GUIDED |
| L7.6 | **Capstone:** direct + audit a SOC-relevant script (log-ingest / deploy helper) | DIRECT |
| L7.7 | **Capstone gate:** ship a hardened, shellcheck-clean script | AUDIT |

**Why this capstone:** a log-ingest or deployment helper is directly usable in your Security Onion pipeline work — and building it by *directing and auditing* AI, rather than hand-writing it, is a rehearsal of exactly how you'll operate. The course ends with a real artifact and a review checklist you keep.

---

## 7. Delivery Plan

Built **one phase at a time**, same as the Rust track. Each delivery is interruption-safe.

1. **You approve this map** (edits welcome — labs can be added, cut, or reordered).
2. **First build ships Phase 0 + Phase 1 together** — Phase 0 is 3 plumbing labs, Phase 1 is unusable without it. Delivered as a zip: working `lab` CLI, all check scripts, all lab content. Unzip into WSL2, run `lab status`.
3. **Each later phase ships as a drop-in folder** + one command to register it. Your progress file is never touched.
4. Between phases, anything can be adjusted based on what worked.

The `lab` CLI and check harness are **shared with the Rust track** — if you've already got the Rust kit installed, the Bash phases can register into the same tooling, and `lab status` shows both tracks. (If you build Bash first, the reverse holds.)

---

## 8. Open Items for Your Review

- **Name:** `bash-literacy-lab` is a working title. Rename freely.
- **Tour targets (Phase 6):** Security Onion installer + Docker entrypoint + systemd + CI is the current pick. Swappable — could add a git hook, a cron wrapper, or one of your own runbook scripts (sanitized).
- **Capstone (L7.6–7.7):** log-ingest / deploy helper is the current pick. Alternatives: a `curl | bash` installer *auditor*, a log-triage one-shot, or a Sigma-rule deploy wrapper.
- **Depth on `sed`/`awk` (Phase 5):** currently reading-level only. Say the word if you want a deeper awk lab — it's the one tool where "write a little" genuinely helps reading.

---

*v1.0 — awaiting approval before Phase 0+1 build.*
