# RUST TRACK — Phase 0 + Phase 1 Build Plan (v1)

Binding content spec: `docs/curriculum/rust-literacy-lab-curriculum-v1.md` (Phase 0 +
Phase 1 sections). Binding mechanical spec: `docs/kit-contracts.md`. Reference
implementation of every file format: `tracks/demo/phases/p0/L0.0-meet-the-kit/`.
This plan is the single source of design judgment for the build session — build it
mechanically; where reality contradicts a claim marked `[VERIFY-AT-BUILD]`, fix the
content to match reality and note the deviation in the build report.

## 1. Lab list (from the map, exactly)

| id | title (meta.json `title`) | type | gate | est_minutes | dir slug |
|---|---|---|---|---|---|
| L0.1 | Toolchain up — rustup, cargo, first build on WSL2 | GUIDED | false | 20 | `L0.1-toolchain-up` |
| L0.2 | Meet the lab kit — CLI, checks, resume | GUIDED | false | 10 | `L0.2-meet-the-lab-kit` |
| L0.3 | Anatomy of a Rust repo — Cargo.toml, src/, cargo doc, docs.rs | DECODE | **true** | 15 | `L0.3-repo-anatomy` |
| L1.1 | `let`, `mut`, shadowing — immutable by default | PREDICT | false | 10 | `L1.1-let-mut-shadowing` |
| L1.2 | Integers without footguns — overflow in debug vs release | PREDICT | false | 15 | `L1.2-integer-overflow` |
| L1.3 | Expressions everywhere — blocks and `if` return values | PREDICT | false | 10 | `L1.3-expressions-everywhere` |
| L1.4 | Functions and the ownership preview | DECODE | false | 15 | `L1.4-functions-ownership-preview` |
| L1.5 | Structs — data without constructor magic | DECODE | false | 15 | `L1.5-structs` |
| L1.6 | Enums are not C enums — variants that carry data | DECODE | false | 15 | `L1.6-enums-carry-data` |
| L1.7 | `match` — exhaustiveness as a security feature | FIX | false | 15 | `L1.7-match-exhaustiveness` |
| L1.8 | No null — first contact with `Option<T>` | PREDICT | false | 15 | `L1.8-option-not-null` |
| L1.9 | Phase gate: read a 60-line program cold, answer 10 questions | AUDIT | **true** | 20 | `L1.9-phase-gate-read-cold` |

Gate placement judgment: the map marks L1.9 explicitly. Phase 0's "exit gate"
paragraph ("clone a random crate and answer: what does this project do and where's
the entry point?") is exactly L0.3's content, and the demo track's precedent puts
`gate: true` on the phase-final lab — so L0.3 carries `gate: true`.

recall.json placement: **L1.1 only** (5 questions drawn from Phase 0, per the
spaced-recall contract). L0.1 gets none — there is no earlier phase in this track,
the kit treats recall.json as optional (only its *position* is linted:
`lib/catalog.sh:166-169`), and demo L0.0's recall was a self-referential bootstrap
special case. Directory layout per lab is fixed by `docs/kit-contracts.md`:
`tracks/rust/phases/p<N>/<slug>/{meta.json,lab.md,quiz.json,check.sh,hints.json,recap.md[,files/,recall.json]}`.

## 2. Binding harness constraints (why every check below looks the way it does)

1. **`check.sh` never runs cargo or rustc.** Checks execute under
   `env -i PATH=/usr/local/bin:/usr/bin:/bin HOME=<ws>/.home ...` — rustup installs
   to `~/.cargo/bin` under the learner's real HOME, so the toolchain is invisible to
   graders *by design*. All grading is artifact-based: (a) `key=value` answer files,
   (b) learner-redirected command output files, (c) learner-built binaries executed
   by relative path (`assert_output_contains ... -- ./hello_lab/target/debug/hello_lab`
   works: it needs no PATH, captures stdout+stderr, and tolerates non-zero exit).
2. **CI-fabricatable artifacts principle:** every check.sh must be passable by
   fabricating artifacts without a Rust toolchain (e.g. a 2-line `#!/bin/sh` script
   standing in for a compiled binary). This is what lets `tests/acceptance.sh` and
   lint CI run on machines with no rustc. Never grade anything only cargo could
   produce in-check.
3. **lint-labs.sh bans** (check.sh only): absolute-path literals, `eval`, `sudo`,
   `curl`, `wget`, ` nc `, `ssh `, `sh -c`, `bash -c`, `pushd`, `bin/lab`,
   `cd ..`/`cd ~`; mode must be 0644; `set -euo pipefail` + LAB_WORKSPACE/LAB_CHECKLIB
   guards + `source "$LAB_CHECKLIB"` mandatory; `ck_summary` is the last line;
   collect-all style (assertions never abort). `# shellcheck disable=` is banned
   repo-wide. Learner-facing `.rs` files live under `files/` and are never linted or
   shellchecked.
4. **File contracts:** quiz.json exactly 3 questions; hints.json exactly 3 levels
   (level 1 never reveals the answer); recap.md exactly 3 lines, no bullet prefix;
   lab.md has exactly the headings `## BRIEF` (≤10 lines of text) and
   `## GUIDED STEPS`; meta.json `{id,title,type,objective,gate,est_minutes}` with
   `id` equal to the directory id. Answers are base64:
   `printf '%s' 'answer' | base64 -w0`. Text quiz answers are normalized at grade
   time (lowercased, trimmed, whitespace-collapsed) — store `answer_b64` already
   lowercase; add `accept_b64` variants where learners may reasonably phrase
   differently.
5. **Quiz I/O:** one line per question from stdin, no reprompting —
   `printf 'a\nb\nc\n' | lab check rust <id>` must behave identically to typing.
   recall runs at `lab start` (non-gating, informational ≥4/5).

## 3. Track-wide conventions (decided here, applied to all 12 labs)

- **Answer files.** Graded free responses go in `key=value` lines, **no spaces around
  `=`**, in `predictions.txt` (PREDICT labs) or `answers.txt` (DECODE/FIX/AUDIT
  labs), created by the learner in the workspace root. Conceptual questions are
  lettered multiple choice (options printed in lab.md; answer like `q1=b`) so
  grading is exact; value questions take the exact program output token
  (case-sensitive, e.g. `p1=Some(22)`). check.sh greps with anchored ERE
  (`'^q1=b$'`) or fixed literals for values containing regex metacharacters
  (`assert_file_contains_fixed` for `Some(22)`).
- **PREDICT protocol.** lab.md prints the full sample inline; the same file ships in
  `files/`. Steps: (1) read, (2) write every prediction into `predictions.txt`,
  (3) compile and run, (4) compare; compile-fail teasers ask for the error **code**
  (`error=E0384`), which the learner reads off the real compiler output — grading
  transcription is fine, the rep is reading the error. BRIEF carries the honor
  framing once per lab: "the check can't tell whether you predicted first — you're
  only cheating your own reps."
- **Build tool per lab.** Phase 1 uses bare `rustc` on single files (one concept per
  lab; no Cargo ceremony) — `rustc sample.rs -o sample && ./sample`. Exceptions:
  L1.2 ships a minimal cargo project because debug-vs-release *profiles* are the
  concept. Phase 0 uses cargo (that's its content). Note: bare `rustc` compiles as
  edition 2015; every Phase-1 sample is edition-independent (inline `{x}` format
  captures are a 1.58 std feature, not edition-gated) `[VERIFY-AT-BUILD: compile
  every sample with plain rustc, no flags]`.
- **Broken samples** are separate `broken.rs` files (never inline edits of the
  working sample), so the workspace always ends with a compiling `sample.rs` whose
  binary check.sh can run.
- **Quiz vs answers separation.** quiz.json questions never duplicate the graded
  answer-file questions verbatim; they test the same concept from a different angle.
- **Hints ladder shape** (all labs): L1 = which artifact/step to look at, never
  content; L2 = narrows to the exact line/command and expected shape; L3 = near-
  answer procedure (for PREDICT labs L3 says "run it and transcribe" — the run *is*
  the legitimate answer source — but never prints prediction values).
- **Workspace hygiene.** Learner work happens in `workspace/rust/<id>/`; repo-root
  `.gitignore` already covers `/workspace/` (verified at plan time), so cargo
  `target/` trees never dirty git.
- **meta.json `objective`** given per lab below; `titles` exactly as §1.

## 4. Lab entries

---

### L0.1 — Toolchain up — rustup, cargo, first build on WSL2
**GUIDED · gate:false · est 20 · files/: none**
**objective:** "Install or verify the Rust toolchain and drive one full cargo new/build/run cycle, leaving graded evidence in the workspace."

**BRIEF gist (builder expands to ≤10 lines):** This track trains reading, not
writing — but a reader who can't build can't verify. Today is pure plumbing: rustup
(the toolchain manager), cargo (the build tool), one throwaway crate. Every later
lab assumes `cargo` works in this WSL2 terminal.

**GUIDED STEPS outline:**
1. Toolchain present? `command -v cargo` — if missing, install via the official
   rustup one-liner (printed in lab.md; learner shell may network — check.sh never
   does), then `source "$HOME/.cargo/env"` or reopen the shell.
2. Record versions (graded): `rustc --version > toolchain.txt` then
   `cargo --version >> toolchain.txt`. Expected shape shown:
   `rustc 1.8x.y (…)` / `cargo 1.8x.y (…)`.
3. `cargo new hello_lab` — walk the generated tree (`Cargo.toml`, `src/main.rs`).
   (Inside the kit's git repo cargo skips `git init` — harmless either way.)
4. `cd hello_lab && cargo run > ../first_run.txt && cd ..` — build noise goes to
   stderr (terminal), stdout (`Hello, world!`) lands in the file. Show expected
   compile-progress lines.
5. Peek at `hello_lab/target/debug/hello_lab` — the actual binary; run it directly
   once: `./hello_lab/target/debug/hello_lab`.
6. `lab check rust L0.1`.

**CHECK LOGIC (check.sh):**
- `assert_file_contains toolchain.txt '^rustc [0-9]+\.[0-9]+'` — hint: step 2.
- `assert_file_contains toolchain.txt '^cargo [0-9]+\.[0-9]+'` — hint: step 2.
- `assert_file_exists hello_lab/Cargo.toml` — hint: step 3 `cargo new hello_lab`.
- `assert_file_contains_fixed hello_lab/Cargo.toml 'name = "hello_lab"'`
- `assert_file_exists hello_lab/src/main.rs`
- `assert_file_contains_fixed first_run.txt 'Hello, world!'` — hint: step 4 redirect.
- `assert_file_exists hello_lab/target/debug/hello_lab`
- `assert_output_contains 'built binary runs and greets' 'Hello, world!' 'step 5 — cargo run must have produced target/debug/hello_lab' -- ./hello_lab/target/debug/hello_lab`
- `ck_summary`
(CI fabrication: `mkdir -p hello_lab/src hello_lab/target/debug`; echo the toml
line, main.rs stub, version lines, greeting file; install a 2-line `#!/bin/sh`
greeter as the "binary", `chmod +x`.)

**QUIZ (plaintext answers; builder base64-encodes):**
1. choice — "cargo run vs cargo build?" a) run only executes an existing binary
   b) run rebuilds if needed, then executes c) they are aliases → **b**
