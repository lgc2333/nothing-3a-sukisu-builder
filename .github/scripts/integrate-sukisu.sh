#!/usr/bin/env bash
set -euo pipefail

: "${SUKISU_REF:?}"
: "${ENABLE_KPM:?}"
: "${ENABLE_SUSFS:=false}"

cd aosp/msm-kernel
curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/${SUKISU_REF}/kernel/setup.sh" | bash -s "$SUKISU_REF"
cd ..

if [ "$ENABLE_SUSFS" = "true" ]; then
  cd common
  curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/${SUKISU_REF}/kernel/setup.sh" | bash -s builtin
  {
    echo "# SukiSU Ultra"
    echo "CONFIG_KSU=y"
    if [ "$ENABLE_KPM" = "true" ]; then
      echo "CONFIG_KPM=y"
    fi
  } >> arch/arm64/configs/gki_defconfig
  cd ..
fi

{
  echo "# SukiSU Ultra"
  echo "CONFIG_KSU=y"
  if [ "$ENABLE_KPM" = "true" ]; then
    echo "CONFIG_KPM=y"
  fi
} >> msm-kernel/arch/arm64/configs/gki_defconfig
