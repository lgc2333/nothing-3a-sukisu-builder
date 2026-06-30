#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_WORKSPACE:?}"

minimal_dir="$GITHUB_WORKSPACE/artifacts-minimal"
full_dir="$GITHUB_WORKSPACE/artifacts-full"
mkdir -p "$minimal_dir" "$full_dir"
cp "$GITHUB_WORKSPACE/build-asteroids.log" "$minimal_dir/" || true
cp "$GITHUB_WORKSPACE/build-asteroids.log" "$full_dir/" || true

if [ -d "$GITHUB_WORKSPACE/aosp/out" ]; then
  cd "$GITHUB_WORKSPACE/aosp/out"
  find . -type f | sort > "$minimal_dir/out-file-list.txt"
  cp "$minimal_dir/out-file-list.txt" "$full_dir/out-file-list.txt"

  while IFS= read -r file; do
    for base_dir in "$minimal_dir" "$full_dir"; do
      dest="$base_dir/${file#./}"
      mkdir -p "$(dirname "$dest")"
      cp "$file" "$dest"
    done
  done < <(find . -type f \( \
    -name 'Image' -o \
    -name 'Image.gz' -o \
    -name 'Image.lz4' -o \
    -name 'boot.img' -o \
    -name 'boot-gz.img' -o \
    -name 'boot-lz4.img' -o \
    -name '.config' -o \
    -name 'Module.symvers' -o \
    -name 'System.map' -o \
    -name 'modules.load' -o \
    -name 'modules.order' \
  \))

  while IFS= read -r file; do
    dest="$full_dir/${file#./}"
    mkdir -p "$(dirname "$dest")"
    cp "$file" "$dest"
  done < <(find . -type f \( \
    -name 'dtbo.img' -o \
    -name 'dtb.img' -o \
    -name 'init_boot.img' -o \
    -name 'system_dlkm.img' -o \
    -name 'system_dlkm.erofs.img' -o \
    -name 'vendor_boot.img' -o \
    -name 'vendor_dlkm.img' -o \
    -name 'vendor_kernel_boot.img' \
  \))
fi

echo "Minimal artifacts:"
find "$minimal_dir" -type f -printf '%p\n' | sort
echo "Full artifacts:"
find "$full_dir" -type f -printf '%p\n' | sort
