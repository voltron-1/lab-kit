## BRIEF
Enrichment adds context to an indicator (IP, domain, hash) by reading mock VirusTotal, WHOIS, and Passive DNS reports.
`lab check` always grades against these staged reports, never a live lookup — the graded path is offline and deterministic by design, so no lab ever depends on a real WHOIS/dig/VT service being reachable.

## GUIDED STEPS

1. Inspect files in `files/enrichment/`.
2. Run the following extraction commands:
   ```bash
   jq '.last_analysis_stats.malicious' files/enrichment/vt-ip-203.0.113.66.json > vt_mal.txt
   jq -r '.resolutions[].domain' files/enrichment/pdns-203.0.113.66.json > pdns_domains.txt
   ```
3. Copy `files/answers.template.txt` to `answers.txt`:
   ```bash
   cp files/answers.template.txt answers.txt
   ```
4. Fill `answers.txt`:
   - `q1`: VT malicious count for 203.0.113.66 -> `31`
   - `q2`: Defanged domain for 203.0.113.66 -> `c2.stonewick[.]example`
   - `q3`: Creation Date of domain from WHOIS -> `2026-02-27`
   - `q4`: VT malicious count for hash -> `52`
   - `q5`: Which source proved dedicated single-domain hosting? (one word) -> `passive-dns`
5. Verify with `lab check soc L4.2`.
