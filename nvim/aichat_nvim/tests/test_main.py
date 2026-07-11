from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import main


class NvimHandlerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)

        self.root = Path(self.temp_dir.name) / "aichat"
        self.sessions_dir = self.root / "session"
        self.system_path = self.root / "system.txt"
        for attribute, value in (
            ("ROOT", self.root),
            ("SESSIONS_DIR", self.sessions_dir),
            ("SYSTEM_PATH", self.system_path),
        ):
            patcher = patch.object(main, attribute, value)
            patcher.start()
            self.addCleanup(patcher.stop)

        self.handler = main.NvimHandler()

    def test_initializes_storage_and_creates_safe_session(self) -> None:
        response = self.handler.nvim_request(
            {"op": "create_session", "message": "项目 1.test_-"}
        )

        session = self.sessions_dir / "项目 1.test_-"
        self.assertEqual(response, "Created: 项目 1.test_-")
        self.assertTrue(self.system_path.is_file())
        self.assertTrue((session / "chat.md").is_file())
        self.assertTrue((session / "summary.txt").is_file())
        self.assertEqual(
            self.handler.nvim_request({"op": "get_session"}),
            [str(session)],
        )

    def test_rejects_unsafe_session_names(self) -> None:
        unsafe_names = (
            "",
            ".",
            "..",
            "../escape",
            "nested/name",
            r"nested\name",
            "/absolute",
            " leading",
            "trailing ",
            "bad:name",
        )

        for name in unsafe_names:
            with self.subTest(name=name):
                response = self.handler.nvim_request(
                    {"op": "create_session", "message": name}
                )
                self.assertTrue(response.startswith("ERROR:"), response)

        self.assertFalse((self.root.parent / "escape").exists())

    def test_rejects_session_symlink_that_resolves_outside_root(self) -> None:
        outside = Path(self.temp_dir.name) / "outside"
        outside.mkdir()
        (self.sessions_dir / "escape").symlink_to(outside, target_is_directory=True)

        response = self.handler.nvim_request(
            {"op": "create_session", "message": "escape"}
        )

        self.assertIn("ERROR:", response)
        self.assertIn("symbolic link", response)

    def test_rejects_invalid_rpc_payload_and_unknown_operation(self) -> None:
        self.assertIn("must be a dictionary", self.handler.nvim_request(["bad"]))
        self.assertIn(
            "requires a non-empty string 'op'",
            self.handler.nvim_request({}),
        )
        self.assertEqual(
            self.handler.nvim_request({"op": "not_real"}),
            "ERROR: unknown operation: not_real",
        )

    def test_reports_storage_failure_without_raising(self) -> None:
        with patch.object(
            main,
            "_ensure_storage",
            side_effect=PermissionError("read-only"),
        ):
            response = self.handler.nvim_request({"op": "get_session"})

        self.assertIn("ERROR: get_session failed", response)
        self.assertIn("PermissionError", response)

    def test_sub_ai_validates_session_and_returns_chat_result(self) -> None:
        self.handler.nvim_request({"op": "create_session", "message": "demo"})

        with patch.object(
            main,
            "chat_with_ai",
            return_value="OK: answer completed",
        ) as chat_mock:
            response = self.handler.nvim_request(
                {
                    "op": "sub_ai",
                    "message": "demo",
                    "nvim_header": "/tmp/nvim.sock",
                    "buf": 3,
                }
            )

        self.assertEqual(response, "OK: answer completed")
        chat_mock.assert_called_once_with(
            self.sessions_dir / "demo" / "chat.md",
            "/tmp/nvim.sock",
            3,
        )


if __name__ == "__main__":
    unittest.main()
