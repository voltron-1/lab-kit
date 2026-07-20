# RUST TRACK — Phase 7 Build Plan (v1): Directing & Auditing AI-Generated Rust

Binding content spec: `docs/curriculum/rust-literacy-lab-curriculum-v1.md` (Phase 7
section). Binding mechanical spec: `docs/kit-contracts.md`. Format precedent:
`docs/plans/rust-p01-plan.md`; conventions continued from the p2–p6 plans §3.
Reference implementation of every file format:
`tracks/demo/phases/p0/L0.0-meet-the-kit/`.
This plan is the single source of design judgment for the build session — build it
mechanically; where reality contradicts a claim marked `[VERIFY-AT-BUILD]`, fix the
content to match reality and note the deviation in the build report.

**This is the capstone phase.** It formalizes the learner's actual workflow:
write specs that produce safe Rust, and review AI output like a lead architect. The
whole course converges here — every red flag from Phases 3–5 becomes a review
checklist item, and the course ends with a **real, runnable artifact**: an IOC/log
parser that emits ECS-formatted JSON, directly usable in SOC pipeline work.

Three framing rules carry forward from Phase 4 and apply to every AI-output exhibit
in this phase:
- **No weaponized payloads** — planted flaws in "AI-generated" snippets are
  patterns to identify; nothing ships a live exploit or performs a malicious
  effect.
- **No runnable undefined behavior** — memory-unsafe flaws are read-only exhibits.
- **AI output is a read-only exhibit** — the harness has no live model; every "AI
  draft" (L7.3, L7.6) is a pre-authored exhibit with planted flaws, graded by
  reading. The DIRECT skill (writing the spec/direction) is graded by the presence
  of the constraints that matter (see §3 grading note).

Planning-context note: at plan time NOTHING in the rust track is built. L7.1's
recall questions are sourced from the **curriculum map's lab lists** for Phases
0–6 (the whole course, interleaved), all `[VERIFY-AT-BUILD]`.

## 1. Lab list (from the map, exactly)

| id | title (meta.json `title`) | type | gate | est_minutes | dir slug |
|---|---|---|---|---|---|
| L7.1 | Spec-writing for safe Rust — constraints that actually matter | DIRECT | false | 15 | `L7.1-spec-writing` |
| L7.2 | The AI-Rust review checklist v1 | AUDIT | false | 15 | `L7.2-review-checklist` |
| L7.3 | Review reps — 3 AI-generated snippets, find every flaw | AUDIT | false | 20 | `L7.3-review-reps` |
| L7.4 | CI guardrails — clippy pedantic + audit + deny + tests as spec | GUIDED | false | 15 | `L7.4-ci-guardrails` |
| L7.5 | Capstone spec — an IOC/log parser emitting ECS-formatted JSON | DIRECT | false | 20 | `L7.5-capstone-spec` |
| L7.6 | Capstone build — direct the AI, review each iteration | DIRECT | false | 25 | `L7.6-capstone-build` |
| L7.7 | Capstone gate: final audit and ship | AUDIT | **true** | 25 | `L7.7-capstone-gate` |

Gate placement: the map marks L7.7 explicitly; it is the course finale.
recall.json placement: **L7.1 only** (5 questions, drawn from across Phases 0–6 —
the widest interleave in the course).

Capstone rationale (map §8): a log parser emitting ECS JSON is directly usable in
the learner's SOC pipeline work — the course ends with a real artifact, not a
certificate. L7.5→L7.6→L7.7 is one continuous thread: spec it, direct/review the
build, audit and ship.

## 2. Binding harness constraints (the relevant subset)

check.sh never runs cargo/rustc/clippy/AI (env -i fence + no live model); all
grading artifact-based and CI-fabricatable without a toolchain; lint bans as
listed; quiz.json exactly 3 / hints.json exactly 3 levels / recap.md exactly 3
lines / lab.md exact headings; answers base64, text answers lowercase-normalized
with `accept_b64` variants; quiz stdin one line per question; recall non-gating at
`lab start` on the opener only.

**GUIDED/DIRECT tool steps (L7.4, L7.7):** as in L4.8/L4.9/L5.5, the learner runs
`cargo clippy`/`cargo audit`/`cargo deny`/`cargo run` in their OWN shell and
redirects output to a file; check.sh grades the redirected artifact plus
answers.txt with marker greps a fabricated echo also satisfies. check.sh never
invokes the tools.

## 3. Track conventions (carried + Phase-7 additions)

Carried: `answers.txt` `key=value` grading (options in lab.md; anchored ERE or
`assert_file_contains_fixed`); quiz-vs-answers non-duplication; hints ladder;
**ERE discipline — ALL metacharacters escaped in assert patterns**; descs/hints
keep apostrophes out; read-only-exhibit handling (banner + never compiled) as in
L4.2/L5.7/L6.x; CWE tokens graded exactly per the p4 convention.

New for Phase 7:
- **DIRECT grading note (honest, stated in each DIRECT lab.md).** The harness
  cannot grade prose quality or run an AI. A DIRECT lab grades two things: (1) a
  **structured "which constraints matter" answer** (an exact multi-select set in
  answers.txt, with distractors — this tests whether the learner KNOWS what to
  specify), and (2) a learner-written **deliverable file** (`spec.md`,
  `direction.md`) checked for the PRESENCE of the load-bearing elements via grep.
  The BRIEF says plainly: "the check confirms your spec names the constraints that
  matter; it cannot grade the prose — that rep is yours." This is a rubric, the
  best offline proxy for a DIRECT skill.
- **Multi-select answer format.** Where a lab asks "which of these matter," the
  learner writes a sorted, comma-separated, no-spaces set of letters (the L1.5
  `q2=port,tls` precedent), e.g. `essential=a,c,d,f`. check.sh greps the exact set
  with `assert_file_contains_fixed`.
