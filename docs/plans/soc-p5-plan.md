# SOC Track — Phase 5 Build Plan (v1)

**Mode:** plan only — produced 2026-07-20 per Phase Builder step 3 (PROMPTS.md Prompt 2),
inside a PLAN-AHEAD session that plans every remaining soc phase one at a time.
**This document is the deliverable for `docs/plans/soc-p5-plan.md`** (saved there verbatim on merge).
**Binding content spec:** `docs/curriculum/soc-analyst-lab-curriculum-v1.md` — Phase 5 (§6, lines 202–214).
**Binding mechanical spec:** `docs/kit-contracts.md` + the soc quality gates in `PROMPTS.md`.
**Predecessor plans (inherited):** `soc-p01/p2/p3/p4-plan.md` — §1 universe, §2 generator, §2.1 grading,
§2.2 id registry, defanged-IOC regex-escape recipe, enrichment mocks, SO-overlay policy. Extended here.
**Scope:** 6 labs — L5.1–L5.6 (gate L5.6) — plus `tools/genevidence/` extensions (`.eml` builder,
mock-sandbox emitter, attachment fixtures) and the track's **first REPORT-lab grading contract**.

## 0. Ground rules this plan follows

- Lab list is **map-exact** (§205–212): ids, titles, types, gate on L5.6 (REPORT) — no deviations.
- Evidence **generated, never hand-written**: `.eml` files, sandbox reports, and answer keys all emit
  from one `scenario.yaml`; keys can't drift.
- **Nothing live-hostile** (PROMPTS.md soc gate): attachments are **inert simulacra** (real container
  magic bytes, benign/empty content, deterministic seeded hashes); sandbox reports are **mocked**
  detonation summaries; no sample is ever executed and no URL is ever fetched in any path.
- `.eml` files carry **full realistic headers** (Received chain, Authentication-Results, DKIM-Signature,
  Return-Path, MIME parts). Raw `.eml`/attachment/sandbox evidence is **never defanged**; prose, keys,
  and every learner submission (answers + the L5.6 report) **do** defang — graded with the soc-p2 §2
  regex-escape recipe, and for REPORT enforced as a *no-raw-IOC* check (§2.3).
- Grades **offline in the check fence** (§2.1 pattern; REPORT = rubric per §2.3). Flat-file first; SO
  overlay ungraded on L5.6 only.
- ADHD contract: one concept per lab, est 10–20 min.

## 1. Universe additions — the reported phish

Additive to `soc-p01-plan.md` §1; single source `universe.yaml`. Phase 5 reads the **M2 phish** in
depth and adds the corpus around it.

- **The malicious phish (motif M2, reused):** From `billing@copperm1ne-billing.example` (typosquat of
  `coppermine.example`), sender IP `198.51.100.71`, to `m.reyes`, `2026-03-11T15:02:00Z`, subject
  "Invoice 2026-03 — Payment Overdue", attachment `invoice_2026-03.docm`, body link
  `http://copperm1ne-billing.example/invoice` redirecting to `http://cdn.stonewick.example/pay`. Auth
  results: **spf=fail, dkim=fail, dmarc=fail** (spoofs the display name, fails alignment).
- **New lookalike/punycode anchors** (for L5.2): `copperm1ne-billing.example` (digit-1 homoglyph);
  `xn--coppermne-9zb.example` = punycode for `coppermïne.example` (homoglyph ı/i); a benign URL
  shortener `lnk.example/x9f2` used as the first hop of the redirect chain.
- **The legitimate email (job hook, for L5.5):** a real vendor invoice from `ar@northshore-freight.com`
  (an established Coppermine carrier, on the vendor allowlist), spf=pass/dkim=pass/dmarc=pass, benign
  PDF attachment, no suspicious URL — **verdict legit**. Declared in `universe.yaml` so it's a stable,
  reusable "known-good sender."
- **A spam-but-not-malicious email (for L5.5):** a marketing blast from `deals@shopnwin.example`,
  spf=pass, unsubscribe footer, no attachment/credential-harvest — **verdict spam** (not phish, not an
  incident). Separates "annoying" from "malicious."
- **Attachment fixtures (inert):** `invoice_2026-03.docm` = a real ZIP/OOXML container (magic
  `PK\x03\x04`) whose `vbaProject.bin` is an **inert marker** (a text stub, no executable macro); a
  `receipt.pdf.exe` double-extension fixture = a real PE header (`MZ`) but a zero-op inert body;
  `photo.jpg` benign control (real JPEG magic). Hashes are seeded constants matching enrichment.
- **Mock sandbox report** (for L5.4): a detonation summary of `invoice_2026-03.docm` — process tree
  (`WINWORD.EXE → powershell.exe -enc → cmd.exe`), network (`c2.stonewick.example:443` beacon, 300s),
  dropped Run key, MITRE tags (T1566.001, T1059.001, T1547.001), verdict `malicious` score 88/100 — all
  mocked, cross-consistent with the M2 endpoint/network evidence from Phases 2–3.

## 2. Generator extensions — `tools/genevidence/`

Prerequisite: `soc-p0…p4` tagged. Phase 5 adds three emitters + one verify invariant:

1. **`eml_mock`** — build RFC-5322 `.eml`: headers (From/To/Subject/Date/Message-ID/Return-Path),
   a realistic multi-hop **Received chain** (bottom = originating IP), **Authentication-Results**
   (spf/dkim/dmarc), a DKIM-Signature header, MIME body parts (text + HTML with links), and an
   attachment part (base64 of the inert fixture). Auth results are **derived** from the scenario's
   sender IP + a declared SPF record so they can't contradict the headers.
