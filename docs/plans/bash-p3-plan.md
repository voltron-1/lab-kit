# BASH TRACK — Phase 3 Build Plan (v1): The Footgun Gallery

> **Deliverable location:** on approval this file's content is written verbatim
> to `docs/plans/bash-p3-plan.md` (uncommitted, for review). No lab files, no
> project code, no commits are produced this session. PLAN ONLY.

> **For the BUILD session (may run on Sonnet):** execute §8 mechanically. Every
> script, answer key, SC-code expectation, containment step, quiz, and recap is
> spelled out below so no design decision needs re-deriving. Items tagged
> **[VERIFY-AT-BUILD]** are values that depend on the build machine's exact
> `shellcheck 0.9.0` / `bash 5.2.21` output — the *behavior* is fixed by this
> plan and was verified at plan time; only re-capture the literal strings/SC sets.

---

## 0. Context — why this phase, why containment is the gate

Phase 3 ("The Footgun Gallery") is the one phase with **no equivalent in the
rust/soc/ps tracks**. Every lab is a real, famous Bash bug class demonstrated on
purpose. Precision matters more than in P0–P2: a vague footgun demo teaches the
wrong reflex. The map's own security hook says "the entire phase" is the security
content, and singles out L3.2 (the empty-variable `rm -rf` that "has wiped
production systems") and L3.8 (formalizing ShellCheck as reviewer).

The hard precondition — **checked and satisfied this session**:

1. **bash Phase 2 is complete and tagged.** `git tag` shows `bash-p0`, `bash-p1`,
   `bash-p2`; commit `0e7e647` closed it; `planned_execution.md` marks `bash p2`
   `[x]` with tag evidence. The phase-opener recall (L3.1) pulls from Phase 2, so
   this gate had to pass before planning — it does.
2. **The containment note exists and is binding.** `planned_execution.md`
   (DEPENDENCY FLAGGED, lines 11–20) and `docs/plans/bash-p2-plan.md §7` both
   state: the decoy-tree / shadowed-destructive-command containment mechanism was
   *deliberately not built* in P0–P2. `harness/checklib.sh` ships
   `make_decoy_tree` / `decoy_intact` / `decoy_changed` as forward-compatible
   primitives that **no lab has exercised yet**. Phase 3's plan session must
   "design and prove the containment story … BEFORE speccing its first footgun
   lab." §3 below does exactly that, with plan-time proof.

**Lab list read from the map (v1, §6 Phase 3 table) — used exactly, ids/titles/
types/gate placement unchanged:**

| id | title | type | gate |
|---|---|---|---|
| L3.1 | Word splitting, deep — the classic bugs and their quoted fixes | TAME | false (phase opener) |
| L3.2 | `rm -rf "$DIR/"` — the empty-variable catastrophe | AUDIT | false |
| L3.3 | `IFS` — what it controls and how changing it breaks (or attacks) a script | DECODE | false |
| L3.4 | Filenames as attack surface — files named `-rf`, `--`, or with newlines | AUDIT | false |
| L3.5 | Arithmetic — `(( ))` and the injection people forget it allows | AUDIT | false |
| L3.6 | Subshells vs current shell — why `… \| while read` eats your variables | PREDICT | false |
| L3.7 | `eval` — why it's almost always the wrong answer | AUDIT | false |
| L3.8 | ShellCheck as co-pilot — reading SC codes, which are security-critical | GUIDED | false |
| L3.9 | Phase gate: one script, every footgun — find and harden them all | TAME | **true** |

9 labs, L3.1–L3.9. est_minutes total **135** (all within the 10–20 ADHD band;
gate at 20).

---

## 1. Inherited harness constraints (from bash-p01 §2 / bash-p2 §2–§3)

Everything in the P0/P1 and P2 plans applies unchanged. The load-bearing facts a
BUILD session must not violate:

- **The fence (proven, not assumed).** `lib/workspace.sh :: ws_run_check` runs
  every `check.sh` as a separate process: `cwd` pinned to
  `workspace/bash/<id>/`, `env -i` allowlist, `HOME`/`TMPDIR` redirected into the
  workspace, `bash --noprofile --norc -euo pipefail`, `stdin=/dev/null`,
  `timeout 120s`. `harness/checklib.sh` canonicalizes every asserted path with
  `realpath -m` and hard-exits (`harness_err`) if it escapes `$LAB_WORKSPACE`.
  This is **not an OS sandbox** — it stops our own content's accidental
  out-of-fence access, and is backstopped by `tools/lint-labs.sh`. Destructive
  teaching content must therefore fence itself (see §3), never rely on the OS.
- **`tools/lint-labs.sh` scans `check.sh` ONLY** (not `files/`). Bans in
  `check.sh`: tokens `eval sudo curl wget nc ssh`, `sh -c`, `bash -c`, `pushd`,
  `bin/lab`; `cd ..`/`cd ~`; absolute-path literals; requires `set -euo
  pipefail`, the `LAB_WORKSPACE`/`LAB_CHECKLIB` guards, `source "$LAB_CHECKLIB"`,
  mode `0644`, `ck_summary` last. **`rm` is NOT a banned token** — but no
  `check.sh` in this phase deletes anything itself (see §3); the decoy helpers do
  the mutation, learner scripts do the destruction.
- **`files/` is never scanned** by lint or `tools/shellcheck-all.sh`. Deliberately
  flawed samples carry `# TEACHING SAMPLE — intentionally flawed` as **line 2**
  and declare their expected SC codes in `meta.json.teaching_samples`. Our new
  `files/fence.sh` (§3 Mechanism B) also lives here — out of lint scope — but is
  authored shellcheck-clean anyway.
- **Grading grammar.** Same `key=value` convention as P2: exact lowercase keys, no
  spaces around `=`, one key per line, anchored-ERE grep except values containing
  ERE metachars (`< > | [ ] * ? ( ) { } $`) use `assert_file_contains_fixed` on
  the full line. DECODE grades `answers.txt`; PREDICT grades `predictions.txt`;
  **AUDIT grades `answers.txt`** (identification keys) **plus**, where a hardened
  rewrite is required, behavioral asserts on the learner's `hardened.sh` run under
  the fence; TAME grades the learner's hardened script behaviorally against a
  decoy.
- **Scripts run as `bash <name>`**, never `./<name>`. Quiz ≠ graded answers.
  `quiz.json` exactly 3 Qs; `hints.json` exactly 3 escalating levels; `recap.md`
  exactly 3 lines; phase-opener `recall.json` exactly 5 Qs. All answers
  base64-encoded by the builder (`printf '%s' 'answer' | base64 -w0`).
- **Determinism.** No graded value depends on date/time/hostname/locale/uid. The
  arithmetic-injection demo (L3.5) prints `id -u` to **stderr for the human**, and
  is never a graded value. All shipped filenames lowercase ASCII except the
  deliberately hostile decoy names (`-rf`, `--`, and one spaced/newline name) that
  are the point of L3.1/L3.4.

**New Phase-3 conventions (decided here — rationale in §9):**

1. **AUDIT grading model** (first AUDIT labs in the track). `answers.txt` carries
   three identification keys — `line=` (or `construct=`), `flaw=`, `fix=` — graded
   by exact-match against a short accept set, **plus** the CWE id where the map
   names one. Where the lab requires a hardened rewrite, the learner edits
   `hardened.sh` and check.sh runs it under the fence and asserts safe behavior.
   AUDIT never grades by detonating the *flawed* script inside check.sh.
2. **Two containment mechanisms, §3.** Mechanism A (decoy tree) is inherited and
   needs no approval. Mechanism B (shadowed-`rm` fence, `files/fence.sh`) is
   **NEW and flagged for approval** (§3.2).
3. **Fenced-run capture convention.** A demonstration that runs a footgun is
   captured as `bash <wrapper>.sh > <name>.txt 2>&1; echo "exit=$?" >> <name>.txt`
   exactly as P2 §2.1, and additionally the fence's `fence.log` is `cat`-ed into
   the transcript so the learner sees `FENCE-BLOCKED: …` lines.
4. **[VERIFY-AT-BUILD] on all SC code SETS.** Behavior is fixed by this plan; the
   literal SC-code list per sample is re-captured on the build machine's 0.9.0 and
   written into `meta.json.teaching_samples`. §7 gives the expected set + which
   are load-bearing for the lesson.

---

## 2. Plan-time verification log (what was actually run)

Run in an isolated scratchpad with a fake `$LAB_WORKSPACE`, sourcing the real
`harness/checklib.sh`. Nothing in the repo or real filesystem was touched.

- **Decoy tree.** `make_decoy_tree build` produced exactly
  `decoy-build/{alpha.txt, subdir/beta.txt, -rf, --}` + `decoy-build.manifest`
  (sha256 of the 4 files, `-rf`/`--` are empty ⇒ the `e3b0…855` empty-file hash).
  `decoy_intact build` passed on the untouched tree; after `rm -f
  decoy-build/alpha.txt`, `decoy_changed build` passed. Confirmed the manifest
  check (`sha256sum -c`) reports `FAILED open or read` + rc=1 on a **deleted**
  file. **Limitation confirmed:** the manifest lists only files present at
  creation, so pure *additions* are invisible to `decoy_changed`; **deletion and
  modification are caught.** Every P3 footgun is a deletion/modification, so this
  is sufficient — documented so BUILD never relies on addition-detection.
- **Shadowed-`rm` fence (Mechanism B), fail-closed.** With the §3.2 shim active:
  `DIR=""; rm -rf "$DIR/"` (⇒ `rm -rf /`) was intercepted → `fence.log` line
  `FENCE-BLOCKED: rm -rf /`, exit 0, **`/` untouched**. The glob form `rm -rf
  "$DIR/"*` (⇒ `rm -rf /*`) would have handed `rm` **28 real top-level entries**
  (`/Docker`, … captured via `set -- /*`) — none were run. An in-workspace target
  passed through to `command rm` and really deleted the decoy subdir.
- **L3.4 filename attack.** In a dir containing a file literally named `-rf`,
  `set -- *` yields argv `[-rf a.txt sub]` — `-rf` sorts first and is consumed as
  a **flag**, so `rm *` becomes `rm -rf a.txt sub` (recursive, eats `sub/`). The
  `./` prefix defuses it (`rm ./*` → `rm ./-rf ./a.txt …`, no recursion — verified
  `keep/` survived), and `--` would too (`rm -- *`).
- **L3.3 IFS.** `IFS=':' read -ra parts <<<"root:x:0:0:root:/root:/bin/bash"` →
  7 fields (`parts[0]=root`, `parts[-1]=/bin/bash`); empty `IFS` with unquoted
  `$data` → argc 1 (splitting disabled).
- **L3.5 arithmetic injection.** In `result=$(( n * 2 ))` with untrusted `n`,
  `n='a[$(id -u >&2)]'` **executed `id -u`** (printed `1000` to stderr) via the
  array-subscript command substitution during recursive arithmetic evaluation;
  `n='z[$(echo INJECTED-CODE-RAN >&2)]'` printed the payload. The numeric guard
  `case "$n" in ''|*[!0-9]*) reject;;` **rejected** `a[$(id)]` and accepted `5`.
- **L3.6 subshell.** `printf 'x\ny\nz\n' | while read -r _; do count=$((count+1));
  done; echo "$count"` → **0** (the `while` ran in a subshell); the process-sub
  form `while … done < <(printf …)` → **3** (same shell).
- **L3.7 eval.** `input='file.txt; echo PWNED'; eval "ls $input"` ran `echo
  PWNED` — the injected command executed.

These behaviors are treated as **fixed**. Only exact stderr prefixes / SC code
sets are re-captured at build (they vary by invocation context and tool version).

---

## 3. CONTAINMENT — the design, and the proof (the phase's critical artifact)

Two mechanisms. Every lab that runs a destructive or dangerous command declares,
in its entry (§6), which mechanism it uses, **what gets destroyed, where, and how
the check proves nothing outside the workspace changed.**

### 3.1 Mechanism A — the decoy tree (INHERITED — `harness/checklib.sh`, no approval needed)

- **Creation:** `make_decoy_tree <name>` builds `$LAB_WORKSPACE/decoy-<name>/`
  containing `alpha.txt` ("alpha\n"), `subdir/beta.txt` ("beta\n"), and the
  pre-seeded hostile filenames `-rf` and `--` (both empty), plus a sha256
  `decoy-<name>.manifest`. It refuses (`require_in_workspace`) to build anywhere
  but inside the workspace.
- **Grading:** `decoy_intact <name>` passes iff every listed file is present and
  unchanged (⇒ the footgun did **not** fire / the decoy is whole). `decoy_changed
  <name>` passes iff any listed file was deleted or modified (⇒ the footgun **did**
  fire on the decoy). Both emit a numbered pass/fail line via the collect-all
  grader.
- **What/where/proof:** destruction is confined to `decoy-<name>/` inside the
  workspace. The check proves the outcome by manifest comparison; because
  `make_decoy_tree` can only target in-workspace paths and `decoy_*` only read the
  manifest, no real path is ever read or written.
- **Used by:** L3.1 (word-splitting really mangles a decoy file), L3.4 (poisoned
  glob really deletes a decoy subdir), L3.9 gate (integrative).
- **Known limitation (documented):** additions are invisible; use `decoy_changed`
  only to assert deletion/modification.

### 3.2 Mechanism B — the shadowed-`rm` fence `files/fence.sh` (**NEW — APPROVED 2026-07-15**)

**APPROVED for the BUILD session** (reviewer chose "ship the fence shim" over
decoy-only). This is new code, not inherited. `checklib.sh` provides the decoy
*primitives* but **no shadowed destructive command**. The map (PROMPTS.md bash
gate) blesses the idea in spirit — "a DECOY TREE … **and/or** a shadowed function
that logs instead of destroys" — but the concrete shim below is authored here and
needs your sign-off before the BUILD session ships it.

**Why a second mechanism is required:** L3.2 (empty-var `rm -rf /`), L3.7 (eval
injecting `rm -rf`), and part of L3.9 are footguns whose *whole lesson* is that
the target becomes the **real filesystem root**, not a decoy. A decoy can't teach
that — the danger is precisely that the command escapes any intended directory.
So these labs run the footgun through a fail-closed shim that intercepts any
target outside the workspace, **logs what would have been destroyed**, and refuses
it — while still letting correctly-scoped, in-workspace deletions really happen
(so decoys really die and `rm -rf`'s power is visible).

**`files/fence.sh` (ship in L3.2, L3.7, L3.9; identical copy; authored
shellcheck-clean):**

```bash
# shellcheck shell=bash
# fence.sh — teaching fence. Source before running a footgun so a runaway
# destructive command cannot escape the lab workspace. NOT a security sandbox;
# a teaching guardrail that logs the would-be catastrophe instead of doing it.
# rm() is redefined FAIL-CLOSED: if ANY target canonicalizes outside
# $LAB_WORKSPACE (or fails to canonicalize), the WHOLE call is refused and
# recorded in fence.log; only fully-in-workspace calls reach the real rm.
: "${LAB_WORKSPACE:?fence.sh: LAB_WORKSPACE must be set}"
: "${LAB_FENCE_LOG:=fence.log}"

rm() {
  local arg canon blocked=0
  for arg in "$@"; do
    case "$arg" in
      -*) continue ;;                       # an option, not a path
    esac
    canon="$(realpath -m -- "$arg" 2>/dev/null)" || canon=""
    case "$canon" in
      "$LAB_WORKSPACE" | "$LAB_WORKSPACE"/*) : ;;   # inside the fence — allowed
      *) blocked=1 ;;                                # escapes (incl. "" and /) — refuse
    esac
  done
  if (( blocked )); then
    printf 'FENCE-BLOCKED: rm %s\n' "$*" >> "$LAB_FENCE_LOG"
    return 0                                # mimic the silent "success" of the real disaster
  fi
  command rm "$@"
}
```

- **What gets destroyed, where:** only in-workspace decoy paths, ever. A correctly
  scoped `rm -rf "decoy-build/"` really removes the decoy; an empty-variable `rm
  -rf /`, a glob `rm -rf /*`, or an eval-injected `rm -rf /etc` all canonicalize
  outside `$LAB_WORKSPACE` → the entire call is refused and logged.
- **How the check proves nothing outside changed** (two layers, honestly scoped):
  1. **By construction, proven.** The fence is fail-closed and was exercised at
     plan time (§2): `rm -rf /` → `FENCE-BLOCKED: rm -rf /`, exit 0, `/`
     untouched; `/*` would have hit 28 real dirs, none run. Empty-string and
     realpath-failure targets fall through to the `*)` refuse arm.
  2. **At runtime, in-fence evidence only.** `check.sh` is *forbidden to read
     outside the workspace* (the `realpath` guard + the absolute-path lint), so it
     cannot and must not inspect `/` directly. Its containment-proof assertions
     are therefore in-fence: (a) `fence.log` contains the expected `FENCE-BLOCKED:
     …` line after the guided demonstration, and (b) after running the learner's
     **hardened** script with the empty variable under the fence, `fence.log` is
     empty (the fix aborted *before* `rm`) **and** `decoy_intact` holds. The
     "`/` is still there" screenshot is a **build-session self-test artifact**
     (§8 step 4): the builder pastes `ls / | wc -l` (or a sentinel canary under a
     non-workspace scratch dir *in the build shell only*, never in shipped
     check.sh) before/after running the *flawed* sample under the fence, showing
     the count unchanged. This satisfies PROMPTS.md's "run the footgun, verify
     nothing outside the workspace changed" as a proof obligation on the builder,
     with the runtime check enforcing the fence engaged.
- **Scope:** the shim shadows `rm` only — the sole destructive verb in these labs.
  Injected/teaching payloads are authored to use `rm` (fenced) or harmless
  commands (`echo`), never `mv`/`>`/`dd`/`find -delete`. If a future lab needs it,
  add a parallel `mv()` guard; none in P3 do.
- **Delivery:** `fence.sh` sits in the lab's `files/` (copied into the workspace by
  `lab start`). Guided steps and check.sh invoke the footgun through a tiny
  shipped wrapper `run-fenced.sh` that does `source ./fence.sh` then runs the
  target — keeping the `source` out of the teaching sample itself so the flawed
  script reads authentically.

**Approval status: GRANTED (2026-07-15).** Mechanism B (`fence.sh` +
`run-fenced.sh`) ships as specified for L3.2/L3.7/L3.9. It is the only NEW
containment code in the phase; everything else reuses the inherited decoy helpers.

---

## 4. AUDIT answer-key grammar (applies to L3.2, L3.4, L3.5, L3.7)

`answers.txt`, one `key=value` per line, graded by anchored ERE unless the value
holds ERE metacharacters (then `assert_file_contains_fixed` on the whole line):

- `line=<n>` — the 1-based line number of the dangerous construct in the shipped
  sample (or `construct=<token>` where a line number is ambiguous).
- `flaw=<slug>` — a short controlled slug (accept set listed per lab).
- `cwe=<id>` — where the map names a CWE for the phase (none named for P3 labs
  specifically; CWE keys appear in Phase 4 — so P3 uses `flaw=` only, **no `cwe=`
  key**, to avoid inventing ids).
- Fix is demonstrated, not just named: labs that require hardening grade the
  learner's `hardened.sh` behaviorally (under the fence where destructive).

Slugs are lowercase, hyphenated, single-token where possible so exact-match
grading is robust: `empty-var-rm`, `dash-filename`, `arith-cmdsub`,
`eval-injection`, `unquoted-split`, `subshell-var-loss`.

---

## 5. Spaced-recall for the phase opener (L3.1 `recall.json` — task item 8)

**Read from disk:** the five questions below were validated against the actual
Phase 2 lab content (`tracks/bash/phases/p2/*/recap.md`) — each answer is a
verbatim consequence of the sourced lab's recap card. This adopts the draft the
P2 build left for the P3 builder (`bash-p2-plan.md:1482`) and confirms its
sourcing. All five pull from Phase 2 (the immediately-prior phase), matching the
established pattern (L2.1's opener pulled all from P1). **Ship in
`L3.1/recall.json`; do NOT reuse any of these as L3.1's own quiz.**

| # | source lab | prompt | options | answer | on-disk evidence (recap.md) |
|---|---|---|---|---|---|
| 1 | **bash L2.2** | Which strict-mode flag makes an unset or typo'd variable fatal? | a) `-e`  b) `-u`  c) `pipefail` | **b** | "set -u: an unset or typo'd variable is fatal and named" |
| 2 | **bash L2.4** | `true && false \|\| echo X` — does X print? | a) no — `\|\|` pairs with `true`'s success  b) yes — `\|\|` reacts to the most recent verdict, `false`'s failure  c) syntax error | **b** | "a && b \|\| c is NOT if/else: c fires on b's failure too — \|\| pairs with the most recent verdict" |
| 3 | **bash L2.7** | A trap registered on EXIT runs… | a) only after `exit 0`  b) only on errors  c) on every way out — success, failure, or interrupt | **c** | "trap … EXIT runs the handler on EVERY way out — the happy end, a set -e death, or Ctrl-C" |
| 4 | **bash L2.6** | `out=$(f)` where `f`'s body is only `return 3` leaves `out` holding… | a) `3`  b) nothing — `return` sends a one-byte code, not text; `$( )` captures stdout only  c) the string `return 3` | **b** | "out=$(fn) stays EMPTY if fn only returns; never confuse the channels" |
| 5 | **bash L2.3** | `for w in $(cat file)` iterates over… | a) the file's lines  b) the whitespace-split words of the file  c) exactly one item | **b** | "for iterates WORDS … an unquoted $(cat f) hands it 7 split words, not 3 lines" |

