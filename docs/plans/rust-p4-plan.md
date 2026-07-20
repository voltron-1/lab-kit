# RUST TRACK — Phase 4 Build Plan (v1): Security-Critical Rust

Binding content spec: `docs/curriculum/rust-literacy-lab-curriculum-v1.md` (Phase 4
section). Binding mechanical spec: `docs/kit-contracts.md`. Format precedent:
`docs/plans/rust-p01-plan.md`; conventions continued from
`docs/plans/rust-p2-plan.md` §3 and `docs/plans/rust-p3-plan.md` §3. Reference
implementation of every file format: `tracks/demo/phases/p0/L0.0-meet-the-kit/`.
This plan is the single source of design judgment for the build session — build it
mechanically; where reality contradicts a claim marked `[VERIFY-AT-BUILD]`, fix the
content to match reality and note the deviation in the build report.

Planning-context note: at plan time NOTHING in the rust track is built. Phases 0–3
exist only as plan documents. L4.1's recall questions are therefore sourced from
the **curriculum map's lab lists** for Phases 0–3 (titles + descriptions), not from
disk content, and every one is `[VERIFY-AT-BUILD]` — the p4 build session refines
wording against the real built earlier phases (build order: p0/p1/p2/p3 first).

**Framing note (read before building any lab):** this is a defensive secure-code-
review phase. Every artifact exists so a reader can *identify* a vulnerability
class and its fix — the course's stated goal ("audit unsafe blocks; review
untrusted-input handling"). Two build rules follow and are non-negotiable:
- **No weaponized payloads.** Flawed samples show the vulnerable *pattern* (user
  input concatenated into a shell string, a path joined without containment); they
  never ship a copy-pasteable exploit string, never pop a shell, never read a real
  sensitive file. Detonation demos are inert (print a resolved path; print a
  truncated number) — they demonstrate the bug's *shape*, not its impact.
- **No runnable undefined behavior.** Where a flaw is memory-unsafe (`unsafe`
  misuse, OOB, use-after-free), the artifact is a **read-only exhibit** graded by
  reading (answers.txt), never compiled or executed — capturing UB is unreliable
  and shipping runnable UB is irresponsible. Safe/logic flaws (truncation, panics,
  path traversal) may run, because their demo is deterministic and harmless.

## 1. Lab list (from the map, exactly)

| id | title (meta.json `title`) | type | gate | est_minutes | dir slug |
|---|---|---|---|---|---|
| L4.1 | What `unsafe` actually unlocks — the five superpowers | DECODE | false | 15 | `L4.1-unsafe-superpowers` |
| L4.2 | Auditing an unsafe block — the checklist | AUDIT | false | 20 | `L4.2-audit-unsafe-block` |
| L4.3 | FFI — where the guarantees end | DECODE | false | 15 | `L4.3-ffi-boundary` |
| L4.4 | `as` casts vs `TryFrom` — truncation bugs | AUDIT | false | 15 | `L4.4-as-truncation` |
| L4.5 | Panics as DoS — untrusted input meets `unwrap` | AUDIT | false | 15 | `L4.5-panics-as-dos` |
| L4.6 | Parsing untrusted bytes — reading a nom-style parser | DECODE | false | 20 | `L4.6-nom-style-parser` |
| L4.7 | What Rust does NOT stop — path traversal, injection, logic bugs | AUDIT | false | 20 | `L4.7-rust-does-not-stop` |
| L4.8 | Supply chain — cargo audit, cargo deny, RUSTSEC advisories | GUIDED | false | 15 | `L4.8-supply-chain` |
| L4.9 | Clippy as a code reviewer | GUIDED | false | 15 | `L4.9-clippy-reviewer` |
| L4.10 | Phase gate: full audit of a 150-line intentionally flawed tool | AUDIT | **true** | 25 | `L4.10-phase-gate-full-audit` |

Gate placement: the map marks L4.10 explicitly; no other gate.
recall.json placement: **L4.1 only** (5 questions, earlier phases, interleaved).

Phase security hook (map): the whole phase. **L4.7 matters most** — Rust kills
memory corruption, not bad logic; a memory-safe path-traversal bug is still a
breach. The through-line every lab restates: *memory safety ≠ security.*

## 2. Binding harness constraints (unchanged — see rust-p2-plan.md §2)

Identical to Phases 2–3: check.sh never runs cargo/rustc/clippy (env -i fence
hides `~/.cargo/bin`); all grading artifact-based and CI-fabricatable without a
toolchain; lint bans as listed (absolute paths, `eval`, `bash -c`, `curl`, `sudo`,
etc.); quiz.json exactly 3 / hints.json exactly 3 levels / recap.md exactly 3
lines / lab.md exact headings; answers base64, text answers lowercase-normalized
with `accept_b64` variants; quiz stdin one line per question; recall non-gating at
`lab start` on the opener only.

**Consequence for the GUIDED tool labs (L4.8, L4.9):** the learner runs
`cargo audit` / `cargo deny` / `cargo clippy` in their OWN shell (which may network
and see the toolchain) and redirects output to a file; check.sh grades the
redirected artifact plus answers.txt — exactly the pattern L0.1 used for
`toolchain.txt`. The grep targets structural markers that BOTH a real tool run and
a fabricated `echo` satisfy (so acceptance/CI stay toolchain- and network-free).
check.sh never invokes the tools itself.

## 3. Track conventions (carried + Phase-4 additions)

Carried unchanged from the p01/p2/p3 plans: `key=value` answer files
(`predictions.txt` for the one PREDICT-shaped step, `answers.txt` otherwise;
options printed in lab.md; anchored-ERE or `assert_file_contains_fixed` grading);
honor framing in AUDIT/DECODE BRIEFs ("the check can't tell whether you reasoned
first — you're only cheating your own reps"); broken/exhibit samples as separate
files, never inline edits; quiz-vs-answers non-duplication; hints ladder L1
artifact → L2 exact line → L3 near-answer procedure; workspace hygiene; **ERE
discipline — ALL ERE metacharacters escaped in assert patterns: brackets, `+`,
parens, `?`, `*`, `.` where literal-critical** (the class of bug the p2/p3 reviews
caught — see rust-p2-plan.md §5.5); descs/hints keep apostrophes and lifetime
ticks out.

New for Phase 4:
- **Build tool: bare `rustc` single files for every COMPILED lab** (L4.3 links
  libc, which bare rustc does by default — see the lab). Samples edition-
  independent `[VERIFY-AT-BUILD: compile every runnable file with plain rustc]`.
- **CWE literacy convention.** Where a lab names a weakness, the graded answer in
  answers.txt is the canonical `CWE-###` token, graded EXACTLY via
  `assert_file_contains_fixed` (the BRIEF's vocabulary line prints the exact
  format so the learner transcribes it, not guesses — there is no alternate
  accepted form for an answers.txt CWE token). Where a lab ALSO asks for the
  class in *words*, that lives in a quiz.json question, which may carry
  `accept_b64` phrasing variants (accept_b64 is a quiz/recall-only mechanism per
  kit-contracts — it never applies to answers.txt). IDs used this phase: CWE-125
  (out-of-bounds read), CWE-190 (integer overflow), CWE-197 (numeric truncation),
  CWE-248 (uncaught exception/panic), CWE-22 (path traversal), CWE-78 (OS command
  injection), CWE-416 (use-after-free, recalled from L2.8).
- **Read-only exhibit (memory-unsafe artifacts)** — extends the L2.8/L3.9/L3.10
  exhibit pattern: L4.2's flawed `unsafe` block is a `files/` exhibit graded by
  answers.txt; it is never compiled or run (framing rule 2). Banner comment on the
  file states this. Its acceptance negative case corrupts an answer key, not a
  binary (no binary exists).
- **Inert detonation** — where a *safe* flaw is demonstrated live (L4.4
  truncation, L4.5 panic, L4.7 traversal-path resolution), the demo prints a
  harmless observable (a wrong number, a captured panic line, a resolved path
  string) — never performs the malicious effect. Panic captures reuse p3's
  convention: `./bin <arg> 2> panicN.txt` (non-zero exit expected), check greps
  `panicked`.

## 4. Lab entries

---

### L4.1 — What `unsafe` actually unlocks — the five superpowers
**DECODE · gate:false · est 15 · files/: sample.rs, broken.rs · recall.json: YES (phase opener)**
**objective:** "Name the five things `unsafe` permits (and the many it does NOT), read a minimal sound unsafe block, and read E0133 when an unsafe call escapes its block."

**recall.json — 5 questions, sourced from the curriculum map's Phase 0–3 lab
lists (nothing built at plan time). ALL FIVE `[VERIFY-AT-BUILD]`: refine wording
against the real built labs before shipping.**
1. choice (source: "rust L3.1 — Result and ?") — "The `?` operator on an `Err`…"
   a) panics b) returns the Err to the caller immediately c) logs and continues →
   **b**
