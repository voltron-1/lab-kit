## BRIEF
Everything so far in this phase has been one technique at a time. A real loader puts them all together in service of a structure — and the structure is what you actually report.

`loader-structure.txt` is that structure with the payload taken out: no code, no real indicators, nothing runnable. What is left is the shape almost every commodity PowerShell loader shares — **decode config → establish C2 → beacon and task** — plus the runtime string assembly that hides all of it from a plain-string scan.

This is a TOUR: you are not decoding anything here. You are reading for intent and writing down what an analyst would put in a ticket.

## GUIDED STEPS

1. **Read the structure**:
   ```bash
   less loader-structure.txt
   ```
   Read it once end to end before writing anything. Then read it a second time
   asking a single question of each section: *what would I tell a colleague this
   stage is for?*

2. **Find the dangerous line**:
   One line in stage 3 is categorically different from everything around it —
   it is the only place attacker-controlled data becomes code. Identify it, and
   note what makes it different from the sleep and the web request next to it.

3. **Write your tour**:
   Create `tour.md`. Name the three stages in order, say what each one is *for*
   (not just what it does), give the defanged C2 the config resolves to, and
   explain why almost nothing in the file can be found with a plain-string
   search. Write it as if the next analyst has to act on it.

4. **Check your work**:
   ```bash
   lab check ps L5.6
   ```