`recall.json` shape (match L2.1's file exactly — `id`, `type:"choice"`, `source`,
`prompt`, `options{a,b,c}`, `answer_b64`). Base64 for the answers: `b`→`Yg==`,
`c`→`Yw==`. (Q1,Q2,Q4,Q5 → `Yg==`; Q3 → `Yw==`.)

---

## 6. Lab entries (build straight from these)

Per-lab template: **(1)** id/title/type/gate/est · **(2)** TEACHING ARTIFACT
(exact scripts) · **(3)** CONTAINMENT SPEC · **(4)** SHELLCHECK STATUS · **(5)**
CHECK LOGIC · **(6)** QUIZ · **(7)** RECAP. L3.1 additionally carries §5's recall.

---

### L3.1 — Word splitting, deep — the classic bugs and their quoted fixes
**TAME · gate:false · est 15 · files/: stage.sh, manifest.txt, fence not needed · recall.json: YES (§5)**
**objective:** "Take a working-but-dangerous file-mover and harden it: name each place an unquoted expansion word-splits or globs, then quote/rewrite so a filename with a space, a glob char, or a leading dash survives intact."

**meta.json.type = TAME.** The learner edits a shipped flawed `stage.sh` into a
hardened one; the shipped flawed copy is a `# TEACHING SAMPLE`.

