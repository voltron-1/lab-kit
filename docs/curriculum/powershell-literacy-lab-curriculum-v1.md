# POWERSHELL LITERACY LAB — Curriculum Map v1.0

**Read. Deobfuscate. Audit. Direct.**
A terminal-based PowerShell comprehension course for security work.

---

## 1. The Premise

PowerShell is not a third shell to learn. It occupies a unique position in your stack:

- **It is the #1 offensive tool on Windows.** Empire, PowerSploit, Cobalt Strike staging, Invoke-Mimikatz, download cradles, encoded payloads — almost every Windows intrusion chain touches PowerShell. Reading it is a core SOC analyst skill, and it feeds directly into your Tier 1 course.
- **It connects to the Windows internals layer no other shell can reach natively.** .NET, COM, WMI/CIM, the registry, ACLs — all accessible from a PS one-liner. That's what makes it dangerous in attacker hands, and why reading it requires understanding that layer.
- **It is not Bash with a Windows costume.** The fundamental architecture is different: PowerShell pipelines pass **objects**, not text. That one fact changes how you read every line of it. Bash's footguns are quoting and injection. PowerShell's footguns are .NET exposure, AMSI evasion, and the illusion that Execution Policy is a security control.
- **It generates the telemetry your SOC ingests.** ScriptBlock logging (Event ID 4104), Module logging, and Transcription are three of the most important Windows event sources you'll ever work with. Understanding the language is what makes those logs legible.

Four skills, in order:

1. **Object-pipeline literacy** — read any PS pipeline and know what type of object is flowing through it and what property is being selected at the end
2. **Windows-layer reading** — recognize .NET method calls, COM objects, WMI queries, and registry access for what they are
3. **Deobfuscation & attack pattern recognition** — reconstruct what an obfuscated payload actually does; recognize download cradles, AMSI bypass patterns, and Empire-style stagers on sight
4. **AI direction** — spec PowerShell that is auditable, logged, and hardened; review AI output like a lead analyst

Same rule as the other tracks: AI writes the code, you understand it. Every lab is built around existing code you read, decode, predict, deobfuscate, or audit.

---

## 2. How It Works (RedHat Academy Mechanics)

Same machinery as the Rust, Bash, and SOC tracks. Registers into the shared `lab` CLI on Dragon-Zord.

### The `lab` CLI

| Command | What it does |
|---|---|
| `lab status` | All tracks, phase map, ✓ / ○ / ⏭ per lab |
| `lab start ps <id>` | Opens the lab: prints the brief, stages the files |
| `lab check ps <id>` | Grades the lab. Pass = next lab unlocked |
| `lab resume` | Where you stopped, last recap, re-primed in 30 seconds |
| `lab hint ps <id>` | 3 graduated levels, never the answer at level 1 |

### Environment Note

Labs target **PowerShell 7+ (pwsh)** installed on WSL2 Ubuntu — cross-platform PS. Selected labs have a **Windows PS 5.1 variant** noted in meta.json (for behaviors that differ: AMSI, Constrained Language Mode, certain COM paths). The WSL2/pwsh path is always the graded path so nothing depends on a Windows session being open, but Windows reps are available when you want them.

---

## 3. Lab Types

Mostly shared with other tracks, plus one new type that only exists here.

| Type | What you do | Skill trained |
|---|---|---|
| **PREDICT** | Read a script or one-liner, predict the output or object type before running | Pipeline literacy |
| **DECODE** | Working code + "what does this do and why?" | Comprehension |
| **FIX** | Broken or unsafe script — read the error, apply the minimal fix | Debugging |
| **TAME** | Working-but-dangerous script — harden it (error handling, logging, least privilege) | Safety reflex |
| **AUDIT** | Find the security flaw — download cradle, AMSI bypass pattern, credential exposure | Security review |
| **DEOBFUSCATE** | Take an obfuscated payload — base64, string concat, format tricks — and reconstruct what it actually does | **The SOC superpower** |
| **TOUR** | Guided walkthrough of a real offensive or defensive PS tool | Codebase navigation |
| **DIRECT** | Write a spec for AI, grade the output against a checklist | Your actual workflow |
| **GUIDED** | Straight follow-along (tooling setup) | Environment ops |

