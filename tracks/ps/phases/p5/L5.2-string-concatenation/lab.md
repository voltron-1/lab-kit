## BRIEF
String concatenation, `-join` on a char array, and `[char]` codes all reassemble a keyword that's been split across several literal pieces — no single piece in the source contains the full word, so a naive plain-string scanner misses it. At runtime the pieces are joined and the result is identical to writing the word plainly.
Run the reconstruction for real. Reconstruct to a **string** and **read** it — same reflex as L5.1: decode to read, never to run.

## GUIDED STEPS

1. **Run the reconstruction for real**:
   ```bash
   pwsh -NoProfile -NonInteractive -File concat.ps1
   ```
   Real output:
   ```
   concatenation (+):  iex
   array -join:        Download
   char codes:         iex
   ```
   Three ways to hide the same two keywords: `"i"+"e"+"x"` joins three separate string
   literals with `+`; `('D','o','w','n','l','o','a','d') -join ''` joins an array of
   single-character strings; `[char]105 + [char]101 + [char]120` builds characters from
   their numeric codes and adds them together. All three produce ordinary strings —
   nothing about *how* a string was built changes what it *is* once built.

2. **Record the reconstruction**:
   Create `plaintext.txt` with what each piece reassembles to:
   ```text
   "i"+"e"+"x" -> iex
   ('D','o','w','n','l','o','a','d') -join '' -> Download
   [char]105 + [char]101 + [char]120 -> iex
   ```

3. **Check your work**:
   ```bash
   lab check ps L5.2
   ```