- **The capstone dependency (L7.6 exhibits, L7.7 artifact): serde + serde_json.**
  Like tokio in Phase 5, this is an explicit contract-level deviation flagged here:
  the ECS-JSON capstone uses serde/serde_json (the realistic SOC-pipeline choice —
  correct JSON escaping for free, which is itself an audit point vs hand-rolled
  JSON). Fetched in the LEARNER shell only (L7.7's `cargo run`); check.sh never
  runs cargo. L7.1–L7.5 need no dependency (spec/checklist/exhibit work); L7.6's
  drafts are read-only serde-based exhibits (never compiled); only L7.7's final
  artifact is a runnable cargo project. Version `[VERIFY-AT-BUILD]`.
- **ECS field set.** The capstone emits a fixed subset of Elastic Common Schema
  fields: `@timestamp`, `event.dataset`, `event.action`, `event.outcome`,
  `source.ip`, `user.name`, `message`. `[VERIFY-AT-BUILD: confirm these are
  current ECS field names and decide dotted-key vs nested-object emission per the
  ECS spec; keep the check greps aligned to whatever form is shipped.]`

## 4. Lab entries

---

### L7.1 — Spec-writing for safe Rust — constraints that actually matter
**DIRECT · gate:false · est 15 · files/: task.md (the spec assignment) · recall.json: YES (phase opener)**
**objective:** "Given a task, identify the constraints that actually matter for safe Rust — failure behavior, not just the happy path — and write a spec that names them."

**recall.json — 5 questions, sourced from the curriculum map's Phase 0–6 lab
lists (the whole course). ALL FIVE `[VERIFY-AT-BUILD]`.**
1. choice (source: "rust L4.7 — what Rust does NOT stop") — "Memory-safe Rust can
   still have…" a) use-after-free b) path traversal, injection, and logic bugs
   c) data races → **b**
2. choice (source: "rust L3.2 — unwrap red flags") — "`unwrap()` on untrusted
   input is a…" a) style nit b) denial-of-service risk c) memory-corruption bug
   → **b**
3. choice (source: "rust L2.1 — move semantics") — "After `let b = a;` on a
   String, `a` is…" a) still usable b) moved — compile-time dead c) null → **b**
4. choice (source: "rust L5.7 — async DoS") — "An awaited read with no timeout
   is…" a) fine b) an unbounded-await DoS (CWE-400) c) a compile error → **b**
5. choice (source: "rust L4.4 — as truncation") — "A narrowing `as` before a size
   check…" a) is safe b) can defeat the check by truncating the value first
   c) is rejected by the compiler → **b**

**files/task.md:** the assignment — "Spec a function `parse_port(input: &str)`
that turns a CLI string into a validated TCP port. Below are eight candidate
constraints (a–h). Decide which are ESSENTIAL for safe Rust, then write a short
spec.md that names them." The eight candidates (printed in task.md AND lab.md):
- a) return a `Result` or `Option` so failure is a value, not a panic
- b) make it run as fast as possible
- c) reject ports outside `1..=65535`
- d) never `unwrap`/`expect`/panic on the input string
- e) convert with `as u16`
- f) reject non-numeric input with a clear error
- g) cache results in a mutable global
- h) add colored terminal output
Essential set (answer key): **a, c, d, f.** (b/h are noise; e is the anti-pattern
from L4.4 — narrowing `as` instead of a checked parse; g is a bad global.)

**GUIDED STEPS outline:** read task.md → decide the essential set → write
`essential=a,c,d,f` in answers.txt (sorted, comma-separated, no spaces) → write
`spec.md` naming those constraints in prose (must mention, in any wording:
returning a Result/Option, rejecting out-of-range ports, no panic on input,
rejecting non-numeric) → check. Honor framing (DIRECT grading note) restated in
BRIEF.

**CHECK LOGIC:** `assert_file_contains_fixed answers.txt 'essential=a,c,d,f'`;
`assert_file_exists spec.md`;
`assert_file_contains spec.md 'Result|Option'` (hint: the spec must say failure is
a returned value) — the `|` here is a real ERE alternation, intended;
`assert_file_contains spec.md '1\.\.=65535|range|1-65535'` (dots escaped — the
spec must name the valid range) `[VERIFY-AT-BUILD: confirm the ERE matches common
phrasings; broaden accept patterns if learners phrase the range differently]`;
`assert_file_contains spec.md 'panic|unwrap'` (must address not panicking on
input); `ck_summary`.
(CI fabrication: echo `essential=a,c,d,f`; echo a spec.md containing "returns a
Result", "reject ports outside 1..=65535", "never unwrap/panic on input", "reject
non-numeric".)

**QUIZ:**
1. choice — "A good spec for safe Rust constrains…" a) only the happy path
   b) the FAILURE behavior — what happens on bad input, where errors go, what
   cannot panic c) only performance → **b**
2. choice — "Which candidate is an anti-pattern to EXCLUDE from the spec?"
   a) return a Result b) convert with `as u16` (silent truncation — use a checked
   parse) c) reject out-of-range ports → **b**
3. text — "The single most important thing a safe-Rust spec adds beyond the happy
   path: how the function ___ on bad input." → **fails** (accept: `errors`,
   `handles errors`, `behaves`)

**RECAP:**
```
a spec that produces safe Rust constrains failure behavior, not just the happy path
name the load-bearing four: return Result, validate range, no panic on input, reject junk
exclude the anti-patterns — `as` truncation, unwrap-on-input, mutable globals — on purpose
```

**HINTS:** L1: the grader wants `essential=` (a sorted letter set) plus a spec.md
naming those constraints. L2: the essential ones are about failure behavior —
return a Result, validate the range, do not panic on input, reject non-numeric;
`as u16` (e) is the L4.4 anti-pattern, and b/g/h are noise. L3: write
`essential=a,c,d,f` and a spec.md that says, in your own words, "returns a Result,
rejects ports outside 1..=65535, never panics on input, rejects non-numeric
input."

---

### L7.2 — The AI-Rust review checklist v1
**AUDIT · gate:false · est 15 · files/: redflags.md (the flag catalog)**
**objective:** "Assemble your reusable AI-Rust review checklist by sorting every course red flag into its category — the artifact you apply for the rest of the phase."

