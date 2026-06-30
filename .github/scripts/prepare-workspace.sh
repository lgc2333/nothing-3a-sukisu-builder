#!/usr/bin/env bash
set -euo pipefail

: "${KERNEL_REPO:?}"
: "${KERNEL_REF:?}"
: "${AOSP_MANIFEST_BRANCH:?}"
: "${DTC_REF:?}"

mkdir -p aosp
cd aosp

repo init --depth=1 \
  -u https://android.googlesource.com/kernel/manifest \
  -b "$AOSP_MANIFEST_BRANCH" \
  --repo-rev=v2.54

python3 ../.github/scripts/patch-aosp-workspace.py "$AOSP_MANIFEST_BRANCH"

repo sync -c -j4 --no-tags --fail-fast
touch build/BUILD.bazel

if ! grep -q "super_image = " build/kernel/kleaf/kernel.bzl; then
  curl --fail --location --show-error --silent --retry 5 --retry-delay 5 \
    "https://android.googlesource.com/kernel/build/+/a32179752cfe632775839e1592c9d7f945d54fe1/kleaf/impl/image/super_image.bzl?format=TEXT" \
    -o super_image.bzl.base64
  base64 --decode super_image.bzl.base64 > build/kernel/kleaf/impl/image/super_image.bzl
  test -s build/kernel/kleaf/impl/image/super_image.bzl
fi

python3 ../.github/scripts/patch-aosp-workspace.py "$AOSP_MANIFEST_BRANCH" --post-sync

cat >> WORKSPACE <<'EOF'

local_repository(
    name = "nt_project_info",
    path = "nt_project_info",
)

new_local_repository(
    name = "dtc",
    path = "external/dtc",
    build_file = "msm-kernel/BUILD.dtc",
)
EOF
mkdir -p nt_project_info
touch nt_project_info/WORKSPACE
touch nt_project_info/BUILD.bazel
cat > nt_project_info/dict.bzl <<'EOF'
TARGET_PRODUCT = "Asteroids"
EOF

git clone --depth=1 --branch "$KERNEL_REF" "https://github.com/${KERNEL_REPO}.git" msm-kernel
git clone --depth=1 --branch "$DTC_REF" https://android.googlesource.com/platform/external/dtc external/dtc

python3 ../.github/scripts/patch-nothing-tree.py

git -C msm-kernel log -1 --oneline
grep -n "Asteroids" msm-kernel/README.md || true
