# Phishing Report (Worked Example — a DIFFERENT case than the one you are graded on)
This example works the 2026-03-12 credential-harvest report from d.okafor. Your
report covers the case in `files/`. Copy the SHAPE, not the content.

## Summary
A link-based credential-harvest email reached d.okafor and was reported before any
credentials were entered.

## Timeline
- 2026-03-12 08:14:02Z: delivery from `copperm1ne-billing[.]example` via 198.51.100[.]71.
- 2026-03-12 08:31:55Z: user reported the message; no click recorded in proxy logs.

## Indicators
- Sender domain: `copperm1ne-billing[.]example` (lookalike of the org domain)
- Sending IP: 198.51.100[.]71
- Credential-harvest link: `hxxp://cdn.stonewick[.]example/sso`

## ATT&CK
- T1566.002: Phishing — Spearphishing Link

## Verdict
- Phish (credential harvest). No compromise: the link was never opened.

## Recommendation
- Block the sender domain and the harvest URL at the proxy.
- Sweep mail for the same sending IP and pull any remaining copies.
