# RUST TRACK — Phase 5 Build Plan (v1): Concurrency & Async

Binding content spec: `docs/curriculum/rust-literacy-lab-curriculum-v1.md` (Phase 5
section). Binding mechanical spec: `docs/kit-contracts.md`. Format precedent:
`docs/plans/rust-p01-plan.md`; conventions continued from the p2/p3/p4 plans §3.
Reference implementation of every file format:
`tracks/demo/phases/p0/L0.0-meet-the-kit/`.
This plan is the single source of design judgment for the build session — build it
mechanically; where reality contradicts a claim marked `[VERIFY-AT-BUILD]`, fix the
content to match reality and note the deviation in the build report.

Planning-context note: at plan time NOTHING in the rust track is built. Phases 0–4
exist only as plan documents. L5.1's recall questions are sourced from the
**curriculum map's lab lists** for Phases 0–4 (titles + descriptions), not from
disk content, and every one is `[VERIFY-AT-BUILD]` — the p5 build session refines
wording against the real built earlier phases (build order: p0–p4 first).

**The tokio dependency (read before building the async labs).** Phases 0–4 used
only bare `rustc` on single files or std-only cargo projects — zero third-party
deps, zero network. Phase 5's async labs (L5.5, L5.6) are the FIRST rust-track
content requiring an external crate: **tokio**. This is an explicit, contract-level
deviation, flagged here per `docs/kit-contracts.md`'s "propose deviations
explicitly" rule:
- The learner's own shell runs `cargo build`/`cargo run`, which fetches tokio from
  crates.io over the network — **exactly as L0.1's rustup install and L4.8's cargo
  audit already do in the learner shell.** check.sh STILL never runs cargo and
  never networks (the env -i fence guarantees it); grading stays artifact-based
  and CI-fabricatable.
- Only L5.5 and L5.6 ship a `Cargo.toml` with a tokio dependency. L5.1–L5.4 are
  std-only (threads, channels, Arc/Mutex — no runtime needed). L5.7 and L5.8 are
  **read-only tokio-shaped exhibits, never compiled** (so they need no dependency
  at all).
- The tokio version and feature set are pinned at build time and
  `[VERIFY-AT-BUILD]`.

## 1. Lab list (from the map, exactly)

| id | title (meta.json `title`) | type | gate | est_minutes | dir slug |
|---|---|---|---|---|---|
| L5.1 | Threads — why data races don't compile | PREDICT | false | 15 | `L5.1-threads-no-data-races` |
| L5.2 | `Send` / `Sync`, conceptually | DECODE | false | 15 | `L5.2-send-sync` |
| L5.3 | `Arc` / `Mutex` reading patterns | DECODE | false | 15 | `L5.3-arc-mutex` |
| L5.4 | Channels | PREDICT | false | 15 | `L5.4-channels` |
| L5.5 | async/await — the mental model | DECODE | false | 15 | `L5.5-async-await-model` |
| L5.6 | Reading a tokio main loop | DECODE | false | 15 | `L5.6-tokio-main-loop` |
| L5.7 | Timeouts, cancellation, resource exhaustion | AUDIT | false | 20 | `L5.7-async-dos` |
| L5.8 | Phase gate: trace a concurrent port scanner's data flow | DECODE | **true** | 20 | `L5.8-phase-gate-scanner-dataflow` |

Gate placement: the map marks L5.8 explicitly; no other gate.
recall.json placement: **L5.1 only** (5 questions, earlier phases, interleaved).

Phase security hook (map): data races are a real vulnerability class (CWE-362);
Rust makes them a **compile error** (L5.1–L5.3). L5.7 covers the async DoS
patterns that memory safety does NOT prevent — unbounded waits and unbounded
concurrency (CWE-400) — the Phase-4 thesis (memory safety ≠ security) carried into
the async world.

## 2. Binding harness constraints (unchanged — see rust-p2-plan.md §2)

Identical to Phases 2–4: check.sh never runs cargo/rustc (env -i fence hides
`~/.cargo/bin` AND blocks the network); all grading artifact-based and
CI-fabricatable without a toolchain; lint bans as listed; quiz.json exactly 3 /
hints.json exactly 3 levels / recap.md exactly 3 lines / lab.md exact headings;
answers base64, text answers lowercase-normalized with `accept_b64` variants; quiz
stdin one line per question; recall non-gating at `lab start` on the opener only.

**Determinism rule (critical for a concurrency phase):** every graded value must
be deterministic despite nondeterministic scheduling. All runnable samples are
built so the observable is order-independent — sums/counts/totals over join
handles or channels, never "the order threads printed." check.sh never asserts an
interleaving. Where output order could vary, the sample sorts before printing and
the lab says why (the L3.7 HashMap-ordering lesson, now for threads).

## 3. Track conventions (carried + Phase-5 additions)

Carried unchanged from the p01/p2/p3/p4 plans: `key=value` answer files
(`predictions.txt` PREDICT / `answers.txt` otherwise; options printed in lab.md;
anchored-ERE or `assert_file_contains_fixed` grading); PREDICT honor framing;
broken samples as separate files; quiz-vs-answers non-duplication; hints ladder L1
artifact → L2 exact line → L3 near-answer procedure; **ERE discipline — ALL ERE
metacharacters escaped in assert patterns** (brackets, `+`, parens, `?`, `*`, `.`
where literal-critical); descs/hints keep apostrophes out.

New for Phase 5:
- **Build tool per lab:** L5.1–L5.4 use bare `rustc` on single files (std threads/
  channels/Arc/Mutex need no cargo). L5.5–L5.6 use a **cargo project with a tokio
  dependency** (`cargo run`), the phase's only network-touching build step, run in
  the learner shell. L5.7–L5.8 are read-only exhibits (nothing compiled).
- **Read-only tokio exhibits** (L5.7, L5.8) extend the L2.8/L3.9/L4.2 exhibit
  pattern: realistic tokio-shaped code the learner AUDITS/TRACES by reading;
  graded via answers.txt; never compiled, so no tokio dependency and no binary.
  Their acceptance negative cases corrupt an answer key, not a binary.
- **Data-race compile-error convention:** L5.1/L5.2's `broken.rs` files fail to
  compile because the borrow/Send rules forbid the racy pattern — captured per the
  p2 rejection-evidence convention (`rustc broken.rs 2> rust_error.txt`, non-zero
  exit expected, check greps the code tag). The lesson is that the data race is a
  *build break*, not a runtime bug (CWE-362).