2. choice (source: "rust L3.2 — unwrap red flags") — "`unwrap()` on
   attacker-controlled input is which class of risk?" a) memory corruption
   b) denial of service — one bad input crashes the process c) privilege
   escalation → **b**
3. choice (source: "rust L2.8 — the C++ crime scene") — "Use-after-free (CWE-416)
   in safe Rust is…" a) a runtime panic b) a compile error c) undefined behavior
   → **b**
4. choice (source: "rust L3.8 — From/Into/TryFrom") — "`70000_u32 as u16`
   evaluates to…" a) 65535 (clamped) b) 4464 (silent truncation) c) a compile
   error → **b**
5. choice (source: "rust L1.2 — integer overflow") — "u8 overflow in a *debug*
   build…" a) wraps silently b) panics c) is undefined behavior → **b**

**files/sample.rs (a minimal SOUND unsafe block — it upholds its invariant):**
```rust
fn main() {
    // Superpower #1: dereference a raw pointer.
    let value = 42u32;
    let ptr: *const u32 = &value;
    // SAFETY: ptr was just made from a live &value on this stack frame; it is
    // non-null, aligned, and initialized, and value outlives this block.
    let read = unsafe { *ptr };
    println!("read = {read}");

    // Superpower #2: call an unsafe function. get_unchecked skips bounds checks.
    let bytes = [10u8, 20, 30, 40];
    let index = 2;
    // SAFETY: index (2) is < bytes.len() (4), checked on the line above.
    let byte = unsafe { *bytes.get_unchecked(index) };
    println!("byte = {byte}");

    println!("unsafe did NOT disable the borrow checker or the type system");
}
```
Expected output `[VERIFY-AT-BUILD]`: `read = 42` / `byte = 30` / `unsafe did NOT
disable the borrow checker or the type system`.
Teaching beats: `unsafe` unlocks exactly **five** superpowers and NOTHING else —
(1) dereference a raw pointer, (2) call an `unsafe` fn/method, (3) access or
modify a mutable `static`, (4) implement an `unsafe` trait, (5) access a `union`
field; it does NOT turn off the borrow checker, the type checker, or lifetimes —
the single most common misconception; the `// SAFETY:` comment is the audit
contract — it states the invariant the human is now responsible for, because the
compiler has stopped checking; both blocks here are sound precisely because the
invariant in the comment actually holds.

**files/broken.rs (an unsafe call with the `unsafe` block removed):**
```rust
fn main() {
    let bytes = [10u8, 20, 30, 40];
    let byte = *bytes.get_unchecked(2);
    println!("byte = {byte}");
}
```
Must produce **E0133** — "call to unsafe function `...get_unchecked...` is unsafe
and requires unsafe function or block" `[VERIFY-AT-BUILD: code + message line]`.

**GUIDED STEPS outline:** read sample.rs → compile/run → answers.txt (options in
lab.md): q1 (value) how many superpowers does `unsafe` unlock (a number) →
`q1=5`; q2 (choice) does `unsafe` disable the borrow checker? a) yes b) no — it
only unlocks the five superpowers; every other rule still applies c) only in
release → `q2=b`; q3 (value) the byte printed by the get_unchecked block →
`q3=30`; q4 (choice) what is the `// SAFETY:` comment for? a) decoration b) it
records the invariant the human now guarantees, since the compiler no longer
checks it — the anchor of every unsafe audit c) it silences a warning →
`q4=b`; q5 (value) broken.rs error code → `q5=E0133` → `rustc broken.rs`, record
→ check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=5$'`, `'^q2=b$'`,
`'^q3=30$'`, `'^q4=b$'`, `'^q5=E0133$'`;
`assert_output_contains 'sample runs' 'read = 42' 'step 2 — rustc sample.rs -o
sample' -- ./sample`; `ck_summary`.
(CI fabrication: echo the five answers; `#!/bin/sh` stub printing the three
output lines as `./sample`.)

**QUIZ:**
1. choice — "`unsafe` means…" a) this code is dangerous and untested b) I,
   the human, take responsibility for invariants the compiler can no longer
   verify c) the borrow checker is off here → **b**
2. choice — "Which is NOT one of the five unsafe superpowers?" a) dereference a
   raw pointer b) ignore a lifetime error c) access a mutable static → **b**
3. text — "The comment convention that documents an unsafe block's invariant." →
   **safety** (accept: `// safety`, `safety comment`)

**RECAP:**
```
unsafe unlocks exactly five powers — raw deref, unsafe call, mut static, unsafe trait, union
it does NOT disable the borrow checker, types, or lifetimes — the top misconception
every unsafe block owes a // SAFETY comment: the invariant the human now guarantees
```

**HINTS:** L1: five answer keys — options in step 3. L2: q1 is the count named in
the BRIEF; q3 is `bytes[2]`; q4/q2 restate what unsafe does and does not do; q5
comes off `rustc broken.rs`. L3: run and transcribe — `rustc sample.rs -o sample;
./sample; rustc broken.rs`.

---

### L4.2 — Auditing an unsafe block — the checklist
**AUDIT · gate:false · est 20 · files/: exhibit.rs (READ-ONLY — never compiled or run)**
**objective:** "Audit a flawed unsafe block against the four-point checklist, find the violated invariant, and name the memory-safety class it would cause — by reading alone."

**files/exhibit.rs (READ-ONLY EXHIBIT — flawed unsafe; banner says do not compile
or run; framing rule 2):**
```rust
// exhibit.rs — READ-ONLY EXHIBIT. Do NOT compile or run this; you are here to
// audit it. The // SAFETY comment below is a LIE. Find where it breaks.
use std::slice;

/// Reinterprets the first `len` bytes at `data` as a &[u8].
/// SAFETY: caller guarantees data points to len valid initialized bytes.
unsafe fn view(data: *const u8, len: usize) -> &'static [u8] {
    slice::from_raw_parts(data, len)
}

fn parse_record(buf: &[u8]) -> &[u8] {
    // read a big-endian length prefix, then hand back that many bytes
    let declared = u32::from_be_bytes([buf[0], buf[1], buf[2], buf[3]]) as usize;
    // BUG: `declared` comes from the buffer itself and is never checked
    // against buf.len(); from_raw_parts will read `declared` bytes starting
    // at buf[4] regardless of how long buf actually is.
    unsafe { view(buf[4..].as_ptr(), declared) }
}
```
Audit findings (the answer key), against the four-point unsafe checklist:
1. **Unchecked length** — `declared` is attacker-controlled (read from the
   buffer) and never bounds-checked against `buf.len() - 4`; `from_raw_parts`
   trusts it → reads past the buffer. **Class: out-of-bounds read (CWE-125).**
2. **Lifetime laundering** — `view` returns `&'static [u8]` from a raw pointer
   with no basis; the slice actually borrows `buf`, but the signature claims it
   lives forever → a dangling reference the moment `buf` drops (**use-after-free
   shape, CWE-416**).
3. **The `// SAFETY` comment is unfulfillable** — it pushes the invariant ("len
   valid bytes") onto the caller, but `parse_record` (the caller) does not
   establish it — the contract is stated and then violated.
The fix direction (lab.md, not graded as code): validate `buf.len() >= 4 &&
declared <= buf.len() - 4` (check the length prefix is present BEFORE the
subtraction, which would otherwise underflow on a short buffer), return
`Option`/`Result`, and use safe slicing `&buf[4..4 + declared]` — no `unsafe`
needed at all; this whole block should not exist.

**GUIDED STEPS outline:** read exhibit.rs as a reviewer (nothing to compile —
lab.md says so) → answers.txt (options in lab.md):
- q1 (choice) the primary flaw: a) the pointer might be null b) `declared` is
  attacker-controlled and never bounds-checked before from_raw_parts trusts it
  c) u32::from_be_bytes is slow → `q1=b`
- q2 (value) the CWE for reading past the end of the buffer (format `CWE-###`,
  given in the brief vocabulary) → `q2=CWE-125`
- q3 (choice) the `-> &'static [u8]` return type is: a) fine, slices are static
  b) a lie — the data borrows buf and cannot outlive it; 'static invites a
  use-after-free → `q3=b`
- q4 (choice) what is wrong with the `// SAFETY` comment? a) nothing b) it
  states an invariant the caller never actually establishes — a contract written
  and then broken c) it is too short → `q4=b`
- q5 (choice) the correct fix: a) add a null check b) bounds-check declared and
  use safe slicing — the unsafe block is unnecessary c) mark parse_record unsafe
  too → `q5=b`

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q3=b$'`,
`'^q4=b$'`, `'^q5=b$'`;
`assert_file_contains_fixed answers.txt 'q2=CWE-125'`;
`ck_summary`. (Pure-reading lab: answers.txt is the only artifact — no binary,
nothing compiled; decision logged in §6. CI fabrication: echo the five lines.)