**files/redflags.md:** eight red flags a reviewer looks for in AI-generated Rust,
each to be categorized. The four categories (printed in lab.md): **memory-safety**,
**availability**, **input-validation**, **supply-chain**. The flags + answer key:
1. `unwrap()` on request/input data → **availability** (panic → DoS, L3.2/L4.5)
2. an `unsafe` block with no `// SAFETY` comment → **memory-safety** (L4.1/L4.2)
3. `len as u16` on an input-derived length → **input-validation** (truncation,
   L4.4)
4. `Path::new(base).join(user_input)` with no containment → **input-validation**
   (path traversal, L4.7)
5. `tokio::spawn` in an unbounded accept loop → **availability** (resource
   exhaustion, L5.7)
6. a dependency flagged by a RUSTSEC advisory → **supply-chain** (L4.8)
7. a shell command built by string interpolation of input → **input-validation**
   (injection, L4.7)
8. a raw pointer dereference / `from_raw_parts` with an unchecked length →
   **memory-safety** (L4.2)

**GUIDED STEPS outline:** read redflags.md → categorize each flag in answers.txt
(`rf1=..rf8=`, each = one of the four category words, lowercase) → write
`checklist.md` — a reusable checklist with at least one concrete check line per
category (the deliverable) → check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^rf1=availability$'`,
`'^rf2=memory-safety$'`, `'^rf3=input-validation$'`, `'^rf4=input-validation$'`,
`'^rf5=availability$'`, `'^rf6=supply-chain$'`, `'^rf7=input-validation$'`,
`'^rf8=memory-safety$'`;
`assert_file_exists checklist.md`;
`assert_file_contains checklist.md 'memory-safety|unsafe|SAFETY'`;
`assert_file_contains checklist.md 'availability|panic|unwrap|timeout'`;
`assert_file_contains checklist.md 'input|validation|traversal|injection'`;
`assert_file_contains checklist.md 'supply-chain|audit|RUSTSEC'`; `ck_summary`.
(CI fabrication: echo the eight rf lines; echo a checklist.md with one line per
category naming the keywords.)

**QUIZ:**
1. choice — "The four categories of an AI-Rust review checklist are…"
   a) speed, size, style, syntax b) memory-safety, availability,
   input-validation, supply-chain c) tests, docs, CI, license → **b**
2. choice — "`unwrap()` on input and an unbounded `tokio::spawn` loop are both…"
   a) memory-safety issues b) availability issues — different mechanisms, same
   category (the process stops serving) c) supply-chain issues → **b**
3. text — "A raw-pointer deref with an unchecked length belongs in which category
   (one word)?" → **memory-safety** (accept: `memory safety`, `memory`)

**RECAP:**
```
the review checklist has four lanes: memory-safety, availability, input-validation, supply-chain
every course red flag sorts into one — unwrap/spawn = availability, unsafe/raw ptr = memory-safety
build it once, apply it to every AI diff — this is the artifact the rest of the phase uses
```

**HINTS:** L1: eight rf keys plus a checklist.md — the grader names each miss;
the four category words are printed in lab.md. L2: panic/DoS flags (unwrap,
unbounded spawn) are availability; unsafe/raw-pointer flags are memory-safety;
truncation/traversal/injection are input-validation; the advisory flag is
supply-chain. L3: assign each flag its category word, then write a checklist.md
with a line per category mentioning its keywords.

---

### L7.3 — Review reps — 3 AI-generated snippets, find every flaw
**AUDIT · gate:false · est 20 · files/: snippet1.rs, snippet2.rs, snippet3.rs (READ-ONLY exhibits)**
**objective:** "Apply the checklist for real: audit three AI-generated snippets cold and name every planted flaw by category and CWE."

**files/ — three READ-ONLY exhibits (banner: do not compile; audit by reading;
framing rules apply — flaws are patterns, no weaponized payloads). Each snippet is
plausible AI-generated Rust with exactly two planted flaws:**

**snippet1.rs** — a config reader:
```rust
// snippet1.rs — READ-ONLY EXHIBIT. Audit it. (AI-generated; two flaws.)
use std::fs;
fn load_max_conns(path: &str) -> u16 {
    let text = fs::read_to_string(path).unwrap();   // FLAW 1: unwrap on I/O
    let raw: u32 = text.trim().parse().unwrap();     //         (+ parse) — DoS
    raw as u16                                        // FLAW 2: as truncation
}
```
Flaws: FLAW 1 = unwrap on I/O + parse (availability / panic-DoS, CWE-248); FLAW 2 =
`raw as u16` truncation of an input-derived value (input-validation, CWE-197).

**snippet2.rs** — a file fetcher:
```rust
// snippet2.rs — READ-ONLY EXHIBIT. Audit it. (AI-generated; two flaws.)
use std::path::Path;
use std::process::Command;
fn fetch(base: &str, name: &str) -> String {
    let p = Path::new(base).join(name);               // FLAW 1: no containment
    let out = Command::new("sh").arg("-c")
        .arg(format!("cat {}", p.display()))          // FLAW 2: shell-string build
        .output().unwrap();
    String::from_utf8_lossy(&out.stdout).to_string()
}
```
Flaws: FLAW 1 = `join(name)` with no containment (input-validation / path
traversal, CWE-22); FLAW 2 = shell command built by string interpolation
(input-validation / command injection, CWE-78). (This exhibit shows the vulnerable
PATTERN for identification — the lab never runs it; framing rule.)

**snippet3.rs** — an async accept loop:
```rust
// snippet3.rs — READ-ONLY EXHIBIT. Audit it. (AI-generated; two flaws.)
async fn serve(listener: TcpListener) {
    loop {
        let (conn, _) = listener.accept().await.unwrap();  // FLAW 1: unwrap in loop
        tokio::spawn(async move {                           // FLAW 2: unbounded spawn
            handle(conn).await;
        });
    }
}
```
Flaws: FLAW 1 = `unwrap()` on accept in the loop (availability, CWE-248 — one bad
accept kills the server); FLAW 2 = unbounded `tokio::spawn` per connection
(availability / resource exhaustion, CWE-400).

