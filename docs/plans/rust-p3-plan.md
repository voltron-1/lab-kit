# RUST TRACK — Phase 3 Build Plan (v1): Types, Traits, Error Handling

Binding content spec: `docs/curriculum/rust-literacy-lab-curriculum-v1.md` (Phase 3
section). Binding mechanical spec: `docs/kit-contracts.md`. Format precedent:
`docs/plans/rust-p01-plan.md`; conventions continued from
`docs/plans/rust-p2-plan.md` §3. Reference implementation of every file format:
`tracks/demo/phases/p0/L0.0-meet-the-kit/`.
This plan is the single source of design judgment for the build session — build it
mechanically; where reality contradicts a claim marked `[VERIFY-AT-BUILD]`, fix the
content to match reality and note the deviation in the build report.

Planning-context note: at plan time NOTHING in the rust track is built. Phases 0–2
exist only as plan documents. L3.1's recall questions are therefore sourced from
the **curriculum map's lab lists** for Phases 0–2 (titles + descriptions), not from
disk content, and every one is `[VERIFY-AT-BUILD]` — the p3 build session refines
wording against the real built earlier phases (build order: p0/p1/p2 first).

## 1. Lab list (from the map, exactly)

| id | title (meta.json `title`) | type | gate | est_minutes | dir slug |
|---|---|---|---|---|---|
| L3.1 | `Result` and the `?` operator | DECODE | false | 15 | `L3.1-result-question-mark` |
| L3.2 | `unwrap` / `expect` / `panic!` — red flags in review | AUDIT | false | 15 | `L3.2-unwrap-red-flags` |
| L3.3 | Reading trait bounds and generics in signatures | DECODE | false | 15 | `L3.3-trait-bounds` |
| L3.4 | `impl` blocks and method syntax | DECODE | false | 15 | `L3.4-impl-methods` |
| L3.5 | Iterators — reading the chains AI loves to generate | PREDICT | false | 15 | `L3.5-iterator-chains` |
| L3.6 | Closures | PREDICT | false | 15 | `L3.6-closures` |
| L3.7 | `Vec` and `HashMap` patterns | DECODE | false | 15 | `L3.7-vec-hashmap` |
| L3.8 | `From` / `Into` / `TryFrom` — conversion literacy | DECODE | false | 15 | `L3.8-from-into-tryfrom` |
| L3.9 | Error taxonomy in real crates — thiserror/anyhow at reading level | DECODE | false | 15 | `L3.9-error-taxonomy` |
| L3.10 | Phase gate: read a real crate's public API and answer questions | DECODE | **true** | 20 | `L3.10-phase-gate-crate-api` |

Gate placement: the map marks L3.10 explicitly; no other gate.
recall.json placement: **L3.1 only** (5 questions, earlier phases, interleaved).

Phase security hook (map): L3.2 builds the first review reflex — `unwrap()` on
untrusted input is a denial of service waiting to happen. Woven through: panic
paths in indexing (L3.3, L3.7), silent truncation via `as` (L3.8, previewing
L4.4), and failure-in-the-types API reading (L3.10).

## 2. Binding harness constraints (unchanged — see rust-p2-plan.md §2)

Identical to Phase 2: check.sh never runs cargo/rustc (env -i fence); all grading
artifact-based and CI-fabricatable without a toolchain; lint bans as listed;
quiz.json exactly 3 / hints.json exactly 3 levels / recap.md exactly 3 lines /
lab.md exact headings; answers base64, text answers lowercase-normalized with
`accept_b64` variants; quiz stdin one line per question; recall non-gating at
`lab start` on the opener only.

## 3. Track conventions (carried + Phase-3 additions)

Carried unchanged from rust-p01-plan.md §3 and rust-p2-plan.md §3: `key=value`
answer files (`predictions.txt` PREDICT / `answers.txt` otherwise, options
printed in lab.md, anchored-ERE or fixed grading); PREDICT honor framing; broken
samples as separate `broken.rs` never inline; quiz-vs-answers non-duplication;
hints ladder L1 artifact → L2 exact line → L3 near-answer procedure; workspace
hygiene; ERE discipline — bracket characters in assert patterns MUST be escaped
(rust-p2-plan.md L2.5 builder note); descs/hints keep apostrophes and lifetime
ticks out.

New for Phase 3:
- **Build tool: bare `rustc` single files for every COMPILED lab.** Nothing here
  needs cargo. All samples edition-independent `[VERIFY-AT-BUILD: compile every
  file with plain rustc, no flags]`.
- **Read-only exhibits extended** (L2.8 precedent): L3.9's excerpt depends on
  third-party crates (thiserror/anyhow) and L3.10's is a transcription of a real
  crate's API — **neither is ever compiled**; no dependency is ever fetched
  anywhere in the track. Their labs grade reading via answers.txt only.
- **Panic-capture convention** (extends p2's rejection-evidence convention to
  runtime): when a lab detonates a real panic on purpose, the learner captures
  it: `./binary <crafted-arg> 2> panicN.txt` (non-zero exit expected — lab.md
  says so), and check.sh greps `panicN.txt` for the panic marker.
- **Closure/iterator values in predictions** follow Debug formatting exactly as
  printed (`true`, not `True`); lab.md states the vocabulary per key as p01 did.

## 4. Lab entries

---

### L3.1 — `Result` and the `?` operator
**DECODE · gate:false · est 15 · files/: sample.rs, broken.rs · recall.json: YES (phase opener)**
**objective:** "Read Result as an ordinary enum and `?` as a visible early return, and prove `?` refuses to run in a function whose return type can't absorb the error."

**recall.json — 5 questions, sourced from the curriculum map's Phase 0–2 lab
lists (nothing built at plan time). ALL FIVE `[VERIFY-AT-BUILD]`: refine wording
against the real built labs before shipping.**
1. choice (source: "rust L2.1 — move semantics") — "After `let b = a;` where a is
   a String, `a` is…" a) still usable b) compile-time dead — it moved c) null →
   **b**
2. choice (source: "rust L2.4 — aliasing XOR mutation") — "The borrow law allows…"
   a) many readers XOR one writer b) one reader and one writer together c) any
   mix → **a**
3. choice (source: "rust L2.8 — the C++ crime scene") — "C++'s use-after-free
   (CWE-416) becomes what in safe Rust?" a) a runtime panic b) a compile error
   c) undefined behavior → **b**
