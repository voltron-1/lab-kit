Received headers read bottom-up: the last hop is where the mail actually originated, regardless of what From claims.
SPF, DKIM, and DMARC are the alignment verdict — all three failing on a billing email is a loud spoofing signal.
The friendly From name is free to forge; the headers and auth results are what you trust.
