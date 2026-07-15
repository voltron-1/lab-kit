#!/usr/bin/env bash
# guard.sh — refuse to continue if the deploy dir is missing.
cd deploy_dir || exit 1
echo "deploying from $(basename "$(pwd)")"
