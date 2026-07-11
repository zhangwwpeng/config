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

if diff and len(paths) >= 2:
    p1, p2 = paths[0], paths[1]
    subcommand = "dir" if os.path.isdir(p1) and os.path.isdir(p2) else "file"
    expression = (
        f'execute("CodeDiff {subcommand} " . fnameescape({json.dumps(p1)})'
        f' . " " . fnameescape({json.dumps(p2)}))'
    )
    result = subprocess.run(
        ["nvim", "--server", father, "--remote-expr", expression],
        check=False,
    )
    raise SystemExit(result.returncode)
elif paths:
    result = subprocess.run(
        ["nvim", "--server", father, "--remote-tab-silent", "--", *paths],
        check=False,
    )
    raise SystemExit(result.returncode)
