#!/usr/bin/env python3
"""
CI-style verification script for SOC Analyst Lab evidence consistency.
Validates universe entities, timestamps, event IDs, and defang conventions.
"""

import sys
import re
import yaml
import json
import base64
import shutil
import subprocess
from pathlib import Path
from datetime import datetime, timezone

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
GENEVIDENCE_DIR = Path(__file__).resolve().parent
SOC_PHASES_DIR = REPO_ROOT / "tracks" / "soc" / "phases"

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

# --- Baseline p0/p1 invariants (docs/plans/soc-p01-plan.md §2) ---
#
# These four functions, plus check_uid_consistency/check_pcap_zeek_agreement
# above, are the CI-style consistency checks soc-p01-plan.md §2 originally
# committed this file to. Unlike the p2 pair (called from genevidence.py at
# generation time, on one scenario's fresh output), these run POST HOC against
# whatever is already committed on disk — every soc lab's emitted evidence,
# every genevidence-linked check.sh's answer key, every lab.md/recap.md the
# curriculum shipped — since the whole point of a baseline gate is to catch
# drift between scenario yaml and emitted files that generation-time checks
# (scoped to one scenario's own fresh run) can never see.

_EVENT_ID_RE = re.compile(r'^[A-Za-z]{1,8}-\d{4}-\d{4}$')
_IPV4_RE = re.compile(r'^(?:\d{1,3}\.){3}\d{1,3}$')
_IPV4_FINDALL_RE = re.compile(r'\b(?:\d{1,3}\.){3}\d{1,3}\b')
_ISO_TS_RE = re.compile(r'\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z\b')
_ZEEK_EPOCH_TS_RE = re.compile(r'(?:^|\t)(\d{9,11}\.\d+)(?=\t)', re.MULTILINE)
_DEFANG_RE = re.compile(r'\[\.\]|\[dot\]|hxxps?://|hxxp\b', re.IGNORECASE)
_GENEVIDENCE_TAG_RE = re.compile(r'genevidence:\s*([a-z0-9-]+)\s*\)')

def _parse_iso_ts(s: str):
    """Parse an explicit-UTC ISO8601 timestamp (must end in 'Z') to an aware
    UTC datetime. Never called on a naive/local string (e.g. a syslog_line's
    'Mar 10 08:59:57') - those don't match _ISO_TS_RE in the first place."""
    return datetime.fromisoformat(s[:-1]).replace(tzinfo=timezone.utc)

def load_universe(universe_path: Path = None) -> dict:
    universe_path = universe_path or (GENEVIDENCE_DIR / "universe.yaml")
    with open(universe_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)

def _find_lab_dirs() -> list:
    """Every soc lab directory (tracks/soc/phases/p*/L*), sorted."""
    if not SOC_PHASES_DIR.exists():
        return []
    return sorted(p for p in SOC_PHASES_DIR.glob("p*/L*") if p.is_dir())

def _scenario_id_for_lab(check_sh_path: Path) -> str:
    """The scenario id a check.sh's GENERATED KEY block was synced from, or
    None if this check.sh has no such block (p3-p7 labs are hand-authored,
    not genevidence-generated, and carry no marker at all)."""
    if not check_sh_path.exists():
        return None
    text = check_sh_path.read_text(encoding="utf-8")
    m = _GENEVIDENCE_TAG_RE.search(text)
    return m.group(1) if m else None


# --- Invariant 1: every timestamp in a scenario's emitted evidence falls
# inside that scenario's declared window (its own `window:`, falling back to
# universe.yaml's global org.scenario_window when a scenario has none).

def _extract_pcap_timestamps(pcap_path: Path) -> list:
    tshark_bin = shutil.which("tshark")
    if tshark_bin is None:
        return []
    cmd = [tshark_bin, "-n", "-r", str(pcap_path), "-T", "fields", "-e", "frame.time_epoch"]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30, check=True)
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return []
    stamps = []
    for line in result.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            stamps.append((datetime.fromtimestamp(float(line), tz=timezone.utc), line))
        except ValueError:
            pass
    return stamps

