from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from aiclients import chat


class FakeBuffer(list[str]):
    def append(self, lines: list[str]) -> None:
        self.extend(lines)


class FakeNvim:
    def __init__(self, buf_id: int, buf: FakeBuffer) -> None:
        self.buffers = {buf_id: buf}


class ChatWithAiTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)

        self.root = Path(self.temp_dir.name) / "aichat"
        self.session_dir = self.root / "session" / "demo"
        self.session_dir.mkdir(parents=True)
        self.md_path = self.session_dir / "chat.md"
        self.summary_path = self.session_dir / "summary.txt"
        self.system_path = self.root / "system.txt"
        self.buf = FakeBuffer()
        self.nvim = FakeNvim(7, self.buf)

    def test_openai_chat_creates_missing_context_files_and_streams(self) -> None:
        self.md_path.write_text(
            "# Ask CHATGPT\nWhat is robust code?",
            encoding="utf-8",
        )

        with (
            patch("pynvim.attach", return_value=self.nvim),
            patch.object(
                chat,
                "_stream_openai",
                return_value=iter(["Robust\ncode"]),
            ) as stream_mock,
            patch.object(chat, "_update_summary", return_value=None),
        ):
            result = chat.chat_with_ai(self.md_path, "/tmp/nvim.sock", 7)

        self.assertEqual(result, "OK: answer completed")
        self.assertTrue(self.system_path.is_file())
        self.assertTrue(self.summary_path.is_file())
        self.assertIn("Robust", self.buf)
        self.assertIn("code", self.buf)
        provider_call = stream_mock.call_args
        self.assertEqual(provider_call.args[0], "[pro]gpt-5.5")
        self.assertEqual(provider_call.args[2], "openai")
        self.assertEqual(
            provider_call.args[1][-1],
            {"role": "user", "content": "What is robust code?"},
        )

    def test_gemini_model_uses_mocked_gemini_stream(self) -> None:
        self.md_path.write_text("# Ask GEMINI\nHello", encoding="utf-8")

        with (
            patch("pynvim.attach", return_value=self.nvim),
            patch.object(
                chat,
                "_stream_gemini",
                return_value=iter(["Hi"]),
            ) as stream_mock,
            patch.object(chat, "_update_summary", return_value=None),
        ):
            result = chat.chat_with_ai(self.md_path, "/tmp/nvim.sock", "7")

        self.assertEqual(result, "OK: answer completed")
        self.assertEqual(stream_mock.call_args.args[0], "gemini-3.1-pro")

    def test_empty_question_and_unknown_model_return_clear_errors(self) -> None:
        for contents, expected in (
            ("# Ask CHATGPT\n", "question is empty"),
            ("# Ask NOT_A_MODEL\nHello", "unknown model"),
        ):
            with self.subTest(contents=contents):
                self.md_path.write_text(contents, encoding="utf-8")
                result = chat.chat_with_ai(self.md_path)
                self.assertIn("ERROR:", result)
                self.assertIn(expected, result)

    def test_missing_nvim_connection_does_not_start_api_request(self) -> None:
        self.md_path.write_text("# Ask DEEPSEEK\nHello", encoding="utf-8")

        with patch.object(chat, "_stream_openai") as stream_mock:
            result = chat.chat_with_ai(self.md_path)

        self.assertIn("unable to connect to nvim buffer", result)
        stream_mock.assert_not_called()

    def test_nvim_attach_failure_is_reported(self) -> None:
        self.md_path.write_text("# Ask CHATGPT\nHello", encoding="utf-8")

        with patch("pynvim.attach", side_effect=OSError("socket closed")):
            result = chat.chat_with_ai(self.md_path, "/tmp/missing.sock", 7)

        self.assertIn("unable to connect to nvim buffer", result)
        self.assertIn("socket closed", result)

    def test_api_start_failure_is_reported_to_buffer(self) -> None:
        self.md_path.write_text("# Ask CHATGPT\nHello", encoding="utf-8")

        with (
            patch("pynvim.attach", return_value=self.nvim),
            patch.object(
                chat,
                "_stream_openai",
                side_effect=RuntimeError("provider unavailable"),
            ),
        ):
            result = chat.chat_with_ai(self.md_path, "/tmp/nvim.sock", 7)

        self.assertIn("AI request failed", result)
        self.assertTrue(
            any("provider unavailable" in line for line in self.buf),
            self.buf,
        )

    def test_stream_failure_does_not_escape(self) -> None:
        self.md_path.write_text("# Ask CHATGPT\nHello", encoding="utf-8")

        def broken_stream():
            yield "partial"
            raise RuntimeError("stream interrupted")

        with (
            patch("pynvim.attach", return_value=self.nvim),
            patch.object(chat, "_stream_openai", return_value=broken_stream()),
        ):
            result = chat.chat_with_ai(self.md_path, "/tmp/nvim.sock", 7)

        self.assertIn("AI request failed", result)
        self.assertIn("stream interrupted", result)

    def test_summary_api_failure_is_logged_and_returned(self) -> None:
        self.summary_path.touch()

        with patch.object(
            chat,
            "OpenAI",
            side_effect=RuntimeError("summary provider unavailable"),
        ):
            result = chat._update_summary(
                self.summary_path,
                "",
                "Question",
                "Answer",
            )

        self.assertEqual(
            result,
            "RuntimeError: summary provider unavailable",
        )


if __name__ == "__main__":
    unittest.main()
