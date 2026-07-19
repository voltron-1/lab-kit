# RUST TRACK — Phase 2 Build Plan (v1): Ownership, Borrowing, Lifetimes

Binding content spec: `docs/curriculum/rust-literacy-lab-curriculum-v1.md` (Phase 2
section). Binding mechanical spec: `docs/kit-contracts.md`. Format precedent:
`docs/plans/rust-p01-plan.md`. Reference implementation of every file format:
`tracks/demo/phases/p0/L0.0-meet-the-kit/`.
This plan is the single source of design judgment for the build session — build it
mechanically; where reality contradicts a claim marked `[VERIFY-AT-BUILD]`, fix the
content to match reality and note the deviation in the build report.

Planning-context note: at plan time NOTHING in the rust track is built
(`tracks/rust/phases/` does not exist). Phase 0+1 exist only as
`docs/plans/rust-p01-plan.md`. Consequence: L2.1's recall questions are sourced from
the **curriculum map's lab list** for Phases 0–1 (titles + descriptions), not from
disk content, and every one is `[VERIFY-AT-BUILD]` — the p2 build session must
refine wording against the real built p0/p1 labs (build order: p0+p1 first).

## 1. Lab list (from the map, exactly)

| id | title (meta.json `title`) | type | gate | est_minutes | dir slug |
|---|---|---|---|---|---|
| L2.1 | Move semantics — why the compiler "took" your variable | PREDICT | false | 15 | `L2.1-move-semantics` |
| L2.2 | `Copy` vs `Clone` | PREDICT | false | 10 | `L2.2-copy-vs-clone` |
| L2.3 | Shared borrows — `&` | PREDICT | false | 10 | `L2.3-shared-borrows` |
| L2.4 | `&mut` and the aliasing-XOR-mutation law | FIX | false | 15 | `L2.4-mut-aliasing-xor` |
| L2.5 | Borrow-error triage I — E0382, E0499, E0502 | FIX | false | 20 | `L2.5-borrow-triage-1` |
| L2.6 | `String` vs `&str`, and slices | DECODE | false | 15 | `L2.6-string-vs-str` |
| L2.7 | Lifetimes — reading `'a` without fear | DECODE | false | 15 | `L2.7-lifetimes` |
| L2.8 | The C++ crime scene — use-after-free side-by-side | AUDIT | false | 20 | `L2.8-cpp-crime-scene` |
| L2.9 | Borrow-error triage II — lifetimes in errors | FIX | false | 20 | `L2.9-borrow-triage-2` |
| L2.10 | Phase gate: explain 5 rejected programs | FIX | **true** | 20 | `L2.10-phase-gate-five-rejections` |

Gate placement: the map marks L2.10 explicitly; no other gate in this phase.
recall.json placement: **L2.1 only** (5 questions, earlier phases, per the
spaced-recall contract).

Phase security hook (map, woven through the labs): the borrow checker eliminates
use-after-free (CWE-416), double-free (CWE-415), and data races (CWE-362) at
compile time. L2.8 makes it explicit with a side-by-side exhibit; L2.5/L2.10 tie
each error code to the C++ bug it would have been.

## 2. Binding harness constraints (unchanged from p01 — restated short)

1. **check.sh never runs cargo or rustc** — the `env -i` fence hides `~/.cargo/bin`
   by design. All grading is artifact-based: `key=value` answer files, learner-
   redirected output files, learner-built binaries run by relative path via
   `assert_output_contains ... -- ./name`.
2. **CI-fabricatable artifacts:** every check must be passable without a Rust
   toolchain (echo the answer/output files; 2-line `#!/bin/sh` stubs for binaries,
   `chmod +x`) — this keeps `tests/acceptance.sh` and lint CI toolchain-free.
3. **lint-labs.sh bans** (check.sh only): absolute-path literals, `eval`, `sudo`,
   `curl`, `wget`, ` nc `, `ssh `, `sh -c`, `bash -c`, `pushd`, `bin/lab`,
   `cd ..`/`cd ~`; mode 0644; `set -euo pipefail` + LAB_WORKSPACE/LAB_CHECKLIB
   guards + `source "$LAB_CHECKLIB"`; collect-all assertions; `ck_summary` last
   line; `# shellcheck disable=` banned repo-wide. `files/` content is never
   linted, shellchecked, or executed by repo tooling.
4. **File contracts:** quiz.json exactly 3; hints.json exactly 3 levels (L1 never
   reveals); recap.md exactly 3 lines, no bullet prefix; lab.md exactly `## BRIEF`
   (≤10 lines) + `## GUIDED STEPS`; meta.json `{id,title,type,objective,gate,
   est_minutes}`, id == directory id. Answers base64
   (`printf '%s' 'answer' | base64 -w0`), text answers stored lowercase; add
   `accept_b64` variants where phrasing varies.
5. **Quiz I/O:** one line per question from stdin, no reprompting; recall runs at
   `lab start` on the phase opener only, non-gating (informational ≥4/5).

## 3. Track conventions (carried from p01 + Phase-2 additions)

Carried unchanged from `rust-p01-plan.md` §3:
- `key=value` answer files, no spaces around `=`: `predictions.txt` (PREDICT) /
  `answers.txt` (DECODE/FIX/AUDIT), in the workspace root. Conceptual questions are
  lettered multiple choice (options printed in lab.md); value questions take the
  exact output token. check.sh greps anchored ERE (`'^q1=b$'`) or
  `assert_file_contains_fixed` for values with regex metacharacters.