4. choice (source: "rust L1.7 — match exhaustiveness") — "A match missing one
   enum variant…" a) fails to compile (E0004) b) runs the first arm c) panics →
   **a**
5. choice (source: "rust L1.2 — overflow debug vs release") — "u8 overflow in a
   *release* build…" a) panics b) wraps silently c) refuses to compile → **b**

**files/sample.rs:**
```rust
use std::num::ParseIntError;

fn parse_port(raw: &str) -> Result<u16, ParseIntError> {
    let port: u16 = raw.trim().parse()?;
    Ok(port)
}

fn describe(raw: &str) -> String {
    match parse_port(raw) {
        Ok(port) => format!("{raw} -> port {port}"),
        Err(err) => format!("{raw} -> refused ({err})"),
    }
}

fn main() {
    println!("{}", describe("443"));
    println!("{}", describe("70000"));
    println!("{}", describe("http"));
}
```
Expected output `[VERIFY-AT-BUILD: exact std error Display strings]`:
`443 -> port 443` / `70000 -> refused (number too large to fit in target type)` /
`http -> refused (invalid digit found in string)`.
Teaching beats: Result<T, E> is an ordinary enum — Ok(T) | Err(E); `?` reads "on
Err, return it to MY caller right now; on Ok, hand me the value" — a visible
early return, no invisible control flow; errors are values with Display
messages; fallibility is declared in the signature (contrast with exceptions).
One lab.md note: `main` itself may be declared `fn main() -> Result<(), E>` —
this sample keeps main infallible on purpose.

**files/broken.rs:**
```rust
fn read_flag(input: &str) -> u32 {
    let value: u32 = input.parse()?;
    value
}

fn main() {
    println!("{}", read_flag("7"));
}
```
Must fail because `?` sits in a function returning plain `u32` — expected
**E0277** ("the `?` operator can only be used in a function that returns
`Result` or `Option`") `[VERIFY-AT-BUILD: code + message — moderate confidence;
if rustc reports differently, fix content to reality]`.

**GUIDED STEPS outline:** read → compile/run sample → answers.txt (options in
lab.md): q1 (choice) `?` on Err: a) panics b) returns the Err to parse_port's
caller immediately c) logs and continues → `q1=b`; q2 (choice) `?` on Ok:
a) unwraps the value into `port` b) returns early c) clones → `q2=a`; q3 (value)
the port number in the first output line → `q3=443`; q4 (choice) why can't a
()-returning main use `?` on parse_port? a) it can b) `?` early-returns the Err,
so the enclosing return type must be able to hold it — () cannot c) `?` is
method-only → `q4=b` → `rustc broken.rs`, record `error=E0277` → check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=a$'`,
`'^q3=443$'`, `'^q4=b$'`, `'^error=E0277$'`;
`assert_output_contains 'sample ok path' '443 -> port 443' 'step 2 — rustc
sample.rs -o sample' -- ./sample`; `ck_summary`.
(CI fabrication: echo answer lines; `#!/bin/sh` stub printing the three lines.)

**QUIZ:**
1. choice — "Result<T, E> is…" a) a compiler intrinsic b) an ordinary enum:
   Ok(T) | Err(E) — nothing magic c) a wrapper around exceptions → **b**
2. choice — "The audit advantage of `?` over exceptions:" a) none b) every
   fallible call is visibly marked at the call site and declared in the
   signature — no invisible control flow c) it is faster → **b**
3. text — "Name the two variants of Result." → **ok and err** (accept: `ok err`,
   `ok, err`, `ok/err`)

**RECAP:**
```
Result is just an enum — errors are values that travel through return types
? reads as: on Err return it to my caller now; on Ok hand me the inner value
fallibility lives in signatures — every risky call is marked where it happens
```

**HINTS:** L1: five answer keys — the grader names each miss; options are in
step 3. L2: q1/q2 are the two halves of the `?` contract stated in the BRIEF;
q3 traces "443" through parse; the error code comes off `rustc broken.rs`. L3:
run and transcribe — `rustc sample.rs -o sample; ./sample; rustc broken.rs`.

---

### L3.2 — `unwrap` / `expect` / `panic!` — red flags in review
**AUDIT · gate:false · est 15 · files/: ingest.rs**
**objective:** "Count the panic paths in a working tool, judge which ones untrusted input can reach, and detonate one for real — the unwrap-is-DoS review reflex."

**files/ingest.rs (compiles clean; that is the point):**
```rust
// ingest.rs — a tiny event-line ingester. It compiles. That is not the same
// as safe. Count the ways input can kill this process.
fn main() {
    let line = std::env::args().nth(1).unwrap();
    let (kind, size) = line.split_once(':').unwrap();
    let size: u32 = size.parse().unwrap();
    let tag = kind.get(..4).expect("kind at least 4 bytes");
    println!("{tag} accepted ({size} bytes)");
}
```
Happy path `[VERIFY-AT-BUILD]`: `./ingest "scan:512"` → `scan accepted (512
bytes)`. Panic inventory (the answer key): **4 sites** — three `unwrap` + one
`expect`. Reachable by a crafted argument *value* (argument present but hostile):
**3** — no `:` (split_once → None), non-numeric size (parse → Err), kind shorter
than 4 bytes (get(..4) → None). The `args().nth(1).unwrap()` site is
operator-reachable (missing argument), not value-crafted — lab.md teaches the
distinction (reachability judgment, not just grep counting).
Detonation (graded artifact): `./ingest "scan-512" 2> panic1.txt` — expected
panic text contains `called` / `unwrap()` / `None` `[VERIFY-AT-BUILD: exact
message; check greps the stable word 'panicked']`; non-zero exit expected,
lab.md says so.

**GUIDED STEPS outline:** read ingest.rs → count sites, judge reachability →
`rustc ingest.rs -o ingest` → happy path run → detonate with `"scan-512"`,
capture panic1.txt → answers.txt (options in lab.md):
- q1 (value) total panic-capable call sites → `q1=4`
- q2 (value) sites reachable by a crafted argument value → `q2=3`
- q3 (choice) the security class of unwrap-on-untrusted-input: a) memory
  corruption b) denial of service — one request kills the process (CWE-248,
  uncaught exception) c) privilege escalation → `q3=b`
