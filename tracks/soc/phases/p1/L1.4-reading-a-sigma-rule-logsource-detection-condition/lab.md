## BRIEF
Sigma rules define vendor-neutral detection logic using three core sections:
1. `logsource`: Scopes which telemetry category and product the rule evaluates against.
2. `detection`: Defines named pattern blocks testing specific field values.
3. `condition`: Boolean logic combining the named pattern blocks to trigger an alert.

In this lab, you read `rule-encoded-powershell.yml` and evaluate it against four candidate events in `candidates.jsonl` to predict which events fire and why filters suppress benign matches.

## GUIDED STEPS

1. **Read `rule-encoded-powershell.yml`**:
   Examine the rule's `logsource`, `detection` blocks, and `condition` line:
   ```bash
   cat rule-encoded-powershell.yml
   ```
   Notice:
   - `logsource`: `product: windows`, `category: process_creation` (Sysmon Event ID 1 / Windows Security 4688).
   - `selection_img`: `Image|endswith: '\powershell.exe'` (ECS field: `process.executable`).
   - `selection_cli`: `CommandLine|contains: '-enc'` (ECS field: `process.command_line`).
   - `filter_backup`: `ParentImage|endswith: '\veeam.backup.svc.exe'` (ECS field: `process.parent.executable`).
   - `condition`: `selection_img and selection_cli and not filter_backup`.

2. **Evaluate `candidates.jsonl` events**:
   Inspect the candidate events:
   ```bash
   jq -c '{id: .["event.id"], dataset: .["event.dataset"], parent: .["process.parent.executable"], exe: .["process.executable"], cli: .["process.command_line"]}' candidates.jsonl
   ```
   - Event `CM-0311-0201` (`q1`): `powershell.exe` spawned from `WINWORD.EXE` with `-enc` → `y` (matches `selection_img` and `selection_cli`, not suppressed by `filter_backup`).
   - Event `CM-0311-0021` (`q2`): `powershell.exe` spawned from `veeam.backup.svc.exe` with `-enc` → `n` (suppressed by `filter_backup`).
   - Event `CM-0312-0233` (`q3`): Zeek DNS query (`event.dataset: "zeek.dns"`) → `n` (`logsource` mismatch: not process creation).
   - Event `CM-0312-0301` (`q4`): `pwsh.exe` (PowerShell 7) spawned from `explorer.exe` with `-enc` → `n` (`Image|endswith` specifies `\powershell.exe`, missing `pwsh.exe`).

3. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each field in `answers.txt`:
   - `q1`: Does `CM-0311-0201` fire? (`y`)
   - `q2`: Does `CM-0311-0021` fire? (`n`)
   - `q3`: Does `CM-0312-0233` fire? (`n`)
   - `q4`: Does `CM-0312-0301` fire? (`n`)
   - `q5`: Filter key name excluding `CM-0311-0021` (`filter_backup`)
   - `q6`: Executable basename needed for `CM-0312-0301` to match (`pwsh.exe`)

4. **Check your work**:
   ```bash
   lab check soc L1.4
   ```
