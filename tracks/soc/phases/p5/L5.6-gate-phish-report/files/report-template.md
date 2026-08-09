# Phishing Escalation Report

## Timeline
- 2026-03-11 15:02Z: Email received from billing@copperm1ne-billing[.]example

## Indicators
- Sender IP: 198.51.100[.]71
- Domain: copperm1ne-billing[.]example
- C2 URL: hxxp://cdn.stonewick[.]example/pay

## ATT&CK
- T1566.001 Spearphishing Attachment

## Verdict
- True Positive / Malicious Phish

## Recommendation
- Block sender IP and domain at gateway
- Reset compromised user credentials