**DEOBFUSCATE is the signature type of this track.** It has no equivalent in Rust or Bash. Attacker PowerShell is almost never clean — it arrives encoded, reversed, concatenated, or run through Invoke-Obfuscation. The ability to sit with a 4104 ScriptBlock event and reconstruct the payload step by step is a direct SOC analyst skill, and it is what separates an analyst who works PS alerts from one who escalates them reflexively.

---

## 4. ADHD Design Contract

Unchanged from the other tracks — same commitments, honored every lab.

- **Atomic:** every lab completes in 10–20 minutes.
- **One concept per lab.** Never two.
- **Hard checkpoint every lab.** `lab check` passing = a real, saved win.
- **Re-entry in 30 seconds.** `lab resume` reorients you after a day or a month.
- **Hint ladder, not stuck-spirals.** Three graduated hints before frustration.
- **Zero prerequisite reading.** Everything you need is in the lab brief.
- **Spaced recall.** The first lab of every phase opens with a 5-question quiz pulling from earlier phases.

---

## 5. Phase Map (Overview)

| Phase | Name | Labs | After this phase you can… |
|---|---|---|---|
| **0** | Toolchain & Kit | 3 | Run pwsh; explain PS5.1 vs PS7; explain Execution Policy honestly |
| **1** | The Object Pipeline | 8 | Read any PS pipeline; know what object type is flowing and what property comes out |
| **2** | Control Flow, Errors & Modules | 7 | Read PS logic, error handling, and module imports fluently |
| **3** | The Windows Integration Layer | 8 | Recognize .NET, COM, WMI, registry, and ACL access in any script |
| **4** | PowerShell as Attack Surface | 9 | Spot download cradles, encoded payloads, AMSI bypass patterns, and LOLBin calls |
| **5** | Deobfuscation & Malware Reading | 7 | Reconstruct a layered obfuscated payload; read a 4104 ScriptBlock event |
| **6** | Reading Real Security Tools | 5 | Tour PowerView, a threat-hunting collector, and a PS-targeted Sigma rule |
| **7** | Directing & Auditing AI PowerShell | 7 | Spec, review, and CI-gate AI-generated PS. Capstone. |

**54 labs total.** No schedule, no deadlines — a chain of checkpoints.

---

## 6. Phase Detail

### Phase 0 — Toolchain & Kit
*Plumbing: PS7 on WSL2, the kit, and the first honest conversation about Execution Policy.*

| Lab | Title | Type |
|---|---|---|
| L0.1 | Install pwsh on WSL2; verify version; first command | GUIDED |
| L0.2 | Meet the lab CLI — start, check, resume for the ps track | GUIDED |
| L0.3 | PS 5.1 vs PS 7, Windows vs cross-platform, and Execution Policy — what it is and what it is NOT | DECODE |

**Exit gate:** given three behaviors (Execution Policy bypass, AMSI, Constrained Language Mode), you correctly classify each as "real security control" or "speed bump with documented bypasses."

**Why L0.3 matters immediately:** Execution Policy is the most misunderstood "security feature" in Windows environments. Every attacker bypasses it in the first five minutes. An analyst who thinks it's a control is already behind.

---

### Phase 1 — The Object Pipeline
*The single mental model that unlocks PS: cmdlets return .NET objects, the pipeline passes those objects, and the text you see on screen is just the default display representation. Almost every PS misread is a confusion between the object and its display.*

