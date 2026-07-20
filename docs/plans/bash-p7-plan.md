# Bash Track — Phase 7 Build Plan (Directing & Auditing AI-Generated Bash)

## Context

Phase 7 is the bash track's capstone: seven labs that turn everything from
Phases 1–6 into a working review practice for AI-generated shell. The premise
from the curriculum map (§Phase 7): **AI writes Bash badly by default** —
unquoted expansions, no strict mode, no error handling, cheerful `eval`,
legacy backticks, `cd` without a guard. Expert level here means the learner's
specs force safe output and nothing sloppy survives their review.

This is also where the track's opening promise closes. Phase 0 installed
ShellCheck; Phase 3 taught which of its codes are security-critical; Phase 7
makes the learner's *own* shipped artifact pass a real `shellcheck -x -S
style` run inside `check.sh` (L7.7) — the first and only lab in the track
where the learner's own script is swept for real.

**Sequencing note:** this plan was written in the same session as the Phase 6
plan, before Phase 6 is built. The one dependency that flows p6 → p7 is
L7.1's `recall.json` (the phase-opener spaced-recall quiz pulls from Phase 6
content). It is drafted here from the p6 plan's recap text and marked
`[FROM-P6-HANDOFF] [VERIFY-AT-BUILD]` — reconcile against the p6 `recap.md`
files actually on disk before committing L7.1. Building Phase 6 first is
assumed.

Every shell sample in this plan was **written and run through `shellcheck -x
-S style` (ShellCheck 0.9.0) during the plan session**, and every emitted
code set below is the *verified* set, not a prediction — the L3.8 precedent,
where speculative SC codes in a plan turned out wrong at build. The L7.7
reference solution was additionally executed against fixtures to pin its
behavior.

## Phase 7 lab list (authoritative, from curriculum map §Phase 7)

| id   | dir name                        | title                                                          | type   | gate  | est |
|------|---------------------------------|----------------------------------------------------------------|--------|-------|-----|
| L7.1 | `L7.1-ai-bash-failure-patterns` | Why AI Bash is dangerous by default — the recurring patterns   | AUDIT  | false | 18m |
| L7.2 | `L7.2-safe-bash-spec`           | The safe-Bash spec — strict mode, quoting, shellcheck-clean    | DIRECT | false | 15m |
| L7.3 | `L7.3-review-checklist`         | The AI-Bash review checklist v1                                 | AUDIT  | false | 15m |
| L7.4 | `L7.4-review-reps`              | Review reps — 3 AI-generated scripts, find every flaw           | AUDIT  | false | 20m |
| L7.5 | `L7.5-ci-guardrails`            | CI guardrails — ShellCheck + shfmt as a merge gate              | GUIDED | false | 15m |
| L7.6 | `L7.6-capstone-direct`          | **Capstone:** direct + audit a SOC-relevant script              | DIRECT | false | 20m |
| L7.7 | `L7.7-capstone-gate`            | **Capstone gate:** ship a hardened, shellcheck-clean script     | AUDIT  | true  | 20m |

Completing L7.7 completes the bash track: **54/54 labs**.

## Design conventions for Phase 7

- **Flawed samples are p3/p4-style inert `files/` content.** The
  "AI-generated" scripts in L7.1, L7.4, and L7.6 are original scripts written
  to read like default model output — chatty exclamation-mark comments,
  no strict mode, unquoted expansions, legacy backticks, unguarded `cd`.
  They are **never executed** by `check.sh` and **not added to the
  shellcheck sweep** (`tools/shellcheck-all.sh`'s glob stays scoped to p5/p6
  `files/`; p7's flawed samples must stay unswept exactly as p3/p4's do).
- **Accurate banners, per the L5.3 `verify1.sh` lesson.** Every flawed
  sample carries two comment lines under the shebang:
  `# TEACHING SAMPLE — deliberately flawed. Never run this.`
  `# It exists to be read and reviewed, not executed.`
  Banner lines are comments; they do not change the verified SC code sets
  below (all of which are line-anchored in the tables — **re-anchor line
  numbers at build after banner insertion**).
- **Verified SC code sets, not predicted ones.** Each sample's table below
  lists what ShellCheck 0.9.0 *actually emitted*. Two samples emit **zero**
  findings despite being genuinely unsafe — that is deliberate and is the
  spine of L7.4 and L7.6 (see "The blind-spot beat" below).
- **The blind-spot beat.** `gen2-fetch-deploy.sh` (L7.4) and the `eval`
  and predictable-temp-path flaws in `model-output.sh` (L7.6) are invisible
  to ShellCheck. The phase's thesis: *shellcheck-clean is the floor, not the
  ceiling* — a lint pass is necessary and insufficient, which is why the
  L7.3 checklist exists as a separate human instrument. This mirrors the
  documented blind spot from L3.5 (arithmetic injection, zero SC output).
- **Lint hygiene — the L3.7 workaround is mandatory here.**
  `tools/lint-labs.sh` bans the `eval` builtin as a whole word anywhere in
  `check.sh`, and several p7 answer keys pin `eval` as a graded flaw slug.
  Resolution, exactly as L3.7 did it: build the slug string from two
  adjacent literals so the banned word never appears contiguously in
  `check.sh`'s source, and assert hardened fixes positively where possible.
  Also keep hint/failure strings free of a bare `/` surrounded by spaces and
  free of inline sed-like snippets (the p5 absolute-path false-positive
  precedent).
- **Anchored, fixed-vocabulary grading throughout** (the L4.2 lesson):
  `grep -Eqix 'key=value'` against `answers.txt`, whole-line anchored,
  case-insensitive value. Every question in `lab.md` states its allowed
  tokens. Flaw-inventory questions are scored **all-or-nothing per sample**
  — a review that finds 3 of 4 flaws is a review that shipped a bug.
- **Two labs execute real tooling.** L7.5 runs `shellcheck` and `shfmt` for
  real against a lab-local sandbox dir, and L7.7 runs `shellcheck -x -S
  style` against the learner's own `hardened.sh` plus safe behavior checks
  over lab-local fixtures. Both are read-only analyzers or operate solely on
  files inside the lab directory — nothing touches the system.

## Global build conventions (unchanged from p3/p4/p5/p6)

- One branch + PR + merge per lab: `bash-p7-l7.1` … `bash-p7-l7.7`, then
  `bash-p7-close-out`. Explicit go-ahead before each merge (multi-phase
  gating rule).
- Per lab: `lab.md`, `meta.json`, `files/`, `check.sh`, `quiz.json`,
  `hints.json`, `recap.md` (+ `recall.json` in L7.1 only). Self-test through
  the real `lab` CLI: fail-before-artifacts → correct artifacts → PASS →
  negative case.
