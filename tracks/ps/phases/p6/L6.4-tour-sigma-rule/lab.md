## BRIEF
Sigma is detection written as YAML that no single vendor owns: the same rule compiles to a Splunk search, a Sentinel query, an Elastic query. Reading one is how you find out what a detection actually covers — and, more usefully, what it does not.

This rule targets the exact PowerShell behaviour phases 4 and 5 taught you to recognise. Nothing here executes; a Sigma rule is compiled by a SIEM, not run by PowerShell.

## GUIDED STEPS

1. **Read the rule**:
   ```bash
   less rule.yml
   ```
   Three keys carry the whole meaning: `logsource` (which telemetry),
   `detection.selection` (what must match), and `condition` (how selections combine).
   The rest is metadata for humans.

2. **Say what it catches**:
   Work out which log it reads and what has to appear in an event for it to fire.
   Note that it matches on the *decoded* script text, which is why encoding a
   command line on its own does not evade it.

3. **Then break it**:
   This is the important half. The rule matches literal strings. Go back to the
   samples in L5.2 and L5.3 and decide whether any of those strings would appear in
   the ScriptBlock text of a payload built that way. Name the technique that wins.

4. **Write your readout**:
   Create `readout.md` with the telemetry the rule reads, at least one string it
   matches on, and one evasion it misses.

5. **Check your work**:
   ```bash
   lab check ps L6.4
   ```
