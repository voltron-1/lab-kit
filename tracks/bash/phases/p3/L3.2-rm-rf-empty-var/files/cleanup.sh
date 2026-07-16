#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# cleanup.sh — wipe the build output dir before a fresh build.
BUILD_DIR="${BUILD_DIR-$(dirname "$0")/build}"   # if this ever arrives empty, the next line is fatal
rm -rf "$BUILD_DIR/"                              # empty BUILD_DIR => rm -rf "/"  ← the catastrophe
echo clean
