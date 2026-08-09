Tokio task pools use a spawn loop to launch tasks and a join_next drain loop to collect results
tasks complete in nondeterministic order, requiring order-independent accumulators
dropping a JoinSet cancels all tasks remaining in the set
