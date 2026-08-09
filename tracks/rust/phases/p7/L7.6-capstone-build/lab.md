## BRIEF
Audit the AI's flawed draft `draft_v1.rs` in `files/` and write your review directions for v2.

## GUIDED STEPS

1. Inspect `files/draft_v1.rs`.
2. Create `answers.txt`:
   ```text
   f1=availability
   f1cwe=CWE-248
   f2=availability
   f2cwe=CWE-248
   f3=correctness
   f4=availability
   f4cwe=CWE-248
   escaping=ok
   ```
3. Create `direction.md` specifying:
   - Check `parts.len()` bounds before indexing
   - Map outcome OK->success and FAILED->failure
4. Verify with `lab check rust L7.6`.
