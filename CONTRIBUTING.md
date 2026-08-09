# Contributing & Quality Framework

Thank you for contributing to **LAB-KIT**! This document explains our CI lint gates, curriculum design standards, MITRE ATT&CK® mapping, and content-review guardrails.

---

## 1. Automated CI Lint Gates

All pull requests and commits to `main` must pass automated CI checks configured in `.github/workflows/ci.yml`:

- **ShellCheck & Lab Structural Lint**:
  - All shell scripts, CLI helpers, and `check.sh` files must pass `./tools/shellcheck-all.sh`.
  - All lab directories must adhere to structural requirements checked by `./tools/lint-labs.sh` (valid `meta.json`, `lab.md`, `check.sh`, `quiz.json`, `hints.json`, and `recap.md`).
  - Full acceptance test suite (`tests/acceptance.sh`) must pass 100%.
- **PSScriptAnalyzer (PowerShell)**:
  - PowerShell scripts and samples under `tracks/ps` are analyzed with `PSScriptAnalyzer` at Error and Warning severity thresholds.
- **Clippy & Cargo Check (Rust)**:
  - Rust projects under `tracks/rust` are checked with `cargo check` and `cargo clippy -- -D warnings`.

Before submitting a pull request, run locally:
```bash
./tools/shellcheck-all.sh
./tools/lint-labs.sh
bash tests/acceptance.sh
```

---

## 2. MITRE ATT&CK® Mapping

Security-relevant lessons in the **PowerShell (`ps`)** and **SOC Analyst (`soc`)** tracks are tagged with technique IDs from the **MITRE ATT&CK Framework**.

Refer to [`docs/ATTACK_MAPPING.md`](docs/ATTACK_MAPPING.md) for the full mapping matrix. When adding or modifying security-focused lessons:
- Identify implicit or explicit ATT&CK technique IDs (`T1059.001`, `T1027`, `T1547.001`, `T1218`, `T1071`, etc.).
- Update `docs/ATTACK_MAPPING.md` to keep the curriculum reference up to date.

---

## 3. Offense-Adjacent Content Review Framework

All offense-adjacent lessons (such as obfuscation, download cradles, C2 beacon patterns, LOLBins, and encoded commands) MUST adhere to the **Content Review Checklist** documented in [`docs/CONTENT_REVIEW_CHECKLIST.md`](docs/CONTENT_REVIEW_CHECKLIST.md):

1. **Defensive Framing**: Content must teach students to read, analyze, audit, or detect techniques — never to weaponize them.
2. **Payload Sanitization**: All network destinations must use RFC 2606/6761 reserved domains (`.example`) or RFC 5737 reserved IP ranges (`198.51.100.0/24`, `203.0.113.0/24`). All URIs in prose/report templates must be defanged (`hxxp://`, `[.]`).
3. **Safe Command Primitives**: Script samples must use inert inspection commands (`whoami /all`, `Get-Process`, `hostname`) rather than destructive payloads.
4. **Static Evaluation**: Graders check file properties or static strings without executing untrusted learner code.
