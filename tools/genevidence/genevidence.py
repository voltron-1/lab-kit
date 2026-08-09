#!/usr/bin/env python3
"""
Evidence Generator for SOC Analyst Lab Kit.
Generates evidence files and syncs base64 key blocks inside lab check.sh files.
"""

import os
import sys
import json
import base64
import struct
import hashlib
import ipaddress
import yaml
from pathlib import Path
from datetime import datetime, timedelta, timezone

sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify  # noqa: E402 - sibling module, path set immediately above

REPO_ROOT = Path(__file__).resolve().parent.parent.parent

def write_file(filepath: Path, content: str):
    filepath.parent.mkdir(parents=True, exist_ok=True)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

def write_binary(filepath: Path, content: bytes):
    filepath.parent.mkdir(parents=True, exist_ok=True)
    with open(filepath, "wb") as f:
        f.write(content)

def build_pcap_dns(queries) -> bytes:
    """Build a minimal pcap file containing DNS A query/response UDP packets."""
    global_hdr = struct.pack("<IHHiIII", 0xa1b2c3d4, 2, 4, 0, 0, 65535, 1)
    pkts = bytearray()
    eth_hdr = bytes.fromhex("00aabbccddee 001122334455 0800".replace(" ", ""))
    
    for q_item in queries:
        client_ip = [int(x) for x in q_item["client"].split(".")]
        server_ip = [int(x) for x in q_item["server"].split(".")]
        qnames = q_item["qnames"]
        
        t0 = 1773061500  # 2026-03-09T13:05:00Z approx
        step = q_item.get("step_seconds", 2)
        
        for idx, qname in enumerate(qnames):
            pkt_time = t0 + (idx * step)
            
            # DNS Query
            txn_id = 0x1234 + idx
            flags = 0x0100
            qdcount = 1
            ancount = 0
            nscount = 0
            arcount = 0
            
            dns_hdr = struct.pack(">HHHHHH", txn_id, flags, qdcount, ancount, nscount, arcount)
            qname_parts = qname.split(".")
            qname_bin = b"".join(bytes([len(p)]) + p.encode("ascii") for p in qname_parts) + b"\x00"
            qtype_qclass = struct.pack(">HH", 1, 1)
            dns_payload = dns_hdr + qname_bin + qtype_qclass
            
            src_port = 50000 + idx
            dst_port = 53
            udp_len = 8 + len(dns_payload)
            udp_hdr = struct.pack(">HHHH", src_port, dst_port, udp_len, 0)
            
            ip_tot_len = 20 + udp_len
            ip_hdr = struct.pack(">BBHHHBBH4s4s",
                                 0x45, 0x00, ip_tot_len, 0x1000 + idx, 0x0000,
                                 64, 17, 0x0000,
                                 bytes(client_ip), bytes(server_ip))
            
            frame = eth_hdr + ip_hdr + udp_hdr + dns_payload
            pkt_hdr = struct.pack("<IIII", pkt_time, 0, len(frame), len(frame))
            pkts.extend(pkt_hdr + frame)
            
            # DNS Response
            txn_id_resp = txn_id
            flags_resp = 0x8180
            ancount_resp = 1
            dns_resp_hdr = struct.pack(">HHHHHH", txn_id_resp, flags_resp, qdcount, ancount_resp, nscount, arcount)
            ans_ip = bytes([192, 0, 2, 44]) if "www" in qname else bytes([10, 20, 10, 5 + idx])
            answer_bin = struct.pack(">HHHIH", 0xc00c, 1, 1, 300, 4) + ans_ip
            dns_resp_payload = dns_resp_hdr + qname_bin + qtype_qclass + answer_bin
            
            udp_resp_len = 8 + len(dns_resp_payload)
            udp_resp_hdr = struct.pack(">HHHH", dst_port, src_port, udp_resp_len, 0)
            ip_resp_tot_len = 20 + udp_resp_len
            ip_resp_hdr = struct.pack(">BBHHHBBH4s4s",
                                      0x45, 0x00, ip_resp_tot_len, 0x2000 + idx, 0x0000,
                                      64, 17, 0x0000,
                                      bytes(server_ip), bytes(client_ip))
            
            frame_resp = eth_hdr + ip_resp_hdr + udp_resp_hdr + dns_resp_payload
            pkt_resp_hdr = struct.pack("<IIII", pkt_time + 1, 0, len(frame_resp), len(frame_resp))
            pkts.extend(pkt_resp_hdr + frame_resp)

    return global_hdr + bytes(pkts)

# --- Phase 2 generator extensions (zeek TSV, beacon series, HTTP/TLS pcaps) ---
# Reusable across s2-* scenarios; unlike the p0/p1 lab functions above (which write
# hand-typed log content straight from the scenario yaml), these build evidence
# programmatically from structured fields so uid/timestamp/count facts can never
# drift between the zeek logs, the pcaps, and the answer keys that grade them.

ZEEK_LOG_SCHEMAS = {
    "conn": (
        ["ts", "uid", "id.orig_h", "id.orig_p", "id.resp_h", "id.resp_p", "proto", "service",
         "duration", "orig_bytes", "resp_bytes", "conn_state", "history", "event_id"],
        ["time", "string", "addr", "port", "addr", "port", "enum", "string",
         "interval", "count", "count", "string", "string", "string"],
    ),
    "dns": (
        ["ts", "uid", "id.orig_h", "id.orig_p", "id.resp_h", "id.resp_p", "proto", "query",
         "qtype_name", "rcode_name", "answers", "event_id"],
        ["time", "string", "addr", "port", "addr", "port", "enum", "string",
         "string", "string", "string", "string"],
    ),
    "http": (
        ["ts", "uid", "id.orig_h", "id.orig_p", "id.resp_h", "id.resp_p", "method", "host", "uri",
         "user_agent", "status_code", "request_body_len", "response_body_len", "event_id"],
        ["time", "string", "addr", "port", "addr", "port", "string", "string", "string",
         "string", "count", "count", "count", "string"],
    ),
    "ssl": (
        ["ts", "uid", "id.orig_h", "id.orig_p", "id.resp_h", "id.resp_p", "version", "cipher",
         "server_name", "resumed", "established", "event_id"],
        ["time", "string", "addr", "port", "addr", "port", "string", "string",
         "string", "bool", "bool", "string"],
    ),
}

_ZEEK_BOOL_FIELDS = {"resumed", "established"}

def _zeek_cell(field: str, value) -> str:
    """Render one row value as a zeek TSV cell: '-' for missing/None, T/F for
    the schema's bool fields, str() otherwise. Rejects tab/CR/LF — zeek's TSV
    format has no escape for a literal delimiter inside a field, so a value
    containing one would silently inject a column or a fabricated row instead
    of failing loudly."""
    if value is None or value == "-":
        return "-"
    if field in _ZEEK_BOOL_FIELDS and isinstance(value, bool):
        return "T" if value else "F"
    text = str(value)
    if any(c in text for c in ("\t", "\n", "\r")):
        raise ValueError(f"zeek field {field!r} value {text!r} contains a raw delimiter")
    return text

def write_zeek_tsv(filepath: Path, log_type: str, rows: list):
    """Write a classic zeek TSV log (#separator/#path/#fields/#types header + tab rows)
    for `log_type` (one of ZEEK_LOG_SCHEMAS). Each row is a dict keyed by field name;
    a missing key renders as '-', zeek's unset-field marker."""
    fields, types = ZEEK_LOG_SCHEMAS[log_type]
    lines = [
        "#separator \\x09",
        "#set_separator\t,",
        "#empty_field\t(empty)",
        "#unset_field\t-",
        f"#path\t{log_type}",
        "#fields\t" + "\t".join(fields),
        "#types\t" + "\t".join(types),
    ]
    for row in rows:
        lines.append("\t".join(_zeek_cell(f, row.get(f)) for f in fields))
    write_file(filepath, "\n".join(lines) + "\n")

