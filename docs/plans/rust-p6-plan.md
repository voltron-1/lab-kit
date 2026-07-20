# RUST TRACK — Phase 6 Build Plan (v1): Reading Real Security Tools

Binding content spec: `docs/curriculum/rust-literacy-lab-curriculum-v1.md` (Phase 6
section). Binding mechanical spec: `docs/kit-contracts.md`. Format precedent:
`docs/plans/rust-p01-plan.md`; conventions continued from the p2–p5 plans §3.
Reference implementation of every file format:
`tracks/demo/phases/p0/L0.0-meet-the-kit/`.
This plan is the single source of design judgment for the build session — build it
mechanically; where reality contradicts a claim marked `[VERIFY-AT-BUILD]`, fix the
content to match reality and note the deviation in the build report.

**This phase is structurally different from every prior phase — read this first.**
All six labs are **TOUR** type: guided reading of REAL, production open-source
code, not toy samples. That forces a different build discipline:

1. **The code is vendored, pinned, and transcribed verbatim — never paraphrased
   from memory.** Every `files/` source excerpt is a read-only copy of a real
   repository's source at a **pinned commit SHA**, transcribed exactly. This plan
   specifies the tour ROUTE (which repo, which file, which function, in what
   order) and the comprehension targets; the build session pulls the actual bytes
   from the pinned source. **No lab in this phase ships code this plan wrote from
   memory** — where a code shape is shown below, it is an explicitly-labeled
   *illustrative sketch of what to look for*, and the build session REPLACES it
   with the real excerpt. Every excerpt file carries an SPDX license header and a
   `PROVENANCE:` line (upstream URL + commit SHA + file path + retrieval date).
2. **Nothing is compiled.** These are large real crates; building them is out of
   scope and unnecessary — the skill being trained is *navigation and
   comprehension*, per the map ("guided navigation, comprehension questions").
   Grading is entirely answers.txt reading questions. No `rustc`, no cargo, no
   binaries, no compile-error codes anywhere in this phase.
3. **Zero-prerequisite-reading still holds.** Everything the learner needs is in
   the vendored excerpt + the lab.md tour narration. No lab sends the learner to
   an external URL to read (a browsable link may be *mentioned* for the curious,
   never *required*) — the excerpt in `files/` is self-contained.

Planning-context note: at plan time NOTHING in the rust track is built. L6.1's
recall questions are sourced from the **curriculum map's lab lists** for Phases
0–5, all `[VERIFY-AT-BUILD]`.

## 1. Lab list (from the map, exactly)

| id | title (meta.json `title`) | type | gate | est_minutes | dir slug |
|---|---|---|---|---|---|
| L6.1 | Tour: RustScan I — CLI args to scan loop | TOUR | false | 20 | `L6.1-rustscan-cli-to-loop` |
| L6.2 | Tour: RustScan II — results and output | TOUR | false | 15 | `L6.2-rustscan-results` |
| L6.3 | Tour: Vector I — source → transform → sink (Logstash territory you already know) | TOUR | false | 20 | `L6.3-vector-topology` |
| L6.4 | Tour: Vector II — inside a codec/parser path | TOUR | false | 20 | `L6.4-vector-codec` |
| L6.5 | Tour: a nom-based protocol parser | TOUR | false | 20 | `L6.5-nom-protocol-parser` |
| L6.6 | Phase gate: solo tour of an unseen repo, answer questions cold | TOUR | **true** | 25 | `L6.6-phase-gate-solo-tour` |

Gate placement: the map marks L6.6 explicitly; no other gate.
recall.json placement: **L6.1 only** (5 questions, earlier phases, interleaved).

The map's §8 "Open Items" names the tour targets as swappable: RustScan + Vector +
a nom parser is the current pick. This plan commits to them and names the exact
excerpts; the build session may swap a target if a repo has moved or a license
blocks excerpting (see §3 licensing rule) — log any swap.

## 2. Binding harness constraints (the relevant subset)

check.sh never runs cargo/rustc (irrelevant here — nothing compiles); all grading
is answers.txt `key=value` reading, artifact-based and CI-fabricatable; lint bans
as listed (no absolute-path literals etc. in check.sh — the vendored source lives
in `files/`, which is never linted or shellchecked, so real-tool code with
absolute paths / any tokens is fine there); quiz.json exactly 3 / hints.json
exactly 3 levels / recap.md exactly 3 lines / lab.md exact headings
(`## BRIEF` + `## GUIDED STEPS` — the tour route lives under GUIDED STEPS);
answers base64, text answers lowercase-normalized with `accept_b64` variants;
quiz stdin one line per question; recall non-gating at `lab start` on the opener
only.

## 3. Track conventions (carried + Phase-6 additions)

Carried: `answers.txt` `key=value` grading (options printed in lab.md; anchored
ERE or `assert_file_contains_fixed`); quiz-vs-answers non-duplication; hints
ladder L1 artifact/step → L2 exact function/line → L3 near-answer; **ERE
discipline — ALL metacharacters escaped in assert patterns**; descs/hints keep
apostrophes out.