2. **`sandbox_mock`** — emit the detonation report (JSON + a human `report.md`) from scenario-declared
   process tree / network / MITRE / verdict, cross-referenced to the M2 canon ids.
3. **`attachment_fixture`** — write the inert container/PE/JPEG fixtures with **real magic bytes** and
   deterministic seeded sha256 (matching the VT/enrichment mocks).
4. **`verify.py` additions:** (a) `.eml` auth results are consistent with the sender IP + SPF record
   (a spoofed sender must fail alignment); (b) every sandbox-report IOC exists in the universe and its
   ids match the M2 canon; (c) every attachment hash equals the seeded constant used in enrichment;
   (d) the existing no-defang-in-raw / no-fang-in-prose checks run over `.eml` and report files.

## 2.1 Canonical id additions (extends prior registries)

Phase 5 mints few new event ids (it reads M2). New phish-corpus items use **`CM-<MMDD>-08xx`**; phish
alerts/cases use **`CM-A-5xx`** and case slugs `p1..p6`. Reused canon: the full M2 chain
(`CM-0311-0201` spawn, `CM-0311-0179` beacon, `CM-0311-0181` Run key) and the L1.6 indicator set
(i1 sha256 docm, i2 C2 IP, i3 C2 domain, i4 filename, i5 UA). New:

| Canonical id / slug | Item |
|---|---|
| `MAIL-M2` | the malicious M2 phish `.eml` (single source for L5.1/L5.2/L5.3/L5.4/L5.6) |
| `MAIL-LEGIT` | northshore-freight legitimate vendor invoice `.eml` (L5.5 known-good) |
| `MAIL-SPAM` | shopnwin marketing blast `.eml` (L5.5 spam-not-phish) |
| `SBX-M2` | the mock sandbox report for `invoice_2026-03.docm` (L5.4/L5.6) |

`universe.yaml` pins the phish sender/typosquat/legit-vendor so L5.5's "one is legitimate" and every
lookalike stay stable across labs.

## 2.2 (inherited) grading pattern — unchanged

§2.1 canonical pattern for DECODE/TRIAGE (presence → normalize → anchored `assert_file_contains` from
generated base64 keys → `ck_summary`); §2 regex-escape for defanged IOC keys; `harness_err` only for a
corrupt key block.

## 2.3 REPORT-lab grading contract (NEW — binding for L5.6 and every later REPORT lab)

REPORT labs grade a **required-elements rubric** on the learner's `report.md`, plus a **defang gate**,
then print a **model report** for self-comparison. Honest limitation (map §57): the check verifies
*structure and defang*, the model answer calibrates *quality*. The check.sh pattern:

```bash
assert_file_exists "report.md"
# 1. Required sections/elements (ERE, case-insensitive via a normalized copy):
assert_file_contains ".report.norm" "^## *timeline"            # a timeline section
assert_file_contains ".report.norm" "t1566\.001"              # an ATT&CK technique id (>=1, real)
assert_file_contains ".report.norm" "(verdict|disposition).*(phish|malicious|true positive)"
assert_file_contains ".report.norm" "^## *recommendation"      # a recommendation section
assert_file_contains ".report.norm" "\[\.\]"                  # >=1 defanged IOC present (bracketed dot)
# 2. Defang GATE — the report must contain NO raw IOC forms:
assert_file_not_contains "report.md" "http://[a-z]"            # raw scheme (must be hxxp://)
assert_file_not_contains "report.md" "cdn\.stonewick\.example" # raw C2 domain (must be defanged)
assert_file_not_contains "report.md" "203\.0\.113\.66"        # raw C2 IP (must be bracketed)
ck_summary
```

The **defang gate is the graded teeth** (PROMPTS.md: "check.sh for REPORT labs enforces defanging");
a report that names a raw IOC fails, teaching the habit the job requires. The required-element keys
(section names, the technique id, the verdict token) come from the generated key block so they stay
tied to the scenario. `assert_file_not_contains` is in the checklib inventory.

## 3. Decisions & flagged deviations (approve/veto with the plan)

1. **L5.6 REPORT graded on structure + defang, not exact prose** (per §2.3 / map §57). A model report
   (`model-report.md`) ships and is printed on pass for self-comparison. Veto to make it a fixed-answer
   DECODE instead (would lose the writing rep the map wants).
2. **L5.5 verdict vocabulary = `phish | legit | spam`** (not tp/fp/btp) — the reported-email domain has
   its own trichotomy, and "legit" vs "spam" is the distinction the job hook turns on. Veto to reuse
   tp/fp/btp.
3. **Attachments are inert simulacra with REAL magic bytes** so L5.3's `file`/`xxd` teaching is
   authentic, but no macro executes and nothing detonates (map "inert simulacra"). The `.docm` is a
   real OOXML/ZIP with a text-stub `vbaProject.bin`; the `.pdf.exe` is a real PE header with a zero-op
   body. Veto only if you want fully synthetic (non-parsing) fixtures.
4. **Punycode shown both raw and decoded.** L5.2 ships `xn--…` in the raw URL (evidence) and asks the
   learner to decode it; the decoded homoglyph domain is defanged in the answer. `idn`/`python -c
   'idna'` optional; the graded answer is the decoded label, keyed.