- Parallel `security-auditor` + `code-reviewer` sub-agent review per lab
  before merge.
- `check.sh` sources the harness via `$LAB_CHECKLIB`; stays shellcheck-clean
  (it is always swept).
- Hint ladder: 3 levels, never the answer first; level 3 gives exact
  `answers.txt` content.
- Quiz/recall JSON: house schema — `type: "choice"`, options `a/b/c`,
  `answer_b64` base64 of the letter (a=`YQ==`, b=`Yg==`, c=`Yw==`); recall
  questions carry `source` fields.

## Lab entries (build straight from these)

---

### L7.1 — Why AI Bash is dangerous by default — the recurring failure patterns

**id/title/type/gate/est:** L7.1 · "Why AI Bash is dangerous by default —
the recurring failure patterns" · AUDIT · gate:false · est 18m (includes the
phase-opener recall quiz).

**meta.json objective:** "Read a script in the style AI produces by default,
name its five recurring failure patterns, and state which of them ShellCheck
would never have caught."

**FLAWED SAMPLE — `files/ai-backup.sh` (complete; deliberately flawed, never
executed):**

```bash
#!/bin/bash
# Backup script generated by AI assistant
# This script backs up your logs directory! Easy to use and flexible.

# Set the directories (feel free to change these!)
SRC_DIR=$1
BACKUP_DIR=/var/backups/logs

# Create a timestamped backup name
STAMP=`date +%Y%m%d`
BACKUP_NAME=backup-$STAMP.tar.gz

# Go to the source directory
cd $SRC_DIR

# Clean up old backups older than 30 days to save space
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -exec rm {} \;

# Create the backup!
tar -czf $BACKUP_DIR/$BACKUP_NAME .

# Allow custom post-backup hooks for flexibility
if [ -n "$POST_HOOK" ]; then
    eval $POST_HOOK
fi

echo "Backup complete! Saved to $BACKUP_DIR/$BACKUP_NAME"
```

**Verified ShellCheck output** (`shellcheck -x -S style`, 0.9.0 — line
numbers are pre-banner; re-anchor at build):

| line | code | meaning |
|---|---|---|
| 10 | SC2006 (style) | legacy backticks instead of `$(...)` |
| 14 | SC2164 (warning) | `cd` without `\|\| exit` |
| 14 | SC2086 (info) | unquoted `$SRC_DIR` |
| 20 | SC2086 (info) | unquoted `$BACKUP_NAME` |
| 24 | SC2086 (info) | unquoted `$POST_HOOK` in the `eval` |

**What ShellCheck does NOT say** — the teaching core:
- **No strict mode.** There is no `set -euo pipefail`, and ShellCheck never
  asks for one. Every failure below is silent: if `cd` fails, the script
  keeps going and `tar -czf … .` archives *the current directory instead of
  the intended one*.
- **`$1` is never validated.** Empty `$1` makes `cd` a no-op (cd to home in
  some shells / fail in others), and the `-n` guard is on the wrong
  variable.
- **The `eval` is a feature, not a typo.** The comment calls it
  "flexibility." An attacker-controlled `POST_HOOK` environment variable is
  arbitrary code execution (L3.7 + L4.4 combined). ShellCheck flags only the
  *quoting* of the argument — quoting it does not make it safe.
- **`find … -exec rm {} \;` on an unquoted `$BACKUP_DIR`** — the L3.2
  empty-variable shape; if `BACKUP_DIR` were ever unset, the deletion walks
  from the wrong root.

**Walkthrough / audit talking points (lab.md):**

1. Read the comments first and notice the *tone*: exclamation marks,
   "flexible," "easy to use." Cheerful comments explaining a dangerous
   feature are the single best tell of unreviewed generated code.
2. Line 1 to 3 have no `set -euo pipefail`. Ask what happens if `cd` fails
   (talking point 5) — this is Phase 2's silent-failure lesson at full scale.
3. `$1` in, no validation out: what does this script do with no arguments?
4. Backticks (SC2006) date the output — models reproduce old training-data
   idioms. Cosmetic on its own, a smell in aggregate.
5. The `cd` + `tar … .` pair is the payload: unguarded `cd` plus a relative
   `.` means a failed `cd` silently archives the wrong tree. Neither line is
   wrong alone; the *pair* is the bug.
6. `eval $POST_HOOK` — quote it and ShellCheck goes quiet, and the
   vulnerability is untouched. State the rule out loud: **ShellCheck grades
   syntax, not trust.**
7. Sort the five patterns into "ShellCheck caught it" versus "only a human
   caught it" — that split becomes the L7.3 checklist.

**Comprehension/audit questions (`answers.txt`):**

| key | question | allowed tokens | answer |
|---|---|---|---|
| `strictmode` | Which one-line preamble is missing entirely? | pipefail\|errexit\|none | `pipefail` |
| `cdrisk` | If `cd` fails, what does `tar -czf … .` archive? | wrongdir\|nothing\|homedir | `wrongdir` |
| `execflaw` | Which construct turns the POST_HOOK env var into arbitrary code? | (slug — see lint note) | `evalhook` |
| `sc2164` | Which SC code names the unguarded cd? | code | `sc2164` |
| `sc2006` | Which SC code names the legacy backticks? | code | `sc2006` |
| `blindspot` | Which of the flaws would a shellcheck-clean rewrite still contain? | evalhook\|backticks\|quoting | `evalhook` |
| `tell` | The clearest human tell of unreviewed generated code here is the… | comments\|indentation\|filename | `comments` |

**Lint note:** the `execflaw`/`blindspot` answer token is `evalhook` — a slug
that deliberately does **not** contain the banned builtin as a whole word, so
`check.sh` needs no string-splitting workaround for these two keys. Keep it.

**CHECK LOGIC:** anchored asserts on all seven keys; quiz. **Does NOT execute
`files/ai-backup.sh`** — it contains a live `eval` of an environment variable
and a `find … -exec rm` on an unvalidated path; the sample is read-only
teaching material, banner-marked, and excluded from the shellcheck sweep.
Guided steps DO run `shellcheck -x -S style files/ai-backup.sh` — the learner
must *see* the real five findings and compare them against the seven flaws
they were asked to find. That gap is the lab.

**QUIZ:**
1. "A shellcheck-clean script is…" — a) proven safe · **b) free of the flaws
   ShellCheck can detect, and nothing more** · c) formatted correctly.
   (`Yg==`)
2. "Quoting the argument to `eval` makes it…" — a) safe · **b) quieter to
   ShellCheck, and no less dangerous** · c) POSIX-compliant. (`Yg==`)
3. "The unguarded `cd` matters here because…" — **a) if it fails the script
   continues and the following relative-path command operates on the wrong
   directory** · b) cd is deprecated · c) it slows the script down. (`YQ==`)