New for Phase 6 (the TOUR discipline):
- **Vendored-source rule (hard requirement).** Every `files/` excerpt is real
  source at a pinned commit, transcribed verbatim, and carries a header block with
  three things: (1) a `// READ-ONLY EXHIBIT — never compiled or run; you are here
  to read` banner (same self-documenting convention as L4.2/L5.7/L5.8's exhibits),
  (2) an SPDX license identifier, and (3) a `PROVENANCE:` line (upstream URL +
  commit SHA + file path + retrieval date). This plan NEVER ships invented "real"
  code; illustrative sketches are labeled as such and REPLACED at build.
  `[VERIFY-AT-BUILD]` on every excerpt: pull the real bytes, pin the SHA, confirm
  the tour route still matches the current code (repos move — if a function was
  renamed/relocated, update the route and the answer key to match reality).
- **Licensing rule (hard requirement).** Before vendoring, the build session
  confirms the upstream license permits a small excerpt for educational use with
  attribution (RustScan, Vector, and the nom parser are all
  permissively/copyleft-licensed open source; a bounded excerpt with SPDX +
  provenance + a NOTICE pointer is standard). If a target's license is
  incompatible with in-repo redistribution, SWAP the target (§1 allows it) and log
  it. No excerpt ships without a confirmed license header.
- **Answer-key sourcing (two tiers, every answer tagged).** Each lab's answer key
  mixes: **(A) architecture-level answers** stated here with confidence (stable
  facts about the tool's design — e.g. "Vector's pipeline is source → transform →
  sink"), and **(B) excerpt-specific answers** the build session reads off the
  pinned code (an exact function name, a constant, a type) — every (B) slot is
  `[VERIFY-AT-BUILD]` with the comprehension target specified so the builder knows
  what to extract. This keeps the plan substantive without fabricating specifics.
- **TOUR route format.** GUIDED STEPS is a numbered reading walk: "open FILE, find
  FUNCTION, notice X, follow the call to Y." Each numbered stop maps to one
  answer-key checkpoint. The gate (L6.6) omits the narration — the learner
  navigates cold.
- **No compilation, no binaries, no CWE machinery.** Grading is reading only;
  negative acceptance cases corrupt an answer key (there is no binary to delete).

## 4. Lab entries

---

### L6.1 — Tour: RustScan I — CLI args to scan loop
**TOUR · gate:false · est 20 · files/: rustscan-src/ (vendored excerpt) · recall.json: YES (phase opener)**
**objective:** "Navigate RustScan from CLI-argument parsing to the batched async scan loop, and answer where user input becomes a bounded set of concurrent connect attempts."

**recall.json — 5 questions, sourced from the curriculum map's Phase 0–5 lab
lists. ALL FIVE `[VERIFY-AT-BUILD]`.**
1. choice (source: "rust L5.8 — concurrent scanner gate") — "The primitive that
   caps how many async probes run at once is a…" a) Mutex b) Semaphore c) channel
   → **b**
2. choice (source: "rust L5.5 — async/await model") — "Calling an `async fn`
   without `.await`…" a) runs it immediately b) returns a lazy Future that does
   nothing yet c) spawns a thread → **b**
3. choice (source: "rust L3.1 — Result and ?") — "The `?` operator on an `Err`…"
   a) panics b) returns the Err to the caller c) ignores it → **b**
4. choice (source: "rust L4.5 — panics as DoS") — "An `unwrap()` reachable by
   untrusted input is a…" a) memory-corruption bug b) denial-of-service risk
   c) type error → **b**
5. choice (source: "rust L0.3 — repo anatomy") — "To learn what an unknown crate
   does and where it starts, you read…" a) the test output b) Cargo.toml plus the
   binary entry point (src/main.rs) c) the git log → **b**

**files/rustscan-src/ — VENDOR AT BUILD `[VERIFY-AT-BUILD]`:** the excerpt spans
RustScan's CLI/config and scan-loop path. Vendor, pinned SHA + SPDX + PROVENANCE:
- the CLI/args definition (the struct with the clap/structopt derive — ports,
  targets, batch size, timeout) and where it is parsed in `main`;
- the batching/scan-order module and the async scan loop that turns a batch of
  (addr, port) pairs into concurrent connect futures and awaits them.
`[VERIFY-AT-BUILD: confirm current file paths — RustScan's layout has evolved;
transcribe the real functions and record their names for the answer key.]`

**TOUR ROUTE (GUIDED STEPS — reading walk, no compilation):**
1. Open Cargo.toml in the excerpt — note it is a binary crate; identify the CLI
   parsing crate in `[dependencies]` (clap or structopt) `[VERIFY-AT-BUILD:
   which]`.
2. Open the args/opts source — read the options struct: find the fields for
   targets, ports, **batch size**, and **timeout**. These four are the whole user
   contract.
3. Follow to `main` — see args parsed into a config, then handed to the scanner.
4. Open the scanner/scan-loop source — find the loop that takes a **batch** of
   sockets and builds one async connect future per socket, then awaits the batch
   (the L5.8 pattern in a real tool: bounded concurrency, here bounded by the
   batch size rather than a Semaphore).
5. Notice the connect is time-bounded (a timeout wraps each attempt — the L5.7
   lesson in production) `[VERIFY-AT-BUILD: confirm the timeout mechanism]`.