| Lab | Title | Type |
|---|---|---|
| L1.1 | Cmdlets and the verb-noun pattern — reading `Get-Process`, `Set-Item`, `Invoke-Command` at a glance | DECODE |
| L1.2 | **Objects, not text** — why `Get-Process | grep chrome` fails and `Where-Object` works | PREDICT |
| L1.3 | `Get-Member` — the most important cmdlet for reading unfamiliar PS | DECODE |
| L1.4 | `Select-Object` and properties — what you're extracting from the object | PREDICT |
| L1.5 | `Where-Object` — filtering the stream | PREDICT |
| L1.6 | `ForEach-Object` and `$_` / `$PSItem` — reading loops in pipelines | PREDICT |
| L1.7 | Variables, typing, and `$null` — how PS handles types silently | DECODE |
| L1.8 | **Phase gate:** five pipelines — for each, name the input object type, the operation, and the output | PREDICT |

**Security hook:** L1.2 is the foundation for reading attacker pipelines. Empire and PowerSploit are heavily pipeline-based — an analyst who doesn't understand the object model sees noise; one who does sees the data being enumerated and exfiltrated.

---

### Phase 2 — Control Flow, Errors & Modules
*Reading PS logic — the constructs that show up in every script, admin or attacker.*

| Lab | Title | Type |
|---|---|---|
| L2.1 | `if` / `elseif` / `else` and comparison operators — `-eq`, `-ne`, `-like`, `-match` | DECODE |
| L2.2 | `switch` — the PS switch is more powerful than most languages' (regex, wildcard, file) | DECODE |
| L2.3 | Loops — `for`, `foreach`, `while`, `do-while` | PREDICT |
| L2.4 | Functions and parameters — reading `[Parameter()]` decorators and `[CmdletBinding()]` | DECODE |
| L2.5 | Error handling — `try/catch/finally`, `$Error`, `-ErrorAction`, `$?` | DECODE |
| L2.6 | Modules — `Import-Module`, `Get-Command`, `Get-Module`; reading a module manifest | DECODE |
| L2.7 | **Phase gate:** read a 60-line admin script cold, answer 10 comprehension questions | DECODE |

**Security hook:** L2.4 is important because sophisticated PS malware uses `[CmdletBinding()]` and proper parameter decorators to look legitimate. Knowing what those look like separates "this is structured code" from "this is an admin script" in triage.

---

### Phase 3 — The Windows Integration Layer
*What makes PowerShell uniquely dangerous: the reach into Windows internals that no other cross-platform shell has. Every lab in this phase directly maps to a real attack technique.*

| Lab | Title | Type |
|---|---|---|
| L3.1 | .NET method calls — `[System.Net.WebClient]`, `[System.Convert]`, `[System.Text.Encoding]` | DECODE |
| L3.2 | COM objects — `New-Object -ComObject Shell.Application`, `WScript.Shell` | DECODE |
| L3.3 | WMI/CIM — `Get-WmiObject`, `Get-CimInstance`; why attackers love WMI | DECODE |
| L3.4 | The registry — `Get-ItemProperty HKLM:\...`, persistence paths | DECODE |
| L3.5 | `Invoke-Expression` (iex) — PS's `eval`; why it's in almost every stager | AUDIT |
| L3.6 | Remoting and WinRM — `Invoke-Command`, `Enter-PSSession`; lateral movement reading | DECODE |
| L3.7 | ACLs and `Get-Acl` / `Set-Acl` — permission enumeration and abuse patterns | DECODE |
| L3.8 | **Phase gate:** identify the Windows subsystem being accessed in ten one-liners | AUDIT |

**Security hook:** L3.1 + L3.5 together are the core of a download cradle — `[System.Net.WebClient]::DownloadString(url) | iex` is the canonical stager. You meet the pieces here so Phase 4 is recognition, not discovery.

---

### Phase 4 — PowerShell as Attack Surface
*The phase that makes you dangerous as a reviewer. How attackers use PS, what the telemetry looks like, and the logging layer that feeds your SOC.*