2. text — "Directory (relative to the crate root) where unoptimized debug binaries
   land?" → **target/debug** (accept: `target/debug/`)
3. choice — "rustup's job?" a) package registry b) installs/updates Rust toolchains
   c) builds crates → **b**

**RECAP (exactly 3 lines):**
```
rustup manages toolchains; cargo builds — new/build/run is the whole loop
cargo run = compile if needed + execute; stdout is yours, build noise is stderr
debug binaries land in target/debug/<crate> — a plain executable you can run
```

**HINTS:** L1: every graded artifact maps to one numbered step — `ls` and compare
against the step list. L2: `toolchain.txt` needs both version lines (exact commands
in step 2); `first_run.txt` must be stdout of `cargo run` executed *inside*
hello_lab, redirected to `../first_run.txt`. L3: replay verbatim:
`rustc --version > toolchain.txt; cargo --version >> toolchain.txt; cargo new hello_lab; cd hello_lab; cargo run > ../first_run.txt; cd ..` then re-check.

---

### L0.2 — Meet the lab kit — CLI, checks, resume
**GUIDED · gate:false · est 10 · files/: kit-notes.txt**
**objective:** "Drive the kit's own mechanics — status, hint ladder, key=value answer files, the fence, resume — once each, on rails."

**files/kit-notes.txt:** ~15 lines of facts the steps and answers draw from: the
five CLI verbs; check = check.sh grader + 3-question quiz, 3/3 required; hint ladder
= 3 levels, level 1 never answers; `lab resume` replays the last recap + next lab;
marks ✓/○/⏭ and ⏭'s permanence; this track's convention: graded answers are
`key=value` lines, no spaces around `=`, exact keys.

**GUIDED STEPS outline:**
1. `lab status` from the repo root — find this lab's ▶ mark.
2. Read `kit-notes.txt` in the workspace.
3. Spend one hint for free: `lab hint rust L0.2` — see level 1's shape.
4. Create `answers.txt` with three lines (questions + options printed here):
   - q1 (choice): first command after a month away? a) lab status b) lab resume
     c) lab hint → learner writes `q1=b`
   - q2 (value): how many hint levels does every lab have? → `q2=3`
   - q3 (choice): quiz comes back 2/3 — what happened? a) partial credit saved
     b) the whole check failed; nothing lost, run `lab check` again c) lab resets → `q3=b`
5. Prove you're inside the fence: `pwd > location.txt`.
6. `lab check rust L0.2` — type quiz answers when prompted.

**CHECK LOGIC:**
- `assert_file_contains answers.txt '^q1=b$'` / `'^q2=3$'` / `'^q3=b$'` — hints
  point at step 4 and kit-notes.txt.
- location.txt fence proof — copy demo L0.0's realpath-compare block verbatim
  (`tracks/demo/.../check.sh:15-26`), adjusted hint text (`workspace/rust/L0.2`).
- `ck_summary`

**QUIZ:**
1. choice — "⏭ in lab status means?" a) passed on retry b) forced past with
   --force; never becomes ✓ c) locked → **b**
