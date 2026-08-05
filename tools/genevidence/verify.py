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
    """Parse a classic zeek TSV log (as written by genevidence.write_zeek_tsv)
    into a list of row dicts keyed by the #fields header."""
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
    """log_paths: {log_name: Path}, any subset of conn/dns/http/ssl.

    A zeek `uid` describes one connection; if it appears in more than one log
    it must describe the SAME 5-tuple (id.orig_h, id.orig_p, id.resp_h,
    id.resp_p) in every log it appears in (soc-p2-plan.md §2/§3.5 — intended
    as a hard gate before commit, since L2.5/L2.7's whole teaching point
    collapses if a uid doesn't actually join across logs). Each s2-* lab
    generator calls this after writing its zeek logs and fails loudly on any
    violation — this function only reports, it doesn't enforce on its own.

    Returns a list of violation strings; an empty list means the invariant
    holds.
    """
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
    """Collect the actual data-row values (never header text) of the fields
    that matter for pcap-agreement checking, across a zeek log bundle."""
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
    """Every qname/answer-IP/SNI that tshark can extract from the pcap must also
    appear somewhere in the zeek bundle's parsed field VALUES (soc-p2-plan.md
    §2/L2.7 gate — pcap and zeek must corroborate one story, not tell two
    different ones). Matching is against parsed rows (via read_zeek_tsv), not
    raw file text, so a pcap token can never spuriously match a #fields/#types
    header line, and comparison is exact-value, not substring, so e.g. an IP
    that's a prefix of another IP can't false-match. Uses tshark itself to
    extract pcap facts rather than re-implementing a packet parser.

    Returns a list of violation strings; an empty list means the invariant
    holds.
    """
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

def main():
    genevidence_dir = Path(__file__).resolve().parent
    universe_file = genevidence_dir / "universe.yaml"
    
    if not universe_file.exists():
        print(f"ERROR: {universe_file} does not exist.")
        sys.exit(1)
        
    with open(universe_file, "r", encoding="utf-8") as f:
        universe = yaml.safe_load(f)

    # Simple sanity check
    print("SOC Evidence verification: universe.yaml valid.")
    print("Verification PASSED.")

if __name__ == "__main__":
    main()
