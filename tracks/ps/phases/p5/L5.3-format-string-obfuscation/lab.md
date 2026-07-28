## BRIEF
The `-f` format operator substitutes arguments into `{index}` placeholders. Reordering the indices scrambles a keyword's letters in the source — `"{0}{2}{1}" -f 'I','x','E'` doesn't spell `I`-`x`-`E` in that order; it picks argument 0, then argument 2, then argument 1.
Run the reconstruction for real. Reconstruct to a **string** and **read** it.

## GUIDED STEPS

1. **Run the reconstruction for real**:
   ```bash
   pwsh -NoProfile -NonInteractive -File fmt.ps1
   ```
   Real output:
   ```
   reordered 3-arg format: IEx
   reordered 2-arg format: iex
   ```
   `"{0}{2}{1}" -f 'I','x','E'`: position `{0}` = `'I'`, `{2}` = `'E'`, `{1}` = `'x'` → `I` +
   `E` + `x` = `IEx`. The template's own left-to-right order never matches the argument
   order — that mismatch is the tell.

2. **Record the reconstruction**:
   Create `plaintext.txt`:
   ```text
   "{0}{2}{1}" -f 'I','x','E' -> IEx
   "{1}{0}" -f 'ex','i' -> iex
   ```

3. **Check your work**:
   ```bash
   lab check ps L5.3
   ```