**(2) TEACHING ARTIFACT.** The exact working-but-dangerous starting script
(`files/stage.sh`, header line 2 = the teaching-sample marker):
```bash
#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# stage.sh — move every file listed in the manifest into the archive dir.
manifest=$1
archive=$2
for f in $(cat $manifest); do        # $(cat) splits on IFS: every word, not every line
  mv $f $archive                     # unquoted $f: a spaced name splits into two args
done
echo staged
```
Shipped `files/manifest.txt` — three names, one with a space (the detonator):
```
alpha.txt
my report.txt
subdir
```
The exact hardened version the learner should reach (reference `hardened.sh`,
authored shellcheck-clean; the lab text names the goals, hints escalate to the
edits):
```bash
#!/usr/bin/env bash
set -euo pipefail
manifest=$1
archive=$2
while IFS= read -r f; do             # read LINES, not split words (L2.3 pattern)
  [[ -n "$f" ]] || continue
  mv -- "$f" "$archive"/             # quote the name; -- ends option parsing
done < "$manifest"
echo staged
```
Behavior (verified reasoning): on `my report.txt` the flawed script runs `mv my
report.txt <archive>` → mv treats `my` and `report.txt` as two sources and
`<archive>` as… actually three-arg `mv a b c` requires `c` be a dir → it "works"
by accident here but silently moves the wrong pair on other inputs; the guided
step uses a decoy where the split is *visibly* wrong (a spaced name plus a name
containing a glob char) so the learner *sees* the wrong files move. The hardened
version moves each listed name verbatim.

**(3) CONTAINMENT SPEC — Mechanism A (decoy tree).** `check.sh` calls
`make_decoy_tree stage`, then augments it in-workspace with a spaced filename
`"$LAB_WORKSPACE/decoy-stage/my report.txt"` (a `printf`, in-fence) and an
`archive/` target dir inside the decoy. **What gets destroyed/moved:** files under
`decoy-stage/` only. **Where:** `$LAB_WORKSPACE/decoy-stage/`. **Proof:** after
running the learner's hardened `stage.sh` against the decoy manifest,
`assert_file_exists "decoy-stage/archive/my report.txt"` (the spaced name arrived
intact) and `assert_file_missing "decoy-stage/archive/my"` (no split happened).
No `rm` is involved; `mv` stays inside the decoy; the fence shim is not required
for this lab (no path can escape — `mv` targets are the in-workspace archive dir).

**(4) SHELLCHECK STATUS.** `files/stage.sh` — teaching sample, header line 2.
Expected codes under `shellcheck -x -S style` (0.9.0): **SC2086** (unquoted `$f`,
`$manifest`, `$archive`), **SC2046/SC2013** family on `for f in $(cat …)` — [VERIFY-AT-BUILD]
exact set; the load-bearing one for the lesson is **SC2086** (+ the `$(cat)`-into-`for`
warning). `meta.json.teaching_samples = {"files/stage.sh": [<verified set>]}`. The
learner's `hardened.sh` must be shellcheck-clean (verified for the reference).

**(5) CHECK LOGIC (`check.sh`).** Standard preamble (`set -euo pipefail`,
`LAB_WORKSPACE`/`LAB_CHECKLIB` guards, `source "$LAB_CHECKLIB"`), then:
```
make_decoy_tree stage
# seed a spaced name + archive dir INSIDE the decoy (in-fence printf/mkdir)
require_in_workspace "decoy-stage/my report.txt"; : > "$REQ_PATH"
require_in_workspace "decoy-stage/archive";       mkdir -p "$REQ_PATH"
# learner's hardened script must exist and be the strict-mode form
assert_file_exists "stage.sh" "edit the shipped stage.sh into your hardened version"
assert_file_contains "stage.sh" 'set -euo pipefail' "add the strict-mode preamble (L2.2)"
assert_file_contains_fixed "stage.sh" 'read -r' "read the manifest LINE BY LINE (L2.3), don't $(cat) it into a for"
assert_file_not_contains "stage.sh" 'for [a-z]+ in \$\(cat' "the $(cat)-into-for split is the bug you're removing"
# behavioral: run it against a decoy manifest and prove the spaced name survived
printf '%s\n' 'my report.txt' > decoy-stage/manifest.txt
assert_cmd_ok "hardened stage.sh runs clean on the decoy" \
  "your script must move the listed file without splitting it" \
  -- bash -- stage.sh decoy-stage/manifest.txt decoy-stage/archive   # cwd=workspace; paths in-fence
assert_file_exists "decoy-stage/archive/my report.txt" \
  "the spaced filename must arrive WHOLE — that's the whole lesson"
assert_file_missing "decoy-stage/archive/my" \
  "if 'my' exists on its own, the name still word-split — quote \$f and use -- "
ck_summary
```
(≈9 assertions. `check.sh` itself never deletes; `mv` happens inside the learner's
script, in-fence. CI fabrication for `tests/acceptance.sh`: after `lab start`,
overwrite `stage.sh` with the reference hardened content via `printf`; negative
case: leave the shipped flawed `stage.sh` unedited → the `set -euo pipefail`
assert + the split-survivor assert fail.)

**(6) QUIZ (plaintext; builder base64s):**
1. choice — "`for f in $(cat list)` splits the file into…" a) lines b) **words on
   `$IFS` — a spaced filename becomes two iterations** c) one string → **b**
2. choice — "Which single change stops `mv $f $dest` from breaking on a spaced
   name?" a) rename the file b) **double-quote it: `mv -- "$f" "$dest"/`** c) add
   `set -e` → **b**
3. choice — "The `--` in `mv -- "$f" "$dest"/` is there to…" a) speed mv up
   b) **stop a filename that starts with `-` from being read as an option** c)
   make mv recursive → **b**

**(7) RECAP:**
```
$(cat file) and $var without quotes are word-split on IFS — a filename with a space becomes two arguments and the wrong thing moves
the fixes are muscle memory: quote every expansion ("$f"), read lines with while IFS= read -r (L2.3), and end options with --
the shell will not warn you — you quote by reflex, and ShellCheck's SC2086 is the backstop, not the other way round
```

---

### L3.2 — `rm -rf "$DIR/"` — the empty-variable catastrophe
**AUDIT · gate:false · est 15 · files/: cleanup.sh, fence.sh, run-fenced.sh · recall.json: no**
**objective:** "Read a cleanup script and name the exact line where an unset or typo'd variable turns `rm -rf \"$DIR/\"` into `rm -rf /`; state the one-token fix that makes it fail safe."

**(2) TEACHING ARTIFACT.** The exact vulnerable script (`files/cleanup.sh`,
teaching-sample header line 2):
```bash
#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# cleanup.sh — wipe the build output dir before a fresh build.
BUILD_DIR=$(dirname "$0")/build      # if this ever yields empty, the next line is fatal
rm -rf "$BUILD_DIR/"                  # empty BUILD_DIR => rm -rf "/"  ← the catastrophe
echo clean
```
The **exact flaw to find:** line 5 (`rm -rf "$BUILD_DIR/"`). If `BUILD_DIR` is
ever empty/unset (a failed `dirname`, an unset export in a stripped cron env, a
refactor that drops the assignment), `"$BUILD_DIR/"` expands to `/` and the
command becomes `rm -rf /`. ShellCheck flags this precise pattern as **SC2115**.
The **exact fix:** make empty fatal — either the strict-mode `set -u` **plus**
`"${BUILD_DIR:?BUILD_DIR is empty}"`, or the SC2115-recommended
`rm -rf "${BUILD_DIR:?}/"`. Reference hardened `hardened.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
BUILD_DIR=$(dirname "$0")/build
rm -rf "${BUILD_DIR:?BUILD_DIR is empty — refusing to rm}/"   # :? aborts before rm if empty
echo clean
```

**(3) CONTAINMENT SPEC — Mechanism B (shadowed-`rm` fence) — MANDATORY.** The
whole lesson is that the target becomes `/`, so a decoy can't carry it. **What
would be destroyed:** the entire real filesystem (`rm -rf /`). **Where the danger
is fenced:** `files/fence.sh` (§3.2) redefines `rm` fail-closed; the guided
demonstration runs the flawed script via `run-fenced.sh` with `BUILD_DIR` forced
empty, so `rm -rf /` is intercepted → `fence.log` gets `FENCE-BLOCKED: rm -rf /`
and **nothing is deleted** (proven §2). **How the check proves nothing outside
changed:** (a) after the demonstration, `assert_file_contains "fence.log"
'FENCE-BLOCKED: rm -rf /'`; (b) running the learner's **hardened** script with an
empty `BUILD_DIR` under the fence must **abort before `rm`** — asserted by
`fence.log` staying empty on that run and a fresh `decoy_intact` holding; (c)
build-session self-test pastes `ls / | wc -l` before/after the flawed run to show
the count unchanged (proof obligation, not a shipped check — check.sh may not read
`/`). `run-fenced.sh`:
```bash
#!/usr/bin/env bash
# run-fenced.sh <script> [args…] — source the fence, then run the target so a
# runaway rm cannot escape the workspace. Keeps 'source fence.sh' out of the
# teaching sample so cleanup.sh reads authentically.
set -uo pipefail
source ./fence.sh
target=$1; shift
# shellcheck disable=SC1090  # (lives in files/, not linted; disable is illustrative only)
BUILD_DIR="" bash -c 'source ./fence.sh; source "$1"' _ "$target" "$@" 2>&1 || true
```
> BUILD note: keep `run-fenced.sh` minimal and shellcheck-clean; the exact
> mechanism (source-in-subshell vs. function export) is a build detail — the
> contract is only "`rm` is shadowed by fence.sh when the sample runs, and
> `BUILD_DIR` is empty for the catastrophe demo." Verify the fence engages by
> checking `fence.log` after the run.

