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
import yaml
from pathlib import Path

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

if __name__ == "__main__":
    main()