def beacon_conn_series(src_ip, dst_ip, dst_port, service, start_ts_iso,
                        base_period_s, jitter_offsets_s, orig_bytes, resp_bytes,
                        event_ids, uid_prefix,
                        src_port_base=49500, conn_state="SF", history="ShAdDaFf"):
    """Build a deterministic conn.log row series for one 5-tuple beacon.

    jitter_offsets_s is a FIXED list of per-hop second offsets (e.g. [0, -8, 11, ...]),
    supplied by the calling scenario yaml — never generated with `random` here — so
    re-running the generator is byte-identical. jitter_offsets_s[0] must be 0: the
    first row is always exactly start_ts_iso (the beacon's known first hit), offsets
    apply to every hop AFTER it. start_ts_iso must be timezone-aware (an explicit
    UTC offset, e.g. a trailing 'Z') so rows are never silently mislabeled UTC.

    event_ids is an explicit list of one 'CM-<MMDD>-<seq>' string per row, the same
    length as jitter_offsets_s — pulled by the caller from tools/genevidence/
    universe-events.yaml rather than minted here by blind increment, so a beacon
    series can never collide with an id another lab already pinned for a different
    event.

    Returns (rows, count); count is the exact emitted row count and must be the
    same integer the answer key uses (never hand-counted), per the soc-p2 plan's
    beacon-count-off-by-one fix.
    """
    if jitter_offsets_s[0] != 0:
        raise ValueError("jitter_offsets_s[0] is never applied to the anchor row and must be 0")
    if len(event_ids) != len(jitter_offsets_s):
        raise ValueError("event_ids must have one entry per jitter_offsets_s row")

    start = datetime.fromisoformat(start_ts_iso.replace("Z", "+00:00"))
    if start.tzinfo is None:
        raise ValueError(f"start_ts_iso {start_ts_iso!r} has no UTC offset")
    start = start.astimezone(timezone.utc)

    rows = []
    t = start
    for i, offset in enumerate(jitter_offsets_s):
        ts = t if i == 0 else t + timedelta(seconds=offset)
        rows.append({
            "ts": ts.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "uid": f"{uid_prefix}{i + 1}",
            "id.orig_h": src_ip, "id.orig_p": src_port_base + i,
            "id.resp_h": dst_ip, "id.resp_p": dst_port,
            "proto": "tcp", "service": service,
            "duration": f"{0.28 + (i % 3) * 0.01:.2f}",
            "orig_bytes": orig_bytes, "resp_bytes": resp_bytes,
            "conn_state": conn_state, "history": history,
            "event_id": event_ids[i],
        })
        t = ts + timedelta(seconds=base_period_s)
    return rows, len(rows)

_ETH_HDR = bytes.fromhex("00aabbccddee0011223344550800")

def _ip_addr(ip: str) -> bytes:
    """Authoritative dotted-quad -> 4 bytes. Raises on anything malformed
    (wrong octet count, out-of-range octet) instead of the silent pad/truncate
    that struct's '4s' format would otherwise apply to a bytes() object of the
    wrong length."""
    return ipaddress.IPv4Address(ip).packed

def _ip_hdr(src_ip, dst_ip, proto, payload_len, ident):
    return struct.pack(">BBHHHBBH4s4s",
                        0x45, 0x00, 20 + payload_len, ident, 0x0000,
                        64, proto, 0x0000, _ip_addr(src_ip), _ip_addr(dst_ip))

def _udp_hdr(sport, dport, payload_len):
    return struct.pack(">HHHH", sport, dport, 8 + payload_len, 0)

def _tcp_hdr(sport, dport, seq, ack, flags, win=64240):
    return struct.pack(">HHIIBBHHH", sport, dport, seq, ack, 5 << 4, flags, win, 0, 0)

def _frame(pkt_time, ip_hdr_bytes, l4_bytes):
    frame = _ETH_HDR + ip_hdr_bytes + l4_bytes
    return struct.pack("<IIII", pkt_time, 0, len(frame), len(frame)) + frame

def _dns_qr_packets(t0, client_ip, server_ip, qname, answer_ip, src_port=51000, txn_id=0x2001):
    """One DNS A query + response, as two ready-to-append pcap packet records."""
    qname_bin = b"".join(bytes([len(p)]) + p.encode("ascii") for p in qname.split(".")) + b"\x00"

    q_payload = struct.pack(">HHHHHH", txn_id, 0x0100, 1, 0, 0, 0) + qname_bin + struct.pack(">HH", 1, 1)
    q_ip = _ip_hdr(client_ip, server_ip, 17, 8 + len(q_payload), 0x1001)
    pkt_q = _frame(t0, q_ip, _udp_hdr(src_port, 53, len(q_payload)) + q_payload)

    answer = struct.pack(">HHHIH", 0xc00c, 1, 1, 300, 4) + _ip_addr(answer_ip)
    r_payload = (struct.pack(">HHHHHH", txn_id, 0x8180, 1, 1, 0, 0) + qname_bin
                 + struct.pack(">HH", 1, 1) + answer)
    r_ip = _ip_hdr(server_ip, client_ip, 17, 8 + len(r_payload), 0x2001)
    pkt_r = _frame(t0 + 1, r_ip, _udp_hdr(53, src_port, len(r_payload)) + r_payload)

    return [pkt_q, pkt_r]

def _tcp_handshake_packets(t0, client_ip, client_port, server_ip, server_port, seq0=1000, ack0=2000):
    """SYN, SYN-ACK, ACK — returns (packets, next_client_seq, next_server_seq)."""
    syn = _frame(t0, _ip_hdr(client_ip, server_ip, 6, 20, 0x1010),
                 _tcp_hdr(client_port, server_port, seq0, 0, 0x02))
    synack = _frame(t0 + 1, _ip_hdr(server_ip, client_ip, 6, 20, 0x2010),
                     _tcp_hdr(server_port, client_port, ack0, seq0 + 1, 0x12))
    ack = _frame(t0 + 1, _ip_hdr(client_ip, server_ip, 6, 20, 0x1011),
                 _tcp_hdr(client_port, server_port, seq0 + 1, ack0 + 1, 0x10))
    return [syn, synack, ack], seq0 + 1, ack0 + 1

def _tcp_push_packet(t0, src_ip, src_port, dst_ip, dst_port, seq, ack, payload, ident):
    ip_h = _ip_hdr(src_ip, dst_ip, 6, 20 + len(payload), ident)
    return _frame(t0, ip_h, _tcp_hdr(src_port, dst_port, seq, ack, 0x18) + payload)

def _tcp_ack_packet(t0, src_ip, src_port, dst_ip, dst_port, seq, ack, ident):
    return _frame(t0, _ip_hdr(src_ip, dst_ip, 6, 20, ident),
                  _tcp_hdr(src_port, dst_port, seq, ack, 0x10))

def _tcp_finack_packet(t0, src_ip, src_port, dst_ip, dst_port, seq, ack, ident):
    return _frame(t0, _ip_hdr(src_ip, dst_ip, 6, 20, ident),
                  _tcp_hdr(src_port, dst_port, seq, ack, 0x11))

_MAX_HTTP_BODY_BYTES = 8192

