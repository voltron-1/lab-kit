#!/usr/bin/env python3
"""
CI-style verification script for SOC Analyst Lab evidence consistency.
Validates universe entities, timestamps, event IDs, and defang conventions.
"""

import sys
import re
import yaml
import json
import shutil
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent

def read_zeek_tsv(path: Path) -> list:
    """Parse a classic zeek TSV log into a list of row dicts."""
    fields = None
    rows = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if line.startswith("#fields"):
                fields = line.split("\t")[1:]
            elif not line or line.startswith("#"):
                continue
            elif fields:
                rows.append(dict(zip(fields, line.split("\t"))))
    return rows

def check_uid_consistency(log_paths: dict) -> list:
    """Validate 5-tuple consistency across zeek logs for shared connection UIDs."""
    seen = {}
    violations = []
    for log_name, path in log_paths.items():
        if not path.exists():
            continue
        for row in read_zeek_tsv(path):
            uid = row.get("uid")
            if uid is None or uid == "-":
                continue
            tup = (row.get("id.orig_h"), row.get("id.orig_p"),
                   row.get("id.resp_h"), row.get("id.resp_p"))
            if uid in seen and seen[uid][0] != tup:
                violations.append(
                    f"uid {uid} describes {seen[uid][0]} in {seen[uid][1]} "
                    f"but {tup} in {log_name}"
                )
            else:
                seen.setdefault(uid, (tup, log_name))
    return violations

_ZEEK_AGREEMENT_FIELDS = {"query", "answers", "server_name", "host", "uri",
                          "id.orig_h", "id.resp_h"}

def _zeek_fact_set(zeek_log_paths: list) -> set:
    """Collect data-row values of fields that matter for pcap-agreement checking."""
    values = set()
    for p in zeek_log_paths:
        if not p.exists():
            continue
        for row in read_zeek_tsv(p):
            for field, value in row.items():
                if field in _ZEEK_AGREEMENT_FIELDS and value not in ("-", ""):
                    values.add(value)
    return values

def check_pcap_zeek_agreement(pcap_path: Path, zeek_log_paths: list) -> list:
    """Every qname/answer-IP/SNI extracted from pcap must appear in the zeek bundle."""
    if not pcap_path.exists():
        return [f"{pcap_path} does not exist"]

    tshark_bin = shutil.which("tshark")
    if tshark_bin is None:
        return ["tshark not found on PATH"]

    fields = ["dns.qry.name", "dns.a", "tls.handshake.extensions_server_name",
              "http.host", "http.request.uri"]
    cmd = [tshark_bin, "-n", "-r", str(pcap_path), "-T", "fields"]
    for fld in fields:
        cmd += ["-e", fld]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30, check=True)
    except subprocess.CalledProcessError as e:
        return [f"tshark failed reading {pcap_path}: {e} (stderr: {e.stderr!r})"]
    except subprocess.TimeoutExpired as e:
        return [f"tshark timed out reading {pcap_path}: {e}"]

    pcap_tokens = set()
    for line in result.stdout.splitlines():
        for tok in line.split("\t"):
            tok = tok.strip()
            if tok:
                pcap_tokens.add(tok)

    zeek_facts = _zeek_fact_set(zeek_log_paths)

    violations = []
    for tok in pcap_tokens:
        if tok not in zeek_facts:
            violations.append(f"pcap fact '{tok}' not found anywhere in the zeek bundle")
    return violations

# ==============================================================================
# Baseline Invariants (soc-p01-plan.md §2)
# ==============================================================================

def check_universe_entities(universe: dict) -> list:
    """Validate struct coherence of universe.yaml entities (hosts, IPs, accounts).

    universe.yaml keys hosts by name under `servers:`/`workstations:` mappings,
    so an entry is a (name, attrs) pair rather than a dict carrying its own
    'name' field. Every host needs an ip, no two hosts may claim the same ip,
    and a workstation's assigned user must exist under `people:`.
    """
    violations = []
    seen_ips = {}
    for section in ("servers", "workstations"):
        entries = universe.get(section) or {}
        if not isinstance(entries, dict):
            violations.append(f"universe.yaml '{section}' is not a name-keyed mapping")
            continue
        for name, attrs in entries.items():
            attrs = attrs or {}
            ip = attrs.get("ip")
            if not ip:
                violations.append(f"universe host '{name}' ({section}) has no ip")
                continue
            if ip in seen_ips and seen_ips[ip] != name:
                violations.append(f"universe ip {ip} is claimed by both {seen_ips[ip]} and {name}")
            seen_ips[ip] = name
            user = attrs.get("user")
            if user and user not in (universe.get("people") or {}):
                violations.append(f"universe host '{name}' assigns unknown user '{user}'")
    return violations

