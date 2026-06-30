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

for tree in common msm-kernel; do
  cp "$kernel_patch" "$tree/"
  cp susfs4ksu/kernel_patches/fs/* "$tree/fs/"
  cp susfs4ksu/kernel_patches/include/linux/* "$tree/include/linux/"

  (
    cd "$tree"
    patch -p1 -F 3 < "50_add_susfs_in_${SUSFS_BRANCH}.patch"
  )
done

for ksu_dir in common/KernelSU/kernel msm-kernel/KernelSU/kernel; do
  kconfig="$ksu_dir/Kconfig"
  makefile="$ksu_dir/Makefile"
  if ! grep -q "config KSU_SUSFS" "$kconfig"; then
    sed -i '/^endmenu/i\
menu "KernelSU - SUSFS"\
\
config KSU_SUSFS\
\tbool "KernelSU addon - SUSFS"\
\tdepends on KSU\
\tdepends on THREAD_INFO_IN_TASK\
\tdefault y\
\
config KSU_SUSFS_SUS_PATH\
\tbool "Enable to hide suspicious path"\
\tdepends on KSU_SUSFS\
\tdefault y\
\
config KSU_SUSFS_SUS_MOUNT\
\tbool "Enable to hide suspicious mounts"\
\tdepends on KSU_SUSFS\
\tdefault y\
\
config KSU_SUSFS_SUS_KSTAT\
\tbool "Enable to spoof suspicious kstat"\
\tdepends on KSU_SUSFS\
\tdefault y\
\
config KSU_SUSFS_SPOOF_UNAME\
\tbool "Enable to spoof uname"\
\tdepends on KSU_SUSFS\
\tdefault y\
\
config KSU_SUSFS_ENABLE_LOG\
\tbool "Enable logging susfs log to kernel"\
\tdepends on KSU_SUSFS\
\tdefault y\
\
config KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS\
\tbool "Enable to hide ksu and susfs symbols from /proc/kallsyms"\
\tdepends on KSU_SUSFS\
\tdefault y\
\
config KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG\
\tbool "Enable to spoof /proc/bootconfig or /proc/cmdline"\
\tdepends on KSU_SUSFS\
\tdefault y\
\
config KSU_SUSFS_OPEN_REDIRECT\
\tbool "Enable to redirect opened paths"\
\tdepends on KSU_SUSFS\
\tdefault y\
\
config KSU_SUSFS_SUS_MAP\
\tbool "Enable to hide mmapped files from proc maps"\
\tdepends on KSU_SUSFS\
\tdefault y\
\
config KSU_SUSFS_HAS_MAGIC_MOUNT\
\tbool "Enable SUSFS magic mount support marker"\
\tdepends on KSU_SUSFS\
\tdefault y\
\
config KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT\
\tbool "Auto add KernelSU default mounts to SUSFS"\
\tdepends on KSU_SUSFS\
\tdefault y\
\
config KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT\
\tbool "Auto add bind mounts to SUSFS"\
\tdepends on KSU_SUSFS\
\tdefault y\
\
config KSU_SUSFS_TRY_UMOUNT\
\tbool "Enable SUSFS try umount"\
\tdepends on KSU_SUSFS\
\tdefault y\
\
config KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT\
\tbool "Auto add try umount for bind mounts"\
\tdepends on KSU_SUSFS_TRY_UMOUNT\
\tdefault y\
\
endmenu\
' "$kconfig"
  fi

  if ! grep -q "SUSFS_VERSION" "$makefile"; then
    cat >> "$makefile" <<'EOF'

ifeq ($(shell test -e $(srctree)/fs/susfs.c; echo $$?),0)
$(eval SUSFS_VERSION=$(shell grep -E '^#define SUSFS_VERSION' $(srctree)/include/linux/susfs.h | cut -d' ' -f3 | sed 's/"//g'))
$(info -- SUSFS_VERSION: $(SUSFS_VERSION))
endif
EOF
  fi
done

if [ -f common/build.config.gki ]; then
  sed -i 's/check_defconfig//g' common/build.config.gki
fi

for config in \
  common/arch/arm64/configs/gki_defconfig \
  msm-kernel/arch/arm64/configs/gki_defconfig
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
    echo "CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y"
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y"
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y"
    echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y"
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y"
  } >> "$config"
done