def build_pcap_http_get(client_ip, server_ip, dns_server_ip, qname, answer_ip,
                         uri, host_header, user_agent, status_line, body,
                         t0, client_port=44601, server_port=80):
    """DNS resolve + a full plaintext HTTP GET/response over TCP, as a pcap.
    Deterministic t0 + fixed-step timestamps (never a real clock read) so
    re-running the generator is byte-identical. Used by L2.4 (tshark first
    contact)."""
    for name, value in (("uri", uri), ("host_header", host_header),
                        ("user_agent", user_agent), ("status_line", status_line)):
        if "\r" in value or "\n" in value:
            raise ValueError(f"{name} may not contain CR/LF (HTTP header injection): {value!r}")
    if len(body) > _MAX_HTTP_BODY_BYTES:
        raise ValueError(f"body is {len(body)} bytes, over the {_MAX_HTTP_BODY_BYTES}-byte lab-evidence cap")

    global_hdr = struct.pack("<IHHiIII", 0xa1b2c3d4, 2, 4, 0, 0, 65535, 1)
    pkts = bytearray()

    for p in _dns_qr_packets(t0, client_ip, dns_server_ip, qname, answer_ip):
        pkts.extend(p)

    hs_pkts, seq, ack = _tcp_handshake_packets(t0 + 2, client_ip, client_port, server_ip, server_port)
    for p in hs_pkts:
        pkts.extend(p)

    request = (f"GET {uri} HTTP/1.1\r\nHost: {host_header}\r\nUser-Agent: {user_agent}\r\n"
               f"Accept: */*\r\n\r\n").encode("ascii")
    pkts.extend(_tcp_push_packet(t0 + 3, client_ip, client_port, server_ip, server_port,
                                  seq, ack, request, 0x1012))
    seq += len(request)
    pkts.extend(_tcp_ack_packet(t0 + 3, server_ip, server_port, client_ip, client_port,
                                 ack, seq, 0x2011))

    response = (f"HTTP/1.1 {status_line}\r\nContent-Type: text/plain\r\n"
                f"Content-Length: {len(body)}\r\n\r\n{body}").encode("ascii")
    pkts.extend(_tcp_push_packet(t0 + 4, server_ip, server_port, client_ip, client_port,
                                  ack, seq, response, 0x2012))
    ack2 = ack + len(response)
    pkts.extend(_tcp_ack_packet(t0 + 4, client_ip, client_port, server_ip, server_port,
                                 seq, ack2, 0x1013))

    pkts.extend(_tcp_finack_packet(t0 + 5, client_ip, client_port, server_ip, server_port,
                                    seq, ack2, 0x1014))
    pkts.extend(_tcp_ack_packet(t0 + 5, server_ip, server_port, client_ip, client_port,
                                 ack2, seq + 1, 0x2013))
    pkts.extend(_tcp_finack_packet(t0 + 5, server_ip, server_port, client_ip, client_port,
                                    ack2, seq + 1, 0x2014))
    pkts.extend(_tcp_ack_packet(t0 + 6, client_ip, client_port, server_ip, server_port,
                                 seq + 1, ack2 + 1, 0x1015))

    return bytes(global_hdr) + bytes(pkts)

def _tls_client_hello_bytes(sni_hostname: str) -> bytes:
    """A structurally valid (non-cryptographic) TLS 1.2 ClientHello record carrying
    the SNI extension — enough for tshark to dissect tls.handshake.type==1 and
    tls.handshake.extensions_server_name. This never performs or simulates a real
    handshake; it exists only so the SNI is readable from a pcap for L2.7's gate."""
    if "\r" in sni_hostname or "\n" in sni_hostname:
        raise ValueError(f"sni_hostname may not contain CR/LF: {sni_hostname!r}")
    sni_bytes = sni_hostname.encode("ascii")
    server_name_entry = struct.pack(">B", 0) + struct.pack(">H", len(sni_bytes)) + sni_bytes
    server_name_list = struct.pack(">H", len(server_name_entry)) + server_name_entry
    sni_ext = struct.pack(">HH", 0x0000, len(server_name_list)) + server_name_list

    cipher_suites = struct.pack(">6H", 0xc02c, 0xc02b, 0xc030, 0xc02f, 0x009f, 0x009e)
    compression_methods = b"\x00"

    body = (
        struct.pack(">H", 0x0303)
        + (b"\x00" * 32)
        + b"\x00"  # session_id length 0
        + struct.pack(">H", len(cipher_suites)) + cipher_suites
        + struct.pack(">B", len(compression_methods)) + compression_methods
        + struct.pack(">H", len(sni_ext)) + sni_ext
    )
    handshake = struct.pack(">B", 0x01) + struct.pack(">I", len(body))[1:] + body
    return struct.pack(">BHH", 0x16, 0x0301, len(handshake)) + handshake

def build_pcap_tls_beacon(client_ip, server_ip, dns_server_ip, sni_hostname, answer_ip,
                           t0, client_port=49500, server_port=443):
    """DNS resolve of the C2 domain + the first TLS beacon's ClientHello (SNI
    visible), as a pcap. Deterministic t0 + fixed-step timestamps. Used by L2.7's
    gate pcap, which must agree fact-for-fact with the gate's zeek bundle."""
    global_hdr = struct.pack("<IHHiIII", 0xa1b2c3d4, 2, 4, 0, 0, 65535, 1)
    pkts = bytearray()

    for p in _dns_qr_packets(t0, client_ip, dns_server_ip, sni_hostname, answer_ip):
        pkts.extend(p)

    hs_pkts, seq, ack = _tcp_handshake_packets(t0 + 4, client_ip, client_port, server_ip, server_port)
    for p in hs_pkts:
        pkts.extend(p)

    client_hello = _tls_client_hello_bytes(sni_hostname)
    pkts.extend(_tcp_push_packet(t0 + 5, client_ip, client_port, server_ip, server_port,
                                  seq, ack, client_hello, 0x1012))
    seq += len(client_hello)
    pkts.extend(_tcp_ack_packet(t0 + 5, server_ip, server_port, client_ip, client_port,
                                 ack, seq, 0x2011))

    return bytes(global_hdr) + bytes(pkts)

def sync_key_block(check_sh_path: Path, scenario_id: str, keys: dict):
    if not check_sh_path.exists():
        return
    with open(check_sh_path, "r", encoding="utf-8") as f:
        content = f.read()

    lines = []
    lines.append(f"# --- BEGIN GENERATED KEY (genevidence: {scenario_id}) ---")
    for k, v in keys.items():
        val_b64 = base64.b64encode(str(v).encode("utf-8")).decode("utf-8")
        lines.append(f"KEY_{k.upper()}_B64=\"{val_b64}\"")
    lines.append("# --- END GENERATED KEY ---")
    new_block = "\n".join(lines)

    start_marker = f"# --- BEGIN GENERATED KEY (genevidence: {scenario_id}) ---"
    end_marker = "# --- END GENERATED KEY ---"

    if start_marker in content and end_marker in content:
        before = content.split(start_marker)[0]
        after = content.split(end_marker)[1]
        updated = before + new_block + after
        with open(check_sh_path, "w", encoding="utf-8") as f:
            f.write(updated)
        print(f"Synced key block in {check_sh_path.relative_to(REPO_ROOT)}")