2. text — "Command that prints the phase map with ✓ marks?" → **lab status**
3. choice — "Why must answer-file keys match exactly (q1=, not Q1 =)?"
   a) style preference b) check.sh greps exact anchored keys — a typo is a fail
   c) the CLI rewrites them → **b**

**RECAP:**
```
lab check = check.sh grader + quiz, 3/3 — fail costs nothing but a rerun
this track grades key=value answer files: exact keys, no spaces around =
lab resume replays your last recap — 30-second re-entry is the contract
```

**HINTS:** L1: the grader wants exactly two files from steps 4–5 — compare your
workspace against the step list. L2: answers.txt needs exactly `q1=`/`q2=`/`q3=`
lines with the letter or number, no spaces; location.txt must be written from
inside `workspace/rust/L0.2`. L3: re-read kit-notes.txt lines about resume, the
hint ladder, and failed checks; the three answers are all in there — then
`pwd > location.txt` from the workspace and re-check.

---

### L0.3 — Anatomy of a Rust repo — Cargo.toml, src/, cargo doc, docs.rs
**DECODE · gate:TRUE · est 15 · files/: scanport/ (a complete mini crate)**
**objective:** "Open a never-seen crate and answer the two auditor questions cold: what does it do, and where is the entry point."

**files/scanport/Cargo.toml:**
```toml
[package]
name = "scanport"
version = "0.3.1"
edition = "2021"
description = "Tiny port-number sanity checker (teaching sample)"

[dependencies]
```

**files/scanport/src/main.rs:**
```rust
use scanport::parse_port;

fn main() {
    for raw in std::env::args().skip(1) {
        match parse_port(&raw) {
            Some(port) => println!("{raw} -> ok (port {port})"),
            None => println!("{raw} -> INVALID"),
        }
    }
}
```

**files/scanport/src/lib.rs:**
```rust
//! Parsing helpers for the scanport CLI.

/// Parse a decimal port string. Returns `None` unless it is 1..=65535.
pub fn parse_port(raw: &str) -> Option<u16> {
    match raw.trim().parse::<u16>() {
        Ok(0) => None,
        Ok(port) => Some(port),
        Err(_) => None,
    }
}

#[cfg(test)]
mod tests {
    use super::parse_port;

    #[test]
    fn rejects_zero() {
        assert_eq!(parse_port("0"), None);
    }
}
```
(The Option/match syntax is *ahead* of Phase 1 — deliberate: the gate skill is
navigating an unfamiliar repo structurally, not parsing every line. lab.md says so.)

**GUIDED STEPS outline:**
1. `ls -R scanport` — map the tree: manifest, `src/main.rs`, `src/lib.rs`.
2. Read Cargo.toml top to bottom — `[package]` identity vs `[dependencies]`
   supply chain (empty here — that itself is an audit datum).
3. Read both src files; note `use scanport::parse_port` — the binary consuming its
   own library crate; doc comments `//!` vs `///`.
4. Run it: `cd scanport && cargo run -- 22 99999 > ../run_out.txt && cd ..`
   expect `22 -> ok (port 22)` and `99999 -> INVALID` (99999 overflows u16 → parse
   error → None).
5. Docs like docs.rs builds them: `cd scanport && cargo doc --no-deps && cd ..` —
   output lands at `scanport/target/doc/scanport/index.html` `[VERIFY-AT-BUILD:
   path]`; docs.rs is this, run automatically for every published crate.
6. Answer in `answers.txt` (options printed in lab.md):
   q1 crate name → `q1=scanport`; q2 binary entry-point file (path from crate
   root) → `q2=src/main.rs`; q3 file where `parse_port` lives → `q3=src/lib.rs`;
   q4 number of third-party dependencies → `q4=0`; q5 (choice) what does this
   project do? a) scans remote hosts b) validates port-number strings
   c) benchmarks TCP throughput → `q5=b`; q6 (choice) docs.rs is: a) hosted
   `cargo doc` output for every published crate b) the language reference
   c) a crates.io mirror → `q6=a`
7. `lab check rust L0.3`.

**CHECK LOGIC:** anchored greps on answers.txt — `'^q1=scanport$'`,
`'^q2=src/main\.rs$'`, `'^q3=src/lib\.rs$'`, `'^q4=0$'`, `'^q5=b$'`, `'^q6=a$'`
(relative-path slashes in ERE are lint-safe: preceded by alnum);
`assert_file_contains_fixed run_out.txt '22 -> ok (port 22)'`;
`assert_file_contains_fixed run_out.txt '99999 -> INVALID'`;
`assert_file_exists scanport/target/doc/scanport/index.html` (hint: step 5
`cargo doc --no-deps`); `ck_summary`.
(CI fabrication: mkdir -p the doc path, touch index.html, echo the two run_out
lines and six answers.)

**QUIZ:**
1. choice — "A crate with both src/main.rs and src/lib.rs builds…" a) two
   independent programs b) a binary that can call the library crate c) docs only → **b**
2. text — "Command that builds local HTML docs for just this crate?" →
   **cargo doc --no-deps** (accept: `cargo doc`)
3. choice — "`[dependencies]` in Cargo.toml is…" a) build flags b) the third-party
   supply chain pulled from crates.io c) dev-only tools → **b**

**RECAP:**
```
Cargo.toml = identity ([package]) + supply chain ([dependencies])
src/main.rs is the binary entry; src/lib.rs is the library the binary calls
cargo doc --no-deps builds locally what docs.rs hosts for every published crate
```

**HINTS:** L1: six answers, two output lines, one generated HTML file — each comes
from a numbered step; find which one you skipped. L2: q1/q4 are literally in
Cargo.toml; q2/q3 are the two files under src/ (answer with paths from the crate
root, like src/main.rs); the doc file only exists after step 5's command. L3:
`cd scanport; cargo run -- 22 99999 > ../run_out.txt; cargo doc --no-deps; cd ..`
then re-read Cargo.toml for the name and count the entries under [dependencies].

---

### L1.1 — `let`, `mut`, shadowing — immutable by default
**PREDICT · gate:false · est 10 · files/: sample.rs, broken.rs · recall.json: YES (phase opener)**
**objective:** "Predict what let/mut/shadowing print before running, and read your first compiler rejection (E0384)."

**recall.json — 5 questions, all sourced from Phase 0:**
1. choice (source: "rust L0.1") — "Which cargo command compiles if needed and then
   executes?" a) cargo build b) cargo run c) cargo check → **b**
2. text (source: "rust L0.1 / L0.3") — "File that declares a crate's name and its
   dependencies?" → **cargo.toml** (accept: `Cargo.toml`)
3. text (source: "rust L0.1") — "Path of hello_lab's debug binary, from the crate
   root?" → **target/debug/hello_lab** (accept: `target/debug/hello_lab` with
   leading `./`)
4. choice (source: "rust L0.3") — "src/main.rs and src/lib.rs both exist — which is
   the binary entry point?" a) src/lib.rs b) src/main.rs c) whichever Cargo.toml
   names first → **b**
5. choice (source: "rust L0.2") — "Passing `lab check` requires…" a) grader only
   b) grader pass AND quiz 3/3 c) quiz 2/3 → **b**