**Answer key (Tier A confident + Tier B build-sourced):**
- q1 (choice, A) RustScan is a: a) library crate b) binary (CLI) crate — it has a
  main entry point c) proc-macro → `q1=b`
- q2 (choice, A) the four user-facing knobs the options struct exposes are, in
  spirit: a) colors, verbosity, log file, help b) targets, ports, batch size,
  timeout — what/where to scan and how hard c) threads, nice level, PID, cwd →
  `q2=b` `[VERIFY-AT-BUILD: confirm these four exist; adjust option wording to the
  real field names]`
- q3 (value, B) the name of the options/args struct (read off the excerpt) →
  `q3=<StructName>` `[VERIFY-AT-BUILD]`
- q4 (choice, A) concurrency in the scan loop is bounded by: a) nothing — it is
  unbounded b) the batch size — a fixed number of connect futures are awaited at
  once (RustScan tunes this to the file-descriptor ulimit) c) one at a time →
  `q4=b`
- q5 (choice, A) each connect attempt is: a) unbounded — it can hang forever
  b) time-bounded by the timeout option — a filtered port cannot stall the scan
  c) retried infinitely → `q5=b`

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=b$'`,
`'^q4=b$'`, `'^q5=b$'`; `assert_file_contains_fixed answers.txt 'q3=<StructName>'`
`[VERIFY-AT-BUILD: substitute the real struct name; keep it a fixed-string grep]`;
`ck_summary`. (Pure-reading lab: answers.txt only, no binary. CI fabrication: echo
the five lines.)

**QUIZ:**
1. choice — "The first two files to open in any unfamiliar Rust tool are…"
   a) the tests and the CI config b) Cargo.toml (deps + is it a bin?) and the
   binary entry point c) the changelog and the license → **b**
2. choice — "RustScan bounds its scan concurrency with…" a) an unbounded spawn
   b) a batch size tuned to the FD ulimit — the real-world version of L5.8's
   Semaphore cap c) a global mutex → **b**
3. text — "Reading a tool 'CLI-first' means starting from where user ___ is
   parsed into config." → **input** (accept: `arguments`, `args`)

**RECAP:**
```
tour a tool CLI-first: options struct -> config -> the loop that does the work
RustScan turns targets+ports into batches of async connect futures, awaited a batch at a time
concurrency is bounded (batch size ~ FD ulimit) and each connect is timeout-bounded — L5.7/L5.8 for real
```

**HINTS:** L1: five answer keys, all read from the excerpt + the tour narration —
nothing runs. L2: q1 is answered by Cargo.toml (a `[[bin]]` / `src/main.rs` makes
it a binary); q2 is the options struct's fields; q4/q5 are the batch-size and
timeout bounds the tour points at. L3: re-walk the numbered tour — each stop names
one answer; q3 is the exact struct name at tour stop 2.

---

### L6.2 — Tour: RustScan II — results and output
**TOUR · gate:false · est 15 · files/: rustscan-src/ (vendored excerpt, output path)**
**objective:** "Follow RustScan's open-port results from the scan loop to output — collection, dedup/sort, and the nmap hand-off — and see where a tool's output becomes another tool's input."

**files/rustscan-src/ — VENDOR AT BUILD `[VERIFY-AT-BUILD]`:** the results/output
path — where open ports are collected from the awaited futures, deduplicated/
sorted, printed, and (RustScan's signature behavior) **handed to nmap** for
service/version detection. `[VERIFY-AT-BUILD: transcribe the real collection and
nmap-invocation code; record function/type names.]`

**TOUR ROUTE (GUIDED STEPS):**
1. Return to the scan loop's output side — find where a successful connect
   becomes a recorded open port (the `Ok` arm / the collection push).
2. Follow the collected ports — note dedup/sort before output (the determinism
   lesson from L5.8: completion order is nondeterministic, so results are sorted).
3. Find the output/reporting code — how open ports are presented to the user.
4. Find the **nmap hand-off** — RustScan finds open ports fast, then shells out to
   nmap for deep service detection; locate where the open-port list is formatted
   into nmap arguments. This is the "output becomes input" seam.
5. Reviewer's eye: the open-port list flows into a subprocess argument — note
   whether it is passed as an argument vector vs a shell string (the L4.7
   injection lens applied to a real tool) `[VERIFY-AT-BUILD: report which; RustScan
   builds an argument list — confirm and make it q5].`

**Answer key:**
- q1 (choice, A) a successful connect is recorded as: a) an error b) an open port
  pushed into a results collection c) an immediate print with no storage →
  `q1=b`
- q2 (choice, A) results are sorted before output because: a) speed b) probe
  completion order is nondeterministic — sorting makes output stable/comparable
  (L5.8) c) nmap requires it → `q2=b`
- q3 (choice, A) after finding open ports, RustScan: a) stops b) hands the open
  ports to **nmap** for service/version detection — fast discovery, then deep
  scan c) re-scans them → `q3=b`
- q4 (value, B) the name of the function/type that performs the nmap hand-off
  (read off the excerpt) → `q4=<name>` `[VERIFY-AT-BUILD]`