- PREDICT protocol: read → write predictions → compile/run → compare; compile-fail
  teasers ask for the error **code** read off real compiler output; honor framing
  in BRIEF ("the check can't tell whether you predicted first — you're only
  cheating your own reps").
- Broken samples are separate `broken*.rs` files, never inline edits of the working
  sample — the workspace always ends with a compiling `sample.rs` binary for
  check.sh to run.
- Quiz questions never duplicate graded answer-file questions verbatim; same
  concept, different angle.
- Hints ladder: L1 = which artifact/step, never content; L2 = exact line/command
  and expected shape; L3 = near-answer procedure ("run it and transcribe" is
  legitimate for error codes and outputs).
- Workspace hygiene: learner work in `workspace/rust/<id>/`; `/workspace/` is
  gitignored (verified at p01 plan time).

New for Phase 2 (applied consistently):
- **Build tool: bare `rustc` on single files for ALL ten labs.** Nothing in this
  phase needs cargo (no profiles, no deps). Bare rustc compiles edition 2015;
  every sample below is edition-independent — no `dyn`, no `async`, inline `{x}`
  format captures only (a 1.58 std feature, not edition-gated)
  `[VERIFY-AT-BUILD: compile every file with plain rustc, no flags]`.
- **FIX protocol** (generalizes L1.7): (1) `rustc brokenN.rs` for real, (2) record
  the error code in answers.txt (`eN=E0xxx` — transcription is fine, the rep is
  reading the error), (3) `cp brokenN.rs fixedN.rs`, apply the **minimal fix named
  by lab.md** — each FIX lab names its forbidden lazy fix and check.sh greps its
  absence, (4) `rustc fixedN.rs -o fixedN` and check.sh runs `./fixedN`.
  Single-broken-file labs use `broken.rs`/`fixed.rs`/`./fixed` unnumbered.
- **Rejection-evidence convention** (L2.8): when a lab's whole point is that a file
  does NOT compile, the learner captures the proof:
  `rustc <file>.rs 2> rust_error.txt` (non-zero exit expected — lab.md says so),
  and check.sh greps the code tag in `rust_error.txt`. No binary is ever produced
  from such a file, so no run-assert applies.
- **NLL teaching line** (used by L2.4/L2.5/L2.9 fixes): a borrow ends at its
  **last use**, not the closing brace — reordering statements is therefore a
  legitimate minimal fix, and the labs say so explicitly.
- **Read-only exhibits:** L2.8's `crime.cpp` is a text exhibit — never compiled,
  never executed, no C++ toolchain assumed anywhere in the track. Precedent for
  Phase 3+ vendored-source labs.

## 4. Lab entries

---

### L2.1 — Move semantics — why the compiler "took" your variable
**PREDICT · gate:false · est 15 · files/: sample.rs, broken.rs · recall.json: YES (phase opener)**
**objective:** "Predict which String bindings die at each assignment or call, and read E0382 — use of a moved value — off real compiler output."

**recall.json — 5 questions, sourced from the curriculum map's Phase 0–1 lab list
(p0/p1 unbuilt at plan time). ALL FIVE are `[VERIFY-AT-BUILD]`: refine wording
against the real built p0/p1 labs before shipping.**
1. choice (source: "rust L1.1 — let, mut, shadowing") — "In Rust, variables are ___
   by default." a) mutable b) immutable c) uninitialized → **b**
2. choice (source: "rust L1.2 — integer overflow debug vs release") — "A u8
   counter overflows in a *debug* build — what happens?" a) silent wrap b) panic
   (overflow checks are on) c) undefined behavior → **b**
3. choice (source: "rust L1.7 — match exhaustiveness") — "A `match` over an enum
   misses one variant — the result is…" a) runtime panic on that variant
   b) compile error (E0004, non-exhaustive patterns) c) the first arm runs → **b**
4. choice (source: "rust L1.8 — Option, no null") — "Rust's replacement for NULL /
   sentinel returns is…" a) 0 b) `Option<T>` — Some/None as ordinary values
   c) exceptions → **b**
5. choice (source: "rust L0.3 — repo anatomy") — "A crate has both src/main.rs and
   src/lib.rs — the *binary* entry point is…" a) src/lib.rs b) src/main.rs
   c) whichever Cargo.toml lists first → **b**

**files/sample.rs:**
```rust
fn register(tag: String) -> usize {
    tag.len()
}

fn main() {
    let alpha = String::from("intrusion");
    let beta = alpha;
    println!("beta = {beta}");

    let gamma = String::from("port-22");
    let size = register(gamma);
    println!("size = {size}");

    let delta = beta.clone();
    println!("delta = {delta}");
    println!("beta again = {beta}");
}
```
Expected output `[VERIFY-AT-BUILD]`: `beta = intrusion` / `size = 7` /
`delta = intrusion` / `beta again = intrusion`.
Teaching beats: `let beta = alpha;` MOVES — alpha is dead at compile time (not
null, not zeroed: illegal to name); passing `gamma` by value moves it into
`register`, gone for good; `.clone()` is the explicit deep copy, and beta remains
usable after being cloned *from*; a move is a pointer handoff, not a byte copy.

**files/broken.rs:**
```rust
fn main() {
    let session = String::from("sess-491");
    let backup = session;
    println!("backup = {backup}");
    println!("session = {session}");
}
```
Must produce **E0382** — "borrow of moved value: `session`"
`[VERIFY-AT-BUILD: exact message line]`.

**GUIDED STEPS outline:** read sample.rs (printed inline) → write
`predictions.txt` with keys `beta=`, `size=`, `delta=` (exact printed values) →
`rustc sample.rs -o sample && ./sample` → compare → `rustc broken.rs` (expect
rejection; read the `error[E....]` tag) → record `error=E0382` → check. Honor
framing in BRIEF per §3.

**CHECK LOGIC:** `assert_file_contains predictions.txt '^beta=intrusion$'`,
`'^size=7$'`, `'^delta=intrusion$'`, `'^error=E0382$'` (hints name the step);
`assert_output_contains 'sample binary runs' 'beta again = intrusion' 'step 3 —
rustc sample.rs -o sample' -- ./sample`; `ck_summary`.
(CI fabrication: echo the four lines; `#!/bin/sh` stub printing the four output
lines as `./sample`.)

**QUIZ:**
1. choice — "Why does Rust move a String on assignment instead of copying it?"
   a) copying is forbidden b) String owns heap memory — an implicit copy would be
   expensive and risk double-free; ownership transfers instead c) a compiler
   limitation → **b**
2. choice — "After a move, the old variable is…" a) null b) zero-filled
   c) compile-time dead — naming it at all is the error → **c**
3. text — "The explicit method that duplicates a String instead of moving it." →
   **clone** (accept: `clone()`, `.clone()`)

**RECAP:**
```
assignment or a by-value call MOVES a String — the old name is dead at compile time
a move is a pointer handoff, not a copy; clone() is the explicit deep copy
E0382 = use of moved value; the error names both the move site and the use site
```

**HINTS:** L1: four prediction keys (beta, size, delta, error) — the grader names
each miss; no spaces around `=`. L2: trace ownership line by line — `let beta =
alpha` kills alpha; `register(gamma)` kills gamma; size is the character count of
"port-22"; the error code is the `error[E....]` tag on rustc's first line. L3: run
it and transcribe: `rustc sample.rs -o sample; ./sample; rustc broken.rs` — the
run is the answer sheet.

---

### L2.2 — `Copy` vs `Clone`
**PREDICT · gate:false · est 10 · files/: sample.rs, broken.rs**
**objective:** "Predict which assignments duplicate and which move, and explain why Copy is refused the moment a type owns heap (E0204)."

