False-positive mines are noisy rules and authorized admin behavior — verdict them fp or btp, never escalate them.
The value you add is specific tuning feedback: exclude host X on pattern Y, allowlist user Z under change window — precise enough to suppress the noise without blinding the rule.
That feedback is the analyst-to-detection-engineering loop; a brittle filename-substring rule is exactly what your note fixes.
