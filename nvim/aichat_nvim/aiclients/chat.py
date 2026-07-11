from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import Any, Iterator

from google import genai
from google.genai import types
from openai import OpenAI

MODEL_MAP = {
    "DEEPSEEK": ("deepseek", "deepseek-v4-pro"),
    "CHATGPT": ("openai", "[pro]gpt-5.5"),
    "GEMINI": ("gemini", "gemini-3.1-pro"),
}

_OPENAI_CFG: dict[str, tuple[str, str | None]] = {
    "openai": ("DEEPSEEK_API_KEY", "http://127.0.0.1:15721"),
    "deepseek": ("DEEPSEEK_API_KEY", "https://api.deepseek.com"),
}

logger = logging.getLogger(__name__)


class ChatInputError(ValueError):
    """Raised when the current chat prompt cannot be submitted."""


def _to_gemini_messages(
    messages: list[dict[str, str]],
) -> tuple[str | None, list[types.Content]]:
    system_instruction = None
    contents: list[types.Content] = []
    for msg in messages:
        if msg["role"] == "system":
            system_instruction = msg["content"]
        else:
            role = "model" if msg["role"] == "assistant" else "user"
            contents.append(
                types.Content(
                    role=role,
                    parts=[types.Part.from_text(text=msg["content"])],
                )
            )
    return system_instruction, contents


def _stream_openai(
    model: str,
    messages: list[dict[str, str]],
    provider: str,
) -> Iterator[str]:
    key_env, base_url = _OPENAI_CFG[provider]
    client = OpenAI(api_key=os.environ.get(key_env), base_url=base_url)
    stream = client.chat.completions.create(
        model=model,
        messages=messages,
        stream=True,
    )
    for chunk in stream:
        if chunk.choices[0].delta.content:
            yield chunk.choices[0].delta.content


def _stream_gemini(
    model: str,
    messages: list[dict[str, str]],
) -> Iterator[str]:
    client = genai.Client()
    system_instruction, contents = _to_gemini_messages(messages)
    config = types.GenerateContentConfig(system_instruction=system_instruction)
    stream = client.models.generate_content_stream(
        model=model,
        contents=contents,
        config=config,
    )
    for chunk in stream:
        if chunk.text:
            yield chunk.text


def _update_summary(
    summary_path: Path,
    prev_summary: str,
    question: str,
    answer: str,
) -> str | None:
    """Summarize conversation with DeepSeek Flash and write to summary.txt."""
    try:
        key_env, base_url = _OPENAI_CFG["deepseek"]
        client = OpenAI(api_key=os.environ.get(key_env), base_url=base_url)
        prompt = (
            f"Previous summary:\n{prev_summary}\n\n"
            f"Latest Q&A:\nQ: {question}\nA: {answer}\n\n"
            "Combine the previous summary with the latest Q&A into a concise summary. "
            "Keep only key facts, decisions, and context useful for future conversations. "
            "Reply in the same language as the question. Under 3000 characters. Use English to summary"
        )
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[{"role": "user", "content": prompt}],
            stream=False,
        )
        summary = response.choices[0].message.content
        if summary:
            summary_path.write_text(summary, encoding="utf-8")
        return None
    except Exception as exc:
        logger.exception("Summary update failed")
        return f"{type(exc).__name__}: {exc}"


def _parse_prompt(md_text: str) -> tuple[str, str, str]:
    chunks = md_text.split("***")
    current_prompt = chunks[-1]
    lines = current_prompt.splitlines()

    prompt_line_index = next(
        (index for index, line in enumerate(lines) if line.strip()),
        None,
    )
    if prompt_line_index is None:
        raise ChatInputError("question is empty")

    prompt_tokens = lines[prompt_line_index].split()
    model_name = prompt_tokens[-1]
    if model_name not in MODEL_MAP:
        expected = ", ".join(MODEL_MAP)
        raise ChatInputError(
            f"unknown model '{model_name}' (expected one of: {expected})"
        )

    question = "\n".join(lines[prompt_line_index + 1 :]).strip()
    if not question:
        raise ChatInputError("question is empty")

    history_text = "***".join(chunks[-10:-1]).strip()
    return model_name, question, history_text


def _connect_buffer(nvim_socket: str, buf_id: int | str) -> tuple[Any, Any]:
    if not nvim_socket:
        raise ConnectionError("nvim socket is not connected")
    if isinstance(buf_id, bool) or buf_id == "":
        raise ConnectionError("nvim buffer id is missing")
    try:
        numeric_buf_id = int(buf_id)
    except (TypeError, ValueError) as exc:
        raise ConnectionError("nvim buffer id must be an integer") from exc
    if numeric_buf_id <= 0:
        raise ConnectionError("nvim buffer id must be positive")

    from pynvim import attach

    nvim = attach("socket", path=nvim_socket)
    try:
        buf = nvim.buffers[numeric_buf_id]
    except (IndexError, KeyError) as exc:
        raise ConnectionError(f"nvim buffer {numeric_buf_id} does not exist") from exc
    return nvim, buf