**(4) SHELLCHECK STATUS.** `files/cleanup.sh` — teaching sample. Expected codes:
**SC2115** (`Use "${var:?}" to ensure this never expands to /`) — **the
load-bearing, security-critical code for this lab** — plus possibly **SC2086** on
`$0`/`$BUILD_DIR` context [VERIFY-AT-BUILD]. This is the lab where ShellCheck
*does* catch the bug (contrast L3.5/L3.7 where it can't) — a point L3.8 revisits.
`meta.json.teaching_samples = {"files/cleanup.sh": [<verified set incl. SC2115>]}`.

**(5) CHECK LOGIC (`check.sh`).** AUDIT identification + hardened-behavior +
containment proof:
```
# --- identification (answers.txt) ---
assert_file_contains "answers.txt" '^line=5$' "which single line becomes rm -rf / when the var is empty?"
assert_file_contains "answers.txt" '^flaw=empty-var-rm$' "name the flaw class (see the brief's slug list)"
assert_file_contains "answers.txt" '^fix=' "state the fix — the :? guard or set -u making empty fatal"
assert_file_contains "answers.txt" '(:\?|set -u|nounset)' "the fix must make an EMPTY variable fatal before rm runs"
# --- the fence engaged on the flawed demo (guided step wrote fence.log) ---
assert_file_contains_fixed "fence.log" 'FENCE-BLOCKED: rm -rf /' \
  "run the demo via run-fenced.sh first — the fence log must show the blocked rm -rf /"
# --- hardened script fails SAFE with an empty var, under the fence ---
make_decoy_tree c
: > fence.log                                  # reset before the hardened run
assert_cmd_fails "hardened cleanup aborts when BUILD_DIR is empty" \
  "your :? / set -u fix must STOP the script before rm when the dir is empty" \
  -- bash -c 'source ./fence.sh; BUILD_DIR=""; source ./hardened.sh' 
assert_file_not_contains "fence.log" 'FENCE-BLOCKED' \
  "the hardened script must abort BEFORE rm — nothing should reach the fence"
decoy_intact c
ck_summary
```
(≈9 assertions. `check.sh` runs no destructive command itself; the only `rm`
reachable is inside the sourced learner/reference script, shadowed by `fence.sh`.
CI fabrication: write `answers.txt` with the three keys; `printf 'FENCE-BLOCKED:
rm -rf /\n' > fence.log`; copy the reference `hardened.sh`. Negative case: omit
`fence.log` or use the flawed `cleanup.sh` as `hardened.sh` → the fence-empty
assert / abort assert fails.)

**(6) QUIZ:**
1. choice — "`rm -rf "$DIR/"` with `DIR` unset becomes…" a) a no-op b) **`rm -rf
   /` — it wipes the filesystem root** c) a syntax error → **b**
2. choice — "Which turns the empty case fatal *before* `rm` runs?" a) quoting
   `"$DIR"` harder b) **`"${DIR:?}"` (or `set -u`) — an empty/unset var aborts the
   script** c) `rm -ri` → **b**
3. choice — "ShellCheck's take on this line:" a) silent — it can't see it b)
   **SC2115 warns exactly this: use `${var:?}` so it never expands to `/`** c) it
   rewrites the line for you → **b**

**(7) RECAP:**
```
rm -rf "$DIR/" with an empty DIR is rm -rf / — one unset variable away from wiping the machine (this class has caused real outages)
the fix is one token: "${DIR:?}" (or set -u) makes empty fatal, so the script dies instead of the filesystem
this is the footgun ShellCheck DOES catch — SC2115 — so a clean shellcheck run is part of the guardrail here
```

---

### L3.3 — `IFS` — what it controls and how changing it breaks (or attacks) a script
**DECODE · gate:false · est 12 · files/: split-demo.sh, passwd.line · recall.json: no**
**objective:** "Explain what `IFS` decides (how the shell cuts unquoted expansions into words) and predict how the same line behaves under the default IFS, `IFS=':'`, and an empty IFS — including how a script that trusts an inherited IFS can be mis-steered."

**(2) TEACHING ARTIFACT — the exact demonstration script** (`files/split-demo.sh`,
a *working* DECODE sample — no teaching-sample header, it is not flawed, it
demonstrates):
```bash
#!/usr/bin/env bash
# split-demo.sh — the SAME data, cut three ways, to show what IFS controls.
line='root:x:0:0:root:/root:/bin/bash'
data='a b c'

# 1) default IFS (space/tab/newline): whitespace splits, ':' does not
set -- $data;        printf '1) default IFS, $data  -> argc=%d\n' "$#"

# 2) IFS=':'  — now the colon is the separator, spaces are not
IFS=':' read -ra f <<< "$line"
printf '2) IFS=":" on passwd -> fields=%d first=%s shell=%s\n' "${#f[@]}" "${f[0]}" "${f[-1]}"

# 3) IFS=''  — splitting DISABLED: the whole value stays one word
IFS='' ; set -- $data; printf '3) IFS empty, $data      -> argc=%d\n' "$#"
```
Verified output (behavior fixed; exact text [VERIFY-AT-BUILD]):
```
1) default IFS, $data  -> argc=3
2) IFS=":" on passwd -> fields=7 first=root shell=/bin/bash
3) IFS empty, $data      -> argc=1
```
**The attack angle (in `lab.md`, demonstrated, not just told):** a script that
does `for tok in $untrusted` and *inherits* `IFS` from its environment can be
re-steered by whoever sets `IFS` — e.g. an attacker exporting `IFS=/` before
invoking a script that splits a path, so `for p in $path` cuts on `/` instead of
whitespace. The defensive reflex: set `IFS` explicitly (or `local IFS=$' \t\n'`)
at the top of any function that relies on splitting, and quote what you don't want
split. `answers.txt` records the three predicted counts + the one-line attack
statement.

**(3) CONTAINMENT SPEC.** None required — no destructive command; the script only
splits strings and prints counts. All writes (`answers.txt`) stay in-workspace.
Explicitly note in the entry: **no decoy, no fence** — IFS here changes *parsing*,
not the filesystem.

**(4) SHELLCHECK STATUS.** `files/split-demo.sh` is a **clean** sample (no
teaching-sample header). Under `shellcheck -x -S style` it may emit **SC2086** on
the deliberate unquoted `$data` (the point of the demo) — if so, this file gets a
teaching-sample header + `teaching_samples` entry after all, **or** the two
`set -- $data` lines carry an inline justification and the file is treated as a
demo whose SC2086 is intentional. **BUILD decision [VERIFY-AT-BUILD]:** run
shellcheck; if it flags the intentional split, add the `# TEACHING SAMPLE` header
(line 2) and list the exact codes — do **not** add `# shellcheck disable=` (banned
repo-wide). Simplest: give it the teaching-sample header from the start and list
`SC2086`. Recommended: **ship with the header + `teaching_samples:{"files/split-demo.sh":["SC2086"]}`.**

**(5) CHECK LOGIC.** DECODE — grade `answers.txt`:
```
assert_file_contains "answers.txt" '^default_argc=3$'  "run split-demo.sh — how many words is 'a b c' under default IFS?"
assert_file_contains "answers.txt" '^passwd_fields=7$' "with IFS=':' how many colon-separated fields in the passwd line?"
assert_file_contains "answers.txt" '^empty_argc=1$'    "with IFS='' does 'a b c' split at all?"
assert_file_contains "answers.txt" '^ifs_controls=splitting$' \
  "one word: IFS decides how the shell cuts unquoted expansions into ___"
assert_file_contains "answers.txt" '^attack=' \
  "one line: how can an inherited/hostile IFS re-steer 'for x in \$untrusted'?"
ck_summary
```
(5 assertions. CI fabrication: `printf 'default_argc=3\npasswd_fields=7\nempty_argc=1\nifs_controls=splitting\nattack=env sets IFS so the loop splits on the wrong char\n' > answers.txt`. Negative: wrong count.)

**(6) QUIZ:**
1. choice — "IFS controls…" a) which commands exist b) **how the shell splits
   unquoted expansions into words** c) file permissions → **b**
2. choice — "With `IFS=''`, `set -- $data` where `data='a b c'` gives argc…" a) 3
   b) **1 — splitting is disabled** c) 0 → **b**
3. choice — "A function that relies on word-splitting should…" a) trust the
   caller's IFS b) **set IFS explicitly (e.g. `local IFS=$' \t\n'`) so a hostile
   inherited IFS can't re-steer it** c) never use loops → **b**

**(7) RECAP:**
```
IFS is the shell's cutting guide: it decides where unquoted $var and $(cmd) break into separate words — default is space/tab/newline
change IFS and the same line parses differently: IFS=':' reads /etc/passwd fields; IFS='' turns splitting off entirely
a script that splits untrusted data while trusting an inherited IFS can be re-steered — set IFS explicitly, and quote what must stay whole
```

---

### L3.4 — Filenames as attack surface — files named `-rf`, `--`, or with newlines
**AUDIT · gate:false · est 15 · files/: purge.sh · recall.json: no**
**objective:** "Read a directory-cleanup script and explain how a file named `-rf` (or `--`, or one containing a newline) turns a flat `rm *` into a recursive delete or otherwise subverts it; give the two fixes (`./*` and `--`)."

**(2) TEACHING ARTIFACT.** The exact vulnerable script (`files/purge.sh`,
teaching-sample header line 2):
```bash
#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# purge.sh — delete every file in the current dir (flat, non-recursive… supposedly).
rm *                                  # a file named -rf sorts FIRST and becomes a FLAG
echo purged
```
**The exact flaw:** line 4 (`rm *`). The glob is expanded and **sorted by the
shell before `rm` sees it**; a file literally named `-rf` sorts ahead of normal
names and is parsed by `rm` as the options `-r -f`, silently upgrading a flat
delete into a recursive one that descends into subdirectories. Verified: `set --
*` in a dir containing `-rf`, `a.txt`, `sub/` yields argv `[-rf a.txt sub]` →
`rm -rf a.txt sub` eats `sub/`. Filenames with newlines/leading dashes are the
same class of "the name is data, but an unguarded command treats it as syntax."
**The exact fixes (two, both taught):** prefix the glob so every match starts with
a path (`rm ./*` → `rm ./-rf …`, dashes no longer lead), **or** end option parsing
first (`rm -- *`). Reference hardened `hardened.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
rm -- ./*        # -- ends options AND ./ defuses dash-leading names; belt and braces
echo purged
```

