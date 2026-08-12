# rust track — quiz.json / recall.json exposure audit

rust track: 63 labs checked, 0 labs with ≥1 BLOCKING quiz issue, 0 labs with ≥1 MINOR quiz issue, 0 labs with ≥1 recall GAP.

No lab in the rust track reproduces the soc `L0.1` calibration bug (a quiz fact that exists
only in `recap.md` and nowhere reachable before the gate). Every quiz question in all 63
labs is grounded in that lab's own `lab.md` (BRIEF or the "record predictions/answers"
walkthrough, which spells out the correct value **and** a one-line rationale for nearly
every graded fact), a `files/` fixture the guided steps explicitly direct the learner to
read, or direct output of a guided-step `rustc`/`cargo` command. No `hints.json` in the
track introduces a fact that isn't already present in `lab.md` (hints only restate/repeat,
never add new graded-quiz content), so there were no MINOR candidates either.

| lab id | file | question # | severity | issue | suggested fix |
|---|---|---|---|---|---|
| — | — | — | — | (no findings — table intentionally empty, see notes below) | — |

## Methodology notes (read before trusting the zero counts)

**Scope of "reachable material" for quiz.json.** The task brief scopes quiz grounding
strictly to *this lab's own* `lab.md`/`hints.json`/`files/`/guided-step output. Six labs in
this track are **phase gates** whose explicit objective is to test synthesis of the whole
phase (e.g. L1.9's objective literally says "combines all Phase 1 concepts"). A handful of
gate-lab quiz questions use terminology coined in an earlier lab in the *same phase* rather
than re-defining it in the gate's own `lab.md`:

| lab | question | term/fact relies on | earlier source (same track, same or earlier phase) |
|---|---|---|---|
| L1.9 | Q1 | "if/else lacks match's compile-time exhaustiveness guarantee" | L1.7 (match exhaustiveness) |
| L2.10 | Q2 | "CWE-416/415 family" naming for UAF/double-free/stale-alias | L2.8 (C++ crime scene, CWE-416) |
| L2.10 | Q3 | "Aliasing XOR Mutation law" exact phrase | L2.4 (title is literally this law) |
| L4.10 | Q3 | "memory safety is not security" thesis phrase | L4.7 (BRIEF opens with "Memory safety ≠ Security") |
| L7.7 | Q1 | "ship = every checklist lane passed with evidence" | L7.2 (introduces the 4-lane checklist) |

I did **not** count these as BLOCKING/MINOR findings, and here is the reasoning so it can be
overridden if you disagree: `lib/catalog.sh`'s `catalog_frontier()` locks progression
per-track and sequentially, so a learner cannot reach any of these gate labs without having
already *passed* the earlier lab that taught the term (this is the same guarantee the task
brief already grants to `recall.json`'s "earlier lab, same track" OK case). This is
categorically different from the soc calibration bug, where the fact was reachable **only
after** the same lab's own gate (a forward reference to knowledge the learner cannot yet
have). Here the reference always points backward to already-passed material. If you want a
stricter same-lab-only standard applied uniformly (including to gate labs), reclassify these
5 rows as MINOR.

**recall.json is missing its required `source` field, track-wide.** Per
`docs/kit-contracts.md:123`, `recall.json` "same shape plus a `source` field per question."
All other tracks that have `recall.json` (bash, ps, soc, demo) include it. **All 7
`recall.json` files in the rust track omit it entirely**:
`p1/L1.1-let-mut-shadowing`, `p2/L2.1-move-semantics`, `p3/L3.1-result-question-mark`,
`p4/L4.1-unsafe-superpowers`, `p5/L5.1-threads-no-data-races`,
`p6/L6.1-rustscan-cli-to-loop`, `p7/L7.1-spec-writing`. This is a schema-conformance gap
worth fixing on its own merits (self-documentation, tooling that might rely on the field),
independent of the content-exposure audit. It's why the GAP classification below was done
by manually tracing each recall question to its source rather than reading a `source` field.

**recall.json GAP check (manual, since `source` is absent).** For all 7 recall-bearing labs,
every one of the 5 questions traces to material from an earlier phase within the rust track
itself (e.g. L6.1's recall Q5 traces to L0.3's "Cargo.toml + main.rs" lesson; L7.1's recall
Q4 traces to L5.7's CWE-400 unbounded-await lesson). None reference another track, a
repo-root README, or anything outside the rust track. **Zero GAPs found.**

## Coverage

All 63 lab directories under `tracks/rust/phases/*/*/` were opened: `meta.json`, `lab.md`,
`hints.json`, `quiz.json`, `recall.json` (7 labs have one), `recap.md`, and every file under
`files/` (including nested subdirectories like `rustscan-src/`, `vector-src/`,
`mystery-src/`, `ecs_parser/`, `async_demo/`, `tokio_loop/`, `scanport/`, `vuln-project/` —
all were text and small enough to read in full; no binary/oversized fixtures existed to
skip). Inline `rust` code blocks in every `lab.md` were diffed against the corresponding
`files/*.rs` and found identical in every case checked.