| Lab | Title | Type |
|---|---|---|
| L4.1 | Download cradles — the canonical patterns; `DownloadString | iex`, `WebRequest`, `BitsTransfer` | AUDIT |
| L4.2 | Encoded commands — `-EncodedCommand`, base64 + UTF-16LE, and the `powershell.exe` command-line signature | AUDIT |
| L4.3 | AMSI — what it actually does, where it hooks, what bypass attempts look like in behavior | DECODE |
| L4.4 | Constrained Language Mode — what it restricts, what it doesn't, AppLocker/WDAC relationship | DECODE |
| L4.5 | PowerShell logging — ScriptBlock (4104), Module logging, Transcription; reading a 4104 event | DECODE |
| L4.6 | LOLBin calls from PS — `certutil`, `mshta`, `rundll32`, `regsvr32` invoked via PS | AUDIT |
| L4.7 | Credential exposure — `ConvertTo-SecureString`, plain-text creds in scripts, `$Env:` abuse | AUDIT |
| L4.8 | Empire and PowerSploit patterns — reading the structure without the payload | TOUR |
| L4.9 | **Phase gate:** five malicious one-liners — classify technique, ATT&CK ID, and what log evidence it generates | AUDIT |

**Security hook:** L4.5 is the hinge between this track and your SOC analyst course. After this lab, a 4104 ScriptBlock event is not an opaque blob — it is a readable artifact with a story. The two courses reinforce each other here.

---

### Phase 5 — Deobfuscation & Malware Reading
*The SOC superpower. Attackers obfuscate PS because AMSI and defenders look for strings. Your job is to peel the layers and name what the script actually does.*

| Lab | Title | Type |
|---|---|---|
| L5.1 | Base64 decode pipeline — `[System.Convert]::FromBase64String()` → `[System.Text.Encoding]::Unicode.GetString()` | DEOBFUSCATE |
| L5.2 | String concatenation obfuscation — `"po"+"wer"+"shell"`, char arrays, `-join` | DEOBFUSCATE |
| L5.3 | Format string obfuscation — `"{0}{2}{1}" -f 'I','x','E'` and similar | DEOBFUSCATE |
| L5.4 | String reversal — `$s[-1..-$s.Length] -join ''` | DEOBFUSCATE |
| L5.5 | Layered obfuscation — a payload wrapped in multiple of the above techniques | DEOBFUSCATE |
| L5.6 | Reading a sanitized real-world loader — structure, staging, and what the C2 call looks like | TOUR |
| L5.7 | **Phase gate:** multi-layer obfuscated payload — reconstruct the plain-text payload and name the technique | DEOBFUSCATE |

**Security hook:** every lab in this phase is a real SOC task. The 4104 event in your SIEM arrives encoded. The analyst who can decode it writes the escalation ticket. The analyst who can't writes "suspicious PowerShell activity."

---

### Phase 6 — Reading Real Security Tools
*TOUR phase — production PowerShell, defender and attacker. The goal is tool navigation, not memorization.*

| Lab | Title | Type |
|---|---|---|
| L6.1 | Tour: PowerView — AD enumeration functions, what data they collect and why it matters | TOUR |
| L6.2 | Tour: a PS-based IR collector — what telemetry it pulls and how to read the output | TOUR |
| L6.3 | Tour: a threat-hunting script — `Get-WinEvent` pipelines reading security logs | TOUR |
| L6.4 | Tour: a Sigma rule targeting PS (back to the detection engineering connection) | TOUR |
| L6.5 | **Phase gate:** solo tour of an unseen PS security tool, answer questions cold | TOUR |

**Why PowerView:** it's the standard AD enumeration tool used in nearly every red team and many real intrusions. Reading PowerView output and understanding the function that generated it is a direct analyst skill.

---

