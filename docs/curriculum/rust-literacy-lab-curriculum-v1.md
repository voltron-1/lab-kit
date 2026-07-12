# RUST LITERACY LAB — Curriculum Map v1.0

**Read. Audit. Direct.**
A terminal-based Rust comprehension course for security work.

---

## 1. The Premise

You are not training to be a Rust developer. You are training to be a **Rust reader and auditor** who directs AI code generation. That means the course optimizes for four skills, in this order:

1. **Fluent reading** — look at any Rust file and know what it does
2. **Compiler-error literacy** — read a borrow-checker error and explain *why* Rust rejected the code
3. **Security auditing** — spot panic paths, unsafe blocks, bad input handling, and supply-chain risk
4. **AI direction** — write specs that produce safe Rust, and review the output like a lead architect

You will type code in labs — but only enough to make concepts stick. You will never be asked to write a program from scratch. Every lab is built around code that already exists: predict it, decode it, fix it, or audit it.

---

## 2. How It Works (RedHat Academy Mechanics)

The course ships as a repo you clone into WSL2 on Dragon-Zord. Everything happens in the terminal.

### The `lab` CLI

| Command | What it does |
|---|---|
| `lab status` | Phase map with ✓ marks — your progress bar |
| `lab start L2.3` | Opens the lab: prints the brief, sets up files |
| `lab check L2.3` | Grades the lab (runs checks + quiz). Pass = unlocked next lab |
| `lab resume` | **Interruption recovery.** Tells you exactly where you stopped, replays the last recap, re-primes context in under 30 seconds |
| `lab hint L2.3` | Graduated hints (3 levels, never the full answer first) |

### Anatomy of Every Lab

1. **OBJECTIVE** — one sentence. What you can do after this lab.
2. **BRIEF** — ≤10 lines of context. No external reading, ever.
3. **GUIDED STEPS** — terminal follow-along with expected output shown, exactly like a RedHat guided exercise.
4. **KNOWLEDGE CHECK** — 3 active-recall questions, graded by `lab check`.
5. **RECAP CARD** — 3-line summary written to your progress log (this is what `lab resume` replays).

Progress lives in a local `.progress.json`. Nothing is lost mid-session. Ever.

---

## 3. Lab Types (the Reading-First Twist)

| Type | What you do | Skill trained |
|---|---|---|
| **PREDICT** | Read code, predict output or compile-fail *before* running | Reading fluency |
| **DECODE** | Working code + "why does this work?" questions | Comprehension |
| **FIX** | Read a real compiler error, identify the cause, apply the minimal fix | Error literacy |
| **AUDIT** | Find the flaw — panic path, unsafe risk, logic bug — in provided code | Security review |
| **TOUR** | Guided walkthrough of a real open-source tool's source | Codebase navigation |
| **DIRECT** | Write a spec/prompt for AI, then grade the output against a checklist | Your actual workflow |
| **GUIDED** | Straight follow-along (setup, tooling) | Environment ops |

---

## 4. ADHD Design Contract

These are commitments, not suggestions. Every lab honors them.

- **Atomic:** every lab completes in 10–20 minutes. "Varies wildly" sessions are the design target — do one lab or do six, the course doesn't care.
- **One concept per lab.** Never two.
- **Hard checkpoint every lab.** `lab check` passing = a real, saved win. No partial-credit limbo.
- **Re-entry in 30 seconds.** `lab resume` reorients you after a day or a month away.
- **Hint ladder, not stuck-spirals.** Three graduated hints before frustration sets in.
- **Zero prerequisite reading.** Everything you need is inside the lab brief.
- **Spaced recall.** The first lab of every phase opens with a 5-question quiz pulling from *earlier* phases (interleaved, not just the last one).

---

## 5. Phase Map (Overview)

| Phase | Name | Labs | After this phase you can… |
|---|---|---|---|
| **0** | Toolchain & Kit | 3 | Run cargo, navigate any Rust repo cold |
| **1** | Reading Basic Rust | 9 | Read straightforward Rust; explain enums/match |
| **2** | Ownership, Borrowing, Lifetimes | 10 | Explain any borrow-check error; name the C++ bugs that die here |
| **3** | Types, Traits, Error Handling | 10 | Read real API signatures; spot panic paths on sight |
| **4** | Security-Critical Rust | 10 | Audit unsafe blocks; review untrusted-input handling; run supply-chain checks |
| **5** | Concurrency & Async | 8 | Read tokio-based tools; explain Arc/Mutex patterns |
| **6** | Reading Real Security Tools | 6 | Tour RustScan and Vector source; trace data end-to-end |
| **7** | Directing & Auditing AI Rust | 7 | Spec, review, and CI-gate AI-generated Rust. Capstone. |