**QUIZ:**
1. choice — "The unsafe-audit checklist asks, for each block:" a) is it fast
   b) is every invariant in the SAFETY comment actually upheld by the callers,
   and are pointers/lengths/lifetimes all valid c) is it short → **b**
2. choice — "`slice::from_raw_parts(ptr, len)` with an unchecked `len` from
   input causes…" a) a compile error b) an out-of-bounds read — the function
   trusts len completely c) automatic truncation → **b**
3. text — "A SAFETY comment that claims an invariant the code never establishes
   is worth ___ (how much)?" → **nothing** (accept: `zero`, `worthless`)

**RECAP:**
```
auditing unsafe = check every SAFETY invariant is real: pointers, lengths, lifetimes
a length read from input and trusted by from_raw_parts is an out-of-bounds read
a SAFETY comment is a claim to verify, not to trust — an unfulfilled one is a bug
```

**HINTS:** L1: five answer keys, all read from exhibit.rs — nothing runs. L2: the
inline `// BUG:` comment points at q1; the CWE format is in the BRIEF; q3 asks
what happens to the returned slice when `buf` is dropped. L3: re-read the three
audit points named in the BRIEF — each maps to one answer key; the CWE for an
out-of-bounds read is CWE-125.

---

### L4.3 — FFI — where the guarantees end
**DECODE · gate:false · est 15 · files/: sample.rs, broken.rs**
**objective:** "Read an `extern \"C\"` declaration as a promise YOU make, run a real libc call across the boundary, and read E0133 when the call escapes its unsafe block."

**files/sample.rs (calls libc `abs` — bare rustc links libc by default):**
```rust
// The declaration below is a PROMISE: "somewhere there is a C function named
// abs taking one i32 and returning i32." Rust cannot check it. If the promise
// is wrong, the result is undefined behavior — no borrow checker reaches here.
extern "C" {
    fn abs(input: i32) -> i32;
}

fn main() {
    // SAFETY: abs is a real, pure libc function matching this signature.
    let a = unsafe { abs(-9) };
    println!("abs(-9) = {a}");

    let b = unsafe { abs(1024) };
    println!("abs(1024) = {b}");

    println!("the extern signature is unchecked — correctness is on the human");
}
```
Expected output `[VERIFY-AT-BUILD: confirm libc links and abs resolves under
plain rustc on the target — if not, fall back to a `#[link]`ed build note]`:
`abs(-9) = 9` / `abs(1024) = 1024` / `the extern signature is unchecked —
correctness is on the human`.
Teaching beats: FFI is the seam where every Rust guarantee stops — across
`extern "C"` there is no borrow checker, no lifetime, no null-safety, no type
check beyond what YOU wrote in the declaration; the declaration is an unverified
promise, and a wrong signature (wrong arg count, wrong width, wrong nullability)
is instant UB; calling any extern fn requires `unsafe` because the compiler
cannot vouch for the other side; `#[repr(C)]` (mentioned, not shipped) is how
structs cross the boundary with a C-compatible layout. This is why an audit
treats every FFI boundary as a trust boundary.

**files/broken.rs (extern call without the unsafe block):**
```rust
extern "C" {
    fn abs(input: i32) -> i32;
}

fn main() {
    let a = abs(-9);
    println!("abs(-9) = {a}");
}
```
Must produce **E0133** — "call to unsafe function `abs` is unsafe and requires
unsafe function or block" `[VERIFY-AT-BUILD: code + message]`.

**GUIDED STEPS outline:** read → compile/run sample → answers.txt (options in
lab.md): q1 (choice) what does the `extern "C"` block guarantee about `abs`?
a) that it exists and matches — the compiler verifies it b) nothing — it is an
unchecked promise the human makes; a wrong signature is UB c) that it is safe →
`q1=b`; q2 (value) the printed value of abs(-9) → `q2=9`; q3 (choice) why does
calling abs require `unsafe`? a) it is slow b) the compiler cannot verify the
foreign side upholds Rust's guarantees — the boundary is a trust boundary
c) libc is deprecated → `q3=b`; q4 (choice) across an FFI boundary, the borrow
checker… a) still applies b) does not reach — no lifetimes, no aliasing rules,
no null safety are enforced on the C side c) runs at link time → `q4=b`; q5
(value) broken.rs error code → `q5=E0133` → `rustc broken.rs` → check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=9$'`,
`'^q3=b$'`, `'^q4=b$'`, `'^q5=E0133$'`;
`assert_output_contains 'sample runs libc abs' 'abs\(1024\) = 1024' 'step 2 —
rustc sample.rs -o sample' -- ./sample` (parens escaped); `ck_summary`.

**QUIZ:**
1. choice — "An `extern \"C\"` fn declaration is…" a) verified against the C
   library at compile time b) an unchecked promise — if the signature is wrong,
   the result is undefined behavior c) automatically safe → **b**
2. choice — "Why is every FFI call `unsafe`?" a) FFI is slow b) the compiler
   cannot check that the foreign code respects Rust's invariants — you vouch for
   it c) C is older than Rust → **b**
3. text — "The attribute that gives a struct a C-compatible memory layout for
   FFI." → **repr(c)** (accept: `#[repr(c)]`, `repr c`)

**RECAP:**
```
FFI is the seam where Rust's guarantees stop — no borrow check, no lifetimes, no null safety
an extern signature is an unverified promise; a wrong one is instant undefined behavior
audit every FFI boundary as a trust boundary — the C side can violate every invariant
```

**HINTS:** L1: five answer keys — options in step 3. L2: q2 is |−9|; q1/q3/q4 all
restate the same idea from the BRIEF — the boundary is unchecked; q5 is the same
E0133 as L4.1 (unsafe call without a block). L3: run and transcribe — `rustc
sample.rs -o sample; ./sample; rustc broken.rs`.

---

### L4.4 — `as` casts vs `TryFrom` — truncation bugs
**AUDIT · gate:false · est 15 · files/: sample.rs**
**objective:** "Audit a size computation for silent `as` truncation, watch a bounds check get defeated by a narrowing cast, and give the TryFrom fix (CWE-197)."

**files/sample.rs (a length-check defeated by a narrowing cast — runs, inert):**
```rust
// A gatekeeper that rejects oversized records... or does it?
fn accept(declared_len: u32) -> bool {
    const MAX: u16 = 4096;
    // BUG: declared_len is truncated to u16 BEFORE the comparison. A value
    // whose low 16 bits are small sails through, no matter how large it is.
    let checked = declared_len as u16;
    checked <= MAX
}

fn main() {
    let honest: u32 = 512;
    println!("accept(512) = {}", accept(honest));

    // 65536 + 100 = 0x10064; as u16 -> 0x0064 = 100, which is <= 4096.
    let hostile: u32 = 65_636;
    println!("accept(65636) = {}", accept(hostile));
    println!("truncated view of 65636 = {}", hostile as u16);

    // The safe gate: TryFrom refuses to narrow a value that does not fit.
    let safe_gate = u16::try_from(hostile).map(|v| v <= 4096).unwrap_or(false);
    println!("safe gate accepts 65636 = {safe_gate}");
}
```
Expected output `[VERIFY-AT-BUILD]`: `accept(512) = true` / `accept(65636) =
true` / `truncated view of 65636 = 100` / `safe gate accepts 65636 = false`.
Arithmetic check: 65636 = 65536 + 100; `65636u32 as u16` = 65636 − 65536 =
**100**; 100 ≤ 4096 → the flawed gate returns `true` for a value 16× over the
limit; `u16::try_from(65636)` is `Err` → the safe gate returns `false`.
Teaching beats: `as` between integer types NEVER fails — it truncates
(narrowing) or sign-/zero-extends (widening) silently; a narrowing `as` placed
*before* a bounds check silently defeats the check — the exact real-world
truncation bug class (CWE-197), and a cousin of CWE-190 from L1.2; the reviewer
rule: any `as` on a value derived from input, especially near a size/length/index
or a comparison, is a flag; `TryFrom` turns "does not fit" into a handled
`Err` instead of a wrong answer.

**GUIDED STEPS outline:** read → compile/run → answers.txt (options in lab.md):
q1 (choice) why does accept(65636) return true? a) 65636 really is ≤ 4096 b) the
`as u16` truncates 65636 to 100 before the check — the gate compares the wrong
number c) a compiler bug → `q1=b`; q2 (value) the truncated value of 65636 as
u16 → `q2=100`; q3 (value) the CWE id for numeric truncation (format `CWE-###`,
given in brief) → `q3=CWE-197`; q4 (choice) the fix: a) use a bigger constant
b) validate with `u16::try_from` (or compare in u32) so an out-of-range value is
rejected, never silently narrowed c) add a comment → `q4=b`; q5 (choice) the
review heuristic: a) `as` is always fine b) any `as` on input-derived data near a
length/index/comparison is a flag — it can silently change the value c) only
`unsafe` casts matter → `q5=b` → check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=100$'`,
`'^q4=b$'`, `'^q5=b$'`;
`assert_file_contains_fixed answers.txt 'q3=CWE-197'`;
`assert_output_contains 'sample shows the safe gate rejecting' 'safe gate
accepts 65636 = false' 'step 2 — rustc sample.rs -o sample' -- ./sample`;
`ck_summary`.

