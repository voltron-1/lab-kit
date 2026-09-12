## BRIEF
File extensions can be deceptive. Inspect true container types with magic bytes and compute sha256 hashes safely.

## GUIDED STEPS

1. Inspect files in `files/`.
2. Compute the sha256 hash of `files/invoice_2026-03.docm`:
   ```bash
   sha256sum files/invoice_2026-03.docm > hash.txt
   ```
3. Copy `files/answers.template.txt` to `answers.txt`.
4. Fill `answers.txt`. Every line in the template names exactly what it wants —
   answer each one from the evidence above.
5. Run `lab check soc L5.3`.