**files/sample.rs:**
```rust
fn main() {
    let x = 5;
    let x = x + 1;
    let x = x * 2;
    println!("x = {x}");

    let mut count = 10;
    count += 5;
    println!("count = {count}");

    let label = "TCP";
    let label = label.len();
    println!("label = {label}");
}
```
Expected output (learner predicts these): `x = 12`, `count = 15`, `label = 3`.
Teaching beats: shadowing rebinds (each `let x` is a NEW variable — not mutation);
`mut` is the explicit opt-in C++ doesn't ask for; shadowing may change type
(&str → usize).

**files/broken.rs:**
```rust
fn main() {
    let retries = 3;
    retries = 5;
    println!("retries = {retries}");
}
```
Must produce **E0384** — `cannot assign twice to immutable variable `retries``
(rustc also suggests `mut`). `[VERIFY-AT-BUILD: exact message line]`

**GUIDED STEPS outline:** read sample.rs (printed inline) → write
`predictions.txt`: `x=12`-style lines for the three prints (`x=`, `count=`,
`label=`) → `rustc sample.rs -o sample && ./sample` → compare → `rustc broken.rs`
(expect rejection; read the error top line) → record `error=E0384` → check.

**CHECK LOGIC:** `assert_file_contains predictions.txt '^x=12$'`, `'^count=15$'`,
`'^label=3$'`, `'^error=E0384$'`; `assert_output_contains 'sample binary output'
'label = 3' 'step 3 — rustc sample.rs -o sample' -- ./sample`; `ck_summary`.

**QUIZ:**
1. choice — "In Rust, variables are ___ by default." a) mutable b) immutable
   c) uninitialized → **b**
2. choice — "`let x = x + 1;` after an earlier `let x` is…" a) mutation of x
   b) a compile error c) shadowing — a brand-new binding that may even change type → **c**
3. text — "Keyword that opts a binding into mutation?" → **mut**

**RECAP:**
```
immutable by default — mutation is an explicit opt-in with mut
let x = ... again is shadowing: a new binding, new type allowed, old one gone
E0384 = assigned twice without mut; the compiler names the fix
```

**HINTS:** L1: the grader reads predictions.txt — four exact keys (x, count,
label, error), no spaces around `=`. L2: trace each shadowing line one at a time —
each `let x` starts from the previous x's value; label becomes the *length* of
"TCP"; the error code is the `error[E....]` tag on the first line rustc prints.
L3: compile and run both files and transcribe what you see: `rustc sample.rs -o
sample; ./sample; rustc broken.rs` — the run is the answer sheet.

---

### L1.2 — Integers without footguns — overflow in debug vs release
**PREDICT · gate:false · est 15 · files/: overflow/ (mini cargo project)**
**objective:** "Predict the same u8 overflow panicking in debug and wrapping in release, and name the checked/wrapping alternatives (CWE-190)."

**files/overflow/Cargo.toml:**
```toml
[package]
name = "overflow"
version = "0.1.0"
edition = "2021"
```
**files/overflow/src/main.rs:**
```rust
fn bump(n: u8) -> u8 {
    n + 1
}

fn main() {
    let max: u8 = u8::MAX;
    println!("max = {max}");
    println!("checked = {:?}", max.checked_add(1));
    println!("wrapped = {}", max.wrapping_add(1));
    println!("bumped = {}", bump(max));
}
```
Design note (do not "simplify" away): the overflow crosses a function boundary
(`bump`) precisely so the deny-by-default `arithmetic_overflow` lint cannot
const-fold it into a *compile* error — it must survive to runtime.
`[VERIFY-AT-BUILD: cargo run panics at runtime, not compile time, on current stable]`

Expected debug (`cargo run`): three lines `max = 255`, `checked = None`,
`wrapped = 0`, then panic containing `attempt to add with overflow`
`[VERIFY-AT-BUILD: message text]`. Expected release (`cargo run --release`): same
three lines then `bumped = 0`.

**GUIDED STEPS outline:** read main.rs → `predictions.txt` with vocabulary given
in lab.md ("debug: one of panic/wrap/value · release: the printed number"):
`debug=panic`, `release=0`, `checked=None`, `wrapped=0` →
`cd overflow && cargo run > ../debug_out.txt 2>&1 || true` (the `|| true` because a
panic exits non-zero) → `cargo run --release > ../release_out.txt 2>&1 && cd ..` →
compare → check. Security hook stated in lab.md: this is CWE-190; a u8/u16 counter
fed by attacker-controlled event volume is a debug-build DoS and a release-build
silent wrap.

**CHECK LOGIC:** predictions.txt anchored greps `'^debug=panic$'`, `'^release=0$'`,
`'^checked=None$'` (fixed is fine too), `'^wrapped=0$'`;
`assert_file_contains_fixed debug_out.txt 'attempt to add with overflow'` (hint:
step 3 — run the DEBUG profile and keep stderr: `2>&1`);
`assert_file_contains_fixed release_out.txt 'bumped = 0'` (hint: step 4 —
--release); `ck_summary`. (CI fabrication: echo the lines.)

**QUIZ:**
1. choice — "Default cargo *debug* profile behavior on integer overflow?" a) wraps
   silently b) panics (overflow checks on) c) undefined behavior → **b**
2. text — "Method returning None instead of panicking on u8 overflow?" →
   **checked_add** (accept: `checked_add()`, `.checked_add`)
3. choice — "CWE-190 in a Rust service: worst realistic outcome of `total += evt`
   on a u8 in a *release* build?" a) memory corruption b) silent wraparound
   corrupting logic (e.g. counters, sizes) c) compile error → **b**

**RECAP:**
```
debug builds panic on overflow; release builds wrap silently — same source, two behaviors
wrapping_add / checked_add / saturating_add say what you MEANT — reviewers look for them
CWE-190: attacker-driven counters + small ints = DoS (debug) or logic corruption (release)
```

**HINTS:** L1: two output files and four prediction keys — the grader names each
missing one; re-run the exact redirects from the steps. L2: `debug_out.txt` must
contain the panic text, so the debug run needs `2>&1` (panics print to stderr);
release needs `--release`. L3: `cd overflow; cargo run > ../debug_out.txt 2>&1 ||
true; cargo run --release > ../release_out.txt 2>&1; cd ..` and transcribe what
each file shows into predictions.txt.

---

### L1.3 — Expressions everywhere — blocks and `if` return values
**PREDICT · gate:false · est 10 · files/: sample.rs, broken.rs**
**objective:** "Predict values produced by block and if expressions, and read E0308 when two arms disagree on type."

**files/sample.rs:**
```rust
fn classify(port: u32) -> &'static str {
    if port < 1024 { "well-known" } else { "registered" }
}

fn main() {
    let x = {
        let a = 3;
        a * a
    };
    println!("x = {x}");

    let kind = classify(443);
    println!("kind = {kind}");

    let parity = if x % 2 == 0 { "even" } else { "odd" };
    println!("parity = {parity}");
}
```
Expected: `x = 9`, `kind = well-known`, `parity = odd`. Teaching beats: a block's
value is its last expression *without a semicolon*; a function body is one such
block (no `return` needed); `if` is an expression, so both arms feed one type.