- q4 (choice) honest take on `expect` vs `unwrap`: a) same crash, but the string
  documents the assumption — better forensics, same DoS b) expect handles the
  error c) expect only warns → `q4=a`
- q5 (choice) the fix direction: a) unwrap but log first b) make absence/failure
  a handled value — match, `?`, unwrap_or, with a policy per site c) catch the
  panic downstream → `q5=b`
→ check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=4$'`, `'^q2=3$'`,
`'^q3=b$'`, `'^q4=a$'`, `'^q5=b$'`;
`assert_file_contains panic1.txt 'panicked'` (hint: step 4 — the detonation
must capture stderr: `2> panic1.txt`);
`assert_output_contains 'ingest happy path' 'scan accepted \(512 bytes\)'
'step 3 — rustc ingest.rs -o ingest, then run with scan:512' -- ./ingest
scan:512` (parens escaped — assert patterns are ERE);
`ck_summary`.
(CI fabrication: echo answers; echo a 'panicked at' line into panic1.txt;
`#!/bin/sh` stub `./ingest` printing the happy-path line.)

**QUIZ:**
1. choice — "First grep sweep for panic paths reads for…" a) unwrap, expect,
   panic!, indexing/slicing — then judge each site's input reachability b) TODO
   comments c) unsafe blocks only → **a**
2. choice — "A panic in one request handler of a service means…" a) undefined
   behavior b) that worker/process dies — an availability loss, not memory
   corruption c) nothing, panics are caught automatically → **b**
3. text — "In a #[test], is unwrap() acceptable? (yes/no)" → **yes** (context is
   the whole judgment — tests want loud failure)

**RECAP:**
```
unwrap/expect/panic are crash-on-purpose: fine in tests, red flags on input paths
the review question is reachability: can attacker-shaped data arrive at this site?
fixes make failure a value with a policy — match, ?, unwrap_or; never catch-and-hope
```

**HINTS:** L1: five answer keys, panic1.txt, and a working ./ingest — the grader
names each miss. L2: count every unwrap AND the expect for q1; for q2 exclude
the one only a missing argument (operator error) can trigger; detonate with an
argument that has no colon. L3: exact commands — `rustc ingest.rs -o ingest;
./ingest "scan:512"; ./ingest "scan-512" 2> panic1.txt`.

---

### L3.3 — Reading trait bounds and generics in signatures
**DECODE · gate:false · est 15 · files/: sample.rs, broken.rs**
**objective:** "Read `<T: Bound + Bound>` as a capability list that predicts which call sites compile, and read E0277 when a concrete type misses a bound."

**files/sample.rs:**
```rust
use std::fmt::Display;

fn render<T: Display>(items: &[T]) -> String {
    let mut out = String::new();
    for item in items {
        out.push_str(&format!("[{item}]"));
    }
    out
}

fn largest<T: PartialOrd + Copy>(items: &[T]) -> T {
    let mut best = items[0];
    for &item in &items[1..] {
        if item > best {
            best = item;
        }
    }
    best
}

fn main() {
    let ports = [443u16, 22, 8443];
    println!("{}", render(&ports));
    println!("largest = {}", largest(&ports));

    let names = [String::from("ids"), String::from("edr")];
    println!("{}", render(&names));
}
```
Expected output `[VERIFY-AT-BUILD]`: `[443][22][8443]` / `largest = 8443` /
`[ids][edr]`.
Teaching beats: a bound is a *capability list* — the body may do exactly what
the bounds grant (Display → format it; PartialOrd → compare; Copy → move out of
the borrowed slice by duplicating); reading bounds predicts call-site fate:
String has Display and PartialOrd but not Copy, so render(&names) compiles and
largest(&names) cannot; one panic-path line (L3.2 crossover): `items[0]` panics
on an empty slice — bounds say nothing about emptiness.

**files/broken.rs (same `largest`, called on String):**
```rust
fn largest<T: PartialOrd + Copy>(items: &[T]) -> T {
    let mut best = items[0];
    for &item in &items[1..] {
        if item > best {
            best = item;
        }
    }
    best
}

fn main() {
    let names = [String::from("ids"), String::from("edr")];
    println!("{}", largest(&names));
}
```
Must produce **E0277** — "the trait bound `String: Copy` is not satisfied"
`[VERIFY-AT-BUILD: message line]`.

**GUIDED STEPS outline:** read → compile/run sample → answers.txt (options in
lab.md): q1 (choice) `<T: Display>` means a) T is a string type b) any T the
body may format — the bound grants exactly that capability c) T prints only in
debug builds → `q1=b`; q2 (choice) why largest needs Copy: a) speed b) `best =
items[0]` must duplicate out of a borrowed slice — without Copy that is a move
out of a borrow c) convention → `q2=b`; q3 (value) largest(&ports) → `q3=8443`;
q4 (value) broken.rs error code → `q4=E0277`; q5 (choice) which bound does
String fail? a) PartialOrd b) Copy c) Display → `q5=b` → `rustc broken.rs` →
check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=b$'`,
`'^q3=8443$'`, `'^q4=E0277$'`, `'^q5=b$'`;
`assert_output_contains 'sample runs' 'largest = 8443' 'step 2 — rustc
sample.rs -o sample' -- ./sample`; `ck_summary`.

**QUIZ:**
1. choice — "A trait bound is best read as…" a) an inheritance tree b) a
   capability contract: the body may use exactly what the bounds grant, nothing
   more c) a performance annotation → **b**
2. choice — "Where does a bound violation surface?" a) at the offending call
   site, at compile time, naming the missing trait (E0277) b) at runtime c) at
   link time → **a**
3. text — "The symbol that stacks multiple bounds on one type parameter." →
   **+** (accept: `plus`, `plus sign`)

**RECAP:**
```
bounds are capability lists: T: Display + Copy is everything the body may do with T
read signatures bounds-first — they predict which call sites can even compile
E0277 names the missing trait at the call site; the fix is the caller's type, not luck
```

**HINTS:** L1: five answer keys — options in step 3. L2: for q2 ask what
`let mut best = items[0]` does to a slice element when T can't copy (Phase 2's
move rule inside a generic); q3 compares three numbers; q4 comes off the broken
compile. L3: run and transcribe — `rustc sample.rs -o sample; ./sample; rustc
broken.rs`.

---

