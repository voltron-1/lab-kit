## BRIEF
`std::sync::mpsc` stands for **Multi-Producer, Single-Consumer** channels.
- Multiple threads can send messages by cloning the transmitter (`tx.clone()`).
- A single receiver (`rx`) collects messages.

Iterating over `rx` (`for value in rx`) yields messages as they arrive and terminates **only when all transmitters have been dropped**. If the original `tx` is not explicitly dropped when cloned transmitters are used, the receive loop will hang indefinitely waiting for potential future messages.

## GUIDED STEPS

1. Inspect `files/sample.rs`.
2. Predict `count` (number of items received) and `total` (sum of items received).
3. Create `predictions.txt`:
   - `count`: Number of messages received -> `3`
   - `total`: Sum of all messages received ((1*100) + (2*100) + (3*100)) -> `600`

Format `predictions.txt`:
```text
count=3
total=600
```

4. Compile and run `files/sample.rs`:
   ```bash
   rustc files/sample.rs -o sample
   ./sample
   ```
5. Verify with `lab check rust L5.4`.