**(3) CONTAINMENT SPEC — Mechanism A (decoy tree) — MANDATORY.** This is the lab
`make_decoy_tree` was purpose-built for: it pre-seeds files named **`-rf`** and
**`--`**. **What gets destroyed, where:** files inside `decoy-purge/` — the guided
demonstration runs the *flawed* `purge.sh` **inside the decoy dir** and the learner
watches the poisoned glob recursively delete `decoy-purge/subdir/` (real deletion,
but confined to the decoy). **How the check proves nothing outside changed:**
`decoy_purge` lives under `$LAB_WORKSPACE`; the demonstration `cd`s into it (in
the guided step / a shipped `run-in-decoy.sh` wrapper, never in check.sh which is
banned from `cd ..`), so even the recursive `rm -rf` can't climb above the decoy —
and the manifest proof (`decoy_changed` after the flawed run, `decoy_intact` after
the hardened run's *scoped* behavior) confirms the outcome. Because the target is a
relative glob inside an in-workspace dir, the runaway is naturally bounded by the
workspace even without the shim; the fence shim is **not** required here (contrast
L3.2 where the target is `/`). If the BUILD prefers defense-in-depth, sourcing
`fence.sh` too is harmless — but the decoy is the primary and sufficient fence.

**(5) CHECK LOGIC.** AUDIT identification + hardened behavior on a decoy carrying
the hostile name:
```
# identification
assert_file_contains "answers.txt" '^line=4$'                 "which line's glob can pick up a filename as a flag?"
assert_file_contains "answers.txt" '^flaw=dash-filename$'     "name the flaw class (brief's slug list)"
assert_file_contains "answers.txt" '(\./\*|-- )' "answers.txt" # the fix must mention ./* or --
# hardened behavior: build a decoy that CONTAINS a -rf file and a subdir, run the
# learner's hardened purge.sh INSIDE it, prove subdir survived (no recursion)
make_decoy_tree purge     # seeds -rf, --, alpha.txt, subdir/beta.txt
assert_cmd_ok "hardened purge.sh runs without treating -rf as a flag" \
  "run scoped: your rm must delete files, not recurse into subdir via a -rf name" \
  -- bash -c 'cd decoy-purge && cp ../hardened.sh ./h.sh && bash ./h.sh'
# subdir/ must be GONE only if the learner intended recursion — here hardened is
# FLAT, so a correct fix removes the top-level files but rm -- ./* on a dir arg
# errors safely; assert the -rf file is gone and subdir/ (a dir) was NOT recursed:
assert_file_missing "decoy-purge/-rf"        "the -rf file should be deleted as a FILE, safely"
assert_file_exists  "decoy-purge/subdir"     "subdir/ must survive — a flat purge must not recurse"
ck_summary
```
> BUILD refinement [VERIFY-AT-BUILD]: `rm -- ./*` in a dir with a subdir prints
> `rm: cannot remove './subdir': Is a directory` and exits nonzero under `set -e`.
> Decide at build whether the hardened reference should (a) stay flat and tolerate
> that (use `rm -- ./*.txt` or a `find -maxdepth 1 -type f` form), or (b) the lab's
> "flat purge" explicitly means files-only. **Recommended:** ship hardened as
> `rm -f -- ./*` won't help (still hits the dir); use
> `find . -maxdepth 1 -type f -exec rm -- {} +` OR narrow to a pattern. Pick the
> files-only `find`-based hardened reference so the assert set above holds cleanly.
> The lesson (a `-rf` name must never become a flag) is unchanged; the assert
> proves `subdir/` survived. Re-verify the exact hardened script's exit/behaviour
> on the build machine and pin it.

**(4) SHELLCHECK STATUS.** `files/purge.sh` — teaching sample. Expected code:
**SC2035** (`Use ./*glob* or -- so names with dashes won't be treated as options`)
— **security-critical, the lab's whole point** — [VERIFY-AT-BUILD] exact set.
`meta.json.teaching_samples = {"files/purge.sh": ["SC2035", …]}`.

**(6) QUIZ:**
1. choice — "A file named `-rf` in a dir where you run `rm *`…" a) is ignored b)
   **sorts first and is parsed as the flags `-r -f` — your flat delete goes
   recursive** c) causes a syntax error → **b**
2. choice — "Which defuses it?" a) `rm *.` b) **`rm -- *` or `rm ./*` — end
   options, or make every name start with a path** c) `rm -i *` → **b**
3. choice — "The general principle this teaches:" a) never name files with dashes
   b) **a filename is untrusted data; an unguarded command can read it as syntax
   (flags), so guard the boundary (`--`, `./`)** c) globs are always safe → **b**

**(7) RECAP:**
```
the shell expands and SORTS a glob before the command sees it, so a file named -rf leads the argv and rm reads it as flags — flat delete goes recursive
two reflexes defuse it: rm -- * (end option parsing) and rm ./* (every name starts with a path, so no name can lead with -)
filenames (and their newlines and dashes) are attacker-controlled data — ShellCheck SC2035 flags exactly this
```

---

### L3.5 — Arithmetic — `(( ))` and the injection people forget it allows
**AUDIT · gate:false · est 15 · files/: calc.sh · recall.json: no**
**objective:** "Read a script that does arithmetic on an untrusted value and explain how `$(( n ))` / `(( n ))` can execute an attacker's command through an array-subscript command substitution; give the numeric-validation fix."

**(2) TEACHING ARTIFACT.** The exact vulnerable script (`files/calc.sh`,
teaching-sample header line 2):
```bash
#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# calc.sh — double a quantity supplied on the command line.
n=$1                                  # UNTRUSTED
result=$(( n * 2 ))                   # $(( )) evaluates n as an arithmetic EXPRESSION,
                                      # and an array subscript inside it runs command substitution
echo "result=$result"
```
**The exact flaw:** line 5 (`result=$(( n * 2 ))`). Arithmetic evaluation is
*recursive*: bash re-evaluates the contents of `n` as an arithmetic expression, so
a value like `a[$(id -u)]` is parsed as an array reference whose **subscript is
command-substituted** — the command runs. **Verified at plan time:** `n='a[$(id -u
>&2)]'` executed `id -u` (printed `1000`); `n='z[$(echo INJECTED-CODE-RAN >&2)]'`
printed the payload. **The exact fix:** validate the input is numeric before it
ever reaches `(( ))` — reject anything non-digit. Reference hardened `hardened.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
n=$1
case "$n" in
  '' | *[!0-9]*) echo "refusing non-numeric input: $n" >&2; exit 2 ;;
esac
result=$(( n * 2 ))                   # now n is guaranteed all-digits
echo "result=$result"
```
Verified: the guard rejects `a[$(id)]` (exit 2) and accepts `5` (`result=10`).

**(3) CONTAINMENT SPEC.** No destructive command *by design* — but the injection
executes an arbitrary command, so the **teaching payload is authored to be
harmless**: the demonstration uses `n='x[$(id -u >&2)]'` (prints your uid to
stderr) — never a payload that writes/deletes. **What could be destroyed:**
nothing, because we control the payload string shipped in the guided step.
**Where:** N/A. **Proof:** the guided-step capture shows the uid printed by the
injected `id` (evidence the code ran) with **zero filesystem effect**; check.sh
never runs the flawed script — it grades identification + the hardened script's
*rejection* behavior. Note explicitly in the entry: because the injection vector
is "runs a command," the containment story is **"ship only a read-only payload,"**
and the fence shim is not applicable (no `rm`). If BUILD wants belt-and-braces,
run the demo via `run-fenced.sh` so even an accidental destructive payload can't
escape — recommended, cheap.

**(4) SHELLCHECK STATUS.** `files/calc.sh` — teaching sample. **Expected: SC does
NOT flag this as injection** — [VERIFY-AT-BUILD], but the pedagogically important
fact is that ShellCheck has **no dedicated warning** for arithmetic command-sub
injection (it may emit nothing, or only style noise). This is a **blind spot** the
lab teaches and L3.8 reinforces: "a clean shellcheck run does not mean safe."
`meta.json.teaching_samples = {"files/calc.sh": [<verified set — likely []>]}`. If
the set is empty, that empty list is graded insight (like P2's e-demo.sh), echoed
in the quiz.

**(5) CHECK LOGIC.** AUDIT identification + hardened rejection behavior:
```
assert_file_contains "answers.txt" '^line=5$'              "which line evaluates untrusted input as an arithmetic expression?"
assert_file_contains "answers.txt" '^flaw=arith-cmdsub$'   "name the flaw class (brief's slug list)"
assert_file_contains "answers.txt" '^fix=' "answers.txt"   # fix names numeric validation
assert_file_contains "answers.txt" '([0-9]-9\]|numeric|digit)' "the fix must reject non-numeric input before (( ))"
# hardened script must REJECT an injection payload and ACCEPT a number
assert_cmd_fails "hardened calc rejects a[\$(id)] injection" \
  "your numeric guard must refuse anything that isn't all digits" \
  -- bash -- hardened.sh 'a[$(id -u)]'
assert_output_contains "hardened calc doubles a real number" '^result=10$' \
  "a valid numeric input must still work: 5 -> result=10" \
  -- bash -- hardened.sh 5
ck_summary
```
(6 assertions. `check.sh` runs the **hardened** script only — its injection input
is inert because the guard rejects it before `(( ))`; even if it didn't, the
payload is `id`, read-only. CI fabrication: keys in `answers.txt` + copy reference
`hardened.sh`. Negative: use flawed `calc.sh` as `hardened.sh` → the reject-assert
fails, because flawed `calc.sh` would *run* the injection and not exit nonzero.)

**(6) QUIZ:**
1. choice — "`result=$(( n * 2 ))` with `n='a[$(cmd)]'`…" a) prints `0` and is
   safe b) **runs `cmd` — arithmetic re-evaluates `n`, and the array subscript is
   command-substituted** c) is a syntax error → **b**
2. choice — "The fix is to…" a) quote `"$n"` inside `(( ))` b) **validate `n` is
   all digits before it reaches `(( ))`; reject otherwise** c) use `let` instead of
   `$(( ))` → **b**
3. choice — "Did ShellCheck warn about this?" a) yes, loudly b) **no dedicated
   warning — arithmetic injection is a blind spot; a clean lint run is not proof of
   safety** c) it auto-fixed it → **b**

**(7) RECAP:**
```
$(( n )) and (( n )) evaluate their operand as an arithmetic EXPRESSION, and an array subscript inside it — a[$(cmd)] — command-substitutes: the cmd runs
so untrusted data in arithmetic is command injection; the fix is to validate it's all digits BEFORE the (( )), and reject anything else
ShellCheck has no warning for this — it's one of the blind spots that make "shellcheck-clean" necessary but not sufficient
```

---

### L3.6 — Subshells vs current shell — why `… | while read` eats your variables
**PREDICT · gate:false · est 12 · files/: counter.sh · recall.json: no**
**objective:** "Predict the value a variable holds after a `cmd | while read … done` loop versus a `while read … done < <(cmd)` loop, and explain that the pipeline runs its right-hand side in a subshell whose variable changes are lost."

**(2) TEACHING ARTIFACT — the exact script + the counterintuitive behavior to
predict** (`files/counter.sh`, a *working* PREDICT sample, no flawed header):
```bash
#!/usr/bin/env bash
# counter.sh — count three lines two ways. Predict each 'count=' BEFORE running.

count=0
printf 'x\ny\nz\n' | while read -r _; do
  count=$((count + 1))
done
echo "pipe:  count=$count"          # <-- PREDICT this

count=0
while read -r _; do
  count=$((count + 1))
done < <(printf 'x\ny\nz\n')
echo "procsub: count=$count"        # <-- PREDICT this
```
**The exact (counterintuitive) behavior to predict — verified at plan time:**
```
pipe:  count=0
procsub: count=3
```
The `cmd | while …` form runs the `while` loop in a **subshell** (the right side
of a pipe is a child process), so its `count` increments are discarded when the
subshell exits — the outer `count` stays `0`. The process-substitution form
(`< <(cmd)`) keeps the loop in the **current shell**, so `count` survives as `3`.
`predictions.txt`: `pipe=0`, `procsub=3`, plus a one-line `why=` naming the
subshell.

**(3) CONTAINMENT SPEC.** None — no destructive command; the script only counts
and prints. `predictions.txt` write stays in-workspace. State explicitly: **no
decoy, no fence.**