- **CWE ids this phase:** CWE-362 (race condition — made a compile error), CWE-400
  (uncontrolled resource consumption — the async DoS L5.7 audits). Tokens graded
  exactly in answers.txt per the p4 CWE convention (format printed in the BRIEF).

## 4. Lab entries

---

### L5.1 — Threads — why data races don't compile
**PREDICT · gate:false · est 15 · files/: sample.rs, broken.rs · recall.json: YES (phase opener)**
**objective:** "Predict the deterministic result of joined worker threads, and read the compile error that stops a shared-borrow data race before it can run (CWE-362)."

**recall.json — 5 questions, sourced from the curriculum map's Phase 0–4 lab
lists (nothing built at plan time). ALL FIVE `[VERIFY-AT-BUILD]`.**
1. choice (source: "rust L4.7 — what Rust does NOT stop") — "Memory-safe Rust can
   still contain…" a) use-after-free b) path traversal, injection, and logic
   bugs — memory safety is not security c) data races → **b**
2. choice (source: "rust L2.4 — aliasing XOR mutation") — "The borrow law:"
   a) many readers XOR one writer, never both at once b) one reader and one
   writer together c) unlimited writers → **a**
3. choice (source: "rust L3.2 — unwrap red flags") — "`unwrap()` on untrusted
   input is which risk class?" a) memory corruption b) denial of service — a
   crash on bad input c) privilege escalation → **b**
4. choice (source: "rust L4.4 — as truncation") — "`70000_u32 as u16` gives…"
   a) 65535 b) 4464 (silent truncation) c) a compile error → **b**
5. choice (source: "rust L3.1 — Result and ?") — "`?` on an `Err` value…"
   a) panics b) returns the Err to the caller immediately c) ignores it → **b**

**files/sample.rs (deterministic — the observable is a sum over join handles):**
```rust
use std::thread;

fn main() {
    let mut handles = Vec::new();
    for id in 0..4u32 {
        handles.push(thread::spawn(move || {
            // each thread owns its own copy of id (moved in)
            id * 10
        }));
    }

    let mut total = 0;
    for handle in handles {
        total += handle.join().unwrap();
    }
    println!("total = {total}");
    println!("threads joined; result is order-independent");
}
```
Expected output `[VERIFY-AT-BUILD]`: `total = 60` / `threads joined; result is
order-independent`. (0+1+2+3 = 6, ×10 = 60 — independent of completion order.)
Teaching beats: `thread::spawn` runs a closure on a new OS thread; `move`
transfers owned data into it (each thread owns its own `id` — no sharing, no
race); `join()` waits and returns the thread's value as a `Result`; the total is
deterministic because it sums returned values, never observes print order — the
determinism rule a reviewer insists on. One forward line: to *share* mutable
state you need L5.3's Arc/Mutex; to *send* messages you need L5.4's channels.

**files/broken.rs (a shared-borrow race the compiler refuses):**
```rust
use std::thread;

fn main() {
    let mut log = vec![String::from("start")];
    thread::spawn(|| {
        log.push(String::from("from thread")); // borrows log by reference
    });
    log.push(String::from("from main"));
    println!("{log:?}");
}
```
Must fail to compile — the closure borrows `log` but the spawned thread may
outlive `main`'s frame, and `log` is also used in main: a data race the borrow +
`'static` rules forbid. Expected **E0373** ("closure may outlive the current
function, but it borrows `log`") `[VERIFY-AT-BUILD: exact code — E0373 is the
likely primary; if rustc leads with E0505/a Send error instead, record the real
one]`. Capture: `rustc broken.rs 2> rust_error.txt`, non-zero exit expected.
Teaching: the compiler stops the race at BUILD time — the fix is `move` (give the
thread its own data) or Arc/Mutex (share it safely), never "hope the timing works
out." This is CWE-362 turned into a compile error.

**GUIDED STEPS outline:** read sample.rs → `predictions.txt`: `total=60` (the sum)
→ `rustc sample.rs -o sample && ./sample` → compare → `rustc broken.rs 2>
rust_error.txt` (expect failure), read the tag, record `error=E0373` → check.

**CHECK LOGIC:** `assert_file_contains predictions.txt '^total=60$'`,
`'^error=E0373$'`;
`assert_output_contains 'sample joins threads' 'total = 60' 'step 2 — rustc
sample.rs -o sample' -- ./sample`;
`assert_file_contains rust_error.txt 'error\[E0373\]'` (hint: step 4 — capture
with `rustc broken.rs 2> rust_error.txt`) `[VERIFY-AT-BUILD: bracket tag shape];`
`ck_summary`.
(CI fabrication: echo the two prediction lines; `#!/bin/sh` stub printing the two
output lines as `./sample`; echo an `error[E0373]` line into rust_error.txt.)

**QUIZ:**
1. choice — "Why does the broken closure not compile?" a) threads are unsafe
   b) it borrows `log` by reference, but the thread could outlive that borrow —
   a data race the compiler refuses c) Vec is not thread-safe → **b**
2. choice — "The two safe ways to give a thread data:" a) globals and statics
   b) `move` it in (owned), or share it behind Arc/Mutex — never a bare borrow
   c) raw pointers → **b**
3. text — "Data races are which CWE class (format CWE-###)?" → **cwe-362**
   (accept: `362`, `cwe 362`)

**RECAP:**
```
thread::spawn + move gives each thread its own data; join returns its value as a Result
a bare shared borrow across a thread boundary is a data race — the compiler refuses it (CWE-362)
determinism rule: grade sums/totals over joins, never the order threads happened to print
```

**HINTS:** L1: two prediction keys (total, error) — the grader names the miss.
L2: total sums 0..3 then ×10 — order-independent; the broken file's closure
borrows `log` without `move`, so the thread could outlive it. L3: run and
transcribe — `rustc sample.rs -o sample; ./sample; rustc broken.rs 2>
rust_error.txt` — the `error[E....]` tag is the answer.

---

### L5.2 — `Send` / `Sync`, conceptually
**DECODE · gate:false · est 15 · files/: sample.rs, broken.rs**
**objective:** "Read Send/Sync as the marker traits that gate cross-thread movement, and read the E0277 that stops a non-Send `Rc` from entering a thread."