- q5 (choice, A) the open-port list is passed to the nmap subprocess as: a) a
  concatenated shell string (injection-prone) b) an argument vector / structured
  args (the L4.7-safe form) c) an environment variable → `q5=b`
  `[VERIFY-AT-BUILD: confirm against the real code; if it actually builds a shell
  string, flip the key and turn this into a finding.]`

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=b$'`,
`'^q3=b$'`, `'^q5=b$'`; `assert_file_contains_fixed answers.txt 'q4=<name>'`
`[VERIFY-AT-BUILD]`; `ck_summary`.

**QUIZ:**
1. choice — "RustScan's design philosophy is…" a) replace nmap b) fast open-port
   discovery, then hand results to nmap for deep detection — each tool does what
   it is best at c) scan without concurrency → **b**
2. choice — "One tool's output feeding another's input is a place to check…"
   a) nothing b) how the hand-off is built — an argument vector is injection-safe,
   a shell string is not (L4.7) c) the color codes → **b**
3. text — "Results are ___ before output because async completion order is
   nondeterministic." → **sorted** (accept: `sort`, `ordered`)

**RECAP:**
```
follow results out: connect Ok -> collected open port -> dedup/sort -> output
RustScan's signature: fast discovery, then hand the open ports to nmap for deep detection
the output->input seam is a security read: argument vector (safe) vs shell string (L4.7)
```

**HINTS:** L1: five answer keys from the excerpt + tour. L2: q1 is the Ok-arm
collection; q3 is the nmap hand-off the tour points at; q5 asks how the args are
built (vector vs string). L3: re-walk stops 1–5; q4 is the exact function name at
the nmap-handoff stop.

---

### L6.3 — Tour: Vector I — source → transform → sink (Logstash territory you already know)
**TOUR · gate:false · est 20 · files/: vector-src/ (vendored excerpt, topology)**
(meta.json `title` carries the full string above, verbatim from the map.)
**objective:** "Map Vector's core pipeline — source → transform → sink — onto the Logstash input/filter/output you already know, and locate where an event enters, is reshaped, and exits."

**files/vector-src/ — VENDOR AT BUILD `[VERIFY-AT-BUILD]`:** an excerpt showing
Vector's topology model — the `Source`/`Transform`/`Sink` trait definitions (or
their component-spec equivalents) and a small concrete example of each (e.g. a
simple source, a `remap`/filter transform, a console/file sink), plus the `Event`
type an event flows as. `[VERIFY-AT-BUILD: Vector's crate layout is large and has
evolved; pick a coherent, small, current excerpt that shows all three stages and
the Event type; record the real trait/type names.]`

**TOUR ROUTE (GUIDED STEPS):**
1. Read the topology overview in the excerpt — the three roles: **Source**
   (ingests events), **Transform** (reshapes/filters/enriches), **Sink** (emits
   events out). Map to Logstash: input → filter → output (the map's "Logstash
   territory you already know").
2. Find the `Event` type — the unit that flows through the pipeline; note it
   carries structured fields (log/metric/trace) `[VERIFY-AT-BUILD: the Event
   enum/struct name]`.
3. Read the Source trait/spec — how bytes/records become Events entering the
   pipeline.
4. Read a Transform — how one Event becomes zero, one, or many Events (filter =
   maybe-drop; remap = reshape).
5. Read a Sink — how Events leave (to a file, console, network) — note it is the
   only stage that talks to the outside world on the way out.
6. Note the whole thing is **config-driven** (TOML/YAML wires sources → transforms
   → sinks by name) and **async/tokio** under the hood (L5.6's spawn-drain shape
   at scale).

**Answer key:**
- q1 (value, A) Vector's three pipeline stages, in order, comma-separated, no
  spaces (lowercase) → `q1=source,transform,sink`
- q2 (choice, A) mapping to Logstash: source/transform/sink correspond to:
  a) output/filter/input b) input/filter/output c) codec/pipeline/buffer →
  `q2=b`
- q3 (choice, A) a Transform can turn one input event into: a) exactly one output
  always b) zero, one, or many events (filter can drop; splits can fan out)
  c) only metrics → `q3=b`
- q4 (value, B) the name of the type that flows through the pipeline (read off the
  excerpt) → `q4=Event` `[VERIFY-AT-BUILD: confirm it is `Event`; adjust if the
  excerpt names it differently]`
- q5 (choice, A) the pipeline is wired together by: a) hardcoded Rust b) a config
  file (TOML/YAML) naming sources, transforms, and sinks and connecting them
  c) command-line flags only → `q5=b`

**CHECK LOGIC:** `assert_file_contains_fixed answers.txt 'q1=source,transform,sink'`;
`assert_file_contains answers.txt '^q2=b$'`, `'^q3=b$'`, `'^q5=b$'`;
`assert_file_contains_fixed answers.txt 'q4=Event'` `[VERIFY-AT-BUILD]`;
`ck_summary`.

**QUIZ:**
1. choice — "Vector's source → transform → sink is the same shape as…"
   a) MVC b) Logstash's input → filter → output c) a REST API → **b**
2. choice — "The only pipeline stage that emits events to the outside world is
   the…" a) source b) sink c) transform → **b**
