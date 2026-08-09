async DoS is real: unbounded awaits and uncapped task spawns are CWE-400 resource exhaustion risks
tokio::time::timeout limits await durations while Semaphores cap concurrent task execution
memory-safe Rust does not guarantee availability — timeouts and concurrency caps are mandatory review items
