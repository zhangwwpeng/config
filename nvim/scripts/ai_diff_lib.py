#!/usr/bin/env python3
"""
ai-diff 公共库。

各 hook 脚本通过本模块共享 session 目录布局与 change.json 读写逻辑：
  ~/.cache/nvim/ai-diff/sessions/<session_id>/
    old/          工具执行前的快照（M/D）
    new/          Stop 时从工作区复制的最新内容（M/A）
    change.json   相对路径 -> 操作类型（M=修改, A=新增, D=删除）
    .cwd          项目根目录，供 Stop 时 resolve 相对路径
"""

from __future__ import annotations

import json
import os
import re
import shutil
from pathlib import Path

# 快照根目录：~/.cache/nvim/ai-diff/sessions/<session_id>/
SESSION_ROOT = Path.home() / ".cache/nvim/ai-diff/sessions"

# Codex apply_patch 的 *** Add/Update/Delete File: 行
PATCH_OP_RE = re.compile(r"^\*\*\* (Add|Update|Delete) File: (.+)$", re.MULTILINE)

# PreToolUse hook 关注的写/删工具名（大小写敏感，与宿主一致）
WRITE_TOOLS = {"Write", "Edit", "MultiEdit", "apply_patch"}
DELETE_TOOLS = {"Delete"}


def get_session_id(payload: dict) -> str | None:
    """返回 session 名。可通过 AI_DIFF_FIXED_SESSION 固定为常量。"""
    fixed_session = os.environ.get("AI_DIFF_FIXED_SESSION")
    if fixed_session:
        return fixed_session

    session_id = (
        payload.get("session_id")
        or payload.get("sessionId")
    )
    return str(session_id) if session_id else None


def get_payload_cwd(payload: dict) -> Path | None:
    """兼容不同宿主的 cwd 字段，返回解析后的绝对路径。"""
    cwd_raw = (
        payload.get("cwd")
        or payload.get("workspace_cwd")
        or payload.get("workspaceCwd")
        or payload.get("workspace_path")
        or payload.get("workspacePath")
    )
    if not cwd_raw:
        return None
    return Path(str(cwd_raw)).resolve()


def get_session_dir(session_id: str) -> Path:
    return SESSION_ROOT / session_id


def init_session_dir(session_dir: Path, cwd: Path | None = None) -> None:
    """创建 session 目录及 old/、new/ 子目录。"""
    session_dir.mkdir(parents=True, exist_ok=True)
    (session_dir / "old").mkdir(exist_ok=True)
    (session_dir / "new").mkdir(exist_ok=True)
    if cwd is not None:
        (session_dir / ".cwd").write_text(str(cwd))


def reset_session_dir(session_dir: Path, cwd: Path | None = None) -> None:
    """重建 session 目录，清空旧的 old/new/change.json。"""
    if session_dir.exists():
        shutil.rmtree(session_dir)
    init_session_dir(session_dir, cwd)


def load_change_json(session_dir: Path) -> dict[str, str]:
    change_file = session_dir / "change.json"
    if not change_file.exists():
        return {}
    return json.loads(change_file.read_text())


def save_change_json(session_dir: Path, changes: dict[str, str]) -> None:
    change_file = session_dir / "change.json"
    change_file.write_text(
        json.dumps(changes, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def rel_path_key(cwd: Path, file_path: Path) -> str | None:
    """返回相对 cwd 的路径；不在 cwd 内则返回 None。"""
    resolved = resolve_file_path(cwd, str(file_path)).resolve()
    try:
        return str(resolved.relative_to(cwd.resolve()))
    except ValueError:
        return None


def _record_change(
    cwd: Path,
    session_dir: Path,
    rel: str,
    op: str,
    file_path: Path | None = None,
) -> None:
    """写入 change.json；M/D 时复制原文件到 old/。"""
    init_session_dir(session_dir)

    changes = load_change_json(session_dir)
    # 同一文件多次写入只保留首次记录，old/ 保留第一次修改前的内容
    if rel in changes:
        return

    changes[rel] = op

    if op in {"M", "D"} and file_path is not None and file_path.is_file():
        old_target = session_dir / "old" / rel
        old_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(file_path, old_target)

    save_change_json(session_dir, changes)
    (session_dir / ".cwd").write_text(str(cwd))


def track_file_change(cwd: Path, session_dir: Path, file_path: Path) -> None:
    """记录修改(M)或新建(A)。"""
    resolved = resolve_file_path(cwd, str(file_path)).resolve()
    rel = rel_path_key(cwd, resolved)
    if rel is None:
        return

    if resolved.is_file():
        _record_change(cwd, session_dir, rel, "M", resolved)
    else:
        _record_change(cwd, session_dir, rel, "A")


def track_file_delete(cwd: Path, session_dir: Path, file_path: Path) -> None:
    """记录删除(D)，并把删除前的文件复制到 old/。"""
    resolved = resolve_file_path(cwd, str(file_path)).resolve()
    rel = rel_path_key(cwd, resolved)
    if rel is None:
        return

    if not resolved.is_file():
        return

    _record_change(cwd, session_dir, rel, "D", resolved)


def parse_patch_operations(command: str) -> list[tuple[str, str]]:
    """从 apply_patch 文本提取 [(相对路径, 操作)]，操作为 A/M/D。"""
    op_map = {"Add": "A", "Update": "M", "Delete": "D"}
    result: list[tuple[str, str]] = []
    for match in PATCH_OP_RE.finditer(command):
        rel = match.group(2).strip()
        if rel:
            result.append((rel, op_map[match.group(1)]))
    return result


def resolve_file_path(cwd: Path, path_str: str) -> Path:
    path = Path(path_str)
    return path if path.is_absolute() else cwd / path_str


def populate_new_dir(cwd: Path, session_dir: Path, changes: dict[str, str]) -> None:
    """Stop 时把 M/A 的当前工作区文件复制到 new/。"""
    new_dir = session_dir / "new"
    new_dir.mkdir(parents=True, exist_ok=True)

    for rel, op in changes.items():
        if op not in {"M", "A"}:
            continue
        src = cwd / rel
        if not src.is_file():
            continue
        dst = new_dir / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)


def get_cwd_from_session(session_dir: Path) -> Path | None:
    cwd_file = session_dir / ".cwd"
    if cwd_file.exists():
        return Path(cwd_file.read_text().strip())
    return None