3. text — "Vector wires its pipeline together with a ___ file (TOML/YAML), not
   hardcoded Rust." → **config** (accept: `configuration`, `toml`, `yaml`)

**RECAP:**
```
Vector pipeline = source (in) -> transform (reshape/filter) -> sink (out) = Logstash's model
one Event type flows through; a transform can drop, keep, or fan out events
the topology is config-driven (TOML/YAML) and async/tokio underneath — L5.6 at scale
```

**HINTS:** L1: five answer keys from the excerpt + tour. L2: q1/q2 are the three
stages and their Logstash mapping (input/filter/output); q3 is what a transform
may do to event count; q5 is config-driven wiring. L3: re-read the topology
overview at tour stop 1 and the Event type at stop 2 — q1 and q4 are right there.

---

### L6.4 — Tour: Vector II — inside a codec/parser path
**TOUR · gate:false · est 20 · files/: vector-src/ (vendored excerpt, codec path)**
**objective:** "Follow one concrete decode path inside Vector — raw bytes → framed → decoded Event — and see where untrusted input is parsed and how a decode failure is handled (not panicked)."

**files/vector-src/ — VENDOR AT BUILD `[VERIFY-AT-BUILD]`:** a codec/decoder
excerpt — a framer (splits a byte stream into frames, e.g. newline-delimited) and
a decoder/deserializer (turns a frame into an Event, e.g. the JSON or syslog
codec), showing the `Result`-returning decode signature. `[VERIFY-AT-BUILD:
transcribe a real, current codec path; record the trait/function names and the
error type.]`

**TOUR ROUTE (GUIDED STEPS):**
1. Open the codec excerpt — find the **framing** step: how a continuous byte
   stream is split into discrete frames (a length prefix or a delimiter — the
   L4.6 bounded-read lesson at production scale).
2. Find the **decoding** step: how one frame is deserialized into an Event (e.g.
   parse JSON / syslog).
3. Read the decode signature — note it returns a `Result` (decode can FAIL on
   malformed input) — untrusted bytes meet a fallible parser, exactly the L3.1/
   L4.6 pattern.
4. Follow the error path — a decode failure produces an `Err` that is handled
   (logged/counted/dropped), NOT an `unwrap` that panics the pipeline (the L4.5
   availability lesson — one malformed record must not kill the ingest).
5. Note the reviewer takeaway: this is where Vector meets untrusted input at
   scale — the framing bound and the fallible, non-panicking decode are the two
   things that keep a malformed or hostile record from becoming a DoS.

**Answer key:**
- q1 (choice, A) framing does: a) decodes JSON b) splits a continuous byte stream
  into discrete frames (by delimiter or length) before decoding c) opens sockets
  → `q1=b`
- q2 (choice, A) the decode function returns a: a) plain Event, panicking on bad
  input b) `Result<Event, DecodeError>` — decode is fallible, malformed input is
  an `Err` c) bool → `q2=b`
- q3 (choice, A) a malformed record hitting the decoder should: a) panic the
  pipeline b) produce an `Err` that is logged/counted/dropped so ingest survives
  (L4.5) c) be silently accepted → `q3=b`
- q4 (value, B) the codec/decoder function or trait name (read off the excerpt) →
  `q4=<name>` `[VERIFY-AT-BUILD]`
- q5 (choice, A) the two controls that keep a hostile record from becoming a DoS
  here are: a) unsafe and speed b) a bounded framing step and a fallible,
  non-panicking decode c) a mutex and a retry loop → `q5=b`

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=b$'`,
`'^q3=b$'`, `'^q5=b$'`; `assert_file_contains_fixed answers.txt 'q4=<name>'`
`[VERIFY-AT-BUILD]`; `ck_summary`.

**QUIZ:**
1. choice — "Framing before decoding exists to…" a) compress data b) cut a
   continuous byte stream into discrete records before each is parsed c) encrypt
   → **b**
2. choice — "A production codec returns `Result` on decode because…" a) style
   b) input is untrusted and can be malformed — failure must be a value, not a
   panic that kills ingest (L4.5) c) it is faster → **b**
3. text — "One malformed record must not crash ingest — the decoder returns an
   Err instead of calling ___." → **unwrap** (accept: `panic`, `panic!`)

**RECAP:**
```
Vector decode path: raw bytes -> framed (delimiter/length) -> Result<Event> decode
decode is fallible by design — malformed input is an Err that is logged/dropped, never a panic
this is untrusted input at scale: bounded framing + non-panicking decode keep it from being a DoS
```

**HINTS:** L1: five answer keys from the excerpt + tour. L2: q1 is the framing
step (stop 1); q2/q3 are the Result signature and the handled error path; q5 is
the two controls named at stop 5. L3: re-walk stops 1–4; q4 is the codec function
name at the decode stop.

---

### L6.5 — Tour: a nom-based protocol parser
**TOUR · gate:false · est 20 · files/: nom-parser-src/ (vendored excerpt)**
**objective:** "Read a REAL nom parser-combinator protocol parser — the production form of L4.6's hand-rolled version — and identify the combinators, the IResult flow, and the bounds that make it safe on hostile bytes."