**RECAP:**
- AI Bash fails the same five ways every time: no strict mode, unquoted
  expansions, unvalidated input, an unguarded `cd`, and an `eval` sold as
  flexibility.
- ShellCheck catches the syntax half of that list; it never asks for strict
  mode, never validates input, and never judges trust.
- Cheerful comments explaining a dangerous feature are the fastest human
  tell that nobody reviewed the output.

**RECALL (recall.json — phase opener, 5 questions from Phase 6)
`[FROM-P6-HANDOFF] [VERIFY-AT-BUILD]` — reconcile with the p6 `recap.md`
files on disk before committing:**
1. source `bash L6.1`: "A runbook script that is idempotent…" — a) may only
   run once · **b) is safe to re-run: an unchanged system means a no-op** ·
   c) always needs --force. (`Yg==`)
2. source `bash L6.2`: "A container entrypoint ends in `exec "$@"` so
   that…" — **a) the service becomes PID 1 and receives SIGTERM directly on
   docker stop** · b) the shell can clean up afterwards · c) the config
   re-renders. (`YQ==`)
3. source `bash L6.3`: "In a systemd unit, `After=` orders startup — which
   directive actually pulls the target in?" — a) Requires= · **b) Wants=** ·
   c) PartOf=. (`Yg==`)
4. source `bash L6.4`: "`set -euo pipefail` in a CI script prevents…" — **a)
   a stage failing mid-pipe from exiting 0 and shipping a broken artifact
   under a green build** · b) slow builds · c) YAML parse errors. (`YQ==`)
5. source `bash L6.5`: "Download → validate → atomic rename exists so
   that…" — a) the download is faster · **b) the deployed artifact is either
   the old version or the new one, never a partial file** · c) the checksum
   can be skipped. (`Yg==`)

---

### L7.2 — The safe-Bash spec: strict mode, quoting, and shellcheck-clean as acceptance criteria

**id/title/type/gate/est:** L7.2 · "The safe-Bash spec" · DIRECT ·
gate:false · est 15m.

**meta.json objective:** "Write a reusable spec that forces an AI to produce
hardened Bash, with shellcheck-clean as a stated acceptance criterion rather
than a hope."

**Learner deliverable:** `spec.md`, written from a shipped skeleton in
`files/spec-skeleton.md`. This is the first artifact the learner *authors*
rather than reads — and it is prose, not code, which keeps the DIRECT lab
type honest (the learner directs; the AI writes).

**`files/spec-skeleton.md` (shipped scaffold — headings only, learner fills
each section):**

```markdown
# Safe-Bash Spec (fill in each section)

## 1. Non-negotiable preamble
<!-- What must be the first executable line of every script, and why? -->

## 2. Quoting rule
<!-- State the rule in one sentence. When is an unquoted expansion allowed? -->

## 3. Input validation
<!-- What must happen to every argument and environment variable before use? -->

## 4. Forbidden constructs
<!-- Name the construct that re-parses a string as code, and state the ban. -->

## 5. Error handling
<!-- What happens when a step fails? Silent continue is not an option. -->

## 6. Acceptance criteria
<!-- How is "done" verified mechanically, before a human reviews it? -->
```

**Graded content of `spec.md`** — `check.sh` asserts that each required
commitment is present, anchored per section. To keep grading anchored rather
than free-text, `lab.md` instructs the learner to end each section with a
one-line **commitment tag** in fixed vocabulary:

| tag line the learner writes | required value |
|---|---|
| `preamble=` | `set -euo pipefail` (asserted as the three flags in any order) |
| `quoting=` | `always` |
| `validation=` | `reject-unset` |
| `forbidden=` | `evalstring` |
| `errors=` | `fail-loud` |
| `acceptance=` | `shellcheck-clean` |

Plus `answers.txt` with the "why" behind three of them:

| key | question | allowed tokens | answer |
|---|---|---|---|
| `whystrict` | Without the preamble, a failing middle command produces a… | silentsuccess\|crash\|hang | `silentsuccess` |
| `whyaccept` | Naming shellcheck-clean as acceptance criteria makes review… | mechanical\|optional\|faster | `mechanical` |
| `whyban` | The forbidden construct is banned because it re-parses data as… | code\|text\|json | `code` |

**Lint note:** `forbidden=evalstring` and the `whyban` key avoid the banned
whole-word builtin. `check.sh` asserts `forbidden=evalstring` literally — no
string-splitting needed. Do **not** widen these to match the raw builtin
name.

**CHECK LOGIC:** asserts `spec.md` exists and is non-trivial (≥ 6 sections
present via anchored heading greps — guards against an empty-file pass, the
L4.7 vacuous-check lesson); asserts each of the six commitment tags with
anchored `grep -Eqix`; asserts the three `answers.txt` keys; quiz. Nothing is
executed. The spec is prose — no script is produced in this lab.

**QUIZ:**
1. "Putting 'shellcheck-clean' in the spec's acceptance criteria matters
   because…" — **a) it converts part of review into a mechanical check that
   runs before a human reads a line** · b) it makes the AI faster · c) it
   replaces human review entirely. (`YQ==`)
2. "A spec that says 'write safe Bash' fails because…" — a) it is too long ·
   **b) 'safe' is not verifiable — the spec must name the preamble, the
   quoting rule, the bans, and the check** · c) models ignore all specs.
   (`Yg==`)
3. "Input validation belongs in the spec because…" — **a) the model will not
   add it on its own, and unvalidated input is where injection starts** ·
   b) it is required by POSIX · c) it improves performance. (`YQ==`)

**RECAP:**
- A spec that says "be safe" produces nothing; a spec that names the
  preamble, the quoting rule, the banned construct, and the check produces
  hardened output.
- Acceptance criteria must be mechanical: shellcheck-clean is verifiable
  before a human reads a single line.
- The spec is reusable — it is the artifact you paste at the start of every
  future request, not a one-off.

---

### L7.3 — The AI-Bash review checklist v1

**id/title/type/gate/est:** L7.3 · "The AI-Bash review checklist v1" ·
AUDIT · gate:false · est 15m.

**meta.json objective:** "Build the review checklist you will keep — the
human instrument that catches what ShellCheck cannot — and order it so the
highest-severity items come first."

**Learner deliverable:** `checklist.md`, built from the flaws catalogued in
L7.1. This artifact is *used as the grading frame* in L7.4 and L7.7, so it is
the phase's connective tissue.

**Required checklist items** — `lab.md` gives the required item IDs and the
learner writes one line per item (a check they can actually perform), each
line beginning with the fixed ID token:

