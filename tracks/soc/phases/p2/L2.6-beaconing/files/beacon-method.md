# Beacon math - the delta method

1. Group connections by destination (`awk` on `id.resp_h`, or `id.resp_h:id.resp_p`).
2. Sort each destination's rows by `ts`.
3. Compute the delta (seconds) between each row and the one before it, per destination.
4. A near-fixed delta with small variation ("jitter") — same magnitude every time, give or
   take a small percentage — is automation's fingerprint: a program calling home on a timer.
5. Periodic is not the same as hostile. Before calling a periodic destination malicious, check:
   - **Port/service**: a well-known port (123/udp NTP, a mail sync port) argues for legitimate
     background traffic, not C2.
   - **Byte pattern**: tiny, near-identical bytes each hit reads as a heartbeat; larger,
     *varying* byte counts read as a human or an app doing real work on each poll.
   - **Destination**: is it a known-good service, or an external IP with no other footprint?

The platform can surface "this destination is periodic" automatically. Deciding whether that
periodicity is hostile — port, bytes, destination — is the Tier 1 analyst's job.