def _format_error(context: str, exc: Exception) -> str:
    return f"ERROR: {context}: {type(exc).__name__}: {exc}"


def _append_error(buf: Any, message: str) -> None:
    try:
        buf.append(["", message, ""])
    except Exception:
        logger.exception("Unable to report error to nvim buffer")


def _report_input_error(
    message: str,
    nvim_socket: str,
    buf_id: int | str,
) -> None:
    if not nvim_socket or buf_id == "":
        return
    try:
        _, buf = _connect_buffer(nvim_socket, buf_id)
        _append_error(buf, message)
    except Exception:
        logger.exception("Unable to report input error to nvim buffer")


def chat_with_ai(
    md_path: Path,
    nvim_socket: str = "",
    buf_id: int | str = "",
) -> str:
    md_path = Path(md_path)
    try:
        root = md_path.parents[2]
    except IndexError as exc:
        error = _format_error("invalid chat path", exc)
        logger.error(error)
        return error

    system_path = root / "system.txt"
    summary_path = md_path.parent / "summary.txt"

    try:
        md_path.parent.mkdir(parents=True, exist_ok=True)
        md_path.touch(exist_ok=True)
        system_path.parent.mkdir(parents=True, exist_ok=True)
        system_path.touch(exist_ok=True)
        summary_path.touch(exist_ok=True)
        system_text = system_path.read_text(encoding="utf-8").strip()
        summary_text = summary_path.read_text(encoding="utf-8").strip()
        md_text = md_path.read_text(encoding="utf-8")
    except OSError as exc:
        error = _format_error("unable to read chat files", exc)
        logger.exception("Unable to prepare chat files")
        return error

    try:
        model_name, question, history_text = _parse_prompt(md_text)
    except ChatInputError as exc:
        error = f"ERROR: {exc}"
        logger.warning(error)
        _report_input_error(error, nvim_socket, buf_id)
        return error

    try:
        _nvim, buf = _connect_buffer(nvim_socket, buf_id)
    except Exception as exc:
        error = _format_error("unable to connect to nvim buffer", exc)
        logger.exception("Unable to connect to nvim buffer")
        return error

    provider, model = MODEL_MAP[model_name]
    system_content = "\n\n".join(
        part for part in (system_text, f"You are {model_name}.") if part
    )
    messages: list[dict[str, str]] = [
        {"role": "system", "content": system_content},
    ]
    if summary_text:
        messages.append({"role": "assistant", "content": summary_text})
    if history_text:
        messages.append({"role": "assistant", "content": history_text})
    messages.append({"role": "user", "content": question})

    try:
        if provider == "gemini":
            stream = _stream_gemini(model, messages)
        else:
            stream = _stream_openai(model, messages, provider)
        iterator = iter(stream)
    except Exception as exc:
        error = _format_error("AI request failed", exc)
        logger.exception("Unable to start AI request")
        _append_error(buf, error)
        return error

    try:
        buf.append(["", f"# {model_name} Answer", "", ""])
    except Exception as exc:
        error = _format_error("nvim buffer update failed", exc)
        logger.exception("Unable to initialize answer in nvim buffer")
        return error

    full_answer: list[str] = []
    while True:
        try:
            delta = next(iterator)
        except StopIteration:
            break
        except Exception as exc:
            error = _format_error("AI request failed", exc)
            logger.exception("AI stream failed")
            _append_error(buf, error)
            return error

        if delta is None:
            continue
        if not isinstance(delta, str):
            error = "ERROR: AI request failed: stream returned non-text content"
            logger.error(error)
            _append_error(buf, error)
            return error

        full_answer.append(delta)
        parts = delta.split("\n")
        try:
            buf[-1] = buf[-1] + parts[0]
            for part in parts[1:]:
                buf.append([part])
        except Exception as exc:
            error = _format_error("nvim buffer update failed", exc)
            logger.exception("Unable to write AI response to nvim buffer")
            return error

    if not full_answer:
        error = "ERROR: AI request failed: provider returned an empty response"
        logger.error(error)
        _append_error(buf, error)
        return error

    try:
        buf.append(["", "***", ""])
        buf.append([f"# Ask {model_name}", ""])
    except Exception as exc:
        error = _format_error("nvim buffer update failed", exc)
        logger.exception("Unable to finish answer in nvim buffer")
        return error

    summary_error = _update_summary(
        summary_path,
        summary_text,
        question,
        "".join(full_answer),
    )
    if summary_error:
        return f"WARNING: answer completed but summary update failed: {summary_error}"
    return "OK: answer completed"
