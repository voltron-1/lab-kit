# SOC Analyst Lab — browser version

`docs/site/soc.html` is the whole `tracks/soc` track (52 labs, 8 phases, about 15 hours) as a
single generated HTML file. No framework, no CDN, no server: open it from disk.

## Open it

    xdg-open docs/site/soc.html        # or double-click it, or drag it into a browser

(GitHub Pages can serve it once Pages is enabled from `main` at `/docs`; see `planned_execution.md`.)

## Rebuild it

    ./tools/build-site.sh              # rewrites docs/site/soc.html
    ./tools/build-site.sh --check      # exit 1 if the committed page is stale (CI runs this)
    ./tools/build-site.sh --data-only out.json   # the JSON bundle alone

Needs `bash` and `jq`. With `tshark` installed the pcap evidence gets a decoded text view; without it
the build falls back to a hex dump. The sources are `docs/site/src/{index.html,app.js,style.css}`;
edit those, never `soc.html`. Verify with `bash tests/site.sh`.

## How it stays in sync with the labs

The build runs each lab's real `check.sh` once, with `harness/checklib-record.sh` standing in for
`harness/checklib.sh`. Instead of grading, every `assert_*` call appends one JSON line describing
the assertion. The page replays those assertions in JavaScript (`app.js`, `Grader`), with the
lab's own text normaliser (`tr | sed` pipeline) re-implemented per lab. Quiz grading mirrors
`lib/quiz.sh`; the progress store mirrors `lib/state.sh`. Change a lab, rebuild, and the page
follows. Nothing in `tracks/`, `lib/` or `harness/checklib.sh` is touched.

## What a lab looks like

- **Your task** line under the title: the files to produce (or the answer file and its line count) and
  which guided step to start at. Install-only and `cd` steps are folded because they do not apply here.
- **Guided steps** with a **run** button on every command block. Run executes the block in the terminal
  and shows the output right under it.
- **Terminal**: a simulated shell on the lab's own files (see below).
- **Evidence** viewer, then **Workspace**: one box per graded file, each with the guided step(s) that
  produce it, a run button, and an optional "Fill from expected output".
- **Check**: the grader and quiz. `lab check soc <id>` typed in the terminal does the same thing.

## The simulated terminal

Authored as ordered parts in `docs/site/src/term/` and inlined by the build. It is a real shell
language, not a lookup table: pipes, `> >> <  2>&1`, `&& || ;`, `$VAR`, `$(...)`, globs, `{ ...; }`,
`for`/`while`/`if`. Commands: `ls cat head tail wc cp mv rm mkdir touch find file sha256sum base64 xxd`,
`grep rg sed awk cut tr sort uniq column nl diff xargs`, `jq` (full filter language), `tshark` (a pcap
dissector: `-r -Y -T fields -e -z follow,tcp,ascii,N`), and `lab check|hint|status`. `dig` and `whois`
print their version only (no network). Files the terminal writes into a graded name appear in that
Workspace box, and the other way round.

`tests/site-term.mjs` runs every fenced bash block in all 52 `lab.md` files, plus about 180 extra commands,
in real bash and in the page shell and requires identical stdout, exit status and written files (against
both gawk and mawk). It also replays the labs' own commands and requires the tool-output checks to pass.

## What it does and does not do

- **Terminal first, still.** The page terminal is an emulation: it covers the commands above and says so
  plainly when something is outside them (`python3` only emulates the L2.6 timestamp snippet). The
  terminal kit stays the primary path; the page is a second way in and a preview.
- **Keys are visible.** The answers the grader checks are in the page data, exactly as they are in
  each `check.sh`, and a failing check prints the expected literal as `checklib.sh` does. The page
  leaks nothing the repo does not already show.
- **Unlock rule.** Linear. The first lab that is neither passed nor skipped is the frontier (▶).
  Skipping asks for confirmation and marks ⏭.
- **Keyboard.** `c` check, `h` hint, `n` next lab, `/` focus the filter (when not typing in a box).
  Terminal: Enter runs (or continues an open quote), Up/Down history, Tab completes, Ctrl+L clears.

## Progress

Stored in the browser under `labkit.soc.progress.v1` (theme under `labkit.soc.theme`, unsent
workspace text under `labkit.soc.drafts.v1`). The progress document is the same
`.progress.json` v1 that `lib/state.sh` writes: `{version, created_at, updated_at, labs, events}`
keyed `soc/<id>`. **Export** downloads it as `progress.json`; **Import** accepts any document that
passes the check `state_apply` makes (`version == 1`, `labs` object, `events` array). Copying a
CLI `.progress.json` in, or an exported one back to the repo root, works in both directions.

## Build notes

Decisions taken during the unattended build, recorded here instead of asked:

- **Branch.** Work went to the session's designated branch `claude/hopeful-gates-axjlqj`, not the
  `claude/hopeful-keller-bc3avf` named in the plan.
- **Recording runs need stubs.** About 40 graders run `tr < answers.txt` unguarded and abort when the
  file is missing, which would drop every later assertion. The build seeds an empty stub (`q1=` ..
  `q9=`) for each file a grader redirects from, so the recording always reaches the last assertion.
- **Escaping.** The plan's `<!--` escape (`<\!--`) is not valid JSON. The build uses `<!--`;
  `</` is escaped as `<\/` as planned.
- **Magic labels** come from a built-in first-bytes table, not `file(1)`, so the page is
  byte-identical across machines (`file` output varies by version).
- **tshark renderings and `--check`.** A different tshark release prints different text. When the
  local tshark is missing or differs from the one recorded in the committed page, `--check` reuses
  the committed pcap renderings instead of reporting a false stale page.
- **Templates.** A template is only hidden from the evidence list when a graded file claims it as its
  prefill. `report.md` takes `report-template.md`, else the single `*template*.md`, so L6.4's
  `ticket-template.md` and L6.6's `escalation-template.md` prefill `report.md`. L6.5's
  `handoff-template.md` is claimed by nothing and stays in evidence.
- **Grader test inputs.** `files/model-*.md` are style examples, not answer keys (they fail the
  real graders), so `tests/site-grader.mjs` synthesizes report answers from the assertions like it
  does for every other lab.
- **Commits.** Steps 3 to 6 are one commit: the page is one `app.js`, so shell, lab view, grader and
  export/import cannot be split after the fact.
- **Terminal output formats.** `ls` sorts like a UTF-8 locale and `rg` prints the heading format only
  when its output is the terminal, as the real tools do. `file` uses a short built-in label table.
- **Directions.** Per-file directions are matched by file name against the numbered guided steps, so a
  lab that never names a graded file in its steps shows only the generic "what to write here" note.
- **No fallbacks were needed** for tshark, `file`, empty assertions or the Playwright smoke test.
