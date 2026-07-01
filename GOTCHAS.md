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

## Clean Baseline

- Run `28472590894` succeeded with `root_solution=none`, `variant=gki`.
- In clean mode, SukiSU and SUSFS steps must be skipped.
- Verified artifact names: `nothing-3a-nos4-none-gki-minimal` and `nothing-3a-nos4-none-gki-full`.
- Minimal artifact contains `boot.img`, `boot-gz.img`, `boot-lz4.img`, `Image*`, `System.map`, `Module.symvers`, logs, and inventory.
- `.config` in the downloaded minimal artifact had no `CONFIG_KSU`, `KSU_SUSFS`, `SUSFS`, or `KPM` matches.

## SukiSU Integration

- Run `28475657168` succeeded with `root_solution=sukisu`, `variant=gki`, `enable_kpm=false`.
- Root setup lives in `.github/scripts/integrate-root.sh`; keep clean, SukiSU, ReSukiSU, and SUSFS branches explicit.
- Run SukiSU setup inside `aosp/msm-kernel`, not `aosp/common`, unless testing the verified `sukisu_susfs` path.
- Append `CONFIG_KSU=y` to `msm-kernel/arch/arm64/configs/gki_defconfig`.
- Do not put KSU/SUSFS symbols in `vendor/Asteroids.config`; duplicated vendor fragment values fail `check_merged_defconfig`.
- KPM and SUSFS are separate layers. Do not mix them into clean baseline validation.
- `resukisu` is currently root-only. Do not route SUSFS through it until the adapter is checked against ReSukiSU's source layout.

## SUSFS Status

- Run `28481638077` succeeded with `root_solution=sukisu_susfs`, `variant=gki`, `enable_kpm=false`.
- Original community workflows append SUSFS symbols to `common/arch/arm64/configs/gki_defconfig` and disable `check_defconfig`.
- Without disabling that check, Kleaf `savedefconfig` removes unknown SUSFS symbols and fails the build.
- For this mixed Nothing build, patch/copy SUSFS into both `common` and `msm-kernel`; the build passes, but a narrower final patch surface may still be possible.
- Put KSU/SUSFS symbols in `gki_defconfig`, not `vendor/Asteroids.config`; duplicated vendor fragment values fail `check_merged_defconfig`.
- SukiSU-Ultra main does not define SUSFS Kconfig symbols by default; inject minimal symbol definitions rather than applying the full incompatible `10_enable_susfs_for_ksu.patch`.
- Do not require `susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch`; the referenced community workflows do not apply it for SukiSU-Ultra.
- Do not test optional text replacements with `new in text` when `new` is a substring of `old`; it skipped exporting `fake_state` from `static struct selinux_state fake_state;`.
- SUSFS expects `ksu_handle_sys_read(unsigned int fd)`. Current SukiSU has a static 3-argument helper, so keep it as an internal impl and export a one-argument wrapper.
- The successful SUSFS config has `CONFIG_KSU=y`, `CONFIG_KSU_SUSFS=y`, and `# CONFIG_KPM is not set`.

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

- Use `include-hidden-files: true` for upload-artifact; otherwise `.config` appears in `out-file-list.txt` but is missing from downloaded artifacts.
- Full `.ko` + `vmlinux` upload is huge, around 1.4 GB.
- Upload both minimal and full artifacts from one build; do not require a rebuild just to fetch full outputs.
- Minimal artifact should center on `boot.img` plus logs/config/symbols/inventory.
- Known successful plain SukiSU run produced `boot.img`, `vendor_boot.img`, `vendor_dlkm.img`, `dtb.img`, `dtbo.img`, `Image*`, and `System.map`.

## Flashing Caution

- These are build artifacts, not a validated flashable release.
- Match the exact installed Nothing OS build before flashing.
- `boot.img` alone may not be enough; vendor modules and `vendor_dlkm`/`vendor_boot` compatibility matter.
