#!/usr/bin/env bash
set -euo pipefail

: "${VARIANT:?}"
: "${GITHUB_WORKSPACE:?}"

cd aosp
export CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"
./msm-kernel/build_with_bazel.py \
  -s abl \
  -s dtc \
  -t pitti "$VARIANT" \
  2>&1 | tee "$GITHUB_WORKSPACE/build-asteroids.log"
