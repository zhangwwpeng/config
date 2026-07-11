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
import tempfile
from contextlib import contextmanager
from fcntl import LOCK_EX, LOCK_UN, flock
from pathlib import Path
from typing import Iterator

# 快照根目录：~/.cache/nvim/ai-diff/sessions/<session_id>/
SESSION_ROOT = Path.home() / ".cache/nvim/ai-diff/sessions"

# Codex apply_patch 的 *** Add/Update/Delete File: 行
PATCH_OP_RE = re.compile(r"^\*\*\* (Add|Update|Delete) File: (.+)$", re.MULTILINE)

# PreToolUse hook 关注的写/删工具名（大小写敏感，与宿主一致）
WRITE_TOOLS = {"Write", "Edit", "MultiEdit", "apply_patch"}
DELETE_TOOLS = {"Delete"}

# Session 名只允许作为单个目录名使用的字符。
SESSION_ID_RE = re.compile(r"^[A-Za-z0-9._-]+$")
VALID_OPERATIONS = {"A", "M", "D"}


def is_valid_session_id(session_id: str) -> bool:
    """仅接受不会逃逸 session 根目录、也不能注入 Ex 命令的 session 名。"""
    return (
        session_id not in {".", ".."}
        and SESSION_ID_RE.fullmatch(session_id) is not None
    )


def is_safe_relative_path(rel: str) -> bool:
    """change.json 中的路径必须是无 traversal 的 POSIX 相对路径。"""
    if not rel or "\0" in rel or Path(rel).is_absolute():
        return False
    return all(part not in {"", ".", ".."} for part in rel.split("/"))


def _atomic_write_text(path: Path, content: str) -> None:
    """在同一目录写临时文件后 replace，读者不会看到半份内容。"""
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(
        prefix=f".{path.name}.",
        suffix=".tmp",
        dir=path.parent,
    )
    temp_path = Path(temp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_path, path)
    finally:
        temp_path.unlink(missing_ok=True)


def _atomic_copy(source: Path, target: Path) -> None:
    """原子地创建快照，避免 Stop 读到复制一半的 old 文件。"""
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(
        prefix=f".{target.name}.",
        suffix=".tmp",
        dir=target.parent,
    )
    os.close(fd)
    temp_path = Path(temp_name)
    try:
        shutil.copy2(source, temp_path)
        os.replace(temp_path, target)
    finally:
        temp_path.unlink(missing_ok=True)


@contextmanager
def _change_lock(session_dir: Path) -> Iterator[None]:
    """串行化同一 session 的 read/transition/write。"""
    lock_path = session_dir / ".change.lock"
    with lock_path.open("a+", encoding="utf-8") as handle:
        flock(handle.fileno(), LOCK_EX)
        try:
            yield
        finally:
            flock(handle.fileno(), LOCK_UN)


def get_session_id(payload: dict) -> str | None:
    """返回 session 名。可通过 AI_DIFF_FIXED_SESSION 固定为常量。"""
    fixed_session = os.environ.get("AI_DIFF_FIXED_SESSION")
    if fixed_session:
        return fixed_session if is_valid_session_id(fixed_session) else None

    session_id = (
        payload.get("session_id")
        or payload.get("sessionId")
    )
    if not session_id:
        return None
    value = str(session_id)
    return value if is_valid_session_id(value) else None


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
    if not is_valid_session_id(session_id):
        raise ValueError(f"invalid AI diff session: {session_id!r}")
    return SESSION_ROOT / session_id


def init_session_dir(session_dir: Path, cwd: Path | None = None) -> None:
    """创建 session 目录及 old/、new/ 子目录。"""
    session_dir.mkdir(parents=True, exist_ok=True)
    (session_dir / "old").mkdir(exist_ok=True)
    (session_dir / "new").mkdir(exist_ok=True)
    if cwd is not None:
        _atomic_write_text(session_dir / ".cwd", str(cwd.resolve()))