### L3.4 — `impl` blocks and method syntax
**DECODE · gate:false · est 15 · files/: sample.rs**
**objective:** "Read an impl block through its receivers — &self reads, &mut self writes, self consumes — and recognize method calls as sugar over Phase-2 ownership rules."

**files/sample.rs:**
```rust
struct Tally {
    hits: u32,
    label: String,
}

impl Tally {
    fn new(label: &str) -> Self {
        Tally { hits: 0, label: String::from(label) }
    }

    fn record(&mut self) {
        self.hits += 1;
    }

    fn report(&self) -> String {
        format!("{}: {} hits", self.label, self.hits)
    }

    fn into_label(self) -> String {
        self.label
    }
}

fn main() {
    let mut auth = Tally::new("failed-auth");
    auth.record();
    auth.record();
    auth.record();
    println!("{}", auth.report());

    let label = auth.into_label();
    println!("archived: {label}");

    // step 4 experiment: add another auth.report() call HERE, recompile,
    // read the error, then remove it again.
}
```
Expected output `[VERIFY-AT-BUILD]`: `failed-auth: 3 hits` /
`archived: failed-auth`.
Teaching beats: impl separates behavior from data; the receiver is the contract
— `&self` reads, `&mut self` writes (requires a `mut` binding), bare `self`
consumes (into_label moves auth — after it, auth is dead: Phase 2's move rule
wearing method clothes); `new` is a convention, not a keyword — any associated
function returning Self constructs; `auth.record()` is sugar for
`Tally::record(&mut auth)`.
Graded experiment (revert protocol per L1.4/L2.7): a report() call after
into_label must produce **E0382** `[VERIFY-AT-BUILD: "borrow of moved value"]`.

**GUIDED STEPS outline:** read → compile/run → the experiment: add
`println!("{}", auth.report());` at the marked line, `rustc sample.rs` fails —
record the code — remove it, recompile → answers.txt (options in lab.md):
q1 (choice) why does record take `&mut self`? a) it mutates a field — writer
access b) speed c) style → `q1=a`; q2 (choice) bare `self` in into_label means:
a) borrow b) the call consumes the value — auth is moved, dead afterward
c) copy → `q2=b`; q3 (value) the report line printed → `q3=failed-auth: 3 hits`;
q4 (value) the experiment's error code → `q4=E0382`; q5 (choice)
`auth.record()` desugars to: a) `Tally::record(&mut auth)` b) `record(auth)`
c) `auth::record()` → `q5=a` → check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=a$'`, `'^q2=b$'`,
`'^q4=E0382$'`, `'^q5=a$'`;
`assert_file_contains_fixed answers.txt 'q3=failed-auth: 3 hits'`;
`assert_output_contains 'sample runs (experiment reverted)' 'archived:
failed-auth' 'step 4 — remove the extra report() call and recompile' --
./sample`; `ck_summary`.

**QUIZ:**
1. choice — "The receiver spectrum, in order &self / &mut self / self:"
   a) read / write / consume b) fast / slow / unsafe c) public / private /
   internal → **a**
2. choice — "`new` in Rust is…" a) a keyword the compiler treats specially
   b) a naming convention — any associated function returning Self is a
   constructor c) generated automatically → **b**
3. text — "To call a &mut self method, the binding must be declared with which
   keyword?" → **mut**

**RECAP:**
```
impl separates behavior from data; method calls are sugar for Type::method(recv)
the receiver is the contract: &self reads, &mut self writes, self consumes
consuming methods are moves — Phase 2's ownership rules apply unchanged here
```

**HINTS:** L1: five answer keys; q4 requires actually doing the experiment.
L2: the receiver of each method answers q1/q2; q3 is three record() calls
formatted through report's template; the experiment error is Phase 2's
use-after-move code. L3: add the marked call, `rustc sample.rs`, read the
`error[E....]` tag, remove it, recompile with `-o sample`.

---

### L3.5 — Iterators — reading the chains AI loves to generate
**PREDICT · gate:false · est 15 · files/: sample.rs**
**objective:** "Predict the output of adapter chains — filter/map/collect and friends — and read the extra & that closure parameters stack on."

**files/sample.rs:**
```rust
fn main() {
    let ports: Vec<u32> = vec![21, 22, 443, 8080, 9200];

    let total: u32 = ports.iter().sum();
    println!("total = {total}");

    let high: Vec<u32> = ports.iter().copied().filter(|p| *p > 1000).collect();
    println!("high = {high:?}");

    let doubled: Vec<u32> = high.iter().map(|p| p * 2).collect();
    println!("doubled = {doubled:?}");

    let low_count = ports.iter().filter(|p| **p < 100).count();
    println!("low_count = {low_count}");

    let lazy = ports.iter().map(|p| p * 10);
    println!("adapters built, nothing computed yet");
    let scaled: Vec<u32> = lazy.collect();
    println!("first = {}", scaled[0]);
}
```
Expected output `[VERIFY-AT-BUILD]`: `total = 17766` / `high = [8080, 9200]` /
`doubled = [16160, 18400]` / `low_count = 2` / `adapters built, nothing computed
yet` / `first = 210`.
Teaching beats: read chains left→right: source → lazy adapters → ONE terminal op
(sum/collect/count) that actually pulls; `.iter()` yields `&u32`, `.copied()`
flattens to `u32`, and `filter` hands its closure a reference to the item — so
over `.iter()` the filter param is `&&u32`, hence `**p` (the count-the-&s
heuristic — the single most common stumble when reading AI-generated chains);
arithmetic like `p * 2` auto-derefs; laziness: the `lazy` binding computes
nothing until `.collect()`.

**GUIDED STEPS outline:** read (honor framing) → `predictions.txt` keys with
vocabulary given in lab.md: `total=` (the sum), `hi=` (first element of high),
`low_count=`, `first=` (the value printed last) → compile/run → compare →
check.
Answers: `total=17766`, `hi=8080`, `low_count=2`, `first=210`.

**CHECK LOGIC:** `assert_file_contains predictions.txt '^total=17766$'`,
`'^hi=8080$'`, `'^low_count=2$'`, `'^first=210$'`;
`assert_output_contains 'sample runs' 'doubled = \[16160, 18400\]' 'step 3 —
rustc sample.rs -o sample' -- ./sample` (brackets escaped per ERE discipline);
`ck_summary`.

