# LAB-KIT

Terminal training tracks — **rust, bash, soc, ps** — driven by one shared `lab` CLI. Pure bash + jq. Built for Ubuntu 24.04 on WSL2.

**223 total labs across 4 complete tracks (Phases 0–7):**
- **Rust Literacy (`rust`)** — 63 labs: ownership, borrowing, lifetimes, traits, memory safety, concurrency, async/await.
- **Bash Literacy (`bash`)** — 54 labs: POSIX shell, pipelines, text processing, control flow, system automation.
- **SOC Analyst (`soc`)** — 52 labs: attack-to-alert pipeline, network/endpoint triage, phishing, incident investigation, AI-assisted verification.
- **PowerShell Literacy (`ps`)** — 54 labs: object pipeline, WMI/CIM, registry, security features, deobfuscation, attack surface analysis.

---

## Quickstart — clone to first lab in 5 commands

    git clone <REPO_URL> lab-kit          # 1
    cd lab-kit                            # 2
    sudo apt-get install -y jq shellcheck # 3
    ./bin/lab start demo L0.0             # 4
    ./bin/lab check demo L0.0             # 5

Optional: `export PATH="$PWD/bin:$PATH"` to drop the `./bin/` prefix from here on.

---

## Starting a session

Run `lab` with no arguments and it walks you in:

    $ lab
    Select a track
      1) demo   Demo Lab                 (0/1)
      2) rust   Rust Literacy Lab        (0/63)
      ...
    track (number or name, q to quit) > 4

    soc · SOC Analyst Lab   4/52
      last checkpoint  L3.3 — Anomalous process ancestry   (2026-08-08T22:46:53Z)

      1) Resume from last saved checkpoint   → L3.4 Persistence spots
      2) Start from the beginning            → L0.1 Analyst toolbelt
         (moves where you start; your ✓ passes and ⏭ marks are kept)

From there the session opens the lab and you drive it with `check`, `hint`,
`brief`, `skip` and `quit` — it picks the next lab for you, so you never type a
lab id. **Start from the beginning moves the pointer only**: nothing in
`.progress.json` is erased, and the linear unlock rule still applies (the
session never hands you a lab past the frontier — `skip` is the only way past
one, and it marks `⏭` permanently, exactly like `lab start --force`).

`lab session` does the same thing explicitly. With no terminal on stdin (a
script, a pipe, CI) bare `lab` prints usage instead, as it always did.

---

## The Five Commands

| Command | Description |
|---|---|
| `lab status` | Displays progress across all tracks and phase maps (`✓` passed · `○` not done · `⏭` forced). |
| `lab start [track] <id>` | Prints the brief and provisions `workspace/<track>/<id>/`. |
| `lab check [track] <id>` | Grades the lab check script + 3-question quiz (both must pass). |
| `lab resume` | Re-primes context after time away — replays last passed lab recap card and names next lab. |
| `lab hint [track] <id>` | Provides 3 levels of graduated hints (level 1 never gives away the answer). |

`track` is optional whenever the lab ID is unambiguous across installed tracks (e.g., `lab start L0.0` works if only one track has `L0.0`).

---

## Rules of the Road

- **Linear Progression:** `lab start` unlocks labs sequentially per track. `--force` allows skipping ahead, but permanently marks skipped labs as `⏭` in `lab status`.
- **Atomic State Storage:** Progress is saved atomically in `.progress.json` at the repo root (local, gitignored).
- **Workspace Isolation:** All lab work takes place inside `workspace/<track>/<id>/`. `lab start` provisions it; deleting it resets the workspace. No harness script reads or writes outside the workspace fence.

---

## Repository Layout

    bin/                  CLI entrypoint
    lib/                   CLI internals (state, catalog, workspace, quiz, hints, render)
    harness/checklib.sh     helpers every lab's check.sh sources
    tracks/<track>/phases/  lab content across phases (p0-p7)
    workspace/               user working directory (gitignored, rebuilt by `lab start`)
    docs/curriculum/          curriculum maps and specifications

---

## Adding a Track

Drop `tracks/<name>/` with a `track.json` (title, display order, phase names) and `phases/p<N>/L<phase>.<n>-<slug>/` lab directories. No CLI changes needed — `lab status` automatically discovers new tracks and labs from the filesystem.

---

## Quality Assurance & Development

All check scripts, CLI internals, and lab metadata undergo strict quality control:

- **ShellCheck Linting:**
  ```bash
  ./tools/shellcheck-all.sh
  ```
- **Structural Lab Linting:**
  ```bash
  ./tools/lint-labs.sh
  ```
- **Full Acceptance Test Suite:**
  ```bash
  bash tests/acceptance.sh
  ```
- **Interactive Session Suite** (drives the menus on a pty via `script`):
  ```bash
  bash tests/session.sh
  ```
- **SOC Evidence Verification** (only needed when authoring or regenerating SOC
  evidence — requires `python3` with `PyYAML`, plus `tshark` for the pcap/zeek
  cross-check):
  ```bash
  sudo apt-get install -y python3-yaml tshark
  python3 tools/genevidence/verify.py
  ```
  It validates the universe entities in `tools/genevidence/universe.yaml`, the
  `cm-` event-id format across every SOC lab, that a zeek `uid` describes the
  same connection everywhere it appears in a bundle, and that each pcap agrees
  with the zeek logs shipped beside it.

---

## Framework & Quality Gates

- **Automated CI Gates:** Continuous Integration via GitHub Actions ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) runs `PSScriptAnalyzer` for PowerShell, `Clippy` for Rust, and `ShellCheck` for Bash.
- **MITRE ATT&CK® Mapping:** Security-relevant lessons across the PowerShell and SOC Analyst tracks are mapped to MITRE ATT&CK techniques in [`docs/ATTACK_MAPPING.md`](docs/ATTACK_MAPPING.md).
- **Content Review Framework:** Offense-adjacent lessons follow strict defensive framing, payload sanitization, and static evaluation rules documented in [`docs/CONTENT_REVIEW_CHECKLIST.md`](docs/CONTENT_REVIEW_CHECKLIST.md).
- **Contributor Guidelines:** See [`CONTRIBUTING.md`](CONTRIBUTING.md) for full contribution guardrails and quality standards.
