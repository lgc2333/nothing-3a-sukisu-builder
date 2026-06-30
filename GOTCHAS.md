# GOTCHAS

Concise notes for future maintainers / AI agents.

## Target Facts

- Nothing Phone (3a) NOS4 branch: `sm7635/b/mr`.
- Target product: `Asteroids`.
- Qualcomm target used by the Nothing tree: `pitti`.
- Working variant: `gki`.
- `consolidate` is not a good default here; the selected AOSP manifest lacks `//common:kernel_aarch64_consolidate`.

## Workspace Setup

- Workflow orchestration lives in `.github/workflows/`; long logic lives in `.github/scripts/`.
- Keep shell scripts small and pass workflow inputs through env vars.
- Use AOSP kernel manifest `common-android14-6.1-2025-05`.
- Its default revision must be rewritten to `deprecated/android14-6.1-2025-05`.
- Create `build/BUILD.bazel`; Nothing's Bazel files expect `//build`.
- Add `@nt_project_info` local repo with `TARGET_PRODUCT = "Asteroids"`.
- Add `@dtc` as `new_local_repository(path = "external/dtc", build_file = "msm-kernel/BUILD.dtc")`.
- Clone `platform/external/dtc`; do not assume it exists in the kernel manifest checkout.

## Kleaf / Dist Patches

- This AOSP branch lacks exported `super_image` / `unsparsed_image`; patch `build/kernel/kleaf/kernel.bzl` and fetch `super_image.bzl`.
- Fetch googlesource `?format=TEXT` with `curl --fail --retry`, then `base64 --decode`; otherwise transient HTML/error pages become `base64: invalid input`.
- Remove `:{}_super_image` and `:{}_unsparsed_image` from `msm_kernel_la.bzl` dist targets for this kernel-only workspace.
- Build with `-s abl -s dtc`; ABL is unavailable and Qualcomm's dtc dist target is not needed here.

## SukiSU Integration

- Run SukiSU setup inside `aosp/msm-kernel`, not `aosp/common`.
- Append `CONFIG_KSU=y` to both:
  - `msm-kernel/arch/arm64/configs/gki_defconfig`
  - `msm-kernel/arch/arm64/configs/vendor/Asteroids.config`
- KPM and SUSFS are intentionally off by default. Enable them in separate runs.

## SUSFS Status

- Original community workflows append SUSFS symbols to `common/arch/arm64/configs/gki_defconfig` and disable `check_defconfig`.
- Without disabling that check, Kleaf `savedefconfig` removes unknown SUSFS symbols and fails the build.
- For this mixed Nothing build, patch/copy SUSFS into both `common` and `msm-kernel` while testing; the exact minimal tree is still being verified.
- Do not require `susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch`; the referenced community workflows do not apply it for SukiSU-Ultra.

## Nothing / Asteroids Module Fixes

- `ufs_qcom.ko` and `qcom_glink.ko` reference `nt_er_in_schedule`.
- Provider is `drivers/nothing_stability/nothing_error_report.ko`.
- `Asteroids.config` does not enable `CONFIG_NOTHING_ERROR_REPORT` by default; add `CONFIG_NOTHING_ERROR_REPORT=m`.
- Bazel also needs Asteroids modules declared in `pitti.bzl` and `modules.list.msm.pitti`, including:
  - `drivers/leds/aw20036/led_aw20036.ko`
  - `drivers/misc/cable_detect.ko`
  - `drivers/misc/hwid.ko`
  - `drivers/misc/ois_vdd_ctrl.ko`
  - `drivers/misc/rpmb_state.ko`
  - `drivers/misc/secure_state.ko`
  - `drivers/misc/slot_detect.ko`
  - `drivers/misc/st54spi.ko`
  - `drivers/nothing_stability/nothing_error_report.ko`

## Artifacts

- Full `.ko` + `vmlinux` upload is huge, around 1.4 GB.
- Upload both minimal and full artifacts from one build; do not require a rebuild just to fetch full outputs.
- Minimal artifact should center on `boot.img` plus logs/config/symbols/inventory.
- Known successful plain SukiSU run produced `boot.img`, `vendor_boot.img`, `vendor_dlkm.img`, `dtb.img`, `dtbo.img`, `Image*`, and `System.map`.

## Flashing Caution

- These are build artifacts, not a validated flashable release.
- Match the exact installed Nothing OS build before flashing.
- `boot.img` alone may not be enough; vendor modules and `vendor_dlkm`/`vendor_boot` compatibility matter.