def reset_session_dir(session_dir: Path, cwd: Path | None = None) -> None:
    """重建 session 目录，清空旧的 old/new/change.json。"""
    if session_dir.exists():
        shutil.rmtree(session_dir)
    init_session_dir(session_dir, cwd)


def load_change_json(session_dir: Path) -> dict[str, str]:
    change_file = session_dir / "change.json"
    if not change_file.exists():
        return {}
    try:
        raw_changes = json.loads(change_file.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    if not isinstance(raw_changes, dict):
        return {}
    return {
        rel: op
        for rel, op in raw_changes.items()
        if isinstance(rel, str)
        and isinstance(op, str)
        and is_safe_relative_path(rel)
        and op in VALID_OPERATIONS
    }


def save_change_json(session_dir: Path, changes: dict[str, str]) -> None:
    if any(
        not is_safe_relative_path(rel) or op not in VALID_OPERATIONS
        for rel, op in changes.items()
    ):
        raise ValueError("change.json contains an invalid path or operation")
    _atomic_write_text(
        session_dir / "change.json",
        json.dumps(changes, indent=2, ensure_ascii=False) + "\n",
    )


def rel_path_key(cwd: Path, file_path: Path) -> str | None:
    """返回相对 cwd 的路径；不在 cwd 内则返回 None。"""
    resolved = resolve_file_path(cwd, str(file_path)).resolve()
    try:
        rel = resolved.relative_to(cwd.resolve()).as_posix()
    except ValueError:
        return None
    return rel if is_safe_relative_path(rel) else None


_STATE_TRANSITIONS: dict[tuple[str | None, str], str | None] = {
    (None, "A"): "A",
    (None, "M"): "M",
    (None, "D"): "D",
    ("A", "A"): "A",
    ("A", "M"): "A",
    ("A", "D"): None,
    ("M", "A"): "M",
    ("M", "M"): "M",
    ("M", "D"): "D",
    ("D", "A"): "M",
    ("D", "M"): "M",
    ("D", "D"): "D",
}


def _remove_snapshot(session_dir: Path, tree: str, rel: str) -> None:
    (session_dir / tree / rel).unlink(missing_ok=True)


def _record_change(
    cwd: Path,
    session_dir: Path,
    rel: str,
    op: str,
    file_path: Path | None = None,
) -> None:
    """应用一次状态转换；old/ 始终保留相对 session 的最初基线。"""
    init_session_dir(session_dir)

    if not is_safe_relative_path(rel) or op not in VALID_OPERATIONS:
        return

    with _change_lock(session_dir):
        changes = load_change_json(session_dir)
        previous = changes.get(rel)
        next_op = _STATE_TRANSITIONS[(previous, op)]
        old_target = session_dir / "old" / rel

        if next_op is None:
            changes.pop(rel, None)
            _atomic_write_text(session_dir / ".cwd", str(cwd.resolve()))
            save_change_json(session_dir, changes)
            _remove_snapshot(session_dir, "old", rel)
            _remove_snapshot(session_dir, "new", rel)
            return

        if previous is None:
            if op == "A":
                _atomic_write_text(old_target, "")
            elif file_path is not None and file_path.is_file():
                _atomic_copy(file_path, old_target)

        changes[rel] = next_op
        _atomic_write_text(session_dir / ".cwd", str(cwd.resolve()))
        save_change_json(session_dir, changes)


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
    if new_dir.exists():
        shutil.rmtree(new_dir)
    new_dir.mkdir(parents=True, exist_ok=True)

    for rel, op in changes.items():
        if not is_safe_relative_path(rel) or op not in {"M", "A"}:
            continue
        src = (cwd / rel).resolve()
        try:
            src.relative_to(cwd.resolve())
        except ValueError:
            continue
        if not src.is_file():
            continue
        dst = new_dir / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)


def get_cwd_from_session(session_dir: Path) -> Path | None:
    cwd_file = session_dir / ".cwd"
    if cwd_file.exists():
        value = cwd_file.read_text(encoding="utf-8").rstrip("\r\n")
        path = Path(value)
        if value and path.is_absolute():
            return path.resolve()
    return None
