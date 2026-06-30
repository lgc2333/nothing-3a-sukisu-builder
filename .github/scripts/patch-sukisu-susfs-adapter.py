#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f"{path}: expected text not found")
    path.write_text(text.replace(old, new, 1))


def replace_optional(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    if new in text or old not in text:
        return
    path.write_text(text.replace(old, new, 1))


def append_once(path: Path, marker: str, text: str) -> None:
    current = path.read_text()
    if marker in current:
        return
    path.write_text(current.rstrip() + "\n\n" + text.strip() + "\n")


def patch_tree(tree: Path) -> None:
    if (tree / "feature" / "sucompat.c").exists():
        ksu = tree
    else:
        ksu = tree / "KernelSU" / "kernel"
    if not ksu.exists():
        raise SystemExit(f"{ksu}: missing SukiSU tree")

    replace_optional(
        ksu / "feature" / "selinux_hide.c",
        "static bool ksu_selinux_hide_enabled __read_mostly = false;\n"
        "static bool ksu_selinux_hide_running __read_mostly = false;",
        "bool ksu_selinux_hide_enabled __read_mostly = false;\n"
        "bool ksu_selinux_hide_running __read_mostly = false;",
    )
    replace_optional(
        ksu / "feature" / "selinux_hide.c",
        "static struct selinux_state fake_state;",
        "struct selinux_state fake_state;",
    )
    replace_optional(
        ksu / "feature" / "selinux_hide.c",
        "static DEFINE_STATIC_KEY_FALSE(fake_status_initialize_key);\n"
        "static struct page *fake_status = NULL;\n\n"
        "static void initialize_fake_status()",
        "DEFINE_STATIC_KEY_FALSE(fake_status_initialize_key);\n"
        "struct page *fake_status = NULL;\n\n"
        "void initialize_fake_status()",
    )

    replace_once(
        ksu / "runtime" / "ksud_integration.c",
        "static void ksu_handle_sys_read(unsigned int fd, char __user **buf_ptr, size_t *count_ptr)",
        "void ksu_handle_sys_read(unsigned int fd, char __user **buf_ptr, size_t *count_ptr)",
    )
    replace_once(
        ksu / "runtime" / "ksud_integration.c",
        "static void stop_init_rc_hook();\n"
        "static void stop_execve_hook();\n\n"
        "static struct work_struct stop_input_hook_work;",
        "static void stop_init_rc_hook();\n"
        "static void stop_execve_hook();\n\n"
        "DEFINE_STATIC_KEY_TRUE(ksu_is_init_rc_hook_enabled);\n"
        "DEFINE_STATIC_KEY_TRUE(ksu_is_input_hook_enabled);\n\n"
        "static struct work_struct stop_input_hook_work;",
    )
    append_once(
        ksu / "runtime" / "ksud_integration.c",
        "void ksu_handle_vfs_fstat(int fd, loff_t *kstat_size_ptr)",
        r'''
void ksu_handle_vfs_fstat(int fd, loff_t *kstat_size_ptr)
{
    size_t extra = 0;
    struct file *file;

    if (!kstat_size_ptr)
        return;

    file = fget(fd);
    if (!file)
        return;

    if (is_init_rc(file)) {
        load_module_rc_once();
        extra = ksu_rc_len + module_rc_len;
        *kstat_size_ptr += extra;
        pr_info("adding rc len: %lld -> %lld (static=%zu module=%zu)",
                *kstat_size_ptr - extra, *kstat_size_ptr, ksu_rc_len, module_rc_len);
    }

    fput(file);
}
''',
    )

    append_once(
        ksu / "feature" / "sucompat.c",
        "int ksu_handle_faccessat(int *dfd, const char __user **filename_user",
        r'''
int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode,
                         int *__unused_flags)
{
    char path[sizeof(su_path) + 1] = {0};

    if (!filename_user || !*filename_user)
        return 0;

    strncpy_from_user_nofault(path, *filename_user, sizeof(path));
    if (unlikely(!memcmp(path, su_path, sizeof(su_path)))) {
        pr_info("ksu_handle_faccessat: su->sh\n");
        *filename_user = empty_user_path();
    }

    return 0;
}

int ksu_handle_stat(int *dfd, struct filename **filename, int *flags)
{
    if (!filename || IS_ERR(*filename) || !(*filename)->name)
        return 0;

    if (likely(memcmp((*filename)->name, su_path, sizeof(su_path))))
        return 0;

    pr_info("ksu_handle_stat: su->sh\n");
    memcpy((void *)(*filename)->name, SH_PATH, sizeof(SH_PATH));
    return 0;
}

int ksu_handle_execveat_sucompat(int *fd, struct filename **filename_ptr,
                                 void *argv, void *envp, int *flags)
{
    if (!filename_ptr || IS_ERR(*filename_ptr) || !(*filename_ptr)->name)
        return 0;

    if (likely(memcmp((*filename_ptr)->name, su_path, sizeof(su_path))))
        return 0;

    pr_info("ksu_handle_execveat_sucompat: su->sh\n");
    memcpy((void *)(*filename_ptr)->name, SH_PATH, sizeof(SH_PATH));
    return escape_with_root_profile();
}

int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,
                        void *envp, int *flags)
{
    return ksu_handle_execveat_sucompat(fd, filename_ptr, argv, envp, flags);
}
''',
    )

    append_once(
        ksu / "selinux" / "selinux.c",
        "u32 susfs_ksu_sid __read_mostly = 0;",
        r'''
#define KERNEL_PRIV_APP_DOMAIN "u:r:priv_app:s0:c512,c768"

u32 susfs_ksu_sid __read_mostly = 0;
u32 susfs_priv_app_sid __read_mostly = 0;

static void susfs_set_sid(const char *secctx_name, u32 *out_sid)
{
    int err;

    if (!secctx_name || !out_sid)
        return;

    err = security_secctx_to_secid(secctx_name, strlen(secctx_name), out_sid);
    if (err)
        pr_warn("failed setting sid for '%s': %d\n", secctx_name, err);
}

bool susfs_is_current_ksu_domain(void)
{
    return unlikely(current_sid() == susfs_ksu_sid);
}

void susfs_set_batch_sid(void)
{
    susfs_set_sid(KERNEL_SU_CONTEXT, &susfs_ksu_sid);
    susfs_set_sid(KERNEL_PRIV_APP_DOMAIN, &susfs_priv_app_sid);
}
''',
    )
    replace_once(
        ksu / "selinux" / "selinux.c",
        "void cache_sid(void)\n{",
        "void cache_sid(void)\n{\n    susfs_set_batch_sid();",
    )
    append_once(
        ksu / "selinux" / "selinux.h",
        "bool susfs_is_current_ksu_domain(void);",
        r'''
void susfs_set_batch_sid(void);
bool susfs_is_current_ksu_domain(void);
''',
    )

    append_once(
        ksu / "supercall" / "dispatch.c",
        "int ksu_handle_sys_reboot(int magic1, int magic2, unsigned int cmd",
        r'''
#ifdef CONFIG_KSU_SUSFS
#include <linux/susfs.h>
#endif

#ifndef KSU_INSTALL_MAGIC1
#define KSU_INSTALL_MAGIC1 0xDEADBEEF
#endif

int ksu_handle_sys_reboot(int magic1, int magic2, unsigned int cmd, void __user **arg)
{
#ifdef CONFIG_KSU_SUSFS
    if (magic1 != KSU_INSTALL_MAGIC1 || current_uid().val != 0)
        return -EINVAL;

    if (magic2 == SUSFS_MAGIC) {
        switch (cmd) {
#ifdef CONFIG_KSU_SUSFS_SUS_PATH
        case CMD_SUSFS_ADD_SUS_PATH:
            susfs_add_sus_path(arg);
            return 0;
        case CMD_SUSFS_ADD_SUS_PATH_LOOP:
            susfs_add_sus_path_loop(arg);
            return 0;
#endif
#ifdef CONFIG_KSU_SUSFS_SUS_MOUNT
        case CMD_SUSFS_HIDE_SUS_MNTS_FOR_NON_SU_PROCS:
            susfs_set_hide_sus_mnts_for_non_su_procs(arg);
            return 0;
#endif
#ifdef CONFIG_KSU_SUSFS_SUS_KSTAT
        case CMD_SUSFS_ADD_SUS_KSTAT:
        case CMD_SUSFS_ADD_SUS_KSTAT_STATICALLY:
            susfs_add_sus_kstat(arg);
            return 0;
        case CMD_SUSFS_UPDATE_SUS_KSTAT:
            susfs_update_sus_kstat(arg);
            return 0;
#endif
#ifdef CONFIG_KSU_SUSFS_SPOOF_UNAME
        case CMD_SUSFS_SET_UNAME:
            susfs_set_uname(arg);
            return 0;
#endif
#ifdef CONFIG_KSU_SUSFS_ENABLE_LOG
        case CMD_SUSFS_ENABLE_LOG:
            susfs_enable_log(arg);
            return 0;
#endif
#ifdef CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG
        case CMD_SUSFS_SET_CMDLINE_OR_BOOTCONFIG:
            susfs_set_cmdline_or_bootconfig(arg);
            return 0;
#endif
#ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT
        case CMD_SUSFS_ADD_OPEN_REDIRECT:
            susfs_add_open_redirect(arg);
            return 0;
#endif
#ifdef CONFIG_KSU_SUSFS_SUS_MAP
        case CMD_SUSFS_ADD_SUS_MAP:
            susfs_add_sus_map(arg);
            return 0;
#endif
        case CMD_SUSFS_ENABLE_AVC_LOG_SPOOFING:
            susfs_set_avc_log_spoofing(arg);
            return 0;
        case CMD_SUSFS_SHOW_ENABLED_FEATURES:
            susfs_get_enabled_features(arg);
            return 0;
        case CMD_SUSFS_SHOW_VARIANT:
            susfs_show_variant(arg);
            return 0;
        case CMD_SUSFS_SHOW_VERSION:
            susfs_show_version(arg);
            return 0;
        default:
            return -EINVAL;
        }
    }
#endif

    return -EINVAL;
}
''',
    )


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("usage: patch-sukisu-susfs-adapter.py TREE [TREE ...]")
    for arg in sys.argv[1:]:
        patch_tree(Path(arg))


if __name__ == "__main__":
    main()
