# Coppermine SOC Alert Cases

## CASE 1 — alert CM-A-1 — Password spray — OWA/VPN auth failures
Between 2026-03-11 14:05Z and 14:25Z, source IP 203.0.113.66 initiated 4625 login failure bursts across 40+ COPPERMINE accounts.
At 14:22:31Z, ONE successful 4624 type 3 logon was recorded for account m.reyes on DC01.
An accompanying Entra ID sign-in succeeded from the same external IP with no MFA claim present, originating from a geolocation inconsistent with her 13:58Z Duluth VPN session.

## CASE 2 — alert CM-A-2 — AV quarantine — adware
At 2026-03-10T16:12Z, Defender on WKS-HD-03 (j.walsh) quarantined commodity adware bundler 'PDFTurbo Setup' immediately upon download.
Endpoint telemetry shows no process creation (4688), no network connections (Sysmon 3), and no secondary host activity.

## CASE 3 — alert CM-A-3 — User-reported phish
At 2026-03-09T13:30Z, d.okafor forwarded a suspicious email from billing@copperm1ne-billing.example (sender IP 198.51.100.71) linking to http://copperm1ne-billing.example/invoice.
Zeek HTTP and DNS logs confirm zero requests originated from 10.20.31.112 (WKS-ENG-12), and no unusual process execution occurred.

## CASE 4 — alert CM-A-4 — Remote admin tool on DC
At 2026-03-12T19:41Z, PSEXESVC service was installed on DC01 authenticated as t.aoki.
No change control ticket covers this time window (charter lists only CHG-2143 on 2026-03-10 10:00Z).
At 19:44Z, Event 4720 recorded new account creation for 'it_svc_tmp', immediately followed by Event 4732 adding it to Domain Administrators.

## CASE 5 — alert CM-A-5 — Mass file copy
At 2026-03-12T02:00:14Z, a large SMB file transfer was detected from SRV-BACKUP to FS01.
Process telemetry identifies robocopy.exe running under service account svc_backup, exactly matching the charter's documented nightly 02:00Z backup job.

