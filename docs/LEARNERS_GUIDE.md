# Lab Companion — Learner's Guide

This is your walkthrough for actually working through lab-kit, day to day.
The [README](../README.md) is the quick-reference card; the
[curriculum maps](curriculum/) are what each track is teaching and why. This
guide is the missing middle: what to type, what you'll see, and what to do
when you get stuck.

If you only read one section, read [The Five Commands](#the-five-commands)
and [Anatomy of a Lab](#anatomy-of-a-lab) — everything else is detail.

---

## Before you start

You need `bash`, `jq`, and `shellcheck` on Ubuntu 24.04 (WSL2 is the target
platform, but any Linux with those three tools works).

    git clone <REPO_URL> lab-kit
    cd lab-kit
    sudo apt-get install -y jq shellcheck
    export PATH="$PWD/bin:$PATH"   # optional: drop the ./bin/ prefix below

Everything else — tracks, labs, evidence files — is already in the repo.
There's nothing to build.

---

## Your first five minutes

    lab start demo L0.0
    cd workspace/demo/L0.0
    # ...follow the GUIDED STEPS printed by `lab start`...
    lab check demo L0.0

`L0.0` — "Meet the Kit" — is a real lab that exists solely to walk you
through every mechanic below (workspace fence, hints, check, quiz, resume)
before you touch a real track. If you do nothing else, do this one first.

---

## How a session works

Run `lab` with no arguments and it drives the whole thing for you:

    $ lab
    Select a track
      1) demo   Demo Lab                 (0/1)
      2) rust   Rust Literacy Lab        (0/63)
      3) bash   Bash Literacy Lab        (0/54)
      4) soc    SOC Analyst Lab          (0/52)
      5) ps     PowerShell Literacy Lab  (0/54)
    track (number or name, q to quit) >

Pick a track. If you've made progress in it, you're asked:

    soc · SOC Analyst Lab   4/52
      last checkpoint  L3.3 — Anomalous process ancestry   (2026-08-08T22:46:53Z)

      1) Resume from last saved checkpoint   → L3.4 Persistence spots
      2) Start from the beginning            → L0.1 Analyst toolbelt

**"Start from the beginning" only moves where you start** — it does not erase
anything. Your `✓` passes and `⏭` skip marks are untouched, and the linear
unlock rule (below) still applies: the session will never hand you a lab
past your frontier.

From there you're in the lab loop: read the brief, do the work, run `check`,
reach for `hint` if you're stuck, and the session picks the next lab for
you — you never type a lab id yourself in session mode.