**GUIDED STEPS outline:** read all three (nothing compiles — lab.md says so) → for
each snippet, name its two flaws' categories and CWEs in answers.txt → check.
answers.txt keys (categories use the L7.2 four-word set; CWE tokens per the p4
convention, formats printed in lab.md):
- snippet 1: `s1a=availability`, `s1cwe=CWE-248`, `s1b=input-validation`,
  `s1trunc=CWE-197`
- snippet 2: `s2a=input-validation`, `s2trav=CWE-22`, `s2b=input-validation`,
  `s2inj=CWE-78`
- snippet 3: `s3a=availability`, `s3panic=CWE-248`, `s3b=availability`,
  `s3exh=CWE-400`

**CHECK LOGIC:** anchored greps for the category keys
(`'^s1a=availability$'`, `'^s1b=input-validation$'`, `'^s2a=input-validation$'`,
`'^s2b=input-validation$'`, `'^s3a=availability$'`, `'^s3b=availability$'`);
fixed-string greps for the CWE tokens (`assert_file_contains_fixed answers.txt
's1cwe=CWE-248'`, `'s1trunc=CWE-197'`, `'s2trav=CWE-22'`, `'s2inj=CWE-78'`,
`'s3panic=CWE-248'`, `'s3exh=CWE-400'`); `ck_summary`.
(Pure-reading lab: answers.txt only, no binaries. CI fabrication: echo all keys.)

**QUIZ:**
1. choice — "snippet2 builds a shell string from `name`. The fix is…" a) escape
   the quotes b) never build a shell line — pass an argument vector (no `sh -c`)
   c) validate the length → **b**
2. choice — "Two different snippets share CWE-248 (uncaught panic). That tells
   you…" a) they are identical b) the same flaw class (unwrap on a path that bad
   input/errors reach) recurs — that is why it is a checklist item c) nothing →
   **b**
3. text — "snippet3's unbounded `tokio::spawn` is which CWE (format CWE-###)?" →
   **cwe-400** (accept: `400`, `cwe 400`)

**RECAP:**
```
apply the checklist cold: each AI snippet hid two flaws across the four categories
recurring classes — unwrap-DoS (CWE-248), truncation (197), traversal (22), injection (78), exhaustion (400)
the fixes are the same ones the course taught: Result, try_from, containment, arg-vector, a cap
```

**HINTS:** L1: each snippet has two flaws — twelve keys total (category + CWE per
flaw); the grader names each miss; the CWE formats are in lab.md. L2: snippet1 is
unwrap-DoS + `as` truncation; snippet2 is traversal + injection (both
input-validation); snippet3 is unwrap-in-loop + unbounded spawn (both
availability). L3: match each `// FLAW` comment to its category (L7.2's four) and
its CWE — 248 panic, 197 truncation, 22 traversal, 78 injection, 400 exhaustion.

---

### L7.4 — CI guardrails — clippy pedantic + audit + deny + tests as spec
**GUIDED · gate:false · est 15 · files/: none (learner writes the guardrail script)**
**objective:** "Stand up the four automated gates that catch AI-Rust regressions — clippy pedantic, cargo audit, cargo deny, cargo test — and understand what each does and does NOT catch."

**GUIDED STEPS outline (learner shell; tools run there, never in check.sh):**
1. Write `guardrails.sh` — the four gate commands, one per line (lab.md gives the
   canonical forms): `cargo clippy -- -W clippy::pedantic -D warnings`,
   `cargo audit`, `cargo deny check`, `cargo test`. (lab.md: `cargo deny` and
   `cargo audit` may need one-time `cargo install`; network in the learner shell,
   as in L4.8.)
2. Optionally run them against any cargo project the learner has (e.g. Phase-5's
   async_demo) and redirect a combined transcript:
   `bash guardrails.sh > ../ci_out.txt 2>&1 || true` (`|| true` — a gate failing
   is a normal outcome to observe).
3. Answer in answers.txt (options in lab.md):
   - g1 (choice) "tests as spec" means: a) tests are optional b) tests encode the
     spec's invariants as executable checks — the spec you can run in CI c) tests
     replace review → `g1=b`
   - g2 (choice) which gate catches a known-vulnerable dependency? a) clippy
     b) cargo audit (RUSTSEC) c) cargo test → `g2=b`
   - g3 (choice) which gate enforces policy (licenses, banned/duplicate crates)?
     a) cargo deny b) clippy c) cargo test → `g3=a`
   - g4 (choice) `-D warnings` on clippy does: a) nothing b) turns warnings into
     hard errors — the gate FAILS CI on any lint, so regressions can't merge
     c) disables lints → `g4=b`
   - g5 (choice) what do NONE of these four gates catch? a) a known CVE b) a logic
     bug like L4.7's inverted access check — intent is invisible to tools; human
     review still required c) a style lint → `g5=b`
4. `lab check rust L7.4`.

**CHECK LOGIC:** `assert_file_contains answers.txt '^g1=b$'`, `'^g2=b$'`,
`'^g3=a$'`, `'^g4=b$'`, `'^g5=b$'`;
`assert_file_exists guardrails.sh`;
`assert_file_contains guardrails.sh 'clippy'`;
`assert_file_contains guardrails.sh 'audit'`;
`assert_file_contains guardrails.sh 'deny'`;
`assert_file_contains guardrails.sh 'test'`; `ck_summary`.
(Note: `guardrails.sh` is a learner DELIVERABLE in the workspace, NOT a committed
check.sh — it is never linted/shellchecked by repo tooling, so its `cargo`/tool
tokens are fine. CI fabrication: echo the five answers; echo a guardrails.sh
containing the four command lines.)

