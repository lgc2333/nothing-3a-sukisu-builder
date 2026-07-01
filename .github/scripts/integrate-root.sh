#!/usr/bin/env bash
set -euo pipefail

: "${ROOT_SOLUTION:?}"
: "${SUKISU_REF:?}"
: "${RESUKISU_REF:?}"
: "${ENABLE_KPM:?}"
: "${ENABLE_SUSFS:=false}"

append_ksu_config() {
  local config="$1"
  local label="$2"

  {
    echo "# $label"
    echo "CONFIG_KSU=y"
    if [ "$ENABLE_KPM" = "true" ]; then
      echo "CONFIG_KPM=y"
    fi
  } >> "$config"
}

install_sukisu() {
  local tree="$1"
  local setup_arg="$2"

  (
    cd "$tree"
    curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/${SUKISU_REF}/kernel/setup.sh" |
      bash -s "$setup_arg"
  )
}

install_resukisu() {
  local tree="$1"

  if [ "$ENABLE_KPM" = "true" ]; then
    echo "ReSukiSU KPM support is not validated in this workflow; set enable_kpm=false." >&2
    exit 2
  fi

  (
    cd "$tree"
    curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/${RESUKISU_REF}/kernel/setup.sh" |
      bash -s "$RESUKISU_REF"
    ksu_src="$(pwd)/KernelSU/kernel"
    sed -i "s|^KSU_SRC := .*|KSU_SRC := ${ksu_src}|" "$ksu_src/Kbuild"
  )
}

case "$ROOT_SOLUTION" in
  sukisu|sukisu_susfs)
    install_sukisu aosp/msm-kernel "$SUKISU_REF"

    if [ "$ENABLE_SUSFS" = "true" ]; then
      install_sukisu aosp/common builtin
      append_ksu_config aosp/common/arch/arm64/configs/gki_defconfig "SukiSU Ultra"
    fi

    append_ksu_config aosp/msm-kernel/arch/arm64/configs/gki_defconfig "SukiSU Ultra"
    ;;
  resukisu)
    if [ "$ENABLE_SUSFS" = "true" ]; then
      echo "ReSukiSU + SUSFS is not wired yet; use root_solution=sukisu_susfs for the verified SUSFS path." >&2
      exit 2
    fi

    install_resukisu aosp/msm-kernel
    append_ksu_config aosp/msm-kernel/arch/arm64/configs/gki_defconfig "ReSukiSU"
    ;;
  *)
    echo "Unsupported root_solution: $ROOT_SOLUTION" >&2
    exit 2
    ;;
esac