**QUIZ:**
1. choice — "An integer `as` cast that narrows (u32 as u16)…" a) returns an
   error on overflow b) silently keeps the low bits — truncation, no signal
   c) clamps to the max → **b**
2. choice — "A narrowing `as` placed before a size check…" a) is harmless
   b) can defeat the check — the comparison runs on the truncated value, not the
   real one c) is a compile error → **b**
3. text — "The trait to use instead of `as` when a value might not fit." →
   **tryfrom** (accept: `try_from`, `tryinto`, `try_into`)

**RECAP:**
```
as never fails — it truncates or extends silently; there is no error path
a narrowing as before a bounds check defeats the check: 65636 as u16 is 100 <= 4096
CWE-197: any as on input-derived sizes/indices is a flag; TryFrom makes overflow a decision
```

**HINTS:** L1: five answer keys — options in step 3. L2: compute `65636 − 65536`
for q2; that truncated value is what the flawed gate actually compares; the CWE
format is in the BRIEF. L3: run and transcribe — `rustc sample.rs -o sample;
./sample` — and note the flawed gate says true while the TryFrom gate says false
for the same input.

---

### L4.5 — Panics as DoS — untrusted input meets `unwrap`
**AUDIT · gate:false · est 15 · files/: parse.rs**
**objective:** "Inventory the panic paths in a working parser, rank them by input reachability, and detonate one for real — the availability audit L3.2 started."

**files/parse.rs (compiles and runs on good input; four distinct panic KINDS):**
```rust
// parse.rs — turns "field=count" args into a running total. It works on good
// input. Count the distinct ways a crafted argument can crash it.
fn main() {
    let mut total: u32 = 0;
    for arg in std::env::args().skip(1) {
        let (field, count) = arg.split_once('=').unwrap();      // A: no '='
        let n: u32 = count.parse().unwrap();                    // B: not a number
        let short = &field[..3];                                // C: <3 bytes / non-char-boundary
        total += n;                                             // D: overflow (debug panic)
        println!("{short}: {n}");
    }
    println!("total = {total}");
}
```
Happy path `[VERIFY-AT-BUILD]`: `./parse "scan=5" "auth=3"` → `sca: 5` / `aut: 3`
/ `total = 8`. Panic inventory (answer key): **four distinct kinds** —
A `unwrap` on `split_once` (missing `=`), B `unwrap` on `parse` (non-numeric),
C slice `&field[..3]` (field shorter than 3 bytes, or a cut through a multi-byte
UTF-8 char), D `total += n` overflow (u32 sum exceeding `u32::MAX` — panics in
debug, CWE-190). All four are reachable by argument *values*; none needs operator
error. Detonation (graded, inert): `./parse "nodelim" 2> panic1.txt` triggers A;
expected stderr contains `panicked` `[VERIFY-AT-BUILD: exact message]`; non-zero
exit expected.
Teaching beats: memory safety does not buy availability — every panic is a
process-killing DoS on an input path (CWE-248); panics come in more flavors than
`unwrap` (indexing/slicing, arithmetic overflow, `/0`, `.expect`); the audit is
reachability triage — which sites can attacker-shaped *data* reach?; the fixes
are per-site policies (`split_once` → handle `None`; `parse` → `?`/`unwrap_or`;
slice → `.get(..3)`; `+=` → `checked_add`).

**GUIDED STEPS outline:** read parse.rs → count distinct panic kinds, confirm
reachability → `rustc parse.rs -o parse` → happy-path run → detonate with a
delimiter-less arg, capture panic1.txt → answers.txt (options in lab.md):
- q1 (value) number of distinct panic kinds → `q1=4`
- q2 (choice) which line panics on the argument `nodelim`? a) the parse b) the
  split_once unwrap — there is no `=` c) the slice → `q2=b`
- q3 (choice) the security class of a panic on an input path: a) memory
  corruption b) denial of service — an uncaught panic kills the process (CWE-248)
  c) info leak → `q3=b`
- q4 (choice) which site is an integer-overflow panic (CWE-190)? a) the slice
  b) `total += n` in a debug build c) the parse → `q4=b`
- q5 (choice) the fix for the slice site: a) unwrap it b) `field.get(..3)` and
  handle `None` — make absence a value, not a crash c) cast to u16 → `q5=b`

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=4$'`, `'^q2=b$'`,
`'^q3=b$'`, `'^q4=b$'`, `'^q5=b$'`;
`assert_file_contains panic1.txt 'panicked'` (hint: step 4 — capture stderr with
`2> panic1.txt`);
`assert_output_contains 'parse happy path total' 'total = 8' 'step 3 — rustc
parse.rs -o parse, then run with scan=5 auth=3' -- ./parse scan=5 auth=3`;
`ck_summary`.
(CI fabrication: echo answers; echo a 'panicked at' line into panic1.txt;
`#!/bin/sh` stub `./parse` printing the happy-path lines when given two args.)

**QUIZ:**
1. choice — "Beyond `unwrap`/`expect`, which of these also panics on bad data?"
   a) only unwrap panics b) indexing/slicing out of range, integer overflow in
   debug, and divide-by-zero all panic too c) nothing else → **b**
2. choice — "A panic in a network service request handler is…" a) memory
   corruption b) an availability failure — that request (or worker) dies; safe
   from corruption, not from DoS c) automatically retried → **b**
3. text — "The panic-free slice accessor that returns Option instead of
   crashing." → **get** (accept: `.get`, `get()`)

**RECAP:**
```
memory safety is not availability — every panic on an input path is a DoS (CWE-248)
panics are more than unwrap: indexing, slicing, overflow (debug), and / 0 all crash
audit by reachability; fix per site — handle None, use ?, .get(..), checked_add
```

**HINTS:** L1: five answer keys, panic1.txt, and a working ./parse — the grader
names each miss. L2: count the FOUR distinct crash kinds (two unwraps, one slice,
one overflow) for q1; the arg `nodelim` has no `=`, so split_once returns None
and its unwrap fires; the `+=` is the overflow site. L3: exact commands — `rustc
parse.rs -o parse; ./parse "scan=5" "auth=3"; ./parse "nodelim" 2> panic1.txt`.

---

### L4.6 — Parsing untrusted bytes — reading a nom-style parser
**DECODE · gate:false · est 20 · files/: sample.rs**
**objective:** "Read a length-prefixed byte parser the way nom is written — take/verify/bounds-check — and see how safe Rust turns a malicious length field into a handled error, not corruption."

**files/sample.rs (a hand-rolled nom-STYLE parser — no external crate, runs):**
```rust
// A nom-style parser reads a byte stream by consuming pieces and returning the
// value plus the REMAINING input. Real nom returns IResult; this hand-rolled
// version uses Option to keep the shape without a dependency. The security
// lesson is identical: every read is bounds-checked before it happens.

/// Take exactly `n` bytes; return (taken, rest) or None if not enough input.
fn take(input: &[u8], n: usize) -> Option<(&[u8], &[u8])> {
    if input.len() < n {
        return None; // the whole game: refuse before reading past the end
    }
    Some((&input[..n], &input[n..]))
}

/// Parse: [1-byte tag][1-byte length N][N bytes payload].
fn parse_record(input: &[u8]) -> Option<(u8, &[u8], &[u8])> {
    let (tag, rest) = take(input, 1)?;
    let (len_byte, rest) = take(rest, 1)?;
    let declared = len_byte[0] as usize;
    let (payload, rest) = take(rest, declared)?; // declared is CHECKED by take
    Some((tag[0], payload, rest))
}

fn main() {
    // tag=0x01, len=3, payload="abc", then a trailing 0xFF
    let good = [0x01u8, 0x03, b'a', b'b', b'c', 0xFF];
    match parse_record(&good) {
        Some((tag, payload, rest)) => {
            println!("tag = {tag}");
            println!("payload len = {}", payload.len());
            println!("trailing bytes = {}", rest.len());
        }
        None => println!("truncated"),
    }

    // A hostile record: claims length 200 but only 2 payload bytes follow.
    let hostile = [0x01u8, 0xC8, b'a', b'b'];
    match parse_record(&hostile) {
        Some(_) => println!("parsed (unexpected)"),
        None => println!("rejected: declared length exceeds input"),
    }
}
```
Expected output `[VERIFY-AT-BUILD]`: `tag = 1` / `payload len = 3` / `trailing
bytes = 1` / `rejected: declared length exceeds input`.
(0xC8 = 200; only 2 bytes follow, so `take(rest, 200)` returns None → the whole
parse is None → the `?` propagates it.)
Teaching beats: a parser-combinator reads input as (value, remaining) pairs
threaded through `?` — read nom's `IResult<&[u8], T>` exactly this way; the
single security-critical habit is that **every read is bounds-checked before it
happens** (`take` refuses when `input.len() < n`) — so a malicious length field
becomes a clean `None`/`Err`, never an out-of-bounds read; contrast directly with
L4.2's exhibit, which trusted the same kind of length field via `unsafe` and read
past the end; `?` on `Option`/`IResult` is the propagation that makes "not enough
input" flow to the top as a handled outcome.