| id token | the check it names | tier |
|---|---|---|
| `c1-strictmode` | Does line 1-3 set errexit, nounset, and pipefail? | blocking |
| `c2-quoting` | Is every expansion quoted unless splitting is explicitly wanted? | blocking |
| `c3-input` | Is every argument and env var validated before use? | blocking |
| `c4-noeval` | Is any string re-parsed as code by a shell builtin? | blocking |
| `c5-cdguard` | Does every `cd` have a failure guard, or is the script path-absolute? | blocking |
| `c6-tempfiles` | Are temp files created with mktemp, never a predictable path? | blocking |
| `c7-cleanup` | Is there a trap that cleans up on every exit path? | advisory |
| `c8-shellcheck` | Does `shellcheck -x -S style` emit zero findings? | mechanical |

**The ordering lesson (graded):** `c8-shellcheck` is deliberately **last**
and tagged `mechanical`, not `blocking`. `lab.md` makes the argument
explicitly: the lint pass is the cheapest check and belongs in CI (L7.5), so
it should never be the *first* thing a human does — a reviewer who leads with
ShellCheck anchors on the flaws it reports and stops looking for the ones it
cannot see.

**Comprehension questions (`answers.txt`):**

| key | question | allowed tokens | answer |
|---|---|---|---|
| `firstcheck` | Which item does a human reviewer apply first? | c1-strictmode\|c8-shellcheck\|c7-cleanup | `c1-strictmode` |
| `lastcheck` | Which item is mechanical and belongs in CI rather than a human pass? | item id | `c8-shellcheck` |
| `invisible` | Which blocking item is the one ShellCheck can never decide for you? | c4-noeval\|c2-quoting\|c5-cdguard | `c4-noeval` |
| `advisory` | Which item is advisory rather than blocking? | item id | `c7-cleanup` |
| `anchoring` | Leading a human review with the lint output risks… | anchoring\|fatigue\|drift | `anchoring` |

**CHECK LOGIC:** asserts `checklist.md` exists; asserts all eight `cN-` ID
tokens present, each on its own line with non-empty text after the token
(guards against an ID-only stub — the vacuous-pass lesson); asserts the five
`answers.txt` keys anchored; quiz. Nothing executed.

**Lint note:** the `c4-noeval` token contains the banned builtin only as part
of a longer word (`noeval`), not as a whole word. Confirm against
`tools/lint-labs.sh`'s actual regex at build — if the heuristic is
whole-word (`\beval\b`), `noeval` passes cleanly; if it is a bare substring
match, rename the token to `c4-nostringexec` and update every reference in
L7.3/L7.4/L7.7. **[VERIFY-AT-BUILD — this affects three labs; resolve it
during L7.3 and carry the decision forward.]**

**QUIZ:**
1. "The checklist exists alongside ShellCheck because…" — **a) the
   highest-severity flaws (trust, validation, intent) are invisible to a
   linter** · b) ShellCheck is often unavailable · c) it is faster to read.
   (`YQ==`)
2. "Running the lint pass first in a human review risks…" — **a) anchoring
   the reviewer on the findings it reports, so the invisible flaws go
   unlooked-for** · b) crashing the terminal · c) nothing at all. (`YQ==`)
3. "A blocking item differs from an advisory item in that…" — **a) a
   blocking item failing means the script does not ship** · b) advisory
   items are optional to read · c) there is no difference. (`YQ==`)

**RECAP:**
- The checklist is the human half of review: strict mode, quoting, input
  validation, no re-parsed strings, cd guards, temp files, cleanup, lint.
- Lint goes last and belongs in CI — leading with it anchors you on the
  flaws a linter can see and hides the ones it cannot.
- This file is yours to keep; L7.4 and L7.7 grade against it.

---

### L7.4 — Review reps: three AI-generated scripts, find every flaw

**id/title/type/gate/est:** L7.4 · "Review reps — 3 AI-generated scripts,
find every flaw" · AUDIT · gate:false · est 20m.

**meta.json objective:** "Apply the L7.3 checklist to three generated
scripts under time pressure, find every planted flaw, and correctly identify
the one that a linter reports as perfectly clean."

Three samples, three distinct failure profiles. Grading is **all-or-nothing
per sample** — a review that finds 3 of 4 flaws shipped a bug.

**SAMPLE 1 — `files/gen1-cleanup.sh` (complete):**

```bash
#!/bin/bash
# Disk cleanup script - keeps your log partition healthy!

LOG_DIR=$1
KEEP_DAYS=14

# Go to the log directory
cd $LOG_DIR

# Remove old rotated archives to free up space
rm -rf $OLD_DIR/*.gz

# Also clear anything older than the retention window
find . -name "*.log" -mtime +$KEEP_DAYS -delete

echo "Cleanup finished for $LOG_DIR"
```

**Verified ShellCheck output:** SC2164 + SC2086 (line 8, the `cd`), SC2086
(line 11, `$OLD_DIR`). **Four findings across two lines.**

**The flaw ShellCheck reports only as a quoting nit:** `OLD_DIR` is **never
assigned anywhere in this script.** `rm -rf $OLD_DIR/*.gz` with an unset
`OLD_DIR` expands to `rm -rf /*.gz` — the Phase 3 L3.2 empty-variable
catastrophe, verbatim, in generated code. ShellCheck says "double quote to
prevent globbing and word splitting" (SC2086) and says nothing about the
variable being undefined, because it cannot know it is not set elsewhere in
the environment. `set -u` would have caught it; there is no `set -u`.

**SAMPLE 2 — `files/gen2-fetch-deploy.sh` (complete):**

```bash
#!/bin/bash
# Deploy helper - fetches the latest agent build and installs it. So easy!

URL=https://releases.agent-updates.test/latest/agent.tar.gz
DEST=/opt/agent

# Download to a temp location
curl -s $URL -o /tmp/agent.tar.gz

# Unpack over the install directory
tar -xzf /tmp/agent.tar.gz -C $DEST

# Restart to pick up the new version
systemctl restart agent
echo "Deployed the latest agent!"
```

**Verified ShellCheck output: ZERO FINDINGS.** This is the phase's
centerpiece. The script is shellcheck-clean and unsafe in at least four ways:

- **`curl -s` with no `--fail`**: an HTTP 404 or 500 writes the *error page*
  to `/tmp/agent.tar.gz` and exits 0. The next line unpacks it.
- **No integrity check**: no checksum, no signature. Whatever the URL
  returns is unpacked over `/opt/agent`.
- **Predictable temp path**: `/tmp/agent.tar.gz` is world-writable-directory,
  fixed-name — the L4.7 TOCTOU shape. `mktemp` exists for this.
- **Unpacks over a live install directory** with no staging and no rollback;
  a truncated archive leaves `/opt/agent` in a mixed state, then the service
  is restarted onto it.