**QUIZ:**
1. choice — "Adapter chains execute…" a) eagerly, one full pass per adapter
   b) lazily — nothing runs until a terminal op (collect/sum/count) pulls items
   through c) on background threads → **b**
2. choice — "`.iter()` over a Vec<u32> yields…" a) u32 values b) &u32 borrows —
   `.copied()` is what turns them back into plain u32 c) boxed values → **b**
3. text — "Name one *terminal* (consuming) method used in this lab." →
   **collect** (accept: `sum`, `count`)

**RECAP:**
```
read chains left to right: source → lazy adapters (filter/map) → one terminal op
.iter() lends &T and filter adds another & — count the ampersands, then the stars
nothing computes until collect/sum/count pulls; laziness is why chains compose free
```

**HINTS:** L1: four prediction keys — the grader names each miss; vocabulary per
key is in step 2. L2: total is a plain sum of five numbers; `hi` — which ports
survive `> 1000`?; low_count — how many are `< 100`?; first = 21 × 10. L3: run
it and transcribe: `rustc sample.rs -o sample; ./sample`.

---

### L3.6 — Closures
**PREDICT · gate:false · est 15 · files/: sample.rs, broken.rs**
**objective:** "Predict capture behavior — by-reference, by-mutable-reference, and move — and read E0382 when a move closure takes a variable away."

**files/sample.rs:**
```rust
fn main() {
    let threshold = 100;
    let is_high = |v: u32| v > threshold;
    println!("is_high(150) = {}", is_high(150));
    println!("threshold still = {threshold}");

    let mut streak = 0;
    let mut bump = || streak += 1;
    bump();
    bump();
    bump();
    println!("streak = {streak}");

    let tag = String::from("scan");
    let label = move |v: u32| format!("{tag}:{v}");
    println!("{}", label(9));
    println!("{}", label(10));
}
```
Expected output `[VERIFY-AT-BUILD]`: `is_high(150) = true` /
`threshold still = 100` / `streak = 3` / `scan:9` / `scan:10`.
Teaching beats: closures capture their environment automatically — by the
lightest borrow that works (is_high only reads threshold → shared borrow;
threshold stays usable); a closure that mutates a capture holds a &mut and its
OWN binding needs `mut` (`let mut bump`); `move` transfers ownership of captures
into the closure — required when the closure must outlive the scope (threads —
Phase 5 foreshadow, one line); a move closure that only *reads* its captures is
still callable many times (label runs twice).

**files/broken.rs:**
```rust
fn main() {
    let tag = String::from("scan");
    let label = move |v: u32| format!("{tag}:{v}");
    println!("{}", label(7));
    println!("tag = {tag}");
}
```
Must produce **E0382** — borrow of moved value: `tag` (moved into the closure)
`[VERIFY-AT-BUILD: message line]`.

**GUIDED STEPS outline:** read → `predictions.txt`: `high=true` (what
is_high(150) prints), `threshold=100`, `streak=3`, then compile/run →
`rustc broken.rs`, record `error=E0382` → check.

**CHECK LOGIC:** `assert_file_contains predictions.txt '^high=true$'`,
`'^threshold=100$'`, `'^streak=3$'`, `'^error=E0382$'`;
`assert_output_contains 'sample runs' 'scan:10' 'step 3 — rustc sample.rs -o
sample' -- ./sample`; `ck_summary`.

**QUIZ:**
1. choice — "Default capture mode:" a) always by move b) the lightest borrow
   that works — shared if reading, mutable if writing, move only with the
   keyword c) always by copy → **b**
2. choice — "`move` exists because…" a) closures are faster that way b) a
   closure that outlives its scope (thread, returned value) cannot hold borrows
   into that scope — it must own its captures c) borrows are deprecated → **b**
3. text — "Which closure trait is call-at-most-once because calling consumes
   its captures?" → **fnonce** (accept: `fn once`, `fnonce()`)

**RECAP:**
```
closures capture the environment by the lightest borrow that works — or own it with move
a closure that mutates a capture needs mut on ITS OWN binding — the &mut lives in it
Fn / FnMut / FnOnce describe what calling does to captures: read / write / consume
```

**HINTS:** L1: four prediction keys — the grader names the miss. L2: is_high
only *reads* threshold, so threshold survives; streak counts the bump() calls;
the broken file's tag moved INTO the closure — the later println is Phase 2's
use-after-move. L3: run and transcribe — `rustc sample.rs -o sample; ./sample;
rustc broken.rs`.

---

### L3.7 — `Vec` and `HashMap` patterns
**DECODE · gate:false · est 15 · files/: sample.rs**
**objective:** "Read the entry/or_insert counting idiom, the panic-vs-Option split between indexing and .get, and why HashMap output must be sorted before asserting."

**files/sample.rs:**
```rust
use std::collections::HashMap;

fn main() {
    let events = ["login", "scan", "login", "probe", "login"];

    let mut counts: HashMap<&str, u32> = HashMap::new();
    for event in events {
        *counts.entry(event).or_insert(0) += 1;
    }

    println!("login = {}", counts["login"]);
    println!("scan = {}", counts.get("scan").copied().unwrap_or(0));
    println!("ghost = {}", counts.get("ghost").copied().unwrap_or(0));

    let mut kinds: Vec<&str> = counts.keys().copied().collect();
    kinds.sort();
    println!("kinds = {kinds:?}");
}
```
Expected output `[VERIFY-AT-BUILD]`: `login = 3` / `scan = 1` / `ghost = 0` /
`kinds = ["login", "probe", "scan"]`.
Teaching beats: `*counts.entry(k).or_insert(0) += 1` — the get-or-create
counting idiom AI reaches for constantly (entry returns a slot; or_insert fills
it if vacant; the `*` writes through); indexing (`counts["login"]`) PANICS on a
missing key — assertive access; `.get` returns Option and the None policy is
explicit (`unwrap_or(0)`) — on untrusted keys that difference is uptime (L3.2
crossover); HashMap iteration order is unspecified and varies run to run — sort
before printing, asserting, or diffing (real flaky-detection-logic beat).