5. **SO overlay ungraded on L5.6 only** (investigate the phish in the Hunt UI's email/case view).
   Flat-file `.eml` path always graded.
6. **Defanged IOCs graded in answers and enforced in the report** (D of every prior phase + §2.3).

## 3.5 Self-review corrections applied

- **Received chain must read bottom-up unambiguously.** L5.1 collapses if the originating IP is
  ambiguous. Fixed: `eml_mock` writes a 3-hop Received chain where the **bottom** hop is the attacker
  MTA (198.51.100.71) and upper hops are Coppermine's own relays; lab.md teaches "read bottom-up," and
  the key is that bottom IP.
- **Auth results can't contradict the story.** A spoofed sender that shows `dmarc=pass` would be
  incoherent. Fixed: `verify.py` derives spf/dkim/dmarc from the sender IP vs the From-domain's SPF
  record — MAIL-M2 fails all three; MAIL-LEGIT passes all three.
- **The legit email must be genuinely tempting to misjudge.** If it's obviously benign, L5.5 teaches
  nothing. Fixed: MAIL-LEGIT is an *unexpected invoice with an attachment* (the surface shape of a
  phish) but from an allowlisted vendor with passing auth and a benign PDF — the learner must check
  auth + sender reputation, not just "invoice = phish."
- **Sandbox report must be verdictable without the sample.** Fixed: SBX-M2 contains enough grounded
  evidence (process tree + network IOC + MITRE + score) that the verdict follows from the report alone;
  L5.4 keys the verdict + the C2 IOC + a technique id, all present in the report.
- **REPORT defang gate must not false-fail on legitimate text.** `assert_file_not_contains
  "http://[a-z]"` could trip on a defanged `hxxp://` only if the learner wrote raw. Fixed: the gate
  patterns target raw schemes/domains/IPs specifically; the recap and model report model the defanged
  forms so the learner copies the right habit.

---

## 4. Phase 5 — labs

### L5.1 — Email headers — reading the Received chain; SPF, DKIM, DMARC results

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L5.1 | Email headers — reading the Received chain; SPF, DKIM, DMARC results | DECODE | false | 15 |

Dir `tracks/soc/phases/p5/L5.1-email-headers/`. **One concept:** read the Received chain bottom-up to
the originating IP, and read SPF/DKIM/DMARC as the alignment verdict.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s5-headers`, RAW):
  - `reported.eml` — MAIL-M2, full headers: 3-hop `Received` chain (bottom = attacker MTA
    198.51.100.71), `From: "Coppermine Billing" <billing@copperm1ne-billing.example>`,
    `Return-Path: <bounce@stonewick.example>` (misaligned), `Authentication-Results: spf=fail
    dkim=fail dmarc=fail`, `DKIM-Signature` (broken), MIME text+html + the `.docm` attachment part.
  - `header-legend.md` — static: how to read Received bottom-up; what spf/dkim/dmarc mean; alignment.
  - `answers.template.txt`.
- **Learner task:** parse headers (`grep`/`formail`-free — just read/`rg`); answer. Template + grammar:
  ```
  q1=   # originating IP (bottom Received hop) — DEFANGED                        -> 198.51.100[.]71
  q2=   # SPF result (pass|fail|softfail|none)                                    -> fail
  q3=   # DKIM result                                                            -> fail
  q4=   # DMARC result                                                           -> fail
  q5=   # the From-header domain — DEFANGED                                       -> copperm1ne-billing[.]example
  q6=   # does Return-Path align with the From domain? y|n                        -> n
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks (q1/q5 defanged, regex-escape);
  `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L5.1", type:"DECODE", objective:"Read an email's Received chain to the
    originating IP and interpret SPF/DKIM/DMARC alignment", gate:false, est_minutes:15}`
  - `quiz.json`:
    1. (choice) "The originating server is found in the Received chain:" a) top hop b) bottom hop —
       chains build top-down as mail is relayed, so the earliest (bottom) is the source c) the From
       header d) the Subject → **b**
    2. (choice) "`dmarc=fail` means:" a) the email is definitely malware b) the message failed
       SPF/DKIM alignment with the From domain — a strong spoofing signal c) DKIM is disabled d) the
       server is down → **b**
    3. (choice) "`From:` says Coppermine Billing but auth fails and Return-Path is a different domain.
       This is:" a) normal b) classic display-name spoofing — the friendly name lies, the headers
       don't c) a mail loop d) fine if SPF passes → **b**
  - `hints.json`: L1 "Received headers stack newest-on-top; scroll to the LAST Received line for the
    source IP. Authentication-Results holds spf/dkim/dmarc." L2 "q1 the bottom Received IP (defang it);
    q2-q4 read straight off Authentication-Results; q5 the From domain (defang); q6 compare Return-Path
    domain to From domain." L3 "q1 198.51.100[.]71; q2-q4 all fail; q5 copperm1ne-billing[.]example; q6
    n."
  - `recap.md` (3 lines): `Received headers read bottom-up: the last hop is where the mail actually
    originated, regardless of what From claims.` / `SPF, DKIM, and DMARC are the alignment verdict —
    all three failing on a billing email is a loud spoofing signal.` / `The friendly From name is free
    to forge; the headers and auth results are what you trust.`
  - **`recall.json`** (phase opener; 5, non-gating; **[VERIFY-AT-BUILD]** — Phase 4 unbuilt, sourced from
    the map's Phase 4 lab list (§189–196); matches the parked L5.1 draft in `soc-p4-plan.md` L4.8):
    1. (text) "The five triage questions end by producing a ___." → **key `verdict`** — source **L4.1**.
    2. (choice) "A high VT score on an IP hosting 400 domains is likely a ___ trap." a) shared-hosting b)
       dedicated c2 c) stale → **key a** — source **L4.3**.
    3. (text) "One password against many accounts is a password ___." → **key `spray`** — source **L4.4**.
    4. (text) "Closing a noisy-rule false positive should produce ___ feedback." → **key `tuning`** —
       source **L4.6**.
    5. (choice) "Severity is the rule's estimate; ___ is what you work first." a) priority b) risk_score
       c) confidence → **key a** — source **L4.5**.

