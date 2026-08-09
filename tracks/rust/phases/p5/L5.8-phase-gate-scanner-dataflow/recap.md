gate passed: traced a bounded async scanner combining Semaphore cap, timeout, channel, and spawn loop
race-free by sharing nothing mutably: tasks own local state, report via messages, and sort results
Phase 5 verdict: Rust kills data races at compile time; timeouts and caps are still your responsibility
