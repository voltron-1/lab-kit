## BRIEF
This lab is the kit driving itself. You will provision a workspace,
follow guided steps, climb the hint ladder, and pass a graded check plus
a 3-question quiz. Everything you touch lives in workspace/demo/L0.0/ —
the same fence the future bash-track footgun labs detonate inside, so it
has to be real from day one. Progress is stored in .progress.json at the
repo root; every write is atomic, so Ctrl-C can never corrupt it. Status
marks: ✓ passed, ○ not done, ⏭ forced — a forced lab never turns into a
✓. Stuck? lab hint demo L0.0.

## GUIDED STEPS

1. Look around.

       cd workspace/demo/L0.0
       ls

   expect:

       README-first.txt  broken.conf

   Read README-first.txt — it has the facts the quiz asks about.

2. Fix the config.

       cp broken.conf fixed.conf

   Edit `fixed.conf`: change `max_retries = ten` to `max_retries = 3`,
   and `workspace_fence = off` to `workspace_fence = on`. Verify:

       grep -E 'max_retries|workspace_fence' fixed.conf

   expect:

       max_retries = 3
       workspace_fence = on

3. Capture a command's output to a file.

       uname -r > sysinfo.txt
       cat sysinfo.txt

   expect (your kernel string will differ from this example):

       6.6.87.2-microsoft-standard-WSL2

4. Prove you're inside the fence.

       pwd > location.txt

5. Grade it.

       lab check demo L0.0

   Optional detour first: run `lab hint demo L0.0` once just to see the
   ladder — it costs nothing but a look.