**EVIDENCE SPEC**
```yaml
scenario: s5-headers
lab: L5.1
mail: MAIL-M2
sender: {from: billing@copperm1ne-billing.example, origin_ip: 198.51.100.71, return_path: bounce@stonewick.example}
auth: {spf: fail, dkim: fail, dmarc: fail}   # verify.py derives these from origin_ip vs SPF record
emit: {eml: files/reported.eml, legend: files/header-legend.md, answers_template: files/answers.template.txt}
answer_key: {q1: 198.51.100[.]71, q2: fail, q3: fail, q4: fail, q5: copperm1ne-billing[.]example, q6: n}
verify: [bottom Received hop == origin_ip; auth results coherent with sender spoof]
```

---

### L5.2 — URL analysis — redirect chains, lookalike domains, punycode, defang discipline

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L5.2 | URL analysis — redirect chains, lookalike domains, punycode, defang discipline | DECODE | false | 15 |

Dir `tracks/soc/phases/p5/L5.2-url-analysis/`. **One concept:** the visible link is not the
destination — follow redirect chains, spot lookalike/punycode domains, and defang everything.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s5-urls`, RAW):
  - `urls.txt` — extracted from MAIL-M2's HTML body (RAW, fanged): a redirect chain
    `http://lnk.example/x9f2` → `http://copperm1ne-billing.example/invoice` →
    `http://cdn.stonewick.example/pay`; plus a punycode link `http://xn--coppermne-9zb.example/verify`;
    plus a benign link `https://coppermine.example/portal` (the real domain, control).
  - `url-legend.md` — static: display vs destination, redirect chains, homoglyph/digit lookalikes,
    punycode `xn--`, and the defang rules (`hxxp://`, `[.]`).
  - `answers.template.txt`.
- **Learner task:** analyze the chain; answer (all IOCs defanged). Template + grammar:
  ```
  q1=   # final landing domain of the redirect chain — DEFANGED                  -> cdn.stonewick[.]example
  q2=   # the digit-homoglyph lookalike of coppermine.example — DEFANGED          -> copperm1ne-billing[.]example
  q3=   # decode the punycode xn--coppermne-9zb.example (the real unicode label,
  #        ascii-approx 'coppermïne') — DEFANGED                                  -> coppermïne[.]example
  q4=   # which link is the REAL Coppermine domain (benign)? — DEFANGED           -> coppermine[.]example
  q5=   # number of hops in the redirect chain                                    -> 3
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks (q1–q4 defanged, regex-escape;
  q3 accepts the ascii form `coppermine[.]example`-with-diacritic-note via an alternation the generator
  encodes); `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L5.2", type:"DECODE", objective:"Follow a redirect chain to its true
    destination, spot lookalike and punycode domains, and defang every IOC", gate:false, est_minutes:15}`
  - `quiz.json`:
    1. (choice) "A link displays `coppermine.example` but href is `copperm1ne.example`. This is:" a)
       a typo b) a homoglyph/digit lookalike domain — the '1' replaces the 'i' c) the same domain d) a
       redirect → **b**
    2. (choice) "A `xn--` domain is:" a) invalid b) punycode — an ASCII encoding of a Unicode
       (often homoglyph) domain; decode it before judging c) always malicious d) a subdomain → **b**
    3. (choice) "Why defang IOCs (`hxxp://`, `[.]`) in your notes and tickets?" a) style b) so a reader
       or tool can't accidentally click/resolve a live-malicious indicator c) encryption d) it's
       required by RFC → **b**
  - `hints.json`: L1 "Read urls.txt: one benign real domain, one redirect chain, one punycode. The
    chain's LAST hop is the true destination." L2 "Count the arrows for hops; the lookalike swaps a
    letter for a digit; xn-- decodes to a homoglyph of coppermine. Defang every answer." L3 "q1
    cdn.stonewick[.]example; q2 copperm1ne-billing[.]example; q3 the decoded homoglyph coppermïne
    (defanged); q4 coppermine[.]example; q5 3."
  - `recap.md` (3 lines): `The link you see is not the link you get — follow redirect chains to the
    final destination before judging.` / `Lookalikes swap letters for digits or homoglyphs, and
    punycode (xn--) hides Unicode domains that read like the real one.` / `Defang every IOC you write —
    hxxp://, [.] — so no one clicks or resolves it by accident.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s5-urls
lab: L5.2
urls:
  redirect_chain: [http://lnk.example/x9f2, http://copperm1ne-billing.example/invoice, http://cdn.stonewick.example/pay]
  punycode: {raw: xn--coppermne-9zb.example, decoded: "coppermïne.example"}
  benign_real: https://coppermine.example/portal
emit: {urls: files/urls.txt, legend: files/url-legend.md, answers_template: files/answers.template.txt}
answer_key:
  q1: cdn.stonewick[.]example
  q2: copperm1ne-billing[.]example
  q3: (coppermïne[.]example|coppermine[.]example)   # accept diacritic or ascii-approx
  q4: coppermine[.]example
  q5: "3"
verify: [redirect_chain length == 3; punycode decodes to the declared homoglyph]
```

---

### L5.3 — Attachment triage — true file types vs extensions, hashes, macro risk, safe-handling rules

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L5.3 | Attachment triage — true file types vs extensions, hashes, macro risk, safe-handling rules | DECODE | false | 15 |