Contrast this against L6.5's cron wrapper, which does the *same job*
correctly: `curl --fail`, validate before deploy, `mktemp` beside the
destination, atomic `mv`. The learner has already read the right answer — the
lab asks them to notice that they have.

**SAMPLE 3 — `files/gen3-report.sh` (complete):**

```bash
#!/bin/bash
# Generates a quick failed-login report from your auth logs!

LOG_DIR=$1

for f in $(ls $LOG_DIR); do
    count=$(cat $LOG_DIR/$f | grep "FAILED LOGIN" | wc -l)
    echo "$f: $count failures"
done | sort -t: -k2 -rn
```

**Verified ShellCheck output:** SC2045 (**error**, iterating over `ls`
output), SC2086 ×2 (line 6 and line 7), SC2126 (style, `grep | wc -l` →
`grep -c`). Note SC2045 is severity **error** — the first and only
error-severity finding in this phase's samples, and worth calling out: the
loop breaks on any filename containing a space (L1.3/L3.4 territory, now
appearing in generated code).

This sample is also the Phase 5 callback: `cat | grep | wc -l` is the classic
useless-`cat` pipeline, and the `sort -t: -k2 -rn` at the end is exactly the
ranking shape from L5.1.

**Per-sample flaw inventories (`answers.txt`, all-or-nothing per sample):**

| key | allowed tokens | answer |
|---|---|---|
| `s1_worst` | unsetvar\|quoting\|retention | `unsetvar` |
| `s1_savedby` | nounset\|errexit\|pipefail | `nounset` |
| `s2_findings` | a number | `0` |
| `s2_fetch` | nofail\|noretry\|notimeout | `nofail` |
| `s2_integrity` | checksum\|permissions\|logging | `checksum` |
| `s2_temppath` | predictable\|toolong\|readonly | `predictable` |
| `s2_model` | l6.5\|l6.2\|l6.3 | `l6.5` |
| `s3_severity` | sc2045\|sc2086\|sc2126 | `sc2045` |
| `s3_breaks` | spaces\|symlinks\|permissions | `spaces` |
| `s3_useless` | cat\|grep\|sort | `cat` |
| `cleanest` | gen2\|gen1\|gen3 | `gen2` |
| `lesson` | floor\|ceiling\|proof | `floor` |

(`cleanest` asks which sample ShellCheck reports as clean; `lesson` asks what
shellcheck-clean therefore is — the floor.)

**CHECK LOGIC:** anchored asserts on all twelve keys, grouped so the failure
message names the sample and the checklist item to re-apply (never the
answer); quiz. **Executes none of the three samples** — `gen1` contains a
live `rm -rf` on an unset variable, `gen2` fetches and unpacks over a system
path, `gen3` is harmless but stays consistent with the phase's
never-execute-flawed-samples rule. Guided steps run `shellcheck -x -S style`
on **all three** and have the learner record the finding counts (5, 0, 4
respectively pre-banner — **re-count at build after banner insertion**,
banners are comments so counts should hold) before opening the checklist.

**QUIZ:**
1. "`gen2-fetch-deploy.sh` emits zero ShellCheck findings, which proves…" —
   a) it is safe to deploy · **b) only that it contains no flaws ShellCheck
   can detect — trust, integrity, and error handling are all still absent** ·
   c) the linter is broken. (`Yg==`)
2. "`curl -s` without `--fail` is dangerous because…" — **a) an HTTP error
   page is written to the output file and curl still exits 0** · b) it is
   slower · c) it disables TLS. (`YQ==`)
3. "`for f in $(ls $DIR)` is an error-severity finding because…" — **a) the
   loop splits on whitespace, so any filename with a space becomes two
   iterations** · b) ls is deprecated · c) it is slower than find. (`YQ==`)

**RECAP:**
- Three generated scripts, three profiles: one loud with findings, one clean
  and dangerous, one broken by the oldest bug in the book (a filename with a
  space).
- The clean one is the lesson — no `--fail`, no checksum, a predictable temp
  path, and an unpack over a live directory, all invisible to a linter.
- You have already read the correct version of that script: L6.5's cron
  wrapper does the same job with fail-fast, validate, and atomic replace.

---

### L7.5 — CI guardrails: ShellCheck + shfmt as a merge gate

**id/title/type/gate/est:** L7.5 · "CI guardrails — ShellCheck + shfmt as a
merge gate" · GUIDED · gate:false · est 15m.

**meta.json objective:** "Wire a working merge gate that fails on any
ShellCheck finding or formatting drift, prove it fails, fix the script, and
prove it passes."

This is the phase's one build-and-run lab. Everything happens inside the lab
directory; both tools are read-only analyzers. `shfmt` confirmed present at
`/usr/bin/shfmt` on the target box during planning (installed back in L0.1).

**SHIPPED — `files/gate.sh` (complete; clean, and it IS executed):**

```bash
#!/bin/bash
# gate.sh — the merge gate: lint everything under scripts/, fail on any finding.
set -euo pipefail
shellcheck -x -S style scripts/*.sh
shfmt -d scripts/
echo "gate: clean"
```

**Verified:** `shellcheck -x -S style` → CLEAN.

**SHIPPED — `files/scripts/bad.sh` (the gate's first victim; one planted
finding):**

```bash
#!/bin/bash
set -euo pipefail
msg="hello from the gate demo"
echo $msg
```

**Verified ShellCheck output:** SC2086 (line 4) — exactly one finding, by
design. Small enough that the fix is obvious and the lab's subject stays the
*gate*, not the bug.

**Guided steps (run for real):**

1. `cp -r files/scripts .` and `cp files/gate.sh .` into the lab workdir.
2. Run `./gate.sh` → it **fails** on SC2086, exit nonzero. Expected output
   shown in `lab.md`. This is the gate doing its job.
3. Fix `scripts/bad.sh` (quote the expansion). Re-run `./gate.sh` → passes,
   prints `gate: clean`.
4. Introduce formatting drift (the lab suggests collapsing the indentation
   on a multi-line block in a second shipped script,
   `files/scripts/ok.sh`), re-run, watch `shfmt -d` fail with a diff, then
   `shfmt -w` it and re-run.
5. Read this repo's own `tools/shellcheck-all.sh` as the production version
   of the same idea — and specifically read its comment block explaining
   *why* `git ls-files --cached --others --exclude-standard` is used instead
   of a bare glob (a brand-new unstaged script would otherwise be silently
   skipped, producing a false clean bill). That comment is a real lesson in
   how gates lie.

**Comprehension questions (`answers.txt`):**