**files/sample.rs (Arc IS Send + Sync — moves across a thread cleanly):**
```rust
use std::sync::Arc;
use std::thread;

fn main() {
    // Arc<T> is Send + Sync (when T is): it can cross thread boundaries.
    let shared = Arc::new(vec![10u32, 20, 30]);

    let clone = Arc::clone(&shared);
    let handle = thread::spawn(move || {
        // read-only access from another thread — Sync makes &Arc shareable
        clone.iter().sum::<u32>()
    });

    let from_thread = handle.join().unwrap();
    let from_main: u32 = shared.iter().sum();
    println!("from_thread = {from_thread}");
    println!("from_main = {from_main}");
    println!("strong_count = {}", Arc::strong_count(&shared));
}
```
Expected output `[VERIFY-AT-BUILD]`: `from_thread = 60` / `from_main = 60` /
`strong_count = 1` `[VERIFY-AT-BUILD: strong_count after the thread joined and its
`clone` dropped — likely 1; confirm]`.
Teaching beats: **Send** = "safe to MOVE ownership to another thread"; **Sync** =
"safe to SHARE `&T` across threads" (`T: Sync` ⟺ `&T: Send`); they are *auto
traits* — the compiler derives them structurally, you rarely write them; `Arc<T>`
is Send+Sync so it crosses the boundary, and that is exactly why concurrent code
reaches for it; the whole cross-thread type system is these two markers — reading
a "cannot be sent between threads" error means "this type is !Send."

**files/broken.rs (Rc is !Send — refused at the boundary):**
```rust
use std::rc::Rc;
use std::thread;

fn main() {
    let counter = Rc::new(5);
    let clone = Rc::clone(&counter);
    thread::spawn(move || {
        println!("{}", clone); // Rc is !Send — cannot cross the boundary
    });
}
```
Must produce **E0277** — "`Rc<i32>` cannot be sent between threads safely" / "the
trait `Send` is not implemented for `Rc<i32>`" `[VERIFY-AT-BUILD: exact message;
the code is E0277]`. Teaching: `Rc`'s reference count is NOT atomic — sharing it
across threads would race the count itself (a real CWE-362), so the compiler marks
`Rc` `!Send` and refuses; the fix is `Arc` (atomic count). Capture:
`rustc broken.rs 2> rust_error.txt`.

**GUIDED STEPS outline:** read sample → compile/run → answers.txt (options in
lab.md): q1 (choice) Send means: a) safe to move ownership to another thread
b) safe to share a reference c) thread-local → `q1=a`; q2 (choice) Sync means:
a) safe to move b) safe to share `&T` across threads (`&T: Send`) c) atomic →
`q2=b`; q3 (value) from_thread → `q3=60`; q4 (choice) why is `Rc` !Send? a) it is
slow b) its reference count is non-atomic — sharing across threads would race the
count (CWE-362), so the compiler forbids it c) it is deprecated → `q4=b`; then
`rustc broken.rs 2> rust_error.txt` (expect failure), read the tag, and record q5
(value) the error code when moving Rc into a thread → `q5=E0277` → check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=a$'`, `'^q2=b$'`,
`'^q3=60$'`, `'^q4=b$'`, `'^q5=E0277$'`;
`assert_output_contains 'sample shares via Arc' 'from_thread = 60' 'step 2 —
rustc sample.rs -o sample' -- ./sample`;
`assert_file_contains rust_error.txt 'error\[E0277\]'` (hint: step 4 — capture
`rustc broken.rs 2> rust_error.txt`); `ck_summary`.

**QUIZ:**
1. choice — "`Send` vs `Sync`:" a) Send = move to another thread; Sync = share
   `&T` across threads b) identical c) Send is for channels only → **a**
2. choice — "`Rc` vs `Arc` across threads:" a) both work b) only `Arc` — its
   count is atomic; `Rc` is !Send because its count is not c) only `Rc` → **b**
3. text — "Send and Sync are ___ traits — the compiler derives them
   structurally, you rarely implement them by hand." → **auto** (accept: `marker`,
   `automatic`)

**RECAP:**
```
Send = safe to move to another thread; Sync = safe to share &T across threads
they are auto traits — a "cannot be sent between threads" error means the type is !Send
Rc is !Send (non-atomic count); Arc is the thread-safe fix — atomic reference counting
```

**HINTS:** L1: five answer keys — options in step 3. L2: q1/q2 are the two
definitions from the BRIEF (move vs share); q3 sums 10+20+30; the Rc error is
E0277. L3: run and transcribe — `rustc sample.rs -o sample; ./sample; rustc
broken.rs 2> rust_error.txt`.

---

### L5.3 — `Arc` / `Mutex` reading patterns
**DECODE · gate:false · est 15 · files/: sample.rs**
**objective:** "Read the Arc<Mutex<T>> shared-counter pattern, explain what each layer does, and know that lock() returns a guard that unlocks on drop."

**files/sample.rs (deterministic total — N threads × K increments):**
```rust
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    // Arc = shared OWNERSHIP across threads; Mutex = synchronized ACCESS.
    let counter = Arc::new(Mutex::new(0u32));

    let mut handles = Vec::new();
    for _ in 0..4 {
        let c = Arc::clone(&counter);
        handles.push(thread::spawn(move || {
            for _ in 0..25 {
                let mut guard = c.lock().unwrap(); // acquire the lock
                *guard += 1;
            }                                      // guard drops here -> unlock
        }));
    }

    for handle in handles {
        handle.join().unwrap();
    }

    println!("count = {}", *counter.lock().unwrap());
}
```
Expected output `[VERIFY-AT-BUILD]`: `count = 100` (4 threads × 25 = 100,
deterministic — the Mutex serializes every increment).
Teaching beats: the pattern is two layers with two jobs — `Arc` gives every
thread shared *ownership* of the same allocation; `Mutex` gives *synchronized
access* so only one thread mutates at a time (this is what makes `+= 1`
race-free); `lock()` returns a `Result<MutexGuard>` (Err only if the lock is
"poisoned" — a holder panicked), and the guard is a smart pointer that
**releases the lock when it drops** (RAII — no manual unlock, no forgetting);
without the Mutex the count would race and without the Arc the threads couldn't
share it at all — you need both.

**GUIDED STEPS outline:** read → compile/run → answers.txt (options in lab.md):
q1 (choice) Arc's job here: a) synchronize access b) shared ownership — every
thread points at the same allocation c) speed → `q1=b`; q2 (choice) Mutex's job:
a) shared ownership b) synchronized access — one mutator at a time, making `+= 1`
race-free c) atomic reference counting → `q2=b`; q3 (value) the printed count →
`q3=100`; q4 (choice) when is the lock released? a) manual unlock() call b) when
the `MutexGuard` drops — at the end of its scope (RAII) c) never, until the
program exits → `q4=b`; q5 (choice) what does `lock()` return an Err on? a) never
b) a "poisoned" mutex — a previous holder panicked while holding it c) timeout →
`q5=b` → check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=b$'`,
`'^q3=100$'`, `'^q4=b$'`, `'^q5=b$'`;
`assert_output_contains 'sample counts to 100' 'count = 100' 'step 2 — rustc
sample.rs -o sample' -- ./sample`; `ck_summary`.