Dir `tracks/soc/phases/p5/L5.3-attachment-triage/`. **One concept:** the extension lies — magic bytes
give the true type, the hash is the identity, and macro-bearing office files are the risk. Never
open/detonate.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s5-attachments`, inert fixtures, RAW):
  - `invoice_2026-03.docm` — real OOXML/ZIP (`PK\x03\x04`), contains an inert `vbaProject.bin` stub
    (macro-bearing type, but the stub is a text marker — nothing runs). Seeded sha256 = i1.
  - `receipt.pdf.exe` — double-extension; real PE header (`MZ`), zero-op inert body.
  - `photo.jpg` — benign JPEG (`\xff\xd8\xff`), control.
  - `safe-handling.md` — static: inspect in a sandbox/hex, never double-click; `file`, `xxd | head`,
    `sha256sum`; macro-bearing extensions (.docm/.xlsm), double extensions, magic vs extension.
  - `answers.template.txt`.
- **Learner task (guided reads, run for real):** `file *`; `xxd invoice_2026-03.docm | head -1`;
  `sha256sum invoice_2026-03.docm > hash.txt`; then fill answers:
  ```
  q1=   # true container type of invoice_2026-03.docm (by magic): zip|ole|pe|jpeg -> zip
  q2=   # does the .docm carry a macro project (vbaProject present)? y|n           -> y
  q3=   # the file whose REAL type is an executable despite its name               -> receipt.pdf.exe
  q4=   # sha256 of invoice_2026-03.docm (first 12 hex chars)                       -> <seeded prefix>
  q5=   # safe first step with a suspicious attachment: open|hash|reply             -> hash
  ```
- **Grading** (`check.sh`, §2.1 + produced-artifact): `assert_file_exists hash.txt`;
  `assert_file_contains_fixed hash.txt "<seeded full sha256>"` (tool output raw); normalize answers →
  anchored q1–q5 (q4 the seeded 12-char prefix); `ck_summary`.
- **Kit files:**
  - `meta.json`: `{id:"L5.3", type:"DECODE", objective:"Determine an attachment's true type by magic
    bytes, hash it, judge macro risk, and apply safe-handling — never open the sample", gate:false,
    est_minutes:15}`
  - `quiz.json`:
    1. (choice) "A file named `receipt.pdf.exe` is:" a) a PDF b) an executable using a double extension
       to look like a PDF c) safe d) a macro → **b**
    2. (choice) "`file` reports an OOXML/ZIP for a `.docm`. The macro risk lives in:" a) the extension
       b) the embedded vbaProject (VBA macros) inside the container c) the filename d) the hash → **b**
    3. (choice) "Your first move on a suspicious attachment is to:" a) open it to see b) hash it and
       enrich/sandbox — never execute it c) forward it to the user d) rename it → **b**
  - `hints.json`: L1 "`file *` reads magic bytes, not the name. `xxd | head -1` shows the first bytes:
    PK=zip, MZ=exe, ffd8=jpeg. `sha256sum` is the identity." L2 "The .docm is really a ZIP container
    (OOXML) and carries a macro project; receipt.pdf.exe is really a PE. Hash first, never open." L3
    "q1 zip; q2 y; q3 receipt.pdf.exe; q4 the sha256 prefix from your hash.txt; q5 hash."
  - `recap.md` (3 lines): `Extensions lie — magic bytes (PK, MZ, ffd8) give the true type, and a
    double extension like .pdf.exe is a classic disguise.` / `Office files ending .docm/.xlsm carry
    macros inside a ZIP container; that vbaProject is the risk, not the icon.` / `The hash is the
    sample's identity and the safe first step — inspect and enrich, never open or detonate.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s5-attachments
lab: L5.3
fixtures:
  - {name: invoice_2026-03.docm, magic: "PK\\x03\\x04", type: zip, macro: true, sha256: <i1 seeded>}
  - {name: receipt.pdf.exe, magic: "MZ", type: pe, macro: false}
  - {name: photo.jpg, magic: "\\xff\\xd8\\xff", type: jpeg, macro: false}
emit: {fixtures: files/, legend: files/safe-handling.md, answers_template: files/answers.template.txt}
answer_key: {q1: zip, q2: y, q3: receipt.pdf.exe, q4: "<i1 sha256 first 12>", q5: hash}
verify: [fixture magic bytes real; docm hash == i1 seeded constant used in enrichment; nothing executable]
```

---

### L5.4 — Reading a sandbox report — verdicting from a detonation summary without touching the sample

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L5.4 | Reading a sandbox report — verdicting from a detonation summary without touching the sample | DECODE | false | 15 |

Dir `tracks/soc/phases/p5/L5.4-sandbox-report/`. **One concept:** the sandbox detonated it so you don't
have to — read its process/network/MITRE evidence and verdict from the report alone.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s5-sandbox`, RAW): `sandbox-report.json` + `sandbox-report.md`
  (SBX-M2): `{sample: invoice_2026-03.docm, sha256: i1, verdict: malicious, score: 88,
  process_tree:[WINWORD.EXE→powershell.exe -enc→cmd.exe], network:[{dst:"c2.stonewick.example:443",
  proto:tls, beacon_s:300}], dropped:[{registry:"HKCU\\...\\Run\\OneDriveUpd"}], mitre:[T1566.001,
  T1059.001, T1547.001], signatures:["office_spawns_shell","encoded_powershell","autorun_persistence"]}`.
  `answers.template.txt`.
