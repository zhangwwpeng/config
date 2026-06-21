#!/usr/bin/env python3
"""
SessionStart hook：创建 session 目录及 old/、new/ 子目录。
兼容 Claude Code、Codex CLI 的 hook JSON 格式。
"""

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ai_diff_lib import get_payload_cwd, get_session_dir, get_session_id, reset_session_dir


def main() -> None:
    payload = json.load(sys.stdin)

    session_id = get_session_id(payload)
    if not session_id:
        return

    session_dir = get_session_dir(session_id)

    cwd = get_payload_cwd(payload)
    if cwd is None and os.getcwd():
        # payload 无 workspace 时仍清空旧快照，但不写 .cwd（后续 hook 会用 os.getcwd()）
        reset_session_dir(session_dir)
    else:
        # 正常路径：重建 old/new 并记录项目根到 .cwd
        reset_session_dir(session_dir, cwd)


if __name__ == "__main__":
    main()
