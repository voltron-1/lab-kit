## BRIEF
This is the phase gate. `gate-blob.txt` is one sample wrapped in **three** layers — every technique this phase taught, stacked: base64/UTF-16LE (L5.1) over a character reversal (L5.4) over an unresolved format-operator expression (L5.3).

The job is the SOC job. Peel every layer, reconstruct the plaintext, name each technique you had to undo, and name what the payload turned out to be. Then stop. Reconstructing a payload and running it are different acts, and the entire phase has been about keeping them different.

## GUIDED STEPS

1. **Look at what you were given**:
   ```bash
   cat gate-blob.txt
   ```
   One opaque base64 line. Everything below comes out of it.

2. **Peel all three layers**:
   ```bash
   pwsh -NoProfile -NonInteractive -File gate-peel.ps1
   ```
   It prints one line per layer, so you can watch each technique come off. Read all
   three before writing anything. Note especially what layer 2 gives you: legible
   PowerShell, except for one expression that is still unresolved — that leftover
   expression is layer 3, and it exists precisely so a scanner reading layer 2
   still never sees the keyword.

3. **Record the reconstruction**:
   Create `plaintext.txt` holding the final layer-3 plaintext.

4. **Write the analysis**:
   Create `answers.md`. Name each layer you peeled and the payload the plaintext
   turned out to be. Write it the way you would write the ticket: someone reading
   only your `answers.md` should know what the sample was and what it would have
   done. You are graded on covering the topics, not on matching a fixed wording.

5. **Pass the gate**:
   ```bash
   lab check ps L5.7
   ```
   This is a gate: the 3-question quiz must be 3/3.
