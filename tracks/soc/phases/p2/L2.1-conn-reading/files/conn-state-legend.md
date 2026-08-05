# Zeek `conn_state` legend

| Code | Meaning |
|---|---|
| `SF` | Normal establishment and teardown — both sides opened and closed cleanly. |
| `S0` | Connection attempt seen, no reply — the originator's SYN got no answer. |
| `REJ` | Connection attempt rejected — a RST came back instead of a SYN-ACK. |
| `RSTO` | Connection established, then reset by the **originator**. |
| `RSTR` | Connection established, then reset by the **responder**. |
| `OTH` | No SYN seen (mid-stream capture) — neither a clean open nor a clean close. |

Every row is a 5-tuple sentence: `id.orig_h:id.orig_p -> id.resp_h:id.resp_p`, over
`proto`/`service`, lasting `duration` seconds. `orig_bytes` is what the **originator**
(the host that opened the connection) sent; `resp_bytes` is what it received back.
