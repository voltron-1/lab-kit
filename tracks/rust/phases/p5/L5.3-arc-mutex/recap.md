Arc<Mutex<T>> combines shared ownership (Arc) with synchronized access (Mutex)
lock() returns a MutexGuard that automatically unlocks when dropped via RAII
lock() returns an Err only if a thread panicked while holding the lock (poisoned)
