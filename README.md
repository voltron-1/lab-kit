# LAB-KIT

Terminal training tracks — rust, bash, soc — driven by one shared `lab`
CLI. Pure bash + jq. Built for Ubuntu 24.04 on WSL2.

## Quickstart — clone to first lab in 5 commands

    git clone <REPO_URL> lab-kit          # 1
    cd lab-kit                            # 2
    sudo apt-get install -y jq shellcheck # 3
    ./bin/lab start demo L0.0             # 4
    ./bin/lab check demo L0.0             # 5

Optional: `export PATH="$PWD/bin:$PATH"` to drop the `./bin/` prefix from
here on.

## The five commands

| command | what it does |
|---|---|
| `lab status` | all tracks, phase map: ✓ passed · ○ not done · ⏭ forced |
| `lab start [track] <id>` | prints the brief, provisions `workspace/<track>/<id>/` |
| `lab check [track] <id>` | grades: the lab's checks + a 3-question quiz — both must pass |
| `lab resume` | re-primes you after time away — replays your last passed lab's 3-line recap card, then names the next lab and its one-line brief. Read it in under 30 seconds and you're back in context. |
| `lab hint [track] <id>` | graduated hints — 3 levels, one per call, never the answer at level 1 |

`track` is optional whenever the lab id is unambiguous across installed
tracks (e.g. `lab start L0.0` works as long as only one installed track
has an `L0.0`).

## Rules of the road

- **Progression is linear per track.** `lab start` refuses a lab past the
  next unlocked one. `--force` is the escape hatch: it starts the lab you
  asked for, but permanently marks every lab you skipped over `⏭` in
  `lab status` — a forced-past lab can still be passed later, but it will
  never show `✓`.
- **Progress lives in `.progress.json`** at the repo root (local,
  gitignored). Every write goes to a temp file that is then renamed over
  the real file, so Ctrl-C at any moment during a `lab` command can never
  corrupt it.
- **Everything a lab does happens inside `workspace/<track>/<id>/`** — the
  fence. `lab start` provisions it; delete it any time and `lab start`
  rebuilds it. No lab, hint, or check reads or writes outside it.

## Layout

    bin/                  CLI entrypoint
    lib/                   CLI internals (state, catalog, workspace, quiz, hints, render)
    harness/checklib.sh     helpers every lab's check.sh sources
    tracks/<track>/phases/p<N>/<id>-<slug>/   lab content
    workspace/               yours — gitignored, rebuilt by `lab start`
    docs/curriculum/          the three binding curriculum maps

## Adding a track

Drop `tracks/<name>/` with a `track.json` (title, display order, phase
names) and `phases/p<N>/L<phase>.<n>-<slug>/` lab directories. No CLI
changes needed — `lab status` discovers new tracks and labs from the
filesystem the next time it runs.

## Development

Every check.sh and the harness itself must be shellcheck-clean:

    ./tools/shellcheck-all.sh

Lab content also has a structural lint (required files present,
quiz/hint counts, banned patterns in check.sh):

    ./tools/lint-labs.sh

Full bootstrap acceptance run (works against a throwaway copy — never
touches your real `.progress.json` or `workspace/`):

    ./tests/acceptance.sh
