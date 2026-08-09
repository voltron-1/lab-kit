an async fn returns a lazy Future — calling it executes no code until .await is called
.await yields control to the runtime while waiting, avoiding OS thread blocking
#[tokio::main] sets up the async runtime required to poll main's top-level future
