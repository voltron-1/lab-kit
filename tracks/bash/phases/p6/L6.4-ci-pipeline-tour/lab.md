## BRIEF
In this lab, you tour a CI pipeline script (`files/run-checks.sh`).
Production CI pipelines keep YAML definitions thin, delegating execution logic to shell scripts. This design guarantees local vs CI parity, allows scripts to be shellchecked, and ensures consistent error handling.
Nothing in this kit executes the script — it expects repository subdirectories that do not exist here. Your job is to audit the script, trace pipeline stage dispatch, and answer the comprehension questions.

## GUIDED STEPS

1. **Read the header and design philosophy (lines 1–15)**:
   - Notice the `# TOUR ARTIFACT...` header banner.
   - The script explains why YAML is kept thin: keeping logic in shell scripts maintains parity between local developer runs (`./ci/run-checks.sh all`) and CI runner executions.

2. **Examine runner context and fail-fast guarantees (lines 16–35)**:
   - `set -euo pipefail` (Phase 2 callback) ensures any failing step in any stage aborts the job immediately, preventing broken artifacts from shipping under a false "green" build.
   - `COMMIT_SHA="${CI_COMMIT_SHA:-$(git rev-parse HEAD)}"` reads CI runner environment variables with a local `git` fallback.

3. **Audit stage definitions (lines 36–60)**:
   - `stage_lint`: runs `shellcheck` and `shfmt` across repo scripts (lint as a merge gate).
   - `stage_test`: creates `$ARTIFACT_DIR` and executes unit tests.
   - `stage_build`: creates a reproducible tarball using `--sort=name --owner=0 --group=0 --mtime='@0'` to ensure identical commits yield byte-identical archives. It generates a `.sha256` checksum file alongside the archive.

4. **Examine secret exposure risks**:
   - Every command and sub-script executed by the pipeline inherits the runner's full environment, including any CI secret tokens exported in environment variables.

5. **Verify ShellCheck status**:
   ```bash
   shellcheck -x -S style files/run-checks.sh
   ```
   *(Expected output: clean, 0 findings)*

6. **Write `answers.txt`** using the exact allowed vocabulary:
   - `thinyaml=parity`
   - `failstop=pipefail`
   - `fallback=git`
   - `tarflags=reproducible`
   - `integrity=sha256`
   - `exposure=env`

7. **Check your work**:
   ```bash
   lab check bash L6.4
   ```
