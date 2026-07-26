## BRIEF
Security analysts rely on two core conceptual models during investigation and response:
1. **Cyber Kill Chain**: Sequences adversary progression across seven stages: `recon`, `weaponization`, `delivery`, `exploitation`, `installation`, `c2`, and `actions` (on objectives).
2. **Pyramid of Pain**: Ranks indicator types by the cost incurred by the adversary to modify them when defenders block them: `trivial` (hashes), `easy` (IPs), `simple` (domains), `annoying` (host/network artifacts), `challenging` (tools), and `tough` (TTPs / behavior).

In this lab, you map incident beats from `incident-brief.md` to the Cyber Kill Chain and rate indicators in `indicators.csv` on the Pyramid of Pain.

## GUIDED STEPS

1. **Review the Cyber Kill Chain Stages**:
   - `recon`: Information gathering off-network (e.g. WHOIS lookup, typosquat domain registration).
   - `weaponization`: Building weaponized payloads off-network (e.g. embedding malicious macros in Office documents).
   - `delivery`: Transmission of payload into target environment (e.g. email attachment landing in inbox).
   - `exploitation`: Execution of malicious code on target host (e.g. macros running, WINWORD spawning PowerShell).
   - `installation`: Establishing persistence to survive host reboot (e.g. registry Run key creation).
   - `c2`: Command and Control beaconing channel established to external attacker infrastructure.
   - `actions`: Executing adversary objectives (e.g. staging data, exfiltration).

2. **Review the Pyramid of Pain Levels**:
   - `trivial`: File hashes (SHA256, MD5) — trivial for attacker to change by altering 1 byte.
   - `easy`: IP addresses — easy to change using proxies or cloud infrastructure.
   - `simple`: Domain names — simple to re-register or rotate.
   - `annoying`: Network/Host Artifacts (User-Agents, file paths) — annoying to reconfigure.
   - `challenging`: Tools — challenging to rewrite custom malware binaries or frameworks.
   - `tough`: TTPs / Behaviors — tough to alter core operational habits and techniques.

3. **Inspect the incident brief and indicators**:
   ```bash
   cat incident-brief.md
   cat indicators.csv
   ```

4. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each field in `answers.txt`:
   - `q1`: Kill-chain stage for beat B (weaponization of `.docm`) → `weaponization`
   - `q2`: Kill-chain stage for beat D (macro execution / `WINWORD` spawning `powershell`) → `exploitation`
   - `q3`: Kill-chain stage for beat E (registry Run key persistence) → `installation`
   - `q4`: Pyramid level for indicator `i1` (SHA256 hash) → `trivial`
   - `q5`: Pyramid level for indicator `i3` (domain `c2.stonewick.example`) → `simple`
   - `q6`: Pyramid level for indicator `i5` (User-Agent string) → `annoying`
   - `q7`: Indicator row ID (`i1`..`i6`) that costs the attacker MOST to replace → `i6`

5. **Check your work**:
   ```bash
   lab check soc L1.6
   ```