**files/sample.rs:**
```rust
#[derive(Clone, Copy)]
struct PortRange {
    first: u16,
    last: u16,
}

fn width(range: PortRange) -> u16 {
    range.last - range.first
}

fn main() {
    let a = 41;
    let b = a;
    println!("a = {a}, b = {b}");

    let scan = PortRange { first: 20, last: 25 };
    let w = width(scan);
    println!("w = {w}");
    println!("scan.first = {}", scan.first);

    let name = String::from("dmz-probe");
    let copy_of_name = name.clone();
    println!("{name} / {copy_of_name}");
}
```
Expected output `[VERIFY-AT-BUILD]`: `a = 41, b = 41` / `w = 5` /
`scan.first = 20` / `dmz-probe / dmz-probe`.
Teaching beats: integers are `Copy` — assignment duplicates bits, both names live;
`#[derive(Clone, Copy)]` on a small all-Copy struct opts into the same behavior
(that's why `scan` survives the by-value `width(scan)` call — contrast with
L2.1's `register`); String can never be Copy (owns heap) — `clone()` is the
explicit, visible-in-review duplicate; `Copy` requires `Clone` (derive both).

**files/broken.rs:**
```rust
#[derive(Clone, Copy)]
struct Session {
    id: u32,
    token: String,
}

fn main() {
    let s = Session { id: 7, token: String::from("abc") };
    println!("{} {}", s.id, s.token);
}
```
Must produce **E0204** — the `Copy` derive is refused because field `token:
String` is not Copy `[VERIFY-AT-BUILD: exact code + message line — lower
confidence than the borrow-family codes; if reality differs, fix content to
reality]`.

**GUIDED STEPS outline:** read → `predictions.txt` keys `b=` (what b prints),
`w=`, `first=` (scan.first after the call), then compile/run → `rustc broken.rs`,
record `error=E0204` → check.

**CHECK LOGIC:** `assert_file_contains predictions.txt '^b=41$'`, `'^w=5$'`,
`'^first=20$'`, `'^error=E0204$'`; `assert_output_contains 'sample runs'
'dmz-probe / dmz-probe' 'step 3 — rustc sample.rs -o sample' -- ./sample`;
`ck_summary`. (CI fabrication: echo lines + stub binary.)

**QUIZ:**
1. choice — "A type may derive Copy only when…" a) it is smaller than 64 bytes
   b) every field is itself Copy and the type owns no heap/resources c) it also
   derives Debug → **b**
2. choice — "The review value of Copy vs Clone:" a) none, they're identical
   b) Copy duplication is invisible at call sites, so Rust only allows it where
   duplication is trivially safe; clone() is always visible in the code → **b**
3. text — "Can a struct containing a String derive Copy? (yes/no)" → **no**

**RECAP:**
```
Copy types (ints, bools, small all-Copy structs) duplicate on assignment — no move
String/Vec own heap: never Copy; clone() is the explicit, visible duplicate
E0204 = Copy derive refused over a non-Copy field — the compiler polices the line
```

**HINTS:** L1: four prediction keys; the grader names the misses. L2: a/b are
plain integers (Copy — both live); PortRange derives Copy, so `scan` survives the
by-value call; w = last − first; the error code comes from compiling broken.rs.
L3: run both files and transcribe: `rustc sample.rs -o sample; ./sample;
rustc broken.rs`.

---

### L2.3 — Shared borrows — `&`
**PREDICT · gate:false · est 10 · files/: sample.rs, broken.rs**
**objective:** "Predict a program where multiple & borrows coexist and the owner survives every call, and read the rejection when a & borrow tries to mutate."

**files/sample.rs:**
```rust
fn longest_len(a: &String, b: &String) -> usize {
    if a.len() > b.len() { a.len() } else { b.len() }
}

fn main() {
    let host = String::from("bastion-01");
    let alias = &host;
    let alias2 = &host;
    println!("{alias} / {alias2} / {host}");

    let primary = String::from("core-router");
    let backup = String::from("edge-fw");
    let max = longest_len(&primary, &backup);
    println!("max = {max}");
    println!("{primary} + {backup} still here");
}
```
Expected output `[VERIFY-AT-BUILD]`: `bastion-01 / bastion-01 / bastion-01` /
`max = 11` / `core-router + edge-fw still here`.
Teaching beats: any number of `&` borrows may coexist, all read-only; borrowing
for a call (`&primary`) leaves the caller owning the value — the exact contrast
with L2.1's `register(gamma)`; parameters here are `&String` for simplicity —
lab.md carries one forward-pointer line: "real code prefers `&str`; L2.6 shows
why."

**files/broken.rs:**
```rust
fn main() {
    let config = String::from("mode=passive");
    let view = &config;
    view.push_str(";debug=1");
    println!("{view}");
}
```
Must produce **E0596** — cannot borrow `*view` as mutable, as it is behind a `&`
reference `[VERIFY-AT-BUILD: exact code + message — lower confidence; if rustc
reports a different code for mutating through &, fix content to reality]`.

**GUIDED STEPS outline:** read → `predictions.txt` keys `alias=` (what alias
prints), `max=` → compile/run → `rustc broken.rs`, record `error=E0596` → check.

**CHECK LOGIC:** `assert_file_contains predictions.txt '^alias=bastion-01$'`,
`'^max=11$'`, `'^error=E0596$'`; `assert_output_contains 'sample runs'
'core-router + edge-fw still here' 'step 3 — rustc sample.rs -o sample' --
./sample`; `ck_summary`.

**QUIZ:**
1. choice — "How many simultaneous & borrows of one value are allowed?" a) one
   b) two c) any number → **c**
2. choice — "After `longest_len(&primary, &backup)` returns, `primary` is…"
   a) moved into the function b) still owned by main — the function only borrowed
   c) cloned → **b**
3. text — "In its error messages, the compiler calls a & borrow a ___ borrow
   (mutable/immutable)." → **immutable**

**RECAP:**
```
& = shared borrow: any number may coexist, all read-only, the owner keeps ownership
a &-taking function costs the caller nothing — the signature promises it up front
mutation through & is refused: shared means look, don't touch
```

**HINTS:** L1: three prediction keys; the grader names the miss. L2: `max` is the
character count of the longer hostname — count "core-router"; the broken file
calls a mutating method (`push_str`) through a read-only borrow. L3: run and
transcribe: `rustc sample.rs -o sample; ./sample; rustc broken.rs`.

---

### L2.4 — `&mut` and the aliasing-XOR-mutation law
**FIX · gate:false · est 15 · files/: broken.rs**
**objective:** "Read E0502, then apply the minimal reordering fix that respects many-readers-XOR-one-writer — without reaching for clone()."

**files/broken.rs:**
```rust
fn main() {
    let mut queue = String::from("alert-1");
    let snapshot = &queue;
    queue.push_str(",alert-2");
    println!("snapshot = {snapshot}");
    println!("queue = {queue}");
}
```
Must produce **E0502** — "cannot borrow `queue` as mutable because it is also
borrowed as immutable" `[VERIFY-AT-BUILD: message line]`. The `&` borrow
(`snapshot`) is still live at the `push_str` (its last use is the later println).

**THE FIX (lab.md states it as the requirement):** `cp broken.rs fixed.rs`; move
the `println!("snapshot = {snapshot}");` line ABOVE the `push_str` call. NLL:
snapshot's borrow now ends (last use) before the `&mut` borrow begins — same five
lines, one reordering. **Forbidden fix, named in lab.md:** `snapshot.clone()` /
`queue.clone()` — it compiles, but it dodges the law instead of learning it, and
check.sh rejects any `clone` in fixed.rs.
Fixed output `[VERIFY-AT-BUILD]`: `snapshot = alert-1` / `queue = alert-1,alert-2`.

