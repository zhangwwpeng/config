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

SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))

import ai_diff_lib as lib


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

    def test_add_records_a_without_old_copy(self) -> None:
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
        self.assertFalse((session_dir / "old" / "new.txt").exists())

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

        lib.populate_new_dir(self.cwd, session_dir, lib.load_change_json(session_dir))

        self.assertEqual((session_dir / "new" / "foo.txt").read_text(), "after\n")
        self.assertEqual((session_dir / "new" / "bar.txt").read_text(), "new content\n")
        self.assertFalse((session_dir / "new" / "gone.txt").exists())

        # Stop hook 在无 NVIM_PIP_FATHER 时只做 populate，不会阻塞
        self.run_with_payload(
            ai_diff_stop,
            {"session_id": self.session_id},
        )
        self.assertTrue((session_dir / "new" / "foo.txt").exists())


if __name__ == "__main__":
    unittest.main()
