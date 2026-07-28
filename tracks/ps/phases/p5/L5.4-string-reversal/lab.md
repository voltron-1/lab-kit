## BRIEF
`$s[-1..-$s.Length] -join ''` walks a string backwards, character by character — same characters, same length, only the order changes. A reversed literal hides a keyword from a forward string scan; reversing it again recovers the original.
Run the reconstruction for real. Reconstruct to a **string** and **read** it.

## GUIDED STEPS

1. **Run the reconstruction for real**:
   ```bash
   pwsh -NoProfile -NonInteractive -File rev.ps1
   ```
   Real output:
   ```
   reversed keyword 1: iex
   reversed keyword 2: DownloadString
   ```
   `$s[-1..-$s.Length]` indexes the string from its last character back to its first —
   `-1` is the last element, `-$s.Length` is the first — then `-join ''` glues the
   resulting character array back into one string. The shipped literals (`'xei'`,
   `'gnirtSdaolnwoD'`) are the *already-reversed* form; running this reverses them again.

2. **Record the reconstruction**:
   Create `plaintext.txt`:
   ```text
   'xei' reversed -> iex
   'gnirtSdaolnwoD' reversed -> DownloadString
   ```

3. **Check your work**:
   ```bash
   lab check ps L5.4
   ```