**QUIZ:**
1. choice — "In `Arc<Mutex<T>>`, the two layers do…" a) the same thing twice
   b) Arc = shared ownership across threads, Mutex = one-at-a-time access
   c) Arc locks, Mutex counts → **b**
2. choice — "A `MutexGuard` releases the lock…" a) when you call unlock()
   b) automatically when it goes out of scope (RAII) c) after a timeout → **b**
3. text — "A mutex whose previous holder panicked while locked is said to be
   ___." → **poisoned**

**RECAP:**
```
Arc<Mutex<T>> = shared ownership (Arc) + synchronized access (Mutex) — you need both
lock() returns a guard; the guard unlocks on drop (RAII) — no manual unlock to forget
lock() errors only on a poisoned mutex — a prior holder panicked while holding it
```

**HINTS:** L1: five answer keys — options in step 3. L2: q1/q2 split the two
layers (own vs synchronize); q3 is 4×25; q4 is the RAII drop; q5 is poisoning.
L3: run and transcribe — `rustc sample.rs -o sample; ./sample`.

---

### L5.4 — Channels
**PREDICT · gate:false · est 15 · files/: sample.rs**
**objective:** "Predict the deterministic total and count a receiver collects from producer threads, and explain when the receiving loop ends (all senders dropped)."

**files/sample.rs (deterministic total/count; order may vary, sum does not):**
```rust
use std::sync::mpsc;
use std::thread;

fn main() {
    let (tx, rx) = mpsc::channel::<u32>();

    for id in 0..3u32 {
        let tx = tx.clone();
        thread::spawn(move || {
            // each producer sends one value; clones of tx are separate senders
            tx.send((id + 1) * 100).unwrap();
        });
    }
    drop(tx); // drop the original: now only the 3 clones remain

    let mut total = 0;
    let mut count = 0;
    for value in rx { // ends when ALL senders have dropped
        total += value;
        count += 1;
    }
    println!("count = {count}");
    println!("total = {total}");
}
```
Expected output `[VERIFY-AT-BUILD]`: `count = 3` / `total = 600`. (Producers send
100, 200, 300; sum = 600; count = 3 — both order-independent.)
Teaching beats: `mpsc` = multi-producer, single-consumer; `tx.clone()` makes an
independent sender, `rx` is the single receiver; `for value in rx` iterates until
**every** sender (the original + all clones) has dropped — that is what closes the
channel and ends the loop (forgetting to `drop(tx)` here would hang forever
waiting on the original sender — a real deadlock beat, called out in lab.md); the
total is deterministic, the *order* of arrival is not — grade the sum, not the
sequence.

**GUIDED STEPS outline:** read (honor framing) → `predictions.txt`: `count=3`,
`total=600` → compile/run → compare → check.

**CHECK LOGIC:** `assert_file_contains predictions.txt '^count=3$'`,
`'^total=600$'`;
`assert_output_contains 'sample sums channel values' 'total = 600' 'step 3 —
rustc sample.rs -o sample' -- ./sample`; `ck_summary`.

**QUIZ:**
1. choice — "`mpsc` stands for and means…" a) multi-producer, single-consumer —
   many senders, one receiver b) multi-process shared channel c) mutex-protected
   sender channel → **a**
2. choice — "`for value in rx` ends when…" a) the first value arrives b) every
   sender (original + clones) has dropped, closing the channel c) after a fixed
   count → **b**
3. text — "Forgetting to drop the original `tx` here makes the receive loop ___
   forever." → **hang** (accept: `block`, `wait`, `deadlock`)

**RECAP:**
```
mpsc = many senders (clone tx), one receiver (rx) — message passing, not shared state
for v in rx runs until ALL senders drop; a stray live sender hangs the loop forever
grade the total, never the arrival order — the sum is deterministic, the sequence is not
```

**HINTS:** L1: two prediction keys (count, total). L2: three producers send
(id+1)×100 → 100, 200, 300; count is how many values arrive; the sum is
order-independent. L3: run and transcribe — `rustc sample.rs -o sample;
./sample`.

---

### L5.5 — async/await — the mental model
**DECODE · gate:false · est 15 · files/: async_demo/ (cargo project, tokio dep)**
**objective:** "Read async/await correctly: an async fn returns an inert Future that does nothing until awaited, and the runtime is what drives it to completion."

**files/async_demo/Cargo.toml** `[VERIFY-AT-BUILD: pin the current tokio release.
Feature set is deliberately minimal — the `current_thread` flavor (see main.rs)
needs only `rt`, NOT `rt-multi-thread`; `macros` for #[tokio::main], `time` for
sleep. Confirm this compiles as the smallest set.]`:
```toml
[package]
name = "async_demo"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1", features = ["rt", "macros", "time"] }
```
**files/async_demo/src/main.rs:**
```rust
use tokio::time::{sleep, Duration};

async fn work(id: u32) -> u32 {
    // an async fn body does NOT run when called — only when the returned
    // Future is awaited. This sleep yields control back to the runtime.
    sleep(Duration::from_millis(10)).await;
    id * 2
}

// current_thread flavor: one thread, so join! below is concurrency (interleaving
// awaits), never parallelism — exactly the mental model this lab teaches.
#[tokio::main(flavor = "current_thread")]
async fn main() {
    let fut = work(21);                 // nothing has run yet — fut is inert
    println!("future created, not yet awaited");

    let result = fut.await;             // NOW work(21) actually runs
    println!("result = {result}");

    // join! drives two futures concurrently on this one thread
    let (a, b) = tokio::join!(work(1), work(2));
    println!("a = {a}, b = {b}");
}
```
Expected output `[VERIFY-AT-BUILD]`: `future created, not yet awaited` /
`result = 42` / `a = 2, b = 4`.
Teaching beats: calling an `async fn` returns a `Future` and runs NOTHING —
Rust's futures are *lazy* (contrast: in many languages an async call starts
immediately); `.await` is what drives the future and yields control to the
runtime while it waits; `#[tokio::main]` is the macro that sets up the runtime and
"drives" `main`'s future to completion — without a runtime, `.await` has nothing
to poll it; `tokio::join!` awaits multiple futures concurrently on one thread
(concurrency, not necessarily parallelism) — the mental model that makes reading a
tokio program possible.