**files/broken.rs:**
```rust
fn main() {
    let width = if true { 5 } else { "six" };
    println!("width = {width}");
}
```
Must produce **E0308** — "`if` and `else` have incompatible types".
`[VERIFY-AT-BUILD: message line]`
(Design note — do not "improve" this by annotating `width: i32`: with an explicit
annotation rustc coerces each arm against the expected type and reports the plain
"mismatched types" flavor of E0308 blaming the annotation, not the arms — which
kills the teaching beat. No annotation → rustc unifies the arms → the canonical
incompatible-arms diagnostic. Verified by plan-time review.)

**GUIDED STEPS outline:** read → predict `x=9`, `kind=well-known`, `parity=odd` →
compile/run sample → `rustc broken.rs`, record `error=E0308` → check.

**CHECK LOGIC:**
- `assert_file_contains predictions.txt '^x=9$' 'step 2 — evaluate the block: last expression, no semicolon'`
- `assert_file_contains predictions.txt '^kind=well-known$' 'step 2 — trace classify(443)'`
- `assert_file_contains predictions.txt '^parity=odd$' 'step 2 — parity checks x, not 443'`
- `assert_file_contains predictions.txt '^error=E0308$' 'step 4 — rustc broken.rs; the code is in the error[E....] tag'`
- `assert_output_contains 'sample binary output' 'parity = odd' 'step 3 — rustc sample.rs -o sample' -- ./sample`
- `ck_summary`

**QUIZ:**
1. choice — "What makes a block evaluate to a value?" a) a return statement b) its
   last expression has no trailing semicolon c) the `yield` keyword → **b**
2. choice — "Add a semicolon to that last expression and the block's value
   becomes…" a) unchanged b) `()` — the unit type c) a compile error always → **b**
3. text — "In broken.rs, what is the type of the else arm's value \"six\"?" →
   **&str** (accept: `&'static str`, `str`, `string slice`)

**RECAP:**
```
almost everything is an expression: blocks, if, match all produce values
last line without a semicolon = the value; add the semicolon and you get ()
if is an expression, so both arms must agree on one type — E0308 otherwise
```

**HINTS:** L1: four prediction keys; the grader tells you which is missing or
wrong — reread that one construct. L2: evaluate the `{ let a = 3; a * a }` block
by hand (last expression, no semicolon); parity checks x, not 443; the error code
is on rustc's first output line. L3: run it and transcribe — `rustc sample.rs -o
sample; ./sample; rustc broken.rs`.

---

### L1.4 — Functions and the ownership preview
**DECODE · gate:false · est 15 · files/: sample.rs**
**objective:** "Explain from the signatures alone why a borrowed argument survives a call and a moved one doesn't (first sight of E0382)."

**files/sample.rs:**
```rust
fn shout(message: &str) -> String {
    message.to_uppercase()
}

fn consume(message: String) -> usize {
    message.len()
}

fn main() {
    let alert = String::from("port scan detected");
    let loud = shout(&alert);
    println!("{loud}");

    let size = consume(alert);
    println!("{size} bytes");

    // step 4: uncomment the next line, recompile, read the error, re-comment it
    // println!("{alert}");
}
```
Runs: `PORT SCAN DETECTED` then `18 bytes` ("port scan detected" is 18 bytes).
Uncommenting the marked line must produce **E0382** — "borrow of moved value:
`alert`" `[VERIFY-AT-BUILD]`. Teaching beats: `&str` parameter = borrows, caller
keeps it; `String` parameter = takes ownership, caller loses it; the *signature*
tells you which — that's the reading skill.

**GUIDED STEPS outline:** read; answer q1/q2 (options in lab.md) in answers.txt →
compile/run sample → step 4 experiment: uncomment, `rustc sample.rs` fails, record
`q3=E0382`, re-comment, recompile so `./sample` works again → check.
- q1 (choice): why is `alert` still usable after `shout(&alert)`? a) shout returns
  it b) shout only borrowed it — `&str` in the signature c) String is Copy → `q1=b`
- q2 (choice): what did `consume(alert)` do? a) copied alert b) took ownership —
  alert is gone afterward c) borrowed mutably → `q2=b`
- q3 (value): error code from the uncommented line → `q3=E0382`

**CHECK LOGIC:** `assert_file_contains answers.txt` with `'^q1=b$'`, `'^q2=b$'`,
`'^q3=E0382$'` (hints point at steps 2 and 4);
`assert_output_contains 'sample runs (re-commented after step 4)' 'PORT SCAN
DETECTED' 'step 5 — put the // back and recompile: rustc sample.rs -o sample' --
./sample`; `assert_output_contains '18 bytes line' '18 bytes' 'step 3 — rustc
sample.rs -o sample' -- ./sample`; `ck_summary`.

**QUIZ:**
1. choice — "A parameter typed `&str` tells the caller…" a) the function frees it
   b) the function borrows; you keep ownership c) it must be static → **b**
2. choice — "A parameter typed `String` (no &)…" a) borrows b) copies cheaply
   c) takes ownership — the argument is moved → **c**
3. text — "Change consume's parameter type so callers keep ownership:
   `message:` ___?" → **&str** (accept: `&string`)

**RECAP:**
```
read the signature: &str borrows (caller keeps it), String moves (caller loses it)
a move is not a copy — the old name is dead, and the compiler enforces the funeral
E0382 = used after move; the fix is usually a borrow, not a clone
```

**HINTS:** L1: three answer keys plus a working ./sample — the grader names which
is missing; q1/q2 options are in step 2. L2: compare the two signatures — one takes
`&str`, one takes `String`; that single `&` is the entire answer to q1/q2; q3 comes
from actually compiling the uncommented line. L3: uncomment the marked line, run
`rustc sample.rs`, read the `error[E....]` tag, write it as q3, put the `//` back,
recompile with `-o sample`.

---

### L1.5 — Structs — data without constructor magic
**DECODE · gate:false · est 15 · files/: sample.rs**
**objective:** "Read struct literals, field-init shorthand, and update syntax, and explain which fields ..a actually moves."

**files/sample.rs:**
```rust
#[derive(Debug)]
struct Endpoint {
    host: String,
    port: u16,
    tls: bool,
}

fn make_local(port: u16) -> Endpoint {
    Endpoint {
        host: String::from("127.0.0.1"),
        port,
        tls: false,
    }
}

fn main() {
    let a = make_local(8080);
    println!("a = {a:?}");

    let b = Endpoint {
        host: String::from("10.0.0.5"),
        ..a
    };
    println!("b = {b:?}");
    println!("a.host = {}", a.host);
}
```
Expected output:
```
a = Endpoint { host: "127.0.0.1", port: 8080, tls: false }
b = Endpoint { host: "10.0.0.5", port: 8080, tls: false }
a.host = 127.0.0.1
```
Teaching beats: a struct literal IS the constructor (no magic, no partial init
possible); `port,` = field-init shorthand; `..a` fills the *remaining* fields —
here port+tls (both Copy); because `host` was overridden, nothing non-Copy moved
out of `a`, so `a` stays fully usable. Optional exploration step: delete the
override and watch `a.host` die (E0382) — not graded.

**GUIDED STEPS outline:** read → compile/run → answers.txt (options in lab.md):
- q1 (choice): `port,` inside the literal means… a) default value b) field-init
  shorthand for `port: port` c) a tuple field → `q1=b`