**QUIZ:**
1. choice — "The four AI-Rust CI gates are…" a) fmt, build, run, deploy
   b) clippy (pedantic, -D warnings), cargo audit, cargo deny, cargo test
   c) lint, docs, bench, publish → **b**
2. choice — "'Tests as spec' captures the idea that…" a) tests are documentation
   b) the spec's invariants become executable assertions that fail CI when
   violated c) tests are for coverage numbers → **b**
3. text — "The gate that turns clippy warnings into build-failing errors uses the
   `-D` flag on which word?" → **warnings**

**RECAP:**
```
four gates: clippy pedantic -D warnings, cargo audit, cargo deny, cargo test
audit catches known CVEs, deny enforces policy, clippy -D warnings blocks lint regressions
none catch logic bugs — CI gates are necessary, not sufficient; human review still ships
```

**HINTS:** L1: five answer keys plus a guardrails.sh naming the four gates. L2:
audit = advisories, deny = policy, clippy -D = fail-on-lint, test = spec-as-code;
g5 is the logic-bug blind spot (L4.7). L3: write guardrails.sh with the four
`cargo ...` lines from step 1, then answer which gate does what.

---

### L7.5 — Capstone spec — an IOC/log parser emitting ECS-formatted JSON
**DIRECT · gate:false · est 20 · files/: sample.log, ecs-fields.md (reference)**
**objective:** "Write the full spec for the capstone: an IOC/log parser that turns raw log lines into ECS-formatted JSON, with the failure and safety constraints named."

**files/sample.log (the input format the spec targets):**
```
2026-07-20T10:15:00Z sshd FAILED user=root src=203.0.113.9
2026-07-20T10:15:04Z sshd OK user=deploy src=198.51.100.7
2026-07-20T10:15:09Z sudo FAILED user=www-data src=203.0.113.9
```
**files/ecs-fields.md:** the required ECS output fields + meanings (given so the
learner specs to a real schema): `@timestamp`, `event.dataset` (e.g. sshd/sudo),
`event.action` (login-attempt), `event.outcome` (success/failure from OK/FAILED),
`user.name`, `source.ip`, `message` (the raw line). `[VERIFY-AT-BUILD: confirm ECS
field names/forms.]`

**GUIDED STEPS outline:** read sample.log + ecs-fields.md → decide the essential
spec constraints (candidates a–h in lab.md; essential set is the answer) → write
`spec.md` (the deliverable) covering: input line format, the seven ECS output
fields, error handling (malformed line → skip-and-count or Result, NEVER panic),
and safety constraints (bounded line length, no unwrap on input, escape/serialize
JSON correctly rather than hand-concatenate) → check.
Candidate constraints (a–h; essential = **a,b,d,f,g**):
- a) emit the seven required ECS fields [ESSENTIAL]
- b) map OK/FAILED to `event.outcome` success/failure [ESSENTIAL]
- c) make it multithreaded [noise]
- d) a malformed line is skipped/counted, never panics the run [ESSENTIAL]
- e) parse with `unwrap()` for brevity [ANTI-PATTERN]
- f) never `unwrap`/panic on a log line's contents [ESSENTIAL]
- g) serialize JSON with a library (correct escaping), not string concatenation
  [ESSENTIAL]
- h) print in color [noise]

**CHECK LOGIC:** `assert_file_contains_fixed answers.txt 'essential=a,b,d,f,g'`;
`assert_file_exists spec.md`;
`assert_file_contains_fixed spec.md '@timestamp'` (the spec must name the ECS
fields);
`assert_file_contains_fixed spec.md 'event.outcome'`;
`assert_file_contains spec.md 'panic|unwrap'` (must address not panicking on a
line);
`assert_file_contains spec.md 'malformed|skip|invalid'` (must define the
bad-line policy); `ck_summary`.
(CI fabrication: echo the essential set; echo a spec.md naming @timestamp,
event.outcome, the no-panic policy, and the malformed-line handling.)

**QUIZ:**
1. choice — "The spec's rule for a malformed log line should be…" a) unwrap and
   crash b) skip it (and count it), never panic — one bad line must not stop the
   pipeline c) guess the fields → **b**
2. choice — "Emit JSON with a library rather than string concatenation because…"
   a) it is shorter b) the library escapes correctly — hand-built JSON risks
   malformed output / injection when field values contain quotes or control
   chars c) it is required by Rust → **b**
3. text — "The schema the capstone emits (three letters)." → **ecs**

**RECAP:**
```
a capstone spec names outputs (7 ECS fields), the OK/FAILED->outcome mapping, and failure policy
the failure policy is the point: a malformed line is skipped and counted, never a panic
serialize JSON with a library — correct escaping is safety, not convenience
```

**HINTS:** L1: the grader wants `essential=` (a letter set) plus a spec.md naming
the ECS fields and the failure policy. L2: essential = emit the fields (a), map
outcome (b), skip malformed lines (d), no panic on input (f), library JSON (g);
`unwrap for brevity` (e) is the anti-pattern, c/h are noise. L3: write
`essential=a,b,d,f,g` and a spec.md that names @timestamp/event.outcome, "skip and
count malformed lines", "never unwrap/panic on a line", "serialize with serde_json".

---

### L7.6 — Capstone build — direct the AI, review each iteration
**DIRECT · gate:false · est 25 · files/: draft_v1.rs (READ-ONLY AI draft, flawed)**
**objective:** "Direct the build like a lead: audit the AI's first-draft ECS parser against your checklist, then write the exact corrections that turn draft v1 into a shippable v2."

