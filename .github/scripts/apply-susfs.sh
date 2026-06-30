#!/usr/bin/env bash
set -euo pipefail

: "${SUSFS_BRANCH:?}"

cd aosp
for attempt in 1 2 3 4 5; do
  if git clone --depth=1 --branch "$SUSFS_BRANCH" https://gitlab.com/simonpunk/susfs4ksu.git susfs4ksu; then
    break
  fi
  rm -rf susfs4ksu
  if [ "$attempt" = 5 ]; then
    exit 1
  fi
  sleep $((attempt * 10))
done

kernel_patch="susfs4ksu/kernel_patches/50_add_susfs_in_${SUSFS_BRANCH}.patch"
ksu_patch="susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch"

for tree in common msm-kernel; do
  cp "$kernel_patch" "$tree/"
  cp susfs4ksu/kernel_patches/fs/* "$tree/fs/"
  cp susfs4ksu/kernel_patches/include/linux/* "$tree/include/linux/"

  (
    cd "$tree"
    patch -p1 -F 3 < "50_add_susfs_in_${SUSFS_BRANCH}.patch"
  )
done

(
  cd msm-kernel/KernelSU
  if ! patch -p1 -F 3 --dry-run < "../../$ksu_patch"; then
    echo "::error::SUSFS KernelSU patch does not apply to the selected SukiSU-Ultra ref."
    echo "::error::Pin a compatible SukiSU ref or add a SukiSU-specific SUSFS adapter before enabling SUSFS."
    exit 1
  fi
  patch -p1 -F 3 < "../../$ksu_patch"
)

for config in \
  msm-kernel/arch/arm64/configs/gki_defconfig \
  msm-kernel/arch/arm64/configs/vendor/Asteroids.config
do
  {
    echo "# SUSFS"
    echo "CONFIG_KSU_SUSFS=y"
    echo "CONFIG_KSU_SUSFS_SUS_PATH=y"
    echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y"
    echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y"
    echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y"
    echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y"
    echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y"
    echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y"
    echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y"
    echo "CONFIG_KSU_SUSFS_SUS_MAP=y"
  } >> "$config"
done
