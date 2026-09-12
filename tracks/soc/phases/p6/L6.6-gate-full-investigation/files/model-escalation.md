# Full Escalation Report (Worked Example — a DIFFERENT case than the one you are graded on)
This example works the 2026-03-12 DNS-tunnel case end to end so you can see the
shape of a complete report. The case you are graded on is in `files/case/` — its
hosts, events, techniques and verdict are yours to establish.

## Scope
- 1 host affected: wks-acct-07

## Timeline
- 2026-03-12 03:10:44Z: Event cm-0312-0310 — 2217 TXT queries to `tun.stonewick[.]example`, mean label length 48.
- 2026-03-12 03:51:10Z: queries stop; no second host reproduces the pattern.

## Indicators
- Tunnel zone: `tun.stonewick[.]example`
- Pattern: TXT record type, 2217 queries in 40 minutes

## ATT&CK
- T1071.004: Application Layer Protocol — DNS
- T1048.003: Exfiltration Over Unencrypted Non-C2 Protocol

## Verdict
- True Positive / Malicious — tunnelled data, not name resolution.

## Recommendation
- Sinkhole `tun.stonewick[.]example` and isolate wks-acct-07.
- Hunt the same query shape across the workstation subnets for scope.