- q2 (value): which fields did `..a` supply, comma-separated, declaration order,
  no spaces → `q2=port,tls`
- q3 (choice): why is `a.host` still printable at the end? a) String is Copy
  b) `..a` clones c) host was overridden in b, so it was never moved out of a → `q3=c`
→ check.

**CHECK LOGIC:** `assert_file_contains answers.txt` with `'^q1=b$'`,
`'^q2=port,tls$'`, `'^q3=c$'` (hints point at step 3's option lists);
`assert_output_contains 'sample runs' 'port: 8080' 'step 2 — rustc sample.rs -o
sample' -- ./sample`; `assert_output_contains 'a still owns its host'
'a\.host = 127\.0\.0\.1' 'step 2 — rustc sample.rs -o sample' -- ./sample`;
`ck_summary`.

**QUIZ:**
1. text — "Attribute that makes {:?} printing work on your struct?" →
  **#[derive(debug)]** (accept: `derive(debug)`, `debug`)
2. choice — "Rust constructors are…" a) special `constructor` methods b) any plain
   function returning the type — `new` is only a convention c) compiler-generated → **b**
3. choice — "Can a struct literal leave a field uninitialized?" a) yes, defaults to
   zero b) yes, with unsafe c) no — every field, every time, or it doesn't compile → **c**

**RECAP:**
```
struct literals are the constructor — every field named, nothing uninitialized
port, is shorthand for port: port; fn make_x(...) -> X is the whole "new" story
..a fills only the fields you didn't write — moves non-Copy ones unless overridden
```

**HINTS:** L1: three keys in answers.txt; q2 wants field *names* from the struct
declaration. L2: `..a` fills exactly the fields NOT already written in b's literal —
list those two, declaration order, `q2=name,name`; for q3, ask which field of `a`
is non-Copy and whether b took it. L3: the two fields b didn't override are port
and… reread the Endpoint declaration; then try the ungraded experiment (delete the
host override) to see q3's answer prove itself.

---

### L1.6 — Enums are not C enums — variants that carry data
**DECODE · gate:false · est 15 · files/: sample.rs**
**objective:** "Read an enum whose variants carry payloads and the match arms that destructure them — the tagged union C never gave you."

**files/sample.rs:**
```rust
enum Event {
    Login { user: String, success: bool },
    PortScan { first: u16, last: u16 },
    Heartbeat,
}

fn describe(event: &Event) -> String {
    match event {
        Event::Login { user, success: true } => format!("login ok: {user}"),
        Event::Login { user, success: false } => format!("login FAIL: {user}"),
        Event::PortScan { first, last } => format!("scan {first}-{last}"),
        Event::Heartbeat => String::from("heartbeat"),
    }
}

fn main() {
    let feed = [
        Event::Login { user: String::from("root"), success: false },
        Event::PortScan { first: 1, last: 1024 },
        Event::Heartbeat,
    ];
    for event in &feed {
        println!("{}", describe(event));
    }
}
```
Expected output: `login FAIL: root` / `scan 1-1024` / `heartbeat`.
Teaching beats: a C enum is a named integer; a Rust enum is a tagged union — each
variant carries its own fields; match arms *destructure* payloads and can match on
payload values (`success: true` vs `success: false`); `&feed` iteration lends
`&Event` which is all `describe` needs.

**GUIDED STEPS outline:** read → compile/run → answers.txt (options in lab.md):
- q1 (choice): vs a C enum, a Rust enum… a) is identical, just namespaced b) each
  variant can carry its own typed data — a tagged union c) is a bitflag set → `q1=b`
- q2 (choice): the arm `Event::Login { user, success: true }` matches… a) every
  Login b) only Logins where success is true, binding user c) any variant with a
  user field → `q2=b`
- q3 (value): exact line printed for the PortScan event → `q3=scan 1-1024`
→ check.

**CHECK LOGIC:** `assert_file_contains answers.txt` with `'^q1=b$'`, `'^q2=b$'`,
`'^q3=scan 1-1024$'` (hints point at step 3's option lists / the PortScan arm);
`assert_output_contains 'sample runs' 'login FAIL: root' 'step 2 — rustc sample.rs
-o sample' -- ./sample`; `ck_summary`.

**QUIZ:**
1. choice — "Where does a Rust enum's payload live?" a) separate heap table b) in
   the enum value itself — tag + the matched variant's fields c) global statics → **b**
2. choice — "`match event { Event::Heartbeat => ... }` alone fails to compile
   because…" a) Heartbeat has no data b) match must cover every variant c) match
   needs a default arm first → **b**
3. text — "In `describe`, what type is the `event` parameter, exactly as written?"
   → **&event** (accept: `&Event`)

**RECAP:**
```
Rust enums are tagged unions: every variant carries its own typed payload
match destructures the payload and can condition on it (success: true vs false)
one Event type replaces the C struct-plus-type-int pattern — invalid states unrepresentable
```

**HINTS:** L1: three answer keys; q3 wants the exact printed line for the middle
event — trace only that arm. L2: for q3, substitute first=1, last=1024 into the
PortScan arm's format string, exactly as printed (dash, no spaces around it). L3:
compile and run: `rustc sample.rs -o sample; ./sample` — the middle output line is
q3 verbatim.

---

### L1.7 — `match` — exhaustiveness as a security feature
**FIX · gate:false · est 15 · files/: broken.rs**
**objective:** "Read E0004, apply the minimal fix — the missing arm, never the wildcard — and say why `_` is the insecure fix."

**files/broken.rs:**
```rust
enum Severity {
    Low,
    Medium,
    High,
    Critical,
}

fn action(level: Severity) -> &'static str {
    match level {
        Severity::Low => "log only",
        Severity::Medium => "open ticket",
        Severity::High => "page on-call",
    }
}

fn main() {
    let alerts = [
        Severity::Low,
        Severity::Medium,
        Severity::High,
        Severity::Critical,
    ];
    for level in alerts {
        println!("{}", action(level));
    }
}
```
Must produce **E0004** — "non-exhaustive patterns: `Severity::Critical` not
covered" `[VERIFY-AT-BUILD: message + that by-value `for level in alerts` compiles
on plain rustc once fixed]`. (main constructs all four variants deliberately so the
fixed program emits no dead-code warnings.)

**THE FIX (lab.md states it as the requirement):** copy to `fixed.rs`; add exactly
one arm `Severity::Critical => "isolate host",` — lab.md explicitly forbids
`_ => ...` and explains why: a wildcard silently absorbs every *future* variant;
exhaustiveness is the compiler forcing a triage-policy decision each time the enum
grows. That is the security feature.

Fixed program output: `log only` / `open ticket` / `page on-call` / `isolate host`.

**GUIDED STEPS outline:** `rustc broken.rs` → read the error, record
`error_code=E0004` in answers.txt → `cp broken.rs fixed.rs`, add the arm →
`rustc fixed.rs -o fixed && ./fixed` → check.

**CHECK LOGIC:** `assert_file_contains answers.txt '^error_code=E0004$'`;
`assert_file_exists fixed.rs`;
`assert_file_contains fixed.rs 'Severity::Critical[[:space:]]*=>'`;
`assert_file_not_contains fixed.rs '_[[:space:]]*=>'` (hint: the wildcard is the
forbidden fix — name the variant);
`assert_output_contains 'fixed binary handles Critical' 'isolate host' 'step 3 —
rustc fixed.rs -o fixed' -- ./fixed`; `ck_summary`.