**GUIDED STEPS outline:** `rustc broken.rs` → read the error: note it names BOTH
borrows and points at snapshot's later use → record `error_code=E0502` and the
two answer-file choices below → `cp broken.rs fixed.rs`, reorder →
`rustc fixed.rs -o fixed && ./fixed` → check.
answers.txt (options printed in lab.md):
- `error_code=E0502`
- q2 (choice): why did the original order fail? a) push_str consumed queue
  b) a live & borrow (snapshot — still used later) overlapped the &mut that
  push_str needs c) String cannot grow after a borrow → `q2=b`
- q3 (choice): when does a borrow end? a) at the closing brace, always b) at its
  last use (non-lexical lifetimes) c) only when dropped explicitly → `q3=b`

**CHECK LOGIC:** `assert_file_contains answers.txt '^error_code=E0502$'`,
`'^q2=b$'`, `'^q3=b$'`; `assert_file_exists fixed.rs`;
`assert_file_not_contains fixed.rs 'clone'` (hint: reorder the reads before the
write — don't copy your way around the law);
`assert_output_contains 'fixed reads before mutating' 'snapshot = alert-1'
'step 4 — rustc fixed.rs -o fixed' -- ./fixed`;
`assert_output_contains 'fixed queue grew' 'queue = alert-1,alert-2' 'step 4 —
the push_str must still happen' -- ./fixed`; `ck_summary`.

**QUIZ:**
1. choice — "The aliasing-XOR-mutation law:" a) one &mut OR any number of &, never
   both alive at once b) &mut requires unsafe c) mutation always requires
   ownership → **a**
2. choice — "Which C++ bug family does this law kill at compile time?" a) SQL
   injection b) reads through stale aliases while another path mutates —
   iterator invalidation, use-after-realloc c) stack overflow → **b**
3. text — "How many &mut borrows of one value may be live at the same moment?" →
   **1** (accept: `one`)

**RECAP:**
```
many readers XOR one writer — never both at once; that is the whole borrow law
NLL: a borrow ends at its last USE, not the closing brace — reordering is a real fix
E0502 = writer wanted while readers still live; clone() is the dodge, not the fix
```

**HINTS:** L1: the grader wants answers.txt (three keys), a fixed.rs without the
forbidden call, and a working ./fixed. L2: snapshot's borrow lasts until its last
use — move that use (the snapshot println) so it happens before `push_str`
starts the mutable borrow. L3: exact edit — relocate
`println!("snapshot = {snapshot}");` to directly above `queue.push_str(...)`,
then `rustc fixed.rs -o fixed; ./fixed` and re-check.

---

### L2.5 — Borrow-error triage I — E0382, E0499, E0502
**FIX · gate:false · est 20 · files/: broken1.rs, broken2.rs, broken3.rs**
**objective:** "Triage three real borrow-checker rejections — code, cause, minimal fix — one per error family: moved-then-used, two writers, writer-while-readers."

**files/broken1.rs (E0382 — moved, then used):**
```rust
fn banner(text: String) -> String {
    format!("== {text} ==")
}

fn main() {
    let title = String::from("scan report");
    let framed = banner(title);
    println!("{framed}");
    println!("original: {title}");
}
```
**Fix1 (named in lab.md):** make `banner` borrow — `text: &str`, call site
`banner(&title)` (`&String` coerces; one lab.md line notes L2.6 explains the
coercion). **Forbidden fix, grepped:** `title.clone()`.
Fixed output `[VERIFY-AT-BUILD]`: `== scan report ==` / `original: scan report`.

**files/broken2.rs (E0499 — two &mut at once):**
```rust
fn main() {
    let mut counters = vec![1, 2, 3];
    let first = &mut counters[0];
    let second = &mut counters[1];
    *first += 10;
    *second += 10;
    println!("{counters:?}");
}
```
**Fix2:** sequence the writers — use each &mut before taking the next:
`let first = &mut counters[0]; *first += 10; let second = &mut counters[1];
*second += 10;` (NLL again). Fixed output `[VERIFY-AT-BUILD]`: `[11, 12, 3]`.

**files/broken3.rs (E0502 — writer while a reader lives):**
```rust
fn main() {
    let mut log = vec![String::from("boot")];
    let last = &log[0];
    log.push(String::from("login"));
    println!("last = {last}");
    println!("entries = {}", log.len());
}
```
**Fix3:** move the `last` println above the `push` (reader's last use before the
writer). Fixed output `[VERIFY-AT-BUILD]`: `last = boot` / `entries = 2`.
lab.md teaching line: broken3 IS the C++ iterator-invalidation shape — `push` may
reallocate and, in C++, `last` would silently dangle; full crime scene in L2.8.

**Error codes `[VERIFY-AT-BUILD: all three + message lines]`:** broken1 →
**E0382**, broken2 → **E0499** ("cannot borrow `counters` as mutable more than
once at a time"), broken3 → **E0502**.

**GUIDED STEPS outline:** compile each brokenN in turn, record its code
(`e1=`/`e2=`/`e3=`) → match each to its cause (`c1=`/`c2=`/`c3=`, options below,
printed in lab.md) → apply each lab.md-named fix in fixedN.rs → build and run all
three → check.
Cause options (shared letter set): a) a value was moved and then used b) two
mutable borrows alive at once c) a mutable borrow while a shared borrow is still
live. Answers: `c1=a`, `c2=b`, `c3=c`.

**CHECK LOGIC:** `assert_file_contains answers.txt '^e1=E0382$'`, `'^e2=E0499$'`,
`'^e3=E0502$'`, `'^c1=a$'`, `'^c2=b$'`, `'^c3=c$'`;
`assert_file_not_contains fixed1.rs 'clone'` (hint: borrow, don't copy);
`assert_output_contains 'fixed1 keeps title usable' 'original: scan report'
'fix banner to borrow: text: &str, call banner(&title)' -- ./fixed1`;
`assert_output_contains 'fixed2 both counters bumped' '\[11, 12, 3\]' 'sequence
the two &mut borrows — finish with first before taking second' -- ./fixed2`;
`assert_output_contains 'fixed3 read-then-grow' 'entries = 2' 'move the last
println above the push' -- ./fixed3`; `ck_summary`.
(Builder note: `assert_output_contains` patterns are ERE — bracket characters
MUST be escaped (`\[11, 12, 3\]`); unescaped, the bracket expression matches any
single listed character and false-passes wrong output. Descs avoid apostrophes
so quoting stays trivial.)

**QUIZ:**
1. choice — "First things to read in any borrow error:" a) the code tag plus the
   two spans — where the borrow started, where it conflicted b) the line count
   c) only the final note → **a**
2. choice — "Vec::push needs which access to the Vec?" a) & b) &mut c) ownership
   → **b**
3. text — "In C++, a reference into a vector that reallocates becomes a dangling
   reference at runtime; in safe Rust the same pattern becomes a ___ error." →
   **compile** (accept: `compile-time`, `compiler`, `borrow`)

**RECAP:**
```
triage order: error code → the two spans (borrowed where, conflicted where) → last use
E0382 moved-then-used · E0499 two writers · E0502 writer while a reader still lives
fixes are usually borrow-instead-of-move, or reorder so borrows don't overlap
```