**GUIDED STEPS outline (learner shell; first tokio fetch is one-time, network):**
`cd async_demo && cargo run > ../async_out.txt && cd ..` (build noise to stderr,
program output to the file) → answers.txt (options in lab.md):
- q1 (choice) calling `work(21)` (without .await) does: a) runs it immediately
  b) returns an inert Future — nothing runs until it is awaited c) spawns a
  thread → `q1=b`
- q2 (choice) what does `.await` do? a) blocks the OS thread b) drives the future
  and yields to the runtime while it waits c) forks → `q2=b`
- q3 (value) the printed result of `fut.await` → `q3=42`
- q4 (choice) `#[tokio::main]`'s role: a) marks the fn async b) sets up the
  runtime that drives `main`'s future — without it, `.await` has nothing to poll
  c) enables threads → `q4=b`
- q5 (choice) `tokio::join!(work(1), work(2))` runs them… a) one fully then the
  other, always b) concurrently, awaiting both c) on two OS threads guaranteed →
  `q5=b`

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=b$'`,
`'^q3=42$'`, `'^q4=b$'`, `'^q5=b$'`;
`assert_file_contains_fixed async_out.txt 'result = 42'` (hint: step 1 —
`cargo run > ../async_out.txt` from inside async_demo);
`assert_file_contains_fixed async_out.txt 'a = 2, b = 4'`;
`ck_summary`.
(CI fabrication: echo the answers; echo the three output lines into
async_out.txt — no toolchain/network needed for acceptance.)

**QUIZ:**
1. choice — "Calling an `async fn` in Rust…" a) starts running immediately
   b) returns a lazy Future that does nothing until awaited c) always spawns a
   task → **b**
2. choice — "Why does `.await` need a runtime like tokio?" a) it doesn't b) a
   future must be polled to make progress; the runtime is what polls it — without
   one, `.await` is inert c) for logging → **b**
3. text — "Rust's futures are ___ — they make no progress until polled/awaited."
   → **lazy** (accept: `inert`, `cold`)

**RECAP:**
```
an async fn returns a lazy Future — calling it runs NOTHING until you .await it
.await drives the future and yields to the runtime while it waits — no thread blocked
#[tokio::main] is the runtime that polls main's future; join! awaits many concurrently
```

**HINTS:** L1: five answer keys and async_out.txt — the grader names each miss;
the first `cargo run` fetches tokio once (network). L2: q1/q2 are the laziness and
the drive-it roles from the BRIEF; q3 is 21×2; q4 is what the macro provides.
L3: `cd async_demo; cargo run > ../async_out.txt; cd ..` then read the file —
"result = 42" and "a = 2, b = 4" are the answers.

---

### L5.6 — Reading a tokio main loop
**DECODE · gate:false · est 15 · files/: tokio_loop/ (cargo project, tokio dep)**
**objective:** "Read a real tokio task-spawning main loop: spawn concurrent tasks, await them as they finish, and accumulate a deterministic result."

**files/tokio_loop/Cargo.toml** `[VERIFY-AT-BUILD: pin tokio; JoinSet needs the
`rt` feature — confirm the minimal set]`:
```toml
[package]
name = "tokio_loop"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1", features = ["rt", "rt-multi-thread", "macros", "time"] }
```
**files/tokio_loop/src/main.rs:**
```rust
use tokio::task::JoinSet;
use tokio::time::{sleep, Duration};

async fn probe(port: u16) -> u16 {
    // pretend work: a short async wait, then "report" the port squared-ish
    sleep(Duration::from_millis((port % 5) as u64)).await;
    port
}

#[tokio::main]
async fn main() {
    let mut set = JoinSet::new();

    // the main loop: spawn one concurrent task per port
    for port in [22u16, 80, 443, 8080] {
        set.spawn(probe(port));
    }

    // drain: await tasks AS THEY COMPLETE (order not guaranteed)
    let mut sum: u32 = 0;
    let mut done = 0;
    while let Some(result) = set.join_next().await {
        sum += result.unwrap() as u32;
        done += 1;
    }

    println!("tasks completed = {done}");
    println!("port sum = {sum}");
}
```
Expected output `[VERIFY-AT-BUILD]`: `tasks completed = 4` / `port sum = 8625`.
(22+80+443+8080 = 8625, order-independent.)
Teaching beats: `#[tokio::main]` wraps an async `main`; the **spawn loop** —
`set.spawn(future)` — launches concurrent tasks (each may run on a runtime worker
thread, but you don't manage threads directly); `join_next().await` is the drain
loop — it yields each task's result *as it finishes*, in completion order, which
is why the accumulator must be order-independent; this spawn-then-drain shape is
the skeleton of nearly every tokio tool (a server's accept loop, a scanner's port
loop, a pipeline's worker pool) — read it once and you can read them all; a
`JoinSet` owns its tasks and cancels any still running if dropped (a cancellation
foreshadow for L5.7).

**GUIDED STEPS outline (learner shell; tokio already cached from L5.5):**
`cd tokio_loop && cargo run > ../loop_out.txt && cd ..` → answers.txt (options in
lab.md):
- q1 (choice) `set.spawn(probe(port))` in the loop: a) runs each probe to
  completion before the next b) launches concurrent tasks the runtime drives
  c) creates OS threads you must join → `q1=b`
- q2 (choice) `join_next().await` yields results… a) in spawn order b) in
  completion order — whichever task finishes next c) all at once → `q2=b`
- q3 (value) tasks completed → `q3=4`
- q4 (value) the port sum printed → `q4=8625`
- q5 (choice) why must `sum` be an order-independent accumulator? a) style
  b) tasks complete in nondeterministic order, so only an order-independent
  result (a sum) is stable c) tokio requires it → `q5=b`

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=b$'`,
`'^q3=4$'`, `'^q4=8625$'`, `'^q5=b$'`;
`assert_file_contains_fixed loop_out.txt 'port sum = 8625'` (hint: step 1 —
`cargo run > ../loop_out.txt` inside tokio_loop);
`ck_summary`.
(CI fabrication: echo the answers; echo the two output lines into loop_out.txt.)

**QUIZ:**
1. choice — "The tokio spawn-then-drain loop is…" a) a rare pattern b) the
   skeleton of most tokio tools — servers, scanners, worker pools all share it
   c) slower than threads → **b**
2. choice — "`JoinSet::join_next().await` returns tasks…" a) in the order they
   were spawned b) as they complete — nondeterministic order c) sorted → **b**
