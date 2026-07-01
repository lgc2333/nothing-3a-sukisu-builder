# Nothing Phone (3a) NOS4 内核构建器

[English](README.md) | 简体中文

这是一个轻量 GitHub Actions 构建仓库，用于基于 Nothing 官方 SM7635 内核源码构建 Nothing Phone (3a) NOS4 内核。

本仓库不内置内核源码。workflow 会拉取：

- Nothing 内核源码：`NothingOSS/android_kernel_msm-6.1_nothing_sm7635`
- 默认分支：`sm7635/b/mr`
- 目标产品：`Asteroids`
- 构建目标：`pitti gki`
- AOSP kernel manifest：`common-android14-6.1-2025-05`
- Root 模式：`none`、`sukisu`、`sukisu_susfs`、`resukisu`

## 为什么有这个仓库

通用 GKI 镜像很方便，但这个仓库选择更贴合设备的路线：从 Nothing 官方 NOS4 内核源码构建，并让厂商/Kleaf 构建流程产出匹配的 boot 与 DLKM 相关文件。

对 Nothing Phone (3a) 来说，这通常比直接刷不相关的通用 GKI 镜像更适合作为起点，因为设备内核不只是一份通用 `Image`，还牵涉 vendor modules、DTB/DTBO、`vendor_boot`、`vendor_dlkm` 等产物。

仓库保持轻量，方便迭代 Actions workflow，而不是维护一个笨重的内核 fork。

## 构建

打开 **Actions -> Build Nothing 3a NOS4 Kernel -> Run workflow**。

建议第一次运行：

- `kernel_repo`: `NothingOSS/android_kernel_msm-6.1_nothing_sm7635`
- `kernel_ref`: `sm7635/b/mr`
- `variant`: `gki`
- `root_solution`: `none`
- `enable_kpm`: `false`

先证明不集成 SukiSU/ResukiSU、不打 SUSFS、不做 root hook 的 Nothing 官方纯净内核可以构建成功。纯净基线成功后，再分别测试 root 集成和 SUSFS。

Root 集成按层拆开：

- `sukisu`：已验证的 SukiSU-only root 层。
- `sukisu_susfs`：已验证的 SukiSU + SUSFS 层。
- `resukisu`：实验性的 ReSukiSU-only 层；目前还没有把 SUSFS 接到 ReSukiSU。该模式会为 Bazel/Kleaf sandbox 构建重写 ReSukiSU 的 `KSU_SRC`。

已验证的纯净基线：

- Run: `28472590894`
- 模式：`root_solution=none`，`variant=gki`
- 结果：成功
- 证据：SukiSU 和 SUSFS 步骤均为 skipped；`build-asteroids.log` 以 `Build completed successfully` 结束；minimal artifact 包含 `boot.img`、`boot-gz.img`、`boot-lz4.img`、`Image*`、`System.map`、`Module.symvers` 和日志。

已验证的 SukiSU-only 基线：

- Run: `28475657168`
- 模式：`root_solution=sukisu`，`variant=gki`，`enable_kpm=false`
- 结果：成功
- 证据：SukiSU 集成完成，SUSFS 步骤为 skipped；`build-asteroids.log` 以 `Build completed successfully` 结束；minimal artifact 包含同样的 boot/image 输出集合。

已验证的 SukiSU + SUSFS 基线：

- Run: `28481638077`
- 模式：`root_solution=sukisu_susfs`，`variant=gki`，`enable_kpm=false`
- 结果：成功
- 证据：SukiSU 集成和 SUSFS patch 均完成；`build-asteroids.log` 记录 `SUSFS_VERSION: v2.2.0`，并以 `Build completed successfully` 结束；下载后的 minimal artifact 包含 `.config` 和 `boot.img`。
- 配置证据：`CONFIG_KSU=y`、`CONFIG_KSU_SUSFS=y`，并且 `# CONFIG_KPM is not set`。

## 输出

workflow 会上传两个 artifact：

- `*-minimal`：日常检查/刷入用，核心是 `boot.img`，同时包含 `boot-gz.img`、`boot-lz4.img`、`Image*`、日志、配置、符号和输出清单。
- `*-full`：包含 minimal 的全部内容，并额外包含如 `vendor_boot.img`、`vendor_dlkm.img`、`dtb.img`、`dtbo.img`、`system_dlkm.img` 等设备镜像产物。

请把 artifact 当作“待检查的构建产物”，不是无脑可刷包。刷入前必须确认它与你当前安装的 Nothing OS 版本匹配。

## 维护者备注

构建过程中踩过的坑见 [GOTCHAS.md](GOTCHAS.md)，内容偏简短，主要给后续维护者或 AI 代理使用。