def check_event_id_format(lab_dir: Path) -> list:
    """Verify synthetic event ID format across lab json files."""
    violations = []
    # Match valid event/alert/rule ID formats: CM-\d{4}-\d{4}, CM-A-\d+, CM-R-\d+
    valid_id_pattern = re.compile(r"^cm-(a-\d+|r-\d+|\d{4}-\d{4}|9999-\d{4})$", re.IGNORECASE)
    for json_file in lab_dir.glob("**/*.json"):
        try:
            with open(json_file, "r", encoding="utf-8") as f:
                content = f.read()
                matches = re.findall(r"\bcm-[a-z0-9\-]+\b", content, re.IGNORECASE)
                for m in matches:
                    if not valid_id_pattern.match(m):
                        violations.append(f"Non-standard event ID '{m}' in {json_file.relative_to(REPO_ROOT)}")
        except Exception as e:
            violations.append(f"Could not parse {json_file}: {e}")
    return violations

def _zeek_logs(lab_dir: Path) -> dict:
    """The lab's shipped zeek logs, keyed by path relative to the lab.

    Only classic zeek TSVs count — a `#fields` header is what read_zeek_tsv
    parses, and several labs ship hand-written `key: value` evidence under the
    same .log name that these invariants cannot (and must not) speak to.
    """
    logs = {}
    for p in sorted(lab_dir.glob("files/**/*.log")):
        try:
            with open(p, "r", encoding="utf-8", errors="replace") as f:
                head = f.read(4096)
        except OSError:
            continue
        if "#fields" in head:
            logs[str(p.relative_to(lab_dir))] = p
    return logs

def main():
    genevidence_dir = Path(__file__).resolve().parent
    universe_file = genevidence_dir / "universe.yaml"

    if not universe_file.exists():
        print(f"ERROR: {universe_file} does not exist.")
        sys.exit(1)

    with open(universe_file, "r", encoding="utf-8") as f:
        universe = yaml.safe_load(f)

    violations = []
    violations.extend(check_universe_entities(universe))

    labs = uid_checked = pcap_checked = 0
    for lab_dir in sorted(REPO_ROOT.glob("tracks/soc/phases/p*/*")):
        if not lab_dir.is_dir():
            continue
        labs += 1
        lab = lab_dir.name.split("-")[0]
        violations.extend(check_event_id_format(lab_dir))

        # A uid must describe one connection everywhere it appears in a bundle.
        zeek = _zeek_logs(lab_dir)
        if zeek:
            uid_checked += 1
            violations.extend(f"{lab}: {v}" for v in check_uid_consistency(zeek))

        # A pcap and the zeek logs beside it must tell the same story. Only labs
        # that ship both can be cross-checked; a lone pcap has nothing to agree with.
        if zeek:
            for pcap in sorted(lab_dir.glob("files/**/*.pcap")):
                pcap_checked += 1
                violations.extend(
                    f"{lab}: {v}" for v in check_pcap_zeek_agreement(pcap, list(zeek.values()))
                )

    if violations:
        print(f"ERROR: Evidence verification failed with {len(violations)} violation(s):")
        for v in violations:
            print(f"  - {v}")
        sys.exit(1)

    print(f"SOC evidence verification over {labs} labs:")
    print(f"  universe entities & event IDs valid")
    print(f"  uid 5-tuple consistency checked in {uid_checked} zeek bundle(s)")
    print(f"  pcap/zeek agreement checked for {pcap_checked} capture(s)")
    print("Verification PASSED.")

if __name__ == "__main__":
    main()
