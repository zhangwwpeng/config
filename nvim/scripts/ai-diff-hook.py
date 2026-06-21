#!/usr/bin/env python3
"""
PreToolUse hook：写/删文件前记录 change.json，M/D 时复制原文件到 old/。
兼容 Claude Code、Codex CLI 的 hook JSON 格式。
"""

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ai_diff_lib import (
    DELETE_TOOLS,
    WRITE_TOOLS,
    get_payload_cwd,
    get_session_dir,
    get_session_id,
    parse_patch_operations,
    resolve_file_path,
    track_file_change,
    track_file_delete,
)


def _get_tool_name(payload: dict) -> str:
    """兼容 tool_name / name 等字段。"""
    value = payload.get("tool_name") or payload.get("name")
    return str(value) if value else ""


def _get_tool_input(payload: dict) -> dict:
    """兼容 tool_input / input / arguments 等字段。"""
    tool_input = (
        payload.get("tool_input")
        or payload.get("input")
        or payload.get("arguments")
    )
    return tool_input if isinstance(tool_input, dict) else {}


def _get_file_path(tool_input: dict) -> str | None:
    """兼容 path/file_path/filePath 字段。"""
    file_path = (
        tool_input.get("file_path")
        or tool_input.get("filePath")
        or tool_input.get("path")
    )
    return str(file_path) if file_path else None


def main() -> None:
    # stdin：宿主 hook 注入的 JSON（Claude Code / Codex 字段名可能不同）
    payload = json.load(sys.stdin)

    tool_name = _get_tool_name(payload)
    if tool_name not in WRITE_TOOLS and tool_name not in DELETE_TOOLS:
        return

    session_id = get_session_id(payload)
    if not session_id:
        return

    # path 相对项目 cwd；hook 进程 cwd 可能不在项目内，优先用 payload 里的 workspace 路径
    cwd = get_payload_cwd(payload) or Path(os.getcwd()).resolve()
    session_dir = get_session_dir(session_id)
    tool_input = _get_tool_input(payload)

    if tool_name == "Delete":
        file_path_str = _get_file_path(tool_input)
        if not file_path_str:
            return
        track_file_delete(cwd, session_dir, resolve_file_path(cwd, file_path_str))
        return

    # Codex：单条 command 文本可包含多个文件的 Add/Update/Delete
    if tool_name == "apply_patch":
        command = tool_input.get("command") or tool_input.get("text") or ""
        if not command:
            return

        for rel_path, op in parse_patch_operations(command):
            file_path = resolve_file_path(cwd, rel_path)
            if op == "D":
                track_file_delete(cwd, session_dir, file_path)
            elif op == "A":
                track_file_change(cwd, session_dir, file_path)
            else:
                track_file_change(cwd, session_dir, file_path)
        return

    file_path_str = _get_file_path(tool_input)
    if not file_path_str:
        return

    track_file_change(cwd, session_dir, resolve_file_path(cwd, file_path_str))


if __name__ == "__main__":
    main()