3. text — "A JoinSet, when dropped, ___ any tasks still running." → **cancels**
   (accept: `aborts`, `cancel`, `abort`)

**RECAP:**
```
#[tokio::main] + a spawn loop + a join_next drain loop — the shape of most tokio tools
tasks are spawned concurrently and awaited in COMPLETION order, not spawn order
accumulate order-independently (a sum); a JoinSet cancels unfinished tasks when dropped
```

**HINTS:** L1: five answer keys and loop_out.txt. L2: q1/q2 are the spawn
(concurrent) and drain (completion-order) halves; q3 is the port count (four);
q4 sums the four port numbers. L3: `cd tokio_loop; cargo run > ../loop_out.txt;
cd ..` — "port sum = 8625" is q4.

---

### L5.7 — Timeouts, cancellation, resource exhaustion
**AUDIT · gate:false · est 20 · files/: server.rs (READ-ONLY tokio-shaped exhibit — never compiled)**
**objective:** "Audit an async service for the DoS patterns memory safety never prevents — an unbounded await and unbounded task spawning — and name the controls that fix them (CWE-400)."

**files/server.rs (READ-ONLY EXHIBIT — tokio-shaped; banner says do not compile;
no Cargo.toml, no tokio dep needed; framing rule: the audit is by reading):**
```rust
// server.rs — READ-ONLY EXHIBIT (tokio-shaped; not compiled here). Audit this
// accept loop for async DoS patterns. It is memory-safe. It is not safe.
use tokio::net::TcpListener;

async fn handle(mut conn: tokio::net::TcpStream) {
    let mut buf = vec![0u8; 1024];
    // FLAW 1 (CWE-400): read with NO timeout. A client that connects and never
    // sends holds this task open forever (slowloris) — an unbounded await.
    let _ = conn_read(&mut conn, &mut buf).await;
    // ... process ...
}

#[tokio::main]
async fn main() {
    let listener = TcpListener::bind("0.0.0.0:9000").await.unwrap();
    loop {
        let (conn, _addr) = listener.accept().await.unwrap();
        // FLAW 2 (CWE-400): spawn per connection with NO concurrency cap. A flood
        // of connections spawns unbounded tasks — memory/FD exhaustion.
        tokio::spawn(handle(conn));
    }
}

// (conn_read is a stand-in for an awaited read with no time bound)
async fn conn_read(_c: &mut tokio::net::TcpStream, _b: &mut [u8]) -> usize { 0 }
```
Audit findings (answer key):
1. **Unbounded await (FLAW 1)** — the read has no timeout; a client that never
   sends holds the task (and its buffer/FD) open indefinitely — a slowloris-style
   resource hold. **Class: uncontrolled resource consumption, CWE-400.** Fix:
   wrap the await in `tokio::time::timeout(dur, conn_read(...))` and drop the
   connection on elapse.
2. **Unbounded spawning (FLAW 2)** — one `tokio::spawn` per accepted connection
   with no cap; a connection flood spawns unbounded tasks → memory/FD exhaustion.
   **Class: CWE-400.** Fix: a `tokio::sync::Semaphore` (acquire a permit before
   spawning) or a bounded worker pool / bounded channel — cap concurrent tasks.
3. **No cancellation path** — nothing cancels in-flight work on shutdown or
   overload; graceful degradation needs a cancellation signal
   (`CancellationToken` / `select!` on a shutdown future).
The through-line: every flaw compiles and is 100% memory-safe — availability is a
*separate* property from memory safety (the Phase-4 thesis, now async).

**GUIDED STEPS outline:** read server.rs as a reviewer (nothing compiles — lab.md
says so) → answers.txt (options + CWE vocabulary in lab.md):
- q1 (choice) FLAW 1 is: a) a memory leak b) an unbounded await — a read with no
  timeout lets a silent client hold the task open forever (slowloris) → `q1=b`
- q2 (choice) the fix for FLAW 1: a) a bigger buffer b) `tokio::time::timeout`
  around the await, dropping the connection on elapse c) more threads → `q2=b`
- q3 (choice) FLAW 2 is: a) fine — spawn is cheap b) unbounded task spawning per
  connection — a flood exhausts memory/FDs c) a syntax error → `q3=b`
- q4 (choice) the fix for FLAW 2: a) unwrap less b) cap concurrency — a Semaphore
  permit before each spawn, or a bounded pool/channel c) sleep between accepts →
  `q4=b`
- q5 (value) the CWE for uncontrolled resource consumption (format CWE-###, in the
  brief) → `q5=CWE-400`
- q6 (choice) these flaws coexist with: a) an unsafe block b) complete memory
  safety — the borrow checker is satisfied; availability is a separate property
  c) a data race → `q6=b`

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=b$'`,
`'^q3=b$'`, `'^q4=b$'`, `'^q6=b$'`;
`assert_file_contains_fixed answers.txt 'q5=CWE-400'`;
`ck_summary`. (Pure-reading lab: answers.txt only; no binary, nothing compiled;
decision logged in §6. CI fabrication: echo the six lines.)

**QUIZ:**
1. choice — "An awaited read with no timeout is…" a) fine, async is safe b) an
   unbounded-await DoS — a silent client holds the task and its resources open
   indefinitely c) a compile error → **b**
2. choice — "The control that caps concurrent async tasks:" a) a bigger buffer
   b) a Semaphore (or bounded pool/channel) — acquire a permit before spawning
   c) more unwraps → **b**
3. text — "Uncontrolled resource consumption is which CWE (format CWE-###)?" →
   **cwe-400** (accept: `400`, `cwe 400`)

**RECAP:**
```
async DoS is real: an awaited read with no timeout and unbounded spawns are CWE-400
fixes are controls — tokio::time::timeout around awaits, a Semaphore to cap concurrency
memory-safe async is still not available-by-default; timeouts and caps are the review items
```

**HINTS:** L1: six answer keys, all read from server.rs — nothing runs; the CWE
format is in the BRIEF. L2: FLAW 1 is the timeout-less await (its `// FLAW 1`
comment points at it); FLAW 2 is the uncapped spawn; both are CWE-400; the fixes
are timeout and Semaphore. L3: re-read the two `// FLAW` comments and the audit
points in the BRIEF — each maps to one answer; the CWE for resource exhaustion is
CWE-400.

---

### L5.8 — Phase gate: trace a concurrent port scanner's data flow
**DECODE · gate:TRUE · est 20 · files/: scanner.rs (READ-ONLY tokio-shaped exhibit — never compiled or run)**
**objective:** "Prove Phase 5: trace a concurrent scanner's data flow cold — where concurrency is bounded, how results flow back, why it is race-free, and the one control that keeps it from exhausting itself."