**HINTS:** L1: six answer keys and three fixed binaries — the grader names every
miss. L2: the e-codes come straight off the three `rustc brokenN.rs` runs; the
fixes: fixed1 changes banner's parameter to borrow, fixed2 finishes writer one
before starting writer two, fixed3 moves the read above the push. L3: exact
edits — `fn banner(text: &str)` + `banner(&title)`; move `*first += 10;` up
between the two `let`s; move `println!("last = {last}");` above `log.push(...)`.

---

### L2.6 — `String` vs `&str`, and slices
**DECODE · gate:false · est 15 · files/: sample.rs**
**objective:** "Read the owner/view split — String vs &str, deref coercion at call sites, and zero-copy byte-offset slices — off a URL parser."

**files/sample.rs:**
```rust
fn scheme(url: &str) -> &str {
    match url.find("://") {
        Some(index) => &url[..index],
        None => "unknown",
    }
}

fn main() {
    let owned = String::from("https://vault:8443");
    let borrowed: &str = &owned;

    println!("scheme = {}", scheme(&owned));
    println!("scheme = {}", scheme("ldap://dc-01"));
    println!("len = {}", borrowed.len());

    let literal = "tcp/443";
    let proto = &literal[..3];
    println!("proto = {proto}");
}
```
Expected output `[VERIFY-AT-BUILD]`: `scheme = https` / `scheme = ldap` /
`len = 18` / `proto = tcp`.
Teaching beats: `String` owns heap and can grow; `&str` is a borrowed fixed view;
one `&str` parameter accepts a borrowed String AND a literal AND a slice — that's
why real APIs take `&str` (resolves L2.3/L2.5's forward pointers: `&String → &str`
is deref coercion, automatic at call sites); `&url[..index]` allocates NOTHING —
a view into the caller's buffer; slice indexes are **byte** offsets, and cutting a
multi-byte UTF-8 character in half panics at runtime — a one-line security beat
(untrusted offsets + slicing = panic path; Phase 4 returns to it).

**GUIDED STEPS outline:** read → compile/run → answers.txt (options in lab.md):
- q1 (choice): `url: &str` accepts which arguments? a) only literals b) only
  &String c) String borrows, literals, and slices — all of them → `q1=c`
- q2 (value): the scheme printed for the first URL → `q2=https`
- q3 (value): what `proto` prints → `q3=tcp`
- q4 (value): the len printed → `q4=18`
- q5 (choice): `&url[..index]` allocates… a) a new String b) nothing — it is a
  borrowed view into the same buffer c) a boxed copy → `q5=b`
→ check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=c$'`, `'^q2=https$'`,
`'^q3=tcp$'`, `'^q4=18$'`, `'^q5=b$'`; `assert_output_contains 'sample runs'
'scheme = ldap' 'step 2 — rustc sample.rs -o sample' -- ./sample`; `ck_summary`.

**QUIZ:**
1. choice — "String vs &str in one line:" a) same type, different mutability
   b) String owns and can grow; &str is a borrowed fixed view c) &str lives on
   the heap, String on the stack → **b**
2. choice — "Why do reviewers prefer `&str` parameters over `&String`?" a) speed
   only b) &str accepts strictly more callers (String borrows, literals, slices)
   at zero cost c) &String is deprecated → **b**
3. text — "String slice indexes count ___ (bytes/characters)." → **bytes**

**RECAP:**
```
String owns heap and grows; &str is a borrowed view — parameters want &str
&String coerces to &str at call sites automatically (deref coercion) — read past it
slices are zero-copy byte-offset views; a non-UTF-8-boundary cut panics at runtime
```

**HINTS:** L1: five answer keys; the grader names each miss. L2: `find("://")` on
the first URL returns Some(5), so the slice is the first 5 bytes; proto is the
first 3 bytes of "tcp/443"; q4 counts every byte of "https://vault:8443". L3: run
it and transcribe: `rustc sample.rs -o sample; ./sample`; q1/q5's correct options
restate the coercion and zero-copy lines from the BRIEF.

---

### L2.7 — Lifetimes — reading `'a` without fear
**DECODE · gate:false · est 15 · files/: sample.rs**
**objective:** "Read `'a` as a validity region: what a lifetime-annotated function promises, what a lifetime-carrying struct implies, and what E0597 says when the region is too small."

**files/sample.rs:**
```rust
fn longer<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}

struct Finding<'a> {
    rule: &'a str,
}

fn main() {
    let primary = String::from("credential-stuffing");
    let winner;
    {
        let secondary = String::from("port-sweep");
        winner = longer(&primary, &secondary);
        println!("winner = {winner}");
    }

    let finding = Finding { rule: &primary };
    println!("rule = {}", finding.rule);
}
```
Expected output `[VERIFY-AT-BUILD]`: `winner = credential-stuffing` /
`rule = credential-stuffing`.
Teaching beats: `'a` is a *region of code*, not a runtime thing — it is erased
from the binary; `longer`'s signature says "the returned reference is valid only
while BOTH inputs are" — so `winner` is usable only inside the block where
`secondary` lives, even though the winning value happens to borrow from
`primary` (the compiler reasons about types, not runtime luck); `Finding<'a>`
read: "this struct borrows — an instance must die before the data it points
into"; two refs in + one ref out = the annotation is mandatory because the
compiler won't guess the contract.

**GUIDED STEPS outline:** read → compile/run → the graded experiment: move
`println!("winner = {winner}");` BELOW the block's closing brace → `rustc
sample.rs` now fails — record the code → move the println back, recompile so
`./sample` works (same revert protocol as L1.4) → answers.txt (options in
lab.md):
- q1 (choice): `'a` in longer's signature promises… a) the output is
  heap-allocated b) the returned ref is valid only while both inputs are — the
  shorter-lived one bounds it c) inputs must be 'static → `q1=b`
- q2 (value): the winner line printed → `q2=credential-stuffing`
- q3 (choice): `struct Finding<'a>` tells a reader… a) Finding owns its rule
  string b) Finding borrows — an instance cannot outlive the string it points
  into c) rule is optional → `q3=b`
- q4 (choice): lifetimes at runtime are… a) GC metadata b) nothing — compile-time
  proof, erased from the binary c) debug-build-only checks → `q4=b`
- q5 (value): error code from the experiment → `q5=E0597`
  `[VERIFY-AT-BUILD: E0597, "`secondary` does not live long enough"]`

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`,
`'^q2=credential-stuffing$'`, `'^q3=b$'`, `'^q4=b$'`, `'^q5=E0597$'`;
`assert_output_contains 'sample runs (experiment reverted)' 'rule =
credential-stuffing' 'step 4 — move the winner println back inside the block and
recompile' -- ./sample`; `ck_summary`.

**QUIZ:**
1. choice — "`'a` is best read as…" a) a region of code during which the
   reference must remain valid b) a thread identifier c) a heap generation → **a**
2. choice — "Why does `longer` need `'a` written at all?" a) style convention
   b) with two input refs, the compiler refuses to guess which one the output
   borrows from — the annotation states the contract c) every fn needs one → **b**
