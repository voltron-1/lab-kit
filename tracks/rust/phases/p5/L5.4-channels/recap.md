mpsc channels allow multiple senders (tx.clone()) feeding one receiver (rx)
receiving loop for v in rx runs until ALL senders drop; a live tx clone causes a hang
totals over channels are deterministic even when message arrival order is nondeterministic