**files/nom-parser-src/ — VENDOR AT BUILD `[VERIFY-AT-BUILD]`:** a bounded parse
function from a real nom-based protocol parser. **Recommended target:** a
`rusticata` parser (e.g. `tls-parser`, `dns-parser`, or `ipsec-parser` — real
nom-based parsers used in Suricata IDS, security-relevant and self-contained) —
excerpt one header/record parse function that uses the classic combinators.
`[VERIFY-AT-BUILD: pick one parser, pin the SHA, confirm license permits the
excerpt, transcribe one bounded parse fn, record the combinator names it uses and
the IResult error type.]` (Illustrative shape ONLY — do NOT ship this; it is
L4.6's hand-rolled parser as a memory aid for what to look for; the real excerpt
uses nom's `tag`/`take`/`be_u16`/`map`/etc. and `IResult`):
```rust
// ILLUSTRATIVE — replace with the real vendored nom excerpt. Real nom code
// threads IResult<&[u8], T> through combinators like:
//   let (rest, tag)   = be_u8(input)?;
//   let (rest, len)   = be_u16(rest)?;
//   let (rest, body)  = take(len as usize)(rest)?;   // bounds-checked take
```

**TOUR ROUTE (GUIDED STEPS):**
1. Open the parser excerpt — find the parse function's signature; note it returns
   nom's `IResult<&[u8], T>` (input-slice, remaining, value — the L4.6 shape, now
   real).
2. Identify the **combinators**: `tag` (match exact bytes), `take`/`take(n)`
   (consume n bytes — **bounds-checked**), `be_u16`/`le_u32` (read a fixed-width
   integer), `map`/`map_res` (transform a parsed value), and how `?` / the nom
   sequencing threads the remaining input through each step.
3. Find the **bounds**: where a length field read from the input governs a `take`
   — and confirm nom's `take` returns an `Incomplete`/`Error` (not an OOB read)
   when the input is shorter than the declared length. This is L4.6's central
   safety property in production.
4. Follow one complete parse: bytes in → combinators consume pieces → a typed
   value + remaining bytes out, or a parse error.
5. Reviewer takeaway: a parser-combinator library makes the bounded-read habit
   structural — you get "refuse before reading past the end" for free from
   `take`, which is why security-critical protocol parsers use nom.

**Answer key:**
- q1 (choice, A) a nom parser function returns: a) the value only b) `IResult` —
  the remaining input plus the parsed value (or a parse error) c) a bool →
  `q1=b`
- q2 (value, B) the combinator in the excerpt that consumes exactly N bytes and
  is bounds-checked (read off the code) → `q2=take` `[VERIFY-AT-BUILD: confirm the
  excerpt uses `take`; if it uses `take_while`/`length_data`/etc., set the key to
  the real one]`
- q3 (choice, A) when a length field says 200 bytes but only 4 remain, nom's
  `take(200)`: a) reads past the buffer (OOB) b) returns Incomplete/Error — it
  refuses, no out-of-bounds read (L4.6) c) panics → `q3=b`
- q4 (choice, A) versus L4.2's unsafe from_raw_parts exhibit, the nom parser is
  safe because: a) it is written in C b) `take` bounds-checks the length before
  consuming — the same declared-length that was an OOB read in L4.2 is a handled
  parse error here c) it uses more unsafe → `q4=b`
- q5 (value, B) the name of the parsed protocol/record type the function produces
  (read off the excerpt) → `q5=<TypeName>` `[VERIFY-AT-BUILD]`

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q3=b$'`,
`'^q4=b$'`; `assert_file_contains_fixed answers.txt 'q2=take'` `[VERIFY-AT-BUILD]`;
`assert_file_contains_fixed answers.txt 'q5=<TypeName>'` `[VERIFY-AT-BUILD]`;
`ck_summary`.

**QUIZ:**
1. choice — "A nom `IResult<&[u8], T>` carries…" a) just the value b) the
   remaining unparsed input and the parsed value (or an error) — the L4.6 shape
   c) a file handle → **b**
2. choice — "nom's `take(n)` on input shorter than n…" a) reads out of bounds
   b) refuses — Incomplete/Error, never an OOB read c) panics → **b**
3. text — "Security-critical protocol parsers use combinator libraries like nom
   because bounds-checking every read becomes ___ (built-in vs manual)." →
   **built-in** (accept: `structural`, `automatic`, `free`)

**RECAP:**
```
a real nom parser threads IResult<&[u8], T> through tag/take/be_u16/map — L4.6 in production
take(n) is bounds-checked: a hostile length is a parse error, never an out-of-bounds read
combinator libraries make "refuse before reading past the end" structural — why parsers use nom
```

**HINTS:** L1: five answer keys from the excerpt + tour. L2: q1 is the IResult
return; q3/q4 are `take`'s bounds-check (the L4.6/L4.2 contrast); q2 is the
byte-consuming combinator's name. L3: re-walk stops 1–3; q2 is the combinator at
stop 2 and q5 is the produced type at stop 4.

---