- **Learner task:** read the report; verdict + extract IOCs. Template + grammar:
  ```
  q1=   # the report's verdict (malicious|suspicious|clean)                       -> malicious
  q2=   # the C2 destination host the sample beaconed to — DEFANGED                -> c2.stonewick[.]example
  q3=   # the ATT&CK technique id for the initial delivery (spearphishing attach) -> t1566.001
  q4=   # the persistence artifact the sample dropped (registry key leaf)          -> onedriveupd
  q5=   # can you verdict this WITHOUT running the sample yourself? y|n             -> y
  ```
- **Grading** (`check.sh`, §2.1): presence + normalize; anchored checks (q2 defanged, regex-escape);
  `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L5.4", type:"DECODE", objective:"Verdict a sample from a mock sandbox detonation
    report — process tree, network IOCs, MITRE, score — without executing it", gate:false,
    est_minutes:15}`
  - `quiz.json`:
    1. (choice) "A sandbox report is useful because:" a) it's faster than reading b) it detonated the
       sample in isolation so you get behavior (processes, network, persistence) without risking your
       host c) it's always right d) it replaces triage → **b**
    2. (choice) "The report shows `WINWORD.EXE → powershell.exe -enc → C2 beacon`. Verdict:" a) clean b)
       malicious — document-spawned encoded shell beaconing out is textbook macro malware c) suspicious
       only d) can't tell → **b**
    3. (choice) "You should still ground each claim in the report because:" a) reports are decoration b)
       an ungrounded 'malicious' with no cited behavior isn't a verdict — the process/network evidence
       is what makes it defensible c) it's faster d) MITRE requires it → **b**
  - `hints.json`: L1 "Read the report's verdict/score, then the process_tree and network sections for
    the behavior and IOCs." L2 "The beacon dst is the C2 host (defang it); the spearphishing-attachment
    technique is T1566.001; the dropped Run key leaf is your persistence artifact." L3 "q1 malicious; q2
    c2.stonewick[.]example; q3 t1566.001; q4 onedriveupd; q5 y."
  - `recap.md` (3 lines): `A sandbox report hands you behavior — process tree, network beacons, dropped
    persistence, MITRE tags — from a safe detonation you didn't have to run.` / `Verdict from the report:
    a document spawning encoded PowerShell that beacons out and sets a Run key is malicious, full stop.`
    / `Ground every claim in a report field; an ungrounded verdict is a guess, and the IOCs go into your
    ticket defanged.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s5-sandbox
lab: L5.4
report: SBX-M2
sample: {name: invoice_2026-03.docm, sha256: <i1>}
detonation: {verdict: malicious, score: 88, process_tree: [WINWORD.EXE, powershell.exe -enc, cmd.exe],
             network: [{dst: c2.stonewick.example:443, beacon_s: 300}], dropped_runkey: OneDriveUpd,
             mitre: [T1566.001, T1059.001, T1547.001]}
emit: {json: files/sandbox-report.json, md: files/sandbox-report.md, answers_template: files/answers.template.txt}
answer_key: {q1: malicious, q2: c2.stonewick[.]example, q3: t1566.001, q4: onedriveupd, q5: y}
verify: [report IOCs ⊆ universe M2 canon; sha256 == i1; mitre ids valid]
```

---

### L5.5 — The phish queue — six reported emails, verdict each (including the legitimate one)

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L5.5 | The phish queue — six reported emails, verdict each (including the legitimate one) | TRIAGE | false | 20 |

Dir `tracks/soc/phases/p5/L5.5-phish-queue/`. **One concept:** not every reported email is a phish —
verdict six as `phish | legit | spam`, and don't burn the one legitimate sender (job hook).

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s5-phish-queue`, RAW): six `.eml` in `mail/p1..p6.eml`:
  - **p1** MAIL-M2 (malicious macro phish) → **phish**.
  - **p2** credential-harvest (spf=fail, link to `login-coppermine[.]example` fake portal) → **phish**.
  - **p3** MAIL-LEGIT (northshore-freight invoice, auth pass, allowlisted vendor) → **legit** (the trap).
  - **p4** MAIL-SPAM (shopnwin marketing, auth pass, unsubscribe, no harvest) → **spam**.
  - **p5** internal IT notice from `helpdesk@coppermine.example`, auth pass, no links → **legit**.
  - **p6** BEC-style wire-fraud (display-name spoof of the CFO, reply-to external, no attachment) →
    **phish**.
  - `triage-checklist.md` — static: auth results, sender reputation/allowlist, link/attachment,
    intent (harvest/wire/malware vs marketing vs internal).
  - `answers.template.txt` — `q1..q6`.
- **Learner task:** verdict each. Template grammar: `qN=` one of `phish|legit|spam`.
- **Grading** (`check.sh`, §2.1): presence + normalize; six anchored checks; `ck_summary` last.
- **Kit files:**
  - `meta.json`: `{id:"L5.5", type:"TRIAGE", objective:"Verdict six reported emails as phish, legit, or
    spam — including recognizing the legitimate one", gate:false, est_minutes:20}`
  - `quiz.json`:
    1. (choice) "Calling a legitimate vendor invoice a phish is:" a) safe — better paranoid b) a false
       positive that erodes helpdesk/user trust and buries real reports c) impossible d) fine → **b**
    2. (choice) "Marketing spam that passes auth and has an unsubscribe link is:" a) phish b) spam —
       annoying, not malicious; not an incident c) legit business mail d) BEC → **b**
    3. (choice) "A CFO 'wire request' from an external reply-to with a spoofed display name is:" a)
       legit b) BEC phishing — no malware needed, the ask is the attack c) spam d) internal → **b**
  - `hints.json`: L1 "For each: check auth (spf/dkim/dmarc), sender (allowlisted vendor? internal?),
    and intent (harvest/wire/malware vs marketing vs internal notice)." L2 "Two are malicious phish by
    payload/link, one is BEC by the ask, one is marketing spam, and two are genuinely legitimate — the
    vendor invoice and the internal notice both pass auth." L3 "p1 phish; p2 phish; p3 legit; p4 spam;
    p5 legit; p6 phish."
  - `recap.md` (3 lines): `A phish queue has three answers, not one: malicious phish, legitimate mail,
    and spam that's merely annoying.` / `Check auth, sender reputation, and intent — an unexpected
    invoice from an allowlisted vendor with passing auth is legit, not a phish.` / `Over-calling phish
    burns user trust and buries the real reports; the legitimate email is a graded answer for a reason.`
  - No `recall.json`.