**GUIDED STEPS outline:** read → compile/run → answers.txt (options in lab.md):
q1 (choice) the entry line reads as: a) insert 0 every time b) get-or-create the
slot at 0, then increment in place c) panic if absent → `q1=b`; q2 (value) login
count → `q2=3`; q3 (choice) why `.get` + unwrap_or for ghost instead of
`counts["ghost"]`? a) style b) indexing panics on missing keys; get makes the
None policy explicit c) get is faster → `q3=b`; q4 (choice) why sort kinds?
a) HashMap iteration order is unspecified — unsorted output cannot be asserted
or diffed b) collect requires it c) alphabetical is faster → `q4=a`; q5 (value)
the ghost number printed → `q5=0` → check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=3$'`,
`'^q3=b$'`, `'^q4=a$'`, `'^q5=0$'`;
`assert_output_contains 'sample runs, sorted keys' 'kinds = \["login", "probe",
"scan"\]' 'step 2 — rustc sample.rs -o sample' -- ./sample` (brackets escaped);
`ck_summary`.

**QUIZ:**
1. choice — "`map[key]` on a missing key…" a) returns a default b) panics —
   indexing is the assertive spelling c) inserts and returns 0 → **b**
2. choice — "Reviewer flag: `counts[user_supplied]` in a service means…"
   a) nothing b) an attacker-chosen absent key is a panic — a one-request DoS;
   want .get with an explicit policy c) a type error → **b**
3. text — "The HashMap method returning Option<&V> instead of panicking." →
   **get** (accept: `.get`, `get()`)

**RECAP:**
```
entry(k).or_insert(0) += 1 — the get-or-create counting idiom; the * writes through
indexing panics, .get returns Option — on untrusted keys that difference is uptime
HashMap order is unspecified: sort before you print, assert, or diff anything
```

**HINTS:** L1: five answer keys — options in step 3. L2: count the "login"
occurrences in the array for q2; ghost isn't in the map, so unwrap_or supplies
q5; q4's answer is the reason the sample calls .sort() at all. L3: run and
transcribe — `rustc sample.rs -o sample; ./sample`.

---

### L3.8 — `From` / `Into` / `TryFrom` — conversion literacy
**DECODE · gate:false · est 15 · files/: sample.rs**
**objective:** "Read the three conversion spellings — infallible From/Into, fallible TryFrom, and silently-truncating `as` — and compute what each does to 70000."

**files/sample.rs:**
```rust
fn main() {
    let small: u16 = 8443;
    let wide: u32 = u32::from(small);
    let wide2: u32 = small.into();
    println!("wide = {wide}, wide2 = {wide2}");

    let big: u32 = 70000;
    match u16::try_from(big) {
        Ok(port) => println!("fits: {port}"),
        Err(err) => println!("refused: {err}"),
    }

    let clamped = u16::try_from(big).unwrap_or(u16::MAX);
    println!("clamped = {clamped}");

    let truncated = big as u16;
    println!("truncated = {truncated}");
}
```
Expected output `[VERIFY-AT-BUILD: std error Display string]`:
`wide = 8443, wide2 = 8443` / `refused: out of range integral type conversion
attempted` / `clamped = 65535` / `truncated = 4464`.
Teaching beats: widening (u16→u32) cannot fail → `From`, and one From impl
gives `.into()` free (the annotation on `wide2` is what picks the target);
narrowing (u32→u16) can fail → `TryFrom` returns Result and forces a policy
(match it, or unwrap_or a clamp); `as` NEVER fails — it truncates modulo 2^16
silently: 70000 as u16 = 70000 − 65536 = **4464**, no warning — the CWE-197
numeric-truncation preview of L4.4; reviewer rule: `as` on untrusted sizes is a
flag, `try_from` is a policy.

**GUIDED STEPS outline:** read → compile/run → answers.txt (options in lab.md):
q1 (choice) the From/TryFrom split: a) widening = From (cannot fail), narrowing
= TryFrom (Result) b) interchangeable c) TryFrom is legacy → `q1=a`; q2 (value)
wide2 → `q2=8443`; q3 (value) clamped → `q3=65535`; q4 (value) truncated →
`q4=4464`; q5 (choice) why is `as` the review flag: a) it is slow b) it has no
failure path — overflow truncates silently; try_from makes overflow an explicit
decision c) it is unsafe-only → `q5=b` → check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=a$'`, `'^q2=8443$'`,
`'^q3=65535$'`, `'^q4=4464$'`, `'^q5=b$'`;
`assert_output_contains 'sample runs' 'truncated = 4464' 'step 2 — rustc
sample.rs -o sample' -- ./sample`; `ck_summary`.

**QUIZ:**
1. choice — "Implementing From<A> for B also gives you…" a) nothing else
   b) `a.into()` — Into is the mirror trait, one impl serves both spellings
   c) TryFrom automatically → **b**
2. choice — "`70000_u32 as u16` evaluates to…" a) 65535 — clamped b) 4464 —
   truncation modulo 65536, silently c) a compile error → **b**
3. text — "Which conversion trait returns a Result?" → **tryfrom** (accept:
   `try_from`, `tryinto`, `try_into`)

**RECAP:**
```
From/Into = infallible; TryFrom/TryInto = fallible with a Result you must handle
as never fails — it truncates silently: 70000 as u16 is 4464, zero complaints
review rule: as on untrusted numbers is a flag; try_from turns overflow into policy
```

**HINTS:** L1: five answer keys — options in step 3. L2: wide2 follows the same
conversion as wide; clamped is unwrap_or's fallback (what is u16::MAX?);
truncated = 70000 − 65536. L3: run and transcribe — `rustc sample.rs -o sample;
./sample`.

---

### L3.9 — Error taxonomy in real crates — thiserror/anyhow at reading level
**DECODE · gate:false · est 15 · files/: excerpt.rs (read-only exhibit)**
**objective:** "Read the two-layer error idiom of real crates cold: thiserror's typed library enums and anyhow's application-level context chains."