**63 labs total.** No schedule, no deadlines — just a chain of checkpoints. At one lab a day you're done in two months; at "varies wildly" pace, the progress bar waits for you.

---

## 6. Phase Detail

### Phase 0 — Toolchain & Kit
*Get the environment and the lab system working. Pure plumbing.*

| Lab | Title | Type |
|---|---|---|
| L0.1 | Toolchain up — rustup, cargo, first build on WSL2 | GUIDED |
| L0.2 | Meet the lab kit — CLI, checks, resume | GUIDED |
| L0.3 | Anatomy of a Rust repo — Cargo.toml, src/, cargo doc, docs.rs | DECODE |

**Exit gate:** you can clone a random crate and answer "what does this project do and where's the entry point?"

---

### Phase 1 — Reading Basic Rust (the C++ bridge)
*Syntax and core constructs, framed against the C++ you vaguely remember. Rust's defaults are the opposite of C++'s: immutable by default, no null, no uninitialized memory, no silent conversions.*

| Lab | Title | Type |
|---|---|---|
| L1.1 | `let`, `mut`, shadowing — immutable by default | PREDICT |
| L1.2 | Integers without footguns — overflow in debug vs release | PREDICT |
| L1.3 | Expressions everywhere — blocks and `if` return values | PREDICT |
| L1.4 | Functions and the ownership preview | DECODE |
| L1.5 | Structs — data without constructor magic | DECODE |
| L1.6 | Enums are not C enums — variants that carry data | DECODE |
| L1.7 | `match` — exhaustiveness as a security feature | FIX |
| L1.8 | No null — first contact with `Option<T>` | PREDICT |
| L1.9 | **Phase gate:** read a 60-line program cold, answer 10 questions | AUDIT |

**Security hook:** L1.2 maps directly to integer-overflow bug classes (CWE-190) — you'll see the exact behavior difference between debug and release builds.

---

### Phase 2 — Ownership, Borrowing, Lifetimes
*This IS Rust. The borrow checker is the machinery that eliminates use-after-free, double-free, dangling pointers, and data races at compile time. If you can read borrow-checker errors, you can read Rust.*

| Lab | Title | Type |
|---|---|---|
| L2.1 | Move semantics — why the compiler "took" your variable | PREDICT |
| L2.2 | `Copy` vs `Clone` | PREDICT |
| L2.3 | Shared borrows — `&` | PREDICT |
| L2.4 | `&mut` and the aliasing-XOR-mutation law | FIX |
| L2.5 | Borrow-error triage I — E0382, E0499, E0502 | FIX |
| L2.6 | `String` vs `&str`, and slices | DECODE |
| L2.7 | Lifetimes — reading `'a` without fear | DECODE |
| L2.8 | The C++ crime scene — use-after-free side-by-side | AUDIT |
| L2.9 | Borrow-error triage II — lifetimes in errors | FIX |
| L2.10 | **Phase gate:** explain 5 rejected programs | FIX |

**Security hook:** L2.8 shows a real use-after-free pattern (CWE-416) in C++, then the equivalent Rust that refuses to compile — and you explain exactly which rule blocked it.

---

### Phase 3 — Types, Traits, Error Handling
*The reading skills for real-world APIs. This is where AI-generated code becomes legible: iterator chains, `?` operators, trait bounds in signatures.*

| Lab | Title | Type |
|---|---|---|
| L3.1 | `Result` and the `?` operator | DECODE |
| L3.2 | `unwrap` / `expect` / `panic!` — red flags in review | AUDIT |
| L3.3 | Reading trait bounds and generics in signatures | DECODE |
| L3.4 | `impl` blocks and method syntax | DECODE |
| L3.5 | Iterators — reading the chains AI loves to generate | PREDICT |
| L3.6 | Closures | PREDICT |
| L3.7 | `Vec` and `HashMap` patterns | DECODE |
| L3.8 | `From` / `Into` / `TryFrom` — conversion literacy | DECODE |
| L3.9 | Error taxonomy in real crates — thiserror/anyhow at reading level | DECODE |
| L3.10 | **Phase gate:** read a real crate's public API and answer questions | DECODE |

**Security hook:** L3.2 builds your first review reflex — `unwrap()` on untrusted input is a denial-of-service waiting to happen.

---

### Phase 4 — Security-Critical Rust
*The phase that makes you dangerous as a reviewer. Where Rust's guarantees end, what `unsafe` actually permits, and the honest truth: memory safety is not the same as security.*