def _extract_timestamps(path: Path) -> list:
    """Best-effort (dt, raw_text) pairs found in one evidence file: explicit-UTC
    ISO8601 stamps anywhere in the text (covers JSON/JSONL/CSV/zeek-ISO/syslog),
    PLUS zeek classic epoch-float 'ts' columns (covers the raw literal zeek text
    some s0/s1 scenarios embed verbatim), PLUS pcap frame times via tshark."""
    if path.suffix == ".pcap":
        return _extract_pcap_timestamps(path)
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return []
    stamps = []
    for m in _ISO_TS_RE.finditer(text):
        try:
            stamps.append((_parse_iso_ts(m.group(0)), m.group(0)))
        except ValueError:
            pass
    for m in _ZEEK_EPOCH_TS_RE.finditer(text):
        try:
            stamps.append((datetime.fromtimestamp(float(m.group(1)), tz=timezone.utc), m.group(1)))
        except (ValueError, OSError, OverflowError):
            pass
    return stamps

def check_timestamps_in_window(window: dict, evidence_dir: Path) -> list:
    """Every timestamp found anywhere under evidence_dir (recursively) must fall
    inside [window['start'], window['end']] (inclusive), both explicit-UTC
    ISO8601 strings. Returns a list of violation strings; empty = invariant holds.

    whois-*.txt is skipped on purpose: a WHOIS record's Creation/Updated Date
    describes when the DOMAIN was registered, not when an incident-timeline
    event happened - L0.1's "newly registered lookalike domain" teaching point
    depends on that date being BEFORE the scenario window, not inside it.
    """
    if not evidence_dir.exists():
        return []
    start = _parse_iso_ts(window["start"])
    end = _parse_iso_ts(window["end"])
    violations = []
    for path in sorted(evidence_dir.rglob("*")):
        if not path.is_file() or path.name.startswith("whois-"):
            continue
        for dt, raw in _extract_timestamps(path):
            if dt < start or dt > end:
                violations.append(
                    f"{path.relative_to(REPO_ROOT)}: timestamp {raw} ({dt.isoformat()}) "
                    f"outside scenario window [{start.isoformat()}, {end.isoformat()}]"
                )
    return violations


# --- Invariant 2: every IP/hostname in raw emitted evidence resolves to a
# universe.yaml entity (server/workstation/external), not a mystery address.

_HOSTNAME_LEAF_KEYS = {
    "host", "hostname", "computer", "host_header", "server_name", "sni_hostname",
}

def _flatten_json(obj, prefix=""):
    """Yield (dotted_key, value) for every leaf (non-dict, non-list) value in a
    parsed JSON structure. List items are flattened under their parent key
    (index-free) so e.g. a list-of-dicts still yields each dict's own leaves."""
    if isinstance(obj, dict):
        for k, v in obj.items():
            dotted = f"{prefix}.{k}" if prefix else str(k)
            yield from _flatten_json(v, dotted)
    elif isinstance(obj, list):
        for item in obj:
            yield from _flatten_json(item, prefix)
    else:
        yield prefix, obj

def build_universe_allowlist(universe: dict) -> dict:
    """{'ips': set(), 'hostnames': set(), 'zone_patterns': [glob,...]} of every
    address/hostname the fictional Coppermine universe actually owns or names."""
    ips = set()
    hostnames = set()
    zone_patterns = []

    org = universe.get("org", {})
    domain = org.get("domain", "")
    netbios = org.get("netbios", "")
    if domain:
        hostnames.add(domain.lower())
        # Any subdomain of the org's own domain is unremarkable internal/
        # corporate namespace (e.g. www.coppermine.example) even when it
        # isn't one of the individually-named servers/workstations.
        zone_patterns.append(f"*.{domain.lower()}")
    if netbios:
        hostnames.add(netbios.lower())

    for name, info in {**universe.get("servers", {}), **universe.get("workstations", {})}.items():
        hostnames.add(name.lower())
        if domain:
            hostnames.add(f"{name.lower()}.{domain.lower()}")
        ip = info.get("ip")
        if ip:
            ips.add(ip)
        pub = info.get("public_ip")
        if pub:
            ips.add(pub)

    for key, val in universe.get("externals", {}).items():
        if not isinstance(val, str):
            continue
        if _IPV4_RE.match(val):
            ips.add(val)
        elif "*" in val:
            zone_patterns.append(val.lower())
        else:
            hostnames.add(val.lower())

    return {"ips": ips, "hostnames": hostnames, "zone_patterns": zone_patterns}

def _hostname_allowed(name: str, allow: dict) -> bool:
    import fnmatch
    name = name.lower().rstrip(".")
    if name in allow["hostnames"]:
        return True
    return any(fnmatch.fnmatch(name, pat) for pat in allow["zone_patterns"])

