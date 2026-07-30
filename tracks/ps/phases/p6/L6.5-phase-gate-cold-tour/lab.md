## BRIEF
**Do not run the tool — read it.** This is the phase gate, and it is deliberately unhelpful. `mystery-tool.ps1` arrives with no explanation of what it is — no title, no usage, no description. That is the situation the whole phase has been preparing you for: someone hands you a script and asks what it does.

You have done four guided tours. This one you do cold.

## GUIDED STEPS

1. **Read the tool**:
   ```bash
   less mystery-tool.ps1
   ```
   Resist the urge to work line by line. Read it once for shape first: what does it
   load, what does it walk, and what does it print at the end?

2. **Read what it loads**:
   ```bash
   less reference-list.txt
   ```
   The format of this file tells you what kind of comparison the tool must be
   doing, which is most of the answer to what the tool is.

3. **Work out the two passes**:
   The tool builds its results from two separate sources before printing them
   together. Identify both, and note what each one has to compute before it can
   compare anything.

4. **Write your tour**:
   Create `answers.md` covering: what this tool is for, what it matches against,
   how it decides something matches, which subsystems it reads, and when you would
   reach for it. Your own words — you are graded on covering the ground, not on
   matching a phrasing.

5. **Pass the gate**:
   ```bash
   lab check ps L6.5
   ```
   This is a gate: the 3-question quiz must be 3/3.
