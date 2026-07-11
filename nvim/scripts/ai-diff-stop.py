#!/usr/bin/env python3
"""
Stop hook：
1. 把 M/A 的当前文件复制到 new/
2. 通知 Neovim 执行 :AiDiff <session_id>（由 Neovim 侧完成逐文件对比）
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ai_diff_lib import (
    get_cwd_from_session,
    get_payload_cwd,
    get_session_dir,
    get_session_id,
    load_change_json,
    populate_new_dir,
)


def get_nvim_server() -> str | None:
    """优先使用外层终端注入的地址，兼容不同环境变量名。"""
    for key in ("NVIM_PIP_FATHER", "NVIM_LISTEN_ADDRESS", "NVIM"):
        value = os.environ.get(key)
        if value:
            return value
    return None


def main() -> None:
    payload = json.load(sys.stdin)

    session_id = get_session_id(payload)
    if not session_id:
        return

    session_dir = get_session_dir(session_id)
    if not session_dir.is_dir():
        return

    change_file = session_dir / "change.json"
    if not change_file.exists():
        return

    changes = load_change_json(session_dir)
    if not changes:
        shutil.rmtree(session_dir)
        return

    # 用 session 记录的 .cwd 还原项目根，再复制 M/A 文件到 new/
    cwd = (
        get_cwd_from_session(session_dir)
        or get_payload_cwd(payload)
        or Path(os.getcwd())
    )
    populate_new_dir(cwd, session_dir, changes)

    # 无 NVIM 地址时仅填充 new/，不阻塞（便于单测与无 Neovim 环境）
    nvim_server = get_nvim_server()
    if not nvim_server:
        return

    nvim = shutil.which("nvim")
    if not nvim:
        return

    # session_id 已经过严格白名单验证；参数数组也不会经过 shell。
    remote_cmd = f"<Cmd>AiDiff {session_id}<CR>"
    try:
        subprocess.run(
            [nvim, "--server", nvim_server, "--remote-send", remote_cmd],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    except OSError:
        # Neovim 在 which 与执行之间消失时，Stop 仍应正常结束。
        return


if __name__ == "__main__":
    main()
