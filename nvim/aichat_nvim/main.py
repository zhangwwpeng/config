from __future__ import annotations

from pathlib import Path
from typing import Any

# msgpack>=1.0 removed the `encoding` parameter (UTF-8 is the only option),
# but msgpack-rpc-python still passes it. Strip it at the boundary.
import msgpack as _msgpack

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

import msgpackrpc

from aiclients import chat_with_ai

HOST = "127.0.0.1"
PORT = 6666
AICHAT_DIR = Path.home() / ".local" / "aichat"


def decode_data(data: Any) -> Any:
    """Recursively decode bytes to str in nested dicts/lists."""
    if isinstance(data, dict):
        return {decode_data(k): decode_data(v) for k, v in data.items()}
    if isinstance(data, list):
        return [decode_data(item) for item in data]
    if isinstance(data, bytes):
        return data.decode("utf-8")
    return data


class NvimHandler:
    def nvim_request(self, payload: Any) -> Any:
        payload = decode_data(payload)
        op = payload.get("op")
        msg = payload.get("message", "")
        nvim_header = payload.get("nvim_header", "")
        buf = payload.get("buf", "")

        handlers = {
            "get_session": self._get_session,
            "create_session": lambda: self._create_session(msg),
            "sub_ai": lambda: self._sub_ai(msg, nvim_header, buf),
        }
        handler = handlers.get(op)
        if handler:
            return handler()
        return f"Unknown op: {op}"

    def _get_session(self) -> list[str]:
        if not AICHAT_DIR.is_dir():
            return []
        return [
            str(entry)
            for entry in sorted(AICHAT_DIR.iterdir())
            if entry.is_dir()
        ]

    def _create_session(self, name: str) -> str:
        if not name:
            return "ERROR: session name required"
        dir_path = AICHAT_DIR / name
        dir_path.mkdir(parents=True, exist_ok=True)
        file_path = dir_path / "chat.md"
        file_path.touch(exist_ok=True)
        file_path = dir_path / "summary.txt"
        file_path.touch(exist_ok=True)
        return f"Created: {name}"

    def _sub_ai(self, session: str, nvim_socket: str = "", buf_id: str = "") -> str:
        session_dir = AICHAT_DIR / session
        if not session_dir.is_dir():
            return f"ERROR: session '{session}' not found"
        md_path = session_dir / "chat.md"
        chat_with_ai(md_path, nvim_socket, buf_id)
        return 1


def main() -> None:
    server = msgpackrpc.Server(NvimHandler())
    server.listen(msgpackrpc.Address(HOST, PORT))
    print(f"Server started on {HOST}:{PORT}")
    server.start()


if __name__ == "__main__":
    main()
