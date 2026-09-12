# Capstone Report (Worked Example — a DIFFERENT case than the one you are graded on)
This example works the 2026-03-12 DNS-tunnel case. Your capstone covers the case
in `files/` — its scope, events, techniques, verdict and tuning recommendation
are yours to establish.

## Scope
- 1 host affected: wks-acct-07

## Timeline
- 2026-03-12 03:10:44Z: Event cm-0312-0310 — 2217 TXT queries to `tun.stonewick[.]example`, mean label length 48.
- 2026-03-12 03:51:10Z: queries stop; no other host reproduces the pattern.

## Indicators
- Tunnel zone: `tun.stonewick[.]example`
- Pattern: TXT, 2217 queries in 40 minutes

## ATT&CK
- T1071.004: Application Layer Protocol — DNS
- T1048.003: Exfiltration Over Unencrypted Non-C2 Protocol

## Verdict
- True Positive / Malicious — tunnelled data, not name resolution.

## Recommendation
- Sinkhole the tunnel zone, isolate the host, and hand the capture to Tier 2.

## Tuning Recommendation
- `query.zone:tun.stonewick[.]example` — alert on TXT volume per host per hour rather than per query, so one tunnelling session raises one alert instead of 2217.