**files/draft_v1.rs (READ-ONLY EXHIBIT — a plausible AI first draft of the ECS
parser with planted flaws; banner: do not compile, audit and direct; serde-based
so it LOOKS real, never compiled here):**
```rust
// draft_v1.rs — READ-ONLY EXHIBIT. The AI's first attempt at the L7.5 spec.
// Audit it against your checklist, then write the corrections in direction.md.
use serde_json::json;
fn to_ecs(line: &str) -> String {
    let parts: Vec<&str> = line.split(' ').collect();
    let ts = parts[0];                                  // FLAW 1: index panic on
    let dataset = parts[1];                             //         a short/malformed line
    let outcome = parts[2];                             //         (no length check)
    let user = parts[3].strip_prefix("user=").unwrap(); // FLAW 2: unwrap on input
    let src = parts[4].strip_prefix("src=").unwrap();   //         shape — DoS
    json!({
        "@timestamp": ts,
        "event.dataset": dataset,
        "event.outcome": outcome,                       // FLAW 3: raw OK/FAILED,
        "user.name": user,                              //         not success/failure
        "source.ip": src,
        "message": line
    }).to_string()
}
fn main() {
    for line in std::io::stdin().lines() {
        println!("{}", to_ecs(&line.unwrap()));         // FLAW 4: unwrap per line
    }
}
```
Planted flaws (answer key — mapped to the checklist):
1. **Unchecked indexing** `parts[0]`..`parts[4]` (five elements) on a `split`
   result — a short/malformed line panics (availability, CWE-248). Fix: check
   `parts.len()` (or use `.get`) and skip/count malformed lines (the L7.5 policy).
2. **`unwrap()` on `strip_prefix`** — a line missing `user=`/`src=` panics
   (availability, CWE-248). Fix: handle the `None` — skip the line.
3. **Raw `outcome`** — emits "OK"/"FAILED" verbatim instead of mapping to ECS
   `success`/`failure` (spec violation, correctness). Fix: map OK→success,
   FAILED→failure.
4. **`unwrap()` per line** in `main` — an I/O error on one line kills the whole
   run (availability, CWE-248). Fix: handle the `Result`, skip/log the bad line.
(FLAW-free things to NOTE as correct: it uses `serde_json` (correct escaping — the
L7.5 constraint met) and emits the right field NAMES.)

**GUIDED STEPS outline:** read draft_v1.rs, audit against the L7.2 checklist →
answers.txt: name each flaw's category + CWE (where applicable) → write
`direction.md`: the exact corrections you'd send back to the AI (the deliverable —
must name the four fixes) → check.
answers.txt keys (categories from L7.2's set; CWE tokens per convention):
- `f1=availability`, `f1cwe=CWE-248` (unchecked indexing)
- `f2=availability`, `f2cwe=CWE-248` (strip_prefix unwrap)
- `f3=correctness` (outcome not mapped — a spec/logic flaw, no CWE; `correctness`
  is the fifth category label used only where a flaw is a pure spec violation)
- `f4=availability`, `f4cwe=CWE-248` (per-line unwrap)
- `escaping=ok` (the learner confirms the ONE thing the AI got right: serde_json
  handles escaping — proving they audit for correct code too, not just flaws)

**CHECK LOGIC:** `assert_file_contains answers.txt '^f1=availability$'`,
`'^f2=availability$'`, `'^f3=correctness$'`, `'^f4=availability$'`,
`'^escaping=ok$'`;
`assert_file_contains_fixed answers.txt 'f1cwe=CWE-248'`, `'f2cwe=CWE-248'`,
`'f4cwe=CWE-248'`;
`assert_file_exists direction.md`;
`assert_file_contains direction.md 'len|get|bounds|check'` (a fix must address the
indexing);
`assert_file_contains direction.md 'outcome|success|failure|map'` (a fix must
address the outcome mapping); `ck_summary`.
(Pure-reading/DIRECT lab: no binary. CI fabrication: echo the keys; echo a
direction.md naming the four fixes.)

**QUIZ:**
1. choice — "draft_v1 got ONE thing right; a good reviewer notes it. What?"
   a) nothing b) it uses serde_json — JSON escaping is correct, meeting the L7.5
   constraint c) it is fast → **b**
2. choice — "Three of the four flaws are the same class. Which?" a) truncation
   b) uncaught panic on malformed input (indexing + unwraps → CWE-248) c)
   injection → **b**
3. text — "Directing a fix for `parts[3]` indexing means telling the AI to check
   the ___ before indexing." → **length** (accept: `len`, `bounds`, `count`)

**RECAP:**
```
review the AI draft against your checklist: four flaws, three of them uncaught-panic (CWE-248)
direct precise fixes — bounds-check the split, handle strip_prefix None, map OK/FAILED, handle line errors
a real review also credits what is correct — serde_json escaping was right; keep it
```

**HINTS:** L1: five flaw keys (four flaws + the one correct-thing confirmation)
plus a direction.md — the grader names each miss. L2: flaws 1/2/4 are all
uncaught-panic (indexing, strip_prefix unwrap, per-line unwrap → CWE-248); flaw 3
is a correctness/spec miss (OK/FAILED not mapped to success/failure); the ONE
correct thing is serde_json escaping. L3: write the categories + CWEs, then a
direction.md naming: check parts.len before indexing, handle the strip_prefix
None, map OK→success/FAILED→failure, handle the per-line Result.

---

### L7.7 — Capstone gate: final audit and ship
**AUDIT · gate:TRUE · est 25 · files/: ecs_parser/ (the FINISHED cargo project — runnable, serde), sample.log**
**objective:** "Ship the course: audit the corrected ECS parser against your full checklist, confirm every item passes, run it to produce real ECS JSON, and record the clean bill of health."