### L6.6 — Phase gate: solo tour of an unseen repo, answer questions cold
**TOUR · gate:TRUE · est 25 · files/: mystery-src/ (vendored excerpt of a NOT-yet-toured tool)**
**objective:** "Prove Phase 6: navigate an unfamiliar real Rust security tool cold — no guided narration — and answer the same auditor questions you now ask of any repo: what does it do, where does it start, where does untrusted input enter, and what are its failure/safety properties."

**files/mystery-src/ — VENDOR AT BUILD `[VERIFY-AT-BUILD]`:** a self-contained
excerpt (~60–120 lines: Cargo.toml + the entry point + the one core function) of
a **small, real, security-adjacent Rust tool NOT toured in L6.1–L6.5.** Selection
criteria for the builder: (a) small and self-contained enough to tour cold in one
lab; (b) real and security-relevant (a hex viewer, a hash/IOC utility, a small
log/PCAP parser, a checksum tool, etc.); (c) permissively licensed for excerpting
(SPDX + PROVENANCE required). **Candidates (builder picks one):** `hexyl` (hex
viewer), a small `blake3`/hashing CLI, `pnet`/`etherparse` packet-parse snippet,
or another compact tool. `[VERIFY-AT-BUILD: choose the repo, pin the SHA, confirm
license, transcribe the excerpt, and DERIVE the answer key from the real code —
the questions below are structural and repo-agnostic; the answers are read off
whichever tool is chosen.]`

**GUIDED STEPS (gate — NO tour narration; the learner navigates cold):** read
Cargo.toml, the entry point, and the core function; answer the 8 structural
questions in answers.txt from the source alone. (Honor contract: this is the
gate — the whole point is doing it without a guided route.)

**The 8 structural questions (repo-agnostic; answers derived from the chosen
excerpt at build — every value `[VERIFY-AT-BUILD]`):**
1. choice — is this a binary or a library crate? a) binary (has a main entry
   point) b) library c) both → `q1=<a-or-b>` `[VERIFY-AT-BUILD: from Cargo.toml/
   presence of main.rs]`
2. value — the crate name (from Cargo.toml) → `q2=<name>` `[VERIFY-AT-BUILD]`
3. value — the file holding the entry point (path from crate root, e.g.
   src/main.rs) → `q3=<path>` `[VERIFY-AT-BUILD]`
4. choice — in one line, what does this tool DO? (three plausible options written
   at build, one correct) → `q4=<letter>` `[VERIFY-AT-BUILD]`
5. choice — where does untrusted/external input ENTER? a) CLI args b) a file/
   stdin read c) a network socket (builder sets the real options + correct
   answer) → `q5=<letter>` `[VERIFY-AT-BUILD]`
