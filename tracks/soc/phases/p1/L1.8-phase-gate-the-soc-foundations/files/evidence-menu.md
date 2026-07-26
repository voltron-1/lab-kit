# Evidence Pull Options

## Alert CM-A-51 (Credential Access)
- a) WHOIS and GeoIP lookup report for IP 203.0.113.66
- b) Raw entra-signin records for 2026-03-11 14:05Z–14:25Z from IP 203.0.113.66 across all accounts, including event CM-0311-0143
- c) Sysmon process creation events from workstation WKS-ACCT-07

## Alert CM-A-52 (Execution)
- a) Sysmon Event ID 1 on WKS-ACCT-07 near 15:41Z containing WINWORD.EXE parent and full powershell.exe -enc command line (event CM-0311-0201)
- b) Zeek connection log egress records for WKS-ACCT-07
- c) Windows Security Event ID 4624 for m.reyes on DC01

## Alert CM-A-53 (Command and Control)
- a) Entra sign-in log records for user d.okafor
- b) Live `dig` query to tun.stonewick.example
- c) Zeek DNS log records for source 10.20.31.112 querying tun.stonewick.example showing subdomain length and NXDOMAIN status (events CM-0312-0310..0312)

## Alert CM-A-54 (Persistence)
- a) Windows Security events 4720 (user creation) and 4732 (group membership change) on FS01 (events CM-0311-0244 and CM-0311-0245)
- b) Entra ID directory audit logs for supportadmin
- c) Sysmon process creation events from WKS-ACCT-07

## Alert CM-A-55 (Persistence)
- a) WHOIS report for domain cdn.stonewick.example
- b) WEB01 auth.log entries for 20:15Z–20:21Z showing SSH authentication for root from 203.0.113.66, crontab REPLACE, and PAM session open (events CM-0312-0455..0460)
- c) Zeek conn records for 300s beaconing from WKS-ACCT-07 to 203.0.113.66:443
