#!/usr/bin/env bash
set -euo pipefail
: "${LAB_WORKSPACE:?run this via: lab check rust L0.1}"
: "${LAB_CHECKLIB:?run this via: lab check rust L0.1}"
# shellcheck source=/dev/null
source "$LAB_CHECKLIB"

assert_file_contains "toolchain.txt" '^rustc [0-9]+\.[0-9]+'
assert_file_contains "toolchain.txt" '^cargo [0-9]+\.[0-9]+'
assert_file_exists "hello_lab/Cargo.toml"
assert_file_contains_fixed "hello_lab/Cargo.toml" 'name = "hello_lab"'
assert_file_exists "hello_lab/src/main.rs"
assert_file_contains_fixed "first_run.txt" 'Hello, world!'
assert_file_exists "hello_lab/target/debug/hello_lab"
assert_output_contains 'built binary runs and greets' 'Hello, world!' 'step 5 — cargo run must have produced target/debug/hello_lab' -- ./hello_lab/target/debug/hello_lab

ck_summary
