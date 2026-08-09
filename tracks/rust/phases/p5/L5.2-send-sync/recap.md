Send = safe to move to another thread; Sync = safe to share &T across threads
Send and Sync are auto traits — a cannot be sent between threads error means the type is !Send
Rc is !Send because its count is non-atomic; Arc is the thread-safe atomic alternative