**QUIZ:**
1. text — "E0004's message names the uncovered pattern — which variant was it?" →
   **critical** (accept: `severity::critical`)
2. choice — "Why is `_ =>` the wrong fix here?" a) it's slower b) new variants
   added later compile silently into the wildcard — no forced review c) it can't
   return a value → **b**
3. choice — "Exhaustiveness checking means…" a) the compiler proves every variant
   has an arm, at compile time b) unmatched values panic at runtime c) arms are
   checked in order → **a**

**RECAP:**
```
match must prove coverage of every variant at compile time — E0004 when it can't
minimal fix = name the missing variant; _ => swallows future variants unreviewed
an enum + exhaustive match turns "forgot a case" from a runtime bug into a build break
```

**HINTS:** L1: the grader wants answers.txt, fixed.rs, and a runnable ./fixed —
one of them is missing or the fix used a pattern the lab forbids. L2: the error's
own text names the uncovered variant; add an arm for exactly that variant returning
exactly "isolate host" (the check greps that string); no underscore arm anywhere.
L3: in fixed.rs add `Severity::Critical => "isolate host",` after the High arm,
then `rustc fixed.rs -o fixed; ./fixed` and re-check.

---

### L1.8 — No null — first contact with `Option<T>`
**PREDICT · gate:false · est 15 · files/: sample.rs, broken.rs**
**objective:** "Predict Some/None flows through unwrap_or and if let, and read E0308 when Option<u16> pretends to be u16."

**files/sample.rs:**
```rust
fn find_port(service: &str) -> Option<u16> {
    match service {
        "ssh" => Some(22),
        "https" => Some(443),
        "dns" => Some(53),
        _ => None,
    }
}

fn main() {
    println!("{:?}", find_port("ssh"));
    println!("{:?}", find_port("gopher"));

    let fallback = find_port("telnet").unwrap_or(0);
    println!("fallback = {fallback}");

    if let Some(port) = find_port("dns") {
        println!("dns runs on {port}");
    }
}
```
Expected: `Some(22)` / `None` / `fallback = 0` / `dns runs on 53`.
Teaching beats: absence is a *value* (`None`), not a null pointer; the type system
quarantines it — you must go through unwrap_or / if let / match to touch the inner
value. (`_ =>` in find_port is correct here, unlike L1.7: for a lookup over
unbounded strings the wildcard IS the policy — lab.md draws that contrast in one
line.)

**files/broken.rs:**
```rust
fn find_port(service: &str) -> Option<u16> {
    match service {
        "ssh" => Some(22),
        _ => None,
    }
}

fn main() {
    let port: u16 = find_port("ssh");
    println!("port = {port}");
}
```
Must produce **E0308** — mismatched types: expected `u16`, found `Option<u16>`
`[VERIFY-AT-BUILD]`.

**GUIDED STEPS outline:** read → predictions.txt: `p1=Some(22)`, `p2=None`,
`p3=0` (the fallback number), `p4=53` (the if-let number) → compile/run sample →
`rustc broken.rs`, record `error=E0308` → check.

**CHECK LOGIC:** `assert_file_contains_fixed predictions.txt 'p1=Some(22)'`;
`assert_file_contains predictions.txt '^p2=None$'`, `'^p3=0$'`, `'^p4=53$'`,
`'^error=E0308$'`; `assert_output_contains 'sample runs' 'dns runs on 53' 'step 3
— rustc sample.rs -o sample' -- ./sample`; `ck_summary`.

**QUIZ:**
1. choice — "Option<T> replaces which C/C++ habit?" a) exceptions b) NULL pointers
   and sentinel values c) goto error handling → **b**
2. text — "Method: give me the Some value, or this default." → **unwrap_or**
3. choice — "Why won't `let p: u16 = find_port(\"ssh\")` compile even though ssh IS
   in the table?" a) type mismatch is decided at compile time — the None case exists
   in the type regardless of runtime data b) find_port is private c) u16 is too
   small → **a**

**RECAP:**
```
no null: absence is Some/None data, and the type system quarantines it
unwrap_or / if let / match are the doors out of Option — each names its None policy
Option<u16> is not u16 (E0308): the compiler bills you for the None case up front
```

**HINTS:** L1: five prediction keys; the grader names the wrong one — re-trace only
that call through find_port. L2: p1/p2 print with `{:?}` so write them exactly as
Debug prints an Option (Some(...) / None); p3 asks what unwrap_or(0) yields for a
service NOT in the table; p4 is just the number in the if-let line. L3: run it and
transcribe: `rustc sample.rs -o sample; ./sample; rustc broken.rs`.

---

### L1.9 — Phase gate: read a 60-line program cold, answer 10 questions
**AUDIT · gate:TRUE · est 20 · files/: triage.rs**
**objective:** "Prove Phase 1: read a 60-line triage tool cold and answer 10 questions about its behavior, its types, and its one planted flaw."

**files/triage.rs (the complete artifact — build verbatim):**
```rust
// triage.rs — Phase 1 gate. Read it cold. Answer the 10 questions in
// answers.txt BEFORE you compile it. Then run it to self-check.

#[derive(Debug)]
enum Verdict {
    Benign,
    Suspicious,
    Hostile,
}

struct Source {
    name: String,
    failures: u8,
    internal: bool,
}

fn service_port(service: &str) -> Option<u16> {
    match service {
        "ssh" => Some(22),
        "rdp" => Some(3389),
        _ => None,
    }
}

fn judge(source: &Source) -> Verdict {
    let score = {
        let base = if source.internal { 0 } else { 2 };
        base + source.failures / 3
    };
    if score == 0 {
        Verdict::Benign
    } else if score < 4 {
        Verdict::Suspicious
    } else {
        Verdict::Hostile
    }
}

fn main() {
    let sources = [
        Source { name: String::from("build-server"), failures: 2, internal: true },
        Source { name: String::from("laptop-7"), failures: 9, internal: true },
        Source { name: String::from("203.0.113.9"), failures: 7, internal: false },
    ];

    let mut hostile_count = 0;
    let mut total: u8 = 0;
    for source in &sources {
        let verdict = judge(source);
        println!("{} -> {:?}", source.name, verdict);
        if let Verdict::Hostile = verdict {
            hostile_count += 1;
        }
        total += source.failures;
    }
    println!("hostile: {hostile_count}");
    println!("total failures: {total}");

    let target = service_port("rdp").unwrap_or(0);
    println!("watch port {target}");
}
```
Expected full output `[VERIFY-AT-BUILD: run it]`:
```
build-server -> Benign
laptop-7 -> Suspicious
203.0.113.9 -> Hostile
hostile: 1
total failures: 18
watch port 3389
```
Worked verdicts (for the answer key): build-server: base 0 + 2/3=0 → score 0 →
Benign. laptop-7: base 0 + 9/3=3 → score 3 → Suspicious (< 4). 203.0.113.9: base 2
+ 7/3=2 → score 4 → not < 4 → Hostile. Planted flaw: `total: u8` accumulates
attacker-influenced failure counts — >255 total panics in debug (DoS), wraps in
release (corrupt metric): CWE-190, straight from L1.2.

