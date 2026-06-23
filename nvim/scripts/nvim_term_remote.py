#!/usr/bin/env python3
# 子终端 / 浮动终端里的 vim / vimdiff → 主 Neovim
#
#   nvim_term_remote.py <father> file.lua      → :e file
#   nvim_term_remote.py <father> -d f1 f2      → CodeDiff file
#   nvim_term_remote.py <father> -d dir1 dir2  → CodeDiff dir

import os
import sys

if len(sys.argv) < 2:
    sys.exit("[info] must have nvim pip")

father = sys.argv[1]
args = sys.argv[2:]
diff = "-d" in args or "--diff" in args
paths = [a for a in args if a not in ("-d", "--diff") and not a.startswith("-")]

if diff and len(paths) >= 2:
    p1, p2 = os.path.abspath(paths[0]), os.path.abspath(paths[1])
    if os.path.isdir(p1) and os.path.isdir(p2):
        os.system(f'nvim --server "{father}" --remote-send "<Cmd>CodeDiff dir {p1} {p2}<CR>"')
    else:
        os.system(f'nvim --server "{father}" --remote-send "<Cmd>CodeDiff file {p1} {p2}<CR>"')
elif paths:
    for path in paths:
        os.system(f'nvim --server "{father}" --remote-send "<Cmd>e {os.path.abspath(path)}<CR>"')