def check_ips_hosts_resolve(universe: dict, evidence_dir: Path) -> list:
    """Every IP/hostname appearing in structured network-identity fields of
    evidence_dir's zeek logs, JSON/JSONL records, and pcaps must be a universe
    entity. Scoped to structured fields (id.orig_h/id.resp_h/host/server_name/
    a DNS 'query' that actually resolved/known IP-or-hostname-shaped JSON leaf
    keys), not a blanket free-text scan: this repo's evidence legitimately
    embeds free-text prose (whois reports, alert-case narrative, incident
    briefs) that mentions RFC5737 example addresses in commentary a naive
    regex would misreport as unresolved entities. A DNS query name that got
    NXDOMAIN is skipped on purpose - the s2-dns-hunt/L1.8 decoy near-miss
    hostnames (dc10.coppermine.example etc.) are deliberately fictitious
    lookalikes that never resolve, by design, not a data-quality gap.
    """
    allow = build_universe_allowlist(universe)
    violations = []
    if not evidence_dir.exists():
        return violations

    def check_ip(val, where):
        if val and val != "-" and _IPV4_RE.match(val) and val not in allow["ips"]:
            violations.append(f"{where}: IP {val!r} does not resolve to any universe.yaml entity")

    def check_host(val, where):
        if val and val != "-" and not _hostname_allowed(val, allow):
            violations.append(f"{where}: hostname {val!r} does not resolve to any universe.yaml entity")

    for path in sorted(evidence_dir.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(REPO_ROOT)

        if path.suffix == ".pcap":
            tshark_bin = shutil.which("tshark")
            if tshark_bin is None:
                continue
            fields = ["ip.src", "ip.dst", "dns.qry.name", "dns.a",
                      "tls.handshake.extensions_server_name", "http.host"]
            cmd = [tshark_bin, "-n", "-r", str(path), "-T", "fields"]
            for fld in fields:
                cmd += ["-e", fld]
            try:
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=30, check=True)
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
                continue
            for line in result.stdout.splitlines():
                cols = line.split("\t")
                for i, fld in enumerate(fields):
                    if i >= len(cols) or not cols[i]:
                        continue
                    for tok in cols[i].split(","):
                        tok = tok.strip()
                        if not tok:
                            continue
                        if _IPV4_RE.match(tok):
                            check_ip(tok, f"{rel} (pcap {fld})")
                        else:
                            check_host(tok, f"{rel} (pcap {fld})")
            continue

        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue

        if text.startswith("#separator"):
            for row in read_zeek_tsv(path):
                check_ip(row.get("id.orig_h"), f"{rel} (id.orig_h)")
                check_ip(row.get("id.resp_h"), f"{rel} (id.resp_h)")
                host = row.get("host")
                if host:
                    check_host(host, f"{rel} (host)")
                server_name = row.get("server_name")
                if server_name:
                    check_host(server_name, f"{rel} (server_name)")
                if "query" in row and row.get("rcode_name") == "NOERROR":
                    check_host(row["query"], f"{rel} (query)")
                answers = row.get("answers")
                if answers and answers != "-" and _IPV4_RE.match(answers):
                    check_ip(answers, f"{rel} (answers)")
            continue

        # JSON or JSONL (one object per non-empty line, or a single document).
        records = []
        try:
            records = [json.loads(text)]
        except json.JSONDecodeError:
            for line in text.splitlines():
                line = line.strip()
                if not line:
                    continue
                try:
                    records.append(json.loads(line))
                except json.JSONDecodeError:
                    records = []
                    break
        if not records:
            continue
        for rec in records:
            for dotted_key, val in _flatten_json(rec):
                if not isinstance(val, str):
                    continue
                leaf = dotted_key.rsplit(".", 1)[-1].lower()
                if leaf.endswith("ip") or leaf in {"ipaddress", "clientip"}:
                    check_ip(val, f"{rel} ({dotted_key})")
                elif leaf in _HOSTNAME_LEAF_KEYS or dotted_key.lower().endswith("host.name"):
                    check_host(val, f"{rel} ({dotted_key})")
    return violations


# --- Invariant 3: every event-id-shaped answer-key value decodes to an id
# that actually appears somewhere in that lab's own emitted evidence.