def generate_s0_fixtures(scen: dict):
    l01_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p0" / "L0.1-analyst-toolbelt-install-verify-jq-tshark-dig-whois-ripgrep"
    if (l01_dir / "check.sh").exists():
        l01_files = l01_dir / "files"
        write_file(l01_files / "sample-event.json", json.dumps(scen["l01_emits"]["sample_event"], indent=2) + "\n")
        pcap_data = build_pcap_dns(scen["l01_emits"]["dns_pcap_queries"])
        write_binary(l01_files / "fixtures.pcap", pcap_data)
        
        notes_text = "\n".join(scen["l01_emits"]["handoff_notes"]["lines"]) + "\n"
        write_file(l01_files / "notes" / "triage-notes.txt", notes_text)
        
        w = scen["l01_emits"]["whois_report"]
        whois_text = (
            f"Domain Name: {w['domain'].upper()}\n"
            f"Registrar: {w['registrar']}\n"
            f"Creation Date: {w['created']}\n"
            f"Updated Date: {w['updated']}\n"
            f"Registrant Organization: {w['registrant_org']}\n"
            f"Name Server: {w['name_servers'][0]}\n"
            f"Name Server: {w['name_servers'][1]}\n"
        )
        write_file(l01_files / "whois-stonewick.txt", whois_text)
    
    l02_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p0" / "L0.2-the-evidence-pack-navigate-logs-pcaps-alerts"
    if (l02_dir / "check.sh").exists():
        l02_files = l02_dir / "files"
        write_file(l02_files / "alert-sample.json", json.dumps(scen["l02_emits"]["alert_sample"], indent=2) + "\n")
        events_jsonl = "\n".join([json.dumps(ev) for ev in scen["l02_emits"]["events_jsonl"]]) + "\n"
        write_file(l02_files / "events.jsonl", events_jsonl)

    if "answer_keys" in scen:
        if "L0.1" in scen["answer_keys"]:
            sync_key_block(l01_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L0.1"])
        if "L0.2" in scen["answer_keys"]:
            sync_key_block(l02_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L0.2"])

def generate_s0_tier_cases(scen: dict):
    l03_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p0" / "L0.3-phase-gate-verify-the-analyst-toolbelt"
    if not (l03_dir / "check.sh").exists():
        return
    l03_files = l03_dir / "files"
    
    cases_md = "# Coppermine SOC Alert Cases\n\n"
    for c in scen["cards"]:
        cases_md += c["text"].strip() + "\n\n"
    write_file(l03_files / "cases.md", cases_md)

    if "answer_keys" in scen and "L0.3" in scen["answer_keys"]:
        sync_key_block(l03_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L0.3"])

def generate_s1_telemetry(scen: dict):
    l11_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p1" / "L1.1-telemetry-sources-what-gets-logged-where"
    if not (l11_dir / "check.sh").exists():
        return
    t_files = l11_dir / "files" / "telemetry"
    
    e = scen["l11_emits"]
    write_file(t_files / "a-zeek-conn.log", e["zeek_conn"].strip() + "\n")
    write_file(t_files / "b-zeek-dns.log", e["zeek_dns"].strip() + "\n")
    
    win_sec = "\n".join([json.dumps(row) for row in e["windows_security"]]) + "\n"
    write_file(t_files / "c-windows-security.json", win_sec)
    
    sysmon = "\n".join([json.dumps(row) for row in e["sysmon"]]) + "\n"
    write_file(t_files / "d-sysmon.json", sysmon)
    
    write_file(t_files / "e-auth.log", e["auth_log"].strip() + "\n")
    
    entra = "\n".join([json.dumps(row) for row in e["entra_signin"]]) + "\n"
    write_file(t_files / "f-entra-signin.json", entra)

    if "answer_keys" in scen and "L1.1" in scen["answer_keys"]:
        sync_key_block(l11_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L1.1"])

def generate_s1_log_anatomy(scen: dict):
    l12_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p1" / "L1.2-anatomy-of-a-log-timestamps-utc-ecs"
    if not (l12_dir / "check.sh").exists():
        return
    files_dir = l12_dir / "files"

    events = scen["events"]
    
    # 1. raw-syslog.txt (ascending by local time in syslog_line)
    syslog_lines = [ev["syslog_line"] for ev in sorted(events, key=lambda x: x["syslog_line"])]
    write_file(files_dir / "raw-syslog.txt", "\n".join(syslog_lines) + "\n")
    
    # 2. windows-raw.json (DC01 events: e1, e4, e3)
    evtx_list = [ev["evtx"] for ev in events if "evtx" in ev]
    write_file(files_dir / "windows-raw.json", json.dumps(evtx_list, indent=2) + "\n")
    
    # 3. ecs.jsonl (file order = ingest order: e1, e2, e3, e4, e5)
    ingest_order = ["e1", "e2", "e3", "e4", "e5"]
    by_label = {ev["label"]: ev for ev in events}
    ecs_lines = [json.dumps(by_label[lbl]["ecs"]) for lbl in ingest_order if lbl in by_label]
    write_file(files_dir / "ecs.jsonl", "\n".join(ecs_lines) + "\n")
    
    # 4. events-map.csv
    csv_rows = ["label,event_id,summary"]
    for lbl in ingest_order:
        ev = by_label[lbl]
        msg = ev["ecs"]["message"].replace(",", " ")
        csv_rows.append(f"{lbl},{ev['event_id']},{msg}")
    write_file(files_dir / "events-map.csv", "\n".join(csv_rows) + "\n")

    if "answer_keys" in scen and "L1.2" in scen["answer_keys"]:
        sync_key_block(l12_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L1.2"])

def generate_s1_alert_anatomy(scen: dict):
    l13_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p1" / "L1.3-anatomy-of-an-alert-rule-metadata-severity"
    if not (l13_dir / "check.sh").exists():
        return
    files_dir = l13_dir / "files"
    
    # 1. alert-CM-A-1024.json
    write_file(files_dir / "alert-CM-A-1024.json", json.dumps(scen["alert"], indent=2) + "\n")
    
    # 2. events/raw.jsonl
    raw_lines = "\n".join([json.dumps(ev) for ev in scen["raw_events"]]) + "\n"
    write_file(files_dir / "events" / "raw.jsonl", raw_lines)

    if "answer_keys" in scen and "L1.3" in scen["answer_keys"]:
        sync_key_block(l13_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L1.3"])

def generate_s1_sigma_read(scen: dict):
    l14_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p1" / "L1.4-reading-a-sigma-rule-logsource-detection-condition"
    if not (l14_dir / "check.sh").exists():
        return
    files_dir = l14_dir / "files"
    
    # 1. rule-encoded-powershell.yml
    write_file(files_dir / "rule-encoded-powershell.yml", scen["sigma_rule"].strip() + "\n")
    
    # 2. candidates.jsonl
    cand_lines = "\n".join([json.dumps(cand) for cand in scen["candidates"]]) + "\n"
    write_file(files_dir / "candidates.jsonl", cand_lines)

    if "answer_keys" in scen and "L1.4" in scen["answer_keys"]:
        sync_key_block(l14_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L1.4"])

def generate_s1_attack_map(scen: dict):
    l15_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p1" / "L1.5-mitre-att-ck-tactics-vs-techniques"
    if not (l15_dir / "check.sh").exists():
        return
    files_dir = l15_dir / "files"
    
    # 1. attack-excerpt.json
    write_file(files_dir / "attack-excerpt.json", json.dumps(scen["attack_excerpt"], indent=2) + "\n")
    
    # 2. alerts.jsonl
    alerts_lines = "\n".join([json.dumps(alt) for alt in scen["alerts"]]) + "\n"
    write_file(files_dir / "alerts.jsonl", alerts_lines)
    
    # 3. layer-sample.json
    write_file(files_dir / "layer-sample.json", json.dumps(scen["layer_sample"], indent=2) + "\n")

    if "answer_keys" in scen and "L1.5" in scen["answer_keys"]:
        sync_key_block(l15_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L1.5"])

def generate_s1_killchain(scen: dict):
    l16_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p1" / "L1.6-killchain-and-pyramid-of-pain"
    if not (l16_dir / "check.sh").exists():
        return
    files_dir = l16_dir / "files"
    
    # 1. incident-brief.md
    brief = "# Coppermine IR summary — WKS-ACCT-07, 2026-03-11\n\n"
    for act in scen["attacker_actions"]:
        brief += f"[{act['tag']}] {act['ts']} — {act['prose']}\n"
    write_file(files_dir / "incident-brief.md", brief)

    # 2. indicators.csv
    csv_lines = ["id,indicator_type,value,first_seen_in_incident"]
    for ind in scen["indicators"]:
        csv_lines.append(f"{ind['id']},{ind['type']},{ind['value']},{ind['first_seen']}")
    write_file(files_dir / "indicators.csv", "\n".join(csv_lines) + "\n")

    if "answer_keys" in scen and "L1.6" in scen["answer_keys"]:
        sync_key_block(l16_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L1.6"])

def generate_s1_dispositions(scen: dict):
    l17_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p1" / "L1.7-disposition-taxonomy-tp-fp-btp"
    if not (l17_dir / "check.sh").exists():
        return
    files_dir = l17_dir / "files"
    
    for case_id, c in scen["cases"].items():
        cdir = files_dir / "cases" / case_id
        write_file(cdir / "alert.json", json.dumps(c["alert"], indent=2) + "\n")
        ev_lines = "\n".join([json.dumps(ev) for ev in c["events"]]) + "\n"
        write_file(cdir / "events.jsonl", ev_lines)
        write_file(cdir / "context.txt", c["context"].strip() + "\n")

    if "answer_keys" in scen and "L1.7" in scen["answer_keys"]:
        sync_key_block(l17_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L1.7"])

def generate_s1_gate_five_alerts(scen: dict):
    l18_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p1" / "L1.8-phase-gate-the-soc-foundations"
    if not (l18_dir / "check.sh").exists():
        return
    files_dir = l18_dir / "files"
    
    # 1. alerts/CM-A-51.json .. CM-A-55.json
    for alt_item in scen["alerts"]:
        alt = alt_item["alert"]
        alt_id = alt["id"]
        write_file(files_dir / "alerts" / f"{alt_id}.json", json.dumps(alt_item, indent=2) + "\n")

    # 2. evidence-menu.md
    write_file(files_dir / "evidence-menu.md", scen["evidence_menu_md"].strip() + "\n")

    # 3. attack-excerpt.json
    write_file(files_dir / "attack-excerpt.json", json.dumps(scen["attack_excerpt"], indent=2) + "\n")

    # 4. sources-catalog.md
    catalog_md = """# Telemetry Sources Catalog

| Slug | Telemetry Plane | Description & Primary Index | Telltale Fields |
|---|---|---|---|
| `zeek-conn` | Network | Network connection state & transport metrics (`index=zeek_conn`) | `source.ip`, `destination.ip`, `destination.port`, `network.bytes` |
| `zeek-dns` | Network | DNS queries & responses (`index=zeek_dns`) | `dns.question.name`, `dns.question.type`, `dns.response_code` |
| `win-security` | Host | Windows Security Audit Event Log (`index=win_security`) | `event.code` (e.g. 4624, 4625, 4720, 4732), `winlog.logon.type`, `user.name` |
| `sysmon` | Host | Microsoft Sysmon process & system telemetry (`index=sysmon`) | `event.code` (1=Process, 3=Net, 11=File, 13=Registry), `process.command_line` |
| `linux-auth` | Host | Linux Authentication & PAM Syslog (`index=linux_auth`) | `sshd`, `sudo`, `pam_unix`, `crontab`, `systemd` |
| `entra-signin` | Identity | Microsoft Entra ID Cloud Sign-in Logs (`index=entra_signin`) | `user`, `app`, `mfa`, `result`, `source.ip` |
"""
    write_file(files_dir / "sources-catalog.md", catalog_md.strip() + "\n")

    if "answer_keys" in scen and "L1.8" in scen["answer_keys"]:
        sync_key_block(l18_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L1.8"])

_CONN_STATE_LEGEND_MD = """# Zeek `conn_state` legend

| Code | Meaning |
|---|---|
| `SF` | Normal establishment and teardown — both sides opened and closed cleanly. |
| `S0` | Connection attempt seen, no reply — the originator's SYN got no answer. |
| `REJ` | Connection attempt rejected — a RST came back instead of a SYN-ACK. |
| `RSTO` | Connection established, then reset by the **originator**. |
| `RSTR` | Connection established, then reset by the **responder**. |
| `OTH` | No SYN seen (mid-stream capture) — neither a clean open nor a clean close. |

Every row is a 5-tuple sentence: `id.orig_h:id.orig_p -> id.resp_h:id.resp_p`, over
`proto`/`service`, lasting `duration` seconds. `orig_bytes` is what the **originator**
(the host that opened the connection) sent; `resp_bytes` is what it received back.
"""

def generate_s2_conn_reading(scen: dict):
    l21_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p2" / "L2.1-conn-reading"
    if not (l21_dir / "check.sh").exists():
        return
    files_dir = l21_dir / "files"

    conn_rows = []
    for row in scen["conn_rows"]:
        conn_rows.append({
            "ts": row["ts"], "uid": row["uid"],
            "id.orig_h": row["orig_h"], "id.orig_p": row["orig_p"],
            "id.resp_h": row["resp_h"], "id.resp_p": row["resp_p"],
            "proto": row["proto"], "service": row["service"],
            "duration": row["duration"], "orig_bytes": row["orig_bytes"],
            "resp_bytes": row["resp_bytes"], "conn_state": row["conn_state"],
            "history": row["history"], "event_id": row["event_id"],
        })
    write_zeek_tsv(files_dir / "conn.log", "conn", conn_rows)

    write_file(files_dir / "conn-state-legend.md", _CONN_STATE_LEGEND_MD)

    # Comment lines sit ABOVE their bare 'qN=' field (matches every other lab's
    # answers.template.txt) rather than trailing on the same line: check.sh's
    # normalization strips '#.*' but not the whitespace that preceded it, so a
    # same-line comment left in place by a learner would break the anchored
    # ^qN=value$ match on every field except the one graded unanchored.
    answers_template = """# Read conn.log (with conn-state-legend.md as reference) and answer.

# uid of the row where the scanner's connection was REJECTED
q1=

# conn_state of the svc_backup 445/tcp copy (one token, e.g. sf)
q2=

# service label of row 5 (the short external 443 conversation)
q3=

# resp bytes the beacon's first hit received
q4=

# the ONE external dst IP a workstation opened a 443 session to that is
# NOT saas webmail - DEFANGED (e.g. 198.51.100[.]23)
q5=

# how many rows use conn_state S0 (no reply seen)
q6=
"""
    write_file(files_dir / "answers.template.txt", answers_template)

    if "answer_keys" in scen and "L2.1" in scen["answer_keys"]:
        keys = scen["answer_keys"]["L2.1"]
        s0_count = sum(1 for row in conn_rows if row["conn_state"] == "S0")
        if str(s0_count) != str(keys["q6"]):
            raise ValueError(
                f"q6 answer key is {keys['q6']!r} but conn_rows actually has "
                f"{s0_count} S0 rows - the key was hand-typed and drifted"
            )
        sync_key_block(l21_dir / "check.sh", scen["scenario"], keys)

def _tunnel_label(i: int, length: int) -> str:
    """Deterministic stand-in for a random/high-entropy DNS-tunnel subdomain
    label: a fixed hash of the row index, truncated to `length` hex chars.
    Never uses Python's `random` — re-running the generator is byte-identical."""
    return hashlib.sha256(f"tun-stonewick-{i}".encode()).hexdigest()[:length]

def generate_s2_dns_hunt(scen: dict):
    l22_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p2" / "L2.2-dns-hunt"
    if not (l22_dir / "check.sh").exists():
        return
    files_dir = l22_dir / "files"

    tb = scen["tunnel_burst"]
    start = datetime.fromisoformat(tb.get("start", scen["window"]["start"]).replace("Z", "+00:00"))
    end = datetime.fromisoformat(scen["window"]["end"].replace("Z", "+00:00"))
    if start.tzinfo is None or end.tzinfo is None:
        raise ValueError("tunnel_burst start/window end has no UTC offset")
    step = timedelta(seconds=(end - start).total_seconds() // tb["count"])

    a_indices = set(tb["a_indices"])
    noerror_indices = set(tb["noerror_indices"])
    if a_indices & noerror_indices:
        raise ValueError(
            f"a_indices and noerror_indices overlap at {a_indices & noerror_indices} - "
            "a row can't silently be both an A-qtype override and a NOERROR override "
            "without changing what q3/q4's majority actually is"
        )
    seed_ids = tb["seed_event_ids"]

    dns_rows = []
    for i in range(tb["count"]):
        ts = start + i * step
        length = 24 + (i % 9)
        label = _tunnel_label(i, length)
        qtype = "A" if i in a_indices else "TXT"
        rcode = "NOERROR" if i in noerror_indices else "NXDOMAIN"
        answers = _tunnel_label(1000 + i, 16) if rcode == "NOERROR" else "-"
        event_id = seed_ids[i] if i < len(seed_ids) else f"CM-0312-{tb['bulk_event_id_start'] + i - len(seed_ids):04d}"
        dns_rows.append({
            "ts": ts.strftime("%Y-%m-%dT%H:%M:%SZ"), "uid": f"CTUN{i + 1:05d}",
            "id.orig_h": tb["host"], "id.orig_p": 52000 + i,
            "id.resp_h": tb["resolver"], "id.resp_p": 53, "proto": "udp",
            "query": f"{label}.{tb['zone']}", "qtype_name": qtype, "rcode_name": rcode,
            "answers": answers, "event_id": event_id,
        })

    for row in scen["benign_rows"]:
        dns_rows.append({
            "ts": row["ts"], "uid": row["uid"],
            "id.orig_h": row["orig_h"], "id.orig_p": 52500 + len(dns_rows),
            "id.resp_h": "10.20.10.5", "id.resp_p": 53, "proto": "udp",
            "query": row["query"], "qtype_name": row["qtype"], "rcode_name": row["rcode"],
            "answers": row["answers"], "event_id": row["event_id"],
        })

    dns_rows.sort(key=lambda r: r["ts"])
    write_zeek_tsv(files_dir / "dns.log", "dns", dns_rows)

    answers_template = """# Hunt dns.log with awk/sort/uniq -c/rg and answer.

# source IP doing the tunneling - DEFANGED (e.g. 10.20.31[.]112)
q1=

# the tunnel zone (parent domain shared by the random labels) - DEFANGED
q2=

# dominant qtype of the tunnel traffic (one token)
q3=

# dominant rcode of the tunnel traffic (one token)
q4=

# count of tunnel-zone queries from that host
q5=

# one event_id of a tunnel query (cm-mmdd-nnnn)
q6=
"""
    write_file(files_dir / "answers.template.txt", answers_template)

    if "answer_keys" in scen and "L2.2" in scen["answer_keys"]:
        keys = scen["answer_keys"]["L2.2"]
        if str(tb["count"]) != str(keys["q5"]):
            raise ValueError(
                f"q5 answer key is {keys['q5']!r} but tunnel_burst.count is "
                f"{tb['count']} - the key was hand-typed and drifted"
            )
        sync_key_block(l22_dir / "check.sh", scen["scenario"], keys)

def generate_s2_http_tls(scen: dict):
    l23_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p2" / "L2.3-http-tls"
    if not (l23_dir / "check.sh").exists():
        return
    files_dir = l23_dir / "files"

    http_rows = [{
        "ts": row["ts"], "uid": row["uid"],
        "id.orig_h": row["orig_h"], "id.orig_p": row["orig_p"],
        "id.resp_h": row["resp_h"], "id.resp_p": row["resp_p"],
        "method": row["method"], "host": row["host"], "uri": row["uri"],
        "user_agent": row["user_agent"], "status_code": row["status_code"],
        "request_body_len": row["request_body_len"], "response_body_len": row["response_body_len"],
        "event_id": row["event_id"],
    } for row in scen["http_rows"]]
    write_zeek_tsv(files_dir / "http.log", "http", http_rows)

    ssl_rows = [{
        "ts": row["ts"], "uid": row["uid"],
        "id.orig_h": row["orig_h"], "id.orig_p": row["orig_p"],
        "id.resp_h": row["resp_h"], "id.resp_p": row["resp_p"],
        "version": row["version"], "cipher": row["cipher"],
        "server_name": row["server_name"], "resumed": row["resumed"],
        "established": row["established"], "event_id": row["event_id"],
    } for row in scen["ssl_rows"]]
    write_zeek_tsv(files_dir / "ssl.log", "ssl", ssl_rows)

    answers_template = """# Read http.log and ssl.log and answer.

# status code of the /u.sh payload pull
q1=

# the SNI (server_name) of the beacon's first TLS handshake - DEFANGED
q2=

# the user-agent string that is a scripting engine, not a browser
# (verbatim, lowercased)
q3=

# HTTP method used to send data TO the server in the suspicious row
q4=

# in the resumed TLS row, what is server_name? (one token)
q5=

# which log would you use to find the destination hostname of an
# HTTPS session: http or ssl
q6=
"""
    write_file(files_dir / "answers.template.txt", answers_template)

    if "answer_keys" in scen and "L2.3" in scen["answer_keys"]:
        sync_key_block(l23_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L2.3"])

def generate_s2_tshark_pcap(scen: dict):
    l24_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p2" / "L2.4-tshark-pcap"
    if not (l24_dir / "check.sh").exists():
        return
    files_dir = l24_dir / "files"

    c = scen["capture"]
    pcap = build_pcap_http_get(
        client_ip=c["client_ip"], server_ip=c["server_ip"], dns_server_ip=c["dns_server_ip"],
        qname=c["qname"], answer_ip=c["answer_ip"], uri=c["uri"], host_header=c["host_header"],
        user_agent=c["user_agent"], status_line=c["status_line"], body=c["body"], t0=c["t0"],
    )
    write_binary(files_dir / "capture.pcap", pcap)

    answers_template = """# Carve these facts from capture.pcap with tshark, then answer.

# qname the client resolved - DEFANGED
q1=

# IP it resolved to - DEFANGED
q2=

# HTTP method + URI, space-joined, lowercased (e.g. get /path)
q3=

# user-agent of the request (lowercased)
q4=

# HTTP status code returned
q5=
"""
    write_file(files_dir / "answers.template.txt", answers_template)

    if "answer_keys" in scen and "L2.4" in scen["answer_keys"]:
        sync_key_block(l24_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L2.4"])

def generate_s2_zeek_verdict(scen: dict):
    l25_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p2" / "L2.5-zeek-verdict"
    if not (l25_dir / "check.sh").exists():
        return
    files_dir = l25_dir / "files"

    conn_rows = [{
        "ts": r["ts"], "uid": r["uid"], "id.orig_h": r["orig_h"], "id.orig_p": r["orig_p"],
        "id.resp_h": r["resp_h"], "id.resp_p": r["resp_p"], "proto": r["proto"],
        "service": r["service"], "duration": r["duration"], "orig_bytes": r["orig_bytes"],
        "resp_bytes": r["resp_bytes"], "conn_state": r["conn_state"], "history": r["history"],
        "event_id": r["event_id"],
    } for r in scen["conn_rows"]]
    write_zeek_tsv(files_dir / "conn.log", "conn", conn_rows)

    dns_rows = [{
        "ts": r["ts"], "uid": r["uid"], "id.orig_h": r["orig_h"], "id.orig_p": r["orig_p"],
        "id.resp_h": r["resp_h"], "id.resp_p": r["resp_p"], "proto": "udp",
        "query": r["query"], "qtype_name": r["qtype_name"], "rcode_name": r["rcode_name"],
        "answers": r["answers"], "event_id": r["event_id"],
    } for r in scen["dns_rows"]]
    write_zeek_tsv(files_dir / "dns.log", "dns", dns_rows)

    http_rows = [{
        "ts": r["ts"], "uid": r["uid"], "id.orig_h": r["orig_h"], "id.orig_p": r["orig_p"],
        "id.resp_h": r["resp_h"], "id.resp_p": r["resp_p"], "method": r["method"],
        "host": r["host"], "uri": r["uri"], "user_agent": r["user_agent"],
        "status_code": r["status_code"], "request_body_len": r["request_body_len"],
        "response_body_len": r["response_body_len"], "event_id": r["event_id"],
    } for r in scen["http_rows"]]
    write_zeek_tsv(files_dir / "http.log", "http", http_rows)

    ssl_rows = [{
        "ts": r["ts"], "uid": r["uid"], "id.orig_h": r["orig_h"], "id.orig_p": r["orig_p"],
        "id.resp_h": r["resp_h"], "id.resp_p": r["resp_p"], "version": r["version"],
        "cipher": r["cipher"], "server_name": r["server_name"], "resumed": r["resumed"],
        "established": r["established"], "event_id": r["event_id"],
    } for r in scen["ssl_rows"]]
    write_zeek_tsv(files_dir / "ssl.log", "ssl", ssl_rows)

    # L2.5's whole teaching point IS uid-consistency - enforce it for real at
    # generation time rather than trusting the hand-authored rows above.
    violations = verify.check_uid_consistency({
        "conn": files_dir / "conn.log", "dns": files_dir / "dns.log",
        "http": files_dir / "http.log", "ssl": files_dir / "ssl.log",
    })
    if violations:
        raise ValueError(f"s2-zeek-verdict uid consistency violated: {violations}")

    answers_template = """# Join zeek conn/dns/http/ssl by uid and by resolved IP, then answer.

# the uid shared by the /u.sh conn row and its http row
q1=

# in ssl.log, the field name that carries the C2 destination hostname
q2=

# the dns answers value that the beacon conn row's id.resp_h matches
# (DEFANGED)
q3=

# which log tells you HOW a connection ended (conn_state lives there)
q4=

# the event_id of the ssl row for the beacon (cm-mmdd-nnnn)
q5=
"""
    write_file(files_dir / "answers.template.txt", answers_template)

    if "answer_keys" in scen and "L2.5" in scen["answer_keys"]:
        sync_key_block(l25_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L2.5"])

_BEACON_METHOD_MD = """# Beacon math - the delta method

1. Group connections by destination (`awk` on `id.resp_h`, or `id.resp_h:id.resp_p`).
2. Sort each destination's rows by `ts`.
3. Compute the delta (seconds) between each row and the one before it, per destination.
4. A near-fixed delta with small variation ("jitter") — same magnitude every time, give or
   take a small percentage — is automation's fingerprint: a program calling home on a timer.
5. Periodic is not the same as hostile. Before calling a periodic destination malicious, check:
   - **Port/service**: a well-known port (123/udp NTP, a mail sync port) argues for legitimate
     background traffic, not C2.
   - **Byte pattern**: tiny, near-identical bytes each hit reads as a heartbeat; larger,
     *varying* byte counts read as a human or an app doing real work on each poll.
   - **Destination**: is it a known-good service, or an external IP with no other footprint?

The platform can surface "this destination is periodic" automatically. Deciding whether that
periodicity is hostile — port, bytes, destination — is the Tier 1 analyst's job.
"""

def generate_s2_beaconing(scen: dict):
    l26_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p2" / "L2.6-beaconing"
    if not (l26_dir / "check.sh").exists():
        return
    files_dir = l26_dir / "files"

    bb = scen["beacon_burst"]
    beacon_rows, beacon_count = beacon_conn_series(
        bb["host"], bb["dst"], bb["dst_port"], bb["service"], bb["start"],
        bb["base_period_s"], bb["jitter_offsets_s"], bb["orig_bytes"], bb["resp_bytes"],
        bb["event_ids"], bb["uid_prefix"],
        src_port_base=49156, history="ShADadFf",
    )
    # Row 0 IS the exact same connection L2.1/L2.5 already show for CM-0311-0501
    # (uid CXbeac1) - src_port_base/history above match its 5-tuple, and its
    # duration is pinned here too since beacon_conn_series derives duration
    # from a formula, not a parameter.
    beacon_rows[0]["duration"] = "0.31"

    nb = scen["ntp_burst"]
    ntp_rows, _ = beacon_conn_series(
        nb["host"], nb["dst"], nb["dst_port"], nb["service"], nb["start"],
        nb["base_period_s"], nb["jitter_offsets_s"], nb["orig_bytes"], nb["resp_bytes"],
        nb["event_ids"], nb["uid_prefix"],
    )

    webmail_rows = [{
        "ts": r["ts"], "uid": r["uid"], "id.orig_h": "10.20.30.107", "id.orig_p": 49200 + i,
        "id.resp_h": "192.0.2.60", "id.resp_p": 443, "proto": "tcp", "service": "ssl",
        "duration": r["duration"], "orig_bytes": r["orig_bytes"], "resp_bytes": r["resp_bytes"],
        "conn_state": "SF", "history": "ShADadFf", "event_id": r["event_id"],
    } for i, r in enumerate(scen["webmail_rows"])]

    noise_rows = [{
        "ts": r["ts"], "uid": r["uid"], "id.orig_h": r["orig_h"], "id.orig_p": r["orig_p"],
        "id.resp_h": r["resp_h"], "id.resp_p": r["resp_p"], "proto": r["proto"],
        "service": r["service"], "duration": r["duration"], "orig_bytes": r["orig_bytes"],
        "resp_bytes": r["resp_bytes"], "conn_state": r["conn_state"], "history": r["history"],
        "event_id": r["event_id"],
    } for r in scen["noise_rows"]]

    all_rows = sorted(beacon_rows + ntp_rows + webmail_rows + noise_rows, key=lambda r: r["ts"])
    write_zeek_tsv(files_dir / "conn.log", "conn", all_rows)

    write_file(files_dir / "beacon-method.md", _BEACON_METHOD_MD)

    answers_template = """# Group conn.log by destination, compute deltas, and answer.

# the beaconing host - DEFANGED
q1=

# the hostile beacon's destination IP - DEFANGED
q2=

# approximate base period of the hostile beacon, seconds (integer)
q3=

# number of hostile beacon connections in the log
q4=

# the destination IP that is ALSO periodic but BENIGN - DEFANGED
q5=

# one word: why q5 is benign despite being periodic (port|service)
q6=
"""
    write_file(files_dir / "answers.template.txt", answers_template)

    if "answer_keys" in scen and "L2.6" in scen["answer_keys"]:
        keys = scen["answer_keys"]["L2.6"]
        if str(beacon_count) != str(keys["q4"]):
            raise ValueError(
                f"q4 answer key is {keys['q4']!r} but beacon_burst actually emitted "
                f"{beacon_count} rows - the key was hand-typed and drifted"
            )
        sync_key_block(l26_dir / "check.sh", scen["scenario"], keys)

def generate_s2_gate_session(scen: dict):
    l27_dir = REPO_ROOT / "tracks" / "soc" / "phases" / "p2" / "L2.7-gate-session-story"
    if not (l27_dir / "check.sh").exists():
        return
    files_dir = l27_dir / "files"
    zeek_dir = files_dir / "zeek"

    conn_rows = [{
        "ts": r["ts"], "uid": r["uid"], "id.orig_h": r["orig_h"], "id.orig_p": r["orig_p"],
        "id.resp_h": r["resp_h"], "id.resp_p": r["resp_p"], "proto": r["proto"],
        "service": r["service"], "duration": r["duration"], "orig_bytes": r["orig_bytes"],
        "resp_bytes": r["resp_bytes"], "conn_state": r["conn_state"], "history": r["history"],
        "event_id": r["event_id"],
    } for r in scen["conn_rows"]]
    write_zeek_tsv(zeek_dir / "conn.log", "conn", conn_rows)

    dns_rows = [{
        "ts": r["ts"], "uid": r["uid"], "id.orig_h": r["orig_h"], "id.orig_p": r["orig_p"],
        "id.resp_h": r["resp_h"], "id.resp_p": r["resp_p"], "proto": "udp",
        "query": r["query"], "qtype_name": r["qtype_name"], "rcode_name": r["rcode_name"],
        "answers": r["answers"], "event_id": r["event_id"],
    } for r in scen["dns_rows"]]
    write_zeek_tsv(zeek_dir / "dns.log", "dns", dns_rows)

    http_rows = [{
        "ts": r["ts"], "uid": r["uid"], "id.orig_h": r["orig_h"], "id.orig_p": r["orig_p"],
        "id.resp_h": r["resp_h"], "id.resp_p": r["resp_p"], "method": r["method"],
        "host": r["host"], "uri": r["uri"], "user_agent": r["user_agent"],
        "status_code": r["status_code"], "request_body_len": r["request_body_len"],
        "response_body_len": r["response_body_len"], "event_id": r["event_id"],
    } for r in scen["http_rows"]]
    write_zeek_tsv(zeek_dir / "http.log", "http", http_rows)

    ssl_rows = [{
        "ts": r["ts"], "uid": r["uid"], "id.orig_h": r["orig_h"], "id.orig_p": r["orig_p"],
        "id.resp_h": r["resp_h"], "id.resp_p": r["resp_p"], "version": r["version"],
        "cipher": r["cipher"], "server_name": r["server_name"], "resumed": r["resumed"],
        "established": r["established"], "event_id": r["event_id"],
    } for r in scen["ssl_rows"]]
    write_zeek_tsv(zeek_dir / "ssl.log", "ssl", ssl_rows)

    p = scen["pcap"]
    pcap = build_pcap_tls_beacon(
        client_ip=p["client_ip"], server_ip=p["server_ip"], dns_server_ip=p["dns_server_ip"],
        sni_hostname=p["sni_hostname"], answer_ip=p["answer_ip"], t0=p["t0"],
    )
    write_binary(files_dir / "capture.pcap", pcap)

    # The gate's two hard invariants, enforced for real at generation time:
    # every uid must join consistently across the zeek bundle, and every fact
    # tshark can pull from capture.pcap must be corroborated somewhere in that
    # same bundle - the pcap and the logs must tell one story, not two.
    zeek_logs = {
        "conn": zeek_dir / "conn.log", "dns": zeek_dir / "dns.log",
        "http": zeek_dir / "http.log", "ssl": zeek_dir / "ssl.log",
    }
    uid_violations = verify.check_uid_consistency(zeek_logs)
    if uid_violations:
        raise ValueError(f"s2-gate-session uid consistency violated: {uid_violations}")
    agreement_violations = verify.check_pcap_zeek_agreement(
        files_dir / "capture.pcap", list(zeek_logs.values())
    )
    if agreement_violations:
        raise ValueError(f"s2-gate-session pcap<->zeek agreement violated: {agreement_violations}")

    answers_template = """# Reconstruct the C2 session from the zeek bundle + capture.pcap together.
# IOC answers DEFANGED; timestamps not required.

# the C2 domain the victim resolved - DEFANGED
q1=

# the C2 IP it resolved to - DEFANGED
q2=

# the SNI seen in the first TLS handshake - DEFANGED
q3=

# the beacon base period in seconds (integer)
q4=

# the beaconing host - DEFANGED
q5=

# the tunneling host (a different host) - DEFANGED
q6=

# the plaintext payload URI pulled by WEB01
q7=

# event_id of the pre-beacon C2 DNS resolve (cm-mmdd-nnnn)
q8=
"""
    write_file(files_dir / "answers.template.txt", answers_template)

    if "answer_keys" in scen and "L2.7" in scen["answer_keys"]:
        sync_key_block(l27_dir / "check.sh", scen["scenario"], scen["answer_keys"]["L2.7"])

def main():
    genevidence_dir = Path(__file__).resolve().parent
    scenarios_dir = genevidence_dir / "scenarios"
    
    for scen_file in scenarios_dir.glob("*.yaml"):
        with open(scen_file, "r", encoding="utf-8") as f:
            scen = yaml.safe_load(f)
        scen_id = scen.get("scenario")
        print(f"Processing scenario {scen_id}...")
        if scen_id == "s0-fixtures":
            generate_s0_fixtures(scen)
        elif scen_id == "s0-tier-cases":
            generate_s0_tier_cases(scen)
        elif scen_id == "s1-telemetry":
            generate_s1_telemetry(scen)
        elif scen_id == "s1-log-anatomy":
            generate_s1_log_anatomy(scen)
        elif scen_id == "s1-alert-anatomy":
            generate_s1_alert_anatomy(scen)
        elif scen_id == "s1-sigma-read":
            generate_s1_sigma_read(scen)
        elif scen_id == "s1-attack-map":
            generate_s1_attack_map(scen)
        elif scen_id == "s1-killchain":
            generate_s1_killchain(scen)
        elif scen_id == "s1-dispositions":
            generate_s1_dispositions(scen)
        elif scen_id == "s1-gate-five-alerts":
            generate_s1_gate_five_alerts(scen)
        elif scen_id == "s2-conn-reading":
            generate_s2_conn_reading(scen)
        elif scen_id == "s2-dns-hunt":
            generate_s2_dns_hunt(scen)
        elif scen_id == "s2-http-tls":
            generate_s2_http_tls(scen)
        elif scen_id == "s2-tshark-pcap":
            generate_s2_tshark_pcap(scen)
        elif scen_id == "s2-zeek-verdict":
            generate_s2_zeek_verdict(scen)
        elif scen_id == "s2-beaconing":
            generate_s2_beaconing(scen)
        elif scen_id == "s2-gate-session":
            generate_s2_gate_session(scen)

if __name__ == "__main__":
    main()