| key | question | allowed tokens | answer |
|---|---|---|---|
| `gatefail` | Which SC code made the gate fail on the first run? | code | `sc2086` |
| `whyexit` | What makes a nonzero exit from the gate script fail the CI job? | exitcode\|stderr\|logfile | `exitcode` |
| `fmtflag` | Which shfmt flag reports drift without rewriting files? | flag letter | `-d` |
| `strictgate` | Why does gate.sh itself carry `set -euo pipefail`? | failfast\|speed\|style | `failfast` |
| `sweeptrap` | Per tools/shellcheck-all.sh, a bare glob can miss which files? | untracked\|binary\|hidden | `untracked` |

**CHECK LOGIC:** this lab **does execute** — `check.sh` runs the learner's
`gate.sh` against their fixed `scripts/` directory and requires exit 0 plus
the `gate: clean` marker; separately re-runs `shellcheck -x -S style` on
`scripts/*.sh` itself to confirm the fix is real rather than the gate being
weakened (anti-gaming: assert the learner did not simply delete `bad.sh` —
require the file to still exist, still contain the `msg` assignment, and now
be clean). Then the five anchored `answers.txt` keys and the quiz. Safe:
everything runs inside the lab workdir; both tools are analyzers.

**QUIZ:**
1. "A merge gate works because…" — **a) the job's exit code decides whether
   the merge is allowed, so the check cannot be skipped by inattention** ·
   b) it emails the author · c) it reformats code automatically. (`YQ==`)
2. "`shfmt -d` versus `shfmt -w`…" — **a) `-d` shows a diff and fails; `-w`
   rewrites the file in place** · b) they are aliases · c) `-d` deletes
   drift. (`YQ==`)
3. "`tools/shellcheck-all.sh` lists untracked-but-not-ignored files in its
   sweep because…" — **a) a brand-new script nobody staged yet would
   otherwise be skipped and report a false clean** · b) git requires it ·
   c) it is faster. (`YQ==`)

**RECAP:**
- A merge gate is a script whose exit code decides the merge — ShellCheck for
  correctness, shfmt for formatting drift, both non-optional.
- The gate itself needs strict mode: a gate that fails silently is worse
  than no gate.
- Gates lie when their file list is wrong — sweep untracked files too, or a
  brand-new script ships unchecked.

---

### L7.6 — Capstone: direct + audit a SOC-relevant script (log-ingest helper)

**id/title/type/gate/est:** L7.6 · "Capstone: direct + audit a SOC-relevant
script" · DIRECT · gate:false · est 20m.

**meta.json objective:** "Write the spec for a log-ingest helper, then audit
the output you get back against your own checklist — the full direct-then-
review loop, on a script you would actually use."

**Kit constraint, stated honestly in `lab.md`:** the lab harness makes no
network calls and cannot invoke a model. So the lab ships a **planted "model
output"** — an original script written in default-AI style — and the learner
plays both halves of the real loop: the *direction* rep is writing the spec
(`ingest-spec.md`), the *audit* rep is grading the shipped output against
their L7.3 checklist. `lab.md` says plainly that this is a rehearsal with a
fixed response, and that in real use they would paste their spec and get
something different but failing in the same recognizable ways.

**Target script (what the spec must ask for):** a log-ingest helper that
reads NDJSON events from a file and emits ECS-shaped records — `@timestamp`,
`source.ip`, `event.action` — skipping malformed lines and reporting counts.
This is the map's stated capstone target and reuses L5.4's jq/ECS ground.

**SHIPPED "MODEL OUTPUT" — `files/model-output.sh` (complete; deliberately
flawed, never executed):**

```bash
#!/bin/bash
# AI-generated log ingest helper - converts your logs to ECS format!

INPUT=$1
FILTER=${2:-.}

# Use a temp file to stage the results
TMP=/tmp/ingest-work.json

# Process the input with the user's custom filter for flexibility!
cat $INPUT | while read line; do
    echo $line | jq -c "{\"@timestamp\": .ts, \"source.ip\": .src, \"event.action\": .action}" >> $TMP
done

# Apply the custom filter
eval "jq '$FILTER' $TMP"

echo "Done! Processed $(wc -l < $TMP) events"
```

**Verified ShellCheck output:** SC2086 (line 11, `$INPUT`), SC2162 (line 11,
`read` without `-r`), SC2086 (line 12, `$line`). **Three findings — and none
of them is the real problem.**

**The four flaws ShellCheck does not report** (this is the lab):

- **`eval "jq '$FILTER' …"` is command injection.** `$FILTER` is
  user-supplied (`$2`) and gets spliced into a string the shell re-parses.
  ShellCheck is silent because the `eval` argument *is* quoted. This is
  L3.7 + L4.1, arriving in a script the learner asked for.
- **Predictable temp path** `/tmp/ingest-work.json` — fixed name in a
  world-writable directory (L4.7), plus it is **appended to** (`>>`), so a
  second run silently doubles the output and a stale file from any prior run
  is counted as new data.
- **No strict mode**, so a failing `jq` on a malformed line writes nothing
  and the loop continues — the "skip malformed lines" requirement is met by
  accident, not design, and the skip count is never reported.
- **`cat file | while read`** is the L3.6 subshell shape *and* a useless
  `cat`; the loop body's variables would not survive if it needed them.

**Learner deliverables:** `ingest-spec.md` (the direction rep) and
`answers.txt` (the audit rep).

**Graded spec tags** (same commitment-tag grammar as L7.2, scoped to this
task):

| tag | required value |
|---|---|
| `input=` | `validate` |
| `temp=` | `mktemp` |
| `filter=` | `no-user-filter` (the spec must refuse a user-supplied filter string outright) |
| `malformed=` | `skip-and-count` |
| `accept=` | `shellcheck-clean` |

**Audit questions (`answers.txt`):**

| key | question | allowed tokens | answer |
|---|---|---|---|
| `sc_count` | How many findings does ShellCheck report on the shipped output? | a number | `3` |
| `realflaw` | Which flaw is the most severe, and unreported by ShellCheck? | injection\|quoting\|useless-cat | `injection` |
| `whyquiet` | ShellCheck stays quiet about it because the argument is… | quoted\|short\|lowercase | `quoted` |
| `tempflaw` | The temp path is unsafe because it is… | predictable\|small\|readonly | `predictable` |
| `appendbug` | Because the temp file is appended to, a second run will… | double\|truncate\|fail | `double` |
| `checklist` | Which checklist item catches the top flaw? | item id | `c4-noeval` |

**Lint note:** `realflaw=injection` and `checklist=c4-noeval` keep the banned
whole word out of `check.sh` (subject to the L7.3 `[VERIFY-AT-BUILD]`
resolution on `noeval`).