def check_answer_key_event_ids_exist(check_sh_path: Path, evidence_dir: Path) -> list:
    """Decode every KEY_*_B64 in check_sh_path; for each value (or, for a
    comma/pipe-separated list of values, each part) that matches the project's
    event-id shape (e.g. CM-0312-0310), confirm that id appears literally
    somewhere in evidence_dir's files. Values that aren't event-id-shaped
    (defanged IOC strings, dispositions, MITRE ids, ...) are skipped - not
    a violation, just not applicable to this check.
    """
    violations = []
    if not check_sh_path.exists() or not evidence_dir.exists():
        return violations
    text = check_sh_path.read_text(encoding="utf-8")

    corpus_text = ""
    for path in sorted(evidence_dir.rglob("*")):
        if path.is_file() and path.suffix != ".pcap":
            try:
                corpus_text += path.read_text(encoding="utf-8") + "\n"
            except (UnicodeDecodeError, OSError):
                pass

    for m in re.finditer(r'KEY_(\w+)_B64="([^"]*)"', text):
        key_name, b64 = m.groups()
        try:
            decoded = base64.b64decode(b64).decode("utf-8")
        except (base64.binascii.Error, UnicodeDecodeError):
            continue
        parts = re.split(r'[|,]', decoded) if re.search(r'[|,]', decoded) else [decoded]
        for part in parts:
            part = part.strip()
            if not _EVENT_ID_RE.match(part):
                continue
            candidate = part.upper()
            if candidate not in corpus_text.upper():
                violations.append(
                    f"{check_sh_path.relative_to(REPO_ROOT)}: KEY_{key_name}_B64 decodes to "
                    f"{decoded!r}, whose event id {part!r} does not appear anywhere in "
                    f"{evidence_dir.relative_to(REPO_ROOT)}"
                )
    return violations


# --- Invariant 4: an alert's cited evidence.event_ids is a subset of the
# raw event ids actually emitted alongside it in the same lab.

def _collect_event_id_strings(obj, in_citation=False):
    """Recursively collect event-id-shaped string values from a parsed JSON
    structure, EXCLUDING values found inside an 'event_ids' list (those are
    citations being checked, not the raw corpus being checked against - counting
    them would make every citation trivially satisfy itself)."""
    ids = set()
    if isinstance(obj, dict):
        for k, v in obj.items():
            child_in_citation = in_citation or (k == "event_ids" and isinstance(v, list))
            ids |= _collect_event_id_strings(v, child_in_citation)
    elif isinstance(obj, list):
        for item in obj:
            ids |= _collect_event_id_strings(item, in_citation)
    elif isinstance(obj, str) and not in_citation and _EVENT_ID_RE.match(obj):
        ids.add(obj.upper())
    return ids

def _collect_citations(obj):
    """Recursively collect every 'event_ids' list's contents (the citations)."""
    out = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == "event_ids" and isinstance(v, list):
                out.append([x for x in v if isinstance(x, str)])
            out.extend(_collect_citations(v))
    elif isinstance(obj, list):
        for item in obj:
            out.extend(_collect_citations(item))
    return out

def check_alert_evidence_containment(lab_dir: Path) -> list:
    """For a soc lab directory: build the corpus of event ids the lab actually
    emits as individual raw event records (any JSON/JSONL value matching the
    event-id shape, anywhere under files/, EXCLUDING values inside an
    'event_ids' citation list itself). Then for every 'event_ids' citation
    list found anywhere under files/ (an alert's evidence.event_ids), confirm
    every cited id is in that corpus.

    Labs whose alert(s) cite ids with NO locally-emitted raw corpus at all
    (e.g. L1.5/L1.8, which point at cross-lab canonical events narratively via
    a menu/catalog rather than re-emitting the underlying event stream) have
    nothing to check against and are silently skipped for that lab - not a
    violation, since there is no local ground truth to fail against.
    """
    violations = []
    files_dir = lab_dir / "files"
    if not files_dir.exists():
        return violations

    corpus = set()
    citations = []  # list of (path, [ids])
    for path in sorted(files_dir.rglob("*.json")) + sorted(files_dir.rglob("*.jsonl")):
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        records = []
        try:
            records = [json.loads(text)]
        except json.JSONDecodeError:
            for line in text.splitlines():
                line = line.strip()
                if not line:
                    continue
                try:
                    records.append(json.loads(line))
                except json.JSONDecodeError:
                    records = []
                    break
        for rec in records:
            corpus |= _collect_event_id_strings(rec)
            for cited in _collect_citations(rec):
                citations.append((path, cited))

    if not corpus:
        return violations  # no local raw-events corpus in this lab - not applicable

    for path, cited in citations:
        missing = [c for c in cited if c.upper() not in corpus]
        if missing:
            violations.append(
                f"{path.relative_to(REPO_ROOT)}: evidence.event_ids cites {missing} "
                f"not present in {lab_dir.name}'s own emitted event corpus"
            )
    return violations


