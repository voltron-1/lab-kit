## BRIEF
File extensions can be deceptive. Inspect true container types with magic bytes and compute sha256 hashes safely.

## GUIDED STEPS

1. Inspect files in `files/`.
2. Compute the sha256 hash of `files/invoice_2026-03.docm`:
   ```bash
   sha256sum files/invoice_2026-03.docm > hash.txt
   ```
3. Copy `files/answers.template.txt` to `answers.txt`.
4. Fill `answers.txt`:
   - `q1`: True container type of invoice_2026-03.docm by magic (zip|ole|pe|jpeg) -> `zip`
   - `q2`: Does invoice_2026-03.docm carry a macro project? (y|n) -> `y`
   - `q3`: Filename whose REAL type is an executable -> `receipt.pdf.exe`
   - `q4`: First 12 hex chars of invoice_2026-03.docm sha256 hash -> `55e9d81f361e`
   - `q5`: Safe first step with a suspicious attachment (open|hash|reply) -> `hash`
5. Run `lab check soc L5.3`.
