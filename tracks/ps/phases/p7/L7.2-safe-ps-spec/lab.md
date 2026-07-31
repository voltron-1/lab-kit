## BRIEF
L7.1 named AI's default failures. This lab **inverts** each one into a requirement: a **spec** — a prompt/checklist you hand to AI — that forces auditable output *by construction*. You direct the AI; the spec is the contract that forces safety.
Write `safe-spec.md` with the required clauses below.

## GUIDED STEPS

1. **Invert each L7.1 failure into a requirement**:
   ```text
   bare iex on interpolated input   -> NO Invoke-Expression / iex; call cmdlets directly with
                                        bound parameters
   no [CmdletBinding()]/validation  -> [CmdletBinding()] + typed [Parameter(Mandatory)] with
                                        [ValidateSet]/[ValidateNotNullOrEmpty]
   no error handling                -> try/catch with -ErrorAction Stop on risky calls;
                                        meaningful $_ handling
   no logging                       -> logging ON: structured Write-Verbose / a transcript /
                                        an audit line per action
   hardcoded plaintext credential   -> NO hardcoded creds: use a vault / SecureString from a
                                        store, never plaintext or $Env: echo
   ```

2. **Read why this is the DIRECT moment** (static reference):
   ```text
   A good spec makes the AI's output auditable BY CONSTRUCTION -- the reviewer checks output
   against the spec instead of re-discovering the same five failures every time. You don't
   write the code yourself; you direct the AI with a spec precise enough that a lead analyst
   can grade the result against it in minutes.
   ```

3. **Write your spec**:
   Create `safe-spec.md`:
   ```text
   # safe-PS spec
   - [CmdletBinding()] + typed [Parameter(Mandatory)] with [ValidateSet]/[ValidateNotNullOrEmpty]
   - NO Invoke-Expression / iex; call cmdlets directly with bound parameters
   - try/catch with -ErrorAction Stop on risky calls; meaningful $_ handling
   - logging ON: structured Write-Verbose / a transcript / an audit line per action
   - NO hardcoded creds: use a vault / SecureString from a store, never plaintext or $Env: echo
   - least privilege; validate/sanitize all external input
   ```

4. **Check your work**:
   ```bash
   lab check ps L7.2
   ```
