# LAB-KIT — Kit Contracts (frozen at bootstrap, 2026-07-12)

Reference for anyone building a track phase. The three curriculum maps in
`docs/curriculum/` are the binding *content* spec; this document is the
binding *mechanical* spec — the CLI/harness contracts every phase's
content must fit. Where a future phase seems to need a deviation, propose
it explicitly rather than silently working around these contracts (per
the Phase Builder protocol in `PROMPTS.md`).

## Lab content layout

    tracks/<track>/phases/p<N>/L<phase>.<n>-<slug>/
      meta.json     # {id, title, type, objective, gate: bool, est_minutes}
      lab.md        # "## BRIEF" (<=10 lines) + "## GUIDED STEPS" — exact headings, lint-enforced
      quiz.json      # exactly 3 questions, see schema below
      check.sh        # grader, sourced-helpers contract below, mode 0644
      hints.json       # exactly 3 escalating levels; level 1 never gives the answer
      recap.md          # exactly 3 lines, no bullet prefix (the renderer adds "· ")
      files/             # optional — copied into the workspace on `lab start`
      recall.json        # ONLY on the first lab of a phase (lowest <n> in that p<N>)

`meta.json.id` must equal the directory's id (`catalog_lint_lab` checks
this — it's a deliberate redundancy that catches copy-paste drift during
authoring). Track name grammar: `^[a-z][a-z0-9_-]*$`. Lab id grammar:
`^L<phase>\.<n>$`, numeric on both components (`L2.10` sorts after
`L2.9` — never lexical). A `tracks/<track>/track.json` is optional but
recommended: `{title, tagline, order, phases: {"p0": "Phase Name", ...}}`
— presentation only, every field has a filesystem/dirname fallback.

## State (`.progress.json`, schema v1)

One flat file, keyed `"<track>/<id>"`. Absence of a key = never touched.
Per-lab record: `{status: "in_progress"|"passed"|null, skipped: bool,
attempts, hints_used, started_at, first_passed_at, last_attempt_at}`.
`events[]` is an append-only log of pass events (`{seq, type, track, id,
at, recap}`) — the source of truth for `lab resume`.

**The only code that ever reads or writes this file is `lib/state.sh`.**
Every write goes through `state_apply`: a same-directory `mktemp`, a
jq transform piped from the current state, a shape-validation pass, then
`mv -f` (atomic rename). No code path ever opens the real file for
writing directly, so a SIGINT/SIGTERM at any point either leaves the real
file completely untouched (before the rename) or fully installed (after
it) — never partial. Each command writes state **once, at the very end**
(`start`, `check`) or not at all (`status`, `resume`, refusals).

`completed(lab) := status == "passed" OR skipped == true`. `frontier(track)
:= first lab in track order that is not completed`. `lab start <id>` is
allowed without `--force` iff the lab's position is at or before the
frontier (i.e. it's the frontier itself, or an already-completed lab —
revisiting is always free). Anything past the frontier is refused, naming
the frontier lab, unless `--force`.

**`--force` semantics (skip-marking):** every not-yet-completed lab
*strictly before* the target gets permanently marked `skipped: true`
(renders `⏭` forever, even if later passed — sticky, never cleared). The
lab you actually forced *into* is a normal lab and can still earn `✓`.
Progression then continues linearly from there — no repeated forcing
needed for subsequent labs, only for the ones you actually skipped.
`--force` on a lab that wasn't locked is a no-op (no lock was bypassed).

## Check execution (the fence)

`lab check` runs `check.sh` as a **separate process** (never sourced),
cwd pinned to `workspace/<track>/<id>/`, launched via `env -i` with a
fixed allowlist: `PATH=/usr/local/bin:/usr/bin:/bin`, `LANG=C.UTF-8`,
`TERM` (passthrough, default `dumb`), `HOME=<workspace>/.home`,
`TMPDIR=<workspace>/.tmp`, `LAB_WORKSPACE`, `LAB_CHECKLIB`, `LAB_TRACK`,
`LAB_ID`. Bounded by `timeout --kill-after=5s 120s`; stdin is `/dev/null`
so a grader can never eat a piped quiz answer. Exit codes: `0` pass, `1`
graded failure, `70` harness/content bug, `124` timeout, `>=128`
interrupted.

**There is no OS sandbox** (no containers/chroot/bwrap in this
environment) — the fence is process separation + cwd + the `env -i`
allowlist + HOME/TMPDIR redirection + the realpath-canonicalizing path
guards in `harness/checklib.sh`. It stops accidental out-of-fence
reads/writes in first-party lab content; it does **not** stop a
check.sh that hardcodes an absolute path and calls coreutils directly.
`tools/lint-labs.sh` is the compensating control (bans absolute-path
literals and dangerous tokens in every committed check.sh) — every
check.sh must pass it. **Destructive teaching labs (the bash track's
`rm -rf` / IFS / filename-attack labs) must always target
`make_decoy_tree` output, never a real path** — that helper, plus
`decoy_intact`/`decoy_changed`, already ship in `harness/checklib.sh`.