**files/excerpt.rs (READ-ONLY EXHIBIT — depends on thiserror/anyhow; never
compiled in this lab; banner comment says so — L2.8 precedent):**
```rust
// excerpt.rs — READ-ONLY EXHIBIT (depends on thiserror/anyhow; not compiled
// here). Read it like a reviewer: two layers, two error styles.

// ---- library layer: feedparse/src/lib.rs ----
use thiserror::Error;

#[derive(Debug, Error)]
pub enum FeedError {
    #[error("malformed header at byte {0}")]
    BadHeader(usize),
    #[error("unsupported version {found} (max {max})")]
    Version { found: u8, max: u8 },
    #[error("io failure reading feed")]
    Io(#[from] std::io::Error),
}

pub fn parse_feed(raw: &[u8]) -> Result<Vec<Indicator>, FeedError> {
    // ... (body elided — the signatures are the lesson)
}

// ---- application layer: src/main.rs ----
use anyhow::{Context, Result};

fn run() -> Result<()> {
    let raw = std::fs::read("feed.bin").context("reading feed.bin")?;
    let indicators = parse_feed(&raw).context("parsing threat feed")?;
    println!("{} indicators", indicators.len());
    Ok(())
}
```
Teaching beats: **libraries** define typed error enums; `#[derive(Error)]` +
`#[error("...")]` generate the Display messages from the attribute templates;
`#[from]` derives `From<std::io::Error> for FeedError` — which is exactly what
lets `?` convert and cross layers; **applications** flatten into
`anyhow::Result` (a dynamic catch-all) and add `.context(...)` breadcrumbs for
the final report; the reading rule: `Result<T, ConcreteError>` = library code
callers can match on; `anyhow::Result<T>` = application code that reports.
All attribute semantics `[VERIFY-AT-BUILD: check against thiserror/anyhow docs
at current versions; adjust wording if the crates changed]`.

**GUIDED STEPS outline:** read the exhibit top to bottom (nothing to compile —
lab.md says so explicitly) → answers.txt (options in lab.md):
q1 (choice) `#[error("...")]` generates: a) the Display message for that
variant, from the template b) a panic handler c) a log statement → `q1=a`;
q2 (choice) `#[from]` on Io: a) derives From<std::io::Error> so `?` converts
io errors into FeedError automatically b) reads the file c) retries → `q2=a`;
q3 (choice) anyhow belongs in: a) libraries b) applications — callers who
report errors rather than match on them c) both equally, always → `q3=b`;
q4 (value) the exact Display text for `BadHeader(12)` → `q4=malformed header at
byte 12`; q5 (choice) `.context("...")` adds: a) a breadcrumb layered onto the
error chain, shown in the final report b) a retry policy c) a log line at call
time → `q5=a` → check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=a$'`, `'^q2=a$'`,
`'^q3=b$'`, `'^q5=a$'`;
`assert_file_contains_fixed answers.txt 'q4=malformed header at byte 12'`;
`ck_summary`. (Pure-reading lab: answers.txt is the only artifact — no binary,
nothing compiled; decision logged in §6.)

**QUIZ:**
1. choice — "You see `-> Result<Config, ConfigError>` vs `-> anyhow::Result
   <Config>` — what do they tell you?" a) nothing b) the first is library-style
   (callers can match variants); the second is app-style (callers report) c) the
   second is faster → **b**
2. choice — "What is LOST by flattening into anyhow?" a) nothing b) callers can
   no longer match on specific variants — fine for apps, wrong for libraries
   c) the error message → **b**
3. text — "Which crate derives Display from #[error(...)] attribute templates?"
   → **thiserror**

**RECAP:**
```
libraries: typed enums + thiserror — callers match; #[from] powers cross-layer ?
applications: anyhow::Result + .context breadcrumbs — report chains, not matches
read the return type first: it names the layer and tells you what ? will do
```

**HINTS:** L1: five answer keys, all answered from the exhibit text — nothing
needs to run. L2: q4 substitutes 12 into the BadHeader attribute template
exactly; q1/q2 are what the two attributes generate (stated in the BRIEF).
L3: re-read the BRIEF's two-layer rule and the three #[...] attribute lines —
each answer is one of those lines restated.

---

### L3.10 — Phase gate: read a real crate's public API and answer questions
**DECODE · gate:TRUE · est 20 · files/: regex-api.txt (read-only exhibit)**
**objective:** "Prove Phase 3: read the regex crate's real public API cold and answer 10 questions from the signatures alone — Result constructors, Option lookups, lifetimes, and panic paths."

**files/regex-api.txt:** a vendored transcription of the public API surface of
the **regex** crate (pinned: the current stable release at build time; record
the version number in the file header). Contents: the signatures + one-line doc
summaries for: `Regex::new(re: &str) -> Result<Regex, Error>`;
`Regex::is_match(&self, haystack: &str) -> bool`;
`Regex::find<'h>(&self, haystack: &'h str) -> Option<Match<'h>>`;
`Regex::captures<'h>(&self, haystack: &'h str) -> Option<Captures<'h>>`;
`Match::as_str(&self) -> &'h str`; `Match::start(&self) -> usize`;
`Captures::get(&self, i: usize) -> Option<Match<'h>>`; the `Index<usize>` impl
on Captures (panics on absent/non-participating group); plus the crate's
documented **linear-time guarantee** line (no catastrophic backtracking by
design) and its note that `Regex::new` rejects invalid patterns with Err.
`[VERIFY-AT-BUILD: transcribe every signature and doc line from the real crate
docs at the pinned version — no signature in the shipped file may be
paraphrased from memory]`.

**The 10 questions** (options printed in lab.md; answers ride answers.txt per
L1.9/L2.10 precedent — quiz.json stays capped at 3; honor contract restated:
answer from the signatures before consulting anything else):
1. choice — can constructing a Regex fail? a) no b) yes — new returns
   Result<Regex, Error> c) only at match time → `q1=b`
2. choice — is_match returns/borrows: a) it consumes the regex b) bool, borrowing
   both the regex and the haystack — no ownership changes c) Option<bool> →
   `q2=b`
3. choice — the `'h` on find ties the returned Match to: a) the Regex b) the
   haystack — the match is a borrowed view into the searched text c) 'static →
   `q3=b` (the Phase-2 payoff question)
4. value — captures() when nothing matches returns → `q4=None`
5. choice — `caps[5]` for a group that didn't participate: a) returns "" b)
   panics — the Index impl is the assertive spelling c) returns None → `q5=b`
6. value — the panic-free spelling of caps[i] → `q6=get`
7. choice — an attacker-supplied *pattern* fed to Regex::new: a) catastrophic
   backtracking DoS b) invalid patterns are rejected with Err, and matching is
   linear-time by design — remaining concern is compile cost/size limits, not
   backtracking c) undefined behavior → `q7=b` `[VERIFY-AT-BUILD: this is the
   regex crate's documented design; confirm the doc line and keep the wording
   aligned with it]`