3. text — "A struct with a lifetime parameter can outlive the data it borrows —
   true or false?" → **false**

**RECAP:**
```
'a names a validity region: the returned borrow lives only while every 'a input does
two refs in, one ref out — the compiler makes you write the contract, not guess it
lifetimes are compile-time proof, erased at runtime; reading them costs nothing
```

**HINTS:** L1: five answer keys; q5 comes from actually doing the move-the-println
experiment. L2: longer returns the *longer string*, but 'a binds the result to
the *shorter-lived* input — winner is only usable while secondary is alive; q2 is
the longer of the two attack names. L3: do the experiment — move the winner
println below the closing brace, `rustc sample.rs`, read the `error[E....]` tag,
write it as q5, revert, recompile with `-o sample`.

---

### L2.8 — The C++ crime scene — use-after-free side-by-side
**AUDIT · gate:false · est 20 · files/: crime.cpp, equivalent.rs**
**objective:** "Audit a real CWE-416 use-after-free in C++, then prove the identical shape is a compile error in Rust and name the exact rule that blocks it."

**files/crime.cpp (READ-ONLY EXHIBIT — never compiled, never executed; banner
comment says so; no C++ toolchain is assumed anywhere in this track):**
```cpp
// crime.cpp — READ-ONLY EXHIBIT. Do not compile; you are here to read.
// The bug class: CWE-416, use-after-free via vector reallocation.
#include <cstdio>
#include <vector>

int main() {
    std::vector<int> ports = {22, 80, 443};
    const int& first = ports[0];      // a reference into the buffer
    for (int p = 8000; p < 8032; ++p) {
        ports.push_back(p);           // growth may reallocate the buffer
    }
    std::printf("first = %d\n", first); // reads freed memory
    return 0;
}
```
Teaching beats (lab.md): `push_back` growth may move the buffer; `first` then
points into freed memory; the final read is undefined behavior — it may print 22,
print garbage, or crash, and *may pass every test run* until an attacker grooms
the heap; the C++ type system has no objection — the bug is invisible at compile
time. Detection sidebar (one line): in C++ this is caught — sometimes — at
runtime by ASan/Valgrind; Rust catches it before a binary exists.

**files/equivalent.rs (the same shape, line for line):**
```rust
fn main() {
    let mut ports = vec![22, 80, 443];
    let first = &ports[0];
    for p in 8000..8032 {
        ports.push(p);
    }
    println!("first = {first}");
}
```
Must produce **E0502** — cannot borrow `ports` as mutable because it is also
borrowed as immutable `[VERIFY-AT-BUILD: message line]`. The learner captures the
proof per §3's rejection-evidence convention:
`rustc equivalent.rs 2> rust_error.txt` (non-zero exit expected — lab.md says so).

**GUIDED STEPS outline:** read crime.cpp top to bottom, answer q1/q2 → read
equivalent.rs, predict the rejection → `rustc equivalent.rs 2> rust_error.txt` →
read the captured error, answer q3/q4/q5 → check.
answers.txt (options printed in lab.md):
- q1 (value): the CWE id for use-after-free (format `CWE-###`, given in the
  brief's vocabulary line) → `q1=CWE-416`
- q2 (choice): which line arms the bomb in crime.cpp? a) taking `first` — early
  references are always bugs b) `push_back` possibly reallocating while `first`
  still points into the old buffer c) the printf format string → `q2=b`
- q3 (value): the error code in rust_error.txt → `q3=E0502`
- q4 (choice): which borrow-law clause blocked it? a) two &mut at once b) &mut
  (push) requested while a & (first) is still live — aliasing XOR mutation
  c) a missing lifetime annotation → `q4=b`
- q5 (choice): when does C++ catch this bug? a) compile time b) possibly never —
  it is runtime UB that can silently "work" in every test c) link time → `q5=b`

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=CWE-416$'`, `'^q2=b$'`,
`'^q3=E0502$'`, `'^q4=b$'`, `'^q5=b$'`;
`assert_file_contains rust_error.txt 'error\[E0502\]'` (hint: step 3 — capture
the compile with `rustc equivalent.rs 2> rust_error.txt`) `[VERIFY-AT-BUILD:
tag shape in real stderr]`; `ck_summary`.
(CI fabrication: echo the five answers; echo an `error[E0502]` line into
rust_error.txt.)

**QUIZ:**
1. choice — "Why can crime.cpp print 22 correctly in a test run and still be a
   security hole?" a) UB may behave 'correctly' until allocation patterns change —
   attackers arrange the heap so the freed slot is reused with their data
   b) it can't; printing 22 proves safety c) printf masks the bug → **a**
2. choice — "The Rust rejection happens…" a) at runtime, as a panic b) at compile
   time, before any binary exists c) only under a sanitizer → **b**
3. text — "Name the vulnerability class in words (not the CWE number)." →
   **use-after-free** (accept: `use after free`, `uaf`, `dangling reference read`)

**RECAP:**
```
CWE-416: the reference outlived the buffer — C++ compiles it and attackers exploit it
Rust makes the same shape E0502: growth needs &mut while the old & is still alive
this is the borrow checker's job description: memory-corruption bugs die pre-build
```

**HINTS:** L1: five answer keys plus rust_error.txt — the CWE number and its
format are in the BRIEF. L2: for q2, find the single line that can move the
buffer out from under `first`; for q3, actually run the capture command from
step 3 and read the tag. L3: `rustc equivalent.rs 2> rust_error.txt` then open
rust_error.txt — the `error[E....]` tag is q3, and the message's "as mutable
because it is also borrowed as immutable" phrasing is q4's answer in the
compiler's own words.

---

### L2.9 — Borrow-error triage II — lifetimes in errors
**FIX · gate:false · est 20 · files/: broken1.rs, broken2.rs, broken3.rs**
**objective:** "Triage the three lifetime-flavored rejections — missing contract (E0106), returning a local (E0515), borrow outliving its value (E0597) — and apply each canonical escape."