**EVIDENCE SPEC**
```yaml
scenario: s5-phish-queue
lab: L5.5
mails:
  - {slug: p1, mail: MAIL-M2, verdict: phish}
  - {slug: p2, kind: cred-harvest, auth: fail, verdict: phish}
  - {slug: p3, mail: MAIL-LEGIT, verdict: legit}
  - {slug: p4, mail: MAIL-SPAM, verdict: spam}
  - {slug: p5, kind: internal-notice, sender: helpdesk@coppermine.example, auth: pass, verdict: legit}
  - {slug: p6, kind: bec-wire, spoof: cfo-display-name, verdict: phish}
emit: {mail: files/mail/p1..p6.eml, checklist: files/triage-checklist.md, answers_template: files/answers.template.txt}
answer_key: {q1: phish, q2: phish, q3: legit, q4: spam, q5: legit, q6: phish}
verify: [exactly one allowlisted-vendor legit + one internal legit; auth results coherent per mail]
```

---

### L5.6 — Phase gate: full phish investigation — email → indicators → enrichment → verdict → report

| id | title | type | gate | est_minutes |
|---|---|---|---|---|
| L5.6 | Phase gate: full phish investigation — email → indicators → enrichment → verdict → report | REPORT | true | 20 |

Dir `tracks/soc/phases/p5/L5.6-gate-phish-report/`. **Integrative (REPORT):** investigate MAIL-M2 end
to end and write the escalation report — timeline, defanged IOCs, ATT&CK id, verdict, recommendation.

**TEACHING ARTIFACT**
- **Files staged** (`files/`; generated `s5-gate-phish`, RAW): `reported.eml` (MAIL-M2),
  `enrichment/` (VT/pdns/whois for the C2 + hash, reused from Phase 4 mocks), `sandbox-report.md`
  (SBX-M2), `report-template.md` (section skeleton: `## Summary / ## Timeline / ## Indicators (defanged)
  / ## ATT&CK / ## Verdict / ## Recommendation`), and `model-report.md` (shipped, shown on pass).
- **Learner task:** pull indicators from the email, enrich them (mock reports), read the sandbox
  verdict, and write `report.md` — a complete escalation with a timeline, defanged IOCs, at least one
  ATT&CK technique id, a verdict, and a recommendation.
- **Grading** (`check.sh`, **REPORT rubric per §2.3**): required elements (timeline section, ≥1 real
  ATT&CK id e.g. `t1566.001`, a verdict token, a recommendation section, ≥1 defanged IOC) + the
  **defang gate** (`assert_file_not_contains` raw `http://[a-z]`, raw `cdn.stonewick.example`, raw
  `203.0.113.66`, raw `198.51.100.71`); `ck_summary` last; quiz gates 3/3. On pass, lab.md/recap points
  to `model-report.md` for self-comparison.
- **Kit files:**
  - `meta.json`: `{id:"L5.6", type:"REPORT", objective:"Investigate a reported phish end to end and
    write an escalation report with a timeline, defanged IOCs, ATT&CK id, verdict, and recommendation",
    gate:true, est_minutes:20}`
  - `quiz.json` (gates 3/3):
    1. "A phishing escalation report must contain, at minimum:" a) just a verdict b) timeline, defanged
       IOCs, ATT&CK technique, verdict, and recommendation — the elements Tier 2 triages by c) the raw
       email only d) a screenshot → **b**
    2. "Every IOC in the report must be:" a) raw so it's clickable b) defanged (hxxp://, [.]) so no one
       resolves a live-malicious indicator by accident c) hashed d) omitted → **b**
    3. "The report grades on structure and defang, and ships a model report because:" a) the script can
       verify format and safety, but writing quality calibrates against a worked example b) grading is
       impossible c) reports don't matter d) the model is the only answer → **a**
  - `hints.json`: L1 "Work the pipeline: pull IOCs from reported.eml (sender IP, from-domain, URLs,
    attachment hash), enrich them, read the sandbox verdict, then fill every section of
    report-template.md." L2 "Your report needs a Timeline, an Indicators section with EVERY IOC
    defanged, at least one ATT&CK id (T1566.001 for the attachment), a Verdict (malicious/phish), and a
    Recommendation (block sender/domain, reset m.reyes, hunt the beacon)." L3 "The check requires each
    section and rejects any raw IOC — if it fails, search your report for http:// or an unbracketed
    domain/IP and defang it. Compare to model-report.md after you pass."
  - `recap.md` (3 lines): `A phish investigation runs a pipeline: email → indicators → enrichment →
    sandbox verdict → a written escalation.` / `The report is the deliverable Tier 2 acts on — timeline,
    defanged IOCs, ATT&CK, verdict, recommendation — and every IOC is defanged, always.` / `Phase 5
    complete: you read headers, URLs, attachments, and sandbox reports, worked a mixed phish queue, and
    wrote the escalation — Phase 6 is investigation and the ticket Tier 2 respects.`
  - **`recall.json`: none** (not opener). **Parked draft for L6.1** (drafted now; **[VERIFY-AT-BUILD]**):
    1. (choice) "The Received chain reads which way to find the origin?" a) bottom-up b) top-down c)
       by date → **key a** — source **L5.1**.
    2. (text) "`xn--…` domains are encoded in ___ (one word)." → **key `punycode`** — source **L5.2**.
    3. (text) "Extensions lie; what gives an attachment's true type? (two words)" → **key `magic bytes`**
       (accept `file`, `magic`) — source **L5.3**.
    4. (text) "You verdict a sample from a sandbox report without ___ it (one word)." → **key `running`**
       (accept `executing`, `touching`, `opening`) — source **L5.4**.
    5. (choice) "A reported email that passes auth from an allowlisted vendor is ___." a) legit b) phish
       c) spam → **key a** — source **L5.5**.
  - **`## SECURITY ONION (OPTIONAL)`**: investigate the phish in the `cardinal-so` case/email view;
    flat-file report is the graded gate.
  - `model-report.md` — shipped worked example (defanged throughout) for post-pass self-comparison.