**GUIDED STEPS outline:** read (honor framing) → compile/run → answers.txt
(options in lab.md): q1 (choice) what does `take` return, and why the length
check? a) it panics on short input b) `(taken, rest)` or None — it refuses BEFORE
reading past the end, so an oversized length can't cause an OOB read → `q1=b`;
q2 (value) the payload len printed for the good record → `q2=3`; q3 (value)
trailing byte count for the good record → `q3=1`; q4 (choice) why is the hostile
record rejected? a) the tag is invalid b) it declares length 200 but only 2 bytes
follow, so `take(rest, 200)` returns None and `?` propagates it → `q4=b`; q5
(choice) how does this differ from L4.2's unsafe exhibit? a) it doesn't
b) this bounds-checks the declared length before using it, turning a hostile
length into a handled error instead of an out-of-bounds read → `q5=b` → check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=3$'`,
`'^q3=1$'`, `'^q4=b$'`, `'^q5=b$'`;
`assert_output_contains 'parser rejects the hostile length' 'rejected: declared
length exceeds input' 'step 2 — rustc sample.rs -o sample' -- ./sample`;
`ck_summary`.

**QUIZ:**
1. choice — "A parser combinator like `take` returns…" a) just the value
   b) the parsed value plus the remaining unconsumed input, threaded through the
   next step c) the whole buffer copied → **b**
2. choice — "The security-critical habit in byte parsing is…" a) parsing fast
   b) bounds-checking every read BEFORE it happens, so a malicious length field
   becomes a handled error, not an out-of-bounds read c) using unsafe for speed
   → **b**
3. text — "The operator that propagates a None/Err out of the parser to its
   caller." → **?** (accept: `question mark`, `the ? operator`)

**RECAP:**
```
nom-style parsing threads (value, remaining) through ? — read IResult exactly so
the one rule that matters: bounds-check every read before it happens
a checked length turns a hostile record into a clean None/Err — never an OOB read
```

**HINTS:** L1: five answer keys — options in step 3. L2: q2 is the payload length
of the good record (3 bytes: a,b,c); q3 is what's left after the record (the
trailing 0xFF — one byte); the hostile record's 0xC8 is 200, far more than the
bytes present. L3: run and transcribe — `rustc sample.rs -o sample; ./sample`.

---

### L4.7 — What Rust does NOT stop — path traversal, injection, logic bugs
**AUDIT · gate:false · est 20 · files/: fetch.rs**
**objective:** "Audit memory-safe Rust that is still exploitable — spot path traversal, the command-injection pattern, and a logic bug the borrow checker will never catch. The phase's central lesson."

**files/fetch.rs (100% safe Rust — compiles clean, no unsafe, no panic on the
demo path; the flaws are logical, and the traversal demo is INERT — it prints a
resolved path, it does not read the file):**
```rust
use std::path::{Path, PathBuf};

// FLAW 1 (CWE-22, path traversal): joins user input onto a base directory with
// no containment check. A name like "../../etc/shadow" escapes `base` entirely.
fn resolve(base: &str, name: &str) -> PathBuf {
    Path::new(base).join(name)
}

// FLAW 2 (CWE-78, command injection PATTERN): builds a shell command string
// from user input and would hand it to `sh -c`. Shown as the vulnerable shape
// to RECOGNIZE — this lab does not execute it.
fn build_lookup_command(host: &str) -> String {
    format!("host {host}")   // interpolating untrusted `host` into a shell line
}

// FLAW 3 (logic bug): an access check that is inverted. Compiles, runs, memory-
// safe — and grants access to exactly the wrong callers.
fn may_read(is_admin: bool, is_locked: bool) -> bool {
    is_admin || is_locked   // BUG: a LOCKED account should be denied, not allowed
}

fn main() {
    // INERT demo of FLAW 1: show that the join escaped the base dir. No read.
    let escaped = resolve("/srv/reports", "../../etc/shadow");
    println!("resolved = {}", escaped.display());

    // FLAW 2: the string that WOULD be passed to a shell (never executed here).
    println!("would run: {}", build_lookup_command("scanme.example"));

    // FLAW 3: a locked, non-admin account is wrongly granted read.
    println!("locked non-admin may_read = {}", may_read(false, true));
}
```
Expected output `[VERIFY-AT-BUILD]`: `resolved = /srv/reports/../../etc/shadow` /
`would run: host scanme.example` / `locked non-admin may_read = true`.
Teaching beats (the phase's thesis): **memory safety ≠ security.** All three
flaws compile in perfectly safe Rust and the borrow checker is silent on every
one. FLAW 1 (CWE-22): `Path::join` does no containment — `join`ing attacker input
escapes the base; the fix is canonicalize + verify the result still starts with
the base (or reject `..`/absolute components). FLAW 2 (CWE-78): interpolating
untrusted data into a shell string is injection; the fix is never build a shell
line — pass an argument vector (`Command::new("host").arg(host)`), no `sh -c`.
FLAW 3: an inverted boolean is a pure logic bug — no tool in this course's stack
catches it; only reading the intent does. The reviewer's takeaway: after you
confirm memory safety, the security review has just *started*.

**GUIDED STEPS outline:** read fetch.rs → compile/run (the demo is inert) →
answers.txt (options + CWE vocabulary printed in lab.md):
- q1 (value) the CWE for FLAW 1, path traversal (format `CWE-###`) → `q1=CWE-22`
- q2 (choice) why is `resolve` vulnerable? a) it can panic b) `Path::join` does
  no containment check, so `../..` in `name` escapes `base` entirely → `q2=b`
- q3 (value) the CWE for FLAW 2, OS command injection → `q3=CWE-78`
- q4 (choice) the fix for FLAW 2: a) escape quotes in the string b) never build a
  shell line — pass an argument vector to the program directly, no `sh -c`
  c) validate the length → `q4=b`
- q5 (choice) which flaw will NO tool in this course (clippy, cargo audit, the
  borrow checker) catch for you? a) FLAW 1 b) FLAW 3, the inverted access check —
  a pure logic bug only human review finds c) FLAW 2 → `q5=b`
- q6 (choice) the phase's thesis: a) Rust code is secure by default b) Rust
  eliminates memory-corruption classes, not logic, injection, or traversal —
  memory safety is not security c) unsafe is the only risk → `q6=b`

**CHECK LOGIC:** `assert_file_contains answers.txt '^q2=b$'`, `'^q4=b$'`,
`'^q5=b$'`, `'^q6=b$'`;
`assert_file_contains_fixed answers.txt 'q1=CWE-22'`;
`assert_file_contains_fixed answers.txt 'q3=CWE-78'`;
`assert_output_contains 'inert traversal demo escaped the base' 'etc/shadow'
'step 2 — rustc fetch.rs -o fetch' -- ./fetch`
(grep the bare `etc/shadow` fragment — no metacharacters, lint-safe);
`ck_summary`.
(CI fabrication: echo the six answers; `#!/bin/sh` stub `./fetch` printing the
three demo lines.)

**QUIZ:**
1. choice — "`Path::new(base).join(user_input)` with `user_input =
   \"../../etc/x\"`…" a) is blocked by Rust b) escapes `base` — join does no
   containment; this is path traversal (CWE-22) c) panics → **b**
2. choice — "Which does Rust's memory safety NOT protect against?" a) use-after-
   free b) path traversal, command injection, and logic bugs c) data races →
   **b**
3. text — "To avoid shell injection, pass an argument ___ instead of building a
   shell string." → **vector** (accept: `array`, `list`, `arg vector`, `args`)

**RECAP:**
```
memory safety is not security — safe Rust still ships traversal, injection, logic bugs
Path::join does no containment (CWE-22); shell-string interpolation is injection (CWE-78)
after you confirm no memory corruption, the real security review has only just begun
```

**HINTS:** L1: six answer keys — the CWE formats and options are printed in the
BRIEF and step list. L2: q1/q3 are the two CWE numbers named inline in the file's
FLAW comments; q5 asks which flaw is pure logic (no scanner sees intent); the
traversal demo line literally shows the escaped path. L3: run it — `rustc
fetch.rs -o fetch; ./fetch` — the resolved path printing `.../etc/shadow` is FLAW
1 proving itself; match each printed line to its FLAW comment.

---