**files/scanner.rs (READ-ONLY EXHIBIT — a realistic bounded-concurrency scanner;
banner says read only, do not compile or run. It is a data-flow READING exercise,
the map's chosen gate. The scan target is a placeholder; the lab never executes
it — see §6):**
```rust
// scanner.rs — READ-ONLY EXHIBIT. Trace the DATA FLOW; do not compile or run.
// A bounded-concurrency TCP port scanner: the standard tokio architecture.
use std::sync::Arc;
use tokio::net::TcpStream;
use tokio::sync::{mpsc, Semaphore};
use tokio::time::{timeout, Duration};

const MAX_IN_FLIGHT: usize = 100;   // concurrency cap
const CONNECT_TIMEOUT: Duration = Duration::from_millis(500);

async fn probe(host: String, port: u16) -> Option<u16> {
    // bounded await: a connect that cannot hang longer than CONNECT_TIMEOUT
    match timeout(CONNECT_TIMEOUT, TcpStream::connect((host, port))).await {
        Ok(Ok(_stream)) => Some(port),   // connected -> port is open
        _ => None,                       // timed out or refused -> closed
    }
}

#[tokio::main]
async fn main() {
    let host = String::from("scanme.example.test");
    // the permit pool: at most MAX_IN_FLIGHT probes run at once
    let limiter = Arc::new(Semaphore::new(MAX_IN_FLIGHT));
    let (tx, mut rx) = mpsc::channel::<u16>(MAX_IN_FLIGHT);

    // producer: spawn one bounded task per port
    for port in 1u16..=1024 {
        let permit = Arc::clone(&limiter).acquire_owned().await.unwrap();
        let tx = tx.clone();
        let host = host.clone();
        tokio::spawn(async move {
            if let Some(open) = probe(host, port).await {
                let _ = tx.send(open).await;   // report open ports over the channel
            }
            drop(permit);                      // release the slot on finish
        });
    }
    drop(tx); // drop the original sender so the collector loop can end

    // consumer: collect open ports until every sender has dropped
    let mut open_ports: Vec<u16> = Vec::new();
    while let Some(port) = rx.recv().await {
        open_ports.push(port);
    }
    open_ports.sort();   // completion order is nondeterministic — sort to stabilize
    println!("open ports: {open_ports:?}");
}
```
Teaching beats (the phase, assembled): this one file uses every Phase-5 idea —
**Semaphore** (L5.7's fix) bounds concurrency to `MAX_IN_FLIGHT` so the scanner
can't exhaust its own FDs; **timeout** (L5.7) bounds each connect so a filtered
port can't hang a task; **channel** (L5.4) carries results from many producers to
one consumer; **spawn loop** (L5.6) launches the work; **Arc** (L5.3) shares the
semaphore across tasks; the result is **race-free** because nothing is shared
mutably — each task owns its port and reports by *message*, not by touching shared
state (the L5.1 lesson); and the final `sort()` exists because completion order is
nondeterministic (the determinism rule). This IS RustScan's architecture in
miniature — Phase 6 tours the real thing.

**The 10 data-flow questions** (options in lab.md; breadth rides answers.txt per
the gate precedent; honor contract restated: trace from the source first):
1. value — the constant that caps concurrent probes → `q1=MAX_IN_FLIGHT`
2. value — how many probes run at once, at most (the number) → `q2=100`
3. choice — what bounds each individual connect? a) the Semaphore b) `timeout`
   with CONNECT_TIMEOUT — a connect cannot hang past 500ms c) nothing → `q3=b`
4. choice — how do open ports get from the tasks back to main? a) a shared Vec
   b) an mpsc channel — each task sends, main receives c) a global → `q4=b`
5. choice — why is this scanner race-free without any Mutex? a) luck b) nothing
   is shared mutably — each task owns its port and reports by message, not by
   touching shared state c) tokio disables races → `q5=b`
6. choice — what does `drop(permit)` do? a) closes the channel b) releases the
   semaphore slot so a waiting probe can start c) cancels the task → `q6=b`
7. choice — why `drop(tx)` before the collector loop? a) to save memory b) so the
   receive loop can end once every sender has dropped — otherwise it hangs
   c) to reset the channel → `q7=b`
8. choice — why the final `sort()`? a) speed b) probes complete in
   nondeterministic order, so the output is sorted to be stable/comparable
   c) tokio requires it → `q8=b`
9. choice — which single control most directly prevents the scanner exhausting
   its own resources? a) the timeout b) the Semaphore concurrency cap (CWE-400
   defense) c) the sort → `q9=b`
10. choice — the Phase-5 verdict this file demonstrates: a) async is unsafe
    b) Rust makes data races a compile error, but availability (timeouts, caps)
    is still the reviewer's job c) concurrency needs unsafe → `q10=b`

**GUIDED STEPS outline:** read scanner.rs cold, trace the data flow (nothing
compiles or runs — lab.md says so) → answer all 10 from the source → check.

**CHECK LOGIC:** `assert_file_contains_fixed answers.txt 'q1=MAX_IN_FLIGHT'`;
nine anchored greps — `assert_file_contains answers.txt '^q2=100$'`, `'^q3=b$'`,
`'^q4=b$'`, `'^q5=b$'`, `'^q6=b$'`, `'^q7=b$'`, `'^q8=b$'`, `'^q9=b$'`,
`'^q10=b$'`; `ck_summary`.
(Pure-reading gate: answers.txt only; no binary. CI fabrication: echo ten lines.
Negative case corrupts a key.)

**QUIZ (concept-level, not duplicating the 10):**
1. choice — "The standard bounded-concurrency tool architecture is…" a) one
   thread per task, unbounded b) a Semaphore-capped spawn loop feeding results
   through a channel to one collector c) a single blocking loop → **b**
2. choice — "This scanner is race-free because…" a) it uses a Mutex everywhere
   b) it shares nothing mutably — tasks own their data and communicate by message
   c) tokio is single-threaded → **b**
3. text — "The primitive here that caps how many probes run at once." →
   **semaphore**

**RECAP:**
```
gate passed: traced a bounded async scanner — Semaphore cap, timeout, channel, spawn loop
race-free by sharing nothing mutably: own your data, report by message, sort to stabilize
Phase 5 verdict: Rust kills data races at compile time; timeouts and caps are still your job
```