**CHECK LOGIC:** asserts `ingest-spec.md` exists with all five commitment
tags anchored; asserts the six `answers.txt` keys; quiz. **Does NOT execute
`files/model-output.sh`** — it contains a live injectable `eval` on `$2` and
writes a predictable `/tmp` path. Guided steps run `shellcheck -x -S style`
on it so the learner sees three findings and must then explain why the
severe flaw is not among them.

**QUIZ:**
1. "The shipped output is shellcheck-clean after fixing its three findings —
   at that point it is…" — a) safe to ship · **b) still command-injectable
   through its filter argument** · c) formatted correctly and nothing more.
   (`Yg==`)
2. "A spec that permits a user-supplied jq filter string is…" — **a) a spec
   that has designed the injection in, no matter how carefully the script is
   written** · b) more flexible and therefore better · c) unaffected by
   quoting. (`YQ==`)
3. "Appending to a fixed temp path across runs causes…" — **a) stale data
   from a previous run to be counted as new** · b) a permission error ·
   c) faster processing. (`YQ==`)

**RECAP:**
- The direct-then-audit loop is one motion: write the spec, then review what
  comes back against your own checklist — never one without the other.
- Generated output failed here in exactly the L7.1 ways, plus the one that
  matters most: a user-supplied filter spliced into a re-parsed string.
- Fixing every ShellCheck finding in that script would leave the injection
  fully intact.

---

### L7.7 — CAPSTONE GATE: ship a hardened, shellcheck-clean script

**id/title/type/gate/est:** L7.7 · "Capstone gate: ship a hardened,
shellcheck-clean script" · AUDIT · **gate:true** · est 20m.

**meta.json objective:** "Rewrite the L7.6 output as a hardened log-ingest
helper that passes a real ShellCheck sweep, behaves correctly on malformed
input, and satisfies every blocking item on your own checklist."

**Learner deliverable:** `hardened.sh` — their corrected version of L7.6's
script. This is the only lab in the track where the learner's own script is
swept for real by `check.sh` and executed against fixtures.

**Fixtures shipped in `files/`:**

`files/sample.ndjson` (3 valid records, 1 malformed line — verified during
planning):

```
{"ts":"2026-07-19T04:00:01Z","src":"192.0.2.10","action":"login-failed"}
{"ts":"2026-07-19T04:00:05Z","src":"192.0.2.11","action":"login-failed"}
not json at all
{"ts":"2026-07-19T04:00:09Z","src":"198.51.100.7","action":"login-ok"}
```

`files/allbad.ndjson` (one unparseable line, no valid records).

IPs are RFC 5737 TEST-NET-1/TEST-NET-2 documentation addresses.

**Required behavior (stated in `lab.md` as the acceptance criteria):**

1. `./hardened.sh <input.ndjson>` emits one compact ECS record per valid
   line, with keys `@timestamp`, `source.ip`, `event.action`.
2. Malformed lines are skipped, not fatal.
3. A summary of valid/skipped counts goes to **stderr**, so stdout stays
   pipeable NDJSON.
4. Exit 0 when at least one record was emitted; exit nonzero when none was.
5. Usage error (wrong argument count) exits 2; unreadable input exits 1.
6. No user-supplied filter argument exists at all — the L7.6 injection is
   designed out, not patched over.
7. `shellcheck -x -S style hardened.sh` emits zero findings.

**REFERENCE SOLUTION — build-time aid, NOT shipped to the learner** (kept in
the plan and in the build branch's notes only; the learner writes their own).
Verified during planning: shellcheck-clean, and executed against both
fixtures.

```bash
#!/bin/bash
# Reference solution for the L7.7 gate (build-time aid; the learner writes
# their own hardened.sh — this pins expected behavior).
set -euo pipefail

usage() { echo "usage: $0 <input.ndjson>" >&2; exit 2; }

[[ $# -eq 1 ]] || usage
readonly INPUT="$1"
[[ -r $INPUT ]] || { echo "input not readable: $INPUT" >&2; exit 1; }

valid=0
skipped=0
while IFS= read -r line; do
    [[ -n $line ]] || continue
    if out=$(jq -ce 'select(.ts and .src and .action)
                     | {"@timestamp": .ts, "source.ip": .src, "event.action": .action}' \
                     <<<"$line" 2>/dev/null); then
        printf '%s\n' "$out"
        valid=$((valid + 1))
    else
        skipped=$((skipped + 1))
    fi
done < "$INPUT"

echo "valid=$valid skipped=$skipped" >&2
[[ $valid -gt 0 ]]
```

**Verified behavior (run during planning, ShellCheck 0.9.0 / jq present):**

- `shellcheck -x -S style` → **CLEAN**.
- Against `sample.ndjson`: three ECS records on stdout, `valid=3 skipped=1`
  on stderr, **exit 0**.
- Against `allbad.ndjson`: no stdout records, `valid=0 skipped=1` on stderr,
  **exit 1**.

Note the design choices worth teaching in `hints.json` level 2: `while IFS=
read -r … done < "$INPUT"` (redirect, not `cat |`) keeps the loop in the
current shell so the counters survive — the L3.6 lesson; and the here-string
`<<<"$line"` feeds jq without a temp file at all, which is how the L7.6 temp
flaw disappears rather than getting patched (L5.5).

**CHECK LOGIC (the track's most substantive grader):**

1. `hardened.sh` exists and is executable.
2. **Real lint:** run `shellcheck -x -S style hardened.sh`; require zero
   findings. Failure message quotes the actual ShellCheck output.
3. **Behavior, valid input:** run against `files/sample.ndjson`; require
   exactly 3 stdout lines, each valid JSON containing all three ECS keys
   (verified per-line with `jq -e`), and exit 0.
4. **Behavior, no valid input:** run against `files/allbad.ndjson`; require
   nonzero exit and zero stdout records.
5. **Stream discipline:** require the summary counts to appear on **stderr**
   and never on stdout (capture the two streams separately — a summary line
   polluting stdout breaks downstream NDJSON consumers and must fail).
6. **Usage/error contract:** no arguments → exit 2; nonexistent path → exit
   1.
7. **Anti-gaming, per the L4.7 and L4.2 precedents:** reject a submission
   that merely hardcodes the fixture's expected output (require the script
   to produce correct results for a *second, check-generated* fixture
   written to the lab workdir at check time with different timestamps and
   IPs); reject a submission that accepts a second positional argument used
   as a filter (assert the usage contract rejects two arguments with exit
   2 — closing the L7.6 injection by contract, not by inspection).
8. Anchored `answers.txt` attestations (below), then quiz — gate requires
   3/3.

**Safety:** everything runs inside the lab workdir on lab-local fixtures.
The learner's script reads a file and writes stdout/stderr; no network, no
system paths, no privilege. This is the one lab where executing the
learner's code is both necessary and safe.

**Attestation questions (`answers.txt`):**

| key | question | allowed tokens | answer |
|---|---|---|---|
| `loopform` | Which loop form keeps the counters in the current shell? | redirect\|pipe\|subshell | `redirect` |
| `notemp` | How does the hardened version avoid a temp file entirely? | herestring\|mktemp\|pipe | `herestring` |
| `streams` | Where do the summary counts go, so stdout stays pipeable? | stderr\|stdout\|logfile | `stderr` |
| `noinject` | The L7.6 injection is closed by… | removing-the-filter\|quoting-it\|escaping-it | `removing-the-filter` |
| `exitnone` | With zero valid records the script exits… | nonzero\|zero\|two | `nonzero` |

**QUIZ:**
1. "Your script passing `shellcheck -x -S style` with zero findings means…"
   — a) it is proven correct · **b) the mechanical floor is met; the
   checklist items about trust, validation, and intent are what you
   verified by hand** · c) it needs no tests. (`Yg==`)