**The 10 questions** (lab.md lists them with the choice options; learner writes
`q1=`..`q10=` in answers.txt before compiling — honor contract restated):
1. Verdict printed for build-server → `q1=Benign`
2. Verdict printed for laptop-7 → `q2=Suspicious`
3. Verdict printed for 203.0.113.9 → `q3=Hostile`
4. Number after `hostile:` → `q4=1`
5. Number after `total failures:` → `q5=18`
6. Number after `watch port` → `q6=3389`
7. score for internal=false, failures=5 (integer division!) → `q7=3`
8. choice: why does `judge(source)` leave `sources` usable? a) Source is Copy
   b) judge takes &Source — a borrow c) judge clones → `q8=b`
9. choice: `service_port("http")` returns? a) 0 b) None c) panics → `q9=b`
10. choice: the reviewer flag in this code? a) hostile_count could go negative
    b) `total: u8` can overflow — panic in debug, wrap in release (CWE-190)
    c) String::from allocates too much → `q10=b`

**GUIDED STEPS outline:** read cold (lab.md: do NOT compile yet) → write all 10
answers → now compile/run to self-check q1–q6 → revise nothing you got wrong
without understanding why (the point is the diff between your head and the machine)
→ check. Learners keep the compiled `./triage` binary; check runs it.

**CHECK LOGIC:** ten anchored greps on answers.txt (`'^q1=Benign$'`,
`'^q2=Suspicious$'`, `'^q3=Hostile$'`, `'^q4=1$'`, `'^q5=18$'`, `'^q6=3389$'`,
`'^q7=3$'`, `'^q8=b$'`, `'^q9=b$'`, `'^q10=b$'`);
`assert_output_contains 'triage binary runs' 'watch port 3389' 'compile it:
rustc triage.rs -o triage' -- ./triage`; `ck_summary`.

**QUIZ (concept-level, not duplicating the 10):**
1. choice — "Which Phase-1 guarantee did `judge`'s match-free if/else chain NOT
   give you, that an exhaustive match over an enum would?" a) speed b) a compile
   error when a new Verdict variant appears c) shorter code → **b**
2. choice — "`total += source.failures` on a u8 — in a release build an attacker
   driving failures high causes…" a) a panic b) silent wraparound c) a compile
   error → **b**
3. text — "The function signature marker meaning 'this call cannot cost you
   ownership'." → **&** (accept: `borrow`, `reference`, `&source`)

**RECAP:**
```
you just read 60 lines of Rust cold — structs, enums, borrows, Option, expressions
integer division and small-int accumulators are where triage math quietly lies
gate passed: Phase 2 makes the borrow checker itself the subject
```

**HINTS:** L1: ten keys q1..q10 — the grader names the misses; re-trace only those
through the program on paper. L2: q1–q3 hang on `judge`: compute base (internal?),
add failures/3 with *integer* division, then walk the if/else thresholds; q5 is a
plain sum; q7 is the same arithmetic with the given inputs. L3: compile and run
(`rustc triage.rs -o triage; ./triage`) to check q1–q6 mechanically; for q7 apply
judge by hand: 2 + 5/3 = 2 + 1.

---

## 5. Build-session protocol (execute in this order)

1. Scaffold all 12 lab directories under `tracks/rust/phases/p0/` and `p1/` per §1
   slugs; `tracks/rust/track.json` already exists — do not touch it.
2. Author content straight from §4. Base64 every quiz/recall answer with
   `printf '%s' 'answer' | base64 -w0`; text answers lowercase-normalized, with
   `accept_b64` variants listed here.
3. **[VERIFY-AT-BUILD] sweep (requires the real toolchain, cargo IS allowed in the
   build session — just never inside check.sh):** compile and run every sample.rs /
   project with plain `rustc` (edition-2015 default) and cargo where specified;
   confirm every predicted output string byte-for-byte; confirm every error code
   (E0384, E0308 ×2, E0382, E0004) and the quoted message lines; confirm the L1.2
   runtime-panic-not-compile-error property; confirm `cargo doc --no-deps` output
   path; confirm `for level in alerts` (by-value array iteration) on plain rustc.
   (`.gitignore` coverage of `/workspace/` already verified at plan time.) Fix
   content to reality and log deviations.
4. Lint gates: `./tools/lint-labs.sh` (includes shellcheck sweep) must pass clean.
5. Acceptance: extend `tests/acceptance.sh` per its existing demo pattern — for
   each lab: fabricate passing artifacts WITHOUT a Rust toolchain (echo answer
   files/outputs; `#!/bin/sh` stub binaries, chmod +x), run
   `printf '<a>\n<b>\n<c>\n' | lab check rust <id>` expecting pass; plus one
   negative case per lab (delete one artifact → graded fail, exit 1). For L1.1,
   drive `lab start rust L1.1` with 5 piped recall answers and assert it never
   gates. Verify quiz stdin protocol end-to-end.
6. Run the full track manually once with the real toolchain (the author's own
   `lab check` pass per lab) before tagging `rust-p0` / `rust-p1` per PROMPTS.md.
7. Update `planned_execution.md` (mark rust p0/p1 done with evidence) — build
   session's job, not this plan's.

## 6. Decisions & deviations log (for the reviewer)

- **No recall.json on L0.1** — no earlier phase exists in-track; kit treats the
  file as optional (position-only lint). Demo L0.0's recall was bootstrap-specific.
- **gate:true on L0.3** — the map's Phase-0 exit-gate sentence is L0.3's exact
  content; demo precedent marks phase-final labs as gates.
- **check.sh never touches cargo** — env -i fence hides ~/.cargo/bin by design;
  all grading is artifact-based and CI-fabricatable (§2.1–2.2).
- **L1.2 is the only cargo-project lab in Phase 1** — profiles are its concept;
  everything else is single-file rustc to honor one-concept-per-lab.
- **10-question gate rides answers.txt, not quiz.json** — the kit hard-caps
  quiz.json at 3; the gate's breadth lives in the graded answer file, and quiz.json
  carries 3 concept-level questions on top.
- **Overflow demo crosses a function boundary** (`bump`) so the deny-by-default
  `arithmetic_overflow` lint can't turn the teaching moment into a compile error.
- **Plan-time verification coverage (honest report):** a 27-agent adversarial
  verification fleet was run over this plan. The two L1.3 verifiers completed and
  caught one real defect — the original broken.rs carried a `: i32` annotation,
  which changes the E0308 diagnostic flavor from "`if` and `else` have incompatible
  types" to plain "mismatched types" blaming the annotation; fixed by dropping the
  annotation (design note added at L1.3). They also flagged quiz questions that
  duplicated graded answer-file items in L1.1/L1.3/L1.4/L1.7 (all replaced with
  different-angle questions). The remaining 25 agents were cut off by a session
  usage limit, so every other lab has author self-review only — all expected
  outputs re-derived by hand, all error codes (E0384, E0308 ×2, E0382, E0004)
  high-confidence. The build session's §5 step-3 toolchain sweep is the
  authoritative verification for every [VERIFY-AT-BUILD] tag regardless.
