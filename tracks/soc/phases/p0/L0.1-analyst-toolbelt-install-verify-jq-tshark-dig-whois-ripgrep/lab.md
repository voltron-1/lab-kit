## BRIEF
Every SOC analyst needs a core command-line toolbelt for inspecting log data, packet captures, DNS records, and domain WHOIS reports.
Your toolbelt consists of five core utilities: `jq` (JSON parsing), `tshark` (packet analysis), `dig` (DNS lookups), `whois` (domain registration data), and `ripgrep` (`rg`, fast text searching).
In this lab, you install or verify these five utilities in your environment and run each tool against staged Coppermine Logistics evidence.

## GUIDED STEPS

1. **Install/verify the analyst toolbelt**:
   Run the package manager installation:
   ```bash
   sudo apt-get update && sudo apt-get install -y jq tshark dnsutils whois ripgrep
   ```
   *(Note: If prompted whether non-root users should be allowed to capture packets, select either option — reading PCAP files requires no special privileges).*

2. **Generate tool version proof (`toolcheck.txt`)**:
   Execute the version check commands into `toolcheck.txt`:
   ```bash
   { jq --version; tshark --version | head -1; dig -v 2>&1; whois --version; rg --version | head -1; } > toolcheck.txt
   ```

3. **Extract username using `jq`**:
   Parse `.user.name` from `sample-event.json` into `jq_out.txt`:
   ```bash
   jq -r '.user.name' sample-event.json > jq_out.txt
   ```

4. **Extract unique DNS query names using `tshark`**:
   Parse DNS queries from `fixtures.pcap` into `tshark_out.txt`:
   ```bash
   tshark -n -r fixtures.pcap -T fields -e dns.qry.name | sort -u > tshark_out.txt
   ```

5. **Search escalation marker using `ripgrep`**:
   Search for the escalation marker in `notes/triage-notes.txt` into `rg_out.txt`:
   ```bash
   rg --no-ignore 'escalation-marker' notes/ > rg_out.txt
   ```

6. **Inspect mock WHOIS report**:
   View the registration details for `stonewick.example`:
   ```bash
   grep 'Creation Date' whois-stonewick.txt
   ```

7. **Check your work**:
   ```bash
   lab check soc L0.1
   ```
