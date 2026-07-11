#!/usr/bin/env python3
"""
ai-diff hook 单元测试。

覆盖 SessionStart / PreToolUse / Stop 三阶段，以及多宿主 JSON 字段别名、
apply_patch、固定 session 名（AI_DIFF_FIXED_SESSION）等场景。
运行: python3 test_ai_diff_hook.py -v
"""

import io
import importlib.util
import json
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))

import ai_diff_lib as lib  # noqa: E402


def load_script_module(name: str):
    """按文件名动态加载带连字符的 hook 脚本（不可直接 import）。"""
    path = SCRIPTS_DIR / f"{name}.py"
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


ai_diff_hook = load_script_module("ai-diff-hook")
ai_diff_session_start = load_script_module("ai-diff-session-start")
ai_diff_stop = load_script_module("ai-diff-stop")


class AiDiffHookTest(unittest.TestCase):
    """每个用例使用独立临时 SESSION_ROOT，避免污染 ~/.cache。"""

    def setUp(self) -> None:
        self.temp_root = Path(tempfile.mkdtemp())
        self.original_cwd = Path.cwd()
        self.original_session_root = lib.SESSION_ROOT
        self.original_fixed_session = os.environ.get("AI_DIFF_FIXED_SESSION")
        lib.SESSION_ROOT = self.temp_root / "sessions"
        self.session_id = "test-session"
        self.cwd = self.temp_root / "project"
        self.cwd.mkdir()

    def tearDown(self) -> None:
        os.chdir(self.original_cwd)
        if self.original_fixed_session is None:
            os.environ.pop("AI_DIFF_FIXED_SESSION", None)
        else:
            os.environ["AI_DIFF_FIXED_SESSION"] = self.original_fixed_session
        lib.SESSION_ROOT = self.original_session_root
        shutil.rmtree(self.temp_root)

    def session_dir(self) -> Path:
        return lib.get_session_dir(self.session_id)

    def run_with_payload(self, module, payload: dict) -> None:
        old_stdin = sys.stdin
        sys.stdin = io.StringIO(json.dumps(payload))
        try:
            module.main()
        finally:
            sys.stdin = old_stdin

    def test_session_start_creates_dirs(self) -> None:
        self.run_with_payload(
            ai_diff_session_start,
            {"session_id": self.session_id, "cwd": str(self.cwd)},
        )

        session_dir = self.session_dir()
        self.assertTrue(session_dir.is_dir())
        self.assertTrue((session_dir / "old").is_dir())
        self.assertTrue((session_dir / "new").is_dir())
        self.assertFalse((session_dir / "change.json").exists())

    def test_session_start_resets_existing_session_dir(self) -> None:
        session_dir = self.session_dir()
        lib.init_session_dir(session_dir, self.cwd)
        lib.save_change_json(session_dir, {"stale.txt": "M"})
        (session_dir / "old" / "stale.txt").parent.mkdir(parents=True, exist_ok=True)
        (session_dir / "old" / "stale.txt").write_text("stale\n")

        self.run_with_payload(
            ai_diff_session_start,
            {"session_id": self.session_id, "cwd": str(self.cwd)},
        )

        self.assertTrue((session_dir / "old").is_dir())
        self.assertTrue((session_dir / "new").is_dir())
        self.assertFalse((session_dir / "change.json").exists())
        self.assertFalse((session_dir / "old" / "stale.txt").exists())

    def test_modify_records_m_and_copies_old(self) -> None:
        target = self.cwd / "foo.txt"
        target.write_text("before\n")

        self.run_with_payload(
            ai_diff_session_start,
            {"session_id": self.session_id, "cwd": str(self.cwd)},
        )
        self.run_with_payload(
            ai_diff_hook,
            {
                "tool_name": "Write",
                "session_id": self.session_id,
                "cwd": str(self.cwd),
                "tool_input": {"path": str(target)},
            },
        )

        session_dir = self.session_dir()
        changes = json.loads((session_dir / "change.json").read_text())
        self.assertEqual(changes, {"foo.txt": "M"})
        self.assertEqual((session_dir / "old" / "foo.txt").read_text(), "before\n")

    def test_add_records_a_with_empty_old_copy(self) -> None:
        target = self.cwd / "new.txt"

        self.run_with_payload(
            ai_diff_session_start,
            {"session_id": self.session_id, "cwd": str(self.cwd)},
        )
        self.run_with_payload(
            ai_diff_hook,
            {
                "tool_name": "Write",
                "session_id": self.session_id,
                "cwd": str(self.cwd),
                "tool_input": {"path": str(target)},
            },
        )

        session_dir = self.session_dir()
        changes = json.loads((session_dir / "change.json").read_text())
        self.assertEqual(changes, {"new.txt": "A"})
        self.assertEqual((session_dir / "old" / "new.txt").read_bytes(), b"")

    def test_session_and_path_traversal_are_rejected(self) -> None:
        for session_id in (".", "..", "../escape", "bad/session", "bad session", "x<CR>quit"):
            with self.subTest(session_id=session_id):
                self.assertIsNone(lib.get_session_id({"session_id": session_id}))
                with self.assertRaises(ValueError):
                    lib.get_session_dir(session_id)

        outside = self.temp_root / "outside.txt"
        outside.write_text("outside\n")
        self.run_with_payload(
            ai_diff_session_start,
            {"session_id": self.session_id, "cwd": str(self.cwd)},
        )
        self.run_with_payload(
            ai_diff_hook,
            {
                "tool_name": "Write",
                "session_id": self.session_id,
                "cwd": str(self.cwd),
                "tool_input": {"path": "../outside.txt"},
            },
        )
        self.assertFalse((self.session_dir() / "change.json").exists())

    def test_change_json_filters_traversal_entries(self) -> None:
        session_dir = self.session_dir()
        lib.init_session_dir(session_dir, self.cwd)
        (session_dir / "change.json").write_text(
            json.dumps(
                {
                    "../outside.txt": "M",
                    "/tmp/absolute.txt": "D",
                    "nested/../../escape.txt": "A",
                    "safe file.txt": "A",
                }
            )
        )

        self.assertEqual(lib.load_change_json(session_dir), {"safe file.txt": "A"})

    def test_paths_with_spaces_round_trip_through_stop(self) -> None:
        target = self.cwd / "dir with space" / "file name.txt"
        target.parent.mkdir()
        target.write_text("before\n")

        self.run_with_payload(
            ai_diff_session_start,
            {"session_id": self.session_id, "cwd": str(self.cwd)},
        )
        self.run_with_payload(
            ai_diff_hook,
            {
                "tool_name": "Write",
                "session_id": self.session_id,
                "cwd": str(self.cwd),
                "tool_input": {"path": "dir with space/file name.txt"},
            },
        )
        target.write_text("after\n")

        with mock.patch.object(ai_diff_stop, "get_nvim_server", return_value=None):
            self.run_with_payload(ai_diff_stop, {"session_id": self.session_id})

        session_dir = self.session_dir()
        rel = Path("dir with space/file name.txt")
        self.assertEqual((session_dir / "old" / rel).read_text(), "before\n")
        self.assertEqual((session_dir / "new" / rel).read_text(), "after\n")

    def test_delete_records_d_and_copies_old(self) -> None:
        target = self.cwd / "remove.txt"
        target.write_text("to delete\n")

        self.run_with_payload(
            ai_diff_session_start,
            {"session_id": self.session_id, "cwd": str(self.cwd)},
        )
        self.run_with_payload(
            ai_diff_hook,
            {
                "tool_name": "Delete",
                "session_id": self.session_id,
                "cwd": str(self.cwd),
                "tool_input": {"path": str(target)},
            },
        )

        session_dir = self.session_dir()
        changes = json.loads((session_dir / "change.json").read_text())
        self.assertEqual(changes, {"remove.txt": "D"})
        self.assertEqual((session_dir / "old" / "remove.txt").read_text(), "to delete\n")

    def test_second_write_skips_duplicate(self) -> None:
        target = self.cwd / "foo.txt"
        target.write_text("before\n")

        self.run_with_payload(
            ai_diff_session_start,
            {"session_id": self.session_id, "cwd": str(self.cwd)},
        )
        payload = {
            "tool_name": "Write",
            "session_id": self.session_id,
            "cwd": str(self.cwd),
            "tool_input": {"path": str(target)},
        }
        self.run_with_payload(ai_diff_hook, payload)
        target.write_text("after\n")
        self.run_with_payload(ai_diff_hook, payload)

        session_dir = self.session_dir()
        changes = json.loads((session_dir / "change.json").read_text())
        self.assertEqual(changes, {"foo.txt": "M"})
        self.assertEqual((session_dir / "old" / "foo.txt").read_text(), "before\n")

    def test_a_to_m_stays_a_with_empty_old(self) -> None:
        target = self.cwd / "created.txt"
        session_dir = self.session_dir()
        lib.init_session_dir(session_dir, self.cwd)

        lib.track_file_change(self.cwd, session_dir, target)
        target.write_text("first\n")
        lib.track_file_change(self.cwd, session_dir, target)

        self.assertEqual(lib.load_change_json(session_dir), {"created.txt": "A"})
        self.assertEqual((session_dir / "old" / "created.txt").read_bytes(), b"")

    def test_a_to_d_removes_net_change(self) -> None:
        target = self.cwd / "temporary.txt"
        session_dir = self.session_dir()
        lib.init_session_dir(session_dir, self.cwd)

        lib.track_file_change(self.cwd, session_dir, target)
        target.write_text("temporary\n")
        lib.track_file_delete(self.cwd, session_dir, target)

        self.assertEqual(lib.load_change_json(session_dir), {})
        self.assertFalse((session_dir / "old" / "temporary.txt").exists())

    def test_m_to_d_becomes_d_and_preserves_original_old(self) -> None:
        target = self.cwd / "modified-then-deleted.txt"
        target.write_text("original\n")
        session_dir = self.session_dir()
        lib.init_session_dir(session_dir, self.cwd)

        lib.track_file_change(self.cwd, session_dir, target)
        target.write_text("modified\n")
        lib.track_file_delete(self.cwd, session_dir, target)

        self.assertEqual(
            lib.load_change_json(session_dir),
            {"modified-then-deleted.txt": "D"},
        )
        self.assertEqual(
            (session_dir / "old" / "modified-then-deleted.txt").read_text(),
            "original\n",
        )

    def test_d_to_m_becomes_m_and_preserves_original_old(self) -> None:
        target = self.cwd / "deleted-then-recreated.txt"
        target.write_text("original\n")
        session_dir = self.session_dir()
        lib.init_session_dir(session_dir, self.cwd)

        lib.track_file_delete(self.cwd, session_dir, target)
        target.unlink()
        lib.track_file_change(self.cwd, session_dir, target)

        self.assertEqual(
            lib.load_change_json(session_dir),
            {"deleted-then-recreated.txt": "M"},
        )
        self.assertEqual(
            (session_dir / "old" / "deleted-then-recreated.txt").read_text(),
            "original\n",
        )

    def test_change_json_write_is_atomic(self) -> None:
        session_dir = self.session_dir()
        lib.init_session_dir(session_dir, self.cwd)

        real_replace = os.replace
        with mock.patch.object(lib.os, "replace", wraps=real_replace) as replace:
            lib.save_change_json(session_dir, {"file.txt": "M"})

        replace.assert_called_once()
        self.assertEqual(lib.load_change_json(session_dir), {"file.txt": "M"})
        self.assertEqual(list(session_dir.glob(".change.json.*.tmp")), [])

    def test_apply_patch_modify(self) -> None:
        target = self.cwd / "src" / "main.py"
        target.parent.mkdir(parents=True)
        target.write_text("print('old')\n")

        self.run_with_payload(
            ai_diff_session_start,
            {"session_id": self.session_id, "cwd": str(self.cwd)},
        )
        command = "*** Begin Patch\n*** Update File: src/main.py\n-old\n+new\n*** End Patch\n"
        self.run_with_payload(
            ai_diff_hook,
            {
                "tool_name": "apply_patch",
                "session_id": self.session_id,
                "cwd": str(self.cwd),
                "tool_input": {"command": command},
            },
        )

        session_dir = self.session_dir()
        changes = json.loads((session_dir / "change.json").read_text())
        self.assertEqual(changes, {"src/main.py": "M"})

    def test_apply_patch_delete(self) -> None:
        target = self.cwd / "gone.txt"
        target.write_text("bye\n")

        self.run_with_payload(
            ai_diff_session_start,
            {"session_id": self.session_id, "cwd": str(self.cwd)},
        )
        command = "*** Begin Patch\n*** Delete File: gone.txt\n*** End Patch\n"
        self.run_with_payload(
            ai_diff_hook,
            {
                "tool_name": "apply_patch",
                "session_id": self.session_id,
                "cwd": str(self.cwd),
                "tool_input": {"command": command},
            },
        )

        session_dir = self.session_dir()
        changes = json.loads((session_dir / "change.json").read_text())
        self.assertEqual(changes, {"gone.txt": "D"})
        self.assertEqual((session_dir / "old" / "gone.txt").read_text(), "bye\n")

    def test_write_relative_path_when_process_cwd_differs(self) -> None:
        # 模拟用户级 hook 在非项目目录运行：path 是相对项目 cwd 的相对路径
        target = self.cwd / "nested" / "file.txt"
        target.parent.mkdir(parents=True)
        target.write_text("before\n")
        os.chdir(self.temp_root)

        self.run_with_payload(
            ai_diff_session_start,
            {"session_id": self.session_id, "workspace_path": str(self.cwd)},
        )
        self.run_with_payload(
            ai_diff_hook,
            {
                "tool_name": "Write",
                "session_id": self.session_id,
                "cwd": str(self.cwd),
                "tool_input": {"path": "nested/file.txt"},
            },
        )

        changes = json.loads((self.session_dir() / "change.json").read_text())
        self.assertEqual(changes, {"nested/file.txt": "M"})
        self.assertEqual(
            (self.session_dir() / "old" / "nested" / "file.txt").read_text(),
            "before\n",
        )

    def test_fixed_session_name_without_payload_session(self) -> None:
        os.environ["AI_DIFF_FIXED_SESSION"] = "claude"
        target = self.cwd / "fixed.txt"
        target.write_text("before\n")

        self.run_with_payload(
            ai_diff_session_start,
            {"cwd": str(self.cwd)},
        )
        self.run_with_payload(
            ai_diff_hook,
            {
                "tool_name": "Write",
                "cwd": str(self.cwd),
                "tool_input": {"path": "fixed.txt"},
            },
        )

        session_dir = lib.get_session_dir("claude")
        self.assertTrue(session_dir.is_dir())
        changes = json.loads((session_dir / "change.json").read_text())
        self.assertEqual(changes, {"fixed.txt": "M"})

    def test_stop_populates_new_for_m_and_a(self) -> None:
        modified = self.cwd / "foo.txt"
        modified.write_text("after\n")
        added = self.cwd / "bar.txt"
        added.write_text("new content\n")

        session_dir = self.session_dir()
        lib.init_session_dir(session_dir, self.cwd)
        lib.save_change_json(
            session_dir,
            {"foo.txt": "M", "bar.txt": "A", "gone.txt": "D"},
        )
        (session_dir / "old" / "foo.txt").parent.mkdir(parents=True, exist_ok=True)
        (session_dir / "old" / "foo.txt").write_text("before\n")
        (session_dir / "old" / "gone.txt").write_text("deleted\n")

        # 无 Neovim server 时 Stop 仍填充 new/，且不会尝试启动客户端。
        with (
            mock.patch.object(ai_diff_stop, "get_nvim_server", return_value=None),
            mock.patch.object(ai_diff_stop.subprocess, "run") as run,
        ):
            self.run_with_payload(ai_diff_stop, {"session_id": self.session_id})

        run.assert_not_called()
        self.assertEqual((session_dir / "new" / "foo.txt").read_text(), "after\n")
        self.assertEqual((session_dir / "new" / "bar.txt").read_text(), "new content\n")
        self.assertFalse((session_dir / "new" / "gone.txt").exists())
        self.assertTrue((session_dir / "new" / "foo.txt").exists())

    def test_stop_without_nvim_executable_does_not_raise(self) -> None:
        target = self.cwd / "added.txt"
        target.write_text("new\n")
        session_dir = self.session_dir()
        lib.init_session_dir(session_dir, self.cwd)
        lib.save_change_json(session_dir, {"added.txt": "A"})

        with (
            mock.patch.object(ai_diff_stop, "get_nvim_server", return_value="/tmp/nvim"),
            mock.patch.object(ai_diff_stop.shutil, "which", return_value=None),
            mock.patch.object(ai_diff_stop.subprocess, "run") as run,
        ):
            self.run_with_payload(ai_diff_stop, {"session_id": self.session_id})

        run.assert_not_called()
        self.assertEqual((session_dir / "new" / "added.txt").read_text(), "new\n")

    def test_stop_remote_send_contains_only_valid_session(self) -> None:
        target = self.cwd / "added.txt"
        target.write_text("new\n")
        session_dir = self.session_dir()
        lib.init_session_dir(session_dir, self.cwd)
        lib.save_change_json(session_dir, {"added.txt": "A"})

        with (
            mock.patch.object(ai_diff_stop, "get_nvim_server", return_value="/tmp/nvim socket"),
            mock.patch.object(ai_diff_stop.shutil, "which", return_value="/usr/bin/nvim"),
            mock.patch.object(ai_diff_stop.subprocess, "run") as run,
        ):
            self.run_with_payload(ai_diff_stop, {"session_id": self.session_id})

        command = run.call_args.args[0]
        self.assertEqual(
            command,
            [
                "/usr/bin/nvim",
                "--server",
                "/tmp/nvim socket",
                "--remote-send",
                "<Cmd>AiDiff test-session<CR>",
            ],
        )


if __name__ == "__main__":
    unittest.main()