**files/ecs_parser/ — the FINISHED, CORRECT artifact (runnable cargo project;
serde/serde_json; incorporates every L7.6 fix). Cargo.toml pins serde +
serde_json `[VERIFY-AT-BUILD: versions]`.** src/main.rs (the reference solution —
build verbatim; it is bounded, Result-based, maps outcome, skips malformed lines,
and serializes with serde_json):**
```rust
// ecs_parser — the shipped capstone. Reads log lines on stdin, emits one ECS
// JSON object per VALID line, skips and counts malformed lines, never panics.
use serde_json::json;
use std::io::BufRead;   // brings .lines() on the locked stdin handle into scope

fn to_ecs(line: &str) -> Option<String> {
    let parts: Vec<&str> = line.split(' ').collect();
    if parts.len() != 5 {
        return None;                                   // bounded: wrong shape -> skip
    }
    let user = parts[3].strip_prefix("user=")?;         // None -> skip (no panic)
    let src = parts[4].strip_prefix("src=")?;
    let outcome = match parts[2] {                      // OK/FAILED -> ECS outcome
        "OK" => "success",
        "FAILED" => "failure",
        _ => return None,
    };
    Some(json!({
        "@timestamp": parts[0],
        "event.dataset": parts[1],
        "event.action": "login-attempt",
        "event.outcome": outcome,
        "user.name": user,
        "source.ip": src,
        "message": line
    }).to_string())
}

fn main() {
    let mut ok = 0u32;
    let mut skipped = 0u32;
    let stdin = std::io::stdin();
    for line in stdin.lock().lines() {                  // BufRead::lines on the lock
        let line = match line {                         // handle the I/O Result
            Ok(l) => l,
            Err(_) => { skipped += 1; continue; }
        };
        match to_ecs(&line) {
            Some(json) => { println!("{json}"); ok += 1; }
            None => { skipped += 1; }
        }
    }
    eprintln!("emitted {ok}, skipped {skipped}");       // summary to stderr
}
```
Expected run `[VERIFY-AT-BUILD: run it]`: `cargo run < sample.log > ecs_out.txt`
emits three ECS JSON lines (one per valid sample.log line) to ecs_out.txt, and
`emitted 3, skipped 0` to stderr. Each JSON line contains `"@timestamp"`,
`"event.outcome":"failure"` (or success), `"source.ip"`, etc. `[VERIFY-AT-BUILD:
confirm serde_json emits the dotted keys as written; if serde flattening differs,
adjust the expected strings and the check greps.]`

**GUIDED STEPS outline (learner shell):**
1. Read ecs_parser/src/main.rs — audit it against your L7.2 checklist; confirm
   each item PASSES (this is the "ship" decision — a clean audit, not a
   find-flaws).
2. `cd ecs_parser && cargo run < ../sample.log > ../ecs_out.txt && cd ..` (fetches
   serde once, learner shell) — see real ECS JSON.
3. Answer the ship checklist in answers.txt (options in lab.md):
   - a1 (choice) does any code path unwrap/panic on a log line's contents? a) yes
     b) no — malformed input returns None and is skipped/counted → `a1=b`
   - a2 (choice) is the line length/shape bounded before indexing? a) no
     b) yes — `parts.len() != 5` returns None before any indexing → `a2=b`
   - a3 (choice) is OK/FAILED mapped to ECS outcome? a) no, raw b) yes —
     success/failure via match → `a3=b`
   - a4 (choice) is JSON serialized safely? a) hand-concatenated b) via serde_json
     — correct escaping → `a4=b`
   - a5 (choice) the ship verdict: a) reject — flaws remain b) ship — every
     checklist lane (memory-safety, availability, input-validation) passes →
     `a5=b`
   - a6 (value) the number of lines emitted for sample.log (read from stderr /
     count ecs_out.txt) → `a6=3`
4. `lab check rust L7.7`.

**CHECK LOGIC:** `assert_file_contains answers.txt '^a1=b$'`, `'^a2=b$'`,
`'^a3=b$'`, `'^a4=b$'`, `'^a5=b$'`, `'^a6=3$'`;
`assert_file_contains_fixed ecs_out.txt '"@timestamp"'` (hint: step 2 — run the
parser and redirect to ecs_out.txt);
`assert_file_contains_fixed ecs_out.txt '"event.outcome":"failure"'`
`[VERIFY-AT-BUILD: exact serde output form]`;
`assert_file_contains_fixed ecs_out.txt '"source.ip":"203.0.113.9"'`;
`ck_summary`.
(CI fabrication: echo the six answers; echo three ECS JSON lines into ecs_out.txt
containing the graded field strings — no toolchain/network for acceptance.)

**QUIZ (concept-level, not duplicating the ship checklist):**
1. choice — "'Ship' at the end of an audit means…" a) the code is perfect
   b) every checklist lane passed against this artifact — memory-safety,
   availability, input-validation — with evidence c) the tests are green → **b**
2. choice — "The finished parser survives a malformed line by…" a) panicking
   b) returning None → skipping and counting it, so ingest continues c) guessing
   → **b**
3. text — "The course's final artifact emits logs in which schema (three
   letters)?" → **ecs**

**RECAP:**
```
capstone shipped: an audited, bounded, non-panicking IOC parser emitting real ECS JSON
you directed it, reviewed each iteration, and confirmed every checklist lane before shipping
that is the whole course: read Rust fluently, audit it ruthlessly, direct the AI safely
```

**HINTS:** L1: six ship-checklist keys plus a real ecs_out.txt — the grader names
each miss. L2: a1–a4 walk the checklist lanes against the code (no input panic,
bounded shape, outcome mapped, serde escaping); a6 is the count of valid lines in
sample.log (all three parse). L3: `cd ecs_parser; cargo run < ../sample.log >
../ecs_out.txt; cd ..` — read the stderr summary for a6 and the JSON for the field
checks, then confirm each audit item passes.

---

## 5. Build-session protocol (execute in this order)

0. **Prerequisite: Phases 0–6 built first** (recall refinement + `lab`
   progression). This is the LAST phase — its tag `rust-p7` completes the track.
1. Scaffold the 7 lab directories under `tracks/rust/phases/p7/` per §1 slugs.
2. Author content straight from §4; base64 all answers; `accept_b64` variants as
   listed. Honor the framing rules (no weaponized payloads; no runnable UB; AI
   drafts are read-only exhibits) — L7.3/L7.6's flaw snippets are
   identification-only.
3. **Refine L7.1's recall.json** against the real built p0–p6 content (all five
   `[VERIFY-AT-BUILD]`; this opener interleaves the whole course).
