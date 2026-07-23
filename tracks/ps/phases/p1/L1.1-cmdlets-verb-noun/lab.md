## BRIEF
PowerShell cmdlets follow the standard `Verb-Noun` naming convention.
The verb signals the cmdlet's side-effect class: `Get` is read-only, `Set`/`Remove`/`Stop` modify state, and `Invoke`/`Start` execute actions.
In this lab, you extract approved verbs with `Get-Verb` and map cmdlet verb classes.

## GUIDED STEPS

1. **Extract approved verbs using `Get-Verb`**:
   Run PowerShell to export the list of official verbs into `verbs.txt`:
   ```bash
   pwsh -Command 'Get-Verb | Select-Object -ExpandProperty Verb > verbs.txt'
   ```

2. **Inspect cmdlet verb side-effect classes**:
   Copy `files/decode.txt` to `decode.txt` and review the verb-noun mappings:
   ```bash
   cp files/decode.txt decode.txt
   cat decode.txt
   ```

3. **Verify `Invoke-Expression` mapping**:
   Confirm that `decode.txt` explicitly maps `Invoke-Expression` to the `execute` side-effect class.

4. **Check your work**:
   ```bash
   lab check ps L1.1
   ```
