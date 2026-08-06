## BRIEF
A pcap is queryable from the shell: `tshark -r file -Y <display filter> -T fields -e <field>` pulls
exactly the fact you need, and `-z follow,tcp,ascii,<n>` reassembles a whole conversation. This is a
GUIDED lab — run every command for real; the files they produce are what gets graded.

## GUIDED STEPS

1. **Extract the DNS query and answer**:
   ```bash
   tshark -r capture.pcap -Y 'dns.flags.response==0' -T fields -e dns.qry.name | sort -u > dns_q.txt
   tshark -r capture.pcap -Y 'dns.flags.response==1' -T fields -e dns.a | sort -u > dns_a.txt
   cat dns_q.txt dns_a.txt
   ```
   ```
   cdn.stonewick.example
   198.51.100.23
   ```

2. **Extract the HTTP request line and user-agent**:
   ```bash
   tshark -r capture.pcap -Y http.request -T fields -e http.request.method -e http.host -e http.request.uri > http_req.txt
   tshark -r capture.pcap -Y http.request -T fields -e http.user_agent > http_ua.txt
   cat http_req.txt http_ua.txt
   ```
   ```
   GET	cdn.stonewick.example	/u.sh
   curl/7.81.0
   ```

3. **Extract the HTTP status code**:
   ```bash
   tshark -r capture.pcap -Y 'http.response' -T fields -e http.response.code > http_status.txt
   cat http_status.txt
   ```
   ```
   200
   ```

4. **Record your answers**:
   Copy `answers.template.txt` to `answers.txt`:
   ```bash
   cp answers.template.txt answers.txt
   ```
   Fill in each field from what you just carved:
   - `q1`: qname the client resolved, defanged (`cdn.stonewick[.]example`)
   - `q2`: IP it resolved to, defanged (`198.51.100[.]23`)
   - `q3`: HTTP method + URI, space-joined, lowercased (`get /u.sh`)
   - `q4`: user-agent of the request, lowercased (`curl/7.81.0`)
   - `q5`: HTTP status code returned (`200`)

   (`dns_q.txt`/`dns_a.txt`/`http_req.txt`/`http_status.txt` are tool output, not learner prose — leave
   them exactly as tshark produced them, fanged. Only your `answers.txt` IOCs get defanged.)

5. **OPTIONAL, UNGRADED — follow the whole TCP stream as text**:
   ```bash
   tshark -r capture.pcap -z follow,tcp,ascii,0 -q
   ```
   ```
   ===================================================================
   Follow: tcp,ascii
   Filter: tcp.stream eq 0
   Node 0: 10.20.10.20:44601
   Node 1: 198.51.100.23:80
   89
   GET /u.sh HTTP/1.1
   Host: cdn.stonewick.example
   User-Agent: curl/7.81.0
   Accept: */*


   	157
   HTTP/1.1 200 OK
   Content-Type: text/plain
   Content-Length: 92

   #!/bin/sh
   # inert simulacrum - a comment, not a working payload; nothing here runs anything

   ===================================================================
   ```
   `-z follow,tcp` reassembles scattered packets back into the full request and response — the same
   conversation you carved field-by-field above, now readable as one exchange.

6. **Check your work**:
   ```bash
   lab check soc L2.4
   ```

## SECURITY ONION (OPTIONAL)
The same pcap can be uploaded to `cardinal-so` and pivoted in the PCAP/Zeek view of the Hunt UI; the
tshark path above is the graded one — the VM is optional and nothing here checks for it.