# --- Invariant 5: raw evidence (telemetry meant to "look real") never
# contains a defanged token - defanging belongs only in learner-facing text.

# Explicit, individually-read exception: these two markdown files are
# "markdown-cards"-shaped evidence (built by genevidence from per-item scenario
# text, shipped as a graded input, meant to read like a real analyst
# case/incident write-up) rather than curriculum documentation - the same
# raw-must-look-real rule applies to them as to a zeek log.
_RAW_EVIDENCE_NARRATIVE_NAMES = {"cases.md", "incident-brief.md", "triage-notes.txt"}
# Structured/log-shaped suffixes that are unambiguously raw telemetry
# regardless of filename.
_RAW_EVIDENCE_SUFFIXES = {".log", ".jsonl", ".json", ".csv", ".eml"}

def _is_raw_evidence_file(path: Path) -> bool:
    """True for files this repo's own convention (PROMPTS.md: 'raw evidence
    files do NOT defang - evidence must look real') actually governs. False
    for the large, growing set of curriculum documentation/reference/template/
    exemplar .md and .txt files under files/ (README-evidence.md, *-legend.md,
    *-template.md, model-*.md, evidence-menu.md, beacon-method.md, ...) -
    those are learner-facing prose, correctly subject to defanging instead,
    and scanning them here would be nothing but false positives (verified:
    every .md/.txt hit outside this allowlist in an initial run was exactly
    that kind of file explaining or demonstrating the defang convention
    itself, not evidence pretending to be real telemetry).
    """
    if path.name in _RAW_EVIDENCE_NARRATIVE_NAMES:
        return True
    if path.suffix in _RAW_EVIDENCE_SUFFIXES:
        return True
    if path.name.startswith("whois-") and path.suffix == ".txt":
        return True
    if path.name in {"raw-syslog.txt", "root-crontab.txt"}:
        return True
    return False

def check_raw_evidence_not_defanged(evidence_dir: Path) -> list:
    """Every raw-telemetry file under evidence_dir (a lab's files/ - zeek
    logs, pcaps, syslog, ecs-jsonl, alert-json, markdown-card evidence,
    whois/handoff-notes text, ...; see _is_raw_evidence_file) must contain
    none of the defanged-IOC tokens ('[.]', '[dot]', 'hxxp') - the SOC
    track's own convention (PROMPTS.md) is that raw evidence must look real,
    never defanged; defanging belongs only in what a learner reads/writes as
    prose, never in what genevidence emits as evidence.
    """
    violations = []
    if not evidence_dir.exists():
        return violations
    for path in sorted(evidence_dir.rglob("*")):
        if not path.is_file() or path.suffix == ".pcap" or not _is_raw_evidence_file(path):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for m in _DEFANG_RE.finditer(text):
            lineno = text.count("\n", 0, m.start()) + 1
            violations.append(
                f"{path.relative_to(REPO_ROOT)}:{lineno}: defanged token {m.group(0)!r} "
                f"found in raw evidence (evidence must look real, never defanged)"
            )
    return violations


# --- Invariant 6: learner-facing answer text defangs every external IOC it
# cites - reusing check.sh's own established grading pattern (a raw-IOC ban
# on the learner's submission), applied here to the KEY block genevidence
# itself generates, since that block IS the text a learner must reproduce.

def external_iocs(universe: dict) -> set:
    """Raw (undefanged) forms of every externals: entry that is unambiguously
    attacker/malicious infrastructure - not the generic infra (ntp_server,
    vpn_gateway, pentest_ip, research_scanner) that isn't an 'IOC' in the
    sense this rule means."""
    ext = universe.get("externals", {})
    keys = ("c2_ip", "c2_domain", "payload_ip", "payload_domain",
            "phish_sender_ip", "phish_domain")
    return {ext[k] for k in keys if k in ext}

