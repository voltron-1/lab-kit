# tools/genevidence/ — End-to-End Validation Report

Date: 2026-09-11
Scope: `tools/genevidence/` only (genevidence.py, verify.py, universe.yaml,
universe-events.yaml, scenarios/*.yaml). Repo left read-only; all corruption
testing done on copies under `/tmp/genevidence-test/`.

## 1. Inventory

| File | Purpose |
|---|---|
| `tools/genevidence/genevidence.py` | The generator. Reads every `scenarios/*.yaml`, dispatches by `scenario:` id to one `generate_s*_*()` function per lab, writes evidence files (zeek TSV logs, hand-rolled pcaps via `struct` — no scapy despite `docs/plans/soc-p01-plan.md:67` claiming "scapy only for the one pcap fixture"), JSON alert/log artifacts, and syncs a base64 "GENERATED KEY" block into each lab's `check.sh`. Imports `verify` as a sibling module and calls `verify.check_uid_consistency` / `verify.check_pcap_zeek_agreement` internally as self-tests during generation (lines 937, 1118, 1121). No CLI args — `main()` runs unconditionally over all scenario files. |
| `tools/genevidence/verify.py` | Standalone "CI-style" checker. Defines four checks: `check_uid_consistency`, `check_pcap_zeek_agreement`, `check_universe_entities`, `check_event_id_format`. `main()` hardcodes its own scope: loads `tools/genevidence/universe.yaml` and globs `tracks/soc/phases/p*/*` off `REPO_ROOT` — **it takes no path/target argument**, so it can only ever check the live repo tree it ships in, never an arbitrary bundle. |
| `tools/genevidence/universe.yaml` | Static fixture: org, subnets, `servers:`/`workstations:` (host inventory), `people:`, `externals:` (C2/phish infra) for the "Coppermine Logistics" universe. Top-level keys: `org, subnets, servers, workstations, people, externals` — **no `hosts:` key**. |
| `tools/genevidence/universe-events.yaml` | Canonical cross-lab event/rule ID registry (`CM-<MMDD>-<seq>`, `CM-R-<nnnn>`) plus `id_bands` per phase, to prevent ID collisions across scenario files. Reference data only, not executed. |
| `tools/genevidence/scenarios/*.yaml` (17 files) | One YAML per lab (s0-fixtures … s2-gate-session), each with the raw evidence rows (conn/dns/http/ssl rows, answer keys, etc.) that `genevidence.py` turns into files. Not independently runnable — consumed only by `genevidence.py`'s dispatch table. |
| `tools/genevidence/__pycache__/verify.cpython-312.pyc` | Stale bytecode cache, not source. |

No `gen_*.py` scripts exist — `genevidence.py` is the single generator entrypoint (one file, scenario-dispatch pattern, not one script per lab).

## 2. Entrypoints run

All commands run from repo root (`/home/tjlam/projects/lab-kit`), exactly as a user/build-author would invoke them.

| Command | Exit | Result |
|---|---|---|
| `python3 tools/genevidence/verify.py --help` | 0 | Ran fine — but **`--help` is not implemented**. Neither script uses `argparse`/`sys.argv` at all, so any arguments (including `--help`) are silently ignored and `main()` runs for real regardless. |
| `python3 tools/genevidence/verify.py` | 0 | `SOC Evidence verification: universe entities & event IDs valid. / Verification PASSED.` |
| `python3 tools/genevidence/genevidence.py --help` | 0 | **Ran full generation** (17 scenarios processed, "Synced key block in ..." for every lab's `check.sh` under `tracks/soc/phases/`), not help text. This writes into the live repo tree by design. Verified via `git status --short` / `git diff --stat` immediately after that this run was **idempotent** — it reproduced byte-identical output to what's already committed, so no unintended repo mutation occurred (confirmed no new diff beyond the pre-existing `verify.py`/`tests/acceptance.sh` changes noted in the session's git status). This is still a design risk worth flagging: a user who runs `--help` expecting usage text instead gets a full, silent write pass over the repo tree with no dry-run flag.

Both scripts ran clean (exit 0, no traceback) in every invocation. **0 of 2 entrypoints failed to run**; the finding is about what they silently do/don't check, not crashes.

## 3. Import-time health

```
python3 -c "import sys; sys.path.insert(0,'tools/genevidence'); import genevidence; print('OK')"  → OK
python3 -c "import sys; sys.path.insert(0,'tools/genevidence'); import verify; print('OK')"        → OK
```

Third-party deps actually used: **PyYAML** (`import yaml`, both files) and, at runtime only inside `check_pcap_zeek_agreement`, an external **`tshark`** binary via `shutil.which("tshark")`/`subprocess`. No `scapy` import anywhere in the code (contradicts `docs/plans/soc-p01-plan.md:67`).

Both were present on this machine (PyYAML 6.0.2 via `pip show pyyaml`; `tshark` 4.2.2 at `/usr/bin/tshark`), so nothing failed here — but:

- **`README.md`**: zero mentions of `genevidence`, PyYAML, tshark, or `pip install` for this tooling.
- **`CONTRIBUTING.md`**: zero mentions of `genevidence`, PyYAML, scapy, or `pip install`.
- No `requirements.txt`/`pyproject.toml`/`Pipfile` anywhere in the repo.
- Only place a dependency is documented at all is a planning note, `docs/plans/soc-p01-plan.md:67`: "Python 3 + PyYAML; scapy only for the one pcap fixture (L0.1)" — and that note is itself stale (no scapy in the code) and is a design doc, not user/contributor-facing setup instructions.

**Finding: PyYAML and tshark are undocumented hard dependencies of `tools/genevidence/`. A fresh machine without them would fail at `import yaml` (genevidence.py/verify.py both die immediately) or silently degrade (pcap↔zeek agreement check reports `"tshark not found on PATH"` as a violation string rather than erroring) with no README/CONTRIBUTING guidance on how to install either.**

## 4. verify.py working-tree diff — behavior changed: **YES**

`git diff tools/genevidence/verify.py` / `diff HEAD:tools/genevidence/verify.py` vs working tree shows two categories of change:

**Docstring/comment-only (no behavior change):** trimmed long docstrings on `read_zeek_tsv`, `check_uid_consistency`, `check_pcap_zeek_agreement` down to one-liners. Pure documentation loss, no logic touched in these three functions — confirmed by re-running `check_uid_consistency` directly against both the corrupted and clean bundle in section 5, which behaves identically to its documented contract.

**Behavior-changed (real logic, not comments):**

1. **Two brand-new functions added**, not present in `HEAD:tools/genevidence/verify.py` at all:
   - `check_universe_entities(universe: dict) -> list` — iterates `universe["hosts"]` for missing `name`/`ip`.
   - `check_event_id_format(lab_dir: Path) -> list` — regex-validates every `cm-...` token found in any `**/*.json` under a lab directory against `^cm-(a-\d+|r-\d+|\d{4}-\d{4}|9999-\d{4})$`.

2. **`main()` rewritten from a no-op pass into a real gate.** HEAD's `main()` was:
   ```python
   # Simple sanity check
   print("SOC Evidence verification: universe.yaml valid.")
   print("Verification PASSED.")
   ```
   i.e. it printed PASSED unconditionally after just parsing the YAML — no assertions, could never fail (short of a YAML parse error / `sys.exit(1)` on missing file). The working tree's `main()` now actually calls `check_universe_entities(universe)` and, for every `lab_dir` under `tracks/soc/phases/p*/*`, `check_event_id_format(lab_dir)`, accumulates violations, and `sys.exit(1)` with an itemized list if any are found. **This is a genuine behavior change**: before, `verify.py` could never fail on content; now it can (in principle) fail a build on a bad event-ID format anywhere in `tracks/soc/phases/`.

**Verdict: behavior-changed YES**, specifically in `main()` (no-op → enforcing gate with two new checks) plus the two new check functions themselves. This is not just comment/docstring cleanup, and framing it as a "docs tidy-up" commit would be misleading.

## 5. Invariant-enforcement test — corrupted a copy, re-ran verify.py

**Setup (repo untouched — copy to `/tmp` only):**
```
mkdir -p /tmp/genevidence-test/L2.5-zeek-verdict
cp -r tracks/soc/phases/p2/L2.5-zeek-verdict/files /tmp/genevidence-test/L2.5-zeek-verdict/
```

**Corruption:** in the copy's `http.log`, changed `uid CXush1`'s `id.resp_h` from `198.51.100.23` to `198.51.100.99`, while `conn.log`'s `CXush1` row still says `198.51.100.23` — the exact "same uid, different 5-tuple across logs" scenario `check_uid_consistency`'s docstring says is a hard gate (`soc-p2-plan.md §2/§3.5`):

```
conn.log: 2026-03-12T20:16:00Z  CXush1  10.20.10.20  44601  198.51.100.23  80  ...
http.log: 2026-03-12T20:16:00Z  CXush1  10.20.10.20  44601  198.51.100.99  80  GET ...
```

**Test A — call the check function directly against the corrupted copy:**
```python
import verify
logs = {n: Path('/tmp/genevidence-test/L2.5-zeek-verdict/files')/f'{n}.log' for n in ['conn','dns','http','ssl']}
verify.check_uid_consistency(logs)
```
Result:
```
["uid CXush1 describes ('10.20.10.20', '44601', '198.51.100.23', '80') in conn but ('10.20.10.20', '44601', '198.51.100.99', '80') in http"]
```
→ **The function itself works.** It catches the corruption when called directly, exactly as documented.

**Test B — run the real, unmodified entrypoint (`python3 tools/genevidence/verify.py`) exactly as a user/CI would, from repo root, immediately after Test A:**
```
$ python3 tools/genevidence/verify.py
SOC Evidence verification: universe entities & event IDs valid.
Verification PASSED.
$ echo $?
0
```
→ **verify.py's actual CLI entrypoint does NOT catch it. Exit 0, "PASSED."**

**Root cause:** `verify.py`'s `main()` (both in HEAD and in the working-tree diff — this is not something the uncommitted diff broke, it was never wired up) never calls `check_uid_consistency` or `check_pcap_zeek_agreement` at all. Those two functions are only ever invoked from inside `genevidence.py`'s `generate_s2_zeek_verdict`/`generate_s2_gate_session` functions (lines 937, 1118, 1121) as a self-check at *generation* time, on evidence the generator just wrote in-memory-adjacent paths. `verify.py` run standalone against the committed repo tree only performs `check_universe_entities` + `check_event_id_format` — neither of which touches zeek logs at all. There is also no `--path`/positional-argument support on `verify.py`, so even if the uid check were wired into `main()`, there would be no way to point the standalone verifier at an arbitrary bundle (e.g. this `/tmp` copy, or a PR's changed files) — it can only ever re-check the same repo paths it's shipped inside of.

**Bonus finding — `check_universe_entities` is dead code against the real schema.** `universe.yaml`'s top-level keys are `org, subnets, servers, workstations, people, externals` — there is no `hosts:` key. `check_universe_entities` only inspects `universe["hosts"]`. Verified directly:
```python
universe['servers']['DC01']['ip'] = None   # corrupt a real server's IP
verify.check_universe_entities(universe)   # -> []  (no violations reported)
```
Even with a null IP injected into an actual server record, the check reports zero violations, because it's keyed on a field name (`hosts`) that doesn't exist anywhere in the real universe schema. This is one of the two *new* functions added in the uncommitted `verify.py` diff (section 4) — it was written against a schema (`hosts: [{name, ip}, ...]`) that doesn't match `universe.yaml`'s actual shape (`servers:`/`workstations:` dicts keyed by hostname), so it can never fire.

## Summary of findings (severity-ordered)

1. **HIGH** — `verify.py`'s CLI entrypoint never runs `check_uid_consistency` or `check_pcap_zeek_agreement`. The cross-log 5-tuple and pcap↔zeek agreement invariants that `docs/plans/soc-p01-plan.md` / `soc-p2-plan.md` describe as "hard gates before commit" are **not enforced by any standalone/CI-style check** — only as an in-process self-test the generator runs on its own fresh output. A corrupted/hand-edited evidence file already sitting in `tracks/` would pass `verify.py` silently. Demonstrated empirically in section 5, Test B.
2. **HIGH** — `verify.py` has no way to target an arbitrary path; it hardcodes `REPO_ROOT`-relative globs. It cannot be used as a general-purpose evidence-bundle verifier (e.g., in a PR check against only changed files, or against a `/tmp` reproduction) — only as a fixed self-check of the exact repo it ships in.
3. **MEDIUM** — `check_universe_entities` (new in the uncommitted diff) is dead code: it checks `universe["hosts"]`, a key that does not exist in `universe.yaml`'s actual schema (`servers`/`workstations`). It can never report a violation no matter how broken the universe file is. Demonstrated empirically in section 5.
4. **MEDIUM** — Working-tree `verify.py` diff is a real behavior change, not a docstring tidy-up: `main()` went from an unconditional pass to an enforcing gate with `sys.exit(1)`, plus two new (one broken, one working) check functions. Anyone reviewing this as "just comments" would miss that it's now a functioning (partial) gate.
5. **LOW** — Neither `genevidence.py` nor `verify.py` implements argument parsing; `--help` silently does nothing and instead runs the full script for real. For `genevidence.py` specifically, that means a `--help` typo triggers a full write-pass over `tracks/soc/phases/`'s `check.sh` files (confirmed idempotent this run via `git status`/`git diff --stat`, but there's no dry-run flag and no warning).
6. **LOW** — PyYAML and tshark are undocumented dependencies (no README/CONTRIBUTING mention, no requirements file); the one design doc that mentions a dependency (`docs/plans/soc-p01-plan.md:67`) is stale, claiming scapy usage that doesn't exist in the code.

## Evidence artifacts
- Corrupted test bundle: `/tmp/genevidence-test/L2.5-zeek-verdict/files/` (not in the repo; safe to delete)
- Repo confirmed unmodified beyond the pre-existing session-start diff (`git status --short` / `git diff --stat` re-checked after the `genevidence.py --help` run — no new changes)