### Phase 7 — Directing & Auditing AI-Generated PowerShell
*Your workflow, formalized. AI writes PS badly — no error handling, no logging, weak parameter validation, and it loves bare `iex` calls. Expert level here means your specs force auditable output.*

| Lab | Title | Type |
|---|---|---|
| L7.1 | Why AI PS is risky by default — recurring failure patterns (iex, no logging, hardcoded creds) | AUDIT |
| L7.2 | The safe-PS spec — error handling, ScriptBlock logging on, no iex, `[CmdletBinding()]` | DIRECT |
| L7.3 | The AI-PS review checklist v1 | AUDIT |
| L7.4 | Review reps — 3 AI-generated scripts, find every flaw | AUDIT |
| L7.5 | CI guardrails — PSScriptAnalyzer as a merge gate (PS equivalent of ShellCheck) | GUIDED |
| L7.6 | **Capstone:** direct + audit a PS IR triage / log-collection script | DIRECT |
| L7.7 | **Capstone gate:** ship a hardened, PSScriptAnalyzer-clean script with logging and error handling | AUDIT |

**Why this capstone:** a PS IR triage / log-collection script is a real SOC artifact — the kind of thing a Tier 1 analyst runs on a suspicious host to pull evidence. Building it by directing and auditing AI, then verifying the output is safe to run, closes the loop between all four tracks.

---

## 7. Cross-Track Connections

This course ties directly into the others — these are the reinforcement points worth knowing:

| This lab | Connects to |
|---|---|
| L4.5 — 4104 ScriptBlock logging | SOC L3.2 — Sysmon / Windows events; you now read the source of those events |
| L3.5 — `iex` | Bash L3.7 — `eval`; same concept, same danger, both tracks |
| L4.1 — download cradles | SOC L3.6 — LOLBins in victim telemetry; the two sides of the same attack |
| L4.8 — Empire patterns | SOC L5.4 — sandbox reports; you recognize the tool from both its source and its detonation |
| L5.1–5.7 — deobfuscation | SOC L4.5 — reading obfuscated shell; same skill, Windows side |
| L7.5 — PSScriptAnalyzer | Bash L7.5 — ShellCheck as a merge gate; same posture, different language |

---

## 8. Delivery Plan

Built **one phase at a time**, same as every other track.

1. **You approve this map** (edits welcome — labs can be added, cut, or reordered).
2. **First build ships Phase 0 + Phase 1 together** — as a drop-in folder for the existing lab-kit repo. One command registers it; your progress file is never touched.
3. **Each later phase ships as a drop-in folder** + one registration command.
4. Between phases, anything can be adjusted.

The `lab` CLI is already built by the Bootstrap session — PowerShell drops in as track `ps` alongside `rust`, `bash`, and `soc`.

---

## 9. Open Items for Your Review

- **Name:** `ps` as the track identifier, `powershell-literacy-lab` as the full name. Rename freely.
- **Deobfuscation samples (Phase 5):** all synthetic — built to match real obfuscation patterns without using real malware. Say the word if you want them calibrated to a specific threat actor's style (e.g., TA505, Lazarus PS patterns).
- **Tour targets (Phase 6):** PowerView + PS IR collector + threat-hunting script + Sigma rule is the current pick. PowerSploit, Nishang, or your own CARDINAL scripts are swap candidates.
- **Capstone (L7.6–7.7):** PS IR triage collector is the current pick. Alternatives: a Windows log forwarder to your ECS pipeline, a PS-based IOC scanner, or a Get-WinEvent threat hunt wrapper.
- **PSScriptAnalyzer:** this is the PS equivalent of ShellCheck — it needs to be introduced earlier than Phase 7 (probably L0.1). The Phase Builder will catch this; flagging it now.
- **Windows PS 5.1 variants:** currently optional overlays on Phase 4–5 labs. Say the word to make them first-class for AMSI and CLM labs specifically, since those behaviors only exist in 5.1.

---

*v1.0 — awaiting approval before Phase 0+1 build.*