6. value — the name of the core function that does the tool's main work → `q6=
   <name>` `[VERIFY-AT-BUILD]`
7. choice — the tool's failure posture on bad input: a) unwrap/panic paths reach
   input b) returns Result/Option and handles failure c) cannot tell from the
   excerpt (builder sets the honest answer for the chosen code) → `q7=<letter>`
   `[VERIFY-AT-BUILD]`
8. choice — one Phase-1–5 concept visibly used in the code (Option, Result, a
   borrow, an iterator chain, an enum/match, Arc/async — builder picks a real one
   and writes options) → `q8=<letter>` `[VERIFY-AT-BUILD]`

**CHECK LOGIC:** eight greps on answers.txt — mix of anchored-ERE choice keys
(`'^q1=a$'` etc.) and `assert_file_contains_fixed` for the value keys (crate name,
path, function name), ALL substituted at build from the chosen repo
`[VERIFY-AT-BUILD: fill every key from the real excerpt]`; `ck_summary`.
(Pure-reading gate: answers.txt only, no binary. CI fabrication: echo eight lines
matching the built key.)

**QUIZ (concept-level, not duplicating the 8):**
1. choice — "The four auditor questions for ANY unfamiliar repo are…" a) stars,
   forks, license, age b) what does it do, where does it start, where does
   untrusted input enter, what are its failure/safety properties c) lines of
   code, test count, CI status, last commit → **b**
2. choice — "You can answer 'where does untrusted input enter' by…" a) running it
   b) reading for the CLI/file/socket boundary where external bytes first arrive
   c) checking the star count → **b**
3. text — "The gate skill: navigating an unfamiliar repo ___ — without a guided
   route." → **cold** (accept: `solo`, `unaided`, `alone`)

**RECAP:**
```
gate passed: toured an unseen real repo cold — entry point, purpose, input boundary, failure posture
the four auditor questions travel to any codebase: what, where-start, where-input, how-does-it-fail
Phase 7 next: stop reading others' Rust and start DIRECTING and auditing AI-generated Rust
```

**HINTS:** L1: eight structural keys, all read from the mystery excerpt — the
grader names each miss; there is no tour narration, by design. L2: q1/q2/q3 come
straight from Cargo.toml and the file tree (binary vs lib, crate name, entry
path); q5 is wherever external bytes first arrive (args, a file read, a socket);
q6 is the main work function. L3: open Cargo.toml first (q1/q2), then the entry
point (q3), then follow to the core function (q6) — the same CLI-first route L6.1
taught, now unaided.

---

## 5. Build-session protocol (execute in this order)

0. **Prerequisite: Phases 0–5 built first** (recall refinement + `lab`
   progression).
1. Scaffold the 6 lab directories under `tracks/rust/phases/p6/` per §1 slugs.
2. **Vendor every excerpt (the heart of this phase's build):** for each target
   (RustScan L6.1/L6.2, Vector L6.3/L6.4, the nom parser L6.5, the mystery repo
   L6.6): confirm the license permits an excerpt (SWAP + log if not), pull the
   real source at a **pinned commit SHA**, transcribe the specified functions
   verbatim into `files/`, add the header block per §3's vendored-source rule (the
   `READ-ONLY EXHIBIT — never compiled or run` banner + SPDX identifier +
   `PROVENANCE:` line — URL + SHA + path + date). **Replace every illustrative
   sketch in §4 with real code.**
3. **Derive/confirm every answer key against the vendored code.** Tier-A
   architecture answers: confirm they still hold for the pinned version (repos
   evolve — if RustScan no longer batches, or Vector renamed a trait, UPDATE the
   route and key to reality and log it). Tier-B slots (`<StructName>`, `<name>`,
   `<TypeName>`, all of L6.6): fill from the real code and substitute into both
   lab.md and the CHECK LOGIC `assert_file_contains_fixed` patterns.
4. **Refine L6.1's recall.json** against the real built p0–p5 content (all five
   `[VERIFY-AT-BUILD]`).
5. Lint gates: `./tools/lint-labs.sh` clean. The vendored source in `files/` is
   NEVER linted or shellchecked (it is real third-party code — absolute paths, any
   tokens, all fine there); only the check.sh grader files are linted, and they
   contain only answers.txt greps. **ERE discipline** — when substituting real
   names into `assert_file_contains_fixed` patterns, they are fixed-string
   (literal) greps, so metacharacters in a real identifier are safe; if any name
   is used in an *anchored ERE* grep instead, escape it.
6. Acceptance: extend `tests/acceptance.sh` with a P6 section — every lab is
   pure-reading, so each fabricated-pass case just echoes the answer keys (with
   the real substituted values) and pipes 3 quiz answers; one negative case per
   lab corrupts a key. **No binaries anywhere in this phase.** Drive
   `lab start rust L6.1` with 5 piped recall answers, assert non-gating. Update
   every stale catalog-count denominator at every call site.
7. Manual full-phase pass (read each tour end-to-end, confirm each answer key
   matches the vendored code) before tagging `rust-p6`.
8. Update `planned_execution.md` (build session's job, not this plan's).

## 6. Decisions & deviations log (for the reviewer)

- **This plan ships NO fabricated "real" code** — every Phase-6 excerpt is
  vendored from a pinned real repo at build time; the one illustrative sketch
  (L6.5) is explicitly labeled and to be replaced. This is the honest way to plan
  a tour of code the planner cannot reproduce verbatim from memory: specify the
  ROUTE and the comprehension targets, source the bytes at build. Every
  excerpt-specific answer is a `[VERIFY-AT-BUILD]` Tier-B slot.
- **Two-tier answer keys** — Tier A (architecture facts stated with confidence:
  RustScan is CLI→batched-scan→nmap-handoff; Vector is source→transform→sink,
  config-driven, tokio; nom threads IResult with bounds-checked `take`) give the
  plan real substance; Tier B (exact struct/function/type names) is read off the
  pinned code. Both are demarcated per answer so the builder knows which to source.
- **Licensing + provenance is a hard build gate** — no excerpt ships without a
  confirmed permissive/compatible license, an SPDX header, and a PROVENANCE line;
  a blocked target is swapped (the map explicitly allows swapping tour targets)
  and logged.
- **Nothing compiles in Phase 6** — the trained skill is navigation/comprehension
  of real code (the map's exact framing); grading is answers.txt reading only, no
  binaries, no rustc, no CWE/error-code machinery. Negative acceptance cases
  corrupt a key.
- **The phase is a synthesis, not new concepts** — each tour deliberately re-lands
  earlier lessons in production code: L5.7/L5.8 (bounded concurrency, timeouts) in
  RustScan; L3.1/L4.5 (fallible non-panicking decode) in Vector; L4.6/L4.2
  (bounds-checked parsing vs the unsafe OOB read) in the nom parser; L0.3's
  repo-anatomy skill, unaided, in the L6.6 gate. The recap cards state these
  cross-links.
- **L6.6's questions are repo-agnostic and structural** (binary-or-lib, crate
  name, entry point, purpose, input boundary, core function, failure posture, a
  visible earlier-phase concept) — they work for whatever small tool the builder
  chooses, and every answer is derived from the real excerpt. This makes the gate
  robust to the target swap the plan permits.
- **Plan-time verification coverage (honest report):** author self-review only.
  Because the code is build-sourced, this phase's `[VERIFY-AT-BUILD]` density is
  the highest of any phase — by design: the plan is authoritative on the tour
  route and question structure, and the build session is authoritative on the code
  and the exact answers. The confident Tier-A architecture claims are standard,
  well-known facts about these tools, but even those are to be re-confirmed
  against the pinned version (repos move) — §5.3 makes that mandatory.