| Lab | Title | Type |
|---|---|---|
| L4.1 | What `unsafe` actually unlocks — the five superpowers | DECODE |
| L4.2 | Auditing an unsafe block — the checklist | AUDIT |
| L4.3 | FFI — where the guarantees end | DECODE |
| L4.4 | `as` casts vs `TryFrom` — truncation bugs | AUDIT |
| L4.5 | Panics as DoS — untrusted input meets `unwrap` | AUDIT |
| L4.6 | Parsing untrusted bytes — reading a nom-style parser | DECODE |
| L4.7 | What Rust does NOT stop — path traversal, injection, logic bugs | AUDIT |
| L4.8 | Supply chain — cargo audit, cargo deny, RUSTSEC advisories | GUIDED |
| L4.9 | Clippy as a code reviewer | GUIDED |
| L4.10 | **Phase gate:** full audit of a 150-line intentionally flawed tool | AUDIT |

**Security hook:** the whole phase. L4.7 matters most — Rust kills memory corruption, not bad logic. A memory-safe path-traversal bug is still a breach.

---

### Phase 5 — Concurrency & Async
*Modern security tooling is async. You need to read a tokio main loop, not write one.*

| Lab | Title | Type |
|---|---|---|
| L5.1 | Threads — why data races don't compile | PREDICT |
| L5.2 | `Send` / `Sync`, conceptually | DECODE |
| L5.3 | `Arc` / `Mutex` reading patterns | DECODE |
| L5.4 | Channels | PREDICT |
| L5.5 | async/await — the mental model | DECODE |
| L5.6 | Reading a tokio main loop | DECODE |
| L5.7 | Timeouts, cancellation, resource exhaustion | AUDIT |
| L5.8 | **Phase gate:** trace a concurrent port scanner's data flow | DECODE |

**Security hook:** data races are a real vulnerability class (CWE-362); Rust makes them a compile error. L5.7 covers the async DoS patterns that remain.

---

### Phase 6 — Reading Real Security Tools
*Capstone reading tours of production open-source. No toy code — real repos, guided navigation, comprehension questions.*

| Lab | Title | Type |
|---|---|---|
| L6.1 | Tour: RustScan I — CLI args to scan loop | TOUR |
| L6.2 | Tour: RustScan II — results and output | TOUR |
| L6.3 | Tour: Vector I — source → transform → sink (Logstash territory you already know) | TOUR |
| L6.4 | Tour: Vector II — inside a codec/parser path | TOUR |
| L6.5 | Tour: a nom-based protocol parser | TOUR |
| L6.6 | **Phase gate:** solo tour of an unseen repo, answer questions cold | TOUR |

---

### Phase 7 — Directing & Auditing AI-Generated Rust
*Your actual workflow, formalized. Expert level here means: your specs produce safe code, and nothing gets past your review.*

| Lab | Title | Type |
|---|---|---|
| L7.1 | Spec-writing for safe Rust — constraints that actually matter | DIRECT |
| L7.2 | The AI-Rust review checklist v1 | AUDIT |
| L7.3 | Review reps — 3 AI-generated snippets, find every flaw | AUDIT |
| L7.4 | CI guardrails — clippy pedantic + audit + deny + tests as spec | GUIDED |
| L7.5 | Capstone spec — an IOC/log parser emitting ECS-formatted JSON | DIRECT |
| L7.6 | Capstone build — direct the AI, review each iteration | DIRECT |
| L7.7 | **Capstone gate:** final audit and ship | AUDIT |

**Why this capstone:** a log parser that emits ECS JSON is directly usable in your SOC pipeline work — the course ends with a real artifact, not a certificate.

---

## 7. Delivery Plan

Built **one phase at a time**, exactly as requested. Each delivery is interruption-safe:

1. **You approve this map** (edits welcome — labs can be added, cut, or reordered).
2. **First build ships Phase 0 + Phase 1 together** — Phase 0 is 3 plumbing labs and Phase 1 is unusable without it. Delivered as a zip: working `lab` CLI, all check scripts, all lab content. You unzip into WSL2 and run `lab status`.
3. **Each later phase ships as a drop-in folder** + one command to register it. Your progress file is never touched.
4. Between phases, anything can be adjusted based on what worked and what didn't.

---

## 8. Open Items for Your Review

- **Name:** `rust-literacy-lab` is a working title. Rename freely (your call — CARDINAL-adjacent naming welcome).
- **Tour targets (Phase 6):** RustScan + Vector + a nom parser is the current pick. Swappable.
- **Capstone (L7.5–7.7):** ECS log parser is the current pick. Alternatives: IOC extractor, PCAP summarizer, Sigma-rule linter.

---

*v1.0 — awaiting approval before Phase 0+1 build.*