**files/broken1.rs (E0106 — signature won't state the contract):**
```rust
fn first_token(line: &str, fallback: &str) -> &str {
    match line.split(',').next() {
        Some(token) => token,
        None => fallback,
    }
}

fn main() {
    let line = String::from("alert,high,4625");
    println!("{}", first_token(&line, "none"));
}
```
**Fix1 (named in lab.md):** write the contract — `fn first_token<'a>(line: &'a
str, fallback: &'a str) -> &'a str`. Fixed output `[VERIFY-AT-BUILD]`: `alert`.

**files/broken2.rs (E0515 — returning a reference to a local):**
```rust
fn stamp(prefix: &str) -> &str {
    let full = format!("{prefix}-4097");
    &full
}

fn main() {
    println!("{}", stamp("sess"));
}
```
**Fix2:** return an OWNED value — signature becomes `-> String`, body returns
`full`. Fixed output `[VERIFY-AT-BUILD]`: `sess-4097`.

**files/broken3.rs (E0597 — borrow outlives the value):**
```rust
fn main() {
    let newest;
    {
        let batch = String::from("evt-9911");
        newest = &batch;
    }
    println!("newest = {newest}");
}
```
**Fix3:** make the value outlive the borrow — lift `let batch = ...;` out of the
inner block (delete the braces). Fixed output `[VERIFY-AT-BUILD]`:
`newest = evt-9911`.

**Error codes `[VERIFY-AT-BUILD: all three + message lines]`:** broken1 →
**E0106** "missing lifetime specifier" (rustc's note: the return type borrows
from either `line` or `fallback` and the signature must say which region);
broken2 → **E0515** "cannot return reference to local variable `full`" (the
signature compiles via elision — one input ref, so the output is assumed to
borrow from it — the *body* then breaks the promise); broken3 → **E0597**
"`batch` does not live long enough".

**GUIDED STEPS outline:** compile each, record `e1=`/`e2=`/`e3=` → match causes
`c1=`/`c2=`/`c3=` (options in lab.md, shared letter set): a) the signature won't
say whose lifetime the output borrows b) returning a reference to a value that
dies inside the function c) a reference outliving the value it points at →
`c1=a`, `c2=b`, `c3=c` → apply the three named fixes → build/run all three →
check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^e1=E0106$'`, `'^e2=E0515$'`,
`'^e3=E0597$'`, `'^c1=a$'`, `'^c2=b$'`, `'^c3=c$'`;
`assert_file_contains_fixed fixed1.rs "<'a>"` (hint: the fix is writing the
lifetime contract into the signature);
`assert_file_contains_fixed fixed2.rs '-> String'` (hint: the escape from E0515
is returning an owned value);
`assert_output_contains 'fixed1 splits the line' 'alert' 'write the lifetime
contract into the signature: one region name on the fn, all three refs' --
./fixed1` (hint wording deliberately contains no literal lifetime tick, so the
string needs no shell escaping — keep it that way);
`assert_output_contains 'fixed2 returns owned' 'sess-4097' 'return type String,
return full' -- ./fixed2`;
`assert_output_contains 'fixed3 value outlives borrow' 'newest = evt-9911' 'lift
let batch out of the inner braces' -- ./fixed3`; `ck_summary`.

**QUIZ:**
1. choice — "`fn f(x: &str) -> &str` compiles with no `'a` because…" a) lifetimes
   are optional b) elision: one input ref, so the compiler assumes the output
   borrows from it c) &str is special-cased → **b**
2. choice — "Why can NO annotation ever make `return &local;` legal?" a) style
   rule b) the local is destroyed when the function returns; annotations describe
   lifetimes, they cannot extend them c) it is legal with 'static → **b**
3. text — "The standard escape from E0515: return an ___ value (String, Vec, …)
   instead of a reference." → **owned**

**RECAP:**
```
E0106 = the signature refuses to guess whose lifetime the output borrows — write 'a
E0515 = returning a ref to a local; the escape is returning an owned value instead
E0597 = the borrow outlives the value; move the value out, or move the use in
```

**HINTS:** L1: six answer keys and three fixed binaries — the grader names each
miss. L2: the e-codes come off the three compiles; fixed1 adds `<'a>` to the fn
and `'a` to all three refs, fixed2 changes the return type to String, fixed3
deletes the inner braces so batch lives to the println. L3: exact edits per
file — signature `fn first_token<'a>(line: &'a str, fallback: &'a str) -> &'a
str`; signature `fn stamp(prefix: &str) -> String` with body `format!(...)`
returned directly; remove the `{` `}` pair around batch.

---

### L2.10 — Phase gate: explain 5 rejected programs
**FIX · gate:TRUE · est 20 · files/: reject1.rs … reject5.rs**
**objective:** "Prove Phase 2: for five rejected programs, predict the error code and name the violated rule from the source alone — then verify against the real compiler and fix one."

**files/reject1.rs (moved into a collection, then used):**
```rust
fn main() {
    let key = String::from("0x41");
    let vault = vec![key];
    println!("stored {} keys, first = {key}", vault.len());
}
```
→ **E0382** (the move is into `vec![key]`, not a function call — deliberate
variety vs L2.1).

**files/reject2.rs (two writers):**
```rust
fn main() {
    let mut score = 10;
    let a = &mut score;
    let b = &mut score;
    *a += 1;
    *b += 1;
    println!("score = {score}");
}
```
→ **E0499** (`a` is still used after `b` is created).

**files/reject3.rs (writer while a reader lives — the UAF shape again):**
```rust
fn main() {
    let mut hosts = vec![String::from("db-01")];
    let first = &hosts[0];
    hosts.clear();
    println!("gone but readable? {first}");
}
```
→ **E0502** (`clear` needs &mut while `first` is live — L2.8's crime scene in
miniature).

**files/reject4.rs (returning a local):**
```rust
fn label(kind: &str) -> &str {
    let tag = format!("[{kind}]");
    &tag
}

fn main() {
    println!("{}", label("scan"));
}
```
→ **E0515** (elided signature compiles; the body breaks the promise).

**files/reject5.rs (borrow outlives its value):**
```rust
fn main() {
    let survivor;
    {
        let tmp = String::from("short-lived");
        survivor = &tmp;
    }
    println!("{survivor}");
}
```
→ **E0597**. **This is the one graded fix:** `cp reject5.rs fixed5.rs`, lift
`let tmp` out of the braces; `./fixed5` prints `short-lived`
`[VERIFY-AT-BUILD]`.

**All five codes `[VERIFY-AT-BUILD: compile each, confirm codes and message
lines]`.** Honor contract restated in lab.md: write all ten answers from the
SOURCE first, then compile each file to self-check — the check can't tell, the
reps are the point.

**The graded matrix** (options printed in lab.md; L1.9 precedent — breadth rides
answers.txt because quiz.json is capped at 3):
codes: `e1=E0382`, `e2=E0499`, `e3=E0502`, `e4=E0515`, `e5=E0597`
causes (shared letter set, printed once): a) a value was moved and then used
b) two mutable borrows alive at once c) a mutable borrow while a shared borrow is
still live d) returns a reference to a value that dies inside the function e) a
reference outlives the value it points at (its scope ends first)
→ `c1=a`, `c2=b`, `c3=c`, `c4=d`, `c5=e`

**GUIDED STEPS outline:** read all five cold, fill the ten matrix keys → compile
each (`rustc rejectN.rs`) and self-check the codes — revise nothing you got wrong
without understanding why → fix reject5 per above, build `./fixed5` → check.

**CHECK LOGIC:** ten anchored greps on answers.txt (`'^e1=E0382$'` …
`'^e5=E0597$'`, `'^c1=a$'` … `'^c5=e$'`); `assert_file_exists fixed5.rs`;
`assert_output_contains 'fixed5 runs' 'short-lived' 'lift let tmp out of the
braces, then rustc fixed5.rs -o fixed5' -- ./fixed5`; `ck_summary`.
(CI fabrication: echo ten matrix lines; stub `./fixed5` printing short-lived.)

