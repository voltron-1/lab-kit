#!/bin/bash
# TOUR ARTIFACT — production-shaped reference, entirely fictional.
# Read it; nothing in this kit executes it.
#
# ci/run-checks.sh — everything the CI runner executes for a merge request.
#
# The pipeline definition (the YAML) is thin on purpose: each job calls this
# script with a stage name, so the exact same commands run on a laptop
# (./ci/run-checks.sh all) and in CI. No logic hides in YAML.
#
# Usage: ci/run-checks.sh {lint|test|build|all}

set -euo pipefail

# Runner-provided context, with local-run fallbacks. CI exports these; on a
# laptop we derive them from git so the script behaves identically.
COMMIT_SHA="${CI_COMMIT_SHA:-$(git rev-parse HEAD)}"
ARTIFACT_DIR="${CI_ARTIFACT_DIR:-build/artifacts}"

banner() {
    printf '\n=== %s (%s) ===\n' "$1" "${COMMIT_SHA:0:12}"
}

stage_lint() {
    banner "lint"
    shellcheck -S style scripts/*.sh
    shfmt -d scripts/
}

stage_test() {
    banner "test"
    mkdir -p "$ARTIFACT_DIR"
    ./tests/run-unit-tests.sh --junit "$ARTIFACT_DIR/junit.xml"
}

stage_build() {
    banner "build"
    mkdir -p "$ARTIFACT_DIR"
    # Reproducible tarball: pinned ordering, ownership, and timestamps mean
    # the same commit always produces byte-identical artifacts.
    tar --sort=name --owner=0 --group=0 --mtime='@0' \
        -czf "$ARTIFACT_DIR/relay-$COMMIT_SHA.tar.gz" \
        scripts/ config/
    sha256sum "$ARTIFACT_DIR/relay-$COMMIT_SHA.tar.gz" \
        > "$ARTIFACT_DIR/relay-$COMMIT_SHA.tar.gz.sha256"
}

main() {
    local stage="${1:-}"
    case "$stage" in
        lint)  stage_lint ;;
        test)  stage_test ;;
        build) stage_build ;;
        all)   stage_lint; stage_test; stage_build ;;
        *)
            echo "usage: $0 {lint|test|build|all}" >&2
            exit 2
            ;;
    esac
}

main "$@"
