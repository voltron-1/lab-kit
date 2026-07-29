## BRIEF
Phase 6 changes the question. Up to now you have been reading *techniques* — a cradle, an encoding, a reversal. From here you read *tools*, and the skill is navigating one you have never seen and saying what it does.

PowerView is the standard Active Directory enumeration toolkit. You are not going to run it — it needs Windows and a domain, and this lab ships no PowerView at all, only a sanitized catalog of function names and what each collects. That is deliberate, and it is enough: the name alone tells you what an operator took.

## GUIDED STEPS

1. **Read the catalog**:
   ```bash
   less powerview-catalog.txt
   ```
   Read it once through. Then look again at the function names alone, ignoring
   the descriptions, and see how much you can already predict from the verb and
   the noun. That is the point of the lab.

2. **Find the odd one out**:
   Six of these functions answer one kind of question. One answers a different
   kind. Work out which, and what makes it different — the catalog tells you, but
   see if you get there first.

3. **Write your tour**:
   Create `tour.md` mapping at least three functions to the data they collect and
   the ATT&CK technique they represent. Cover `Get-NetUser` and
   `Find-LocalAdminAccess` among them. Write it for a colleague who has just seen
   one of these names in a 4104 event and needs to know what it means.

4. **Check your work**:
   ```bash
   lab check ps L6.1
   ```