**(4) SHELLCHECK STATUS.** `files/counter.sh` is **clean-intent**. ShellCheck's
**SC2030/SC2031** ("modification of `count` is local to the subshell" / "`count`
was modified in a subshell; that change may be lost") is exactly this footgun and
**should fire on the pipe form** — [VERIFY-AT-BUILD]. Decision: this is the one
sample where the SC warning *is* the teaching point, so give it the
`# TEACHING SAMPLE` header (line 2) and list **SC2030, SC2031** in
`teaching_samples` (the lab text points the learner at reading that exact
warning — a bridge to L3.8). **Recommended:** ship with header +
`{"files/counter.sh": ["SC2030","SC2031"]}` [VERIFY-AT-BUILD].

**(5) CHECK LOGIC.** PREDICT — grade `predictions.txt` (written before running):
```
assert_file_contains "predictions.txt" '^pipe=0$' \
  "the pipe form's while loop runs in a SUBSHELL — what happens to count after it exits?"
assert_file_contains "predictions.txt" '^procsub=3$' \
  "the < <(cmd) form keeps the loop in the CURRENT shell — count survives"
assert_file_contains "predictions.txt" '^why=' \
  "one line: WHY does the pipe form lose the count? (name the subshell)"
assert_file_contains "predictions.txt" '(subshell|sub-shell|child)' \
  "the pipeline's right-hand side runs in a ___"
ck_summary
```
(4 assertions. PREDICT honor line in the brief: "the check can't tell whether you
predicted first — you're only cheating your own reps." CI fabrication:
`printf 'pipe=0\nprocsub=3\nwhy=the pipe runs the while in a subshell, so count changes are lost\n' > predictions.txt`. Negative: `pipe=3`.)

**(6) QUIZ:**
1. choice — "After `printf … | while read …; do n=$((n+1)); done`, the outer `n`
   is…" a) the loop count b) **unchanged — the loop ran in a subshell and its
   changes were discarded** c) undefined → **b**
2. choice — "To keep the count, rewrite as…" a) `for` over `$(cmd)` b) **`while
   read …; done < <(cmd)` — process substitution keeps the loop in the current
   shell** c) add `set -e` → **b**
3. choice — "The general rule:" a) pipes are slow b) **the right-hand side of a
   pipe runs in a subshell; variable assignments there don't reach the parent** c)
   `while` can't read → **b**

**(7) RECAP:**
```
the right-hand side of a pipe runs in a SUBSHELL, so cmd | while read … | any variable you set inside the loop is lost when it exits (count stays 0)
keep the loop in the current shell with process substitution: while read …; done < <(cmd)  → the variable survives (count=3)
ShellCheck SC2030/SC2031 flag exactly this "modified in a subshell, change may be lost" — a warning worth reading, not muting
```

---

### L3.7 — `eval` — why it's almost always the wrong answer
**AUDIT · gate:false · est 15 · files/: dispatch.sh, fence.sh, run-fenced.sh · recall.json: no**
**objective:** "Read a script that builds a command string and runs it with `eval`, show how untrusted input injects an arbitrary command, and rewrite it without `eval` (arrays / direct dispatch)."

**(2) TEACHING ARTIFACT.** The exact vulnerable script (`files/dispatch.sh`,
teaching-sample header line 2):
```bash
#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# dispatch.sh — look up a file's info; the "action" comes from the caller.
action=$1                             # UNTRUSTED (e.g. from a web form / filename)
target=$2
eval "$action \"$target\""            # eval re-parses the whole string as a command line
```
**The exact flaw:** line 5 (`eval "$action \"$target\""`). `eval` re-parses its
argument as shell source, so any shell metacharacter in `action` (or `target`)
becomes syntax: `action='ls'; target='f.txt; rm -rf ~'` runs the `rm`. **Verified
mechanism at plan time:** `input='file.txt; echo PWNED'; eval "ls $input"` executed
`echo PWNED`. **The exact fix:** don't build a command string — dispatch through a
`case` allowlist (or an array), invoking the command directly so data can't become
syntax. Reference hardened `hardened.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
action=$1
target=$2
case "$action" in
  stat) stat -- "$target" ;;          # direct invocation; "$target" is DATA, never re-parsed
  size) wc -c -- "$target" ;;
  type) file -- "$target" ;;
  *) echo "unknown action: $action" >&2; exit 2 ;;
esac
```

**(3) CONTAINMENT SPEC — Mechanism B (shadowed-`rm` fence) — MANDATORY.** The
injection can run `rm -rf`, so the demonstration is fenced. **What would be
destroyed:** whatever the injected command targets — the guided step uses the
classic `target='x; rm -rf $HOME'` to show real intent, but under the fence (`$HOME`
is redirected into the workspace by `ws_run_check`, and even a literal outside path
is refused fail-closed). **Where the danger is fenced:** `files/fence.sh` (§3.2) +
`run-fenced.sh` source the shim before running `dispatch.sh`, so any `rm` the
injection triggers is intercepted → `fence.log` records `FENCE-BLOCKED: …` and
nothing outside the workspace is deleted (proven §2). **How the check proves
nothing outside changed:** (a) the guided demonstration's `fence.log` shows the
blocked `rm`; (b) check.sh runs the learner's **hardened** `dispatch.sh` with an
injection-shaped `action` and asserts it is **rejected** by the `case` allowlist
(exit 2, no command built) — so no `rm` ever reaches the fence, asserted by an
empty `fence.log` on that run + `decoy_intact`; (c) build self-test pastes the
`ls`-count-unchanged evidence (proof obligation). Ship `fence.sh` + `run-fenced.sh`
identical to L3.2.

**(4) SHELLCHECK STATUS.** `files/dispatch.sh` — teaching sample. **Expected:
ShellCheck does NOT block `eval` with a dedicated "this is injectable" code** —
[VERIFY-AT-BUILD]. It may emit **SC2086** on unquoted expansion, or the newer
**SC2294** ("eval negates the benefit of arrays") in some forms, but there is no
"eval is dangerous, remove it" warning — another **blind spot** (reinforced in
L3.8: `eval` is the construct where you cannot lean on the linter). `meta.json.
teaching_samples = {"files/dispatch.sh": [<verified set>]}`.

**(5) CHECK LOGIC.** AUDIT identification + hardened allowlist behavior + fence
proof:
```
assert_file_contains "answers.txt" '^line=5$'             "which line re-parses untrusted input as a command line?"
assert_file_contains "answers.txt" '^flaw=eval-injection$' "name the flaw class (brief's slug list)"
assert_file_contains "answers.txt" '^fix=' "answers.txt"  # names case/allowlist/array, no eval
assert_file_not_contains "hardened.sh" '\beval\b' \
  "your rewrite must not use eval at all — dispatch directly"
# hardened dispatch rejects an unknown/injection action and runs a known one
: > fence.log
assert_cmd_fails "hardened dispatch rejects an injection-shaped action" \
  "the case allowlist must refuse anything that isn't a known verb" \
  -- bash -c 'source ./fence.sh; source ./hardened.sh' _ 'x; rm -rf /' /etc/hostname
assert_file_not_contains "fence.log" 'FENCE-BLOCKED' \
  "a correct allowlist never builds the rm — nothing should reach the fence"
assert_output_contains "hardened dispatch runs a known verb" 'size' \
  "the 'size' action should still work on an in-workspace file" \
  -- bash -c 'printf hi > f.txt; source ./hardened.sh' _ size f.txt
ck_summary
```
> BUILD note [VERIFY-AT-BUILD]: the `bash -c 'source ./hardened.sh' _ arg1 arg2`
> form sets `$1`/`$2` for the sourced script; verify the positional-arg passing on
> the build machine (the `_` fills `$0`). Alternative: `bash -- hardened.sh size
> f.txt` directly (simpler; use unless the fence must wrap it — for the
> rejection assert the fence wrap proves nothing reached `rm`).

