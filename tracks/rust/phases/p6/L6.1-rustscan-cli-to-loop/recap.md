tour a tool CLI-first: options struct -> config -> the loop that does the work
RustScan turns targets+ports into batches of async connect futures, awaited a batch at a time
concurrency is bounded (batch size ~ FD ulimit) and each connect is timeout-bounded — L5.7/L5.8 for real