4. **[VERIFY-AT-BUILD] sweep (real toolchain + network for the capstone; never in
   check.sh):**
   - **L7.7 artifact:** pin serde/serde_json versions; `cargo run < sample.log`
     and confirm it emits three ECS JSON lines + `emitted 3, skipped 0`; confirm
     the EXACT serde output form of the dotted keys (`"event.outcome":"failure"`
     etc.) and align every `assert_file_contains_fixed` grep to reality (if serde
     emits differently, fix the expected strings). Confirm ECS field names against
     the current ECS spec (§3).
   - **L7.6 draft_v1.rs / L7.3 snippets:** read-only exhibits — verify the
     described flaws are accurately stated; NEVER compiled.
   - **L7.4:** confirm the four canonical gate commands are current
     (`cargo clippy -- -W clippy::pedantic -D warnings`, `cargo audit`,
     `cargo deny check`, `cargo test`).
   Fix content to reality and log deviations.
5. Lint gates: `./tools/lint-labs.sh` clean. **ERE discipline** — note L7.1/L7.2/
   L7.5 use intentional ERE ALTERNATIONS (`Result|Option`, category keyword
   groups) in `assert_file_contains` — those `|` are deliberate; every LITERAL
   metacharacter (the `..=` dots in L7.1's range grep, the `"` and `.` in L7.7's
   JSON greps via `assert_file_contains_fixed`) is either escaped or fixed-string.
   Learner deliverables (spec.md, checklist.md, guardrails.sh, direction.md) and
   the vendored/exhibit `files/` are NEVER linted.
6. Acceptance: extend `tests/acceptance.sh` with a P7 section — fabricated pass
   (echo answers; echo the learner deliverable files with required elements; echo
   ci_out.txt for L7.4 and ecs_out.txt with the three graded ECS lines for L7.7) +
   one negative case per lab (corrupt a key or drop a required deliverable
   element). **Only L7.7 has a runnable artifact** (fabricated as an echoed
   ecs_out.txt for acceptance); L7.1–L7.6 grade files/answers only. Drive
   `lab start rust L7.1` with 5 piped recall answers, assert non-gating. Update
   every stale catalog-count denominator at every call site — this phase completes
   the 63-lab track, so the final denominator lands here.
7. Manual full-phase pass with the real toolchain — INCLUDING `cargo run` on the
   L7.7 capstone (the course's final artifact must actually produce ECS JSON) —
   before tagging `rust-p7`. **Tagging `rust-p7` completes the entire rust track
   (63 labs).**
8. Update `planned_execution.md` (build session's job) — mark rust p7 done AND the
   rust track complete.

## 6. Decisions & deviations log (for the reviewer)

- **DIRECT labs are graded by a rubric, stated honestly** (§3) — the harness can't
  run an AI or grade prose, so DIRECT labs grade (1) a structured "which
  constraints matter" multi-select (the real test of the DIRECT skill) and (2)
  learner-written deliverables (spec.md/direction.md) checked for load-bearing
  element PRESENCE. The BRIEF says so plainly. This is the best offline proxy;
  gaming it (listing keywords) is possible but self-defeating per the honor
  contract, and the multi-select core is not gameable by prose.
- **AI output is always a read-only exhibit** — no live model in the harness;
  L7.3's three snippets and L7.6's draft_v1 are pre-authored flawed exhibits,
  graded by reading (the L4.2/L5.7 exhibit pattern). Framing rules (no weaponized
  payloads, no runnable UB) carried from Phase 4; L7.3's snippet2 shows the
  injection PATTERN and is never run.
- **serde/serde_json is the capstone's dependency (L7.6 exhibits, L7.7 artifact)**
  — an explicit contract-level deviation (like tokio in Phase 5), flagged in §3.
  The realistic SOC choice (correct JSON escaping for free — itself an audit point
  vs hand-rolled JSON). Fetched in the learner shell only; check.sh never runs
  cargo. L7.1–L7.5 need no dependency.
- **The capstone is one continuous artifact** — L7.5 specs the ECS parser, L7.6
  reviews the flawed AI draft of it, L7.7 audits and ships the corrected version.
  The learner ends with a real, runnable tool that emits ECS JSON, directly usable
  in SOC pipeline work (the map's stated payoff), not a toy.
- **`correctness` as a fifth flaw label (L7.6 f3 only)** — used exactly once, for
  a flaw that is a pure spec violation (OK/FAILED not mapped) with no CWE; the four
  security categories (memory-safety/availability/input-validation/supply-chain)
  cover every security flaw, and this one non-security-but-wrong item gets its own
  honest label rather than being forced into a security bucket. Logged so the
  reviewer expects it.
- **CWE ids reused (course-wide synthesis):** CWE-248 (panic/DoS — the most
  recurrent, L7.3/L7.6), CWE-197 (truncation), CWE-22 (traversal), CWE-78
  (injection), CWE-400 (async exhaustion). The recurrence IS the lesson — the same
  handful of classes dominate AI-Rust review.
- **ERE alternations are intentional in L7.1/L7.2/L7.5** (`Result|Option`,
  category keyword groups) — these are deliberate `assert_file_contains` ERE
  patterns accepting reasonable phrasings, NOT the escaping bug the p2/p3 reviews
  caught; every LITERAL metacharacter (L7.1's `..=` dots, L7.7's JSON `"`/`.`) is
  escaped or graded via `assert_file_contains_fixed`. §5.5 restates this so a
  reviewer doesn't "fix" the intentional ones.
- **Plan-time verification coverage (honest report):** author self-review only; no
  adversarial fleet at plan time. §5.4's toolchain sweep is authoritative — the
  key items are L7.7's exact serde_json output form (the graded JSON strings must
  match reality byte-for-byte), the current ECS field names, and the four CI gate
  command forms. Being the finale, this phase also depends on the whole track being
  built first (§0) for its recall refinement.

*End of Phase 7 plan — this completes the rust-track plan set (Phases 0–7). With
p0/p1 (`rust-p01-plan.md`) and p2–p7 planned, every one of the 63 labs is
specified; the build sessions proceed phase by phase, p0 first.*