(≈7 assertions. The `\beval\b` ERE needs `assert_file_not_contains` with an
anchored word boundary — confirm `eval` is not a lint-banned token *in files/*
(it is banned in check.sh, but `assert_file_not_contains "hardened.sh" '\beval\b'`
is a grep *pattern string* inside check.sh, not the token `eval` as code — **but
lint-labs bans the literal substring `eval` via `grep -qw eval`**, which WOULD
match the pattern string. **RESOLUTION:** write the check without the literal token
— assert the fix positively instead: `assert_file_contains "hardened.sh"
'case[[:space:]]' "dispatch through a case allowlist"` + `assert_file_contains
"hardened.sh" 'exit 2'`. Do **not** put the word `eval` anywhere in check.sh.)
CI fabrication: keys + copy reference hardened.sh + `printf hi > f.txt`. Negative:
flawed dispatch.sh as hardened.sh → the `case`/`exit 2` asserts fail.

**(6) QUIZ:**
1. choice — "`eval \"$action \\\"$target\\\"\"` with `action='ls; rm -rf ~'`…" a)
   prints an error b) **runs the `rm` — eval re-parses the whole string as shell
   source, so `;` starts a new command** c) treats it as one filename → **b**
2. choice — "The right rewrite is to…" a) quote harder inside eval b) **remove
   eval — dispatch through a `case`/array allowlist and invoke the command
   directly, so input stays data** c) use `eval` with `set -u` → **b**
3. choice — "Will ShellCheck stop you shipping an injectable eval?" a) yes b)
   **no dedicated block — eval is a construct you must audit yourself; the linter
   won't save you** c) it deletes the line → **b**

**(7) RECAP:**
```
eval re-parses its argument as shell source, so any metacharacter in untrusted input becomes syntax — action='x; rm -rf ~' runs the rm
the fix is almost never "quote it better" — it's to remove eval: dispatch through a case/array allowlist so data can't become a command
ShellCheck won't block an injectable eval for you; eval is the construct where the reviewer, not the linter, is the last line of defence
```

---

### L3.8 — ShellCheck as co-pilot — reading SC codes, which are security-critical
**GUIDED · gate:false · est 15 · files/: sample.sh (+ the phase's samples referenced) · recall.json: no**
**objective:** "Run ShellCheck on a flawed script, read each SC code it emits, and sort them into security-critical (fix before shipping) vs cosmetic (style) — and name the classes ShellCheck can't see at all."

**(2) TEACHING ARTIFACT — the exact SC codes to walk through, pre-classified.**
The lab ships one multi-flaw `files/sample.sh` (teaching-sample header) that
triggers a spread of codes, and the guided steps run `shellcheck -x -S style
sample.sh` and read the output line by line. `sample.sh` (composed to hit the
target codes — [VERIFY-AT-BUILD] the exact emitted set on 0.9.0):
```bash
#!/bin/sh
# TEACHING SAMPLE — intentionally flawed
# sample.sh — a grab-bag of ShellCheck triggers to read and classify.
dir=$1
rm -rf "$dir/"                 # SC2115  (security-critical: empty $dir -> rm -rf /)
cp $dir/*.log /backup          # SC2086  (security-critical: word-split/glob on untrusted path)
rm *                           # SC2035  (security-critical: a -rf filename becomes a flag)
files=`ls`                     # SC2006 (cosmetic: backticks) + SC2010/SC2012 (ls parsing, style)
echo "found: $files"           # SC2086 on $files (context-dependent)
if [ $# -gt 0 -a -n "$1" ]; then :; fi   # SC2166 (style: -a is legacy) + SC2086 on $#
unused=42                      # SC2034 (cosmetic: unused variable)
```
**The exact walk-through classification the lab teaches:**

| SC code | what it flags | class | why |
|---|---|---|---|
| **SC2115** | `rm -rf "$dir/"` can become `rm -rf /` | **SECURITY-CRITICAL** | the L3.2 catastrophe; fix with `${dir:?}` |
| **SC2086** | unquoted `$var`/`$(cmd)` word-splits & globs | **SECURITY-CRITICAL** | the L1.3/L3.1 bug; filename/space/injection surface |
| **SC2035** | `rm *` lets a `-rf` filename act as a flag | **SECURITY-CRITICAL** | the L3.4 attack; fix with `--`/`./` |
| **SC2068** | unquoted `${arr[@]}` | **SECURITY-CRITICAL** | array word-splitting (same family as SC2086) |
| **SC2048** | `$*` unquoted | **SECURITY-CRITICAL** | whitespace/splitting of all args |
| **SC2064** | `trap "…$x…" EXIT` expands too early | security-relevant | handler built from data can misfire |
| SC2166 | `[ … -a … ]` legacy operator | **cosmetic/portability** | prefer `[ … ] && [ … ]`; not exploitable |
| SC2006 | backticks vs `$( )` | **cosmetic** | readability/nesting only |
| SC2034 | unused variable | **cosmetic** | dead code, not a vuln |
| SC2012/SC2010 | parsing `ls` output | style/robustness | prefer globs; rarely a security bug |
| SC2148 | missing shebang | cosmetic | interpreter hint |
| SC1090/SC1091 | can't follow `source` | **informational (not a defect)** | expected for dynamic paths (our check.sh uses `# shellcheck source=` for exactly this) |

**And the classes ShellCheck CANNOT see (the blind spots, drawn from this phase):**
arithmetic command-sub injection (**L3.5** — no code), `eval` injection (**L3.7** —
no "remove eval" code), silent failure from a missing `set -euo pipefail`
(**P2/L2.8** — SC has no "you forgot strict mode" error), and logic bugs generally.
The lab's thesis: **shellcheck-clean is necessary but not sufficient.**

**(3) CONTAINMENT SPEC.** None — the lab only *runs shellcheck* (static analysis)
on samples; `sample.sh` is **never executed**. No decoy, no fence. (The `rm -rf`
lines are read, not run.) State this explicitly so BUILD does not add a needless
fence.

**(4) SHELLCHECK STATUS.** `files/sample.sh` — teaching sample; its whole purpose
is to emit codes. `meta.json.teaching_samples = {"files/sample.sh": [<the full
verified set>]}` — this list is itself the lesson content, so **[VERIFY-AT-BUILD]
and pin it exactly**; the guided steps quote the real output.

**(5) CHECK LOGIC.** GUIDED — grade `answers.txt` where the learner classifies
codes (this is the graded comprehension):
```
# The learner runs shellcheck themselves and classifies. Grade the classification.
assert_file_contains "answers.txt" '^sc2115=security$'  "SC2115 (rm -rf could hit /) — security-critical or cosmetic?"
assert_file_contains "answers.txt" '^sc2086=security$'  "SC2086 (unquoted var) — which class?"
assert_file_contains "answers.txt" '^sc2035=security$'  "SC2035 (dash-filename glob) — which class?"
assert_file_contains "answers.txt" '^sc2034=cosmetic$'  "SC2034 (unused variable) — security or cosmetic?"
assert_file_contains "answers.txt" '^sc2006=cosmetic$'  "SC2006 (backticks) — security or cosmetic?"
assert_file_contains "answers.txt" '^blindspot=' \
  "name ONE thing shellcheck cannot catch (eval injection, arithmetic injection, or missing strict mode)"
assert_file_contains "answers.txt" '(eval|arith|strict|pipefail|injection)' \
  "the blind spot must be a real one from this phase"
ck_summary
```
(7 assertions. No script executed by check.sh. CI fabrication:
`printf 'sc2115=security\nsc2086=security\nsc2035=security\nsc2034=cosmetic\nsc2006=cosmetic\nblindspot=eval injection\n' > answers.txt`. Negative: `sc2115=cosmetic`.)

**(6) QUIZ:**
1. choice — "Of SC2115, SC2034, SC2006 — which must you fix before shipping?" a)
   all b) **SC2115 — it's the `rm -rf /` catastrophe; the other two are cosmetic**
   c) none → **b**
2. choice — "A script that is 100% shellcheck-clean is…" a) proven safe b) **free
   of the bugs shellcheck knows — but eval injection, arithmetic injection, and
   missing strict mode are invisible to it** c) unrunnable → **b**
3. choice — "SC1090/SC1091 ('can't follow source') means…" a) a real bug b)
   **usually informational — the path is dynamic; it's not a defect (our own
   check.sh handles it with a `# shellcheck source=` directive)** c) the file is
   corrupt → **b**

**(7) RECAP:**
```
read SC codes by class, not count: SC2115/SC2086/SC2035/SC2068/SC2048 are security-critical (splitting, globbing, rm -rf /); SC2034/SC2006/SC2166 are cosmetic
shellcheck-clean is necessary, not sufficient — it cannot see eval injection (L3.7), arithmetic injection (L3.5), or a missing set -euo pipefail (L2.8)
SC1090/SC1091 "can't follow source" is informational, not a defect — dynamic source paths are normal (our own harness uses a shellcheck source= directive)
```

---

### L3.9 — Phase gate: one script, every footgun — find and harden them all
**TAME · gate:TRUE · est 20 · files/: deploy.sh, fence.sh, run-fenced.sh · recall.json: no (P4 opener drafted below)**
**objective:** "Prove the phase: take one realistic deploy/cleanup script that carries several Footgun-Gallery bugs at once, identify each, and harden the whole script so it is shellcheck-clean and safe under the fence."

Integration, nothing new — every bug is a callback to L3.1–L3.7. The gate is a
single script the learner audits *and* rewrites.

**(2) TEACHING ARTIFACT.** The exact multi-footgun script (`files/deploy.sh`,
teaching-sample header line 2) — each flawed line maps to one earlier lab:
```bash
#!/bin/sh
# TEACHING SAMPLE — intentionally flawed
# deploy.sh — clean the release dir, stage listed files, run a named build step.
REL=$1
rm -rf "$REL/"                          # (A) L3.2: empty REL -> rm -rf /
for f in $(cat manifest.txt); do        # (B) L3.1/L3.3: $(cat) word-splits; spaced names break
  cp $f "$REL"                          # (C) L3.1: unquoted $f
done
rm *.tmp                                 # (D) L3.4: a -rf.tmp name could flag rm
scale=$2
workers=$(( scale * 2 ))                 # (E) L3.5: untrusted scale -> arithmetic injection
eval "run_$3"                            # (F) L3.7: eval on an untrusted action name
echo deployed
```
The exact hardened reference `hardened.sh` (strict mode; every footgun closed;
shellcheck-clean — [VERIFY-AT-BUILD]):
```bash
#!/usr/bin/env bash
set -euo pipefail
REL=${1:?release dir required}
scale=${2:?scale required}
step=${3:?build step required}

case "$scale" in '' | *[!0-9]*) echo "scale must be numeric" >&2; exit 2 ;; esac

rm -rf "${REL:?}/"                       # (A) :? — never rm -rf /
while IFS= read -r f; do                 # (B) read lines, not split words
  [[ -n "$f" ]] || continue
  cp -- "$f" "$REL"/                     # (C) quoted + --
done < manifest.txt
rm -f -- ./*.tmp                         # (D) -- and ./ so a -rf.tmp can't flag rm
workers=$(( scale * 2 ))                 # (E) scale is validated numeric above
case "$step" in                          # (F) allowlist dispatch, no eval
  build) run_build ;;
  test)  run_test ;;
  *) echo "unknown step: $step" >&2; exit 2 ;;
esac
echo "deployed with $workers workers"
```
(`run_build`/`run_test` are stub functions the lab defines or the learner may
replace; the graded point is *no eval* + validated inputs + fenced rm.)

**(3) CONTAINMENT SPEC — BOTH mechanisms — MANDATORY.** This gate exercises the
whole containment story: **Mechanism B (fence)** for the `rm -rf "$REL/"` (A) and
the `eval` (F) — both can target outside the workspace — and **Mechanism A (decoy
tree)** for the file operations (B/C/D) that should really happen inside a decoy.
**What gets destroyed, where:** (i) the demonstration runs the *flawed* `deploy.sh`
with `REL` empty via `run-fenced.sh` → `rm -rf /` intercepted → `fence.log`:
`FENCE-BLOCKED: rm -rf /`, nothing outside touched; (ii) the learner's *hardened*
script runs against a `decoy-gate` tree with a valid `REL=decoy-gate/rel` →
real `rm -rf` and `cp` happen **inside the decoy only**. **How the check proves
nothing outside changed:** `fence.log` shows the flawed run was blocked; the
hardened run's rm/cp are confined to `decoy-gate/` (asserted via `decoy_*` +
`assert_file_exists` on the staged files); and running the hardened script with an
**empty** `REL` must abort before any rm (asserted by empty `fence.log` +
`decoy_intact` on a fresh decoy). Build self-test pastes the `ls /`-unchanged
evidence.

**(4) SHELLCHECK STATUS.** `files/deploy.sh` — teaching sample. Expected codes
(the union of the phase): **SC2115** (A), **SC2086** (C, and `$REL`/`$scale`
contexts), **SC2035** (D), the `for … $(cat)` warning (B), plus `#!/bin/sh`
portability notes — **[VERIFY-AT-BUILD] and pin the exact set**. The learner's
`hardened.sh` must be **shellcheck-clean** (verified for the reference).
`meta.json.teaching_samples = {"files/deploy.sh": [<full verified set>]}`.

**(5) CHECK LOGIC (`check.sh`).** The integrative grade — identification of all
six + a shellcheck-clean, fence-safe hardened rewrite:
```
# --- identification: name each footgun's line (answers.txt) ---
assert_file_contains "answers.txt" '^a_rmrf=5$'      "which line is the empty-var rm -rf catastrophe?"
assert_file_contains "answers.txt" '^b_split=6$'     "which line word-splits the manifest?"
assert_file_contains "answers.txt" '^c_unquoted=7$'  "which line copies with an unquoted \$f?"
assert_file_contains "answers.txt" '^d_dashname=9$'  "which line lets a -rf.tmp filename flag rm?"
assert_file_contains "answers.txt" '^e_arith=11$'    "which line runs arithmetic on untrusted input?"
assert_file_contains "answers.txt" '^f_eval=12$'     "which line evals an untrusted action?"
# --- hardened rewrite: strict mode, no eval, validated, fenced ---
assert_file_contains "hardened.sh" 'set -euo pipefail' "harden with the strict-mode preamble"
assert_file_contains "hardened.sh" '(:\?|\$\{[A-Za-z_]+:\?)' "REL must be :? guarded so it never becomes /"
assert_file_contains "hardened.sh" 'case '            "dispatch the build step through a case allowlist, not eval"
assert_file_not_contains "hardened.sh" 'run_\$'       "no dynamic command building — dispatch known steps directly"
# (do NOT grep for the literal 'eval' token in check.sh — lint bans it; assert the positive pattern above)
# --- fence proof: flawed run was blocked; hardened run with empty REL aborts before rm ---
assert_file_contains_fixed "fence.log" 'FENCE-BLOCKED: rm -rf /' \
  "run the flawed deploy.sh via run-fenced.sh with REL empty first — the fence must log the blocked rm -rf /"
make_decoy_tree gate
: > fence.log
assert_cmd_fails "hardened deploy aborts when REL is empty" \
  "your :? guard must stop the script before rm when REL is empty" \
  -- bash -c 'source ./fence.sh; source ./hardened.sh "" 4 build'
assert_file_not_contains "fence.log" 'FENCE-BLOCKED' \
  "the hardened script must abort before rm — nothing should reach the fence"
decoy_intact gate
# --- hardened run does its real work INSIDE a decoy ---
require_in_workspace "decoy-gate/rel"; mkdir -p "$REQ_PATH"
printf '%s\n' 'alpha.txt' > manifest.txt; : > alpha.txt
assert_cmd_ok "hardened deploy runs cleanly against an in-decoy release dir" \
  "with a valid REL inside the decoy, staging must succeed" \
  -- bash -c 'source ./fence.sh; source ./hardened.sh decoy-gate/rel 4 build'
assert_file_exists "decoy-gate/rel/alpha.txt" "the manifest file must be staged into the release dir"
ck_summary
```
> BUILD notes [VERIFY-AT-BUILD]: (1) `run_build`/`run_test` stubs — define them in
> `hardened.sh` (or have check.sh export no-op functions before sourcing) so the
> `build` step succeeds; pin the approach at build. (2) Confirm the `case ` and
> `run_\$` patterns match your final hardened text. (3) The `hardened.sh ""` /
> positional-arg passing via `source … "" 4 build` — verify positional passing to
> a sourced script on the build machine (or invoke `bash -- hardened.sh "" 4
> build` under a fence-wrapping parent). Keep the "no `eval` literal in check.sh"
> rule.

(≈16 assertions. CI fabrication: write all six `answers.txt` keys, copy reference
`hardened.sh`, `printf 'FENCE-BLOCKED: rm -rf /\n' > fence.log`, seed
`manifest.txt`+`alpha.txt`. Negative case (the FIX-appropriate one, per P2 gate
precedent): leave the shipped flawed `deploy.sh` as `hardened.sh` → the strict-mode,
`:?`, no-`run_$`, and fence-abort asserts all fail.)

**(6) QUIZ:**
1. choice — "The single most dangerous line in `deploy.sh` if `$1` is empty:" a)
   the `cp` b) **`rm -rf "$REL/"` — empty REL makes it `rm -rf /`** c) the `echo`
   → **b**
2. choice — "Hardening the `eval "run_$3"` line means…" a) quoting `$3` b)
   **replacing eval with a `case` allowlist that calls known steps directly** c)
   adding `set -u` → **b**
3. choice — "'Shellcheck-clean' for your hardened deploy.sh proves…" a) it's fully
   safe b) **the bugs shellcheck can see are gone — you still had to close the eval
   and arithmetic injections it can't see** c) nothing → **b**

**(7) RECAP:**
```
one real deploy script carried six footguns at once: empty-var rm -rf (L3.2), $(cat) word-split (L3.1/3.3), unquoted cp (L3.1), a -rf filename (L3.4), arithmetic injection (L3.5), eval (L3.7)
hardening is a fixed checklist: set -euo pipefail, ${VAR:?} on every path fed to rm, quote+-- every expansion, validate numerics, replace eval with a case allowlist
the proof is behavioral AND static: it runs safe under the fence (rm never escapes) and it's shellcheck-clean — necessary and sufficient only together with your own audit
```

---

## 7. ShellCheck code reference (pin these at build)

Security-critical (fix before shipping), each tied to a lab:
`SC2115` (L3.2 rm -rf /), `SC2086` (L3.1 unquoted split/glob), `SC2035` (L3.4
dash-filename), `SC2068` (unquoted array), `SC2048` (`$*`), `SC2064` (trap early
expansion), `SC2030`/`SC2031` (L3.6 subshell var loss — reading them is the skill).
Cosmetic/portability: `SC2034` (unused), `SC2006` (backticks), `SC2166` (`-a`/`-o`
in `[ ]`), `SC2012`/`SC2010` (ls parsing), `SC2148` (shebang), `SC1090`/`SC1091`
(can't follow source — informational). Blind spots (no SC code): arithmetic
command-sub injection (L3.5), `eval` injection (L3.7), missing `set -euo pipefail`
(L2.8). **All per-file `teaching_samples` sets are [VERIFY-AT-BUILD] on 0.9.0.**

---

## 8. Build-session protocol (execute in this order)

1. **Scaffold** the 9 lab dirs under `tracks/bash/phases/p3/` using these slugs:
   `L3.1-word-splitting-deep`, `L3.2-rm-rf-empty-var`, `L3.3-ifs`,
   `L3.4-filename-attacks`, `L3.5-arithmetic-injection`, `L3.6-subshell-var-loss`,
   `L3.7-eval`, `L3.8-shellcheck-copilot`, `L3.9-phase-gate-footguns`.
   `tracks/bash/track.json` already names p3 — do not touch it. Confirm the p3
   phase title matches the map ("The Footgun Gallery").
2. **Ship containment first (the DEPENDENCY).** Before authoring L3.2, create
   `files/fence.sh` and `files/run-fenced.sh` (§3.2) for L3.2/L3.7/L3.9 and
   **prove containment on the build machine**: run each flawed sample under the
   fence with the catastrophic input, capture `fence.log` showing `FENCE-BLOCKED`,
   and paste `ls / | wc -l` before/after to show the count unchanged. Only then
   author the footgun labs. (This is the gate PROMPTS.md §bash requires.)
3. **Author content straight from §6.** Base64 every quiz/recall answer
   (`printf '%s' 'answer' | base64 -w0`). Ship `recall.json` in L3.1 from §5.
   Give each flawed sample the `# TEACHING SAMPLE — intentionally flawed` header on
   **line 2** and a `teaching_samples` entry in `meta.json`.
4. **Self-test sweep (no-fiction rule).** Execute every `lab.md` command yourself
   and paste REAL captured output — never from memory or from this plan. Re-verify
   every **[VERIFY-AT-BUILD]** item: exact `shellcheck -x -S style` code sets per
   sample, exact stderr suffixes, exact `fence.log` lines, every exit code. Run
   each `check.sh` twice (wrong/incomplete → graded fail with a useful `look at:`
   hint; correct → pass). **Containment proof in the self-test for L3.2/L3.7/L3.9:
   run the footgun, show fence.log caught it and the real filesystem is
   unchanged.**
5. **Lint/shellcheck gates.** Every clean-intent `files/*.sh` (`hardened.sh`
   references, `fence.sh`, `run-fenced.sh`, `split-demo.sh` if shipped clean,
   `counter.sh` if shipped clean) → zero output from `shellcheck -x -S style`.
   Every teaching sample → exactly its `meta.json` codes. Then `./tools/lint-labs.sh`
   must pass clean. **Watch the two token traps:** (a) no `check.sh` may contain the
   literal word `eval` (lint bans it even as a grep pattern) — assert the positive
   fix instead (§6 L3.7/L3.9); (b) no absolute-path literals in `check.sh` (the
   `rm -rf /` strings live in `files/` samples and in `fence.log` assertion
   *patterns* — confirm the patterns don't trip the absolute-path lint; if
   `'FENCE-BLOCKED: rm -rf /'` as an `assert_file_contains_fixed` literal trips it,
   split the literal or match `'FENCE-BLOCKED: rm -rf'` without the trailing `/`).
6. **Acceptance.** Extend `tests/acceptance.sh` per the P2 pattern: for each lab,
   fabricate passing artifacts with bash+coreutils only (each entry's CI recipe),
   run `printf 'a\nb\nc\n' | lab check bash <id>` expecting pass, plus one negative
   case per lab (exit 1). For L3.1 (phase opener) drive `lab start bash L3.1` with
   5 piped recall answers and assert it never gates.
7. **Run the phase end-to-end manually once** (author's own `lab check` per lab,
   quiz typed), verify `lab status` renders p3 and `lab resume` works mid-phase,
   then draft **L4.1's `recall.json`** (P4 opener) while context is hot — 5
   spaced-recall questions sourced from P3 (candidates: L3.2 empty-var rm, L3.4
   dash-filename, L3.5 arithmetic injection, L3.6 subshell var-loss, L3.7 eval).
   Include the draft as a "FOR THE PHASE 4 BUILDER" block in the L3.9 entry, mirroring
   how P2's L2.8 handed L3.1's recall forward.
8. **Close out:** update `planned_execution.md` (mark bash p3 done with tag
   evidence, refresh NEXT UP/LAST SESSION), tag `bash-p3`, report against the
   PROMPTS.md PHASE ACCEPTANCE CHECKLIST. One phase per session.

---

## 9. Decisions & deviations log (for the reviewer)

- **NEW containment code — the shadowed-`rm` fence (`fence.sh`/`run-fenced.sh`) —
  APPROVED 2026-07-15.** The only new mechanism in the phase; everything else
  reuses the inherited decoy helpers. Rationale: L3.2/L3.7/L3.9 have `/`-targeting
  footguns a decoy cannot represent; a fail-closed `rm` shim is the minimal way to
  let the learner *see* the catastrophe get caught without risking data. Proven at
  plan time (§2). The decoy-only fallback was considered and declined.
- **AUDIT grading = `answers.txt` identification + hardened-behavior**, never
  detonating the flawed script inside `check.sh`. First AUDIT labs in the track;
  §4 defines the key grammar. No `cwe=` key in P3 (the map names CWEs starting in
  P4) — P3 uses `flaw=` slugs only, to avoid inventing ids.
- **L3.3 and L3.6 samples may need the teaching-sample header** even though they're
  "working demos," because the intentional unquoted split (SC2086) / subshell
  warning (SC2030/2031) is the lesson. Recommended: ship both with the header +
  the exact SC codes listed, so lint/shellcheck stay green. [VERIFY-AT-BUILD].
- **The `eval` literal is banned in `check.sh`** by `lint-labs.sh` (`grep -qw
  eval`). L3.7/L3.9 checks therefore assert the *positive* fix (a `case` allowlist,
  `exit 2`, absence of `run_$`) rather than grepping for the token `eval`. Called
  out in §6 and §8.5.
- **`fence.log` assertion literals containing `/`** may trip the absolute-path lint
  in `check.sh`; §8.5 gives the fallback (match `'FENCE-BLOCKED: rm -rf'` without
  the trailing `/`). [VERIFY-AT-BUILD].
- **est_minutes:** L3.1 15, L3.2 15, L3.3 12, L3.4 15, L3.5 15, L3.6 12, L3.7 15,
  L3.8 15, L3.9 20 → **135** total; all within the 10–20 ADHD band.
- **L3.1 recall.json** is adopted verbatim from the P2 build's forward draft
  (`bash-p2-plan.md:1482`), re-validated against Phase-2 recap cards on disk (§5).
- **P4 opener recall** is drafted in the L3.9 build step (§8.7), not this session —
  same forward-hand-off pattern P2 used.
