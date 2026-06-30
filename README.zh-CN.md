# Nothing Phone (3a) NOS4 SukiSU 内核构建器

[English](README.md) | 简体中文

这是一个轻量 GitHub Actions 构建仓库，用于基于 Nothing 官方 SM7635 内核源码构建 Nothing Phone (3a) NOS4 的 SukiSU 内核。

本仓库不内置内核源码。workflow 会拉取：

- Nothing 内核源码：`NothingOSS/android_kernel_msm-6.1_nothing_sm7635`
- 默认分支：`sm7635/b/mr`
- 目标产品：`Asteroids`
- 构建目标：`pitti gki`
- AOSP kernel manifest：`common-android14-6.1-2025-05`
- Root 方案：`SukiSU-Ultra`

## 为什么有这个仓库

通用 GKI 镜像很方便，但这个仓库选择更贴合设备的路线：从 Nothing 官方 NOS4 内核源码构建，并让厂商/Kleaf 构建流程产出匹配的 boot 与 DLKM 相关文件。

对 Nothing Phone (3a) 来说，这通常比直接刷不相关的通用 GKI 镜像更适合作为起点，因为设备内核不只是一份通用 `Image`，还牵涉 vendor modules、DTB/DTBO、`vendor_boot`、`vendor_dlkm` 等产物。

仓库保持轻量，方便迭代 Actions workflow，而不是维护一个笨重的内核 fork。

## 构建

打开 **Actions -> Build Nothing 3a NOS4 SukiSU Kernel -> Run workflow**。

建议第一次运行：

- `kernel_repo`: `NothingOSS/android_kernel_msm-6.1_nothing_sm7635`
- `kernel_ref`: `sm7635/b/mr`
- `variant`: `gki`
- `sukisu_ref`: `main`
- `enable_kpm`: `false`
- `enable_susfs`: `false`

普通 SukiSU 构建成功后，再分别启用 KPM 和 SUSFS，方便定位失败原因。

## 输出

workflow 会上传：

- `build-asteroids.log`
- `Image`、`Image.gz`、`Image.lz4`
- 如存在：`boot.img`、`vendor_boot.img`、`vendor_dlkm.img`、`dtbo.img` 等镜像
- 如存在：`.config`、`Module.symvers`、`System.map` 和模块元数据
- `out-file-list.txt`，记录完整输出目录清单

请把 artifact 当作“待检查的构建产物”，不是无脑可刷包。刷入前必须确认它与你当前安装的 Nothing OS 版本匹配。

## 维护者备注

构建过程中踩过的坑见 [GOTCHAS.md](GOTCHAS.md)，内容偏简短，主要给后续维护者或 AI 代理使用。
