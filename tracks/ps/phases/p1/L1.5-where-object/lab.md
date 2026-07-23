## BRIEF
`Where-Object` (alias `where` or `?`) filters an incoming object stream based on a boolean script block or property comparison.
Unlike text-filtering tools like `grep`, `Where-Object` evaluates properties on live objects and passes matching objects along the pipeline with their type preserved.
In this lab, you predict and verify pipeline filtering using `Where-Object`.

## GUIDED STEPS

1. **Examine `evens.ps1`**:
   View `files/evens.ps1` and run it:
   ```bash
   cat files/evens.ps1
   pwsh -File files/evens.ps1
   ```
   Notice that `Where-Object { $_ % 2 -eq 0 }` tests each integer in `1..10` and outputs only the even numbers (`2`, `4`, `6`, `8`, `10`).

2. **Record your predictions**:
   Create `predictions.txt` recording the resulting even number list and the object type preservation verdict:
   ```text
   numbers=2 4 6 8 10
   type_preserved=yes
   ```

3. **Check your work**:
   ```bash
   lab check ps L1.5
   ```
