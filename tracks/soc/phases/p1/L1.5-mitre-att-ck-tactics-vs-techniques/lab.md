## BRIEF
The MITRE ATT&CK framework provides a standardized language for describing adversary behavior.
- **Tactics** (the adversary's *why*): High-level goals represented by matrix columns (e.g. Credential Access `TA0006`, Execution `TA0002`).
- **Techniques** (the *how*): Specific methods used to achieve a tactic goal (e.g. Brute Force `T1110`).
- **Sub-techniques** (the *specific how*): Precise implementations of a technique (e.g. Password Spraying `T1110.003`).

Mapping security alerts to specific ATT&CK technique IDs allows SOC teams to categorize threats based on behavior rather than perishable tool names. In this lab, you explore the ATT&CK Matrix and map three Coppermine SIEM alerts (`CM-A-31`, `CM-A-32`, `CM-A-33`) to their exact ATT&CK technique IDs using `attack-excerpt.json`.

## GUIDED STEPS

1. **Explore the MITRE ATT&CK Framework**:
   - Open [MITRE ATT&CK Enterprise Matrix](https://attack.mitre.org).
   - Observe the column headers representing **Tactics** (e.g., Credential Access, Execution, Command and Control).
   - Locate the **Credential Access** column and click **Brute Force (T1110)** to view its four sub-techniques (T1110.001 - T1110.004).
   - Open **Password Spraying (T1110.003)** and review the analyst-focused sections: *Procedure Examples*, *Data Sources*, and *Detection*.

2. **Explore ATT&CK Navigator & Layers**:
   - Open [ATT&CK Navigator](https://mitre-attack.github.io/attack-navigator/).
   - Click **Create New Layer** → **Enterprise ATT&CK**.
   - Use the search magnifier tool to search for "password spraying", select the technique, and assign a score of `1`.
   - Observe how the technique cell is highlighted under Credential Access.
   - Staged file `layer-sample.json` provides an example of an exported ATT&CK Navigator JSON layer.

3. **Inspect staged alerts and ATT&CK reference**:
   View the 3 staged alerts in `alerts.jsonl` and the mini ATT&CK reference table in `attack-excerpt.json`:
   ```bash
   jq . alerts.jsonl
   jq . attack-excerpt.json
   ```

4. **Map alerts to ATT&CK Technique IDs**:
   Match each alert to its most specific ATT&CK technique ID:
   - `CM-A-31` (`q1`): Password failures across 40+ accounts from a single source → `t1110.003` (Password Spraying)
   - `CM-A-32` (`q2`): Office app (WINWORD) spawned hidden encoded interpreter (`powershell.exe`) → `t1059.001` (PowerShell)
   - `CM-A-33` (`q3`): Periodic high-entropy TXT queries to a single DNS zone (command channel) → `t1071.004` (DNS)

5. **Identify tactic and parent technique for `q1`**:
   Using `attack-excerpt.json`:
   - `q4`: Tactic slug of `t1110.003` → `credential-access`
   - `q5`: Parent technique ID of `t1110.003` → `t1110`

6. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each field (`q1` through `q5`) in lowercase.

7. **Check your work**:
   ```bash
   lab check soc L1.5
   ```
