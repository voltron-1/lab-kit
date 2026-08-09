a capstone spec names outputs (7 ECS fields), the OK/FAILED->outcome mapping, and failure policy
the failure policy is the point: a malformed line is skipped and counted, never a panic
serialize JSON with a library — correct escaping is safety, not convenience