**HINTS:** L1: ten keys q1..q10, all read from scanner.rs — the grader names each
miss. L2: q1/q2 are the concurrency-cap constant and its value (100); q3 is the
`timeout` wrapper; q4 is the mpsc channel; q6/q7 are the permit release and the
sender drop; q9 is the Semaphore (the CWE-400 defense from L5.7). L3: walk the
data from `for port in 1..=1024` → acquire permit → spawn → probe → send → recv →
sort; each step answers one question.

---

## 5. Build-session protocol (execute in this order)

0. **Prerequisite: Phases 0–4 built first** (recall refinement + `lab`
   progression).
1. Scaffold the 8 lab directories under `tracks/rust/phases/p5/` per §1 slugs.
2. Author content straight from §4; base64 all answers; `accept_b64` variants as
   listed.
3. **Refine L5.1's recall.json** against the real built p0–p4 content (all five
   questions are map-sourced placeholders, `[VERIFY-AT-BUILD]`).
4. **[VERIFY-AT-BUILD] sweep (real toolchain + network for the tokio labs; never
   inside check.sh):**
   - **std labs (L5.1–L5.4):** compile/run with bare `rustc`; confirm every
     deterministic value (L5.1 total=60, L5.2 from_thread=60 + strong_count, L5.3
     count=100, L5.4 count=3/total=600). Confirm E0373 (L5.1 broken — verify it
     leads; if rustc reports E0505 or a Send error first, record the real one) and
     E0277 (L5.2 broken — Rc-not-Send) with `2> rust_error.txt` capture.
   - **tokio labs (L5.5, L5.6):** pin the tokio version and MINIMAL feature set
     (`rt`/`macros`/`time` for L5.5; add `rt-multi-thread` for L5.6's JoinSet —
     confirm the smallest set that compiles); `cargo run` and confirm outputs
     (L5.5 result=42 / a=2,b=4; L5.6 completed=4 / sum=8625). Record the resolved
     tokio version in each Cargo.toml.
   - **read-only exhibits (L5.7, L5.8):** NEVER compiled — verify only that the
     described flaws/data-flow are accurately stated by reading (they reference
     tokio types but ship no Cargo.toml and are never built).
   Fix content to reality and log every deviation.
5. Lint gates: `./tools/lint-labs.sh` clean. **ERE discipline** — escaped bracket
   tags in the L5.1/L5.2 `rust_error.txt` greps already specified. No absolute-
   path literals in any check.sh (the exhibit *content* has `"0.0.0.0:9000"` /
   `"scanme.example.test"` strings, but those live in `files/`, never linted).
6. Acceptance: extend `tests/acceptance.sh` with a P5 section per the established
   pattern — fabricated pass (echo answers/predictions/outputs; stub binaries for
   ./sample ×3 [L5.1, L5.3, L5.4] — each in its own per-lab workspace so the
   shared `sample` basename never collides — plus ./sample [L5.2]; echo
   rust_error.txt for L5.1/L5.2, async_out.txt for L5.5, loop_out.txt for L5.6) +
   one negative case per lab. **L5.7 and L5.8 have no binary** — their negative
   cases corrupt an answer key. Drive `lab start rust L5.1` with 5 piped recall
   answers, assert non-gating. Update every stale catalog-count denominator at
   every call site.
7. Manual full-phase pass with the real toolchain — INCLUDING the two `cargo run`
   tokio labs (the only labs whose real value needs a live network on first
   build) — before tagging `rust-p5`.
8. Update `planned_execution.md` (build session's job, not this plan's).

## 6. Decisions & deviations log (for the reviewer)

- **tokio is the track's first third-party dependency (L5.5, L5.6)** — an explicit
  contract-level deviation flagged in the header and §5.4 per kit-contracts'
  "propose deviations explicitly" rule. It touches the network only in the LEARNER
  shell (like L0.1 rustup and L4.8 cargo audit already do); check.sh never runs
  cargo and never networks; acceptance is fully fabricatable. Only two labs carry
  the dep; L5.1–L5.4 are std-only; L5.7–L5.8 are never compiled.
- **Determinism rule is load-bearing** (§2) — every graded value in a concurrency
  phase is order-independent (sums/counts/totals over joins and channels), and
  every runnable sample that could print in varying order sorts first (L5.8). No
  check ever asserts an interleaving. This is the single biggest correctness risk
  in a concurrency phase and is designed out.
- **L5.7 and L5.8 are read-only tokio-shaped exhibits, never compiled** — L5.7
  audits the ABSENCE of controls (running an actual DoS is pointless and
  inappropriate) and L5.8 traces a scanner's data flow (running a real port
  scanner is nondeterministic and out of scope). Grading is answers.txt reading;
  no tokio dependency, no binary; negative acceptance cases corrupt a key. (L2.8/
  L3.9/L4.2 established the exhibit precedent.)
- **L5.8's scanner is a READING exhibit, never executed** — the map's chosen gate
  is "trace a concurrent port scanner's data flow," and the value is reading the
  standard bounded-concurrency architecture (Semaphore + timeout + channel + spawn
  loop) that every tokio tool shares. The target host is a placeholder
  (`scanme.example.test`, RFC 2606 `.test`), and the file is never compiled or
  run — no scanning happens anywhere in the lab. This is defensive architecture
  literacy, and it sets up the Phase-6 RustScan tour.
- **Data races as compile errors (CWE-362)** — L5.1/L5.2's broken files fail to
  BUILD, teaching that Rust eliminates the race class before runtime; the codes
  (E0373, E0277) are captured as evidence. L5.1's E0373 is the one lower-
  confidence code (the exact leading diagnostic for a borrow-across-spawn can vary)
  and is tagged for build-time confirmation.
- **CWE ids:** CWE-362 (L5.1/L5.2, data race → compile error), CWE-400 (L5.7,
  async resource exhaustion; L5.8 q9 references the Semaphore as its defense).
  Graded exactly in answers.txt per the p4 CWE convention.
- **Arithmetic hand-verified:** L5.1 (0+1+2+3)×10 = 60; L5.2 10+20+30 = 60; L5.3
  4×25 = 100; L5.4 100+200+300 = 600; L5.5 21×2 = 42; L5.6 22+80+443+8080 = 8625.
- **Plan-time verification coverage (honest report):** author self-review only; no
  adversarial fleet at plan time. §5.4's toolchain sweep is authoritative for
  every `[VERIFY-AT-BUILD]` tag — this phase's notable ones are the tokio version/
  feature sets (L5.5/L5.6), L5.1's exact compile-error code, and every quoted
  rustc message. The determinism of every graded value was the primary design
  constraint and is re-checked at build.
