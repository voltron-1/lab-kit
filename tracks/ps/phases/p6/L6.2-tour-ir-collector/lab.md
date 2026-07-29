## BRIEF
An incident-response collector is the script someone runs on a suspect host to gather evidence before anything is cleaned up. Reading one tells you what evidence *exists* to ask for — which is the thing you actually need when you are handed an incident and do not know where to start.

This one is shipped as an excerpt plus a sample of its output. Nothing runs: several of its cmdlets are Windows-only, and a collector is a thing you read before you trust it anyway.

## GUIDED STEPS

1. **Read the collector**:
   ```bash
   less collector.ps1
   ```
   It has four evidence sections. For each, ask what question it answers about a
   compromised host — the section comments give the answer if you get stuck.

2. **Read its output alongside it**:
   ```bash
   less sample-report.json
   ```
   One key per section. Look at the two autostart entries in particular and decide
   which one you would escalate, and why. The collector gathered both without
   judging either — the judging is your job.

3. **Write your readout**:
   Create `readout.md` naming the evidence categories the collector gathers and
   what each is for, plus why it serializes everything into one structured report
   instead of printing it to the console.

4. **Check your work**:
   ```bash
   lab check ps L6.2
   ```