### L4.8 — Supply chain — cargo audit, cargo deny, RUSTSEC advisories
**GUIDED · gate:false · est 15 · files/: advisory.txt (read-only exhibit), vuln-project/ (mini crate)**
**objective:** "Run the supply-chain toolchain (cargo audit / cargo deny) against a project, read a RUSTSEC advisory, and record what each tool is FOR — dependency risk the compiler never sees."

**files/advisory.txt:** a vendored, lightly-trimmed copy of ONE real RUSTSEC
advisory record (chosen at build time; record its RUSTSEC id and the crate/
version in the file header). Must show the standard fields a learner reads:
advisory id (`RUSTSEC-YYYY-NNNN`), affected crate + versions, the vulnerability
category (e.g. "memory-corruption" / "denial-of-service"), and the patched
version. `[VERIFY-AT-BUILD: paste a real current advisory verbatim from the
RustSec advisory-db; do not invent an id or fields.]`
**files/vuln-project/:** a minimal crate whose `Cargo.toml` pins one dependency
at a version an advisory flags (or a `deny.toml` with a policy the learner will
see enforced). Its purpose is to give `cargo audit`/`cargo deny` something real
to report. `[VERIFY-AT-BUILD: pick a crate+version pair that cargo audit still
flags at build time; the learner's shell fetches the advisory DB over the
network — check.sh never does.]`

**GUIDED STEPS outline (run in the learner's OWN shell — it may network):**
1. `command -v cargo-audit || cargo install cargo-audit` (network; lab.md notes
   this is a one-time install; check.sh never runs it).
2. `cd vuln-project && cargo audit > ../audit_out.txt 2>&1 || true && cd ..`
   (`|| true` because audit exits non-zero when it finds advisories — that is the
   *expected* success here). Expected: at least one `RUSTSEC-` line and a
   `Vulnerabilities` / `error:` summary `[VERIFY-AT-BUILD: exact header words]`.
3. Read `advisory.txt` — map its fields to what audit reported.
4. Answer in answers.txt (options in lab.md):
   - q1 (choice) what does `cargo audit` check? a) code style b) your dependency
     tree against the RUSTSEC advisory database — known-vulnerable versions
     c) compile errors → `q1=b`
   - q2 (choice) `cargo deny` adds, beyond audit: a) nothing b) policy
     enforcement in CI — ban licenses, duplicate versions, unmaintained or
     specific crates, not just known CVEs → `q2=b`
   - q3 (value) the advisory id prefix all RUSTSEC advisories share (format
     `RUSTSEC`) → `q3=RUSTSEC`
   - q4 (choice) a `cargo audit` finding means: a) your code is buggy b) a
     *dependency* you pull in has a known advisory — supply-chain risk the
     compiler cannot see c) a lint → `q4=b`
   - q5 (choice) the remediation for most advisories: a) rewrite the dep b) bump
     to the patched version (or replace/remove the crate) c) add `unsafe` →
     `q5=b`
5. `lab check rust L4.8`.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=b$'`,
`'^q4=b$'`, `'^q5=b$'`;
`assert_file_contains_fixed answers.txt 'q3=RUSTSEC'`;
`assert_file_contains audit_out.txt 'RUSTSEC'` (hint: step 2 — the redirected
`cargo audit` output must contain at least one advisory id);
`ck_summary`.
(CI fabrication: echo the answers; echo a line containing `RUSTSEC-2023-0001`
into audit_out.txt — a real run and this echo both satisfy the grep, keeping
acceptance network-free.)

**QUIZ:**
1. choice — "`cargo audit` protects against…" a) your own logic bugs b) pulling
   in dependency versions with known published advisories (RUSTSEC) c) slow
   builds → **b**
2. choice — "Why is supply-chain risk invisible to the compiler?" a) it isn't
   b) a dependency can compile perfectly and still contain a known
   vulnerability — 'compiles' says nothing about 'advisory-free' c) the compiler
   checks crates.io → **b**
3. text — "The prefix of every RustSec advisory id (e.g. ____-2024-0001)." →
   **rustsec**

**RECAP:**
```
cargo audit = your dependency tree vs the RUSTSEC advisory DB — known-vulnerable versions
cargo deny = CI policy: ban licenses, duplicates, unmaintained/specific crates, not just CVEs
supply-chain risk is invisible to the compiler; 'it compiles' never means 'advisory-free'
```

**HINTS:** L1: five answer keys and a redirected audit_out.txt — the grader names
each miss. L2: q1/q2 are the two tools' jobs (audit = known advisories, deny =
policy); q3 is the shared advisory prefix visible all over advisory.txt; the
audit output file must contain a `RUSTSEC-` line. L3: `cd vuln-project; cargo
audit > ../audit_out.txt 2>&1 || true; cd ..` then read advisory.txt for the id
prefix.

---

### L4.9 — Clippy as a code reviewer
**GUIDED · gate:false · est 15 · files/: lints.rs**
**objective:** "Run clippy on a lint-rich file, read the emitted lint names, and sort them into security-relevant vs cosmetic — clippy as a first-pass reviewer, and its blind spots."

**files/lints.rs (compiles; deliberately triggers several clippy lints — no
unsafe, runs fine, the point is what clippy SAYS about it):**
```rust
// lints.rs — this compiles and runs. Run clippy on it and read what it flags.
fn risk_score(events: &Vec<u32>) -> u32 {   // clippy: ptr_arg (&Vec -> &[])
    let mut sum = 0;
    for i in 0..events.len() {               // clippy: needless_range_loop
        sum = sum + events[i];               // clippy: could be += ; indexing
    }
    if sum > 100 {
        return true as u32;                  // clumsy; clippy may flag
    }
    return sum;                              // clippy: needless_return
}

fn main() {
    let events = vec![10u32, 20, 30];
    let total: u32 = events.iter().map(|x| x * 1).sum();  // clippy: identity_op (* 1)
    println!("score = {}", risk_score(&events));
    println!("total = {total}");
}
```
Expected clippy lints `[VERIFY-AT-BUILD: run `cargo clippy` / `clippy-driver` and
pin the ACTUAL emitted lint names — do not ship a speculative set; the list above
is the design intent, not a guarantee]`: `clippy::ptr_arg`,
`clippy::needless_range_loop`, `clippy::needless_return`, `clippy::identity_op`
(and possibly more). Program output when run: `score = 60` / `total = 60`.
Teaching beats: clippy is a fast automated first-pass reviewer — it catches
idiom, correctness smells, and some genuine bug shapes (e.g. `ptr_arg` widening
an API needlessly, suspicious operations); the reviewer skill is triage — most
clippy lints are style/idiom (`needless_return`, `identity_op`), a few point at
real correctness risks, and clippy sees NONE of the Phase-4 security classes:
it will not find L4.7's path traversal, injection, or logic bug, nor L4.4's
truncation-defeats-the-check — the mirror of bash L3.8's "ShellCheck co-pilot"
lesson. Green clippy ≠ secure.

**GUIDED STEPS outline (learner's own shell):**
1. `command -v cargo-clippy || rustup component add clippy` (lab.md notes this;
   check.sh never runs it).
2. Run clippy on the file and capture it. Since a bare file has no cargo project,
   lab.md gives the driver form: `clippy-driver lints.rs 2> clippy_out.txt ||
   true` (or, if the learner prefers, wrap it in a throwaway `cargo new` — lab.md
   shows both) `[VERIFY-AT-BUILD: confirm the exact invocation that produces
   named clippy:: lints on a single file on the target]`.
3. Read the lint names in clippy_out.txt.
4. answers.txt (options in lab.md):
   - q1 (choice) what is clippy? a) a formatter b) a lint-based reviewer for
     idiom, correctness smells, and some bug shapes — a fast first pass c) a test
     runner → `q1=b`
   - q2 (choice) classify `needless_return` / `identity_op`: a) security-critical
     b) cosmetic/idiom — cleaner code, not a vulnerability → `q2=b`
   - q3 (choice) will clippy catch L4.7's path traversal or the inverted access
     check? a) yes b) no — those are logic/injection/traversal classes no linter
     in this stack sees → `q3=b`
   - q4 (value) one lint name clippy emits here, WITHOUT the `clippy::` prefix
     (e.g. the needless-range-loop one) → `q4=needless_range_loop`
     `[VERIFY-AT-BUILD: confirm this lint actually fires; if not, pick one that
     does and update the key + hint]`
   - q5 (choice) "clippy is clean" means: a) the code is secure b) the code is
     idiomatic — security review is a separate, human pass c) the code is tested
     → `q5=b`
5. `lab check rust L4.9`.

