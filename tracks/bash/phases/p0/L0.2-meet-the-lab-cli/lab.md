## BRIEF
L0.1 proved the toolchain; this lab proves the kit. Drive each mechanic
once — status, hints, a graded answer file, the fence proof, check — so
no later lab is your first contact with the machinery. Everything you
touch lives in `workspace/bash/L0.2/`, the same fence Phase 3's footgun
labs detonate inside. A failed check costs nothing but a rerun; a spent
hint costs nothing but a look. Two track conventions debut here and
never change: graded answers are `key=value` lines (exact lowercase
keys, no spaces around `=`) and scripts run as `bash <script>`. Stuck?
`lab hint bash L0.2`.

## GUIDED STEPS

1. From the repo root: `lab status` — find the bash block. This lab's row
   starts with `▶` because `lab start` marked it in progress. Read the
   legend line: `⏭` never becomes `✓`.

       lab status

   expect (your board also lists whatever other tracks/labs you've
   installed — the important row is bash's `▶ L0.2`; the `next:` footer
   names the first not-yet-passed lab across ALL installed tracks, in
   track order, so it may not point at L0.2):

       LAB-KIT — status
       ══════════════════════════════════════════════════════════

       demo · Demo Lab   0 ✓ · 0 ⏭ · 1 ○  (0/1)
         p0 · Kit Mechanics
           ○  L0.0   Meet the Kit                               GATE ~15m

       bash · Bash Literacy Lab   1 ✓ · 0 ⏭ · 2 ○  (1/3)
         p0 · Toolchain & Kit
           ✓  L0.1   Shells and the kit — which shell am I in, install ShellCheck & shfmt      ~15m
           ▶  L0.2   Meet the lab CLI — start, check, resume       ~10m
           ○  L0.3   Reading the shebang — #!/bin/bash vs #!/bin/sh vs dash, and why it matters GATE ~15m

       --------------------------------------------------------------
       ✓ passed   ▶ in progress   ○ not done   ⏭ forced (--force, never ✓)
       next: demo L0.0 — Meet the Kit   run: lab start demo L0.0

2. Look around and read every line — every graded answer in this lab is
   one of them.

       cd workspace/bash/L0.2
       ls

   expect:

       kit-notes.txt

       cat kit-notes.txt

3. Spend hint level 1 for free — it costs nothing but a look, and it
   never gives the answer.

       lab hint bash L0.2

   expect:

       [hint 1/3] bash L0.2
         The grader wants exactly two files, both named in steps 4-5: answers.txt and location.txt. ls the workspace and compare it against the step list.

       (2 hints remaining — run lab hint bash L0.2 again for the next)

   Level 1 names artifacts, never content. A rerun would show `[hint 2/3]`
   with the next level — the counter only advances after it prints.

4. Create `answers.txt` — one `key=value` line per question, no spaces
   around `=`:

   q1 (choice). A month has passed since you last touched the kit. What's
   the first command back?
   a) `lab status`  b) `lab resume`  c) `lab hint`

   q2 (value). How many hint levels does every lab have?

   q3 (choice). Your quiz comes back 2/3. What just happened?
   a) partial credit — the 2 correct answers are saved
   b) the whole check failed; nothing is lost — rerun `lab check`
   c) the lab resets and must be restarted

   Every answer is a line in `kit-notes.txt` — write `q1=`, `q2=`, `q3=`
   into `answers.txt`.

5. Prove you're inside the fence.

       pwd > location.txt

6. Grade it.

       lab check bash L0.2

   Type the three quiz answers at each `  > ` prompt. expect (quiz answers
   never shown — this is the shape, not the content):

       checks — bash L0.2
       --------------------------------------------------------------
         ✓  [1] answers.txt matches: ^q1=b$
         ✓  [2] answers.txt matches: ^q2=3$
         ✓  [3] answers.txt matches: ^q3=b$
         ✓  [4] location.txt was written from inside the workspace
       checks 4/4

       quiz — 3 questions
       --------------------------------------------------------------
       Q1. A lab shows ⏭ in lab status. You go back, do the work, and pass its check. Its mark becomes…
             a) ✓ — a pass always upgrades the mark
             b) ▶ — in progress until the next lab passes
             c) ⏭ — skipped is permanent; it never becomes ✓
         >
       Q2. Which command replays your last recap card?
         >
       Q3. Why must an answer line be exactly q1=b, never Q1 = b?
             a) style preference — the grader normalizes case and spacing
             b) check.sh greps the anchored pattern ^q1=b$ — any other spelling doesn't match and the check fails
             c) the CLI rewrites the file before grading
         >

       quiz: 3/3

       RESULT: PASS — bash L0.2 · Meet the lab CLI — start, check, resume ✓

       recap
         · lab check = check.sh grader + quiz, all-or-nothing — a fail costs one rerun
         · graded answers are key=value lines: exact lowercase keys, no spaces around =
         · lab resume replays this recap card — 30-second re-entry after any gap

       unlocked → bash L0.3 — Reading the shebang — #!/bin/bash vs #!/bin/sh vs dash, and why it matters
       next     → lab start bash L0.3

   A 2/3 quiz fails the WHOLE check (`RESULT: FAIL — bash L0.2 (quiz)`) —
   nothing is lost, an immediate rerun with the right answers passes.

   Optional ungraded coda — replay the card you just earned:

       lab resume
