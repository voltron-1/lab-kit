## BRIEF
Audit three AI-generated code snippets in `files/` and identify their planted flaws by category and CWE.

## GUIDED STEPS

1. Inspect `files/snippet1.rs`, `files/snippet2.rs`, and `files/snippet3.rs`.
2. Create `answers.txt`:
   ```text
   s1a=availability
   s1cwe=CWE-248
   s1b=input-validation
   s1trunc=CWE-197
   s2a=input-validation
   s2trav=CWE-22
   s2b=input-validation
   s2inj=CWE-78
   s3a=availability
   s3panic=CWE-248
   s3b=availability
   s3exh=CWE-400
   ```
3. Verify with `lab check rust L7.3`.