**CHECK LOGIC:** `assert_file_contains answers.txt '^q1=b$'`, `'^q2=b$'`,
`'^q3=b$'`, `'^q4=needless_range_loop$'`, `'^q5=b$'`;
`assert_file_contains clippy_out.txt 'clippy'` (hint: step 2 — the redirected
clippy output must mention clippy; capture stderr with `2> clippy_out.txt`)
`[VERIFY-AT-BUILD: confirm the token 'clippy' appears in real output — the lint
names carry the `clippy::` prefix, so it will]`;
`ck_summary`.
(CI fabrication: echo the answers; echo a `warning: ... clippy::needless_range_
loop` line into clippy_out.txt.)

**QUIZ:**
1. choice — "Clippy is best used as…" a) the final security sign-off b) a fast
   automated first-pass reviewer for idiom and correctness smells, before human
   review c) a replacement for tests → **b**
2. choice — "A clean clippy run tells you…" a) the code is secure b) the code is
   idiomatic — nothing about traversal, injection, or logic flaws c) the code
   is fast → **b**
3. text — "Clippy lint names carry which module-style prefix?" → **clippy**
   (accept: `clippy::`)

**RECAP:**
```
clippy is a fast first-pass reviewer: idiom, correctness smells, some real bug shapes
triage its output — most lints are cosmetic, a few point at genuine risk
clippy sees no traversal, injection, or logic bug — green clippy is not secure
```

**HINTS:** L1: five answer keys and a captured clippy_out.txt. L2: q2 sorts the
two named lints as style; q3/q5 are the blind-spot lesson (clippy misses Phase-4
security classes); q4 wants a lint name from your actual clippy output, minus the
`clippy::` prefix. L3: `clippy-driver lints.rs 2> clippy_out.txt || true`, read
the `clippy::NAME` tags, and write one of them (without the prefix) as q4.

---

### L4.10 — Phase gate: full audit of a 150-line intentionally flawed tool
**AUDIT · gate:TRUE · est 25 · files/: iocscan.rs (the flawed tool — compiles and runs)**
**objective:** "Prove Phase 4: audit a ~150-line memory-safe tool cold, find and classify all six planted flaws spanning the phase, and name each one's CWE or class."

**files/iocscan.rs (the complete artifact — build verbatim; compiles clean with
bare rustc, runs on the good demo input, is 100% safe Rust, and hides six planted
flaws. The `unsafe`-flavored flaw is a *readable* soundness bug that does NOT
detonate on the demo path — the artifact still runs cleanly so the gate ends
hands-on):**
```rust
// iocscan.rs — a toy IOC (indicator-of-compromise) line scanner. It compiles,
// it is memory-safe, and it runs on the sample input. It also contains six
// planted security flaws spanning Phase 4. Find them all. (Line references in
// the answer key are to THIS file as shipped — do not reformat it.)
use std::collections::HashMap;
use std::path::{Path, PathBuf};

// ---- config ----
const MAX_LINE_BYTES: u16 = 4096;

// FLAW A (CWE-197): declared_len arrives as u32 but is truncated to u16 before
// the size gate, so a value whose low 16 bits are small passes however large.
fn within_limit(declared_len: u32) -> bool {
    (declared_len as u16) <= MAX_LINE_BYTES
}

// FLAW B (CWE-22): the report path is built by joining a caller-supplied name
// onto the base directory with no containment check.
fn report_path(base: &str, name: &str) -> PathBuf {
    Path::new(base).join(name)
}

// FLAW C (CWE-78 pattern): a lookup command is assembled as a shell string from
// an untrusted indicator. Shown as the vulnerable shape; never executed here.
fn enrich_command(indicator: &str) -> String {
    format!("whois {indicator}")
}

// FLAW D (CWE-248): parses a "key:count" record and unwraps every step, so any
// malformed line crashes the whole scan.
fn parse_count(record: &str) -> (String, u32) {
    let (key, count) = record.split_once(':').unwrap();
    let n: u32 = count.parse().unwrap();
    (key.to_string(), n)
}

// FLAW E (logic bug): severity classification has an inverted threshold — a
// higher score should be MORE severe, but the comparison is backwards.
fn severity(score: u32) -> &'static str {
    if score < 10 {
        "critical"
    } else {
        "low"
    }
}

// FLAW F (CWE-190): total is a u16 accumulator over attacker-influenced counts;
// enough volume overflows it (panic in debug, silent wrap in release).
fn scan(records: &[&str]) -> String {
    let mut counts: HashMap<String, u32> = HashMap::new();
    let mut total: u16 = 0;
    for record in records {
        let (key, n) = parse_count(record);
        *counts.entry(key).or_insert(0) += 1;
        total += n as u16;
    }
    let mut keys: Vec<&String> = counts.keys().collect();
    keys.sort();
    format!("distinct = {}, total = {}", keys.len(), total)
}

fn main() {
    // good demo input — nothing here triggers the flaws, so the tool runs clean
    let records = ["scan:3", "auth:5", "scan:2"];
    println!("{}", scan(&records));

    println!("within_limit(512) = {}", within_limit(512));
    println!("report = {}", report_path("/srv/out", "daily.txt").display());
    println!("enrich = {}", enrich_command("scanme.example"));
    println!("severity(50) = {}", severity(50));
}
```
Expected output on the good demo `[VERIFY-AT-BUILD: run it]`:
```
distinct = 2, total = 10
within_limit(512) = true
report = /srv/out/daily.txt
enrich = whois scanme.example
severity(50) = low
```
(scan: total = 3+5+2 = 10; distinct keys = {scan, auth} = 2; severity(50) prints
`low` — which is itself FLAW E visibly wrong: a score of 50 should be critical.)

The six planted flaws (answer key):
| slot | fn | class | CWE |
|---|---|---|---|
| A | within_limit | numeric truncation defeats a size gate | CWE-197 |
| B | report_path | path traversal (no containment on join) | CWE-22 |
| C | enrich_command | OS command injection pattern (shell string) | CWE-78 |
| D | parse_count | panic/DoS on malformed input (unwrap chain) | CWE-248 |
| E | severity | inverted-threshold logic bug (no tool catches it) | (logic) |
| F | scan (`total: u16`) | integer overflow accumulator | CWE-190 |

**The graded matrix** (breadth rides answers.txt per L1.9/L2.10/L3.10 precedent —
quiz.json stays capped at 3; honor contract restated: audit from the source
first). lab.md prints, per slot, the function name and asks for the CWE token (or
`logic` for E), plus one multiple-choice "which line/why" per slot. Keys:
- CWE tokens: `a=CWE-197`, `b=CWE-22`, `c=CWE-78`, `d=CWE-248`, `f=CWE-190`, and
  `e=logic` (the one flaw with no CWE-style scanner signal)
- one reachability/why choice per slot (all six specified here; lab.md prints
  each with a shared 3-option style, correct answer always `b`):
  - whyA (within_limit): a) 512 is genuinely within the limit b) the u32→u16
    truncation happens before the comparison, so a large value whose low 16 bits
    are small passes the gate c) MAX_LINE_BYTES is set too small → `whyA=b`
  - whyB (report_path): a) the joined path might not exist b) `join` applies no
    containment, so `..` components in `name` escape `base` entirely c) PathBuf
    allocation is expensive → `whyB=b`
  - whyC (enrich_command): a) `whois` is deprecated b) an untrusted `indicator`
    is interpolated into a shell command string — injection the moment it reaches
    a shell c) the string may be too long → `whyC=b`
  - whyD (parse_count): a) `split_once` is slow b) every step unwraps, so a
    single malformed record panics the entire scan c) `u32` is too narrow →
    `whyD=b`
  - whyE (severity): a) the input scores are wrong b) the threshold is inverted —
    `score < 10` returns "critical", so high scores map to "low" c) `&'static
    str` cannot hold the label → `whyE=b`
  - whyF (scan `total`): a) HashMap ordering is unspecified b) `total` is `u16`
    and overflows under enough attacker-driven volume — panic in debug, silent
    wrap in release (CWE-190) c) the keys vector leaks memory → `whyF=b`

**GUIDED STEPS outline:** read iocscan.rs cold, fill the matrix (six class tokens
+ the why-choices) → compile/run to confirm the tool works and to SEE flaw E lie
(`severity(50) = low`) → `rustc iocscan.rs -o iocscan` → check. Learners keep the
compiled `./iocscan`; check runs it on the good input.

**CHECK LOGIC:** class-token greps —
`assert_file_contains_fixed answers.txt 'a=CWE-197'`,
`... 'b=CWE-22'`, `... 'c=CWE-78'`, `... 'd=CWE-248'`, `... 'f=CWE-190'`;
`assert_file_contains answers.txt '^e=logic$'`;
the six why-choices — `assert_file_contains answers.txt '^whyA=b$'`,
`'^whyB=b$'`, `'^whyC=b$'`, `'^whyD=b$'`, `'^whyE=b$'`, `'^whyF=b$'`;
`assert_output_contains 'iocscan runs on good input' 'distinct = 2, total = 10'
'compile it: rustc iocscan.rs -o iocscan' -- ./iocscan`;
`ck_summary`.
(CI fabrication: echo the matrix lines; `#!/bin/sh` stub `./iocscan` printing the
five demo output lines.)