**QUIZ (concept-level, not duplicating the matrix):**
1. choice — "All five rejections share one root idea:" a) Rust dislikes
   references b) every reference must be provably valid for its whole use —
   aliasing and lifetime rules are how the compiler proves it c) heap allocation
   is discouraged → **b**
2. choice — "Which C/C++ bug classes did this phase's rules eliminate at compile
   time?" a) SQL injection and XSS b) use-after-free, double-free, and
   stale-alias mutation bugs (CWE-416/415 family) c) integer overflow and path
   traversal → **b**
3. text — "Complete the law: many readers or one writer, but never ___." →
   **both** (accept: `both at once`)

**RECAP:**
```
five rejections, five rules: moves, one writer, readers XOR writer, locals die, scopes bound borrows
reading a borrow error is now mechanical: code → spans → violated rule → minimal fix
gate passed: Phase 3 turns to the type system — traits, Result, and panic paths
```

**HINTS:** L1: ten matrix keys plus one fixed binary — the grader names every
miss; the cause options are printed once above the file list in lab.md. L2: map
each reject to its phase lab — moved-into-vec (L2.1), two &mut (L2.4/2.5),
& alive across clear() (L2.5/2.8), returning &local (L2.9), inner-scope borrow
(L2.9) — the cause letters follow; codes come off the five compiles. L3: compile
all five (`rustc rejectN.rs`), transcribe the `error[E....]` tags in order, then
for fixed5 lift `let tmp = String::from("short-lived");` above the `{` and
rebuild.

---

## 5. Build-session protocol (execute in this order)

0. **Prerequisite: Phases 0+1 must be BUILT first** (this phase's opener recall
   refines against their real content, and `lab` progression assumes p0/p1 exist).
1. Scaffold the 10 lab directories under `tracks/rust/phases/p2/` per §1 slugs.
2. Author content straight from §4. Base64 every quiz/recall answer
   (`printf '%s' 'answer' | base64 -w0`); text answers lowercase-normalized with
   `accept_b64` variants as listed.
3. **Refine L2.1's recall.json** against the real built p0/p1 lab content (the
   five questions above are map-sourced placeholders — every one is
   `[VERIFY-AT-BUILD]`).
4. **[VERIFY-AT-BUILD] sweep (real toolchain; cargo/rustc allowed in the build
   session — never inside check.sh):** compile every file with plain `rustc`;
   confirm every expected output byte-for-byte; confirm every error code at its
   exact site — E0382 (L2.1 broken, L2.5 broken1, L2.10 reject1), E0204 (L2.2
   broken — lower confidence), E0596 (L2.3 broken — lower confidence), E0502
   (L2.4 broken, L2.5 broken3, L2.8 equivalent.rs, L2.10 reject3), E0499 (L2.5
   broken2, L2.10 reject2), E0106 (L2.9 broken1), E0515 (L2.9 broken2, L2.10
   reject4), E0597 (L2.7 experiment, L2.9 broken3, L2.10 reject5) — plus every
   quoted message line; confirm all fixed variants compile and print the stated
   outputs; confirm the L2.7 experiment produces E0597 at the moved println. Fix
   content to reality and log every deviation.
5. Lint gates: `./tools/lint-labs.sh` (includes the shellcheck sweep) clean.
   ERE discipline in assert patterns: bracket characters escaped (see L2.5's
   builder note); desc/hint strings keep apostrophes and lifetime ticks out
   (already true in §4 — preserve that property when adjusting wording).
6. Acceptance: extend `tests/acceptance.sh` with a P2 section per the established
   per-lab pattern — fabricate passing artifacts WITHOUT a toolchain (echo answer
   files and outputs; `#!/bin/sh` stub binaries for ./sample, ./fixed, ./fixed1-3,
   ./fixed5; echo rust_error.txt for L2.8), pipe 3 quiz answers, expect pass; one
   negative case per lab (delete/corrupt one artifact → graded fail). Drive
   `lab start rust L2.1` with 5 piped recall answers, assert non-gating. Update
   every stale catalog-count denominator the moment p2's directories exist —
   check ALL call sites, not just the final one (standing precedent from the bash
   track close-outs).
7. Run the full phase manually once with the real toolchain (author's own
   `lab check` pass per lab) before tagging `rust-p2` per PROMPTS.md.
8. Update `planned_execution.md` (mark rust p2 done with evidence) — build
   session's job, not this plan's.

## 6. Decisions & deviations log (for the reviewer)

- **Recall sourced from the curriculum map, not disk** — p0/p1 are unbuilt at plan
  time; all five questions carry `[VERIFY-AT-BUILD]` and §5 step 3 makes the
  refinement mandatory. (`rust-p01-plan.md` §4 was used as a consistency
  cross-check only.)
- **Bare rustc everywhere; zero cargo in Phase 2** — no profiles, no dependencies;
  one-concept-per-lab holds (contrast: p01 needed cargo only for L1.2's
  debug/release profiles).
- **Forbidden-fix greps** (`clone` in L2.4 fixed.rs and L2.5 fixed1.rs;
  signature greps `<'a>` / `-> String` in L2.9) — same philosophy as L1.7's
  wildcard ban: the check should reject the fix that dodges the lesson, and each
  forbidden fix is named in lab.md, never a silent gotcha.
- **L2.8's crime.cpp is a read-only exhibit** — never compiled, never linted
  (lives in `files/`), no C++ toolchain assumed; the demo of record is the Rust
  twin's REAL rejection, captured to `rust_error.txt` via stderr redirect. All UB
  claims about the C++ side are phrased as "may" (may print 22, may crash) — no
  claim this plan can't stand behind without compiling it.
- **L2.10 breadth rides answers.txt** (ten keys) per L1.9 precedent — quiz.json is
  hard-capped at 3; one graded fix (reject5) keeps a runnable artifact so the
  gate still ends hands-on.
- **Error-code confidence tiers, stated honestly:** E0382/E0499/E0502/E0106/
  E0515/E0597 are high-confidence; **E0204 (L2.2) and E0596 (L2.3) are
  lower-confidence** and explicitly flagged at their sites — if the real compiler
  reports differently, content follows reality per the header rule.
- **NLL is load-bearing** for the L2.4/L2.5/L2.10 reordering fixes — "a borrow
  ends at its last use" is stated as a teaching line in §3 and taught in L2.4 so
  the fixes are principled, not incantations.
- **L2.3 uses `&String` parameters deliberately** (simplest possible borrow
  reading) with a one-line forward pointer; L2.6 owns the `&str`-preference and
  deref-coercion lesson and resolves the pointer. L2.5's fix1 uses `banner(&title)`
  one lab early with the same pointer — accepted cost, footnoted in both labs.
- **Plan-time verification coverage (honest report):** author self-review only —
  every expected output re-derived by hand (all string lengths counted:
  "port-22"=7, "core-router"=11, "https://vault:8443"=18,
  "credential-stuffing"=19 vs "port-sweep"=10); all error codes assigned from
  known diagnostics of stable rustc. No adversarial verification fleet was run at
  plan time. §5 step 4's toolchain sweep is the authoritative verification for
  every `[VERIFY-AT-BUILD]` tag regardless.
