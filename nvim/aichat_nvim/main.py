from __future__ import annotations

import logging
from pathlib import Path
from typing import Any

# msgpack>=1.0 removed the `encoding` parameter (UTF-8 is the only option),
# but msgpack-rpc-python still passes it. Strip it at the boundary.
import msgpack as _msgpack
import msgpackrpc

from aiclients import chat_with_ai

_orig_packer = _msgpack.Packer
_orig_unpacker = _msgpack.Unpacker


def _compat_packer(*args: Any, **kwargs: Any) -> Any:
    kwargs.pop("encoding", None)
    return _orig_packer(*args, **kwargs)


def _compat_unpacker(*args: Any, **kwargs: Any) -> Any:
    kwargs.pop("encoding", None)
    return _orig_unpacker(*args, **kwargs)


_msgpack.Packer = _compat_packer  # type: ignore[assignment]
_msgpack.Unpacker = _compat_unpacker  # type: ignore[assignment]

HOST = "127.0.0.1"
PORT = 6666
ROOT = Path.home() / ".local" / "aichat"
SESSIONS_DIR = ROOT / "session"
SYSTEM_PATH = ROOT / "system.txt"

_ALLOWED_SESSION_PUNCTUATION = frozenset(" ._-")
logger = logging.getLogger(__name__)


def decode_data(data: Any) -> Any:
    """Recursively decode bytes to str in nested dicts/lists."""
    if isinstance(data, dict):
        return {decode_data(k): decode_data(v) for k, v in data.items()}
    if isinstance(data, list):
        return [decode_data(item) for item in data]
    if isinstance(data, bytes):
        return data.decode("utf-8")
    return data


def _ensure_storage() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    SESSIONS_DIR.mkdir(parents=True, exist_ok=True)
    SYSTEM_PATH.touch(exist_ok=True)


def _session_path(name: Any) -> Path:
    if not isinstance(name, str):
        raise ValueError("session name must be a string")
    if not name:
        raise ValueError("session name is required")
    if name != name.strip():
        raise ValueError("session name cannot start or end with whitespace")
    if name in {".", ".."}:
        raise ValueError("session name cannot be '.' or '..'")
    if Path(name).is_absolute() or "/" in name or "\\" in name:
        raise ValueError("session name must be a single name without path separators")
    if any(
        not char.isalnum() and char not in _ALLOWED_SESSION_PUNCTUATION
        for char in name
    ):
        raise ValueError(
            "session name may only contain letters, numbers, spaces, '.', '_' and '-'"
        )

    sessions_root = SESSIONS_DIR.resolve(strict=False)
    candidate = SESSIONS_DIR / name
    if candidate.is_symlink():
        raise ValueError("session path cannot be a symbolic link")
    resolved = candidate.resolve(strict=False)
    if resolved.parent != sessions_root:
        raise ValueError("session path resolves outside the session directory")
    return candidate


def _ensure_session_files(session_path: Path) -> None:
    session_path.mkdir(parents=False, exist_ok=True)
    for filename in ("chat.md", "summary.txt"):
        file_path = session_path / filename
        if file_path.is_symlink():
            raise OSError(f"{filename} cannot be a symbolic link")
        if file_path.exists() and not file_path.is_file():
            raise OSError(f"{filename} is not a regular file")
        file_path.touch(exist_ok=True)


def _error_response(context: str, exc: Exception) -> str:
    logger.exception("%s failed", context, exc_info=exc)
    return f"ERROR: {context} failed: {type(exc).__name__}: {exc}"


class NvimHandler:
    def __init__(self) -> None:
        try:
            _ensure_storage()
        except OSError as exc:
            logger.error(
                "Unable to initialize aichat storage: %s: %s",
                type(exc).__name__,
                exc,
            )

    def nvim_request(self, payload: Any) -> Any:
        try:
            payload = decode_data(payload)
        except (TypeError, UnicodeDecodeError) as exc:
            return f"ERROR: invalid RPC payload encoding: {exc}"
        if not isinstance(payload, dict):
            return "ERROR: RPC payload must be a dictionary"

        op = payload.get("op")
        if not isinstance(op, str) or not op:
            return "ERROR: RPC payload requires a non-empty string 'op'"

        try:
            if op == "get_session":
                return self._get_session()
            if op == "create_session":
                return self._create_session(payload.get("message"))
            if op == "sub_ai":
                nvim_socket = payload.get("nvim_header", "")
                buf_id = payload.get("buf", "")
                if not isinstance(nvim_socket, str):
                    return "ERROR: 'nvim_header' must be a string"
                if isinstance(buf_id, bool) or not isinstance(buf_id, (int, str)):
                    return "ERROR: 'buf' must be an integer or numeric string"
                return self._sub_ai(payload.get("message"), nvim_socket, buf_id)
            return f"ERROR: unknown operation: {op}"
        except ValueError as exc:
            return f"ERROR: invalid request: {exc}"
        except Exception as exc:
            return _error_response(op, exc)

    def _get_session(self) -> list[str]:
        _ensure_storage()
        sessions = []
        for entry in sorted(SESSIONS_DIR.iterdir(), key=lambda path: path.name):
            try:
                safe_path = _session_path(entry.name)
            except ValueError:
                logger.warning("Ignoring unsafe session entry: %s", entry)
                continue
            if safe_path.is_dir():
                sessions.append(str(safe_path))
        return sessions

    def _create_session(self, name: Any) -> str:
        _ensure_storage()
        session_path = _session_path(name)
        _ensure_session_files(session_path)
        return f"Created: {name}"

    def _sub_ai(
        self,
        session: Any,
        nvim_socket: str = "",
        buf_id: int | str = "",
    ) -> str:
        _ensure_storage()
        session_dir = _session_path(session)
        if not session_dir.is_dir():
            return f"ERROR: session '{session}' not found"
        _ensure_session_files(session_dir)
        md_path = session_dir / "chat.md"
        return chat_with_ai(md_path, nvim_socket, buf_id)


def main() -> None:
    server = msgpackrpc.Server(NvimHandler())
    server.listen(msgpackrpc.Address(HOST, PORT))
    print(f"Server started on {HOST}:{PORT}")
    server.start()


if __name__ == "__main__":
    main()