def check_answer_keys_defang_iocs(check_sh_path: Path, iocs: set) -> list:
    """Every KEY_*_B64 value in check_sh_path's GENERATED KEY block - the
    literal text a learner must type into answers.txt to pass - must not
    contain a raw external IOC. Every genevidence-generated lab already
    defangs IP/domain answers (e.g. '203.0.113[.]66') except where the
    literal value being asked for genuinely isn't an IOC (an event id, an
    HTTP method, a disposition); a raw external IOC surviving here means the
    answer text itself teaches the un-defanged form.
    """
    violations = []
    if not check_sh_path.exists() or not iocs:
        return violations
    text = check_sh_path.read_text(encoding="utf-8")
    for m in re.finditer(r'KEY_(\w+)_B64="([^"]*)"', text):
        key_name, b64 = m.groups()
        try:
            decoded = base64.b64decode(b64).decode("utf-8")
        except (base64.binascii.Error, UnicodeDecodeError):
            continue
        for ioc in iocs:
            if ioc in decoded:
                violations.append(
                    f"{check_sh_path.relative_to(REPO_ROOT)}: KEY_{key_name}_B64 decodes to "
                    f"{decoded!r}, which contains the un-defanged external IOC {ioc!r} "
                    f"(answer text must defang; only raw evidence may not)"
                )
    return violations


# --- Driver: run every applicable invariant across every soc lab on disk. ---

def run_all_checks(universe: dict = None) -> dict:
    """Returns {check_name: [violation, ...]}. A check_name with an empty list
    holds cleanly; run_all_checks itself makes no pass/fail judgement (main()
    does), so it's reusable both from main() and from ad hoc investigation.
    """
    universe = universe or load_universe()
    global_window = universe.get("org", {}).get("scenario_window")
    scenarios_dir = GENEVIDENCE_DIR / "scenarios"
    iocs = external_iocs(universe)

    results = {
        "timestamps_in_window": [],
        "ips_hosts_resolve": [],
        "answer_key_event_ids_exist": [],
        "alert_evidence_containment": [],
        "raw_evidence_not_defanged": [],
        "answer_keys_defang_iocs": [],
    }

    for lab_dir in _find_lab_dirs():
        files_dir = lab_dir / "files"
        check_sh = lab_dir / "check.sh"

        results["raw_evidence_not_defanged"].extend(check_raw_evidence_not_defanged(files_dir))
        results["alert_evidence_containment"].extend(check_alert_evidence_containment(lab_dir))

        scen_id = _scenario_id_for_lab(check_sh)
        if scen_id is None:
            continue  # not a genevidence-generated lab - the rest need a scenario yaml

        results["answer_keys_defang_iocs"].extend(check_answer_keys_defang_iocs(check_sh, iocs))
        results["answer_key_event_ids_exist"].extend(
            check_answer_key_event_ids_exist(check_sh, files_dir)
        )

        scen_file = scenarios_dir / f"{scen_id}.yaml"
        if not scen_file.exists():
            results["timestamps_in_window"].append(
                f"{check_sh.relative_to(REPO_ROOT)}: references scenario {scen_id!r} "
                f"but {scen_file.relative_to(REPO_ROOT)} does not exist"
            )
            continue
        with open(scen_file, "r", encoding="utf-8") as f:
            scen = yaml.safe_load(f)
        window = scen.get("window") or global_window
        if window:
            results["timestamps_in_window"].extend(check_timestamps_in_window(window, files_dir))
        results["ips_hosts_resolve"].extend(check_ips_hosts_resolve(universe, files_dir))

    return results

def main():
    universe_file = GENEVIDENCE_DIR / "universe.yaml"

    if not universe_file.exists():
        print(f"ERROR: {universe_file} does not exist.")
        sys.exit(1)

    universe = load_universe(universe_file)
    print("SOC Evidence verification: universe.yaml valid.")

    results = run_all_checks(universe)
    total = 0
    for name, violations in results.items():
        if violations:
            print(f"\n--- {name}: {len(violations)} violation(s) ---")
            for v in violations:
                print(f"  {v}")
        total += len(violations)

    if total:
        print(f"\nVerification FAILED: {total} violation(s) across {len(results)} invariant(s).")
        sys.exit(1)

    print("Verification PASSED.")

if __name__ == "__main__":
    main()
