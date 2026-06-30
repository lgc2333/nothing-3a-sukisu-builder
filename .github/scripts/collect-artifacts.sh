#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_WORKSPACE:?}"

mkdir -p "$GITHUB_WORKSPACE/artifacts"
cp "$GITHUB_WORKSPACE/build-asteroids.log" "$GITHUB_WORKSPACE/artifacts/" || true

if [ -d "$GITHUB_WORKSPACE/aosp/out" ]; then
  cd "$GITHUB_WORKSPACE/aosp/out"
  find . -type f | sort > "$GITHUB_WORKSPACE/artifacts/out-file-list.txt"
  while IFS= read -r file; do
    dest="$GITHUB_WORKSPACE/artifacts/${file#./}"
    mkdir -p "$(dirname "$dest")"
    cp "$file" "$dest"
  done < <(find . -type f \( \
    -name 'Image' -o \
    -name 'Image.gz' -o \
    -name 'Image.lz4' -o \
    -name 'boot.img' -o \
    -name 'dtbo.img' -o \
    -name 'init_boot.img' -o \
    -name 'system_dlkm.img' -o \
    -name 'vendor_boot.img' -o \
    -name 'vendor_dlkm.img' -o \
    -name 'vendor_kernel_boot.img' -o \
    -name '.config' -o \
    -name 'Module.symvers' -o \
    -name 'System.map' -o \
    -name 'modules.load' -o \
    -name 'modules.order' \
  \))
fi

find "$GITHUB_WORKSPACE/artifacts" -type f -printf '%p\n' | sort
