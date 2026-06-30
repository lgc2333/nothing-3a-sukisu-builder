#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path


def patch_manifest(branch_name: str) -> None:
    manifest = Path(".repo/manifests/default.xml")
    text = manifest.read_text()
    branch = branch_name.replace("common-", "")
    text = text.replace(f'revision="{branch}"', f'revision="deprecated/{branch}"')
    manifest.write_text(text)


def patch_kleaf_exports() -> None:
    kernel_bzl = Path("build/kernel/kleaf/kernel.bzl")
    text = kernel_bzl.read_text()
    load_line = 'load("//build/kernel/kleaf/impl:image/super_image.bzl", _super_image = "super_image", _unsparsed_image = "unsparsed_image")\n'
    if load_line not in text:
        anchor = 'load("//build/kernel/kleaf/impl:image/kernel_images.bzl", _kernel_images = "kernel_images")\n'
        text = text.replace(anchor, anchor + load_line)
    if "super_image = _super_image\n" not in text:
        anchor = "merged_kernel_uapi_headers = _merged_kernel_uapi_headers\n"
        text = text.replace(anchor, anchor + "super_image = _super_image\nunsparsed_image = _unsparsed_image\n")
    kernel_bzl.write_text(text)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("branch")
    parser.add_argument("--post-sync", action="store_true")
    args = parser.parse_args()

    if args.post_sync:
        patch_kleaf_exports()
    else:
        patch_manifest(args.branch)


if __name__ == "__main__":
    main()
