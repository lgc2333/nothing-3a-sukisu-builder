# Nothing Phone (3a) NOS4 SukiSU Kernel Builder

Lightweight GitHub Actions builder for the Nothing Phone (3a) NOS4 kernel.

This repository intentionally does not vendor the kernel source. The workflow pulls:

- Nothing kernel source: `NothingOSS/android_kernel_msm-6.1_nothing_sm7635`
- Default branch: `sm7635/b/mr`
- Target product: `Asteroids`
- Base AOSP kernel manifest: `common-android14-6.1-2025-05`
- Root solution: `SukiSU-Ultra`

## Why This Repo Exists

The Nothing kernel tree contains filenames that are awkward to checkout on Windows, and the real build needs the Android kernel workspace/toolchain anyway. Keeping this repo small makes it easier to iterate on the Actions workflow without maintaining a heavy kernel fork.

The workflow borrows the general shape from ShirkNeko's builders:

- free runner disk space
- sync a kernel workspace in Actions
- patch KernelSU/SukiSU into the tree
- collect build logs and artifacts

It is not a direct fork of the OnePlus builder because the OnePlus manifest, scripts, CPU names, and output paths do not match Nothing's SM7635 source layout.

## Build

Run **Actions -> Build Nothing 3a NOS4 SukiSU Kernel -> Run workflow**.

Conservative first run:

- `kernel_repo`: `NothingOSS/android_kernel_msm-6.1_nothing_sm7635`
- `kernel_ref`: `sm7635/b/mr`
- `variant`: `gki`
- `sukisu_ref`: `main`
- `enable_kpm`: `false`
- `enable_susfs`: `false`

After a plain SukiSU build succeeds, enable KPM and SUSFS in separate runs so failures are easier to isolate.

## Output

The workflow uploads:

- build log
- `Image`/compressed images if present
- generated boot / vendor dlkm / dtbo images if present
- `.config`, `Module.symvers`, `System.map`, and module load/order metadata if present
- `out-file-list.txt` with the full output tree inventory

Treat the first successful artifact as a build output to inspect, not as a guaranteed flashable package. Device-specific packaging and boot/vendor_boot replacement still need to be validated against the exact installed Nothing OS build.
