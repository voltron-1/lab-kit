## BRIEF
This is the **Phase 2 Phase Gate** for the SOC Analyst Lab.

In this lab, you are provided with both a `capture.pcap` file and a set of Zeek log files (`zeek/conn.log`, `zeek/dns.log`, `zeek/http.log`, `zeek/ssl.log`). Reconstruct the full network session story across both evidence forms.

## GUIDED STEPS

1. Inspect `zeek/dns.log`, `zeek/conn.log`, `zeek/ssl.log`, and `zeek/http.log`.
2. Inspect `capture.pcap` using `tshark`.
3. Create `answers.txt` by filling in `answers.template.txt`:
   - `q1`: C2 domain resolved (DEFANGED) -> `c2.stonewick[.]example`
   - `q2`: C2 IP resolved (DEFANGED) -> `203.0.113[.]66`
   - `q3`: SNI in first TLS handshake (DEFANGED) -> `c2.stonewick[.]example`
   - `q4`: Beacon base period in seconds -> `300`
   - `q5`: Beaconing host IP (DEFANGED) -> `10.20.30[.]107`
   - `q6`: Tunneling host IP (DEFANGED) -> `10.20.31[.]112`
   - `q7`: Plaintext payload URI -> `/u.sh`
   - `q8`: Event ID of the pre-beacon C2 DNS resolve -> `cm-0311-0500`

Format `answers.txt`:
```text
q1=c2.stonewick[.]example
q2=203.0.113[.]66
q3=c2.stonewick[.]example
q4=300
q5=10.20.30[.]107
q6=10.20.31[.]112
q7=/u.sh
q8=cm-0311-0500
```

4. Verify with `lab check soc L2.7`.
