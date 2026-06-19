from __future__ import annotations

import os
from pathlib import Path
from typing import Iterator

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


def _to_gemini_messages(messages: list[dict]) -> tuple[str | None, list[types.Content]]:
    system_instruction = None
    contents: list[types.Content] = []
    for msg in messages:
        if msg["role"] == "system":
            system_instruction = msg["content"]
        else:
            role = "model" if msg["role"] == "assistant" else "user"
            contents.append(types.Content(role=role, parts=[types.Part.from_text(text=msg["content"])]))
    return system_instruction, contents


def _stream_openai(model: str, messages: list[dict], provider: str) -> Iterator[str | None]:
    key_env, base_url = _OPENAI_CFG[provider]                                                                                      
    client = OpenAI(api_key=os.environ.get(key_env), base_url=base_url)                                                            
    stream = client.chat.completions.create(model=model, messages=messages, stream=True)
    for chunk in stream:
        if chunk.choices[0].delta.content:
            yield chunk.choices[0].delta.content


def _stream_gemini(model: str, messages: list[dict]) -> Iterator[str | None]:
    client = genai.Client()
    system_instruction, contents = _to_gemini_messages(messages)
    config = types.GenerateContentConfig(system_instruction=system_instruction)
    stream = client.models.generate_content_stream(model=model, contents=contents, config=config)
    for chunk in stream:
        if chunk.text:
            yield chunk.text


def _update_summary(summary_path: Path, prev_summary: str, question: str, answer: str) -> None:
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
            summary_path.write_text(summary)
    except Exception:
        pass  # summarization failure should not break the main flow


def chat_with_ai(md_path: Path, nvim_socket: str = "", buf_id: str = "") -> None:
    md_path = Path(md_path)
    system_path = md_path.parent.parent / "system.txt"
    summary_path = md_path.parent / "summary.txt"

    system_text = system_path.read_text().replace("\n", "")
    summary_text = summary_path.read_text().replace("\n", "")
    md_text = md_path.read_text() if md_path.is_file() else ""
    chunks = md_text.split("***")
    history_text = "***".join(chunks[-10:-1])
    question = "***".join(chunks[-1:])

    lines = question.splitlines()
    first_line = ""
    for line in lines:
        if line.strip():
            first_line = line.split()[-1]
            break

    model_info = MODEL_MAP.get(first_line)
    system_text += "you are " + first_line

    while lines and lines[0].strip() == "":
        del lines[0]
    del lines[0]
    question = " ".join(lines)

    buf = None
    if nvim_socket and buf_id:
        from pynvim import attach
        nvim = attach("socket", path=nvim_socket)
        buf = nvim.buffers[int(buf_id)]

    if model_info is None:
        if buf is not None:
            buf.append(["", "错误的MODEL", ""])
        return

    provider, model = model_info

    messages: list[dict] = []
    messages.append({"role": "system", "content": system_text})
    messages.append({"role": "assistant", "content": summary_text})
    messages.append({"role": "assistant", "content": history_text})
    messages.append({"role": "user", "content": question})

    if provider == "gemini":
        stream = _stream_gemini(model, messages)
    else:
        stream = _stream_openai(model, messages, provider)

    buf.append(["", f"# {first_line} Answer", "", ""])

    full_answer: list[str] = []
    for delta in stream:
        if delta is None:
            continue
        full_answer.append(delta)
        parts = delta.split("\n")
        buf[-1] = buf[-1] + parts[0]
        for part in parts[1:]:
            buf.append([part])

    buf.append(["", "***", ""])
    buf.append([f"# Ask {first_line}", ""])

    _update_summary(summary_path, summary_text, question, "".join(full_answer))
