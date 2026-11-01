#!/usr/bin/env python3
# 子终端 / 浮动终端里的 vim / vimdiff → 主 Neovim
#
#   nvim_term_remote.py <father> file.lua      → :e file
#   nvim_term_remote.py <father> -d f1 f2      → CodeDiff file
#   nvim_term_remote.py <father> -d dir1 dir2  → CodeDiff dir

import json
import os
import subprocess
import sys

if len(sys.argv) < 2:
    sys.exit("[info] must have nvim pip")

father = sys.argv[1]
args = sys.argv[2:]
diff = "-d" in args or "--diff" in args
paths = [a for a in args if a not in ("-d", "--diff", "--")]
paths = [os.path.abspath(path) for path in paths if not path.startswith("-")]


def nvim_bin() -> str:
    """与 shell wrapper 用同一个 nvim（否则会拿 PATH 里另一版本去连本实例 socket）。"""
    candidate = os.environ.get("NVIM_BIN")
    if candidate and os.access(candidate, os.X_OK):
        return candidate
    # 官方 release 包解压后的默认目录名（mac / linux），哪个存在用哪个；都没有就用 PATH 里的 nvim
    for name in ("nvim-macos-arm64", "nvim-macos-x86_64", "nvim-linux-x86_64", "nvim-linux-arm64"):
        fallback = os.path.expanduser(f"~/{name}/bin/nvim")
        if os.access(fallback, os.X_OK):
            return fallback
    return "nvim"


def vim_list(values: list[str]) -> str:
    """拼成 vimscript 列表，元素用单引号字符串（内部单引号翻倍）。"""
    items = ["'" + v.replace("'", "''") + "'" for v in values]
    return "[" + ", ".join(items) + "]"


if diff and len(paths) >= 2:
    p1, p2 = paths[0], paths[1]
    subcommand = "dir" if os.path.isdir(p1) and os.path.isdir(p2) else "file"
    expression = (
        f'execute("CodeDiff {subcommand} " . fnameescape({json.dumps(p1)})'
        f' . " " . fnameescape({json.dumps(p2)}))'
    )
    result = subprocess.run(
        [nvim_bin(), "--server", father, "--remote-expr", expression],
        stdout=subprocess.DEVNULL,  # 不让 CodeDiff 的 "Switch to tab N" 之类消息落回终端
        check=False,
    )
    raise SystemExit(result.returncode)
elif paths:
    # 交给父实例的 lua/remote_open.lua：复用普通窗口 :edit，不再每次 tabnew
    expression = "luaeval(\"require('remote_open').open(_A)\", " + vim_list(paths) + ")"
    result = subprocess.run(
        [nvim_bin(), "--server", father, "--remote-expr", expression],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    raise SystemExit(result.returncode)