`check.sh` template:

    #!/usr/bin/env bash
    set -euo pipefail
    : "${LAB_WORKSPACE:?run this via: lab check <track> <id>}"
    : "${LAB_CHECKLIB:?run this via: lab check <track> <id>}"
    # shellcheck source=/dev/null
    source "$LAB_CHECKLIB"

    assert_file_exists "path" "hint shown on failure"
    # ... more assertions ...
    ck_summary   # must be the LAST line — prints the tally and exits 0/1

Helper inventory (all path arguments realpath-guarded to the workspace):
`assert_file_exists`, `assert_file_missing`, `assert_dir_exists`,
`assert_file_contains` (ERE), `assert_file_contains_fixed` (literal),
`assert_file_not_contains`, `assert_cmd_ok "desc" "hint" -- cmd args...`,
`assert_cmd_fails`, `assert_output_contains "desc" pattern "hint" -- cmd
args...`, `make_decoy_tree`, `decoy_intact`, `decoy_changed`,
`harness_err` (immediate exit 70 — a harness/authoring bug, not a graded
failure). This is a **collect-all** grader: assertions never abort the
script; a learner sees every problem in one run, and `ck_summary` is the
only call allowed to exit nonzero.

## Quiz / recall

`quiz.json` — exactly 3 questions:

    { "questions": [
      { "id": 1, "type": "choice", "prompt": "...",
        "options": {"a": "...", "b": "...", "c": "..."},
        "answer_b64": "..." },
      { "id": 2, "type": "text", "prompt": "...",
        "answer_b64": "...", "accept_b64": ["..."], "case_sensitive": false }
    ] }

`recall.json` — same shape plus a `"source"` field per question, exactly
5 questions, **only on the first lab of a phase** (drawn from *earlier*
phases per the curriculum maps' spaced-recall contract). Answers are
base64 purely to stop casual `cat`-spoiling — never treat it as real
secrecy. Encode with `printf '%s' 'answer' | base64 -w0`.

I/O contract: plain `IFS= read -r` from stdin, **no `/dev/tty`**, exactly
one line per question, no reprompting — this is what makes
`printf 'a\nb\nc\n' | lab check <track> <id>` behave identically to
typing, which is how every acceptance/self-test drives the quiz. Text
answers are normalized (lowercased, trimmed, whitespace-collapsed) unless
`case_sensitive: true`. Grading is end-of-run only: a verdict line names
missed question numbers (`missed Q1, Q3`) and **never** the correct
answer. `quiz_run` gates `lab check` (3/3 required); `recall_run` runs at
`lab start` on phase-openers and is **non-gating** (score + `review:`
pointers only, threshold is informational at ≥4/5 — it never blocks
`lab start`).

## Shellcheck-zero

`./tools/shellcheck-all.sh` is the single definition of "clean" — sweeps
`bin/lab harness/*.sh tools/*.sh tracks/*/phases/*/*/check.sh` via
`git ls-files`, default check set (`shellcheck -x -S style`, no
`--enable=`), skipping any file carrying a `# TEACHING SAMPLE —
intentionally flawed` header. `lib/*.sh` is intentionally not swept as a
second, independent target: those files are only ever sourced, and
`bin/lab`'s static `# shellcheck source=` directives already pull them
into its own `-x` analysis — checking them again standalone makes
shellcheck flag their shared globals as unused, since it can't see the
sibling file that consumes them. `# shellcheck disable=` is banned
repo-wide — use the `: "${VAR:?message}"` guard pattern for dynamic
values like `LAB_WORKSPACE`/`LAB_CHECKLIB` instead (it both validates at
runtime and reads as a reference, so SC2154 never fires). Sourced libs
(`lib/*.sh`, `harness/checklib.sh`) carry no shebang and never call
`set` themselves — only executables (`bin/lab`, `tools/*.sh`, every
`check.sh`) do.

Known `set -e` traps to avoid in any new bash: never `((x++))` as a
standalone statement (use `x=$((x + 1))`); always `IFS= read -r v ||
v=""` so EOF degrades gracefully instead of killing the script; never
capture a function's output via `$(fn ...)` if that function might call
`exit` on a real error — the `exit` only kills the subshell created by
the command substitution, not the calling script (see
`require_in_workspace` in `harness/checklib.sh` for the pattern: set a
global result variable instead of printing-and-capturing).

## Rendering

Marks: `✓` passed, `▶` in progress, `○` not done, `⏭` skipped (permanent,
precedence: skipped beats passed beats in-progress). Colors are ANSI,
gated on `[[ -t 1 ]] && -z NO_COLOR && LAB_COLOR != 0`; layout and wording
never change between a tty and a pipe.