**Everything happens in this one terminal — you never need a second window.**
`files` (or `ls`) lists what's in `workspace/<track>/<id>/`; `show <file>`
prints one of those files right there; `edit <file>` opens it in `$EDITOR`
(or `vi` if you haven't set one) and hands control back to the session the
moment you save and quit. All three are confined to the current lab's
workspace, so a typo'd path is refused rather than reaching outside it.

    > files

    workspace/soc/L3.4/
      answers.template.txt
      persistence-legend.md
      root-crontab.txt
      web01-cron.log
      windows-persistence.json

    > show persistence-legend.md
    # Persistence Mechanisms
    - Run Key: Sysmon Event 13 ... -> runkey
    ...

    > edit answers.txt
    [your editor opens on that file; back at the prompt when you exit it]

Need to do something `show`/`edit` can't — install a package, run a tool
the lab points you at, anything without a single file behind it? Prefix it
with `!` and it runs for real, right there:

    > !sudo apt-get install -y jq tshark dnsutils whois ripgrep
    [runs like it would in any terminal; back at the prompt when it's done]

Unlike `files`/`show`/`edit`, `!` is **not confined to the workspace** —
it's a real shell command, running exactly what you type. Reach for it for
things `show`/`edit` have no path argument for; reach for `edit` when
you're just filling in one named file.

`lab session` runs the exact same flow if you want to type it explicitly.
Bare `lab` in a script or CI (no terminal on stdin) just prints usage — it
won't hang waiting for input.

---

## The Five Commands

The session above is a thin driver over these; you can also run them
directly at any time.

| Command | What it does |
|---|---|
| `lab status` | Every track's phase map: `✓` passed · `○` not done · `⏭` forced. Your progress bar. |
| `lab start [track] <id>` | Prints the brief and guided steps, provisions `workspace/<track>/<id>/`. |
| `lab check [track] <id>` | Grades the lab: the check script *and* a 3-question quiz. Both must pass. |
| `lab resume` | Re-primes you after time away — replays your last passed lab's recap, names the next lab. |
| `lab hint [track] <id>` | Three graduated hints. Level 1 never gives away the answer. |

`track` is optional whenever the id alone is unambiguous — `lab start L0.0`
works if only one installed track has an `L0.0`. Add the track name if the
CLI complains it's ambiguous.

---

## Anatomy of a lab

Every lab — in every track — is built the same way:

1. **BRIEF** — ten lines or fewer of context. No outside reading required,
   ever. `lab start` prints it.
2. **GUIDED STEPS** — a terminal follow-along, commands and expected output
   shown explicitly, like a hands-on exercise sheet. You work these inside
   `workspace/<track>/<id>/` — the **fence**. Nothing you do there can touch
   anything outside it, and no lab reaches outside its own workspace either.
3. **`lab check`** — runs the lab's grading script against what's in your
   workspace, then asks you a 3-question quiz. You need both to pass.
4. **A recap** — three lines, no more, of what the lab actually taught you.
   `lab resume` replays the most recent one so you can pick back up cold.

A lab's `meta.json` also tells you its `est_minutes` (a rough time budget)
and whether it's a `gate` lab (a checkpoint the track treats as a hard
milestone). Neither changes how you work the lab — they're just signal for
pacing yourself.

**Workspace isolation** means deleting `workspace/<track>/<id>/` and running
`lab start` again gives you a completely clean slate for that lab — useful
if you've made a mess you don't want to untangle by hand.

---

## Hints

`lab hint <track> <id>` gives you one of three escalating levels each time
you run it:

1. **Level 1** points you at *where* to look — it never gives away the
   answer.
2. **Level 2** narrows it to the specific command or concept you're missing.
3. **Level 3** is close to spelling it out, for when you're genuinely stuck.

Hints cost you nothing mechanically — they don't block a pass or cost
points — so there's no reason to grind against a wall. Reach for level 1
early; you don't have to "earn" your way there by struggling first.

---

## Quizzes

`lab check` always ends with three questions pulled from `quiz.json` —
active recall on what the lab just taught, not busywork. Two question
styles show up:

- **Multiple choice** — pick `a`, `b`, or `c`.
- **Short text** — type the answer; minor formatting differences (case,
  a couple of accepted spellings) are tolerated, but it's checking for the
  actual right term, not free text.

A failed quiz doesn't erase your lab work — fix your answers and re-run
`lab check`. The check script and quiz both have to pass in the *same* run
for the lab to be marked `✓`.

---

## Progress & status marks

`lab status` marks every lab one of three ways:

- **`✓` passed** — check script and quiz both passed at least once.
- **`○` not done** — untouched, or attempted but not yet passing.
- **`⏭` forced** — you jumped past this lab with `--force`. This mark is
  **permanent** — even if you go back and pass the lab later, it stays
  `⏭` in the record. It's an honest trail of what you skipped, not a
  todo list.

**Linear progression** is the rule underneath all of this: `lab start`
only lets you open a lab at or before your **frontier** — the first lab
in the track you haven't completed yet. Anything further ahead is refused
unless you pass `--force`, which also permanently marks every not-yet-done
lab it skips over as `⏭`. Revisiting an already-passed lab is always free.

Everything is saved to `.progress.json` at the repo root (local only,
gitignored) with atomic writes — an interrupted `Ctrl-C` mid-check can
never corrupt your progress file.

---

## Resuming after time away

`lab resume` is built for "it's been a week, remind me where I was":

    $ lab resume
    last passed  soc L3.3 — Anomalous process ancestry   (2026-08-08T22:46:53Z)

      recap
      · ✓/○/⏭ mark passed/todo/forced in lab status; ⏭ never becomes ✓
      · all lab work happens inside workspace/<track>/<id>/ — the fence
      · lab check = check.sh + quiz; state saved atomically to .progress.json

    next up      soc L3.4 — Persistence spots   (GUIDED, ~15 min)
                 <one-line objective for L3.4>
                 lab start soc L3.4

It replays the three-line recap of your last pass and tells you exactly
what to run next — no digging through old terminal scrollback required.

---

## Picking a track

All four tracks share the same mechanics above; they differ in subject and
in what "doing the work" means.

| Track | Labs | Phases | What you're training |
|---|---|---|---|
| **rust** — Rust Literacy | 63 | Toolchain → Reading Basic Rust → Ownership/Borrowing/Lifetimes → Types/Traits/Errors → Security-Critical Rust → Concurrency & Async → Reading Real Security Tools → Directing & Auditing AI Rust | Reading and auditing Rust, and directing AI to write safe Rust — not authoring programs from scratch. |
| **bash** — Bash Literacy | 54 | Toolchain → The Expansion Model → Control Flow & Silent Failure → The Footgun Gallery → Untrusted Input & Injection → Text Processing & Pipelines → Reading Real Deploy Scripts → Directing & Auditing AI Bash | Reading any line and knowing exactly what the shell will run; spotting quoting/injection footguns on sight. |
| **soc** — SOC Analyst | 52 | Toolbelt → How Attacks Become Alerts → Network Triage → Endpoint Triage → Triage Craft & the Queue → Phishing & Malware Triage → Investigation & Escalation → The AI-Assisted Analyst | Hands-on Tier 1 triage against real-format evidence (logs, PCAPs, phishing email, alert queues) — this is the one "doing," not just "reading," track. |
| **ps** — PowerShell Literacy | 54 | Toolchain → The Object Pipeline → Control Flow/Errors/Modules → The Windows Integration Layer → PowerShell as Attack Surface → Deobfuscation & Malware Reading → Reading Real Security Tools → Directing & Auditing AI PowerShell | Reading PowerShell's object pipeline and Windows-internals surface; deobfuscating attacker payloads on sight. |

Every track opens with a short `p0` (3 labs) that just gets your toolchain
and the kit itself running before the real content starts. Full detail on
each track's design and rationale lives in
[`docs/curriculum/`](curriculum/).

---

## Getting unstuck

Work through these in order before you consider a lab "broken":

1. **Re-read the BRIEF and GUIDED STEPS.** `lab start <track> <id>` reprints
   them if you've scrolled past.
2. **`ls` your workspace and compare it against the steps.** Most check
   failures are a missing or misnamed file, not a logic error.
3. **Pull a hint.** `lab hint <track> <id>` — level 1 costs you nothing and
   usually points straight at what's missing.
4. **Diff against what the check script actually wants**, if you're
   comfortable reading shell — `check.sh` in your lab's directory names
   every assertion it's grading.
5. **If you're directing an AI to help**, ask it to *explain* what's wrong
   rather than hand you a fix to paste in — every track's endgame phase is
   specifically about being able to judge AI output, and that muscle only
   grows if you keep reading.

If a check still seems wrong after all of that, it may genuinely be a bug —
see [`CONTRIBUTING.md`](../CONTRIBUTING.md) for how the project wants that
reported.

---

## FAQ

**`lab start L2.3` says the id is ambiguous — what do I do?**
More than one installed track has that id. Add the track name:
`lab start bash L2.3`.

**I deleted my workspace by accident — did I lose my progress?**
No. Progress lives in `.progress.json` at the repo root, not in the
workspace. `lab start <track> <id>` again rebuilds the workspace from
scratch; your pass/fail history is untouched.

**Can I skip ahead to a lab that looks more interesting?**
Yes, with `lab start <track> <id> --force` — but every not-yet-completed
lab it jumps over is permanently marked `⏭`, even if you later go back and
pass it. Use it when you mean it, not to browse.

**`lab` printed usage instead of the interactive menu — why?**
Bare `lab` only opens the interactive session when it's run from an actual
terminal. In a script, a pipe, or CI, it prints usage instead so it never
hangs waiting for input you can't give it. Use the five commands directly
in those contexts.

**Where do I go to understand *why* a track is structured the way it is,**
**not just how to run it?**
[`docs/curriculum/`](curriculum/) — one curriculum map per track, written
for the "why," where this guide is written for the "how."