**QUIZ (concept-level, not duplicating the matrix):**
1. choice — "Five of the six flaws have CWE ids; one does not. Which, and why?"
   a) the truncation — it is too small to classify b) the inverted severity
   threshold — it is a pure logic bug, and no linter, auditor, or the borrow
   checker sees intent c) the panic — panics are not tracked → **b**
2. choice — "Every flaw in this tool coexists with…" a) an unsafe block
   b) complete memory safety — the borrow checker is satisfied by all six; safety
   bought nothing against them c) a compile error → **b**
3. text — "The one-line thesis of Phase 4: memory safety is not ___." →
   **security** (accept: `the same as security`, `safety from all bugs`)

**RECAP:**
```
gate passed: six flaws found in memory-safe Rust — truncation, traversal, injection, DoS, logic, overflow
five carry CWE ids; the inverted-threshold logic bug carries none — only a human reading intent finds it
Phase 4's verdict stands: memory safety is not security; your review starts where the borrow checker stops
```

**HINTS:** L1: the matrix has one class token + one why-choice per flaw slot
(A–F), plus a runnable ./iocscan — the grader names every miss; the CWE
vocabulary is printed in lab.md. L2: walk each function against its phase lab —
within_limit is L4.4's truncation, report_path is L4.7's traversal, enrich_command
is L4.7's injection, parse_count is L4.5's unwrap-DoS, severity is a pure logic
bug (L4.7's third flaw class), scan's `total: u16` is L1.2/CWE-190 overflow.
L3: compile and run (`rustc iocscan.rs -o iocscan; ./iocscan`) — `severity(50) =
low` is flaw E proving itself; then map each function's inline FLAW comment to its
CWE token (or `logic` for severity).

---

## 5. Build-session protocol (execute in this order)

0. **Prerequisite: Phases 0–3 built first** (recall refinement + `lab`
   progression).
1. Scaffold the 10 lab directories under `tracks/rust/phases/p4/` per §1 slugs.
2. Author content straight from §4; base64 all answers; `accept_b64` variants as
   listed. Honor the two framing rules (no weaponized payloads; no runnable UB) —
   L4.2's exhibit and every FLAW comment stay identification-only.
3. **Refine L4.1's recall.json** against the real built p0–p3 content (all five
   questions are map-sourced placeholders, `[VERIFY-AT-BUILD]`).
4. **[VERIFY-AT-BUILD] sweep (real toolchain; never inside check.sh):**
   - Compile and run every RUNNABLE sample (L4.1, L4.3, L4.4, L4.5, L4.6, L4.7,
     L4.10); confirm outputs byte-for-byte, including L4.4's truncation values
     (65636 as u16 = 100), L4.6's parse results, L4.7's resolved traversal path,
     and L4.10's full demo output. Confirm E0133 at both sites (L4.1 broken, L4.3
     broken) and — critically — that **libc `abs` links and resolves under plain
     `rustc`** on the target (L4.3); if it does not, switch L4.3 to a `#[link]`ed
     or cargo build and note the deviation.
   - Confirm L4.5's panic captures `panicked` in stderr.
   - **L4.2 is NEVER compiled** (read-only UB exhibit) — verify only that its
     described flaws are accurately stated by reading.
   - **L4.8:** pick a crate+version that `cargo audit` still flags at build time;
     paste one real RUSTSEC advisory into advisory.txt verbatim (record its id
     and the crate/version in the header). Confirm the redirected output contains
     a `RUSTSEC-` line.
   - **L4.9:** run clippy on lints.rs and PIN the actual emitted `clippy::` lint
     names; confirm `needless_range_loop` (q4 key) actually fires — if not,
     choose a lint that does and update the key + hint; confirm the exact
     single-file invocation that emits named lints on the target.
   Fix content to reality and log every deviation.
5. Lint gates: `./tools/lint-labs.sh` clean. **ERE discipline** — escaped parens
   in L4.3/L4.4 asserts already specified; the L4.7/L4.10 output greps
   deliberately target metacharacter-free fragments (`etc/shadow`, `distinct = 2,
   total = 10`). No absolute-path literals in any check.sh (the sample *content*
   has `/srv/...` strings, but those live in `files/`, which is never linted).
6. Acceptance: extend `tests/acceptance.sh` with a P4 section per the established
   pattern — fabricated pass (echo answers/outputs; stub binaries for ./sample
   ×3 [L4.1, L4.3, L4.4] plus the separate L4.6 ./sample — four total, each in
   its own per-lab workspace so the shared `sample` basename never collides —
   plus ./fetch, ./parse, ./iocscan; echo panic1.txt, audit_out.txt,
   clippy_out.txt) + one negative case per lab. **L4.2 has no binary** — its
   negative case corrupts a matrix key. Drive `lab start rust L4.1` with 5 piped
   recall answers, assert non-gating. Update every stale catalog-count
   denominator at every call site (standing precedent).
7. Manual full-phase pass with the real toolchain — INCLUDING actually running
   `cargo audit` and `cargo clippy` once (L4.8/L4.9 are the only labs whose real
   value needs a live network/toolchain) — before tagging `rust-p4`.
8. Update `planned_execution.md` (build session's job, not this plan's).

## 6. Decisions & deviations log (for the reviewer)

- **Two non-negotiable framing rules (§ header)** — no weaponized payloads (flaws
  are shown as patterns to identify; detonation demos are inert), no runnable
  undefined behavior (memory-unsafe flaws are read-only exhibits). This keeps a
  security-audit phase squarely defensive and avoids the classifier friction the
  bash L4.8 build hit (planned_execution.md records a review prompt flagged for a
  literal exploit string — L4.7/L4.10 ship none).
- **L4.2 is a read-only exhibit, never compiled** — capturing UB from
  `from_raw_parts` misuse is unreliable and shipping runnable UB is
  irresponsible; the lab grades reading (answers.txt) against a stated flaw set.
  Consequence: no binary, so its acceptance negative case corrupts an answer key.
  (L2.8/L3.9/L3.10 established the exhibit precedent.)
- **L4.3 runs a REAL FFI call (libc `abs`)** rather than a read-only exhibit —
  bare rustc links libc by default, so this is a genuine, safe, runnable cross-
  boundary call and a far better lesson than a non-compiling stub. The one build
  risk (does `abs` resolve under plain rustc on the target?) is flagged with a
  concrete fallback (§5.4).
- **L4.8 and L4.9 are the only labs needing a live network/toolchain** — by the
  env -i fence, check.sh cannot run cargo/clippy, so the learner runs them in
  their own shell and check.sh grades a redirected artifact with a marker grep
  that a fabricated echo also satisfies (L0.1's toolchain.txt pattern). Real
  advisory (L4.8) and real lint names (L4.9) are `[VERIFY-AT-BUILD]` — never
  invented; the build session pins current, real values.
- **Every runnable "flaw" demo is inert** — L4.4 prints a wrong number, L4.5
  captures a panic line, L4.7 prints a resolved traversal path and the shell
  string that WOULD run (never executed), L4.10 runs clean on good input and lets
  flaw E (inverted severity) visibly lie. No demo performs a malicious effect.
- **L4.10 hides six flaws, one per major phase thread** (truncation, traversal,
  injection, panic-DoS, logic, overflow); five carry CWE ids and one (inverted
  threshold) deliberately carries none — the gate's sharpest point: the single
  flaw no tool in the course's stack can catch. Breadth rides answers.txt; the
  tool still compiles and runs so the gate ends hands-on.
- **CWE ids used:** CWE-190 (L4.1 recall, L4.5, L4.10-F), CWE-197 (L4.4,
  L4.10-A), CWE-248 (L4.5, L4.10-D), CWE-125 (L4.2), CWE-22 (L4.7, L4.10-B),
  CWE-78 (L4.7, L4.10-C), CWE-416 (L4.2 lifetime-launder, recalled from L2.8).
  All hand-assigned from canonical definitions; the class *names* are the primary
  teaching content and the ids are transcription (format given in each BRIEF).
- **E0133 appears twice** (L4.1 broken, L4.3 broken) — same code, same lesson
  (an unsafe/extern call escaping its block); both tagged for message
  confirmation.
- **Arithmetic hand-verified:** 65636 − 65536 = 100 (L4.4, L4.10-A); L4.5 total
  3+5=8; L4.6 0xC8 = 200; L4.10 scan total 3+5+2 = 10, distinct = 2.
- **Plan-time verification coverage (honest report):** author self-review only;
  no adversarial fleet at plan time. §5.4's toolchain sweep is the authoritative
  verification for every `[VERIFY-AT-BUILD]` tag, and this phase carries more of
  them than any prior phase — the two GUIDED labs (real advisory id, real clippy
  lint names), the FFI link behavior, and every quoted rustc message. Lower-
  confidence items are tagged at their sites.
