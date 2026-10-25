# Security policy

## What is in scope

LAB-KIT is a local training kit. A report is useful if it shows that the **kit itself** lets a lab
do more than it says:

- the `lab` CLI or `lib/` writing or reading outside `workspace/` and `.progress.json`;
- a `check.sh` grader escaping its fence (see "Check execution (the fence)" in
  [`docs/kit-contracts.md`](docs/kit-contracts.md)), or running learner-supplied code;
- the in-session `files` / `show` / `edit` commands resolving a path outside the lab's workspace.

## What is not

- **The offense-adjacent samples are intentional lesson content**: obfuscated PowerShell, download
  cradles, the planted flaws in AI-generated scripts, the vulnerable crate in Rust L4.8. They use
  reserved domains and documentation IP ranges and are never executed by a grader
  ([`docs/CONTENT_REVIEW_CHECKLIST.md`](docs/CONTENT_REVIEW_CHECKLIST.md)). A report that a sample
  is malicious-looking is not a vulnerability; a report that a sample contacts a real host or runs
  for real is.
- **`!<command>` in `lab session`** runs whatever you type, unconfined, by design
  ([`docs/kit-contracts.md`](docs/kit-contracts.md)).
- There is no OS sandbox. That limit is documented; the compensating control is `tools/lint-labs.sh`.

## How to report

Use GitHub's private reporting: **Security → Report a vulnerability** on this repository. If that
button is not available, open an issue titled "Security: please contact me" **without** exploit
details and the maintainer will arrange a private channel.

Please include the lab id or file, what you ran, and what you expected versus what happened.
