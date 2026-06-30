#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path


def patch_dist_targets() -> None:
    msm_kernel_la = Path("msm-kernel/msm_kernel_la.bzl")
    text = msm_kernel_la.read_text()
    text = text.replace('        ":{}_super_image".format(target),\n', "")
    text = text.replace('        ":{}_unsparsed_image".format(target),\n', "")
    msm_kernel_la.write_text(text)


def patch_pitti_modules() -> None:
    pitti_bzl = Path("msm-kernel/pitti.bzl")
    text = pitti_bzl.read_text()
    marker = '        "drivers/misc/qseecom_proxy.ko",\n'
    asteroids_modules = [
        '        "drivers/leds/aw20036/led_aw20036.ko",\n',
        '        "drivers/misc/cable_detect.ko",\n',
        '        "drivers/misc/hwid.ko",\n',
        '        "drivers/misc/ois_vdd_ctrl.ko",\n',
        '        "drivers/misc/rpmb_state.ko",\n',
        '        "drivers/misc/secure_state.ko",\n',
        '        "drivers/misc/slot_detect.ko",\n',
        '        "drivers/misc/st54spi.ko",\n',
        '        "drivers/nothing_stability/nothing_error_report.ko",\n',
    ]
    if marker not in text:
        raise SystemExit("pitti.bzl insertion marker not found")
    insertion = "".join(module for module in asteroids_modules if module not in text)
    if insertion:
        text = text.replace(marker, marker + insertion)
    pitti_bzl.write_text(text)

    modules_list = Path("msm-kernel/modules.list.msm.pitti")
    text = modules_list.read_text()
    asteroids_module_names = [
        "led_aw20036.ko\n",
        "cable_detect.ko\n",
        "hwid.ko\n",
        "ois_vdd_ctrl.ko\n",
        "rpmb_state.ko\n",
        "secure_state.ko\n",
        "slot_detect.ko\n",
        "st54spi.ko\n",
        "nothing_error_report.ko\n",
    ]
    insertion = "".join(module for module in asteroids_module_names if module not in text)
    if insertion:
        text = text.replace("ufs_qcom.ko\n", "ufs_qcom.ko\n" + insertion)
    modules_list.write_text(text)


def patch_asteroids_config() -> None:
    asteroids_config = Path("msm-kernel/arch/arm64/configs/vendor/Asteroids.config")
    text = asteroids_config.read_text()
    if "CONFIG_NOTHING_ERROR_REPORT=" not in text:
        text += "\n# Required by ufs_qcom.ko and qcom_glink.ko Nothing error hooks\nCONFIG_NOTHING_ERROR_REPORT=m\n"
    asteroids_config.write_text(text)


def main() -> None:
    patch_dist_targets()
    patch_pitti_modules()
    patch_asteroids_config()


if __name__ == "__main__":
    main()