**EVIDENCE SPEC**
```yaml
scenario: s5-gate-phish
lab: L5.6
mail: MAIL-M2
enrichment: [vt C2 ip/hash, pdns C2 ip, whois stonewick]   # reused Phase 4 mocks
sandbox: SBX-M2
required_report_elements: [timeline, indicators(defanged), attack_id(>=1 real), verdict, recommendation]
defang_gate: [no raw http://, no raw cdn.stonewick.example, no raw 203.0.113.66, no raw 198.51.100.71]
emit: {eml: files/reported.eml, enrichment: files/enrichment/, sandbox: files/sandbox-report.md,
       template: files/report-template.md, model: files/model-report.md, key_block: check.sh}
answer_key:   # rubric keys, not exact prose
  required_sections: [timeline, attack_id: t1566.001, verdict_token, recommendation, defanged_ioc]
  reject_raw: [http://, cdn.stonewick.example, 203.0.113.66, 198.51.100.71]
verify: [model-report.md passes its own rubric + defang gate; all IOCs in template resolvable to M2 canon]
```

---

## 5. Build order (one session, Phase Builder protocol)

Prerequisite: `soc-p0…p4` tagged.

1. **Generator extensions** — `eml_mock`, `sandbox_mock`, `attachment_fixture` emitters + the auth-
   coherence / sandbox-IOC / hash-consistency `verify.py` invariants; append MAIL-*/SBX-M2 + lookalike
   anchors to `universe.yaml`; self-test on a throwaway scenario. **Build the REPORT rubric helper
   pattern (§2.3) and self-test `model-report.md` against it first** (the model must pass its own gate).
2. **p5 scenarios** in map order — `s5-headers`, `s5-urls`, `s5-attachments`, `s5-sandbox`,
   `s5-phish-queue`, `s5-gate-phish` → L5.1…L5.6. Build lab by lab with §2.1 (and §2.3 for L5.6);
   self-test each (fail + pass, real outputs pasted); commit per lab (`soc L5.x: <title>`), one
   branch+PR+merge each via an isolated worktree.
3. **Gate (L5.6)** integrates + drafts L6.1 recall (parked above); confirm the defang gate actually
   fails a report containing a raw IOC (negative self-test) and passes the model.
4. **Close-out:** `verify.py` green across `s5-*`; lint/shellcheck/acceptance green (extend
   `acceptance.sh` with a P5 section — 6 labs, pass + negative each; the L5.6 negative case is a report
   with a raw IOC that must FAIL); `lab status`/`resume` render p5; update `planned_execution.md`; tag
   `soc-p5`. Gate per lab.

## 6. Acceptance checklist mapping (PROMPTS.md §174–181)

- **Lab count/titles/types match the map** — §4 is map-exact (6 labs, L5.6 REPORT gate).
- **Every lab self-tested, real outputs pasted** — build-order step 2; L5.6 includes a raw-IOC negative.
- **shellcheck clean** — §2.1/§2.3 patterns; no `disable=`.
- **Gate integrative + next-opener recall drafted** — L5.6 (+ parked L6.1, [VERIFY-AT-BUILD]).
- **Evidence generated + consistency-verified** — §2 emitters + `verify.py` (auth coherence, sandbox
  IOC ⊆ universe, hash == seeded, no-defang-in-raw, no-fang-in-prose/report).
- **`.eml` full headers; nothing live-hostile** — inert fixtures, mocked sandbox, no execution/fetch.
- **REPORT enforces defanging in submission** — §2.3 defang gate is the graded teeth of L5.6.
- **Flat-file first / SO overlay** — all 6 grade on `files/`; SO ungraded on L5.6 only.

---

## Session control (PLAN-AHEAD, all remaining soc phases)

Phase 5 of a plan-ahead pass (2→3→4→5→6→7), one at a time, **commit-and-continue** (no per-phase stop —
memory `feedback_plan_ahead_commit_and_continue`). **Phases 2–4 planned and merged** (`soc-p2` PR #254,
`soc-p3` PR #260, `soc-p4` PR #261). Nothing built. Commits go through an **isolated git worktree**
(shared working tree has concurrent writers). After Phase 5 merges, continue to Phase 6 (Investigation &
Escalation). Plans only; no building, no tags, no `planned_execution.md` edits.
