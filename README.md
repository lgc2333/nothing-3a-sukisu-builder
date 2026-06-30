# Nothing Phone (3a) NOS4 SukiSU Kernel Builder

English | [简体中文](README.zh-CN.md)

Lightweight GitHub Actions builder for a Nothing Phone (3a) NOS4 SukiSU kernel based on Nothing's official SM7635 kernel source.

This repo intentionally does not vendor the kernel source. The workflow pulls:

- Nothing kernel source: `NothingOSS/android_kernel_msm-6.1_nothing_sm7635`
- Default branch: `sm7635/b/mr`
- Target product: `Asteroids`
- Build target: `pitti gki`
- Base AOSP kernel manifest: `common-android14-6.1-2025-05`
- Root solution: `SukiSU-Ultra`

## Why This Repo Exists

Generic GKI images are convenient, but this builder takes the more device-aligned route: build from Nothing's official NOS4 kernel source and let the vendor/Kleaf build produce the matching boot and DLKM artifacts.

That should be a better starting point for Nothing Phone (3a) than flashing an unrelated generic GKI image, because the device build also involves vendor modules, DTB/DTBO, `vendor_boot`, and `vendor_dlkm` outputs.

The repo stays small so the Actions workflow can be iterated without maintaining a heavy kernel fork.

## Build

Run **Actions -> Build Nothing 3a NOS4 SukiSU Kernel -> Run workflow**.

Recommended first run:

- `kernel_repo`: `NothingOSS/android_kernel_msm-6.1_nothing_sm7635`
- `kernel_ref`: `sm7635/b/mr`
- `variant`: `gki`
- `sukisu_ref`: `main`
- `enable_kpm`: `false`
- `enable_susfs`: `false`

After a plain SukiSU build succeeds, enable KPM and SUSFS in separate runs so failures are easier to isolate.

## Output

The workflow uploads:

- `build-asteroids.log`
- `Image`, `Image.gz`, `Image.lz4`
- `boot.img`, `vendor_boot.img`, `vendor_dlkm.img`, `dtbo.img`, and related images if present
- `.config`, `Module.symvers`, `System.map`, and module metadata if present
- `out-file-list.txt` with the full output tree inventory

Treat artifacts as build outputs to inspect, not guaranteed flashable packages. Match them against the exact installed Nothing OS build before flashing anything.

## Notes For Maintainers

See [GOTCHAS.md](GOTCHAS.md) for concise build traps found while making this workflow work.