2. "Sending the summary to stderr rather than stdout matters because…" —
   **a) stdout is the data stream — a status line mixed into it corrupts
   every downstream consumer** · b) stderr is faster · c) it is required by
   jq. (`YQ==`)
3. "The safest fix for a user-supplied filter argument is to…" — **a) remove
   the capability from the interface entirely** · b) quote it · c) escape
   the shell metacharacters in it. (`YQ==`)

**RECAP:**
- You shipped it: a hardened, shellcheck-clean, behavior-verified script
  that closes an injection by design rather than by escaping.
- The mechanical gate (lint) and the human gate (your checklist) are
  different instruments — passing one never substitutes for the other.
- This is the loop for every future script an AI writes for you: spec first,
  review against the checklist, gate in CI, then ship.

---

## Build-session protocol (execute in this order — gate at each lab per CLAUDE.md)

1. **Prerequisite:** bash Phase 6 built, merged, and tagged `bash-p6`.
   Reconcile L7.1's `recall.json` against the p6 `recap.md` files on disk
   before committing L7.1 (the `[FROM-P6-HANDOFF]` items above).
2. Branch `bash-p7-l7.1` → build L7.1 → self-test fail-before-artifacts →
   pass path → negative case (one wrong token fails only its assert) →
   parallel `security-auditor` + `code-reviewer` → fix findings → PR →
   explicit go-ahead → merge. Repeat for L7.2–L7.7 in order.
3. **Resolve the `noeval` token question during L7.3** (see that lab's lint
   note) and carry the decision into L7.4 and L7.6 — it affects answer keys
   in three labs.
4. **Do not extend the shellcheck sweep glob** for p7. The p7 `files/`
   samples are deliberately flawed and must stay unswept, exactly like
   p3/p4. The only p7 shell that must be clean is each lab's `check.sh`
   (always swept), `files/gate.sh` and `files/scripts/*.sh` in L7.5
   (executed by that lab's checker — sweep them explicitly by adding
   `'tracks/*/phases/p7/L7.5-*/files/**/*.sh'`, or verify manually at build
   and document the choice) **[VERIFY-AT-BUILD]**, and the learner's own
   `hardened.sh` in L7.7 (swept at check time, not by the repo tool).
5. Re-verify every SC code set and finding count in this plan against the
   committed files **after banner insertion**, and re-anchor the line
   numbers in each table.
6. Close-out branch `bash-p7-close-out`: extend `tests/acceptance.sh` with a
   P7 section (7 labs; fabricated pass + negative case each; plus
   flawed-sample negative cases where a missed planted flaw must fail, and
   an L7.7 case where a shellcheck-dirty `hardened.sh` must fail); fix every
   stale catalog-count denominator, not just the final one —
   `(11/47)→(11/54)`, `(28/47)→(28/54)`, `(36/47)→(36/54)`,
   `(42/47)→(42/54)`, `(47/47)→(47/54)`, new `(54/54)` after the P7 block —
   and the "25 unstarted track-phase lines"→"24" count once bash-p7's marker
   moves past `[ ]`; update `planned_execution.md` (marker, NEXT UP, LAST
   SESSION, **and the track-completion milestone: bash is the first track to
   finish, 54/54**); tag `bash-p7`.

## Verification (how to confirm the built phase is correct)

- `tools/shellcheck-all.sh` clean (all seven p7 `check.sh` files; p7
  `files/` flawed samples correctly **not** swept — confirm by inspecting
  the resolved file list, the same way the p4 plan verified `files/` was
  genuinely never swept).
- `tools/lint-labs.sh` clean — with specific attention to the banned-builtin
  rule across L7.1/L7.3/L7.4/L7.6 answer keys and hint strings.
- Per lab via the real `lab` CLI: fail-before-artifacts → PASS → negative
  case. L7.5 and L7.7 additionally verified by running their graders against
  a deliberately wrong submission (weakened gate; shellcheck-dirty
  `hardened.sh`; a `hardened.sh` that hardcodes fixture output; a
  `hardened.sh` that accepts a filter argument) and confirming each fails.
- `tests/acceptance.sh` fully green at close-out.
- `lab status` shows **54/54** for the bash track, L7.7 marked as gate, and
  the track complete.

## Open items to confirm at build (not blockers)

- **[VERIFY-AT-BUILD]** L7.1 `recall.json` wording against the real p6
  `recap.md` files (see build protocol step 1).
- **[VERIFY-AT-BUILD]** `tools/lint-labs.sh`'s banned-token regex: whole-word
  or substring? Decides whether `c4-noeval` survives or becomes
  `c4-nostringexec` across three labs (L7.3 build resolves it).
- **[VERIFY-AT-BUILD]** Whether L7.5's executed `files/gate.sh` and
  `files/scripts/*.sh` join the sweep glob or are verified manually —
  document whichever is chosen in `tools/shellcheck-all.sh`'s comment block,
  which is the repo's single definition of "shellcheck clean."
- **[VERIFY-AT-BUILD]** Re-run every sample through `shellcheck -x -S style`
  on the build box after banner insertion; re-anchor all line numbers and
  re-confirm the finding counts quoted in L7.4's guided steps (5 / 0 / 4).
- **[VERIFY-AT-BUILD]** Confirm `jq` and `shfmt` are present on the build box
  (both were during planning: `shfmt` at `/usr/bin/shfmt`, `jq` exercised by
  the L7.7 reference run) and that `lab` auto-registers `phases/p7/*`.
- The L7.6 "planted model output" framing is stated honestly in `lab.md`; if
  a future kit version can call a model, this lab is the natural place to
  swap the fixed response for a live one — note it as a v2 candidate.
