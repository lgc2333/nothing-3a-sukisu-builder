# Nothing Phone (3a) NOS4 Kernel Builder

English | [简体中文](README.zh-CN.md)

Lightweight GitHub Actions builder for a Nothing Phone (3a) NOS4 kernel based on Nothing's official SM7635 kernel source.

This repo intentionally does not vendor the kernel source. The workflow pulls:

- Nothing kernel source: `NothingOSS/android_kernel_msm-6.1_nothing_sm7635`
- Default branch: `sm7635/b/mr`
- Target product: `Asteroids`
- Build target: `pitti gki`
- Base AOSP kernel manifest: `common-android14-6.1-2025-05`
- Root modes: `none`, `sukisu`, `sukisu_susfs`, `resukisu`

## Why This Repo Exists

Generic GKI images are convenient, but this builder takes the more device-aligned route: build from Nothing's official NOS4 kernel source and let the vendor/Kleaf build produce the matching boot and DLKM artifacts.

That should be a better starting point for Nothing Phone (3a) than flashing an unrelated generic GKI image, because the device build also involves vendor modules, DTB/DTBO, `vendor_boot`, and `vendor_dlkm` outputs.

The repo stays small so the Actions workflow can be iterated without maintaining a heavy kernel fork.

## Build

Run **Actions -> Build Nothing 3a NOS4 Kernel -> Run workflow**.

Recommended first run:

- `kernel_repo`: `NothingOSS/android_kernel_msm-6.1_nothing_sm7635`
- `kernel_ref`: `sm7635/b/mr`
- `variant`: `gki`
- `root_solution`: `none`
- `enable_kpm`: `false`

First prove the clean Nothing kernel builds without SukiSU, ResukiSU, SUSFS, or any root hooks. Only after that baseline succeeds should root integrations be tested in separate runs.

Root integration is intentionally layered:

- `sukisu`: verified SukiSU-only root layer.
- `sukisu_susfs`: verified SukiSU + SUSFS layer.
- `resukisu`: experimental ReSukiSU-only layer; SUSFS is not wired to ReSukiSU yet. This mode rewrites ReSukiSU `KSU_SRC` for Bazel/Kleaf sandbox builds.

Known clean baseline:

- Run: `28472590894`
- Mode: `root_solution=none`, `variant=gki`
- Result: success
- Evidence: SukiSU and SUSFS steps were skipped; `build-asteroids.log` ended with `Build completed successfully`; the minimal artifact contains `boot.img`, `boot-gz.img`, `boot-lz4.img`, `Image*`, `System.map`, `Module.symvers`, and logs.

Known SukiSU-only baseline:

- Run: `28475657168`
- Mode: `root_solution=sukisu`, `variant=gki`, `enable_kpm=false`
- Result: success
- Evidence: SukiSU integration completed, SUSFS was skipped, `build-asteroids.log` ended with `Build completed successfully`, and the minimal artifact contains the same boot/image output set.

Known SukiSU + SUSFS baseline:

- Run: `28481638077`
- Mode: `root_solution=sukisu_susfs`, `variant=gki`, `enable_kpm=false`
- Result: success
- Evidence: SukiSU integration and SUSFS patching completed, `build-asteroids.log` reported `SUSFS_VERSION: v2.2.0` and ended with `Build completed successfully`, and the downloaded minimal artifact includes `.config` plus `boot.img`.
- Config evidence: `CONFIG_KSU=y`, `CONFIG_KSU_SUSFS=y`, and `# CONFIG_KPM is not set`.

## Output

The workflow uploads two artifacts:

- `*-minimal`: daily-use inspection/flashing set, centered on `boot.img`, `boot-gz.img`, `boot-lz4.img`, `Image*`, logs, config, symbols, and output inventory.
- `*-full`: the minimal set plus device image outputs such as `vendor_boot.img`, `vendor_dlkm.img`, `dtb.img`, `dtbo.img`, and `system_dlkm.img` if present.

Treat artifacts as build outputs to inspect, not guaranteed flashable packages. Match them against the exact installed Nothing OS build before flashing anything.

## Notes For Maintainers

See [GOTCHAS.md](GOTCHAS.md) for concise build traps found while making this workflow work.
