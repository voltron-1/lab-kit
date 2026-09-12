# Escalation Ticket (Worked Example — a DIFFERENT case than the one you are graded on)
This example works the 2026-03-12 DNS-tunnel case. Your ticket covers the case in
`files/`. Copy the SHAPE, not the content.

## Scope
- 1 host affected: wks-acct-07

## Timeline
- 2026-03-12 03:10:44Z: Event cm-0312-0310 — 2217 TXT queries to `tun.stonewick[.]example` in 40 minutes, mean label length 48.
- 2026-03-12 03:51:10Z: query volume stops; no other host shows the pattern.

## Indicators
- Tunnel zone: `tun.stonewick[.]example`
- Query type: TXT, 2217 queries / 40 minutes

## ATT&CK
- T1071.004: Application Layer Protocol — DNS
- T1048.003: Exfiltration Over Unencrypted Non-C2 Protocol

## Verdict
- Malicious. The volume, record type and label length are consistent with tunnelled data, not resolution.

## Recommendation
- Sinkhole the tunnel zone and isolate wks-acct-07 pending review.
- Pull the 40-minute query capture for Tier 2.