8. choice — as_str returns &'h str rather than String because: a) Strings are
   slow b) it is a zero-copy view into the haystack — no allocation, lifetime
   says so c) legacy API → `q8=b`
9. value — which method gives the byte offset where a Match starts → `q9=start`
10. choice — the API's overall failure philosophy: a) panic everywhere
    b) constructors return Result, lookups return Option, panics only behind
    the explicitly assertive Index spelling — failure lives in the types →
    `q10=b`

**GUIDED STEPS outline:** read regex-api.txt cold → answer all 10 from the
signatures (honor framing) → check. Nothing compiles in this lab (§6 decision —
the gate skill is API reading, exactly as the map states it).

**CHECK LOGIC:** ten anchored greps on answers.txt (`'^q1=b$'`, `'^q2=b$'`,
`'^q3=b$'`, `'^q4=None$'`, `'^q5=b$'`, `'^q6=get$'`, `'^q7=b$'`, `'^q8=b$'`,
`'^q9=start$'`, `'^q10=b$'`); `ck_summary`.
(CI fabrication: echo ten lines.)

**QUIZ (concept-level, not duplicating the 10):**
1. choice — "The first three things to read in an unknown API:" a) the README
   badges b) constructor Result-ness, lookup Option-ness, and lifetimes tying
   outputs to inputs c) the license → **b**
2. choice — "A lifetime parameter in a public API (Match<'h>) tells users…"
   a) internal implementation detail b) the output borrows from an input — keep
   that input alive while you hold the output c) the type is slow → **b**
3. text — "In API reading, a Result return type tells you the operation can
   ___." → **fail**

**RECAP:**
```
gate passed: a real crate's API read cold — Result ctors, Option lookups, 'h ties
lifetimes in public APIs are documentation: outputs that borrow name their source
Phase 4 next: where the guarantees end — unsafe, FFI, and what Rust cannot save
```

**HINTS:** L1: ten keys q1..q10 — the grader names the misses; every answer is
in regex-api.txt. L2: q1/q4/q5 are literally the return types; q3/q8 are what
`'h` means (Phase 2); q7 is the crate's own linear-time doc line, included in
the exhibit. L3: walk the exhibit signature by signature and transcribe — the
types ARE the answers.

---

## 5. Build-session protocol (execute in this order)

0. **Prerequisite: Phases 0–2 built first** (recall refinement + `lab`
   progression).
1. Scaffold the 10 lab directories under `tracks/rust/phases/p3/` per §1 slugs.
2. Author content straight from §4; base64 all answers; `accept_b64` variants as
   listed.
3. **Refine L3.1's recall.json** against the real built p0–p2 content (all five
   questions are map-sourced placeholders, `[VERIFY-AT-BUILD]`).
4. **[VERIFY-AT-BUILD] sweep (real toolchain; never inside check.sh):** compile
   and run every compiled sample (L3.1–L3.8); confirm outputs byte-for-byte
   including both std Display strings (ParseIntError variants in L3.1, TryFrom
   error in L3.8); confirm E0277 at both sites (L3.1 broken — the `?`-in-u32-fn
   diagnostic, moderate confidence; L3.3 broken — String: Copy) and E0382 at
   both sites (L3.4 experiment, L3.6 broken); confirm L3.2's panic text and that
   `panicked` appears in stderr; transcribe L3.9's attribute semantics against
   current thiserror/anyhow docs and L3.10's signatures against the pinned regex
   release (record the version in regex-api.txt's header). Fix content to
   reality and log every deviation.
5. Lint gates: `./tools/lint-labs.sh` clean; ERE discipline per rust-p2-plan
   §5.5 (escaped brackets in L3.5/L3.7 asserts already specified).
6. Acceptance: extend `tests/acceptance.sh` with a P3 section per the
   established pattern — fabricated pass (echo answers/outputs; stub binaries
   for ./sample ×7 — L3.1/L3.3/L3.4/L3.5/L3.6/L3.7/L3.8 — plus ./ingest; echo
   panic1.txt) + one negative case per lab;
   drive `lab start rust L3.1` with 5 piped recall answers, assert non-gating;
   update every stale catalog-count denominator at every call site (standing
   precedent).
7. Manual full-phase pass with the real toolchain before tagging `rust-p3`.
8. Update `planned_execution.md` (build session's job, not this plan's).

## 6. Decisions & deviations log (for the reviewer)

- **Recall sourced from the curriculum map** — p0–p2 unbuilt at plan time; all
  five `[VERIFY-AT-BUILD]`; §5.3 makes refinement mandatory.
- **Two read-only exhibits (L3.9, L3.10), nothing fetched, nothing compiled** —
  thiserror/anyhow/regex are third-party; the track never touches the network
  and check.sh never runs cargo, so these labs grade pure reading via
  answers.txt (L2.8 established the exhibit pattern; the map's own L3.9/L3.10
  wording — "at reading level", "read a public API" — is exactly this).
  Consequence, stated honestly: L3.9 and L3.10 have no runnable artifact; their
  negative acceptance cases corrupt an answer key instead of deleting a binary.
- **L3.10 exhibits the regex crate** — chosen over csv/serde because it is
  security-relevant, its API is a showcase of failure-in-the-types, and its
  documented linear-time guarantee makes q7 a real (and commonly
  misunderstood) security fact. Pinned version recorded in the exhibit header
  at build time; every signature transcribed, never paraphrased.
- **The gate has no compile step** — deliberate match to the map ("read a real
  crate's public API and answer questions"); breadth rides answers.txt (ten
  keys) per L1.9/L2.10 precedent.
- **E0277 appears twice with different faces** (L3.1 `?`-outside-Result, L3.3
  missing bound) — deliberate: same code, two diagnostics, teaching that the
  code number alone is not the diagnosis. L3.1's is the moderate-confidence one
  and is tagged as such.
- **`as`-truncation arithmetic in L3.8** (70000 → 4464) hand-verified
  (70000 − 65536 = 4464); iterator arithmetic in L3.5 hand-verified
  (21+22+443+8080+9200 = 17766; 21×10 = 210).
- **Plan-time verification coverage (honest report):** author self-review only;
  no adversarial fleet at plan time. §5.4's toolchain sweep is authoritative for
  every `[VERIFY-AT-BUILD]` tag. The two lower-confidence claims are explicitly
  tagged at their sites: L3.1's E0277 diagnostic wording and L3.10's q7 doc
  line.
