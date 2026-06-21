#!/usr/bin/env python3
"""
Stop hook：
1. 把 M/A 的当前文件复制到 new/
2. 通知 Neovim 用 CodeDiff 比较 old/ 与 new/
3. 等待用户完成比较后，Neovim 会把 new/ 同步回工作区
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ai_diff_lib import (
    SESSION_ROOT,
    get_cwd_from_session,
    get_payload_cwd,
    get_session_id,
    load_change_json,
    populate_new_dir,
)

# Neovim 侧完成 diff 同步后可 touch 此文件；预留供后续轮询等待逻辑使用
SIGNAL_DIR = Path("/tmp")
WAIT_TIMEOUT_SEC = 3600
POLL_INTERVAL_SEC = 0.5


def signal_path(session_id: str) -> Path:
    """/tmp/aidiff_<session_id>，Stop 前清除以免读到上一轮残留信号。"""
    return SIGNAL_DIR / f"aidiff_{session_id}"


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

    session_dir = SESSION_ROOT / session_id
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

    signal_path(session_id).unlink(missing_ok=True)

    # 通过 RPC 触发 :AiDiff，Neovim 用 CodeDiff 比较 old/ 与 new/
    remote_cmd = f"<Cmd>AiDiff {session_id} <CR>"
    subprocess.run(
        ["nvim", "--server", nvim_server, "--remote-send", remote_cmd],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )


if __name__ == "__main__":
    main()
