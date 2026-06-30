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

cp "susfs4ksu/kernel_patches/50_add_susfs_in_${SUSFS_BRANCH}.patch" common/
cp susfs4ksu/kernel_patches/fs/* common/fs/
cp susfs4ksu/kernel_patches/include/linux/* common/include/linux/

cd common
patch -p1 -F 3 < "50_add_susfs_in_${SUSFS_BRANCH}.patch"

for config in \
  arch/arm64/configs/gki_defconfig \
  ../msm-kernel/arch/arm64/configs/vendor/Asteroids.config
do
  {
    echo "# SUSFS"
    echo "CONFIG_KSU_SUSFS=y"
    echo "CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y"
    echo "CONFIG_KSU_SUSFS_SUS_PATH=y"
    echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y"
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y"
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y"
    echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y"
    echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y"
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y"
    echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y"
    echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y"
    echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y"
    echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y"
    echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y"
  } >> "$config"
done
